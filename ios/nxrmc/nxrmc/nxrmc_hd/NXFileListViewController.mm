//
//  NXFileListViewController.m
//  nxrmc
//
//  Created by EShi on 7/27/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXFileListViewController.h"

#import "NXDrag2RefreshTableView.h"
#import "NXNetworkHelper.h"
#import "NXMasterSplitViewController.h"
#import "NXBoundService.h"
#import "NXSharePointFolder.h"

#import "NXSharepointOnline.h"
#import "NXSharepointOnlineAuthentication.h"
#import "AppDelegate.h"

#import "NXFileBase+SortSEL.h"
#import "NXFileBase+SharePointFileSys.h"

#import "NXLoginUser.h"
#import "NXICloudDriveDocPickerManager.h"

#import "NXFileListInfoViewController.h"
#import "NXAccountPageViewController.h"
#import "NXCloudServicesViewController.h"

#import "MDCFocusView.h"
#import "MDCSpotlightView.h"
#import "NXFocusViewPlaceHolder.h"
#import "NXFocusViewUserGuidTitle.h"
#import "NXCommonUtils.h"
#import "NXSyncRepoHelper.h"

#import "NXDropDownMenu.h"

#import "NXServiceListTableView.h"
#import "NXSettingViewController.h"
#import "NXGetRepositoryDetailsAPI.h"
#import "NXEncryptToken.h"
#import "NXAuthRepoHelper.h"


@interface NXFileListViewController ()<UIPopoverControllerDelegate, NXSharepointOnlineDelegete, NXICloudDriveDocPickerMgrDelegate, UINavigationControllerDelegate, NXFileListInfoViewControllerDelegate, NXServiceListTableViewDelegate, UIScrollViewDelegate, DetailViewControllerDelegate>
@property(strong, nonatomic) UIPopoverController *popoverControl;
@property(strong, nonatomic) UIPopoverController *cellAccessoryPopoverControl;
@property(strong, nonatomic) UIPopoverController *morePopoverControl;


@property(nonatomic, strong) NXICloudDriveDocPickerManager* iCloudDriveDocPKMgr;

@property(nonatomic, strong) UINavigationController *fileListNavigationController;
@property(nonatomic, strong) NSMutableDictionary *servicRootsDirectory;   // use for store multi-service's root folder, to cache them
@property(nonatomic, strong) UIView *contentView;

@property(nonatomic, strong) UIView *noRepView;
@property(nonatomic, strong) UIImageView *repIconView;
@property(nonatomic, strong) UIView *labelAndActionView;
@property(nonatomic, strong) UILabel *noRepTitleLabel;
@property(nonatomic, strong) UILabel *noRepDetailLabel;

@property(nonatomic, strong) MDCFocusView *focusView;
@end

#define NXRefreshNavigationTag 1313


