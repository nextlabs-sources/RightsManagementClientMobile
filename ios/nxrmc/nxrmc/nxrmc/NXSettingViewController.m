 //
//  NXSettingViewController.m
//  nxrmc
//
//  Created by EShi on 12/31/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXSettingViewController.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"

#import "NXCloudServicesViewController.h"
#import "AppDelegate.h"
#import  <DropboxSDK/DropboxSDK.h>
#import "GTMOAuth2ViewControllerTouch.h"
#import "NXRepositoryInfoViewController.h"
#import "NXSyncRepoHelper.h"
#import "NXGetRepositoryDetailsAPI.h"
#import "NXRemoveRepositoryAPI.h"
#import "NXAuthRepoHelper.h"

#import "NXOpenSSL.h"


#define KEY_TITLE   @"title"
#define KEY_VALUE   @"value"
#define DATA_PICKER_DAY_COLUMN_NAME @"DAY"
#define DATA_PICKER_HOUR_COLUMN_NAME @"HOUR"
#define CLEANCACHE 10000

@interface NXSettingViewController ()<UITableViewDelegate, UITableViewDataSource, LiveAuthDelegate>
@property(nonatomic, strong) UITableView *settingTableView;
@property(nonatomic, strong) UITableViewCell *syncCell;
@property(nonatomic) BOOL syncFinished;
@property(nonatomic, strong) NSArray *icons;
@property(nonatomic, strong) NSArray *sectionTitles;
@property(nonatomic, strong) NSMutableArray *cloudServices;
@property(nonatomic, strong) NSString *sessionTimeOutString;

@property(nonatomic, strong) NSMutableArray *dataPickerhoursArray;
@property(nonatomic, strong) NSMutableArray *dataPickerDaysArray;
@property(nonatomic, strong) NSMutableDictionary *dataPickerRowDict;
@end

static NSString *SYNC_REPO_CELL_IDENTITY = @"SYNC_REPO_CELL_IDENTITY";

@implementation NXSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _syncFinished = YES;
    _settingTableView = [[UITableView alloc] init];
    [self.view addSubview:_settingTableView];
    _settingTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_settingTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_settingTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_settingTableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_settingTableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    _settingTableView.delegate = self;
    _settingTableView.dataSource = self;
    [_settingTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _settingTableView.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.99 alpha:1.0];
    
    _icons = [NSArray arrayWithObjects:@"DropboxIcon", @"SharepointIcon", @"SharepointIcon", @"OneDriveIcon", @"GoogleDriveIcon", @"iCloudIcon", nil];
    
    _sectionTitles = [NSArray arrayWithObjects:@"", NSLocalizedString(@"ACCOUNT_CONNECTED_SERVICES", nil), @"", nil];

    [self updateSessionTimeOutString];
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToRepositoryChanged:) name:NOTIFICATION_REPO_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToRepositoryChanged:) name:NOTIFICATION_REPO_DELETED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToRepositoryChanged:) name:NOTIFICATION_REPO_CHANGED object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.title = NSLocalizedString(@"SET_TITLE", nil);
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    
    _cloudServices = [NSMutableArray arrayWithArray:[NXLoginUser sharedInstance].boundServices];
    [self.settingTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.shouldShowAddAcountPage) {
        self.shouldShowAddAcountPage = NO;
        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        NXCloudServicesViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"CloudServicesInfoVc"];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark SET/GET
-(NSMutableArray *) dataPickerDaysArray
{
    if (_dataPickerDaysArray == nil) {
        _dataPickerDaysArray = [[NSMutableArray alloc] init];
        for (NSInteger day = 0; day <= 100; ++day) {
            NSString *dayStr = nil;
            if (day < 2) {
                dayStr = [NSString stringWithFormat:@"%ld %@", (long)day, NSLocalizedString(@"DAY", nil)];
            }else
            {
                dayStr = [NSString stringWithFormat:@"%ld %@", (long)day, NSLocalizedString(@"DAYS", nil)];
            }
            [_dataPickerDaysArray addObject:dayStr];
        }
    }
    
    return _dataPickerDaysArray;
}

