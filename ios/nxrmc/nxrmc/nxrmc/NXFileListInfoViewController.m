//
//  NXFileListInfoViewController.m
//  nxrmc
//
//  Created by EShi on 10/15/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//
#define SORT_OPT_NAME @"SortOptName"
#define SORT_OPT_BLOCK @"SortOptBlock"
#define SORT_OPT_ICON @"SortOptIcon"
#define SORT_OPT_NAME_DESC_ICON @"SortByNameDesc"
#define SORT_OPT_NAME_ASC_ICON @"SortByNameAsc"
#define SORT_OPT_DATE_NEWSET_ICON @"SortByDateNewest"
#define SORT_OPT_REOP_ICON @"SortByRepo"
#define SORT_OPT_DATE_OLDEST_ICON @"SortByDateOldest"
#define SORT_OPT_SIZE_LARGEST_ICON @"SortBySizeLargest"
#define SORT_OPT_SIZE_SMALLEST_ICON @"SortBySizeSmallest"

#import "NXFileListInfoViewController.h"
#import "NXFileDetailInfomationView.h"
#import "NXFileListTableViewCell.h"
#import "AppDelegate.h"

typedef void (^SortOperationBlock)();

@interface NXFileListInfoViewController ()<NXFileListInfoDataProviderDelegate,UISearchDisplayDelegate>
@property(nonatomic, strong) NSMutableArray* sortOperationArray;
@property(nonatomic, strong) NSDictionary *curSortDict;
@property(nonatomic, strong) NSMutableDictionary *rootFoldersDic;
@property(nonatomic, strong) NSArray *filterData;
@property(nonatomic)  BOOL isGetFileForRefresh;
@end

@implementation NXFileListInfoViewController

-(instancetype) initWithFileServices:(NSArray *) services ContentFolder:(NXFileBase *) folder
{
    self = [super init];
    if (self) {
        _serviceArray = [services mutableCopy];
        _contentFolder = folder;
        
        _fileListDataProvider = [[NXFileListInfoDataProvider alloc] init];
        _fileListDataProvider.delegate = self;
    }
    return self;
    
}