@implementation NXFileListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    

    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    _fileContentVC = app.fileContentVC;
    
    self.view.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
    
    self.navigationItem.titleView = [self createTitleView];
    
    UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"More"] style:UIBarButtonItemStylePlain target:self action:@selector(didPressMoreBtn:)];
    self.navigationItem.rightBarButtonItem = moreButton;
    
    // add notificaton for RMS server address changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rmsServerChanged:)  name:NOTIFICATION_RMSSERVER_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToDeviceRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToUserLogout:) name:NOTIFICATION_NXRMC_LOG_OUT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userTapStatusBar:) name:NOTIFICATION_USER_TAP_STATUS_BAR object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToBoundServiceOpt) name:NOTIFICATION_REPO_ADDED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToBoundServiceOpt) name:NOTIFICATION_REPO_DELETED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToBoundServiceOpt) name:NOTIFICATION_REPO_CHANGED object:nil];

    
    _contentView = [[UIView alloc] init];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    _contentView.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
    [self.view addSubview:_contentView];
    
   // _contentView.backgroundColor = [UIColor greenColor];

    NSLayoutConstraint *constraintTop = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *constraintBottom = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    
    [self.view addConstraint:constraintTop];
    [self.view addConstraint:constraintBottom];
    
    
    _fileListNavigationController = [[UINavigationController alloc] init];
    _fileListNavigationController.delegate = self;
    _fileListNavigationController.view.backgroundColor = [UIColor clearColor];
    _fileListNavigationController.navigationBarHidden = YES;
    _fileListNavigationController.view.translatesAutoresizingMaskIntoConstraints = NO;
    UIViewController *navigationRootVC = [[UIViewController alloc] init];
    navigationRootVC.view.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.99 alpha:1.0];
    //////
    UILabel *noSelRepoLab = [[UILabel alloc] init];
    noSelRepoLab.translatesAutoresizingMaskIntoConstraints = NO;
    [noSelRepoLab setText:NSLocalizedString(@"NO_REPO_SELECT_IPAD", NULL)];
    [noSelRepoLab setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:15.0]];
    noSelRepoLab.numberOfLines = 0;
    noSelRepoLab.textAlignment = NSTextAlignmentCenter;
    noSelRepoLab.textColor = [UIColor colorWithRed:0.76 green:0.76 blue:0.79 alpha:1.0];
    [navigationRootVC.view addSubview:noSelRepoLab];
    //////
    [navigationRootVC.view addConstraint:[NSLayoutConstraint constraintWithItem:noSelRepoLab attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:navigationRootVC.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [navigationRootVC.view addConstraint:[NSLayoutConstraint constraintWithItem:noSelRepoLab attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:navigationRootVC.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    
    [_fileListNavigationController pushViewController:navigationRootVC animated:NO];
    _fileListNavigationController.view.tag = FILE_LIST_NAV_VIEW_TAG;
    [self.contentView addSubview:_fileListNavigationController.view];
    
    NSDictionary *fileListBindings = @{@"contentView":_fileListNavigationController.view};
    NSArray *constraintsFileListH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:fileListBindings];
    NSArray *constraintsFileListV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|" options:0 metrics:nil views:fileListBindings];
    [self.contentView addConstraints:constraintsFileListH];
    [self.contentView addConstraints:constraintsFileListV];
    
    [self initSortOperation];
    
    //default sort type
    _curSortOptName = NSLocalizedString(@"SORT_OPT_NAME_ASC", nil);
}

- (UIView *)createTitleView {
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 200,42)];
    
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [leftButton setBackgroundImage:[UIImage imageNamed:@"skydrmTitleIcon"] forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [rightButton setBackgroundImage:[UIImage imageNamed:@"Down"] forState:UIControlStateNormal & UIControlStateHighlighted & UIControlStateSelected];
    rightButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIButton *serviceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [serviceButton setTitle:NSLocalizedString(@"IPAD_REPO_LIST_TITLE", NULL) forState:UIControlStateNormal & UIControlStateSelected & UIControlStateHighlighted];
    serviceButton.titleLabel.font = [UIFont systemFontOfSize:22];
    [serviceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    
    [leftButton addTarget:self action:@selector(btnSelServicePressed:) forControlEvents:UIControlEventTouchUpInside];
    [serviceButton addTarget:self action:@selector(btnSelServicePressed:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton addTarget:self action:@selector(btnSelServicePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [titleView addSubview:leftButton];
    [titleView addSubview:serviceButton];
    [titleView addSubview:rightButton];
    leftButton.translatesAutoresizingMaskIntoConstraints = NO;
    rightButton.translatesAutoresizingMaskIntoConstraints = NO;
    serviceButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:serviceButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:titleView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:serviceButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:titleView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:leftButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:serviceButton attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:leftButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:serviceButton attribute:NSLayoutAttributeLeft multiplier:1 constant:-4]];
    [leftButton addConstraint:[NSLayoutConstraint constraintWithItem:leftButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:leftButton attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:rightButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:serviceButton attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:rightButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:serviceButton attribute:NSLayoutAttributeRight multiplier:1 constant:4]];
    [titleView addConstraint:[NSLayoutConstraint constraintWithItem:rightButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:rightButton attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    [rightButton addConstraint:[NSLayoutConstraint constraintWithItem:rightButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:rightButton attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    return titleView;
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    self.tabBarController.navigationController.navigationBarHidden = YES;
    
    if ([NXLoginUser sharedInstance].boundServices.count == 0) {
        [self showNoRepView];
    }else
    {
        UIView* noRepView = [self.view viewWithTag:NO_REPO_VIEW_TAG];
        [noRepView removeFromSuperview];
    }
}



- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // check if have file to open from third app
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    if (appDelegate.thirdAppFileURL) {
        NXFileBase *file = [NXCommonUtils fetchFileInfofromThirdParty:appDelegate.thirdAppFileURL];
        if (self.splitViewController.isCollapsed) {
            AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
            [self.splitViewController showDetailViewController:app.detailNav sender:self];
            DetailViewController *detailVC = (DetailViewController *)app.detailNav.topViewController;
            [detailVC openFile:file currentService:nil isOpen3rdAPPFile:YES isOpenNewProtectedFile:NO];
            
        }else
        {
            UINavigationController *nav = self.splitViewController.viewControllers.lastObject;
            [self.splitViewController showDetailViewController:nav sender:self];
            DetailViewController* fileContentVC = (DetailViewController *)nav.topViewController;
            [fileContentVC openFile:file currentService:nil isOpen3rdAPPFile:YES isOpenNewProtectedFile:NO];
            
        }
        appDelegate.thirdAppFileURL = nil;
    }
    
   
    [self responseToBoundServiceOpt];
    
    __weak NXFileListViewController* weakSekf = self;
    // get service repo
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
                    // update core data
                    [[NXLoginUser sharedInstance] syncLocalServiceInfoWithAddedServices:addRMCReposList deletedServices:delRMCReposList updatedServices:updateRMCReposList];
                    
                    // Update the sync date
                    NSDate *syncDate = [NSDate date];
                    NSString *syncDateKey = [NXCommonUtils userSyncDateDefaultsKey];
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                    NSString *strSyncDate = @"Last update time: ";
                    strSyncDate = [strSyncDate stringByAppendingString:[dateFormatter stringFromDate:syncDate]];
                    [[NSUserDefaults standardUserDefaults] setObject:strSyncDate forKey:syncDateKey];
                    
                    
                    // remove no repo view
                    if (getRepoResponse.rmsRepoList.count > 0) {
                        __strong NXFileListViewController* strongSelf = weakSekf;
                        [strongSelf responseToBoundServiceOpt];
                    }
                });
                
            }  // getRepoResponse.rmsStatuCode == NXRMS_STATUS_CODE_SUCCESS
        }
    }];

    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self removeAllCoverView];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self removeAllCoverView];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_RMSSERVER_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




