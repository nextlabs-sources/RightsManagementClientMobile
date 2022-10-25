//
//  LoginUser.m
//  nxrmc
//
//  Created by Kevin on 15/4/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXLoginUser.h"

#import "AppDelegate.h"
#import "NXCacheManager.h"
#import "NXCommonUtils.h"
#import "NXTokenManager.h"
#import "NXKeyChain.h"
#import "NXAddRepositoryAPI.h"
#import "NXRemoveRepositoryAPI.h"
#import "NXSyncRepoHelper.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "NXHeartbeatManager.h"
#import "NXUpdateRepositoryAPI.h"

static NXLoginUser* sharedObj = nil;

@implementation NXLoginUser

+ (NXLoginUser *)sharedInstance {
    @synchronized(self) {
        if (sharedObj == nil) {
            sharedObj = [[super allocWithZone:nil] init];
        }
    }
    
    return sharedObj;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return nil;
}

#pragma mark 

- (void)loginWithUser:(NXProfile *)profile {
    _profile = profile;
    // save to key chain
    [NXCommonUtils storeProfile:profile];
    [self loadAllBoundServices];
}

- (void)loadAllBoundServices {
    // get bound services
    NSNumber* uid = [NXCommonUtils converttoNumber:_profile.userId];
    NSArray* objects = [NXCommonUtils fetchData:TABLE_BOUNDSERVICE predicate:[NSPredicate predicateWithFormat:@"user_id=%@", uid]];
    
    _boundServices = [objects mutableCopy];
    
    [self.serviceRootFolderDict removeAllObjects];
    
    for (NXBoundService * service in _boundServices) {
        [self addRootFolderInDictionaryForService:service];
    }
    
    [[NXHeartbeatManager sharedInstance] start];
}

#pragma mark

- (void)logOut {
    [[NXHeartbeatManager sharedInstance] stop];
    [[NXTokenManager sharedInstance] cleanUserCacheData];
    
    [NXCommonUtils deleteProfile:self.profile];
    _profile = nil;
    _boundServices = nil;
    _serviceRootFolderDict = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_NXRMC_LOG_OUT object:self];
}

- (BOOL)isLogInState {
    if (self.profile) {
        return YES;
    }
    return NO;
}