-(instancetype) initWithFileServices:(NSArray *) services ContentFolder:(NXFileBase *) folder ServiceRootFolders:(NSMutableDictionary *) rootFoldersDic
{
    self = [self initWithFileServices:services ContentFolder:folder];
    if (self) {
        _rootFoldersDic = [rootFoldersDic mutableCopy];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
    [self initSortOperation];
    NSDictionary *defatulSortOptDict = nil;
    for (NSDictionary *sortOptDict in self.sortOperationArray) {
        if ([sortOptDict[SORT_OPT_NAME] isEqualToString:_defaultSortOptName]) {
            defatulSortOptDict = sortOptDict;
            break;
        }
    }
    
    if (defatulSortOptDict == nil) {
        _curSortDict = self.sortOperationArray[0];
    }else
    {
        _curSortDict = defatulSortOptDict;
    }
    
 
    if (self.contentFolder.isRoot) {
        _drag2RefreshTableView = [[NXDrag2RefreshTableView alloc] initWithFrame:self.view.frame addHeaderRefreshView:YES addFooterRefreshView:NO ContentViewController:self NavBar:nil isHomePage:_isHomePage];

    }else
    {
        _drag2RefreshTableView = [[NXDrag2RefreshTableView alloc] initWithFrame:self.view.frame addHeaderRefreshView:YES addFooterRefreshView:NO ContentViewController:self NavBar:self.navigationController.navigationBar isHomePage:_isHomePage];
    }
    
    
    __weak NXFileListInfoViewController* vc = self;
    _drag2RefreshTableView.dragEndBlock = ^(Drag2RefreshViewType type)
    {
        if (type == kHeaderRefeshView) {
            
            [vc refreshDataInOtherThread];
            
        }else if(type == kFooterRefeshView){
            
            [vc addDataInOtherThread];
        }
    };
    _contentDataArray = [[NSMutableArray alloc] init];
    
    _drag2RefreshTableView.dataSource = self;
    _drag2RefreshTableView.delegate = self;
    [self.view addSubview:_drag2RefreshTableView];
    
    // Listen to the device rotate
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ResponseToDeviceRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userPressedSortMenuBtn:) name:NOTIFICATION_USER_PRESSED_SORT_BTN object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userOpenNewFile:) name:NOTIFICATION_USER_OPEN_FILE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToRepoAliasUpdate:) name:NOTIFICATION_REPO_ALIAS_UPDATED object:nil];

    
    
    self.drag2RefreshTableView.translatesAutoresizingMaskIntoConstraints = NO;
    NSDictionary *dragTableViewBindings = @{@"drag2RefreshTableView":self.drag2RefreshTableView};
    NSArray *constraintsTableViewH = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[drag2RefreshTableView]|" options:0 metrics:nil views:dragTableViewBindings];
    NSArray *constraintsTableViewV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[drag2RefreshTableView]|" options:0 metrics:nil views:dragTableViewBindings];
    [self.view addConstraints:constraintsTableViewH];
    [self.view addConstraints:constraintsTableViewV];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.navigationController.navigationBarHidden = YES;
    
    if (self.contentFolder.isRoot) {
        
        self.navigationController.navigationBarHidden = YES;
        
    }else
    {
        
        if (!self.drag2RefreshTableView.searchDisplayController.isActive && ![self isFileListSearchControllerActived]) {
            
            self.navigationController.navigationBarHidden = NO;
        }
        
        // set current title
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 40)];
        titleLabel.text = self.contentFolder.name;
        titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        titleLabel.textAlignment = NSTextAlignmentCenter;
       // self.navigationItem.title = self.contentFolder.name;
        self.navigationItem.titleView = titleLabel;
    }
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    // fix bug 35836.
    // If NXFileDetailInfomationView is shown, it must in front.
    // but when we disappear NXFileListInfoViewController, we will hidden navigationController and reshow it
    // in NXFileListInfoViewController viewWillAppear.(This will make folder UI change smooth)
    // But if in Fav/Off NXCustomViewController, it will make the NXFileDetailInfomationView behind NXFileListInfoViewController's
    // navigationController. So in viewWillAppear, we bring NXFileDetailInfomationView to font
    if (self.navigationController.view.subviews.count > 0) {
        for (UIView *subView in self.navigationController.view.subviews) {
            if ([subView isKindOfClass:[NXFileDetailInfomationView class]]) {
                [self.navigationController.view bringSubviewToFront:subView];
                break;
            }
        }
    }
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self reloadFileListTableView];
    if (!self.contentFolder.isRoot) {
        self.drag2RefreshTableView.navBar = self.navigationController.navigationBar;
    }
    
    // display content
    if (self.contentDataArray.count > 0) {
        // if is appear by navigaiton back
        if (self.serviceArray.count > 0 && self.contentFolder) {
            if (self.contentFolder.isRoot) {
                [self.fileListDataProvider syncFileByServices:self.serviceArray withFolders:self.rootFoldersDic];
            }else
            {
                [self.fileListDataProvider syncFileByServices:self.serviceArray withFolder:self.contentFolder];
            }
        }
    }else
    {
        [NXCommonUtils createWaitingViewInView:self.view];

        if (self.contentFolder.isRoot) { // root folder, get multi-service and init rootfolder
            
            [self.fileListDataProvider getFileByServices:self.serviceArray folders:self.rootFoldersDic needReadCache:YES];
            
        }else
        {
            [self.fileListDataProvider getFilesByService:self.serviceArray.firstObject Folder:self.contentFolder needReadCache:YES];
        }
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.fileListDataProvider cancelServiceGetFiles];
    NSLog(@"FileListInfoVC disappear, call cancelSync");
    [self.fileListDataProvider cancelSyncFileList];
    self.navigationController.navigationBarHidden = YES;
    if ([self.delegate respondsToSelector:@selector(fileListInfoViewVCWillDisappear:)]) {
        [self.delegate fileListInfoViewVCWillDisappear:self];
    }
    
    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void) reloadFileListTableView {
    [self.drag2RefreshTableView reloadData];
}

-(void) makeFileListTableViewBackToTop
{
    if(self.navigationController.topViewController == self)
    {
        [self.drag2RefreshTableView drag2RefreshTableViewBackToTop];
    }
}

