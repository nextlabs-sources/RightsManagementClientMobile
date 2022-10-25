//
//  NXTokenManager.m
//  nxrmc
//
//  Created by nextlabs on 6/22/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXTokenManager.h"

#import "NXKeyChain.h"
#import "NXLoginUser.h"

#import "NXEncryptToken.h"
#import "NXDecryptTokenAPI.h"
#import "NXMemshipAPI.h"
#import "NXOpenSSL.h"
#import "NSString+Codec.h"
#import "NXCommonUtils.h"

#define kCacheMinCount 1

#define kEncrypKeyChainKey (@"EncryptTokens")


NXTokenManager *sharedInstance = nil;
NSLock* keyChainLock = nil;

@interface NXDecryptionTokenCache : NSObject

@property (nonatomic, strong) NSString* DUID;
@property (nonatomic, strong) NSString* agreement;
@property (nonatomic, strong) NSString* ml;
@property (nonatomic, strong) NSString* owner;
@property (nonatomic, strong) NSString* aeshexkey;

@end

@implementation NXDecryptionTokenCache

- (id) initWith: (NSString*) duid agreement: (NSString*)agreement ml:(NSString*)ml owner:(NSString*)owner aeshexkey: (NSString*)aeshexkey
{
    if (self = [super init]) {
        self.DUID = duid;
        self.agreement = agreement;
        self.ml = ml;
        self.owner = owner;
        self.aeshexkey = aeshexkey;
    }
    return self;
}

- (BOOL) isEqualWith: (NXDecryptionTokenCache*)obj
{
    if ([self.DUID isEqualToString:obj.DUID] && [self.agreement isEqualToString:obj.agreement] && [self.ml isEqualToString:obj.ml] && [self.owner isEqualToString:obj.owner])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end

@interface NXTokenManager ()
{
    NSMutableArray* cachedDecryptionTokens;
}

@end

@implementation NXTokenManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self commitInit];
        
        cachedDecryptionTokens = [NSMutableArray array];
    }
    return self;
}

- (void)commitInit {
    keyChainLock = [[NSLock alloc] init];
}

-(void) cleanUserCacheData
{
    [cachedDecryptionTokens removeAllObjects];
}

#pragma mark

- (NSDictionary *)getEncryptionToken:(NSError**)err {
    // step1. try to get token from cache keychain
    NSMutableDictionary *tokens = [[NSMutableDictionary alloc]initWithDictionary:[self getEncryptTokensFromKeyChain]];
    // step2. if can not get token from keychain, generate new tokens from RMS
    if (tokens == nil || tokens.count == 0)
    {
        tokens = [NSMutableDictionary dictionaryWithDictionary:[self getEncryptionTokensFromServer: err]];
    }
    //if both server and keychain is nil. return false.
    if (tokens == nil || tokens.count == 0) {
        return nil;
    }
    
    //it cache is less than min count. get more tokens and cache them
    if (tokens && tokens.count < kCacheMinCount + 1) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError* error = nil;
            [self getEncryptionTokensFromServer: &error];
        });
    }
    
    if (tokens && tokens.count) {
        NSMutableDictionary *tokensPair = [[NSMutableDictionary alloc]initWithDictionary:tokens[TOKEN_TOKENS_PAIR_KEY]];
        NSString *key = [[tokensPair allKeys] objectAtIndex:0];  // just get first token pair
        
        NSDictionary *token = @{key: [tokensPair objectForKey:key]};
        // when using a token, remove it.
        [tokensPair removeObjectForKey:key];
        tokens[TOKEN_TOKENS_PAIR_KEY] = tokensPair;
        // update keychain
        [self saveEncryptTokensToKeyChain:tokens];
        
        NSDictionary *retToken = @{TOKEN_AG_KEY:tokens[TOKEN_AG_KEY], TOKEN_AG_ICA: tokens[TOKEN_AG_ICA], TOKEN_ML_KEY:tokens[TOKEN_ML_KEY], TOKEN_TOKENS_PAIR_KEY:token};
        return retToken;
    }
    
    return nil;
}