#pragma mark SETTER|GETTER

-(NSMutableDictionary *) servicRootsDirectory
{
    if (_servicRootsDirectory == nil) {
        _servicRootsDirectory = [[NSMutableDictionary alloc] init];
    }
    return _servicRootsDirectory;
}

#pragma mark INIT
- (void) initSortOperation
{
    if (!_sortOperationArray) {
        _sortOperationArray = [[NSMutableArray alloc] init];
    }
    [_sortOperationArray removeAllObjects];
    
    NSString *sortNameAscTitle = NSLocalizedString(@"SORT_OPT_NAME_ASC", nil);
    NSString *sortNewestTitle = NSLocalizedString(@"SORT_OPT_NEWEST", nil);
    NSString *sortRepoTitle = NSLocalizedString(@"SORT_OPT_REPO", nil);
    
    NSDictionary* sortNameAscDic = nil;
    sortNameAscDic = [NSDictionary dictionaryWithObjectsAndKeys:sortNameAscTitle, SORT_OPT_NAME, @"SortByNameAsc", SORT_OPT_ICON, nil];
    [_sortOperationArray addObject:sortNameAscDic];
    
   
    NSDictionary* sortModifyDateNewestDic = nil;
    sortModifyDateNewestDic = [NSDictionary dictionaryWithObjectsAndKeys:sortNewestTitle, SORT_OPT_NAME, @"SortByDateNewest", SORT_OPT_ICON, nil];
    [_sortOperationArray addObject:sortModifyDateNewestDic];
    
    // make sure sort by repo is at the end of sortOperationArray , for it will shown/hide by whether now is root folder!
     NSDictionary* sortByServiceDic = [NSDictionary dictionaryWithObjectsAndKeys:sortRepoTitle, SORT_OPT_NAME, @"SortByRepo", SORT_OPT_ICON, nil];
    [_sortOperationArray addObject:sortByServiceDic];
}

#pragma mark UI Event

- (IBAction)btnSelServicePressed:(UIButton *)sender {
    NXServiceListTableView *serviceTableView = (NXServiceListTableView *)[self.view viewWithTag:FILE_LIST_SERVICE_TABLE_VIEW_TAG];
    if (serviceTableView) {
        [self removeAllCoverView];
        return;
    }
    
   
    serviceTableView = [[NXServiceListTableView alloc] initWithFrame:CGRectMake(0, -10, self.view.frame.size.width, 1)];
    serviceTableView.tag = FILE_LIST_SERVICE_TABLE_VIEW_TAG;
    
    serviceTableView.serviceListTableViewdelegate = self;
    CGFloat serviceTableViewHeight = 0.0;
    for(NXBoundService *boundService in [NXLoginUser sharedInstance].boundServices){
        if (boundService.service_type.integerValue == kServiceSharepoint || boundService.service_type.integerValue == kServiceSharepointOnline) {
            serviceTableViewHeight += 80.0;
        }else
        {
            serviceTableViewHeight += 60.0;
        }
    }
    
    serviceTableViewHeight += 50.0; // for add repostiry cell
    serviceTableViewHeight += 2.0;
    
    if (serviceTableViewHeight > self.view.frame.size.height * 0.5) {
        serviceTableViewHeight = self.view.frame.size.height * 0.5;
    }
    [self showCoverView];
    [self.view addSubview:serviceTableView];
    
    [UIView animateWithDuration:0.5 animations:^{
        serviceTableView.frame = CGRectMake(0, 0, self.view.frame.size.width, serviceTableViewHeight);
    } completion:^(BOOL finished) {
    }];
}