#pragma mark SETTER/GETTER/INIT
- (void) initSortOperation
{
    if (!_sortOperationArray) {
        _sortOperationArray = [[NSMutableArray alloc] init];
    }
    
    NSString* sortNameAscTitle = NSLocalizedString(@"SORT_OPT_NAME_ASC", nil);
    NSString* sortNewestTitle = NSLocalizedString(@"SORT_OPT_NEWEST", nil);
    NSString *sortRepoTitle = NSLocalizedString(@"SORT_OPT_REPO", nil);
    __weak NXFileListInfoViewController *weakself = self;
    
    SortOperationBlock sortByNameAsc = ^(){
        __strong NXFileListInfoViewController *strongself = weakself;
        if (strongself) {
             NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\p{script=Han}" options:NSRegularExpressionCaseInsensitive error:nil];
            
            NSMutableArray *chineseNameArray = [[NSMutableArray alloc] init];
            [strongself.contentDataArray sortUsingSelector:@selector(sortContentByNameAsc:)];
            for (id fileData in strongself.contentDataArray) {
                NXFileBase *file = (NXFileBase *) fileData;
                if ([regex numberOfMatchesInString:file.name options:0 range:NSMakeRange(0, 1)] > 0) {
                    [chineseNameArray insertObject:fileData atIndex:0];
                }
            }
            
            for (id fileData in chineseNameArray) {
                [strongself.contentDataArray removeObject:fileData];
                [strongself.contentDataArray insertObject:fileData atIndex:0];
            }
            
            
            
            ///////////////
            [strongself.groupedFileListDic removeAllObjects];
            [strongself.groupedKeys removeAllObjects];
            
            for (NXFileBase *file in strongself.contentDataArray) {
                NSString *name = file.name;
                NSString *firstString = [[name substringToIndex:1] capitalizedString];
                unichar firstChar = [firstString characterAtIndex:0];
                NSCharacterSet *letters = [NSCharacterSet letterCharacterSet];
                if ([letters characterIsMember:firstChar]) {
                    if (firstChar >= 'A' && firstChar <='Z') {
                        NSMutableArray *storeArray = strongself.groupedFileListDic[firstString];
                        if (storeArray == nil) {
                            storeArray = [[NSMutableArray alloc] init];
                            [storeArray addObject:file];
                            [strongself.groupedFileListDic setObject:storeArray forKey:firstString];
                        }else
                        {
                            [storeArray addObject:file];
                        }
                        
                    }else // stroe in '#' only support Engilsh for now
                    {
                        NSString *noLetterKey = @"#";
                        NSMutableArray *storeArray = strongself.groupedFileListDic[noLetterKey];
                        if (storeArray == nil) {
                            storeArray = [[NSMutableArray alloc] init];
                            [storeArray addObject:file];
                            [strongself.groupedFileListDic setObject:storeArray forKey:noLetterKey];
                        }else
                        {
                            [storeArray addObject:file];
                        }
                    }
                    
                }else // store in '#'
                {
                    
                    NSString *noLetterKey = @"#";
                    NSMutableArray *storeArray = strongself.groupedFileListDic[noLetterKey];
                    if (storeArray == nil) {
                        storeArray = [[NSMutableArray alloc] init];
                        [storeArray addObject:file];
                        [strongself.groupedFileListDic setObject:storeArray forKey:noLetterKey];
                    }else
                    {
                        [storeArray addObject:file];
                    }
                    
                }
            }
            
            strongself.groupedKeys = [[[strongself.groupedFileListDic allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
            //////////////
            
        }
    };
    NSDictionary* sortNameAscDic = [NSDictionary dictionaryWithObjectsAndKeys:sortNameAscTitle, SORT_OPT_NAME, sortByNameAsc, SORT_OPT_BLOCK, SORT_OPT_NAME_ASC_ICON, SORT_OPT_ICON, nil];
    [_sortOperationArray addObject:sortNameAscDic];
    

    SortOperationBlock sortByModifyDateNewest = ^(){
        __strong NXFileListInfoViewController *strongself = weakself;
        if (strongself) {
          
            [strongself.contentDataArray sortUsingSelector:@selector(sortContentByDateNewest:)];
            [strongself.groupedFileListDic removeAllObjects];
            [strongself.groupedKeys removeAllObjects];
            
            for (NXFileBase *file in self.contentDataArray) {
                NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
                [dateFormtter setDateFormat:@"MMMM yyyy"];
                
                NSString *key = [dateFormtter stringFromDate:file.lastModifiedDate];
                if (key) {
                    BOOL isExist = NO;
                    for (NSString* storedTitle in strongself.groupedKeys) {
                        if ([storedTitle isEqualToString:key]) {
                            isExist = YES;
                            break;
                        }
                    }
                    if (!isExist) {
                        [strongself.groupedKeys addObject:key];
                    }
                    
                    NSMutableArray * array = strongself.groupedFileListDic[key];
                    if (array == nil) {
                        array = [[NSMutableArray alloc] initWithObjects:file, nil];
                        
                    }else
                    {
                        [array addObject:file];
                    }
                    [strongself.groupedFileListDic setObject:array forKey:key];
                }else  // file sys not support modify time
                {
                    NSString *key = @"#";
                    BOOL isExist = NO;
                    for (NSString* storedTitle in strongself.groupedKeys) {
                        if ([storedTitle isEqualToString:key]) {
                            isExist = YES;
                            break;
                        }
                    }
                    if (!isExist) {
                        [strongself.groupedKeys insertObject:key atIndex:0];
                    }
                    
                    NSMutableArray * array = strongself.groupedFileListDic[key];
                    if (array == nil) {
                        array = [[NSMutableArray alloc] initWithObjects:file, nil];
                        
                    }else
                    {
                        [array addObject:file];
                    }
                    [array sortUsingSelector:@selector(sortContentByNameAsc:)];
                    [strongself.groupedFileListDic setObject:array forKey:key];
                }
            }
        }
    };
    NSDictionary* sortModifyDateNewestDic = [NSDictionary dictionaryWithObjectsAndKeys:sortNewestTitle, SORT_OPT_NAME, sortByModifyDateNewest, SORT_OPT_BLOCK, SORT_OPT_DATE_NEWSET_ICON, SORT_OPT_ICON, nil];
    [_sortOperationArray addObject:sortModifyDateNewestDic];
    
    // SORT BY REPOTORY
    SortOperationBlock sortByDriver = ^(){
        __strong NXFileListInfoViewController *strongself = weakself;
        if (strongself) {
            [strongself.contentDataArray sortUsingSelector:@selector(sortContentByRepoAlians:)];
            [strongself.groupedFileListDic removeAllObjects];
            [strongself.groupedKeys removeAllObjects];
            
            for (NXFileBase *file in self.contentDataArray) {
                NSString *serviceAlias = [NXCommonUtils serviceAliasByServiceType:file.serviceType.integerValue ServiceAccountId:file.serviceAccountId];
                NSMutableArray *fileArray = strongself.groupedFileListDic[serviceAlias];
                if (!fileArray) {
                    fileArray = [[NSMutableArray alloc] initWithObjects:file, nil];
                    [strongself.groupedFileListDic setObject:fileArray forKey:serviceAlias];
                }else
                {
                    [fileArray addObject:file];
                }
            }
            
            strongself.groupedKeys = [[[strongself.groupedFileListDic allKeys] sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
        }
    };
    NSDictionary* sortByServiceDic = [NSDictionary dictionaryWithObjectsAndKeys:sortRepoTitle, SORT_OPT_NAME, sortByDriver, SORT_OPT_BLOCK, SORT_OPT_REOP_ICON, SORT_OPT_ICON, nil];
    
    [_sortOperationArray addObject:sortByServiceDic];

}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_USER_PRESSED_SORT_BTN object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
-(void) setContentDataArray:(NSMutableArray *) dataArray
{
    _contentDataArray = dataArray;
    SortOperationBlock sortOpt = self.curSortDict[SORT_OPT_BLOCK];
    _defaultSortOptName = self.curSortDict[SORT_OPT_NAME];
    sortOpt();
    [self reloadFileListTableView];
}

-(NSMutableDictionary *) groupedFileListDic
{
    if (_groupedFileListDic == nil) {
        _groupedFileListDic = [[NSMutableDictionary alloc] init];
    }
    return _groupedFileListDic;
}
-(NSMutableArray *) groupedKeys
{
    if (_groupedKeys == nil) {
        _groupedKeys = [[NSMutableArray alloc] init];
    }
    return _groupedKeys;
}

-(void) setCurSortDict:(NSDictionary *) dictionary
{
    _curSortDict = dictionary;
    SortOperationBlock block = _curSortDict[SORT_OPT_BLOCK];
    _defaultSortOptName = _curSortDict[SORT_OPT_NAME];
    block();
    [self reloadFileListTableView];
}


#pragma mark ------------ The function to response to drag2Refresh drag event
-(void) refreshDataInOtherThread
{
    self.isGetFileForRefresh = YES;
    if (self.contentFolder.isRoot) { // root folder, get multi-service and init rootfolder
        
        [self.fileListDataProvider getFileByServices:self.serviceArray folders:self.rootFoldersDic needReadCache:NO];
        
    }else
    {
        [self.fileListDataProvider getFilesByService:self.serviceArray.firstObject Folder:self.contentFolder needReadCache:NO];
    }
}

-(void) addDataInOtherThread
{
    // do something...
    // stop UI to refresh data
}

#pragma mark UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self isFileListSearchControllerActived]) {
        return 1;
    }
    
    if (tableView == self.drag2RefreshTableView && self.groupedKeys) {
        return self.groupedKeys.count;
    }else
    {
        return 1;
    }
    
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isFileListSearchControllerActived]) {
        return _filterData.count;
    }
    
    if (tableView == self.drag2RefreshTableView) {
        NSString *key = self.groupedKeys[section];
        NSMutableArray *groupFiles = self.groupedFileListDic[key];
        return groupFiles.count;
    }
    
    // for search display
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.name contains [cd] %@", self.drag2RefreshTableView.searchDisplayController.searchBar.text];
    _filterData = [[NSArray alloc] initWithArray:[self.contentDataArray filteredArrayUsingPredicate:predicate]];
    return _filterData.count;
}

-(NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self isFileListSearchControllerActived]) {
        return nil;
    }
    
    if (tableView == self.drag2RefreshTableView) {
        NSString *key = self.groupedKeys[section];
        return key;
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NXFileBase *fileData = nil;
    if ([self isFileListSearchControllerActived]) {
        
        fileData = self.filterData[indexPath.row];
        
    }else
    {
        if (tableView == self.drag2RefreshTableView) {
            fileData = [self fileItemAtIndex:indexPath];
        }else
        {
            fileData = self.filterData[indexPath.row];
        }
    }
    UIImage *cellImage = nil;
    UIImage *cellLeftImage = nil;
    UIImage *cellRightImage = nil;
    if ([fileData isKindOfClass:[NXFolder class]] || [fileData isKindOfClass:[NXSharePointFolder class]]) {
        cellImage = [UIImage imageNamed:@"Folder"];
    } else {
        NSString *imageName = [NXCommonUtils getImagebyExtension:fileData.fullPath];
        cellImage = [UIImage imageNamed:imageName];
    }
    
    if (fileData.isFavorite) {
        cellLeftImage = [UIImage imageNamed:@"FavoriteIcon"];
    } else {
        cellLeftImage = [UIImage imageNamed:@"emptyIcon"];
    }
    
    if (fileData.isOffline) {
        cellRightImage = [UIImage imageNamed:@"OfflineIcon"];
    } else {
        cellRightImage = [UIImage imageNamed:@"emptyIcon"];
    }
    
    
    NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
    [dateFormtter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormtter setTimeStyle:NSDateFormatterNoStyle];
    NSString* modifyDateString = [dateFormtter stringFromDate:fileData.lastModifiedDate];
    //const int byteToKB = 1024;
    NSString* fileSizeString = nil;
    
    if ([fileData isKindOfClass:[NXFile class]] || [fileData isKindOfClass:[NXSharePointFile class]]) {
        fileSizeString = [NSByteCountFormatter stringFromByteCount:fileData.size countStyle:NSByteCountFormatterCountStyleBinary];
    }

    NSString* subTitleString = fileSizeString?[NSString stringWithFormat:@"%@, %@", fileSizeString, modifyDateString?modifyDateString:@""]:(modifyDateString?modifyDateString:@"");
    
    
    NSString* cellSubTitle = subTitleString;
    
    static NSString *cellIdentify = @"FILE_LIST_CELL_IDENTIFY";
    static NSString *cellSelIdentify = @"FILE_LIST_SELECTED_CELL_IDENTIFY";
    
    NXFileListTableViewCell *cell = nil;
    
    // Keep cell selected status, for file list view will refresh, so we need keep selected status by manual
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    DetailViewController* fileContentVC = nil;
    for(UIViewController *vc in app.detailNav.viewControllers)
    {
        if ([vc isKindOfClass:[DetailViewController class]]) {
            fileContentVC = (DetailViewController*)vc;
            break;
        }
    }
    if (fileContentVC && [fileContentVC.curFile.fullServicePath isEqualToString:fileData.fullServicePath]) {
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellSelIdentify];
        if (cell == nil) {
            cell = [[NXFileListTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellSelIdentify];
        }
        cell.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
    }else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
        if (cell == nil) {
            cell = [[NXFileListTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentify];
        }
    }
    
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    cell.imageView.contentMode = UIViewContentModeScaleAspectFill;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    cell.textLabel.text = fileData.name;
    
    
    cell.imageView.image = cellImage;
    cell.leftImageView.image = cellLeftImage;
    cell.rightImageView.image = cellRightImage;
    
    
    
    NSString *serviceAlias = [NXCommonUtils serviceAliasByServiceType:fileData.serviceType.integerValue ServiceAccountId:fileData.serviceAccountId];
    if (![cellSubTitle isEqualToString:@""]) {
        cellSubTitle = [NSString stringWithFormat:@"%@, %@", serviceAlias, cellSubTitle];
    }else
    {
         cellSubTitle = [NSString stringWithFormat:@"%@", serviceAlias];
    }
   
    cell.detailTextLabel.text = cellSubTitle;
    return cell;

}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NXFileBase *selNode = nil;
    if ([self isFileListSearchControllerActived]) {
        
        selNode = self.filterData[indexPath.row];
        
    }else
    {
        if (tableView == self.drag2RefreshTableView) {
            selNode = [self fileItemAtIndex:indexPath];
        }else
        {
            selNode = self.filterData[indexPath.row];
        }
    }
    
    NXBoundService* service = [NXCommonUtils getBoundServiceFromCoreData:selNode.serviceAccountId];
    CGRect position = [tableView rectForRowAtIndexPath:indexPath];
    position = CGRectOffset(position, -tableView.contentOffset.x, -tableView.contentOffset.y);
    if ([self.delegate respondsToSelector:@selector(fileListInfoViewVC:didAccessoryButtonTapped:inService:inPosition:)]) {
        [self.delegate fileListInfoViewVC:self didAccessoryButtonTapped:selNode inService:service inPosition:position];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(fileListInfoViewVC:didAccessoryButtonTapped:inService:)]) {
        [self.delegate fileListInfoViewVC:self didAccessoryButtonTapped:selNode inService:service];
    }
}

