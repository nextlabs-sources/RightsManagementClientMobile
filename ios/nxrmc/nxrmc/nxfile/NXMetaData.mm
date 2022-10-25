//
//  NXMetaData.m
//  nxrmc
//
//  Created by Kevin on 15/5/29.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//


#import "NXMetaData.h"

#import <memory>
#import <codecvt>

#import "utils.h"
#import "nxlexception.hpp"

#import "GTMDefines.h"
#import "GTMBase64.h"


#import "NXLoginUser.h"
#import "NXTokenManager.h"
#import "NSData+zip.h"
#import "NSData+Encryption.h"
#import "NXRights.h"
#import "NXLogAPI.h"
#import "NXOpenSSL.h"
#import "NXSyncHelper.h"
#import "NXCacheManager.h"

#define TAGBUFLEN           4096
#define TAGSEPARATOR_TAG        @"="
#define TAGSEPARATOR_TAGS       @"\0"
#define TAGSEPARATOR_END        @"\0\0"
#define KEYDATALENGTH           (44)


@implementation NXMetaData

+ (BOOL)isNxlFile:(NSString *)path {
    BOOL ret;
    try {
        bool b = nxl::util::simplecheck([path cStringUsingEncoding:NSUTF8StringEncoding]);
        ret = b? YES : NO;
    } catch (const nxl::exception& ex) {
        ret = NO;
    }
    
    return ret;
}

+ (void)encrypt:(NSString *)srcPath destPath:(NSString *)destPath complete:(void(^)(NSError *error, id appendInfo))finishBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([NXMetaData isNxlFile:srcPath]) {
            NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNXL userInfo:nil];
            finishBlock(error, nil);
            return;
        }
        
        /* try to get encrytion token
            if there are still tokens in key chain, use directly
            if no tokens in key chain, try to generate tokens on server.
         */
        NSError* error = nil;
        NSDictionary* tokenDictionary = [[NXTokenManager sharedInstance] getEncryptionToken:&error];
        
        if (tokenDictionary == nil || tokenDictionary.count == 0) {
            NSLog(@"get token failed");

            finishBlock(error, nil);
            return;
        }
        __block NXL_CRYPTO_TOKEN token;
        memset(&token, 0, sizeof(token));
        
        // extract public key from agreement.
        NSData* pubKeyAgreement =  tokenDictionary[TOKEN_AG_KEY];
        memcpy(token.PublicKey, [pubKeyAgreement bytes], pubKeyAgreement.length);
        NSData* iCAAgreement = tokenDictionary[TOKEN_AG_ICA];
        memcpy(token.PublicKeyWithiCA, [iCAAgreement bytes], iCAAgreement.length);
        // ml
        token.ml = [tokenDictionary[TOKEN_ML_KEY] intValue];
        // set key pair, DUID => token
        NSDictionary *tokenPairs = tokenDictionary[TOKEN_TOKENS_PAIR_KEY];
        [tokenPairs enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            memcpy(token.UDID, [key cStringUsingEncoding:NSUTF8StringEncoding], 32);
            memcpy(token.Token, [obj cStringUsingEncoding:NSUTF8StringEncoding], 64);

        }];
        
        BOOL ret = NO;
        try {
            const char* pSrc = [srcPath cStringUsingEncoding:NSUTF8StringEncoding];
            const char* pDest = [destPath cStringUsingEncoding:NSUTF8StringEncoding];
            nxl::util::convert([[NXLoginUser sharedInstance].profile.defaultMembership.ID cStringUsingEncoding:NSUTF8StringEncoding], pSrc, pDest, &token, nullptr, true);
            ret = YES;
        } catch (const nxl::exception& ex) {
            ret = NO;
        }
        if (ret == NO) {
            NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ENCRYPT userInfo:nil];
            finishBlock(error, nil);
            return;
        }
        
        
        NXLogAPIRequestModel *model = [[NXLogAPIRequestModel alloc]init];
        model.duid = [[tokenPairs allKeys] firstObject];
        
        __block NSString *owner = nil;
        [NXMetaData getOwner:destPath complete:^(NSString *ownerId, NSError *error) {
            if (error) {
                NSLog(@"getOwner %@", error);
            }
            owner = ownerId;
        }];

        model.owner = owner;
        model.operation = [NSNumber numberWithInteger:kProtectOperation];
        model.repositoryId = @" ";
        model.filePathId = @" ";
        model.accessTime = [NSNumber numberWithLongLong:([[NSDate date] timeIntervalSince1970] * 1000)];
        model.accessResult = [NSNumber numberWithInteger:1];
        model.filePath = srcPath;
        model.fileName = [[destPath componentsSeparatedByString:@"/"] lastObject];
        model.activityData = @"";
        NXLogAPI *logAPI = [[NXLogAPI alloc]init];
        [logAPI generateRequestObject:model];
        [[NXSyncHelper sharedInstance] cacheRESTAPI:logAPI cacheURL:[NXCacheManager getLogCacheURL]];
        
        [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
            
        }];
        
        finishBlock(nil, tokenPairs);
    });
}