-(void) didPressMoreBtn:(UIBarButtonItem *) sender
{
    UIImage *sortByDateImg = nil;
    UIImage *sortByNameImg = nil;
    UIImage *sortByRepoImg = nil;
    
    UIViewController *topVC = self.fileListNavigationController.topViewController;
    if ([topVC isKindOfClass:[NXFileListInfoViewController class]]) {
        self.curSortOptName = ((NXFileListInfoViewController *)topVC).defaultSortOptName;
    }
    
    sortByDateImg = [UIImage imageNamed:@"SortByDateNewest"];
    sortByNameImg = [UIImage imageNamed:@"SortByNameAsc"];
    sortByRepoImg = [UIImage imageNamed:@"SortByRepo"];

    NSMutableArray *itemArray = [[NSMutableArray alloc] init];
    
    NXDropDownMenuItem *itemOne = [NXDropDownMenuItem menuItem:NSLocalizedString(@"SORT_OPT_NAME_ASC", nil) image:sortByNameImg target:self action:@selector(sortBtnPressed:)];
    if ([self.curSortOptName isEqualToString:NSLocalizedString(@"SORT_OPT_NAME_ASC", nil)]) {
        
        itemOne.foreColor = RMC_SUB_COLOR;
    }else
    {
        itemOne.foreColor = RMC_MAIN_COLOR;
    }
    [itemArray addObject:itemOne];
    
    NXDropDownMenuItem *itemTwo = [NXDropDownMenuItem menuItem:NSLocalizedString(@"SORT_OPT_NEWEST", nil) image:sortByDateImg target:self action:@selector(sortBtnPressed:)];
    if ([self.curSortOptName isEqualToString:NSLocalizedString(@"SORT_OPT_NEWEST", nil)])
    {
        itemTwo.foreColor = RMC_SUB_COLOR;
    }else
    {
        itemTwo.foreColor = RMC_MAIN_COLOR;
    }
    [itemArray addObject:itemTwo];
    
    // only root folder can sort by repository
    if ([topVC isKindOfClass:[NXFileListInfoViewController class]]) {
        if (((NXFileListInfoViewController *) topVC).contentFolder.isRoot) {
            NXDropDownMenuItem *itemThree = [NXDropDownMenuItem menuItem:NSLocalizedString(@"SORT_OPT_REPO", nil) image:sortByRepoImg target:self action:@selector(sortBtnPressed:)];
            if ([self.curSortOptName isEqualToString:NSLocalizedString(@"SORT_OPT_REPO", nil)]) {
                
                itemThree.foreColor = RMC_SUB_COLOR;
            }else
            {
                itemThree.foreColor = RMC_MAIN_COLOR;
            }
            [itemArray addObject:itemThree];
        }
    }
    
    CGRect menuRect = CGRectZero;
    if (self.interfaceOrientation == UIInterfaceOrientationPortrait) {
        menuRect = CGRectMake(self.navigationController.navigationBar.frame.size.width - 50, -self.navigationController.navigationBar.frame.size.height, 50, 50);
    }else
    {
        menuRect = CGRectMake(self.navigationController.navigationBar.frame.size.width - 50, -self.navigationController.navigationBar.frame.size.height, 50, 50);
    }
    [NXDropDownMenu setTintColor:[UIColor whiteColor]];
    [NXDropDownMenu showMenuInView:self.view fromRect:menuRect menuItems:itemArray];
//    
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];

//    NXSortFilePopoverContentController *sortFileContent = nil;
//    if ([self.fileListNavigationController.topViewController isKindOfClass:[NXFileListInfoViewController class]]) {
//        NXFileListInfoViewController *vc = (NXFileListInfoViewController *)self.fileListNavigationController.topViewController;
//        self.curSortOptName = vc.defaultSortOptName;
//        if (vc.contentFolder.isRoot) {
//            sortFileContent = [[NXSortFilePopoverContentController alloc] initWithFileListVC:self isRootFolder:YES];
//        }else
//        {
//            sortFileContent = [[NXSortFilePopoverContentController alloc] initWithFileListVC:self isRootFolder:NO];
//        }
//    }else
//    {
//         sortFileContent = [[NXSortFilePopoverContentController alloc] initWithFileListVC:self isRootFolder:NO];
//    }
//    _morePopoverControl = [[UIPopoverController alloc] initWithContentViewController:sortFileContent];
//    _morePopoverControl.delegate = self;
//    [_morePopoverControl presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

-(void) sortBtnPressed:(NXDropDownMenuItem *) menuItem
{
    self.curSortOptName = menuItem.title;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_PRESSED_SORT_BTN object:menuItem.title];
}

#pragma mark CATCHE OPERATION

-(void) cacheAllServicesRootDirectory
{
    for (NSString *key in self.servicRootsDirectory) {
        NXFileBase *root = self.servicRootsDirectory[key];
        NSArray *serviceInfo = [key componentsSeparatedByString:NXDIVKEY];
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *serviceType = [numberFormatter numberFromString:serviceInfo[0]];
        [NXCacheManager cacheDirectory:(ServiceType)[serviceType intValue] serviceAccountId:serviceInfo[1] directory:root];
        
    }
}

#pragma mark sort popover content delegate
- (void) contentController:(NXSortFilePopoverContentController *) contentController selectSortTitle:(NSString *) sortTitle
{
    _curSortOptName = sortTitle;
    [self initSortOperation];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_PRESSED_SORT_BTN object:sortTitle];
    [self.morePopoverControl dismissPopoverAnimated:YES];
    self.morePopoverControl = nil;

}

#pragma mark popover delegate
- (void) popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (popoverController == self.popoverControl) {
        self.popoverControl = nil;
    }
}