- (BOOL)isAutoLogin {
    
    NSArray *profiles = [NXCommonUtils getStoredProfiles];
    if (profiles.count == 0) {
        return  NO;
    }
    NXProfile *profile = [profiles objectAtIndex:0];
    //is session time out.
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    if (profile.ttl.doubleValue - timeInterval * 1000  > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (void) loadUserAccountData
{
    NSArray *profiles = [NXCommonUtils getStoredProfiles];
    assert(profiles.count > 0);
    _profile = [profiles objectAtIndex:0];
    [self loadAllBoundServices];
}

#pragma mark 

- (BOOL)addService:(ServiceType) type serviceAccount:(NSString *)sa serviceAccountId:(NSString *)sai serviceAccountToken:(NSString *)sat isAuthed:(BOOL) isAuthed displayName:(NSString *)displayName{
    //step1. before add service to local, need upload repo to RMS and get repoID
    __block NXRMCRepoItem *rmcRepoItem = [[NXRMCRepoItem alloc] init];
    __block NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
    rmcRepoItem.service_id = RMC_DEFAULT_SERVICE_ID_UNSET;
    rmcRepoItem.user_id = [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId];
    rmcRepoItem.service_alias = displayName;
    rmcRepoItem.service_type = [NSNumber numberWithInteger:type];
    rmcRepoItem.service_account = sa;
    rmcRepoItem.service_account_id  = sai;
    rmcRepoItem.service_account_token = sat;
    rmcRepoItem.service_isAuthed = isAuthed; 
    // change the service_token to the really repo token.(For RMC, the token is the identity for repo token, but for RMS, the token is the really repo token, so we need do change)
    [self changeRMCServiceTokenToRMSServiceToken:rmcRepoItem];
    
    // save the add REST to disk
    NXAddRepositoryAPIRequest *addRepoRESTAPI = [[NXAddRepositoryAPIRequest alloc] initWithAddRepoItem:rmcRepoItem];
    [addRepoRESTAPI requestWithObject:rmcRepoItem Completion:^(id response, NSError *error) {
        if ([response isKindOfClass:[NXAddRepositoryAPIResponse class]]) {
            NXAddRepositoryAPIResponse *addRepoResponsse = (NXAddRepositoryAPIResponse *) response;
            if (addRepoResponsse.rmsStatuCode == 0) {  // 0 OK
               // step1. get the RMS's serviceId and store it
                rmcRepoItem.service_id = addRepoResponsse.repoId;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // step2. store repo info to coredata
                    // restet from rms token into rmc token
                    rmcRepoItem.service_account_token = sat;
                    NXBoundService* service = [NXCommonUtils storeServiceIntoCoreData:rmcRepoItem];
                    
                    ////////////after new boundService///////////////
                    // step3.
                    [_boundServices addObject:service];
                    [self addRootFolderInDictionaryForService:service];
                    
                    // step4.
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_ADDED object:nil];
                    return;
                });
            }else
            {
                // sync with RMS failed, clear the SDK enviroment
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self clearUpSDK:rmcRepoItem.service_type.integerValue appendData:rmcRepoItem.service_account];
                });
                
                if(addRepoResponsse.rmsStatuCode == 4) // dumplicate name
                {
                    userInfo[NOTIFICATION_REPO_ADDED_ERROR_KEY] = RMS_ADD_REPO_DUPLICATE_NAME;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // step5. finish sync with RMS, send result notification
                        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_ADDED object:nil userInfo:userInfo];
                        
                    });
                    
                }else if(addRepoResponsse.rmsStatuCode == 3) // already have the repo
                {
                    userInfo[NOTIFICATION_REPO_ADDED_ERROR_KEY] = RMS_ADD_REPO_ALREADY_EXIST;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_ADDED object:nil userInfo:userInfo];
                    });
                    
                }else{
                    userInfo[NOTIFICATION_REPO_ADDED_ERROR_KEY] = RMS_ADD_REPO_RMS_OTHER_ERROR;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // step5. finish sync with RMS, send result notification
                        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_ADDED object:nil userInfo:userInfo];
                        
                    });
                }
            }
            
            
        }else // other AddRepoResponse error
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self clearUpSDK:rmcRepoItem.service_type.integerValue appendData:rmcRepoItem.service_account];
            });
            
            userInfo[NOTIFICATION_REPO_ADDED_ERROR_KEY] = RMS_ADD_REPO_RMS_OTHER_ERROR;
            dispatch_async(dispatch_get_main_queue(), ^{
                // step5. finish sync with RMS, send result notification
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_ADDED object:nil userInfo:userInfo];
                
            });
        }
    }];

    return YES;
}

- (void)deleteService:(NXBoundService *)service {
    
    __block NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    NXRemoveRepositoryAPIRequest *removeRepoRESTAPI = [[NXRemoveRepositoryAPIRequest alloc] init];
    [removeRepoRESTAPI requestWithObject:service.service_id Completion:^(id response, NSError *error) {
        if (response && [response isKindOfClass:[NXRemoveRepositoryAPIResponse class]]) {
            if (((NXRemoveRepositoryAPIResponse *)response).rmsStatuCode == 0 || ((NXRemoveRepositoryAPIResponse *)response).rmsStatuCode == 2) { // 0 success, 2 means RMS do not have this repo
                 dispatch_async(dispatch_get_main_queue(), ^{
                    [self cleanUpBoundServiceData:service];
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_DELETED object:nil userInfo:nil];

                });
                return;
            }
        }
        
        userInfo[NOTIFICATION_REPO_DELETE_ERROR_KEY] = RMS_DELETE_REPO_FAILED;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_DELETED object:nil userInfo:userInfo];

        });
       
    }];
    
    
}

