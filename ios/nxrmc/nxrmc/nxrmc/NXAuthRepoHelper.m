//
//  NXAuthRepoHelper.m
//  nxrmc
//
//  Created by EShi on 7/28/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXAuthRepoHelper.h"
#import <DropboxSDK/DropboxSDK.h>
#import "NXCommonUtils.h"
#import "NXRMCDef.h"
#import "NXLoginUser.h"
#import "AppDelegate.h"
#import "NXCacheManager.h"
#import "NXNetworkHelper.h"


#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "MDCFocusView.h"
#import "MDCSpotlightView.h"
#import "NXFocusViewPlaceHolder.h"

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



@interface NXAuthRepoHelper()<DBRestClientDelegate,LiveAuthDelegate,LiveOperationDelegate>
@property(nonatomic, strong) authCompletion finishBlock;
@property(nonatomic, weak) UIViewController *authViewController;
@property(nonatomic, strong) NXBoundService *authService;
@property(nonatomic, strong) NXBoundService *anotherUserOneDriveService;

@property(nonatomic, strong) DBRestClient *restClient;
@end

@implementation NXAuthRepoHelper
+(instancetype) sharedInstance
{
    static NXAuthRepoHelper* sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[NXAuthRepoHelper alloc] init];
    });
    return sharedInstance;
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) finishServiceAuth:(NSString *) serviceToken;
{
    
    self.authService.service_isAuthed = [NSNumber numberWithBool:YES];
    self.authService.service_account_token = serviceToken;
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app.managedObjectContext save:nil];
    
}

-(void) resetAuthData
{
    // reset temp data
    self.finishBlock = nil;
    self.authViewController = nil;
    self.authService = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
  //  self.restClient = nil;
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
    
    // step1. store the auth data
    self.finishBlock = compBlock;
    self.authViewController = authViewController;
    self.authService = service;
    
    // step2. do auth according to service
    [self authForService:service inViewController:authViewController];
}
    
-(void) authForService:(NXBoundService *) service inViewController:(UIViewController *) authViewController
{
    switch (service.service_type.integerValue) {
        case kServiceDropbox:
        {
         //   _serviceBindType = kServiceDropbox;
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectServiceFinished:) name:@"dropbox" object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxBindCancel:) name:NOTIFICATION_DROP_BOX_CANCEL object:nil];
            
            [[DBSession sharedSession] linkFromController:authViewController];
        }
            break;
//        case kServiceSharepointOnline:
//        {
//            _serviceBindType = kServiceSharepointOnline;
//            
//            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            NXCloudAccountUserInforViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"CloudAccountUserInfoVC"];
//            vc.delegate = self;
//            vc.serviceBindType = kServiceSharepointOnline;
//            vc.dismissBlock = ^(BOOL res){
//                if (res) {
//                    [self.navigationController popViewControllerAnimated:YES];
//                }else
//                {
//                    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_REPO_ACCOUNT_EXISTED", nil)];
//                }
//                
//            };
//            vc.modalPresentationStyle = UIModalPresentationFormSheet;
//            [self.navigationController presentViewController:vc animated:YES completion:nil];
//        }
//            break;
        case kServiceOneDrive:
        {
            NXOneDriveBoundCase cs = [self getOneDriveBoundedCase];
            AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
            if(cs == NXONEDRIVEBOUNDED_BY_CURRENTUSER)
            {
                [NXCommonUtils showAlertViewInViewController:authViewController
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
                    [NXCommonUtils createWaitingViewInView:authViewController.view];
                    return;
                }
            }
            [self oneDriveDoLogin];
        }
            break;