// listen to rms server address changed event
-(void) rmsServerChanged:(NSNotification *)notification
{
    NSLog(@"rmsServerChanged");
}

#pragma mark Response to Notification
-(void) responseToDeviceRotate:(NSNotification *) notification
{
    [self.popoverControl dismissPopoverAnimated:NO];
    [self.cellAccessoryPopoverControl dismissPopoverAnimated:NO];
    [self.morePopoverControl dismissPopoverAnimated:NO];
}


-(void) responseToUserLogout:(NSNotification *) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) userTapStatusBar:(NSNotification *) notification
{
        if (self.tabBarController.selectedIndex == 0) { // 0 means the file list tab view
        
        if ([self.fileListNavigationController.topViewController isKindOfClass:[NXFileListInfoViewController class]]) {
            [(NXFileListInfoViewController *)self.fileListNavigationController.topViewController makeFileListTableViewBackToTop];
        }
    }
}
#pragma mark NXICloudDriveDocPickerMgrDelegate
-(void) nxICloudDriverDocPickerMgr:(NXICloudDriveDocPickerManager *) pkMgr didImportFile:(NSURL *) fileURL
{
    NSLog(@"Open iCloudDrive file = %@", fileURL);
    //
    
    NSURL* url = [NXCacheManager getLocalUrlForServiceCache:kServiceICloudDrive serviceAccountId:nil];
    url = [url URLByAppendingPathComponent:CACHEROOTDIR isDirectory:NO];
    url = [url URLByAppendingPathComponent:fileURL.lastPathComponent];
    NSString *cachePath = [url.path stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:nil])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    if (![fileData writeToURL:url atomically:YES]) {
        UIAlertView* view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:@"Can not cache iCloud Drive file!" delegate:NULL cancelButtonTitle:NSLocalizedString(@"BOX_OK", NULL) otherButtonTitles:NULL, nil];
        [view show];
        return;
    }
    
    // save to db
    NXBoundService *iCloudDriveService = [[NXLoginUser sharedInstance] getICloudDriveService];
    iCloudDriveService.service_id = RMC_DEFAULT_SERVICE_ID_UNSET;
#pragma mark NOTE this interface is changed please using NXFileBase to cache.
    
    NXFileBase *file = [[NXFileBase alloc] init];
    file.name = url.lastPathComponent;
    file.fullServicePath = url.path;
    [self.fileContentVC openFile:file currentService:iCloudDriveService isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
    
    

}


#pragma mark multi-servic support
-(void) getServicesRootFileListAndShow:(NSArray *) serviceArray
{
     // step1. clear all current service and get new selected service root folder
    [self.servicRootsDirectory removeAllObjects];
    [self.fileListNavigationController popToRootViewControllerAnimated:NO];
    
    if (serviceArray.count == 0) {
        NSLog(@"getRootFile, but no service, return");
        // self.fileListNavigationController.view.hidden = YES;
        return;
    }
    for (NXBoundService *service in serviceArray) {
        NSString *key = [NXCommonUtils getServiceFolderKeyForFolderDirectory:service];
        NXFileBase *rootFolder = [[NXLoginUser sharedInstance] getRootFolderForServiceDictKey:key];
        [self.servicRootsDirectory setObject:rootFolder forKey:key];
    }

    
    // step2. give the root dictory to filelistDataProvider to init the root file base
    NXFileListInfoViewController * fileListVC = [[NXFileListInfoViewController alloc] initWithFileServices:serviceArray ContentFolder:[NXFolder createRootFolder] ServiceRootFolders:self.servicRootsDirectory];
    fileListVC.delegate = self;
    fileListVC.continerView = self.contentView;
    fileListVC.defaultSortOptName = self.curSortOptName;
    [self.fileListNavigationController pushViewController:fileListVC animated:NO];
}

#pragma mark NXFileListInfoViewControllerDelegate
-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didSelectFolder:(NXFileBase *) folder inService:(NXBoundService *) service
{
    NSArray *serviceArray = [NSArray arrayWithObject:service];
    NXFileListInfoViewController *fileListVC = [[NXFileListInfoViewController alloc] initWithFileServices:serviceArray ContentFolder:folder];
    fileListVC.delegate = self;
    [self.fileListNavigationController pushViewController:fileListVC animated:NO];
}



-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didSelectFile:(NXFileBase *)file inService:(NXBoundService *)service
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [self.splitViewController showDetailViewController:app.detailNav sender:self];
    DetailViewController* fileContentVC = nil;
    for(UIViewController *vc in app.detailNav.viewControllers)
    {
        if ([vc isKindOfClass:[DetailViewController class]]) {
            fileContentVC = (DetailViewController*)vc;
            break;
        }
    }
    if (fileContentVC) {
        fileContentVC.delegate = self;
        [fileContentVC openFile:file currentService:service inFileListInfoViewController:vc isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
    }
}
-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didAccessoryButtonTapped:(NXFileBase *)file inService:(NXBoundService *)service inPosition:(CGRect) position
{
    CGRect bound = self.navigationController.view.bounds;
    CGRect boundRect = CGRectMake(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height - self.tabBarController.tabBar.frame.size.height);
    NXFileDetailInfomationView *view = [NXFileDetailInfomationView fileDetailInfoViewWithBounds:boundRect file:file filedelegate:vc];
    [self.navigationController.view addSubview:view];
    view.currentVc = self;
    [view showFileDetailInfoView];
}

