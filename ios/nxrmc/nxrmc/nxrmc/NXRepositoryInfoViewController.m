//
//  NXRepositoryInfoViewController.m
//  nxrmc
//
//  Created by EShi on 1/27/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXRepositoryInfoViewController.h"
#import "NXCommonUtils.h"
#import "NXServiceOperation.h"
#import "NXCacheManager.h"
#import "AppDelegate.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "NXLoginUser.h"

#import "NXFileAttrTableViewCell.h"

// tableview data source
#define SECTION_NUM 3
#define SECTION_ZERO_CELL_NUM 5
#define SECTION_ONE_CELL_NUM 4
#define SECTION_TWO_CELL_NUM 1

#define DELETE_CACHE_TAG 10000
#define DELETE_REPO_TAG 10001
@interface NXRepositoryInfoViewController ()<UITableViewDataSource, UITableViewDelegate, NXServiceOperationDelegate, LiveAuthDelegate>
@property(nonatomic, strong) UITableView *repositoryInfoTableView;
@property(nonatomic, strong) id<NXServiceOperation> serviceOpt;
@property(nonatomic, strong) NSMutableDictionary *detailInfoDict;
@property(nonatomic) long long repoTotalSize;
@property(nonatomic) long long repoUsedSize;
@end

@implementation NXRepositoryInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    _repositoryInfoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _repositoryInfoTableView.translatesAutoresizingMaskIntoConstraints = NO;
    _repositoryInfoTableView.delegate = self;
    _repositoryInfoTableView.dataSource = self;
    [self.view addSubview:_repositoryInfoTableView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_repositoryInfoTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_repositoryInfoTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_repositoryInfoTableView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_repositoryInfoTableView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    
    _repositoryInfoTableView.estimatedRowHeight = 44.0;
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.title = NSLocalizedString(@"REPO_INFO_TITLE", nil);

}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self generateDetailInfo];
    [self.repositoryInfoTableView reloadData];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.serviceOpt cancelGetUserInfo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype) initWithBoundService:(NXBoundService *) boundService
{
    self = [super init];
    if (self) {
        _serviceOpt = [NXCommonUtils createServiceOperation:boundService];
        [_serviceOpt setDelegate:self];
        [_serviceOpt setBoundService:boundService];
    }
    return self;
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            if (([self.serviceOpt getOptBoundService].service_type.integerValue == kServiceSharepoint) || ([self.serviceOpt getOptBoundService].service_type.integerValue == kServiceSharepointOnline)) {
                return SECTION_ZERO_CELL_NUM + 1;
            }else
            {
                return SECTION_ZERO_CELL_NUM;

            }
        }
            break;
        case 1:
        {
            return SECTION_ONE_CELL_NUM;
        }
            break;
        case 2:
        {
            return SECTION_TWO_CELL_NUM;
        }
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    static NSString *DISPLAY_CELL_IDENTIFY =  @"DISPLAY_CELL_IDENTIFY";
    static NSString *NORMAL_CELL_IDENTIFY = @"NORMAL_CELL_IDENTIFY";
    
    switch (indexPath.section) {
        case 0:
        {
            NSArray *titles = @[NSLocalizedString(@"SHAREPOINT_REPO_URL", NULL),NSLocalizedString(@"REPO_TYPE", NULL), NSLocalizedString(@"USER_NAME", NULL), NSLocalizedString(@"EMAIL", NULL), NSLocalizedString(@"TOTAL_SPACE", NULL), NSLocalizedString(@"USED_SPACE", NULL)];
            if ([self.serviceOpt getOptBoundService].service_type.integerValue == kServiceSharepoint || [self.serviceOpt getOptBoundService].service_type.integerValue == kServiceSharepointOnline) {
                if (indexPath.row == 0) {
                    NXFileAttrTableViewCell *cell = [NXFileAttrTableViewCell fileAttrTableViewCellWithTableView:tableView];
                    cell.infoName.text = titles[indexPath.row];
                    cell.infoValue.text = self.detailInfoDict[titles[indexPath.row]];
                    cell.infoValue.numberOfLines = 0;
                    cell.infoValue.lineBreakMode = NSLineBreakByWordWrapping;
                    
                    UITableViewCell *normalCell = [tableView dequeueReusableCellWithIdentifier:DISPLAY_CELL_IDENTIFY];
                    if (normalCell == nil) {
                        normalCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DISPLAY_CELL_IDENTIFY];
                        normalCell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
                    }
                    
                    cell.infoName.font = normalCell.textLabel.font;
                    cell.infoValue.font = normalCell.detailTextLabel.font;
                    cell.infoValue.textAlignment = NSTextAlignmentRight;
                    cell.infoValue.textColor = normalCell.detailTextLabel.textColor;
                    
                    return cell;
                }else
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:DISPLAY_CELL_IDENTIFY];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DISPLAY_CELL_IDENTIFY];
                        cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
                    }
                    cell.textLabel.text = titles[indexPath.row];
                    cell.detailTextLabel.text = self.detailInfoDict[titles[indexPath.row]];
                }
               
                
            }else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:DISPLAY_CELL_IDENTIFY];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DISPLAY_CELL_IDENTIFY];
                    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
                }
                cell.textLabel.text = titles[indexPath.row + 1];
                cell.detailTextLabel.text = self.detailInfoDict[titles[indexPath.row + 1]];
            }
            
            
            if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"USED_SPACE", NULL)]) {
                if ((self.repoUsedSize - self.repoTotalSize) > 0) {
                    cell.detailTextLabel.textColor = [UIColor redColor];
                }
            }
            
            return cell;
            
        }
            break;
        case 1:
        {
            if (indexPath.row == 3) { // Clean Cache
                cell = [tableView dequeueReusableCellWithIdentifier:NORMAL_CELL_IDENTIFY];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NORMAL_CELL_IDENTIFY];
                    cell.textLabel.textAlignment = NSTextAlignmentCenter;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;                    
                }
                cell.textLabel.textColor = [UIColor blueColor];
                cell.textLabel.text = NSLocalizedString(@"CLEANCACHE", NULL);

            }else
            {
                cell = [tableView dequeueReusableCellWithIdentifier:DISPLAY_CELL_IDENTIFY];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:DISPLAY_CELL_IDENTIFY];
                    cell.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
                }
                NSArray *titles = @[NSLocalizedString(@"OFFLINE_SIZE", NULL), NSLocalizedString(@"CACHE_SIZE", NULL), NSLocalizedString(@"TOTAL_SIZE", NULL)];
                cell.textLabel.text = titles[indexPath.row];
                NSNumber *spaceSize = self.detailInfoDict[titles[indexPath.row]];
                NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
                formatter.allowsNonnumericFormatting = NO;
                formatter.countStyle = NSByteCountFormatterCountStyleBinary;
                NSString *strSize = [formatter stringFromByteCount:spaceSize.longLongValue];
                cell.detailTextLabel.text = strSize;
            }
        }
            break;
        case 2:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:NORMAL_CELL_IDENTIFY];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NORMAL_CELL_IDENTIFY];
                cell.textLabel.textAlignment = NSTextAlignmentCenter;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.textLabel.text = NSLocalizedString(@"DELETE_REPO", NULL);
            cell.textLabel.textColor = [UIColor redColor];
            

        }
            break;
        default:
            break;
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SECTION_NUM;
}
#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 40.0;
    }else
    {
        return 30.0;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            return NSLocalizedString(@"REPO_INFO", nil);
        }
            break;
        case 1:
        {
            return NSLocalizedString(@"LOCAL_USAGE", nil);
        }
        default:
        break;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.row == 3) {
            NSString *info = NSLocalizedString(@"DELETE_CACEH_WARNING", NULL);
            UIAlertView *view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:info delegate:self cancelButtonTitle:NSLocalizedString(@"BOX_CANCEL", NULL) otherButtonTitles:NSLocalizedString(@"BOX_OK", NULL), nil];
            view.delegate = self;
            view.tag = DELETE_CACHE_TAG;
            [view show];
        }
    }
    
    if (indexPath.section == 2) {
        
        NSString *info = NSLocalizedString(@"DELETE_REPO_WARNING", NULL);
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:info delegate:self cancelButtonTitle:NSLocalizedString(@"BOX_CANCEL", NULL) otherButtonTitles:NSLocalizedString(@"BOX_OK", NULL), nil];
        view.delegate = self;
        view.tag = DELETE_REPO_TAG;
        [view show];
    }
}
#pragma mark NXServiceOperationDelegate
-(void) getUserInfoFinished:(NSString *) userName userEmail:(NSString *) email totalQuota:(NSNumber *) totalQuota usedQuota:(NSNumber *) usedQuota error:(NSError *) error
{
    UIView *waitingView = [self.view viewWithTag:8808];
    [waitingView removeFromSuperview];
    
    if (!error) {
        if(userName)
        {
            [_detailInfoDict setObject:userName forKey:NSLocalizedString(@"USER_NAME", NULL)];
        }
        
        if (email) {
             [_detailInfoDict setObject:email forKey:NSLocalizedString(@"EMAIL", NULL)];
        }

        if (totalQuota) {
            NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
            formatter.allowsNonnumericFormatting = NO;
            formatter.countStyle = NSByteCountFormatterCountStyleBinary;
            NSString *totalSizeStr = [formatter stringFromByteCount:totalQuota.longLongValue];
            [_detailInfoDict setObject:totalSizeStr forKey:NSLocalizedString(@"TOTAL_SPACE", NULL)];
            self.repoTotalSize = totalQuota.longLongValue;
        }
        
        if (usedQuota) {
            NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
            formatter.allowsNonnumericFormatting = NO;
            formatter.countStyle = NSByteCountFormatterCountStyleBinary;
            NSString *usedSizeStr = [formatter stringFromByteCount:usedQuota.longLongValue];
            [_detailInfoDict setObject:usedSizeStr forKey:NSLocalizedString(@"USED_SPACE", NULL)];
            self.repoUsedSize = usedQuota.longLongValue;

        }
        [self.repositoryInfoTableView reloadData];
    }
}

