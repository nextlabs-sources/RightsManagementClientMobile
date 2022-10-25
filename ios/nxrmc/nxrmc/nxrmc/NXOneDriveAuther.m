//
//  NXOneDriveAuther.m
//  nxrmc
//
//  Created by EShi on 8/5/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXOneDriveAuther.h"
#import <DropboxSDK/DropboxSDK.h>
#import "NXCommonUtils.h"
#import "NXRMCDef.h"
#import "NXLoginUser.h"
#import "AppDelegate.h"

typedef NS_ENUM(NSInteger, NXOneDriveBoundCase)
{
    NXONEDRIVEBOUNDED_UNSET = 0,
    NXONEDRIVEBOUNDED_BY_CURRENTUSER,
    NXONEDRIVEBOUNDED_BY_ANOTHERUSER,
};

typedef NS_ENUM(NSInteger, NXOneDriveUserSet)
{
    NXONEDRIVEUSERSET_UNSET = 0,
    NXONEDRIVEUSERSET_LOGIN,
    NXONEDRIVEUSERSET_LOGOUT,
    NXONEDRIVEUSERSET_LOGOUTFORBOUNDING,
};

@interface NXOneDriveAuther() <LiveAuthDelegate,LiveOperationDelegate>
@property(nonatomic, strong) NXBoundService *anotherUserOneDriveService;
@end

@implementation NXOneDriveAuther
-(instancetype) init
{
    self = [super init];
    if (self) {
        _repoType = kServiceOneDrive;
    }
    return self;
}
- (void) authRepoInViewController:(UIViewController *) vc
{
    self.authViewController = vc;
    
    NXOneDriveBoundCase cs = [self getOneDriveBoundedCase];
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    if(cs == NXONEDRIVEBOUNDED_BY_CURRENTUSER)
    {
        [NXCommonUtils showAlertViewInViewController:self.authViewController
                                               title:NSLocalizedString(@"ALERTVIEW_TITLE", nil)
                                             message:NSLocalizedString(@"ALERTVIEW_MESSAGE_MORE_ONEDRIVE", nil)];
        return;
    }
    else if(app.liveClient.session)
    {
        NSLog(@"One Drive has bounded by another");
        if(app.liveClient.session)
        {
            [app.liveClient logoutWithDelegate:self userState:@(NXONEDRIVEUSERSET_LOGOUTFORBOUNDING)];
            return;
        }
    }
    [self oneDriveDoLogin];

    
}

#pragma mark - liveClient LiveAuthDelegate
- (void) authCompleted:(LiveConnectSessionStatus)status
               session:(LiveConnectSession *)session
             userState:(id)userState
{
    NSInteger iuserState = [((NSNumber*)userState) integerValue];
    if(iuserState == NXONEDRIVEUSERSET_LOGIN)
    {
        [self getOneDriveAccountInfo];
    }
    else if(iuserState == NXONEDRIVEUSERSET_LOGOUTFORBOUNDING)
    {
        [self oneDriveDoLogin];
        if(_anotherUserOneDriveService)
        {
#pragma mark if it is need to delete the cache file and record file,now delete the all record for another user
            //delete record cache  file in database
            [NXCommonUtils deleteCacheFilesFromCoreDataForService:_anotherUserOneDriveService];
            
            // delete cache files.
            NSURL* url = [NXCacheManager getLocalUrlForServiceCache:(ServiceType)[_anotherUserOneDriveService.service_type intValue]serviceAccountId:_anotherUserOneDriveService.service_account_id];
            
            [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            // delete record in database
            [NXCommonUtils deleteServiceFromCoreData:_anotherUserOneDriveService];
        }
    }
}

- (void) authFailed:(NSError *)error
          userState:(id)userState
{
    [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
    
    NSInteger iuserState = [((NSNumber*)userState) integerValue];
    if(iuserState == NXONEDRIVEUSERSET_LOGIN)
    {
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.liveClient logout];
        if (error.code == 2) { // user cancel auth
            if ([self.delegate respondsToSelector:@selector(repoAuthCanceled:)]) {
                [self.delegate repoAuthCanceled:self];
            }
        }else
        {
            if ([self.delegate respondsToSelector:@selector(repoAuther:authFailed:)]) {
                [self.delegate repoAuther:self authFailed:error];
            }
        }
    }
    else if(iuserState == NXONEDRIVEUSERSET_LOGOUTFORBOUNDING)
    {
        if ([self.delegate respondsToSelector:@selector(repoAuther:authFailed:)]) {
            [self.delegate repoAuther:self authFailed:error];
        }
    }
}

#pragma mark  liveClient iveOperationDelegate
- (void) liveOperationSucceeded:(LiveOperation *)operation
{
    if([operation.userState isEqualToString:@"get user info"])
    {
        NSString *account = [operation.result objectForKey:@"name"];
        NSString *ID = [operation.result objectForKey:@"id"];
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        NSString *token = app.liveClient.session.refreshToken;
        [self.authViewController.navigationController popViewControllerAnimated:YES];
        
        NSDictionary *authInfoDict = @{AUTH_RESULT_ACCOUNT:account, AUTH_RESULT_ACCOUNT_ID:ID, AUTH_RESULT_ACCOUNT_TOKEN:token};
        if ([self.delegate respondsToSelector:@selector(repoAuther:didFinishAuth:)]) {
            [self.delegate repoAuther:self didFinishAuth:authInfoDict];
        }
    }
}

-(void)liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation
{
    if([operation.userState isEqualToString:@"get user info"])
    {
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.liveClient logout];
        if ([self.delegate respondsToSelector:@selector(repoAuther:authFailed:)]) {
            [self.delegate repoAuther:self authFailed:error];
        }
    }
}

#pragma mark - OneDrive help method
-(void)getOneDriveAccountInfo
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app.liveClient getWithPath:@"me"
                       delegate:self
                      userState:@"get user info"];
}

- (NXOneDriveBoundCase)getOneDriveBoundedCase
{
    NSArray* objects = [NXCommonUtils fetchData:TABLE_BOUNDSERVICE predicate:[NSPredicate predicateWithFormat:@"service_type=%@ AND service_isAuthed=%@", @(kServiceOneDrive), [NSNumber numberWithBool:YES]]];
    if(objects == nil || objects.count == 0)
    {
        return NXONEDRIVEBOUNDED_UNSET;
    }
    NXBoundService *service = [objects lastObject];
    if(service.user_id.integerValue == [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId].integerValue)
    {
        return NXONEDRIVEBOUNDED_BY_CURRENTUSER;
    }
    else
    {
        _anotherUserOneDriveService = service;
        return NXONEDRIVEBOUNDED_BY_ANOTHERUSER;
    }
}

- (void)oneDriveDoLogin
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    if(app.liveClient.session == nil)
    {
        [app.liveClient login:self.authViewController
                       scopes:[NSArray arrayWithObjects:@"wl.signin", @"wl.basic", @"wl.offline_access", @"wl.skydrive",@"wl.emails", @"wl.skydrive_update", nil]
                     delegate:self
                    userState:[NSNumber numberWithInteger:NXONEDRIVEUSERSET_LOGIN]];
    }
}

@end