- (NSString *)getDecryptionToken:(NSString *)uuid agreement:(NSData *)pubKey owner:(NSString *)owner ml:(NSString *)ml error: (NSError**)err{
    /*
     in nxl, we have stored agreement public key, this is binary.
     so, we need to convert binary format publick key to PEM agreement.
     */
    NSString *agreement = [NXOpenSSL DHAgreementFromBinary:pubKey];
    
    NXDecryptionTokenCache* newToken = [[NXDecryptionTokenCache alloc]initWith:uuid agreement:agreement ml:ml owner:owner aeshexkey:nil];
    
    // step1. check memory cache to see if decrytion key is there.
    for (NXDecryptionTokenCache* cache in cachedDecryptionTokens) {
        if ([cache isEqualWith:newToken]) {
            return cache.aeshexkey;
        }
    }
    
   // step2. if no memory cache, then get decrypt token from server
    
    NSString *token = [self getDecryptionTokenFromServer:uuid agreement:agreement owner:owner ml:ml error: err];
    
    if (token == nil) {
        return nil;
    }
    
    newToken.aeshexkey = token;
    
    // cache in memory.
 //   [cachedDecryptionTokens removeAllObjects];
    [cachedDecryptionTokens addObject:newToken];
    
    return token;
}

#pragma mark -

- (NSDictionary *)getEncryptionTokensFromServer: (NSError**)err{
    
    
    
    __block NSDictionary *certificates = nil;
    
    // call membership first
    NXMemshipAPIRequestModel *model = [[NXMemshipAPIRequestModel alloc]initWithUserId:[NXLoginUser sharedInstance].profile.userId ticket:[NXLoginUser sharedInstance].profile.ticket membership:[NXLoginUser sharedInstance].profile.defaultMembership.ID publickey:[NXOpenSSL generateDHKeyPair][DH_PUBLIC_KEY]];
    
    NXMemshipAPI *memshipAPI = [[NXMemshipAPI alloc]initWithRequest:model];
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSError* apiError = nil;
    [memshipAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if (error) {
            apiError = error;
            NSLog(@"error %@", error.localizedDescription);
            
        } else {
            NXMemshipAPIResponse *membershipResponse = (NXMemshipAPIResponse *)response;
            if (membershipResponse.rmsStatuCode != 200) {
                NSLog(@"error %@", membershipResponse.rmsStatuMessage);

                apiError = [NSError errorWithDomain:NX_ERROR_REST_DOMAIN code:membershipResponse.rmsStatuCode userInfo:nil];
                
            } else {
                certificates = membershipResponse.results;
            }
        }
        dispatch_semaphore_signal(sema);
    }];
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (apiError) {
        if (err) {
            *err = apiError;
        }
        
        return nil;
    }
    
    
    
    if (certificates == nil || certificates.count < 2) {
        if (err) {
            *err = [NSError errorWithDomain:NX_ERROR_REST_DOMAIN code:NXRMC_ERROR_CODE_REST_MEMBERSHIP_CERTIFICATES_NOTENOUGH userInfo:nil];
        }
        return nil;
    }
    
    NSString* rootCA = nil;
    if (certificates.count >= 3) {
        rootCA = [certificates objectForKey:@"certficate3"];
    }
    else
    {
        rootCA = [certificates objectForKey:@"certficate2"];
    }
    
    NSString *tokenAgreement = nil;
    NSData* binPubKey = nil;
    [NXOpenSSL DHAgreementPublicKey:rootCA binPublicKey:&binPubKey agreement:&tokenAgreement];
    
    // calculate agreement between member private key and iCA public key
    NSString* iCA = [certificates objectForKey:@"certficate2"];
    NSData* agreementICA = nil;
    NSString* sAgreementICA = nil;
    [NXOpenSSL DHAgreementPublicKey:iCA binPublicKey:&agreementICA agreement:&sAgreementICA];
    
    // Generate "create encryption token" request
    NXEncryptTokenAPIRequestModel *encryptmodel = [[NXEncryptTokenAPIRequestModel alloc] initWithUserId:[NXLoginUser sharedInstance].profile.userId ticket:[NXLoginUser sharedInstance].profile.ticket membership:[NXLoginUser sharedInstance].profile.defaultMembership.ID agreement:tokenAgreement];
    
    dispatch_semaphore_t sema2 = dispatch_semaphore_create(0);
    NXEncryptTokenAPI *encryptAPI = [[NXEncryptTokenAPI alloc]initWithRequest:encryptmodel];
    apiError = nil;
    __block NSDictionary *tokens = nil;
    [encryptAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if (error) {
            apiError = error;
            NSLog(@"encryptTokenAPI Requset model error");
        } else {
            NXEncryptTokenAPIResponse *encryptResponse = (NXEncryptTokenAPIResponse *)response;
            if (encryptResponse.rmsStatuCode != 200) {
                NSLog(@"error %@", encryptResponse.rmsStatuMessage);

                apiError = [NSError errorWithDomain:NX_ERROR_REST_DOMAIN code:encryptResponse.rmsStatuCode userInfo:nil];
            } else {
                
                tokens = @{TOKEN_AG_KEY:binPubKey, TOKEN_AG_ICA: agreementICA, TOKEN_ML_KEY:encryptResponse.ml, TOKEN_TOKENS_PAIR_KEY:encryptResponse.tokens};
               [self saveEncryptTokensToKeyChain:tokens];
               
            }
        }
        dispatch_semaphore_signal(sema2);
    }];
    dispatch_semaphore_wait(sema2, DISPATCH_TIME_FOREVER);
    
    if (err) {
        *err = apiError;
    }
    
    return tokens;
}