- (void)updateService:(NXBoundService *)service {
    [NXCommonUtils updateBoundServiceInCoreData:service];
}


- (void)updateService:(ServiceType) type serviceAccount:(NSString *)sa serviceAccountId:(NSString *)sai serviceAccountToken:(NSString *)sat isAuthed:(BOOL) isAuthed
{
    if (isAuthed) {
         NXBoundService *service = [NXCommonUtils getBoundServiceFromCoreData:sai];
        if (service && ![service.service_id isEqualToString:RMC_DEFAULT_SERVICE_ID_UNSET]) {  // the current service is sync from RMS for it have RMS service ID
            NXRMCRepoItem *repoItem = [[NXRMCRepoItem alloc] init];
            repoItem.service_id = service.service_id;
            repoItem.service_alias = service.service_alias;
            repoItem.service_type = [NSNumber numberWithInteger:type];
            repoItem.service_account = sa;
            repoItem.service_account_id = sai;
            repoItem.service_account_token = sat;
            // change to rms serviceToken
            [self changeRMCServiceTokenToRMSServiceToken:repoItem];
            
            NXUpdateRepositoryRequest *updateRequeset = [[NXUpdateRepositoryRequest alloc] init];
            [updateRequeset requestWithObject:repoItem Completion:^(id response, NSError *error) {
                if([response isKindOfClass:[NXUpdateRepositoryResponse class]])
                {
                    NXUpdateRepositoryResponse *updateResponse = (NXUpdateRepositoryResponse *) response;
                    if (updateResponse.rmsStatuCode == 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BOOL ret = [NXCommonUtils updateService:type serviceAccount:sa serviceAccountId:sai serviceAccountToken:sat isAuthed:isAuthed];
                            if (ret) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_CHANGED object:nil];
                            }
                        });
                        return;
                    }
                 }
                
                // if net work error or rms error , just clear the auth enviroment and notify error occur
                dispatch_async(dispatch_get_main_queue(), ^{
                    switch (type) {
                        case kServiceDropbox:
                            break;
                        case kServiceSharepoint:
                            break;
                        case kServiceSharepointOnline:
                            break;
                        case kServiceOneDrive:
                        {
                            AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
                            [app.liveClient logout];
                        }
                            break;
                        case kServiceGoogleDrive:
                        {
                            
                            [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:sat];
                        }
                            break;
                        default:
                            break;
                    }
                    NSDictionary *userInfo = @{NOTIFICATION_REPO_UPDATED_ERROR_KEY:RMS_UPDATE_REPO_ERROR};
                    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_CHANGED object:nil userInfo:userInfo];
                });
            }];
            
        }
    }
    
}

- (void)syncLocalServiceInfoWithAddedServices:(NSArray *)addedServices deletedServices:(NSArray *)deletedServices updatedServices:(NSArray *)updatedServices {
    if (addedServices.count > 0) {
        for(NXRMCRepoItem *service in addedServices)
        {
//             step1. (1)depending on various repository type, bulid repo SDK environment,
//             make the environment  same as user added the repo by SDK, not by RMS sync repo
//             (2) change the NXRMCRepoItem serviceToken from RMS type->RMC type if necessary
            [self buildEnviromentForRepoSDK:service];
            
            // step2. store to coredata
            NXBoundService *insertedService = [NXCommonUtils storeServiceIntoCoreData:service];
            if (insertedService) {
                // step3. stroe to the NXLoginUser boundService
                [_boundServices addObject:insertedService];
                // step4. stroe to the rootFolder dict, to do favoriate or offline
                [self addRootFolderInDictionaryForService:insertedService];

            }
        }
    }
    
    if (deletedServices.count > 0)
    {
        for(NXBoundService *service in deletedServices)
        {
            [self cleanUpBoundServiceData:service];
        }
    }
    
    if (updatedServices.count > 0) {
        for (NXBoundService *service in updatedServices) {
            [self updateService:service];
        }
    }
    
    if (addedServices.count > 0 || deletedServices.count > 0 || updatedServices.count > 0) {
        // all done, notify service list changed
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_CHANGED object:nil];
    }
}

