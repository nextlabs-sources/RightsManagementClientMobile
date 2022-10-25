//
//  NXCustomFileListViewController.m
//  文件属性列表测试
//
//  Created by nextlabs on 10/19/15.
//  Copyright © 2015 zhuimengfuyun. All rights reserved.
//

#import "NXCustomFileListViewController.h"
#import "NXFileListInfoViewController.h"
#import "NXFileDetailInfomationView.h"
#import "NXFileListTableViewCell.h"
#import "NXFileListTableViewCell.h"

#import "NXCacheManager.h"
#import "NXCommonUtils.h"
#import "NXLoginUser.h"


#import "NXSharePointFolder.h"
#import "NXSharePointFile.h"

#import "AppDelegate.h"
#import "NXDownloadManager.h"


#define IMAGE_TAG 9999

#define HEADER_TITLE_BACKGROUND_COLOR ([UIColor colorWithRed:1.0 green:245.0/255.0 blue:204.0/255.0 alpha:1])
#define HEADER_TITLE_COLOR ([UIColor colorWithRed:194.0/255.0 green:127.0/255.0 blue:0 alpha:1])


static NSString * const kCustomFileCellIdentifier  = @"cusomFileCellIdentifier";

@interface NXCustomFileListViewController ()<UITableViewDataSource, UITableViewDelegate, NXFileListInfoViewControllerDelegate, NXFileDetailInfomationViewDelegate,NXDownloadManagerDelegate, DetailViewControllerDelegate>
{
    NSMutableArray *_boundServicesData;  // store service which have bounded and have favorite files.
    NSMutableArray *_boundServicesDisplayData; // using in UI.
    NSMutableArray *_fileSysData;
    NSMutableArray *_fileSysDisPlayData;
}

@property (weak, nonatomic) IBOutlet UITableView *fileListTableView;


@end

@implementation NXCustomFileListViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    // Do any additional setup after loading the view.
//    [self initNavigationBar];
    
    [self initFileListTableViewDataSource];
    _fileListTableView.dataSource = self;
    _fileListTableView.delegate = self;
    [self addTableViewHeadView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userOpenNewFile:) name:NOTIFICATION_USER_OPEN_FILE object:nil];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.96 alpha:1.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.tabBarController.navigationController.navigationBarHidden = YES;
    [self initFileListTableViewDataSource];
    [self reloadData];
    
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.title = [self customFileListType];
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];

    
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopListenDownload];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - private method

- (void) initFileListTableViewDataSource {
    _boundServicesData = [[NSMutableArray alloc] init];
    _fileSysData = [[NSMutableArray alloc] init];
    _boundServicesDisplayData = [[NSMutableArray alloc] init];
    _fileSysDisPlayData = [[NSMutableArray alloc] init];
    
    for (NXBoundService *service in [NXLoginUser sharedInstance].boundServices) {
        NXFileBase *rootFolder = [[NXLoginUser sharedInstance] getRootFolderForService:service];
        if ([[self customFileList:[rootFolder ancestor] customFileListType:_fileListType] count]) {
            [_boundServicesData addObject:service];
            [_boundServicesDisplayData addObject:service];
            [_fileSysData addObject:rootFolder];
            [_fileSysDisPlayData addObject:rootFolder];
            [self downloadAllOfflineFiles:rootFolder];
        }
    }
}

- (void) updateFileListTableViewDataSource {
    [_fileSysDisPlayData removeAllObjects];
    [_boundServicesDisplayData removeAllObjects];
    for (int i = 0 ; i < _fileSysData.count; ++i) {
        NXFileBase *rootFolder = _fileSysData[i];
        if ([[self customFileList:[rootFolder ancestor] customFileListType:_fileListType] count]) {
            [_boundServicesDisplayData addObject:[_boundServicesData objectAtIndex:i]];
            [_fileSysDisPlayData addObject:[_fileSysData objectAtIndex:i]];
        }
    }
}

- (void) addTableViewHeadView {
    
    UILabel *headLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _fileListTableView.bounds.size.width, 30)];
    headLabel.text = [self generateHeadViewTitle];
    headLabel.textColor = HEADER_TITLE_COLOR;
    
    _fileListTableView.tableHeaderView = headLabel;
    _fileListTableView.tableHeaderView.backgroundColor = HEADER_TITLE_BACKGROUND_COLOR;
}

