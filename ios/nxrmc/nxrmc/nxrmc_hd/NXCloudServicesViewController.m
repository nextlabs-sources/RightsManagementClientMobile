//
//  NXCloudServicesViewController.m
//  nxrmc
//
//  Created by Bill on 5/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXCloudServicesViewController.h"
#import "NXCloudAccountUserInforViewController.h"

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

@interface NXCloudServicesViewController ()<DBRestClientDelegate,LiveAuthDelegate,LiveOperationDelegate, NXCloudAccountUserInforViewControllerDelegate>
{
    ServiceType _serviceBindType;
    DBRestClient *_restClient;
    NXBoundService *_anotherUserOneDriveService;
}

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property(nonatomic, strong) MDCFocusView *focusView;
@end

@implementation NXCloudServicesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *service1 = [NSArray arrayWithObjects:NSLocalizedString(@"CLOUDSERVICE_DROPBOX", NULL), @"DropboxIcon", nil];
   // NSArray *service2 = [NSArray arrayWithObjects:NSLocalizedString(@"CLOUDSERVICE_SHAREPOINTONLINE", NULL), @"SharepointIcon", nil];
   // NSArray *service3 = [NSArray arrayWithObjects:NSLocalizedString(@"CLOUDSERVICE_SHAREPOINT", NULL), @"SharepointIcon", nil];
    NSArray *service4 = [NSArray arrayWithObjects:NSLocalizedString(@"CLOUDSERVICE_ONEDRIVE", NULL), @"OneDriveIcon", nil];
    NSArray *service5 = [NSArray arrayWithObjects:NSLocalizedString(@"CLOUDSERVICE_GOOGLEDRIVE", NULL), @"GoogleDriveIcon", nil];
    
    //NSArray *service6 = [NSArray arrayWithObjects:NSLocalizedString(@"CLOUDSERVICE_iCloudDrive", NULL), @"iCloudIcon", nil];
    _cloudServices = [NSArray arrayWithObjects:service1, service4, service5, nil];

    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    _serviceBindType = kServiceUnset;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectServiceFinished:) name:@"dropbox" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxBindCancel:) name:NOTIFICATION_DROP_BOX_CANCEL object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repoAdded:) name:NOTIFICATION_REPO_ADDED object:nil];
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showUserGuidView];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.splitViewController.navigationController.navigationBarHidden = YES;
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = NSLocalizedString(@"ADD_A_SERVICE", nil);
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)clickCancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cloudServices count];
}


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cloudservice"];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier: @"cloudservice"];
    }
    NSArray *service = [_cloudServices objectAtIndex:indexPath.row];
    cell.textLabel.text = [service objectAtIndex:0];
    cell.imageView.image = [UIImage imageNamed:[service objectAtIndex:1]];
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.focusView.focusViewFocused) {
        [self.focusView dismiss:nil];
    }
    
    if (![[NXNetworkHelper sharedInstance] isNetworkAvailable]) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"NETWORK_UNREACH_MESSAGE", NULL)];
        return;
    }
    switch (indexPath.row) {
        case 0:
        {
            _serviceBindType = kServiceDropbox;
            [[DBSession sharedSession] linkFromController:self];
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
        case 1:
        {
            NXOneDriveBoundCase cs = [self getOneDriveBoundedCase];
            AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
            if(cs == NXONEDRIVEBOUNDED_BY_CURRENTUSER)
            {
                [NXCommonUtils showAlertViewInViewController:self
                                                       title:NSLocalizedString(@"ALERTVIEW_TITLE", nil)
                                                     message:NSLocalizedString(@"ALERTVIEW_MESSAGE_MORE_ONEDRIVE", nil)];
                return;
            }
            else if(cs == NXONEDRIVEBOUNDED_BY_ANOTHERUSER)
            {
                NSLog(@"One Drive has bounded by another");
                if(app.liveClient.session)
                {
                    [app.liveClient logoutWithDelegate:self userState:@(NXONEDRIVEUSERSET_LOGOUTFORBOUNDING)];
                    [NXCommonUtils createWaitingViewInView:self.view];
                    return;
                }
            }
            [self oneDriveDoLogin];
        }
            break;
//        case kServiceSharepoint:
//        {
//            _serviceBindType = kServiceSharepoint;
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
        case 2:
        {
            _serviceBindType = kServiceGoogleDrive;

            GTMOAuth2ViewControllerTouch *authController;
            NSString *keychainItemName = [NXCommonUtils randomStringwithLength:GOOGLEDRIVEKEYCHAINITEMLENGTH];
            NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeDrive, nil];
            authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:[scopes componentsJoinedByString:@" "]
                                                                        clientID:GOOGLEDRIVECLIENTID
                                                                    clientSecret:GOOGLEDRIVECLIENTSECRET
                                                                keychainItemName:keychainItemName
                                                                        delegate:self
                                                                finishedSelector:@selector(viewController:finishedWithAuth:error:)];
            [NXCommonUtils createWaitingViewInView:self.view];
            //root viewcontroller is new becasue only this can make authController has a back button.
            UIViewController *rootController = [[UIViewController alloc] init];
            rootController.view.backgroundColor = [UIColor whiteColor];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootController];
            [nav pushViewController:authController animated:YES];
            
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        }
            break;