#pragma mark Drag2RefreshTableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NXFileBase *selNode = nil;
    
    if ([self isFileListSearchControllerActived]) {
        selNode = self.filterData[indexPath.row];
    }else
    {
        if (tableView == self.drag2RefreshTableView) {
            selNode = [self fileItemAtIndex:indexPath];
        }else
        {
            selNode = self.filterData[indexPath.row];
        }
    }

    NXBoundService* service = [NXCommonUtils getBoundServiceFromCoreData:selNode.serviceAccountId];
   // NSLog(@"cur service is %@ and curSelNode is %@ sername is %@", service.service_alias, selNode, selNode.serviceAlias);
    if ([selNode isKindOfClass:[NXFolder class]] || [selNode isKindOfClass:[NXSharePointFolder class]]) {
        
        if ([self.delegate respondsToSelector:@selector(fileListInfoViewVC:didSelectFolder:inService:)]) {
            [self.delegate fileListInfoViewVC:self didSelectFolder:selNode inService:service];
        }
    }else if([selNode isKindOfClass:[NXFile class]] || [selNode isKindOfClass:[NXSharePointFile class]])
    {
        if ([self.delegate respondsToSelector:@selector(fileListInfoViewVC:didSelectFile:inService:)]) {
            [self.delegate fileListInfoViewVC:self didSelectFile:selNode inService:service];
        }
    }
    
    [self reloadFileListTableView];
}
#pragma mark - NXFileListInfoDataProviderDelegate
- (void) fileListInfo:(NSArray *)files
           InServices:(NSArray *)services
              Folders:(NSMutableDictionary *) folders
                error:(NSError *)err
     fromDataProvider:(NXFileListInfoDataProvider *) dataProvider
       additionalInfo:(NSDictionary *)additionalInfo
{
    [[self.view viewWithTag:8808] removeFromSuperview];
    if (self.isGetFileForRefresh) {
        [self.drag2RefreshTableView didRefreshDragTableView];
    }
    // update data, the UI will change with SETTER
    // need to make new NSMutalbeArray to store to cut the link of dataProvider's property. for it property may removed
    if (err.code == NXRMC_ERROR_CODE_NOSUCHFILE) {
        if ([self.delegate respondsToSelector:@selector(fileListInfoViewVC:errorForFolderNotFound:)]) {
            [self.delegate fileListInfoViewVC:self errorForFolderNotFound:err];
        }
        return;
    }
    
    if (err.code == NXRMC_ERROR_CODE_CANCEL) {
        
        return;
    }
    
    if (!err && files.count == 0) {
        if (![self.drag2RefreshTableView viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG]) {
            [self showNoFileContentViewinView:self.drag2RefreshTableView];
            self.drag2RefreshTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
    } else {
        [[self.drag2RefreshTableView viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG] removeFromSuperview];
        self.drag2RefreshTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    self.contentDataArray = [NSMutableArray arrayWithArray:files];
    
    if ([self.delegate respondsToSelector:@selector(fileListInfoViewVCDidUpdateData:)]) {
        [self.delegate fileListInfoViewVCDidUpdateData:self];
    }
    if (self.isGetFileForRefresh) {
        self.isGetFileForRefresh = NO;
    }else
    {
        // OK now start update sync
        [dataProvider syncFileByServices:services withFolders:folders];
    }
    
    // display error content
    if (err.code == NXRMC_ERROR_NO_NETWORK) {
         [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"NETWORK_UNREACH_MESSAGE", nil)];
    }else
    {
        if (services.count > 1) {
            if (additionalInfo.count > 0) { // additional count > 0 means multi-service have error when get file
                NSString *errorMsg = NSLocalizedString(@"ALERTVIEW_MESSAGE_GETFILE_FAIL", nil);
                NSArray *serviceAliases = [additionalInfo allKeys];
                for (NSString *alias in serviceAliases) {
                    if (alias == serviceAliases.firstObject) {
                        errorMsg = [errorMsg stringByAppendingFormat:@" from %@", alias];
                    }else
                    {
                        errorMsg = [errorMsg stringByAppendingFormat:@", %@", alias];
                    }
                }
                
                errorMsg = [errorMsg stringByAppendingString:@"."];
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:errorMsg];
            }
        }else if(services.count == 1)
        {
            if (err) {
                if (err.localizedDescription) {
                    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:err.localizedDescription];
                }else
                {
                    NSString *errorMsg = [NSString stringWithFormat:@"%@.", NSLocalizedString(@"ALERTVIEW_TITLE", nil)];
                    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:errorMsg];
                }
                
            }
        }
    }
}