#pragma mark -

- (void)changeRMCServiceTokenToRMSServiceToken:(NXRMCRepoItem *)serviceItem {
    switch (serviceItem.service_type.integerValue) {
        case kServiceGoogleDrive:
        {
            NSError *error = nil;
            GTMOAuth2Authentication *auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:serviceItem.service_account_token clientID:GOOGLEDRIVECLIENTID clientSecret:GOOGLEDRIVECLIENTSECRET error:&error];
            if (auth.canAuthorize) {
                NSString *psw = [auth persistenceResponseString];
                serviceItem.service_account_token = psw;
            }
        }
            break;
        case kServiceSharepoint:
        {
            serviceItem.service_account_token = [NXKeyChain load:serviceItem.service_account_id];
        }
            break;
        default:
            break;
    }
}

- (BOOL)cleanUpBoundServiceData:(NXBoundService *)boundService
{
    //delete directory cache.
    [NXCacheManager deleteCacheDirectory:[boundService.service_type integerValue] serviceAccountId:boundService.service_account_id];
    // delete cache record in db
    [NXCommonUtils deleteCacheFilesFromCoreDataForService:boundService];
    
    // delete cache files.
    NSURL* url = [NXCacheManager getLocalUrlForServiceCache:(ServiceType)[boundService.service_type intValue]serviceAccountId:boundService.service_account_id];
    
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    
    // delete the failed add repository rest API if have
    NSString *nxRepoUUID = NXREST_UUID(boundService);
    [[NXSyncRepoHelper sharedInstance] deletePreviousFailedAddRepoRESTRequest:nxRepoUUID];
    
    [_boundServices removeObject:boundService];
    [self removeRootFolderInDictionaryForService:boundService];
    
    // do repo special clear
    [self destoryEnviromentForRepoSDK:boundService];
    
    BOOL result = [NXCommonUtils deleteServiceFromCoreData:boundService];
    return result;
}


- (void)destoryEnviromentForRepoSDK:(NXBoundService *)repoItem {
    if (repoItem.service_type.integerValue == kServiceGoogleDrive) {
        
        [self clearUpSDK:repoItem.service_type.integerValue appendData:repoItem.service_account_token];
        
    }else
    {
        [self clearUpSDK:repoItem.service_type.integerValue appendData:nil];
    }
   
}

-(void) clearUpSDK:(ServiceType) serviceType appendData:(id) appendData
{
    switch (serviceType) {
        case kServiceDropbox:
            break;
        case kServiceSharepoint:
            break;
        case kServiceSharepointOnline:
            break;
        case kServiceOneDrive:
        {
            AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [app.liveClient logout];
        }
            break;
        case kServiceGoogleDrive:
        {
            NSString *keychainItemName = (NSString *)appendData;
            
           [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:keychainItemName];
        }
            break;
        default:
            break;
    }
}

- (void)buildEnviromentForRepoSDK:(NXRMCRepoItem *)repoItem {
    
    if(repoItem.service_account_token == nil)
        return;
    
    switch (repoItem.service_type.integerValue) {
        case kServiceGoogleDrive:
        {
            NSString *psw = repoItem.service_account_token;
            GTMOAuth2Authentication *auth = [[GTMOAuth2Authentication alloc] init];
            [auth setKeysForPersistenceResponseString:psw];
            NSString *keychainItemName = [NXCommonUtils randomStringwithLength:GOOGLEDRIVEKEYCHAINITEMLENGTH];
            NSError *error;
            [GTMOAuth2ViewControllerTouch saveParamsToKeychainForName:keychainItemName accessibility:NULL authentication:auth error:&error];
            
            // update the repoItemInfo
            repoItem.service_account_token = keychainItemName;
            
        }
            break;
        case kServiceOneDrive:
        {
            AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
            //  step1. log out the old account if any
            if(app.liveClient.session)
            {
                [app.liveClient logout];
            }
            
            // step2. stroe the refreshToken to disk(the same file paht for liveSDK)
            NSString *libDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *filePath = [libDirectory stringByAppendingPathComponent:@"LiveService_auth.plist"];
            
            NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
            [data setValue:ONEDRIVECLIENTID forKey:LIVE_AUTH_CLIENTID];
            [data setValue:repoItem.service_account_token forKey:LIVE_AUTH_REFRESH_TOKEN];
            [data writeToFile:filePath atomically:YES];
            
            // step3. recreate the liveConnectClient to use the new refresh token
            [app refreshLiveConnectionClient];
            
        }
            break;
        case kServiceSharepoint:
        {
            [NXKeyChain save:repoItem.service_account_id data:repoItem.service_account_token];
            repoItem.service_account_token = repoItem.service_account_id;
        }
            break;
            
        default:
            break;
    }
}