-(NSMutableArray *) dataPickerhoursArray
{
    if (_dataPickerhoursArray == nil) {
        _dataPickerhoursArray = [[NSMutableArray alloc] init];
        for (NSInteger hour = 0; hour < 24; ++hour) {
            NSString *hourStr = nil;
            if (hour < 2) {
                hourStr = [NSString stringWithFormat:@"%ld %@", (long) hour, NSLocalizedString(@"HOUR", nil)];
            }else
            {
                hourStr = [NSString stringWithFormat:@"%ld %@", (long) hour, NSLocalizedString(@"HOURS", nil)];
            }
            [_dataPickerhoursArray addObject:hourStr];
        }
    }
    return _dataPickerhoursArray;
}

-(NSMutableDictionary *) dataPickerRowDict
{
    if (_dataPickerRowDict == nil) {
        _dataPickerRowDict = [[NSMutableDictionary alloc] init];
        [_dataPickerRowDict setObject:self.dataPickerDaysArray forKey:DATA_PICKER_DAY_COLUMN_NAME];
        [_dataPickerRowDict setObject:self.dataPickerhoursArray forKey:DATA_PICKER_HOUR_COLUMN_NAME];
    }
    return _dataPickerRowDict;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:  // session time out
        {
//            [self showSessionTimeoutPickerView];
        }
            break;
        case 1:  // repository
        {
            if (indexPath.row == self.cloudServices.count) {  // Add repo
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                NXCloudServicesViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"CloudServicesInfoVc"];
                [self.navigationController pushViewController:vc animated:YES];

            }else  // kinds of repos
            {
                NXBoundService *boundService = _cloudServices[indexPath.row];
                if (boundService.service_isAuthed.boolValue) {
                    NXRepositoryInfoViewController *repoInfoVC = [[NXRepositoryInfoViewController alloc] initWithBoundService:boundService];
                    [self.navigationController pushViewController:repoInfoVC animated:YES];

                }else
                {
                    __weak  typeof(self) weakSelf = self;
                    [[NXAuthRepoHelper sharedInstance] authBoundService:boundService inViewController:self completion:^(id userAppendData, NSError *error) {
                        if(error == nil)
                        {
                            __strong NXSettingViewController *strongSelf = weakSelf;
                            [strongSelf.settingTableView reloadData];
                        }
                    }];
                }
            }
        }
            break;
        case 2: // sync repo
        {
            [self.syncCell setUserInteractionEnabled:NO]; // Disable user quick click sync button
            self.syncFinished = NO;
            [self rotateSyncCell];
            
            [[NXSyncRepoHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getRESTCacheURL] mustAllSuccess:YES Complection:^(id object, NSError *error) {
                if (error) {
                    // Update the sync date
                    NSDate *syncDate = [NSDate date];
                    NSString *syncDateKey = [NXCommonUtils userSyncDateDefaultsKey];
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSString *strSyncDate = @"Update failed:";
                    strSyncDate = [strSyncDate stringByAppendingString:[dateFormatter stringFromDate:syncDate]];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:strSyncDate forKey:syncDateKey];
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.syncFinished = YES;
                        [self.settingTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                    });
                    
                }else // only if pervious failed REST request upload success, then start sync repo from RMS
                {
                    NXGetRepositoryDetailsAPIRequest *getRepoAPI = [[NXGetRepositoryDetailsAPIRequest alloc] init];
                    [getRepoAPI requestWithObject:nil Completion:^(id response, NSError *error) {
                        if (error) {
                            // Update the sync date
                            NSDate *syncDate = [NSDate date];
                            NSString *syncDateKey = [NXCommonUtils userSyncDateDefaultsKey];
                            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                            NSString *strSyncDate = @"Update failed:";
                            strSyncDate = [strSyncDate stringByAppendingString:[dateFormatter stringFromDate:syncDate]];
                            
                            [[NSUserDefaults standardUserDefaults] setObject:strSyncDate forKey:syncDateKey];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.syncFinished = YES;
                                [self.settingTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                            });
                            
                        }else
                        {
                            // 1. check local repo info and remote info, do add or delete
                            NXGetRepositoryDetailsAPIResponse * getRepoResponse = (NXGetRepositoryDetailsAPIResponse *) response;
                            if (getRepoResponse.rmsStatuCode == NXRMS_STATUS_CODE_SUCCESS) {
                                NSMutableArray *addRMCReposList = nil;
                                NSMutableArray *delRMCReposList = nil;
                                NSMutableArray *updateRMCReposList = nil;
                                
                                [[NXSyncRepoHelper sharedInstance] intergateRMSRepoInfoWithRMSRepoDetail:getRepoResponse addRepoList:&addRMCReposList delRepoList:&delRMCReposList updateRepoList:&updateRMCReposList];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{ // core data not thread safe, return to main queue
                                    self.syncFinished = YES;
                                    
                                    [[NXLoginUser sharedInstance] syncLocalServiceInfoWithAddedServices:addRMCReposList deletedServices:delRMCReposList updatedServices:updateRMCReposList];
                                    
                                    // Update the sync date
                                    NSDate *syncDate = [NSDate date];
                                    NSString *syncDateKey = [NXCommonUtils userSyncDateDefaultsKey];
                                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                    NSString *strSyncDate = @"Last update time: ";
                                    strSyncDate = [strSyncDate stringByAppendingString:[dateFormatter stringFromDate:syncDate]];
                                    [[NSUserDefaults standardUserDefaults] setObject:strSyncDate forKey:syncDateKey];
                                    
                                    [self.settingTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                                });
                                
                            }  // getRepoResponse.rmsStatuCode == NXRMS_STATUS_CODE_SUCCESS
                        }
                    }];
                }
            }];

        }
            break;
        case 3:  // clean cache
        {
            NSNumber *cacheSize = [NXCommonUtils calculateCachedFileSize];
            NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
            formatter.allowsNonnumericFormatting = NO;
            formatter.countStyle = NSByteCountFormatterCountStyleBinary;
            NSString *strSize = [formatter stringFromByteCount:cacheSize.longLongValue];
            NSString *info = [NSString stringWithFormat:@"%@: %@. %@", NSLocalizedString(@"CACHEFILESIZE", NULL), strSize, NSLocalizedString(@"", NULL)];
            UIAlertView *view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:info delegate:self cancelButtonTitle:NSLocalizedString(@"BOX_CANCEL", NULL) otherButtonTitles:NSLocalizedString(@"BOX_OK", NULL), nil];
            view.delegate = self;
            view.tag = CLEANCACHE;
            [view show];

        }
            break;
        default:
            break;
    }
}
#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:  // Time out
        {
            return 1;
        }
            break;
        case 1:  // Add Repository
        {
            return self.cloudServices.count + 1;
        }
            break;
        case 2:  // sync repo
        {
            return 1;
        }
            break;
        case 3:  // clean cache
        {
            return 1;
        }
            break;
        default:
            break;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(20, 8, 320, 20);
    myLabel.font = [UIFont boldSystemFontOfSize:14];
   // myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    UIView *headerView = [[UIView alloc] init];
    
    [headerView addSubview:myLabel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {  // session time out
        static NSString *TIME_OUT_CELL_IDENTITY = @"TIME_OUT_CELL_IDENTITY";
        cell = [tableView dequeueReusableCellWithIdentifier:TIME_OUT_CELL_IDENTITY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TIME_OUT_CELL_IDENTITY];
            
            
        }
        cell.textLabel.text = NSLocalizedString(@"RMC_SESSION_TIMEOUT", nil);
        cell.detailTextLabel.text = self.sessionTimeOutString;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
    }else if(indexPath.section == 1)  // repository
    {
        static NSString *REPOSITORY_CELL_IDENTITY = @"REPOSITORY_CELL_IDENTITY";
        cell = [tableView dequeueReusableCellWithIdentifier:REPOSITORY_CELL_IDENTITY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:REPOSITORY_CELL_IDENTITY];
            
        }
        
        if (indexPath.row == [_cloudServices count]) {  // add repo
            cell.textLabel.text = NSLocalizedString(@"ADD_A_SERVICE", NULL);
            cell.detailTextLabel.text = nil;
            cell.imageView.image = [UIImage imageNamed:@"AddRepositoryBlue"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
        }else { // kinds of repos
            NXBoundService *service = [_cloudServices objectAtIndex:indexPath.row];
            cell.textLabel.text = service.service_alias;
            cell.detailTextLabel.text = service.service_account;
            ServiceType t = (ServiceType)[service.service_type integerValue];
            NSString *iconstring = [_icons objectAtIndex:t];
            if (service.service_isAuthed.boolValue) {
                cell.imageView.image = [UIImage imageNamed:iconstring];
            }else
            {
                cell.imageView.image = [UIImage imageNamed:@"HighPriority"];
            }
            
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

    }else if(indexPath.section == 2) // sync repo
    {
        cell = [tableView dequeueReusableCellWithIdentifier:SYNC_REPO_CELL_IDENTITY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:SYNC_REPO_CELL_IDENTITY];
            self.syncCell = cell;
        }
        
        cell.textLabel.text = NSLocalizedString(@"SYNC_REPO_INOF", NULL);
        cell.imageView.image = [UIImage imageNamed:@"FileSync"];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        
        NSString *syncDateKey = [NXCommonUtils userSyncDateDefaultsKey];
        NSString *syncString = [[NSUserDefaults standardUserDefaults] objectForKey:syncDateKey];
        if (syncString) {
            cell.detailTextLabel.text = syncString;
            
        }else
        {
            cell.detailTextLabel.text = NSLocalizedString(@"NOT_SYNC_YET", NULL);
        }
        
        if ([syncString containsString:@"failed"]) {
            
            cell.detailTextLabel.textColor = [UIColor redColor];
            
        }else
        {
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        

    }
    else if(indexPath.section == 3)  // clean cache
    {
        static NSString *CELAN_CACHE_CELL_IDENTITY = @"CLEAN_CACHE_CELL_IDENTITY";
        cell = [tableView dequeueReusableCellWithIdentifier:CELAN_CACHE_CELL_IDENTITY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELAN_CACHE_CELL_IDENTITY];
            
        }
        
        cell.textLabel.text = NSLocalizedString(@"CLEANCACHE", NULL);
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor blueColor];
        cell.imageView.image = nil;
        cell.detailTextLabel.text = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 2) {
        
        return 0;
    }else
    {
        return 30;
    }
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.section == 1) {
        NXBoundService *service = [_cloudServices objectAtIndex:indexPath.row];
        [[NXLoginUser sharedInstance] deleteService:service];
    }
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1 && indexPath.row < [_cloudServices count]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}
#pragma mark private method
-(void) showCoverView
{
    UIView *coverView = [[UIView alloc] init];
    coverView.translatesAutoresizingMaskIntoConstraints = NO;
    coverView.tag = ACCOUNT_PAGE_COVER_VIEW_TAG;
    coverView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];;
    UITapGestureRecognizer *tap= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(coverViewhandeTap:)];
    [coverView addGestureRecognizer:tap];
    [self.view addSubview:coverView];
    
    NSDictionary *viewBounds = @{@"coverView":coverView};
    
    NSArray *constraintH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[coverView]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:viewBounds];
    NSArray *constraintV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[coverView]|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:viewBounds];
    [self.view addConstraints:constraintH];
    [self.view addConstraints:constraintV];
}