- (NXFileBase *) fileNextToFile:(NXFileBase *) file
{
    if ([file isKindOfClass:[NXFile class]] || [file isKindOfClass:[NXSharePointFile class]]) {
        NXCustomFileList *fileList = [self customFileList:[file ancestor] customFileListType:_fileListType];
        NSUInteger curFileIndex = [fileList IndexOfObject:file];
        if (curFileIndex != NSNotFound) {
            NSInteger fileIndex = ++curFileIndex;
            while (fileIndex < [fileList count]) {
                NXFileBase *fileNode = [fileList objectAtIndex:fileIndex];
                if ([fileNode isKindOfClass:[NXFile class] ] || [fileNode isKindOfClass:[NXSharePointFile class]]) {
                    return fileNode;
                }
                ++fileIndex;
            }
        }
        
        // not found in the service, go to the next service
        NSUInteger curRootFolderIndex = [_fileSysDisPlayData indexOfObject:[file ancestor]];
        NSInteger nextRootFolderIndex = ++curRootFolderIndex;
        if (nextRootFolderIndex < _fileSysDisPlayData.count) {
            NXFileBase *nextRootFolder = _fileSysDisPlayData[nextRootFolderIndex];
            NXCustomFileList *nextFileList = [self customFileList:nextRootFolder customFileListType:_fileListType];
            if ([nextFileList count] > 0) {
                NXFileBase *nextFile = [nextFileList objectAtIndex:0];
                return [self findNextFile:nextFile];
            }
            
        }
    }
    return nil;
}

- (NXFileBase *) findNextFile:(NXFileBase *) node;
{
    if ([node isKindOfClass:[NXFile class]] || [node isKindOfClass:[NXSharePointFile class]]) {
        return node;
    }
    
    NXCustomFileList *fileList = [self customFileList:[node ancestor] customFileListType:_fileListType];
    NSUInteger curFileIndex = [fileList IndexOfObject:node];
    if (curFileIndex != NSNotFound) {
        NSInteger fileIndex = ++curFileIndex;
        while (fileIndex < [fileList count]) {
            NXFileBase *fileNode = [fileList objectAtIndex:fileIndex];
            if ([fileNode isKindOfClass:[NXFile class] ] || [fileNode isKindOfClass:[NXSharePointFile class]]) {
                return fileNode;
            }
            ++fileIndex;
        }
        
        // not found in the service, go to the next service
        NSUInteger curRootFolderIndex = [_fileSysDisPlayData indexOfObject:[node ancestor]];
        NSInteger nextRootFolderIndex = ++curRootFolderIndex;
        if (nextRootFolderIndex < _fileSysDisPlayData.count) {
            NXFileBase *nextRootFolder = _fileSysDisPlayData[nextRootFolderIndex];
            NXCustomFileList *nextFileList = [self customFileList:nextRootFolder customFileListType:_fileListType];
            if ([nextFileList count] > 0) {
                NXFileBase *nextFile = [nextFileList objectAtIndex:0];
                return [self findNextFile:nextFile];
            }
            
        }
    }
    
    return nil;

}

- (NXFileBase *) filePreToFile:(NXFileBase *) file
{
    if ([file isKindOfClass:[NXFile class]] || [file isKindOfClass:[NXSharePointFile class]]) {
        NXCustomFileList *fileList = [self customFileList:[file ancestor] customFileListType:_fileListType];
        NSUInteger curFileIndex = [fileList IndexOfObject:file];
        if (curFileIndex != NSNotFound) {
            NSInteger fileIndex = --curFileIndex;
            while (fileIndex >= 0) {
                NXFileBase *fileNode = [fileList objectAtIndex:fileIndex];
                if ([fileNode isKindOfClass:[NXFile class] ] || [fileNode isKindOfClass:[NXSharePointFile class]]) {
                    return fileNode;
                }
                --fileIndex;
            }
            
            // Not in the service, go to pre service
            NSUInteger curRootFolderIndex = [_fileSysDisPlayData indexOfObject:[file ancestor]];
            NSInteger preRootFolderIndex = --curRootFolderIndex;
            if (preRootFolderIndex >=0) {
                NXFileBase *preRootFolder = _fileSysDisPlayData[preRootFolderIndex];
                NXCustomFileList *preFileList = [self customFileList:preRootFolder customFileListType:_fileListType];
                if ([preFileList count] > 0) {
                    NXFileBase *preFile = [preFileList objectAtIndex:([preFileList count] - 1)];
                    return [self findPreFile:preFile];
                }
                
            }
        }
    }
    return nil;
}