#pragma mark

- (NXBoundService*)getICloudDriveService {
    NXBoundService* iCloudDrive = nil;
    for (NXBoundService* service in _boundServices) {
        if ([service.service_type intValue] == kServiceICloudDrive) {
            iCloudDrive = service;
            break;
        }
    }
    
    assert(iCloudDrive);
    
    return iCloudDrive;
}


- (NSURL *)getContentStoreURL:(NSString *)contentType {
    NSURL *documentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    documentURL = [documentURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", CACHERMS, _profile.userId] isDirectory:YES];
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentURL.path]) {
        
        NSError *error;
        BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:documentURL withIntermediateDirectories:YES attributes:nil error:&error];
        if (!rt) {
            NSLog(@"create folder failed, %@, %@", documentURL, error);
            return nil;
        }

    }
    documentURL = [documentURL URLByAppendingPathComponent:contentType];
    return documentURL;
}

-(NSString *)getUserDataAESKey {
    NSString *sid = _profile.userId;
    NSString *aseStoreKey = [[NSString alloc] initWithFormat:@"%@-AESKEY", sid];
    // step2. store password in keychain, key is account_id
    NSString *aesKey = (NSString *)[NXKeyChain load:aseStoreKey];
    if (aesKey == nil) {
        aesKey = [[NSUUID UUID] UUIDString];
        [NXKeyChain save:aseStoreKey data:(id)aesKey];
        
    }
    return aesKey;
        
}

#pragma mark - Service root folder operation

- (NXFileBase *) getRootFolderForService:(NXBoundService *)service {
    NSString *key = [NXCommonUtils getServiceFolderKeyForFolderDirectory:service];
    return self.serviceRootFolderDict[key];
}

- (NXFileBase *) getRootFolderForServiceDictKey:(NSString *)key {
    return self.serviceRootFolderDict[key];
}

- (void)addRootFolderInDictionaryForService:(NXBoundService *)service
{
    if ([self.serviceRootFolderDict objectForKey:[NXCommonUtils getServiceFolderKeyForFolderDirectory:service]]) {
        return;
    }
    
    NXFileBase *rootFolder = [NXCacheManager getDirectory:service.service_type.intValue serviceAccountId:service.service_account_id];
    if (rootFolder == nil) {
        rootFolder = [NXFolder createRootFolder];
    }
    [self.serviceRootFolderDict setObject:rootFolder forKey:[NXCommonUtils getServiceFolderKeyForFolderDirectory:service]];
}

- (void) removeRootFolderInDictionaryForService:(NXBoundService *)service {
    NSString *key = [NXCommonUtils getServiceFolderKeyForFolderDirectory:service];
    [self.serviceRootFolderDict removeObjectForKey:key];
}

#pragma mark  - SETTER/GETTER

- (NSMutableDictionary *)serviceRootFolderDict {
    if (_serviceRootFolderDict == nil) {
        _serviceRootFolderDict = [[NSMutableDictionary alloc] init];
    }
    return _serviceRootFolderDict;
}

@end