-(void) updateFileList:(NSArray *) files InServices:(NSArray *) services Folders:(NSMutableDictionary *) folders error:(NSError *) err fromDataProvider:(NXFileListInfoDataProvider *) dataProvider
{
    if (!err && files.count == 0) {
        [self showNoFileContentViewinView:self.drag2RefreshTableView];
        self.drag2RefreshTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    } else {
        [[self.drag2RefreshTableView viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG] removeFromSuperview];
        self.drag2RefreshTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    if (!err) {
       // NSLog(@"FileListVC sync FileList UI view stack is %@", self.navigationController.viewControllers);
        self.contentDataArray = [NSMutableArray arrayWithArray:files];
        if ([self.delegate respondsToSelector:@selector(fileListInfoViewVCDidUpdateData:)]) {
            [self.delegate fileListInfoViewVCDidUpdateData:self];
        }
    }else if(err.code == NXRMC_ERROR_CODE_NOSUCHFILE)
    {
        if ([self.delegate respondsToSelector:@selector(fileListInfoViewVC:errorForFolderNotFound:)]) {
            [self.delegate fileListInfoViewVC:self errorForFolderNotFound:err];
        }
    }
}

#pragma mark Tools function


-(BOOL) isFileListSearchControllerActived
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 8.0) {
        if (self.drag2RefreshTableView.searchController.isActive && ![self.drag2RefreshTableView.searchController.searchBar.text isEqualToString:@""]) {
            return YES;
        }
    }
    
    return NO;
}

