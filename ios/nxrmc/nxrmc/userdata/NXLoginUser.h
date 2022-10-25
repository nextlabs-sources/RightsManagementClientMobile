//
//  LoginUser.h
//  nxrmc
//
//  Created by Kevin on 15/4/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXRMCDef.h"
#import "NXRMCStruct.h"
#import "NXProfile.h"
#import "NXFileBase.h"
#import "NXBoundService.h"


@interface NXLoginUser : NSObject

@property(readonly, strong) NXProfile* profile;
@property(strong) NSMutableArray* boundServices;
@property(nonatomic, strong) NSMutableDictionary *serviceRootFolderDict;

+ (NXLoginUser*)sharedInstance;

- (void)loginWithUser:(NXProfile *)profile;

- (void)logOut;
- (BOOL)isLogInState;
- (BOOL)isAutoLogin;
- (void) loadUserAccountData;

- (BOOL)addService:(ServiceType) type serviceAccount:(NSString *)sa serviceAccountId:(NSString *)sai serviceAccountToken:(NSString *)sat isAuthed:(BOOL) isAuthed displayName:(NSString *)displayName;


- (void)deleteService:(NXBoundService *) service;
- (void)updateService:(NXBoundService *) service;
- (void)updateService:(ServiceType) type serviceAccount:(NSString *)sa serviceAccountId:(NSString *)sai serviceAccountToken:(NSString *)sat isAuthed:(BOOL) isAuthed;
- (void)syncLocalServiceInfoWithAddedServices:(NSArray *)addedServices deletedServices:(NSArray *)deletedServices updatedServices:(NSArray *)updatedServices; // for sync service info use only
-(void) clearUpSDK:(ServiceType) serviceType appendData:(id) appendData;
- (NXBoundService *)getICloudDriveService;


- (NSURL *)getContentStoreURL:(NSString *)contentType;
- (NSString *)getUserDataAESKey;

- (NXFileBase *)getRootFolderForService:(NXBoundService *)service;
- (NXFileBase *)getRootFolderForServiceDictKey:(NSString *)key;

@end
