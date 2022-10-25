//
//  NXAuthRepoHelperNew.m
//  nxrmc
//
//  Created by EShi on 8/10/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXRMCAuthRepoHelper.h"
#import "NXRepoAuthWorkerBase.h"

#import "NXDropBoxAuther.h"
#import "NXOneDriveAuther.h"
#import "NXGoogleDriveAuther.h"
#import "NXNetworkHelper.h"

@interface NXRMCAuthRepoHelper()<NXRepoAutherDelegate>
@property(nonatomic, strong) id<NXRepoAutherBase> authWorker;
@property(nonatomic, strong) authCompletion compBlock;  // note cycle ref
@property(nonatomic, strong) NXBoundService *authService;
@end

@implementation NXRMCAuthRepoHelper
+(instancetype) sharedInstance
{
    static NXRMCAuthRepoHelper* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NXRMCAuthRepoHelper alloc] init];
    });
    return sharedInstance;
}

- (void) authBoundService:(NXBoundService *) service inViewController:(UIViewController *) authViewController completion:(authCompletion) compBlock
{
    if (service.service_isAuthed.boolValue) {
        compBlock(nil, AUTH_ERROR_ALREADY_AUTHED);
        return;
    }
    
    if (![[NXNetworkHelper sharedInstance] isNetworkAvailable]) {
        compBlock(nil, AUTH_ERROR_NO_NETWORK);
        return;
    }
    
    self.compBlock = compBlock;
    self.authService = service;
    
    self.authWorker = [self authWorkerForService:service.service_type.integerValue];
    [self.authWorker authRepoInViewController:authViewController];
}

-(id<NXRepoAutherBase>) authWorkerForService:(ServiceType) serviceType
{
    id<NXRepoAutherBase> authWorker = nil;
    switch (serviceType) {
        case kServiceDropbox:
        {
            authWorker = [[NXDropBoxAuther alloc] init];
        }
            break;
        case kServiceOneDrive:
        {
            authWorker = [[NXOneDriveAuther alloc] init];
        }
            break;
        case kServiceGoogleDrive:
        {
            authWorker = [[NXGoogleDriveAuther alloc] init];
        }
            break;
        default:
            break;
    }
    return authWorker;
}

#pragma mark - NXRepoAutherDelegate
-(void) repoAuther:(id<NXRepoAutherBase>) repoAuther didFinishAuth:(NSDictionary *) authInfo
{
    
}
-(void) repoAuther:(id<NXRepoAutherBase>) repoAuther authFailed:(NSError *) error
{
    /// self.compBlock(nil, error);
}
-(void) repoAuthCanceled:(id<NXRepoAutherBase>) repoAuther
{
   /// self.compBlock(nil, )
}
@end