-(NXFileBase *) fileItemAtIndex:(NSIndexPath *) indexPath
{
    if (indexPath.section < self.groupedKeys.count) {
        NSString *key = self.groupedKeys[indexPath.section];
        NSMutableArray *groupFiles = self.groupedFileListDic[key];
        
        NXFileBase* fileData = groupFiles[indexPath.row];
        return fileData;
    }
    return nil;
}

-(NXFileBase *) fileNextToFile:(NXFileBase *) file
{
    if ([file isKindOfClass:[NXFile class]] || [file isKindOfClass:[NXSharePointFile class]]) {
        NSUInteger curFileIndex = [self.contentDataArray indexOfObject:file];
        if (curFileIndex == NSNotFound) {
            return nil;
        }
        NSInteger fileIndex = ++curFileIndex;
        while (fileIndex < self.contentDataArray.count) {
            if ([self.contentDataArray[fileIndex] isKindOfClass:[NXFile class]] || [self.contentDataArray[fileIndex] isKindOfClass:[NXSharePointFile class]] ) {
                return self.contentDataArray[fileIndex];
            }
            ++fileIndex;
        }
    }
    return nil;
}
-(NXFileBase *) filePreToFile:(NXFileBase *) file
{
    if ([file isKindOfClass:[NXFile class]] || [file isKindOfClass:[NXSharePointFile class]] ) {
        NSUInteger curFileIndex = [self.contentDataArray indexOfObject:file];
        if (curFileIndex == NSNotFound) {
            return nil;
        }
        NSInteger fileIndex = --curFileIndex;
        while (fileIndex >=0) {
            if ([self.contentDataArray[fileIndex] isKindOfClass:[NXFile class]] || [self.contentDataArray[fileIndex] isKindOfClass:[NXSharePointFile class]] ) {
                return self.contentDataArray[fileIndex];
            }
            --fileIndex;
        }
    }
    return nil;
    
}