- (NSString *)getDecryptionTokenFromServer:(NSString *)uuid agreement: (NSString*)agreement owner:(NSString *)owner ml:(NSString *)ml error: (NSError**)err{

    // compose request 
    NXDecryptTokenAPIRequestModel *decryptModel = [[NXDecryptTokenAPIRequestModel alloc] init];
    decryptModel.userid = [NXLoginUser sharedInstance].profile.userId;
    decryptModel.ticket = [NXLoginUser sharedInstance].profile.ticket;
    decryptModel.tenant = [NXCommonUtils currentTenant];
    
    decryptModel.ml = ml;
    decryptModel.owner = owner;

    decryptModel.agreement = agreement;
    decryptModel.duid = uuid;

    
    NXDecryptTokenAPI *decryptTokenAPI = [[NXDecryptTokenAPI alloc] initWithRequest:decryptModel];
    
    
    
    __block NSString *token = nil;
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block NSError* apiError = nil;
    [decryptTokenAPI requestWithObject:nil Completion:^(id response, NSError *error) {
        if (error) {
            apiError = error;
            
            NSLog(@"error:%@", error.localizedDescription);
        } else {
            NXDecryptTokenResponse *decryptResponse = (NXDecryptTokenResponse *)response;
            if (decryptResponse.rmsStatuCode != 200) {
                NSDictionary *userInfoDict = @{NSLocalizedDescriptionKey:decryptResponse.rmsStatuMessage};
                apiError = [NSError errorWithDomain:NX_ERROR_REST_DOMAIN code:decryptResponse.rmsStatuCode userInfo:userInfoDict];
                
                NSLog(@"NXDecryptTokenAPI error: %@", decryptResponse.rmsStatuMessage);
             
            }
            else
            {
                token = decryptResponse.token;
             //   NSLog(@"get token from server: %@", token);
            }
            
            
        }
        dispatch_semaphore_signal(sema);
    }];
    
    // wait for api access to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    if (err) {
        *err = apiError;
    }
    
    return token;
}

#pragma mark

- (NSDictionary *)getEncryptTokensFromKeyChain {
    [keyChainLock lock];
    NSMutableDictionary *tokens = [NXKeyChain load:kEncrypKeyChainKey];
    [keyChainLock unlock];
    return tokens;
}

- (void)saveEncryptTokensToKeyChain:(NSDictionary *)tokens {
    [keyChainLock lock];
    NSMutableDictionary *oldTokens = [NXKeyChain load:kEncrypKeyChainKey];
    if (oldTokens) {
        [NXKeyChain delete:kEncrypKeyChainKey];
    }
    [NXKeyChain save:kEncrypKeyChainKey data:[NSMutableDictionary dictionaryWithDictionary:tokens]];
    
    [keyChainLock unlock];
}

- (void)deleteEncryptTokensInkeyChain {
    [keyChainLock lock];
    [NXKeyChain delete:kEncrypKeyChainKey];
    [keyChainLock unlock];
}


@end