-(void) rotateSyncCell
{
    if (self.syncCell) {
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            
            [self.syncCell.imageView setTransform:CGAffineTransformRotate(self.syncCell.imageView.transform, M_PI)];
            
        } completion:^(BOOL finished) {
            if (!self.syncFinished) {
                [self rotateSyncCell];
            }else
            {
                NSString *syncDateKey = [NXCommonUtils userSyncDateDefaultsKey];
                NSString *syncString = [[NSUserDefaults standardUserDefaults] objectForKey:syncDateKey];
                if (syncString) {
                    self.syncCell.detailTextLabel.text = syncString;
                    
                }else
                {
                    self.syncCell.detailTextLabel.text = NSLocalizedString(@"NOT_SYNC_YET", NULL);
                }
                
                if ([syncString containsString:@"failed"]) {
                    
                    self.syncCell.detailTextLabel.textColor = [UIColor redColor];
                    
                }else
                {
                    self.syncCell.detailTextLabel.textColor = [UIColor blackColor];
                }
                
                // here to enable syncCell again, if the cell is enable in REST API callback, the event dispatch in main queue sequency is
                // disableInteraction -> enableInteraction(in REST call back block) -> user click event   ::This can not deny user quick click
                // now, here the dispatch sequency is
                // disableInteraction->user click event -> enableInteraction
                // :: This can deny user quick click
                
                [self.syncCell setUserInteractionEnabled:YES];

            }
        }];
    }
}