+ (void)decrypt:(NSString *)srcPath destPath:(NSString *)destPath complete:(void(^)(NSError *error))finishBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![NXMetaData isNxlFile:srcPath]) {
            NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
            finishBlock(error);
            return;
        }
        
        NXL_CRYPTO_TOKEN token;
        NSError* err = nil;
        BOOL ret = [self getFileToken:srcPath token:&token error:&err];
        if (ret == NO) {

            finishBlock(err);
            return;
        }
        
        try {
            const char* pSrc = [srcPath cStringUsingEncoding:NSUTF8StringEncoding];
            const char* pDest = [destPath cStringUsingEncoding:NSUTF8StringEncoding];
            nxl::util::decrypt(pSrc, pDest, &token, true);
            ret = YES;
        } catch (const nxl::exception& ex) {
            ret = NO;
        }
        if (ret == NO) {
            NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_DECRYPT userInfo:nil];
            finishBlock(error);
            return;
        }
        finishBlock(nil);
    });
}

+ (NSDictionary *)getTags:(NSString *)path error:(NSError **)error {
    if (![NXMetaData isNxlFile:path]) {
        if (error) {
            *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
        }
        
        return nil;
    }
    return nil;
}

+ (BOOL)setTags:(NSDictionary *)tags forFile:(NSString *)path {
    if (![NXMetaData isNxlFile:path]) {
        return NO;
    }
    
    return YES;
}

+ (void)getFileType:(NSString *)path complete:(void(^)(NSString *type, NSError *error))finishBlock {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        if (![NXMetaData isNxlFile:path]) {
            error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
            finishBlock(nil, error);
            return;
        }
        NXL_CRYPTO_TOKEN token;
        
        BOOL ret = [self getFileToken:path token:&token error: &error];
        if (ret == NO) {
            
            finishBlock(nil, error);
            return;
        }
        
        try {
            char buf[4096] = {0};
            int len = 4096;
            int flag = 0;
            nxl::util::read_section_in_nxl([path cStringUsingEncoding:NSUTF8StringEncoding], BUILDINSECTIONINFO, buf, &len, &flag, &token);
            
            // in this release, we don't support compression
            if (flag != 0) {
                NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_GETFILETYPE userInfo:@{NSLocalizedDescriptionKey:@"not supported compression for .FileInfo section"}];
                return finishBlock(nil, error);
            }
            
            NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:buf length:len] options:NSJSONReadingMutableContainers error:nil];
            
            NSString* ext = [dict valueForKey:[NSString stringWithFormat:@"%s", FILETYPEKEY]];
            if (ext.length >= 1) {
                [ext substringFromIndex:1];
                finishBlock([ext substringFromIndex:1], nil);
            } else {
                finishBlock(ext, nil);
            }
            return;
        } catch (const nxl::exception& ex) {
            NSLog(@"getFileType exception: %s", ex.what());
            ret = NO;
        }
        if (ret == NO) {
            NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_GETFILETYPE userInfo:nil];
            return finishBlock(nil, error);
        }
    });
}

+ (void)getPolicySection:(NSString *)nxlPath complete:(void(^)(NSDictionary *policySection, NSError *error))finishBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        if (![NXMetaData isNxlFile:nxlPath]) {
            error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
            finishBlock(nil, error);
            return;
        }
        
        NXL_CRYPTO_TOKEN token;
        BOOL ret = [self getFileToken:nxlPath token:&token error: &error];
        if (ret == NO) {
            finishBlock(nil, error);
            return;
        }
        
        char buf[4096] = {0};
        int len = 4096;
        
        try {
            int flag = 0;
            nxl::util::read_section_in_nxl([nxlPath cStringUsingEncoding:NSUTF8StringEncoding], BUILDINSECTIONPOLICY, buf, &len, &flag, &token);
            
            NSData *data = [NSData dataWithBytes:buf length:len];
            NSDictionary* adhoc = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            finishBlock(adhoc, nil);
            return;
            
        } catch (const nxl::exception& ex) {
            ret = NO;
        }
        error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_GETPOLICY userInfo:nil];
        finishBlock(nil, error);
    });
}