- (NXFileBase *) findPreFile:(NXFileBase *) node
{
    if ([node isKindOfClass:[NXFile class]] || [node isKindOfClass:[NXSharePointFile class]]) {
        return node;
    }
    
    NXCustomFileList *fileList = [self customFileList:[node ancestor] customFileListType:_fileListType];
    NSUInteger curFileIndex = [fileList IndexOfObject:node];
    if (curFileIndex != NSNotFound) {
        NSInteger fileIndex = --curFileIndex;
        while (fileIndex >= 0) {
            NXFileBase *fileNode = [fileList objectAtIndex:fileIndex];
            if ([fileNode isKindOfClass:[NXFile class] ] || [fileNode isKindOfClass:[NXSharePointFile class]]) {
                return fileNode;
            }
            --fileIndex;
        }
        
        // Not in the service, go to pre service
        NSUInteger curRootFolderIndex = [_fileSysDisPlayData indexOfObject:[node ancestor]];
        NSInteger preRootFolderIndex = --curRootFolderIndex;
        if (preRootFolderIndex >=0) {
            NXFileBase *preRootFolder = _fileSysDisPlayData[preRootFolderIndex];
            NXCustomFileList *preFileList = [self customFileList:preRootFolder customFileListType:_fileListType];
            if ([preFileList count] > 0) {
                NXFileBase *preFile = [preFileList objectAtIndex:([preFileList count] - 1)];
                return [self findPreFile:preFile];
            }
            
        }
    }

    return nil;
    
}

- (NSString *) generateHeadViewTitle {
    NSInteger spectialFileCount = 0;
    for (NXFileBase *rootFolder in _fileSysData) {
        spectialFileCount += [[self customFileList:[rootFolder ancestor] customFileListType:_fileListType] count];
    }
    if (self.fileListType == CustomFileListTypeFavorite) {
        return [NSString stringWithFormat:@"  %@ %@ %lu %@, %ld %@",NSLocalizedString(@"ALL", null), NSLocalizedString(@"FAVORITE", nil), (unsigned long)_boundServicesDisplayData.count,NSLocalizedString(@"DRIVES", NULL), (long)spectialFileCount, NSLocalizedString(@"ITEMS", NULL)];
    }else
    {
        return [NSString stringWithFormat:@"  %@ %@ %lu %@, %ld %@",NSLocalizedString(@"ALL", null), NSLocalizedString(@"OFFLINE", nil), (unsigned long)_boundServicesDisplayData.count,NSLocalizedString(@"DRIVES", NULL), (long)spectialFileCount, NSLocalizedString(@"ITEMS", NULL)];
    }
}

- (NSString *) customFileListType {
    NSString *fileListType;
    switch (self.fileListType) {
        case CustomFileListTypeFavorite:
            fileListType = NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL);
            break;
        case CustomFileListTypeOffline:
            fileListType = NSLocalizedString(@"TAB_BAR_OFFLINE_TITLE", NULL);
            break;
        default:
            break;
    }
    return fileListType;
}

- (NXCustomFileList *) customFileList:(NXFileBase *) rootfolder customFileListType:(CustomFileListType ) type {
    NXCustomFileList *customFileList;
    switch (type) {
        case CustomFileListTypeFavorite:
            customFileList = rootfolder.favoriteFileList;
            break;
        case CustomFileListTypeOffline:
            customFileList = rootfolder.offlineFileList;
        default:
            break;
    }
    return customFileList;
}

- (void) reloadData {
    [self stopListenDownload];
    [self updateFileListTableViewDataSource];
    [self addTableViewHeadView];
    [self.fileListTableView reloadData];
    [self startListenDownload];
}

- (void) downloadAllOfflineFiles:(NXFileBase *) rootFolder {
    if (self.fileListType == CustomFileListTypeOffline) {
        for (NXFileBase *file in [rootFolder.offlineFileList allNodes]) {
            [NXDownloadManager startDownloadFile:file];
        }
    }
}