-(void) removeCoverView
{
    UIView * coverView = [self.view viewWithTag:ACCOUNT_PAGE_COVER_VIEW_TAG];
    [coverView removeFromSuperview];
}

-(void) coverViewhandeTap:(UITapGestureRecognizer *) tapRecognizer
{
    UIView *dataPicker = [self.view viewWithTag:ACCOUNT_PAGGE_DATA_PICKER_TAG];
    [dataPicker removeFromSuperview];
    
    UIView *coverView = [self.view viewWithTag:ACCOUNT_PAGE_COVER_VIEW_TAG];
    [coverView removeFromSuperview];
}

- (void)updateSessionTimeOutString {
    double timeOutMilliSeconds = [NXLoginUser sharedInstance].profile.ttl.doubleValue - [[NSDate date] timeIntervalSince1970] * 1000;
    NSInteger timeOutSeconds = timeOutMilliSeconds / 1000;
//    NSInteger days = timeOutSeconds / (24*3600);
//    timeOutSeconds -= days * 24* 3600;
//    NSInteger hours = timeOutSeconds / 3600;
    
//    NSInteger seconds = timeOutSeconds % 60;
    timeOutSeconds /= 60;
    NSInteger minutes = timeOutSeconds % 60;
    timeOutSeconds /= 60;
    NSInteger hours = timeOutSeconds % 24;
    timeOutSeconds /= 24;
    NSInteger days = timeOutSeconds;
    
    NSString *timeoutStr = [NSString stringWithFormat:@"%@%@%@", (days ? [NSString stringWithFormat:@"%ld %@ ",days, days > 1 ? NSLocalizedString(@"DAYS", NULL): NSLocalizedString(@"DAY", NULL)] : @""), (hours ? [NSString stringWithFormat:@"%ld %@ ", hours, hours > 1 ? NSLocalizedString(@"HOURS", NULL) : NSLocalizedString(@"HOUR", NULL)] : @""), (minutes ? [NSString stringWithFormat:@"%ld %@", minutes, minutes > 1 ? NSLocalizedString(@"MINUTES", NULL):NSLocalizedString(@"MINUTE", NULL)]: @"")];
//    if (days > 0) {
//        if (hours > 0) {
//            timeoutStr = [NSString stringWithFormat:@"%ld %@ %ld %@",(long)days, days>1?NSLocalizedString(@"DAYS", NULL):NSLocalizedString(@"DAY", NULL), (long)hours, hours > 1?NSLocalizedString(@"HOURS", NULL):NSLocalizedString(@"HOUR", NULL)];
//        }else
//        {
//            timeoutStr = [NSString stringWithFormat:@"%ld %@",(long)days, days>1?NSLocalizedString(@"DAYS", NULL):NSLocalizedString(@"DAY", NULL)];
//        }
//    }else
//    {
//        timeoutStr = [NSString stringWithFormat:@"%ld %@",(long)hours, hours > 1?NSLocalizedString(@"HOURS", NULL):NSLocalizedString(@"HOUR", NULL)];
//    }

    self.sessionTimeOutString = timeoutStr;
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [NXCommonUtils deleteCachedFilesOnDisk];
        });
    }
}

#pragma mark - LiveAuthDelegate

- (void) authCompleted:(LiveConnectSessionStatus)status session:(LiveConnectSession *)session userState:(id)userState {
    if([(NSString*)userState isEqualToString:@"logout"]) {
        NSLog(@"logout success");
    }
}

- (void) authFailed:(NSError *)error userState:(id)userState {
    if([(NSString*)userState isEqualToString:@"logout"]) {
        NSLog(@"logout fail");
    }
}

#pragma mark response to notification
- (void) responseToRepositoryChanged:(NSNotification *) notification
{
    _cloudServices = [NSMutableArray arrayWithArray:[NXLoginUser sharedInstance].boundServices];
    [self.settingTableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
    
    if (notification.userInfo[NOTIFICATION_REPO_DELETE_ERROR_KEY])
    {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_DEL_REPO_SYNC_RMS_ERROR", nil)];
    }
    
    if (notification.userInfo[NOTIFICATION_REPO_UPDATED_ERROR_KEY])
    {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ERROR_UPDATE_REPO_SYNC_RMS_ERROR", nil)];
    }
}

@end