+ (void)addAdHocSharingPolicy:(NSString *)nxlPath
                     issuer:(NSString*)issuer
                       rights:(NXRights*)rights
                timeCondition:(NSString *)timeCondition
                     complete:(void(^)(NSError *error))finishBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        if (![NXMetaData isNxlFile:nxlPath]) {
            error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
            finishBlock(error);
            return;
        }
        
        // compose policy
        NSDictionary* condition = @{
                                    @"subject": @{
                                                @"type": [NSNumber numberWithInt:1],
                                                @"operator": @"=",
                                                @"name": @"application.is_associated_app",
                                                @"value": [NSNumber numberWithBool:YES],
                                            },
                                    };
        NSDictionary* policy = @{
                                 @"id": [NSNumber numberWithInt:0],
                                 @"name": @"Ad-hoc",
                                 @"action": [NSNumber numberWithInt:1],
                                 @"rights": [rights getNamedRights],
                                 @"conditions": condition,
                                 @"obligations": [rights getNamedObligations],
                                 };
        NSArray* policies = @[policy];
        
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSString* issueDate = [NSString stringWithString:[dateFormatter stringFromDate:[NSDate date]]];
        issueDate = [issueDate substringToIndex:issueDate.length - 2];
        NSDictionary* adhoc = @{
                           @"version": @"1.0",
                           @"issuer": issuer,
                           @"issueTime":issueDate,
                           @"policies":policies
                           };
        
        
        NSData* data = [NSJSONSerialization dataWithJSONObject:adhoc options:0 error:nil];
        if (!data || data.length == 0) {
            error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_UNKNOWN userInfo:nil];
            finishBlock(error);
            return;
        }
        
        
        NXL_CRYPTO_TOKEN token;
        BOOL ret = [self getFileToken:nxlPath token:&token error:&error];
        if (ret == NO) {
            
            finishBlock(error);
            return;
        }
      
        
        try {
            nxl::util::write_section_in_nxl([nxlPath cStringUsingEncoding:NSUTF8StringEncoding], BUILDINSECTIONPOLICY, (const char*)[data bytes], (int)data.length, 0, &token);
            finishBlock(nil);
            return;
        } catch (const nxl::exception& ex) {
            ret = NO;
        }
        if (ret == NO) {
            NSError *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ADDPOLICY userInfo:nil];
            finishBlock(error);
        }
    });
}

+ (void)getOwner:(NSString *)nxlPath complete:(void(^)(NSString *ownerId, NSError *error))finishBlock {
    
    NSError *error = nil;
    if (![NXMetaData isNxlFile:nxlPath]) {
        
        error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
        finishBlock(nil, error);
        return;
    }
    
    BOOL ret;
    char buf[256 + 1] = {0};
    int len = sizeof(buf);
    try {
        nxl::util::read_ownerid_from_nxl([nxlPath cStringUsingEncoding:NSUTF8StringEncoding], buf, &len);
        NSString *ownid = [NSString stringWithUTF8String:buf];
        finishBlock(ownid, nil);
        ret = YES;
    } catch (const nxl::exception&ex) {
        ret = NO;
    }
    if (ret == NO) {
        error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ADDPOLICY userInfo:nil];
        finishBlock(nil , error);
    }
    
}


#pragma mark common method for this class.
+ (BOOL)getFileToken:(NSString *)nxlFile tokenDict:(NSDictionary **)tokenDict error:(NSError**)err
{
    BOOL ret = YES;
    NXL_CRYPTO_TOKEN token;
    *tokenDict = nil;
    if(err)
    {
         *err = nil;
    }
    ret = [self getFileToken:nxlFile token:&token error: err];
    
    char duidBuffer[sizeof(token.UDID) + 1] = {0};  // store duid, hex string
    memcpy(duidBuffer, token.UDID, sizeof(token.UDID));
    NSString *udidStr = [NSString stringWithUTF8String:duidBuffer];
    
    char tokenBuffer[sizeof(token.Token) + 1] = {0};
    memcpy(tokenBuffer, token.Token, sizeof(token.Token));
    NSString *tokenStr = [NSString stringWithUTF8String:tokenBuffer];
    
    if (udidStr && tokenStr) {
        *tokenDict = @{udidStr:tokenStr};
    } else if (udidStr) {
        *tokenDict = @{udidStr: @"null value"};
    }
    return ret;
}