//        case kServiceSharepoint:
//        {
//           
//            
//            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            NXCloudAccountUserInforViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"CloudAccountUserInfoVC"];
//            vc.serviceBindType = kServiceSharepoint;
//            vc.delegate = self;
//            vc.dismissBlock = ^(BOOL res){
//                if (res) {
//                    [self.navigationController popViewControllerAnimated:YES];
//                    
//                }else
//                {
//                    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_REPO_ACCOUNT_EXISTED", nil)];
//                }
//            };
//            vc.modalPresentationStyle = UIModalPresentationFormSheet;
//            [self.navigationController presentViewController:vc animated:YES completion:nil];
//        }
//            break;
        case kServiceGoogleDrive:
        {
                       
            GTMOAuth2ViewControllerTouch *authController;
            NSString *keychainItemName = [NXCommonUtils randomStringwithLength:GOOGLEDRIVEKEYCHAINITEMLENGTH];
            NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeDrive, nil];
            authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:[scopes componentsJoinedByString:@" "]
                                                                        clientID:GOOGLEDRIVECLIENTID
                                                                    clientSecret:GOOGLEDRIVECLIENTSECRET
                                                                keychainItemName:keychainItemName
                                                                        delegate:self
                                                                finishedSelector:@selector(viewController:finishedWithAuth:error:)];
      
            //root viewcontroller is new becasue only this can make authController has a back button.
            UIViewController *rootController = [[UIViewController alloc] init];
            rootController.view.backgroundColor = [UIColor whiteColor];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootController];
            [nav pushViewController:authController animated:YES];
            
            [authViewController.navigationController presentViewController:nav animated:YES completion:nil];
        }
        break;
    }

}

#pragma mark - GoogleDrive Authentication delegate
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error {
    if (error == nil) {
        [self.authViewController.navigationController dismissViewControllerAnimated:NO completion:nil];
        if (! [self.authService.service_account_id isEqualToString:authResult.userID]) { // if not same account, return show error
             [NXCommonUtils showAlertViewInViewController:self.authViewController title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_SYNC_REPO_ACCOUNT_NOT_SAME_WITH_RMS", nil)];
            
            return;
        }
        
        [[NXLoginUser sharedInstance] updateService:kServiceGoogleDrive serviceAccount:self.authService.service_account serviceAccountId:self.authService.service_account_id serviceAccountToken:viewController.keychainItemName isAuthed:YES];

        [self finishServiceAuth:viewController.keychainItemName];
        [self.authViewController.navigationController popViewControllerAnimated:YES];
        self.finishBlock(nil, nil);
        [self resetAuthData];
        
    } else {
        [viewController.navigationController dismissViewControllerAnimated:NO completion:^{
            NSInteger errorCode = error.code;
            if (errorCode != -1000) {
                [NXCommonUtils showAlertViewInViewController:self.authViewController title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                     message:NSLocalizedString(@"GOOGLEDRIVE_SIGNIN_ERROR", NULL)];
                
                self.finishBlock(nil, AUTH_ERROR_AUTH_FAILED);
                
            }else
            {
                self.finishBlock(nil, AUTH_ERROR_AUTH_CANCELED); 
            }
            [self resetAuthData];
        }];
    }
}

#pragma mark - Dropbox DBRestClientDelegate
-(void) connectServiceFinished:(NSNotification*) notification {
    
    if (self.finishBlock == nil) {  // finishBlock is nill, means the DropBox auth is not fired by NXAuthRepoHelper, ignore it
        return;
    }
    
    NSDictionary *inforDic = notification.userInfo;
    NSString *url = [[inforDic objectForKey:@"KEY_URL"] absoluteString];
    NSError *error = [inforDic objectForKey:@"KEY_ERROR"];
    if (error) {
        self.finishBlock(nil, AUTH_ERROR_AUTH_FAILED);
        [self resetAuthData];
        
    } else {
            NSDictionary *infor = [NXCommonUtils parseURLParams:url];
            NSString *usrid = [infor objectForKey:@"uid"];
            if (usrid) {
                _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:usrid];
                _restClient.delegate = self;
                [_restClient loadAccountInfo];
                [NXCommonUtils createWaitingViewInView:self.authViewController.view];
            }
    }
}