-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc errorForFolderNotFound:(NSError *)error
{
    if (vc.contentFolder.isRoot ) {
        return;
    }
    [self.fileListNavigationController popViewControllerAnimated:YES];
}

-(void) fileListInfoViewVCDidUpdateData:(NXFileListInfoViewController *)vc
{
    [self cacheAllServicesRootDirectory];
}

-(void) fileListInfoViewVCWillDisappear:(NXFileListInfoViewController *)vc
{
    [self cacheAllServicesRootDirectory];
}

#pragma mark NXServiceListTableViewDelegate
- (void) serviceListTableView:(NXServiceListTableView *) serviceTableView didSelectServices:(NSArray *) services
{
     [self getServicesRootFileListAndShow:services];
}
- (void) serviceListTableViewDidSelectAddService:(NXServiceListTableView *) serviceTableView
{
    [self coverViewTap:nil];
    if (self.popoverControl != nil) {
        [self.popoverControl dismissPopoverAnimated:YES];
        self.popoverControl = nil;
    }
    
    [self navigationToAddServicePage];
}

- (void) serviceListTableView:(NXServiceListTableView *)serviceTableView didSelectUnAuthedService:(NXBoundService *)service
{
    [self removeAllCoverView];
    
    [[NXAuthRepoHelper sharedInstance] authBoundService:service inViewController:self completion:^(id userAppendData, NSError *error) {
        if (error == nil) {
            [self responseToBoundServiceOpt];
        }
    }];
}