//        case kServiceICloudDrive:
//        {
//            _serviceBindType = kServiceICloudDrive;
//            //[[NXLoginUser sharedInstance] addService:kServiceICloudDrive serviceAccount:@"" serviceAccountId:@"" serviceAccountToken:nil isAuthed:YES];
//            [self.navigationController popViewControllerAnimated:YES];
//        }
//            break;
        default:
            break;
    }
}

#pragma mark - GoogleDrive Authentication delegate

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error {
    if (error == nil) {
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
        NSString *userId = [NSString stringWithFormat:@"%@",authResult.userID];
        __weak typeof(self) weakSelf = self;
        [self inputServiceDisplayName:^(id dispalyName) {
            if ([dispalyName isKindOfClass:[NSString class]]) {
                 [[NXLoginUser sharedInstance] addService:kServiceGoogleDrive serviceAccount:authResult.userEmail serviceAccountId:userId serviceAccountToken:viewController.keychainItemName isAuthed:YES displayName:dispalyName];
            }else
            {
                [[NXLoginUser sharedInstance] clearUpSDK:kServiceGoogleDrive appendData:viewController.keychainItemName];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [[strongSelf.view viewWithTag:8808] removeFromSuperview];
            }
           
        }];
        
    } else {
        [[self.view viewWithTag:8808] removeFromSuperview];
        [viewController.navigationController dismissViewControllerAnimated:NO completion:^{
            NSInteger errorCode = error.code;
            if (errorCode != -1000) {
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                     message:NSLocalizedString(@"GOOGLEDRIVE_SIGNIN_ERROR", NULL)];
            }else
            {
                if (_serviceBindType == kServiceGoogleDrive) {
                    _serviceBindType = kServiceUnset;
                }
            }
        }];
    }
}

#pragma mark - Dropbox DBRestClientDelegate
-(void) connectServiceFinished:(NSNotification*) notification {
    
    NSDictionary *inforDic = notification.userInfo;
    NSString *url = [[inforDic objectForKey:@"KEY_URL"] absoluteString];
    NSError *error = [inforDic objectForKey:@"KEY_ERROR"];
    if (error) {
        //failed;
    } else {
        if (_serviceBindType == kServiceDropbox) {
            NSDictionary *infor = [NXCommonUtils parseURLParams:url];
            NSString *usrid = [infor objectForKey:@"uid"];
            if (usrid) {
                _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:usrid];
                _restClient.delegate = self;
                [_restClient loadAccountInfo];
                [NXCommonUtils createWaitingViewInView:self.view];
            }
        }
    }
}

-(void) dropBoxBindCancel:(NSNotification *) notification
{
    //[self showUserGuidView];
    if (_serviceBindType == kServiceDropbox) {
        _serviceBindType = kServiceUnset;
    }
}