#pragma mark private method
-(void) regenreateSpaceData
{
    NXBoundService *service = [self.serviceOpt getOptBoundService];
    NSURL *offlineURL = [NXCacheManager getSafeLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    offlineURL = [offlineURL URLByAppendingPathComponent:CACHEROOTDIR isDirectory:YES];
    NSNumber *offFileSize = [NXCommonUtils calculateCachedFileSizeAtPath:offlineURL.path];
    NSURL *cacheURL = [NXCacheManager getLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    cacheURL = [cacheURL URLByAppendingPathComponent:CACHEROOTDIR isDirectory:YES];
    NSNumber *cacheFileSize = [NXCommonUtils calculateCachedFileSizeAtPath:cacheURL.path];
    
    [_detailInfoDict setObject:offFileSize forKey:NSLocalizedString(@"OFFLINE_SIZE", NULL)];
    [_detailInfoDict setObject:cacheFileSize forKey:NSLocalizedString(@"CACHE_SIZE", NULL)];
    long long totalSize = offFileSize.longLongValue + cacheFileSize.longLongValue;
    NSNumber *totalFileSize = [NSNumber numberWithLongLong:totalSize];
    [_detailInfoDict setObject:totalFileSize forKey:NSLocalizedString(@"TOTAL_SIZE", NULL)];
    [self.repositoryInfoTableView reloadData];

}
- (void) generateDetailInfo
{
    [NXCommonUtils createWaitingViewInView:self.view];
    _detailInfoDict = [[NSMutableDictionary alloc] init];
    
    NXBoundService *boundService = [self.serviceOpt getOptBoundService];
    
    [_detailInfoDict setObject:[NXCommonUtils convertRepoTypeToDisplayName:boundService.service_type] forKey:NSLocalizedString(@"REPO_TYPE", NULL)];
    
    if (boundService.service_type.integerValue == kServiceSharepoint || boundService.service_type.integerValue == kServiceSharepointOnline) {
        NSString *spURL = [boundService.service_account_id componentsSeparatedByString:@"^"].firstObject;
        [_detailInfoDict setObject:spURL forKey:NSLocalizedString(@"SHAREPOINT_REPO_URL", NULL)];
    }else{
        [_detailInfoDict setObject:@"" forKey:NSLocalizedString(@"SHAREPOINT_REPO_URL", NULL)];
    }
    
    [_detailInfoDict setObject:@"" forKey:NSLocalizedString(@"USER_NAME", NULL)];
    [_detailInfoDict setObject:@"" forKey:NSLocalizedString(@"EMAIL", NULL)];
    [_detailInfoDict setObject:@"" forKey:NSLocalizedString(@"TOTAL_SPACE", NULL)];
    [_detailInfoDict setObject:@"" forKey:NSLocalizedString(@"USED_SPACE", NULL)];
    
    NXBoundService *service = [self.serviceOpt getOptBoundService];
    NSURL *offlineURL = [NXCacheManager getSafeLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    offlineURL = [offlineURL URLByAppendingPathComponent:CACHEROOTDIR isDirectory:YES];
    NSNumber *offFileSize = [NXCommonUtils calculateCachedFileSizeAtPath:offlineURL.path];
    NSURL *cacheURL = [NXCacheManager getLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    cacheURL = [cacheURL URLByAppendingPathComponent:CACHEROOTDIR isDirectory:YES];
    NSNumber *cacheFileSize = [NXCommonUtils calculateCachedFileSizeAtPath:cacheURL.path];
    
    [_detailInfoDict setObject:offFileSize forKey:NSLocalizedString(@"OFFLINE_SIZE", NULL)];
    [_detailInfoDict setObject:cacheFileSize forKey:NSLocalizedString(@"CACHE_SIZE", NULL)];
    long long totalSize = offFileSize.longLongValue + cacheFileSize.longLongValue;
    NSNumber *totalFileSize = [NSNumber numberWithLongLong:totalSize];
    [_detailInfoDict setObject:totalFileSize forKey:NSLocalizedString(@"TOTAL_SIZE", NULL)];
    
    [self.serviceOpt getUserInfo];
}

-(void) deleteCacheFile
{
    NXBoundService *service = [self.serviceOpt getOptBoundService];
    NSURL *cacheURL = [NXCacheManager getLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    cacheURL = [cacheURL URLByAppendingPathComponent:CACHEROOTDIR isDirectory:YES];
    [NXCommonUtils deleteFilesAtPath:cacheURL.path];
    [self regenreateSpaceData];

}

-(void) deleteRepo
{
    NXBoundService *service = [self.serviceOpt getOptBoundService];;
    [[NXLoginUser sharedInstance] deleteService:service];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void) removeWaitingView
{
    UIView *waintingView = [self.view viewWithTag:8808];
    [waintingView removeFromSuperview];
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

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag == DELETE_CACHE_TAG) {
            [self deleteCacheFile];
        }
        
        if (alertView.tag == DELETE_REPO_TAG) {
            [self deleteRepo];
        }
    }
}

@end