#pragma mark NO Repo View
-(void) showNoRepView
{
    UIView * noRepView = [self.view viewWithTag:NO_REPO_VIEW_TAG];
    if (noRepView) {
        [noRepView removeFromSuperview];
    }
    self.fileListNavigationController.view.hidden = YES;
    
    //self.drag2RefreshTableContentView.backgroundColor = [UIColor redColor];
    _noRepView = [[UIView alloc] init];
    _noRepView.translatesAutoresizingMaskIntoConstraints = NO;
    _noRepView.tag = NO_REPO_VIEW_TAG;
    //_noRepView.backgroundColor = [UIColor yellowColor];
    
    UIImage *repoEmptyImage = [UIImage imageNamed:@"RepoEmptyState"];
    CGFloat naturalAspect = repoEmptyImage.size.width / repoEmptyImage.size.height;
    _repIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RepoEmptyState"]];
    _repIconView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *repoEmptyCons = [NSLayoutConstraint constraintWithItem:_repIconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:_repIconView attribute:NSLayoutAttributeHeight multiplier:naturalAspect constant:1.0];
    [_repIconView addConstraint:repoEmptyCons];
    
    _labelAndActionView = [[UIView alloc] init];
    _labelAndActionView.translatesAutoresizingMaskIntoConstraints = NO;
    //_labelAndActionView.backgroundColor = [UIColor grayColor];
    
    [self.contentView addSubview:_noRepView];
    [self.noRepView addSubview:_repIconView];
    [self.noRepView addSubview:_labelAndActionView];
    
    
    
    NSDictionary *noRepViewMetrics = @{@"leftRightSpace":@(20.0), @"topBottomSpace":@(40.0)};
    NSDictionary *noRepViewBindings = @{@"noRepView":_noRepView};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[noRepView]|" options:0 metrics:nil views:noRepViewBindings]];
//    NSLayoutConstraint *noRepViewCenterYConstrain = [NSLayoutConstraint constraintWithItem:_noRepView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSArray *noRepViewConstrainsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-leftRightSpace-[noRepView]-leftRightSpace-|" options:0 metrics:noRepViewMetrics views:noRepViewBindings];
    [self.contentView addConstraints:noRepViewConstrainsH];
   // [self.contentView addConstraint:noRepViewCenterYConstrain];
    
    NSDictionary *iconAndLabelBings = @{@"repIconView":_repIconView, @"labelAndActionView":_labelAndActionView};
    NSArray *iconAndLabelConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[repIconView(<=labelAndActionView)]-[labelAndActionView]|" options:NSLayoutFormatAlignAllCenterX metrics:nil views:iconAndLabelBings];
    [self.noRepView addConstraints:iconAndLabelConstraintsV];
    
    NSLayoutConstraint *repIconConsWidth = [NSLayoutConstraint constraintWithItem:self.repIconView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.noRepView attribute:NSLayoutAttributeWidth multiplier:0.9 constant:0.0];
    
    [self.noRepView addConstraint:repIconConsWidth];
    
    NSLayoutConstraint *repIconConsCenterX = [NSLayoutConstraint constraintWithItem:self.repIconView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.noRepView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    
    [self.noRepView addConstraint:repIconConsCenterX];
    
    NSLayoutConstraint *labelAndActionConsWidth = [NSLayoutConstraint constraintWithItem:self.labelAndActionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.noRepView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0];
    
    [self.noRepView addConstraint:labelAndActionConsWidth];
    
    NSLayoutConstraint *labelAndActionConsCenterX = [NSLayoutConstraint constraintWithItem:self.labelAndActionView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.noRepView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    
    [self.noRepView addConstraint:labelAndActionConsCenterX];
        
        
    _noRepTitleLabel = [[UILabel alloc] init];
    _noRepTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_noRepTitleLabel setText:NSLocalizedString(@"NO_REPO_TITLE", NULL)];
    [_noRepTitleLabel setFont:[UIFont fontWithName:@"AppleSDGothicNeo-Light" size:20.0]];
    _noRepTitleLabel.textAlignment = NSTextAlignmentCenter;
    //_noRepTitleLabel.backgroundColor = [UIColor greenColor];
    _noRepTitleLabel.textColor = [UIColor colorWithRed:0.84 green:0.83 blue:0.86 alpha:1.0];
    
    _noRepDetailLabel = [[UILabel alloc] init];
    _noRepDetailLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_noRepDetailLabel setText:NSLocalizedString(@"NO_REPO_DETAIL", NULL)];
    [_noRepDetailLabel setFont:[UIFont fontWithName:@"AvenirNext-Medium" size:15.0]];
    _noRepDetailLabel.numberOfLines = 0;
    _noRepDetailLabel.textAlignment = NSTextAlignmentCenter;
    ////_noRepDetailLabel.backgroundColor = [UIColor blueColor];
    _noRepDetailLabel.textColor = [UIColor colorWithRed:0.76 green:0.76 blue:0.79 alpha:1.0];
    
    UIButton *btn = [[UIButton alloc] init];
    
    [btn addTarget:self action:@selector(addRepositoryBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle: NSLocalizedString(@"NO_REPO_BUTTON_TITLE", NULL) forState:UIControlStateNormal];
    btn.tag = FILE_LIST_NO_REPO_BTN_TAG;
    [btn setTitleColor:[UIColor colorWithRed:0.42 green:0.43 blue:0.49 alpha:1.0] forState:UIControlStateNormal];
    
    [btn.layer setMasksToBounds:YES];
    [btn.layer setCornerRadius:18.0];
    [btn.layer setBorderWidth:1.0];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorref = CGColorCreate(colorSpace,(CGFloat[]){ 0.42, 0.43, 0.49, 1 });
    [btn.layer setBorderColor:colorref];
    btn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:15.0];
    CFRelease(colorSpace);
    CFRelease(colorref);
    [self.labelAndActionView addSubview:btn];
   // [self.labelAndActionView addSubview:_noRepDetailLabel];
    [self.labelAndActionView addSubview:_noRepTitleLabel];
    
    
    
    NSDictionary *labelsActionsHMetrics = @{@"TitleLabelSpace":@(10), @"detailLineTwoSpace":@(15)};
    NSDictionary *labelsActionsVMetrics = @{@"space1":@(40), @"space2":@(10), @"space3":@(20)};
    NSDictionary *labelsActionBindings = @{@"titleView":_noRepTitleLabel, @"detailView":_noRepDetailLabel, @"AddRepoBtn":btn};
    
    NSArray *labelActionConstraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-space1-[titleView(==20)]-space2-[AddRepoBtn(>=40)]" options:0 metrics:labelsActionsVMetrics views:labelsActionBindings];
    NSArray *titleLabelConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-TitleLabelSpace-[titleView]-TitleLabelSpace-|" options:NSLayoutFormatAlignAllCenterX metrics:labelsActionsHMetrics views:labelsActionBindings];
    
//    NSArray *detailOneConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[detailView]-|" options:NSLayoutFormatAlignAllCenterX metrics:labelsActionsHMetrics views:labelsActionBindings];
    NSArray *btnConstraintsH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[AddRepoBtn(>=200)]" options:0 metrics:nil views:labelsActionBindings];
    
    
    [self.labelAndActionView addConstraints:labelActionConstraintsV];
    [self.labelAndActionView addConstraints:btnConstraintsH];
    [self.labelAndActionView addConstraints:titleLabelConstraintsH];
  //  [self.labelAndActionView addConstraints:detailOneConstraintsH];
    [self.labelAndActionView addConstraint:[NSLayoutConstraint constraintWithItem:btn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.labelAndActionView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    
}


-(void) addRepositoryBtnPressed:(UIButton *) button
{
    if (self.focusView.focusViewFocused) {
        [self.focusView dismiss:nil];
    }
    [self navigationToAddServicePage];
}

#pragma mark Tools
-(void) navigationToAddServicePage
{

    NXSettingViewController *vc = [[NXSettingViewController alloc] init];
    vc.shouldShowAddAcountPage = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.splitViewController showDetailViewController:nav sender:self];
}

-(void) showCoverView
{
    UIView *coverView = [[UIView alloc] init];
    coverView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6];
    coverView.tag = FILE_LIST_COVER_VIEW_TAG;
    coverView.translatesAutoresizingMaskIntoConstraints = NO;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(coverViewTap:)];
    [coverView addGestureRecognizer:tap];
    
    [self.view addSubview:coverView];
    NSDictionary *bindViews = @{@"coverView":coverView};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[coverView]|" options:0 metrics:nil views:bindViews]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[coverView]|" options:0 metrics:nil views:bindViews]];
}