+ (BOOL) getNxlFile:(NSString *) nxlFile duid:(NSString **) uuid publicAgrement:(NSData **) pubAgr owner:(NSString **) owner ml:(NSString **) ml error:(NSError **) error
{

    
    try {
        // get token related info from nxl header.
        NXL_CRYPTO_TOKEN token;
        memset(&token, 0, sizeof(token));
        
        nxl::util::read_token_info_from_nxl([nxlFile cStringUsingEncoding:NSUTF8StringEncoding], &token);
        
        char duid[32 + 1] = {0};  // store duid, hex string
        memcpy(duid, token.UDID, sizeof(token.UDID));
        if (uuid) {
            *uuid = [NSString stringWithUTF8String:duid];
        }
        // get public key for agreement (between member and RootCA)
        if (pubAgr) {
            *pubAgr = [NSData dataWithBytes:token.PublicKey length:256];
        }
        
        if (ml) {
            *ml = [NSString stringWithFormat:@"%d", token.ml];
        }
        
    } catch (const nxl::exception& ex) {
        if (error) {
            *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_TOKENINFO userInfo:nil];
        }
        NSLog(@"read duid from nxl failed. error: %s", ex.what());
        
        return NO;
    }
    
    // get owner id from nxl header.
    [self getOwner:nxlFile complete:^(NSString *ownerId, NSError *error) {
        if (!error) {
            if (owner) {
                *owner = ownerId;
            }
        }
        
    }];
    
    if (!(*owner)) {
        if (error) {
            *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_OWNER userInfo:nil];
        }
        
        return NO;
    }
    return YES;
}

//this fuction is sync，may use much time, because it contain network connection
+ (BOOL)getFileToken:(NSString *)nxlFile token:(NXL_CRYPTO_TOKEN *)token error:(NSError**)err {
    //for nxl file, using uuid exiested in file to get Token.
    if (![self isNxlFile:nxlFile])
    {
        if (err) {
            *err = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_ISNOTNXL userInfo:nil];
        }
        return NO;
    }
    
        
    NSString *uuid = nil;
    NSData *publicKeyAgreement = nil;
    NSString* ml;
    
    try {
        // get token related info from nxl header.
        NXL_CRYPTO_TOKEN token;
        memset(&token, 0, sizeof(token));
        
        nxl::util::read_token_info_from_nxl([nxlFile cStringUsingEncoding:NSUTF8StringEncoding], &token);
        
        char duid[32 + 1] = {0};  // store duid, hex string
        memcpy(duid, token.UDID, sizeof(token.UDID));
        uuid = [NSString stringWithUTF8String:duid];
        
        // get public key for agreement (between member and RootCA)
        publicKeyAgreement = [NSData dataWithBytes:token.PublicKey length:256];
        ml = [NSString stringWithFormat:@"%d", token.ml];
        
    } catch (const nxl::exception& ex) {
        if (err) {
            *err = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_TOKENINFO userInfo:nil];
        }
        NSLog(@"read duid from nxl failed. error: %s", ex.what());
        
        return NO;
    }

    if (uuid == nil) {
        if (err) {
            *err = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_TOKENINFO userInfo:nil];
        }
        
        return NO;
    }
    
    memset(token, 0, sizeof(*token));
    memcpy(token->UDID, [uuid cStringUsingEncoding:NSUTF8StringEncoding], 32);
    
    // get owner id from nxl header.
    __block NSString* owner = nil;
    [self getOwner:nxlFile complete:^(NSString *ownerId, NSError *error) {
        if (!error) {
            owner = ownerId;
        }
        
    }];
    
    if (!owner) {
        if (err) {
            *err = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN code:NXRMC_ERROR_CODE_NXFILE_OWNER userInfo:nil];
        }
        
        return NO;
    }
    
    
    NSString* tokenValue = [[NXTokenManager sharedInstance] getDecryptionToken:uuid agreement: publicKeyAgreement owner: owner ml: ml error: err];
    if (tokenValue == nil) {
        return NO;
    }
    memset(token, 0, sizeof(*token));
    
    memcpy(token->UDID, [uuid cStringUsingEncoding:NSUTF8StringEncoding], 32);
    memcpy(token->Token, [tokenValue cStringUsingEncoding:NSUTF8StringEncoding], 64);
    return YES;
    
}

+ (NSString *)hmacSha256Token:(NSString *) token content:(NSData *) content
{
    if (token && content) {
        char hash[64] = {0};
        int length = 64;
        nxl::util::hmac_sha256((char *)content.bytes, (int) content.length, token.UTF8String, hash, &length);
      //  nxl::hmac_sha256_token(token.UTF8String, (int)token.length, content.UTF8String, (int)content.length, hash);
        std::string sHash(hash, 64);
        return [NSString stringWithFormat:@"%s", sHash.c_str()];
    }
    
    return nil;
}

@end