- (void) stopListenDownload {
    if (self.fileListType == CustomFileListTypeOffline) {
        [NXDownloadManager detachListener:self];
    }
}

- (void) startListenDownload {
    if (self.fileListType == CustomFileListTypeOffline) {
        for (NXFileBase *rootFolder  in _fileSysDisPlayData) {
            for (NXFileBase *offlineFile in [rootFolder.offlineFileList allNodes]) {
                [NXDownloadManager attachListener:self file:offlineFile];
            }
        }
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

#pragma mark - action method

- (void) backBarButtonItemClicked:(id) sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backbarButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _boundServicesDisplayData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NXFileBase *rootFolder = _fileSysDisPlayData[section];
    return [[self customFileList:[rootFolder ancestor] customFileListType:_fileListType] count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NXBoundService *service = _boundServicesDisplayData[section];
    NXFileBase *rootFolder = _fileSysDisPlayData[section];
    return [NSString stringWithFormat:@"%@ %ld %@", service.service_alias, (long)[[self customFileList:rootFolder customFileListType:_fileListType] count],NSLocalizedString(@"ITEMS", NULL)];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 1.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25.0f;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
   
    NXFileBase *rootFolder = _fileSysDisPlayData[indexPath.section];
    UIImage *cellImage = nil;
    UIImage *cellRightImage = nil;
    
    NXFileBase *cellData = [[self customFileList:rootFolder customFileListType:_fileListType] objectAtIndex:indexPath.row];
    if ([cellData isKindOfClass:[NXFolder class]]) {
        cellImage = [UIImage imageNamed:@"Folder"];
    }else if([cellData isKindOfClass:[NXSharePointFolder class]]){
        cellImage = [UIImage imageNamed:@"Folder"];
    } else  {
        NSString *imageName = [NXCommonUtils getImagebyExtension:cellData.fullPath];
        cellImage = [UIImage imageNamed:imageName];
    }
    
    NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
    [dateFormtter setDateStyle:NSDateFormatterShortStyle];
    [dateFormtter setTimeStyle:NSDateFormatterFullStyle];
    
    NSDate* modifyDate = [dateFormtter dateFromString:cellData.lastModifiedTime];
    [dateFormtter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormtter setTimeStyle:NSDateFormatterNoStyle];
    NSString* modifyDateString = [dateFormtter stringFromDate:modifyDate];
    
    NSString *strSize = [NSByteCountFormatter stringFromByteCount:cellData.size countStyle:NSByteCountFormatterCountStyleBinary];
    
    if (self.fileListType == CustomFileListTypeOffline && ([cellData isKindOfClass:[NXFile class]] || [cellData isKindOfClass:[NXSharePointFile class]])) {
        NXCacheFile *file = [NXCommonUtils getCacheFile:cellData];
        if (file) {
            cellRightImage = [UIImage imageNamed:@"FileCheck"];
        }
        else {
            cellRightImage = [UIImage imageNamed:@"FileSync"];
        }
    }
    
    NXFileListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCustomFileCellIdentifier];
    if (cell == nil) {
        cell = [[NXFileListTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCustomFileCellIdentifier];
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    
    cell.textLabel.text = cellData.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@", cellData.size?[NSString stringWithFormat:@"%@, ",strSize]:@"", modifyDateString?modifyDateString:@""];
    cell.rightImageView.image = cellRightImage;
    cell.imageView.image = cellImage;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.backgroundColor = [UIColor whiteColor];

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
    if (fileContentVC && [fileContentVC.curFile.fullServicePath isEqualToString:cellData.fullServicePath]) {
        
        cell.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
    }
    

    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NXFileBase *rootFolder = _fileSysDisPlayData[indexPath.section];
    NXFileBase *cellData = [[self customFileList:rootFolder customFileListType:_fileListType] objectAtIndex:indexPath.row];
    NXBoundService* service = _boundServicesDisplayData[indexPath.section];
    
    if ([cellData isKindOfClass:[NXFolder class]] || [cellData isKindOfClass:[NXSharePointFolder class]]) {
        NXFileListInfoViewController *fileListVC = [[NXFileListInfoViewController alloc] initWithFileServices:@[service] ContentFolder:cellData];
        fileListVC.delegate = self;
        [self.navigationController pushViewController:fileListVC animated:NO];
    }else if([cellData isKindOfClass:[NXFile class]] || [cellData isKindOfClass:[NXSharePointFile class]]) {
        
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
            [fileContentVC openFile:cellData currentService:service inCustomFileListViewController:self isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
        }
    }
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NXFileBase *rootFolder = _fileSysDisPlayData[indexPath.section];
    NXFileBase *cellData = [[self customFileList:rootFolder customFileListType:_fileListType] objectAtIndex:indexPath.row];
    NXFileDetailInfomationView *view;
    CGRect bound = self.navigationController.view.bounds;
    CGRect boundRect = CGRectMake(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height - self.tabBarController.tabBar.frame.size.height);
    view = [NXFileDetailInfomationView fileDetailInfoViewWithBounds:boundRect file:cellData filedelegate:self];
    view.currentVc = self;
    [self.navigationController.view addSubview:view];
    [view showFileDetailInfoView];
}

#pragma mark - NXFileListInfoViewControllerDelegate

- (void) fileListInfoViewVC:(NXFileListInfoViewController *) vc didSelectFolder:(NXFileBase *) folder inService:(NXBoundService *) service
{
    NSArray *serviceArray = [NSArray arrayWithObject:service];
    NXFileListInfoViewController *fileListVC = [[NXFileListInfoViewController alloc] initWithFileServices:serviceArray ContentFolder:folder];
    fileListVC.delegate = self;
    
    [self.navigationController pushViewController:fileListVC animated:NO];
    
}

-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc errorForFolderNotFound:(NSError *)error
{
    [self.navigationController popViewControllerAnimated:YES];
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

- (void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didAccessoryButtonTapped:(NXFileBase *)file inService:(NXBoundService *)service
{
    NXFileDetailInfomationView *view;
    CGRect bound = self.navigationController.view.bounds;
    CGRect boundRect = CGRectMake(bound.origin.x, bound.origin.y, bound.size.width, bound.size.height - self.tabBarController.tabBar.frame.size.height);
    view = [NXFileDetailInfomationView fileDetailInfoViewWithBounds:boundRect file:file filedelegate:vc];
    view.currentVc = vc;
    [self.navigationController.view addSubview:view];
    [view showFileDetailInfoView];
}

#pragma mark - NXFileDetailInfomationViewDelegate

- (void) fileDetailInfomationView:(NXFileDetailInfomationView *)view switchValuedidChanged:(BOOL)changedValue file:(NXFileBase *)file inService:(NXBoundService *)service {
    [self reloadData];
}

# pragma mark - NXDownloadManagerDelegate

- (void) downloadManagerDidFinish:(NXFileBase *)file intoPath:(NSString *)localCachePath error:(NSError *)error {
    if (file.isOffline) {
        [self reloadData];
    }
}

- (void) dealloc {
    NSLog(@"NXCustomFileListViewController dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark DetailViewControllerDelegate
- (void) detailViewController:(DetailViewController *) detailVC SwipeToNextFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inCustomFileListViewController:(NXCustomFileListViewController *) customFileListVC
{
    NXFileBase *nextFile = [customFileListVC fileNextToFile:file];
    if (nextFile) {
        [detailVC openFile:nextFile currentService:[NXCommonUtils getBoundServiceFromCoreData:nextFile.serviceAccountId] inCustomFileListViewController:customFileListVC isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
    }else{
        [detailVC showAutoDismissLabel:NSLocalizedString(@"SWIPE_NO_MORE_FILE_TO_SHOW", nil)];
    }
}
- (void) detailViewController:(DetailViewController *) detailVC SwipeToPreFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inCustomFileListViewController:(NXCustomFileListViewController *) customFileListVC
{
    NXFileBase *preFile = [customFileListVC filePreToFile:file];
    if (preFile) {
        [detailVC openFile:preFile currentService:[NXCommonUtils getBoundServiceFromCoreData:preFile.serviceAccountId] inCustomFileListViewController:customFileListVC isOpen3rdAPPFile:NO isOpenNewProtectedFile:NO];
    }else
    {
        [detailVC showAutoDismissLabel:NSLocalizedString(@"SWIPE_NO_MORE_FILE_TO_SHOW", nil)];
    }
}

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

#pragma mark Response to notification
-(void) userOpenNewFile:(NSNotification *) notification
{
    [self.fileListTableView reloadData];
}



@end