#pragma mark BroadCast response
-(void) ResponseToDeviceRotate
{
//    if (![NXCommonUtils isiPad]) {
//        if (self.continerView != nil) {
//            self.drag2RefreshTableView.frame = self.continerView.frame;
//        }
//    }
}

-(void) userPressedSortMenuBtn:(NSNotification *) notifyObj
{
   // NSLog(@"%@", notifyObj);
    NSString *sortName = self.curSortDict[SORT_OPT_NAME];
    if ([sortName isEqualToString:notifyObj.object]) {
        return;
    }else
    {
        for (NSDictionary *sortDict in self.sortOperationArray) {
            if ([sortDict[SORT_OPT_NAME] isEqualToString:notifyObj.object]) {
                self.curSortDict = sortDict;
            }
        }
    }
    
}

- (void) userOpenNewFile:(NSNotification *) notifyObj
{
    // Listen to user open new file notification, to show selected state of cell.
    [self reloadFileListTableView];
}

-(void) responseToRepoAliasUpdate:(NSNotification *) notification
{
    if ([self.defaultSortOptName isEqualToString:NSLocalizedString(@"SORT_OPT_REPO", nil)]) {
        SortOperationBlock sortOpt = self.curSortDict[SORT_OPT_BLOCK];
        _defaultSortOptName = self.curSortDict[SORT_OPT_NAME];
        sortOpt();
    }
    
    [self reloadFileListTableView];
}