-(void) dropBoxBindCancel:(NSNotification *) notification
{
     [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
    self.finishBlock(nil, AUTH_ERROR_AUTH_CANCELED);
    [self resetAuthData];
}

- (void) restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    NSLog(@"restClient loadedAccountInfo Success");
    [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
    
    MPOAuthCredentialConcreteStore* credentialStore = [[DBSession sharedSession] credentialStoreForUserId:info.userId];
    NSString *accountToken = [NSString stringWithFormat:@"%@%@%@", credentialStore.accessToken, NXSYNC_REPO_SPERATE_KEY, credentialStore.accessTokenSecret];
    
    if (! [info.userId isEqualToString:self.authService.service_account_id]) {
        [NXCommonUtils showAlertViewInViewController:self.authViewController title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_SYNC_REPO_ACCOUNT_NOT_SAME_WITH_RMS", nil)];
        self.finishBlock(nil, AUTH_ERROR_ACCOUNT_DIFF_FROM_RMS);
        [self resetAuthData];
        return;
    }
    
    [[NXLoginUser sharedInstance] updateService:kServiceDropbox serviceAccount:info.email serviceAccountId:info.userId serviceAccountToken:accountToken isAuthed:YES];

    [self finishServiceAuth:accountToken];
    self.finishBlock(nil, nil);
    [self resetAuthData];
    
}

- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error{
    NSLog(@"restClient loadAccountInfoFailed");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
        [NXCommonUtils showAlertViewInViewController:self.authViewController
                                               title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                             message:NSLocalizedString(@"DROPBOX_SIGNIN_ERROR", NULL)];
    });
}

#pragma mark - liveClient LiveAuthDelegate
- (void) authCompleted:(LiveConnectSessionStatus)status
session:(LiveConnectSession *)session
userState:(id)userState
{
    NSInteger iuserState = [((NSNumber*)userState) integerValue];
    if(iuserState == NXONEDRIVEUSERSET_LOGIN)
    {
        NSLog(@"login ok");
        [self getOneDriveAccountInfo];
    }
    else if(iuserState == NXONEDRIVEUSERSET_LOGOUTFORBOUNDING)
    {
        NSLog(@"first log out then bound again ok");
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
        NSLog(@"login fail");
        [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.liveClient logout];
        if (error.code != 2) {
            [NXCommonUtils showAlertViewInViewController:self.authViewController
                                                   title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                 message:NSLocalizedString(@"ONEDRIVE_GETUSERINFO_FAIL", NULL)];
            
        }
    }
    else if(iuserState == NXONEDRIVEUSERSET_LOGOUTFORBOUNDING)
    {
        NSLog(@"first log out then bound again ,but log out fail");
    }
}

#pragma mark  liveClient iveOperationDelegate
- (void) liveOperationSucceeded:(LiveOperation *)operation
{
     [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
    NSLog(@"liveOperationSucceeded userState = %@",operation.userState);
    if([operation.userState isEqualToString:@"get user info"])
    {
        NSLog(@"%@",operation.result);
   
        NSString *ID = [operation.result objectForKey:@"id"];
        if (![ID isEqualToString:self.authService.service_account_id]) {
            
            [NXCommonUtils showAlertViewInViewController:self.authViewController title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_SYNC_REPO_ACCOUNT_NOT_SAME_WITH_RMS", nil)];
            [[NXLoginUser sharedInstance] clearUpSDK:kServiceOneDrive appendData:nil];
            self.finishBlock(nil, AUTH_ERROR_ACCOUNT_DIFF_FROM_RMS);
            [self.authViewController.navigationController popViewControllerAnimated:YES];
            [self resetAuthData];

            return;
        }
        
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        NSString *token = app.liveClient.session.refreshToken;
        
        [[NXLoginUser sharedInstance] updateService:kServiceOneDrive serviceAccount:self.authService.service_account serviceAccountId:self.authService.service_account_id serviceAccountToken:token isAuthed:YES];

       
        [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
        [self.authViewController.navigationController popViewControllerAnimated:YES];
        self.finishBlock(nil, nil);
        [self resetAuthData];

    }
}

-(void)liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation
{
     [[self.authViewController.view viewWithTag:8808] removeFromSuperview];
    NSLog(@"liveOperationFailed userState = %@",operation.userState);
    if([operation.userState isEqualToString:@"get user info"])
    {
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.liveClient logout];
        [NXCommonUtils showAlertViewInViewController:self.authViewController
                                               title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                             message:NSLocalizedString(@"ONEDRIVE_GETUSERINFO_FAIL", NULL)];
         self.finishBlock(nil, AUTH_ERROR_AUTH_FAILED);
        [self resetAuthData];

    }
}
//
//#pragma mark get OneDrive account information
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
        if(![self.authViewController.view viewWithTag:8808])
        {
            [NXCommonUtils createWaitingViewInView:self.authViewController.view];
        }
    }
}

@end