- (void) restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    NSLog(@"restClient loadedAccountInfo Success");
    MPOAuthCredentialConcreteStore* credentialStore = [[DBSession sharedSession] credentialStoreForUserId:info.userId];
    NSString *accountToken = [NSString stringWithFormat:@"%@%@%@", credentialStore.accessToken, NXSYNC_REPO_SPERATE_KEY, credentialStore.accessTokenSecret];
    __weak typeof(self) weakSelf = self;
    [self inputServiceDisplayName:^(id dispalyName) {
        if ([dispalyName isKindOfClass:[NSString class]]) {
            [[NXLoginUser sharedInstance] addService:kServiceDropbox serviceAccount:info.email serviceAccountId:info.userId serviceAccountToken:accountToken isAuthed:YES displayName:dispalyName];
        }else
        {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [[strongSelf.view viewWithTag:8808] removeFromSuperview];
        }
    }];

    
}

- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error{
    NSLog(@"restClient loadAccountInfoFailed");
    [[self.view viewWithTag:8808] removeFromSuperview];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.view viewWithTag:8808] removeFromSuperview];
        [NXCommonUtils showAlertViewInViewController:self
                                               title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                             message:NSLocalizedString(@"DROPBOX_SIGNIN_ERROR", NULL)];
    });
}

#pragma mark liveClient LiveAuthDelegate
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
    NSInteger iuserState = [((NSNumber*)userState) integerValue];
    if(iuserState == NXONEDRIVEUSERSET_LOGIN)
    {
        NSLog(@"login fail");
        [[self.view viewWithTag:8808] removeFromSuperview];
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.liveClient logout];
        if (error.code != 2) {
            [NXCommonUtils showAlertViewInViewController:self
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
    NSLog(@"liveOperationSucceeded userState = %@",operation.userState);
    if([operation.userState isEqualToString:@"get user info"])
    {
        NSLog(@"%@",operation.result);
        NSString *account = [operation.result objectForKey:@"name"];
        NSString *ID = [operation.result objectForKey:@"id"];
        
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        NSString *token = app.liveClient.session.refreshToken;
        __weak typeof(self) weakSelf = self;
        
        [self inputServiceDisplayName:^(id dispalyName) {
            if ([dispalyName isKindOfClass:[NSString class]]) {
                 [[NXLoginUser sharedInstance] addService:kServiceOneDrive serviceAccount:account serviceAccountId:ID serviceAccountToken:token isAuthed:YES displayName:dispalyName];
            }else
            {
                [[NXLoginUser sharedInstance] clearUpSDK:kServiceOneDrive appendData:nil];
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [[strongSelf.view viewWithTag:8808] removeFromSuperview];
            }
           
        }];
      
        
    }
}

-(void)liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation
{
    NSLog(@"liveOperationFailed userState = %@",operation.userState);
    if([operation.userState isEqualToString:@"get user info"])
    {
        [[self.view viewWithTag:8808] removeFromSuperview];
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.liveClient logout];
        [NXCommonUtils showAlertViewInViewController:self
                                               title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                             message:NSLocalizedString(@"ONEDRIVE_GETUSERINFO_FAIL", NULL)];
    }
}

#pragma mark get OneDrive account information
-(void)getOneDriveAccountInfo
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app.liveClient getWithPath:@"me"
                       delegate:self
                      userState:@"get user info"];
}