#pragma mark - NXFileDatailInfomationViewDelegate

- (void) fileDetailInfomationView:(NXFileDetailInfomationView *)view switchValuedidChanged:(BOOL)changedValue file:(NXFileBase *)file inService:(NXBoundService *)service
{
    
    [self reloadFileListTableView];
}

#pragma mark UISearchResultsUpdating
// Called when the search bar's text or scope has changed or when the search bar becomes first responder.
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchString = [searchController.searchBar text];
    if (![searchString isEqualToString:@""]) {
        searchController.dimsBackgroundDuringPresentation = NO;
        NSPredicate *preicate = [NSPredicate predicateWithFormat:@"self.name contains [cd] %@", searchString];
        _filterData = [[NSArray alloc] initWithArray:[self.contentDataArray filteredArrayUsingPredicate:preicate]];
        [self reloadFileListTableView];
    }
   
}
#pragma mark UISearchControllerDelegate
- (void)willPresentSearchController:(UISearchController *)searchController;
{
    searchController.dimsBackgroundDuringPresentation = NO;
}
- (void)didDismissSearchController:(UISearchController *)searchController
{
    [self reloadFileListTableView];
}

#pragma mark UISearchDisplayDelegate
- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self.drag2RefreshTableView moveRefreshViewBackToTop];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
   // [self.drag2RefreshTableView moveToOriginalContentInset];
    self.edgesForExtendedLayout = UIRectEdgeAll;
}

#pragma mark - 

- (void)showNoFileContentViewinView:(UIView *)containerView;
{
    if ([containerView viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG]) {
        return;
    }
    UIView *noContentView = [[UIView alloc] init];
    noContentView.backgroundColor = [UIColor whiteColor];
    noContentView.tag = FILE_CONTENT_NO_CONTENT_VIEW_TAG;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emptyFolder"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel *label = [[UILabel alloc] init];
    label.minimumScaleFactor = 0.5;
    label.adjustsFontSizeToFitWidth = YES;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor colorWithRed:0.76 green:0.76 blue:0.79 alpha:1.0];
    label.text = NSLocalizedString(@"NO_FILE_IN_FOLDER", NULL);
    
    [noContentView addSubview:imageView];
    [noContentView addSubview:label];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:noContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:50]];
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:noContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:noContentView attribute:NSLayoutAttributeWidth multiplier:0.3 constant:0]];
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:50]];
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:noContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    [noContentView addConstraint:[NSLayoutConstraint constraintWithItem:label attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:noContentView attribute:NSLayoutAttributeWidth multiplier:0.5 constant:0]];
    
    [containerView addSubview:noContentView];
    noContentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [containerView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeHeight multiplier:1 constant:200]];
    //constant is 200 is avoid scroll the tableview will show cell separator line.
}
@end