-(void) coverViewTap:(UIGestureRecognizer *) recognizer
{
    UIView *serviceTableView = [self.view viewWithTag:FILE_LIST_SERVICE_TABLE_VIEW_TAG];
    [serviceTableView removeFromSuperview];
   
    
    UIView *coverView = [self.view viewWithTag:FILE_LIST_COVER_VIEW_TAG];
    [coverView removeFromSuperview];
}

-(void) removeAllCoverView
{
    UIView *serviceTableView = [self.view viewWithTag:FILE_LIST_SERVICE_TABLE_VIEW_TAG];
    [serviceTableView removeFromSuperview];
    
    UIView *coverView = [self.view viewWithTag:FILE_LIST_COVER_VIEW_TAG];
    [coverView removeFromSuperview];
}

- (void) responseToBoundServiceOpt
{
    if (self.tabBarController.selectedViewController != self.navigationController) {
        return;
    }
    // check if service is deleted
    if ([NXLoginUser sharedInstance].boundServices.count > 0) {
        UIView * noRepView = [self.view viewWithTag:NO_REPO_VIEW_TAG];
        if (noRepView) {
            [noRepView removeFromSuperview];
        }
        
        self.fileListNavigationController.view.hidden = NO;
        //step2. check if selecte service is delete
        NSMutableArray * serviceArray = [[NSMutableArray alloc] init];
        for (NXBoundService *service in [NXLoginUser sharedInstance].boundServices) {
            if (service.service_selected.boolValue && service.service_isAuthed.boolValue) {
                [serviceArray addObject:service];
            }
        }
        
        
        NSMutableDictionary *checkDictionary = [[NSMutableDictionary alloc] init];
        NSString *placeHolder = @"placeHolder";
        for (NXBoundService *selectedService in serviceArray) {
            [checkDictionary setObject:placeHolder forKey:[NSString stringWithFormat:@"%@-%@", selectedService.service_type, selectedService.service_account_id]];
        }
        
        if (self.fileListNavigationController.viewControllers.count > 1) {
            id rootFileListStack = self.fileListNavigationController.viewControllers[1];
            if ([rootFileListStack isKindOfClass:[NXFileListInfoViewController class]]) {
                //condition1. if selected services not equal to homepage services, just get rootFolder
                if (serviceArray.count != ((NXFileListInfoViewController *)rootFileListStack).serviceArray.count) {
                    [self getServicesRootFileListAndShow:serviceArray];
                }else
                {
                    // conditon2. if selected services count equal to homepage count, then check whether same service
                    for (NXBoundService *fileListService in ((NXFileListInfoViewController *)rootFileListStack).serviceArray) {
                        NSString * value = checkDictionary[[NSString stringWithFormat:@"%@-%@", fileListService.service_type, fileListService.service_account_id]];
                        if (!value) {
                            [self getServicesRootFileListAndShow:serviceArray];
                            break;
                        }
                    }
                }
            }
        }else{
            [self getServicesRootFileListAndShow:serviceArray];
        }
    }else
    {
        [self showNoRepView];
    }

}

#pragma mark DetailViewControllerDelegate
- (void) detailViewController:(DetailViewController *) detailVC SwipeToNextFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inFileListInfoView:(NXFileListInfoViewController *) fileListInfoVC
{
    NXFileBase *nextFile = [fileListInfoVC fileNextToFile:file];
    if (nextFile) {
        [detailVC openFile:nextFile currentService:[NXCommonUtils getBoundServiceFromCoreData:nextFile.serviceAccountId] inFileListInfoViewController:fileListInfoVC isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
    }else
    {
        [detailVC showAutoDismissLabel:NSLocalizedString(@"SWIPE_NO_MORE_FILE_TO_SHOW", nil)];
    }
}
- (void) detailViewController:(DetailViewController *) detailVC SwipeToPreFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inFileListInfoView:(NXFileListInfoViewController *) fileListInfoVC
{
    NXFileBase *preFile = [fileListInfoVC filePreToFile:file];
    if (preFile) {
        [detailVC openFile:preFile currentService:[NXCommonUtils getBoundServiceFromCoreData:preFile.serviceAccountId] inFileListInfoViewController:fileListInfoVC isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
    }else
    {
        [detailVC showAutoDismissLabel:NSLocalizedString(@"SWIPE_NO_MORE_FILE_TO_SHOW", nil)];
    }
}

@end