- (NXOneDriveBoundCase)getOneDriveBoundedCase
{
    NSArray* objects = [NXCommonUtils fetchData:TABLE_BOUNDSERVICE predicate:[NSPredicate predicateWithFormat:@"service_type=%@", @(kServiceOneDrive)]];
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
    _serviceBindType = kServiceOneDrive;
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    if(app.liveClient.session == nil)
    {
        [app.liveClient login:self
                       scopes:[NSArray arrayWithObjects:@"wl.signin", @"wl.basic", @"wl.offline_access", @"wl.skydrive",@"wl.emails", @"wl.skydrive_update", nil]
                     delegate:self
                    userState:[NSNumber numberWithInteger:NXONEDRIVEUSERSET_LOGIN]];
        if(![self.view viewWithTag:8808])
        {
            [NXCommonUtils createWaitingViewInView:self.view];
        }
    }
}
#pragma mark cloudAccountUserInfoVCDidPressCancelBtn
-(void) cloudAccountUserInfoVCDidPressCancelBtn:(NXCloudAccountUserInforViewController *) vc
{
    //[self showUserGuidView];
    if (_serviceBindType == kServiceSharepointOnline || _serviceBindType == kServiceSharepoint) {
        _serviceBindType = kServiceUnset;
    }
}
#pragma mark User Guid
-(void) showUserGuidView
{
//    AppDelegate *ad = [UIApplication sharedApplication].delegate;
//    if (ad.isFirstSignIn) {
//        NSInteger centerServiceIndex = _cloudServices.count / 2;
//        NSIndexPath *centerServiceIndexPath = [NSIndexPath indexPathForRow:centerServiceIndex inSection:0];
//        UITableViewCell *centerCell = [self.tableview cellForRowAtIndexPath:centerServiceIndexPath];
//        
//        CGRect placeHolderFrame = CGRectMake(centerCell.frame.origin.x + 10, centerCell.frame.origin.y, centerCell.frame.size.width - 20, centerCell.frame.size.height * _cloudServices.count);
//        NXFocusViewPlaceHolder *focusPH = [[NXFocusViewPlaceHolder alloc] initWithFrame:placeHolderFrame];
//        focusPH.holderView = self.tableview;
//        
//        if ([NXLoginUser sharedInstance].boundServices.count == 0) {
//            self.focusView = [MDCFocusView new];
//            self.focusView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.6f];
//            self.focusView.focalPointViewClass = [MDCSpotlightView class];
//            NXFocusViewUserGuidTitle *guidTitleView = [[NXFocusViewUserGuidTitle alloc] init];
//            guidTitleView.title = @"STEP 2.Select one repository here to bind.";
//            guidTitleView.orientation = kUserGuidViewOrientDown;
//            self.focusView.userGuidTitle = guidTitleView;
//            [self.focusView focus:focusPH, nil];
//        }
//    }
}

#pragma mark - repo notification 
-(void) repoAdded:(NSNotification *) notification
{
    [[self.view viewWithTag:8808] removeFromSuperview];
    
    if([notification.userInfo isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *addRepoResultDict = (NSDictionary *) notification.userInfo;
        if (addRepoResultDict[NOTIFICATION_REPO_ADDED_ERROR_KEY]) {  // error happens when user add repo info to local
            
            NSString *errorString = addRepoResultDict[NOTIFICATION_REPO_ADDED_ERROR_KEY];
            if ([errorString isEqualToString:RMS_ADD_REPO_ERROR_NET_ERROR] || [errorString isEqualToString:RMS_ADD_REPO_RMS_OTHER_ERROR]) {
                
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_ADD_REPO_SYNC_RMS_ERROR", nil)];
            }else if([errorString isEqualToString:RMS_ADD_REPO_DUPLICATE_NAME])
            {
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_ADD_REPO_ACCOUNT_DISPLAY_NAME_DUMPLICATE", nil)];
            }else if([errorString isEqualToString:RMS_ADD_REPO_ALREADY_EXIST])
            {
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_REPO_ACCOUNT_EXISTED", nil)];
            }
            
            return;
        }
        
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) inputServiceDisplayName:(void(^)(id))finishBlock
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                                                  message: NSLocalizedString(@"INPUT_REPO_NAME", NULL)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"name";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
    }];
        
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BOX_CANCEL", NULL) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSNumber * cancelNum = @444;
        finishBlock(cancelNum);
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BOX_OK", NULL) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * displayName = textfields[0];
        if ([displayName.text isEqualToString:@""]) {
            [self presentViewController:alertController animated:YES completion:nil];
            return;
        }
        finishBlock(displayName.text);
    }]];

    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
