//
//  NXFileAttrViewController.m
//  nxrmc
//
//  Created by helpdesk on 11/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXFileAttrViewController.h"

#import "NXFileAttrTableViewCell.h"
#import "NXAttrScrollView.h"
#import "MBProgressHUD.h"

#import "NXFile.h"
#import "NXCommonUtils.h"
#import "NXPolicyEngineWrapper.h"
#import "NXLoginUser.h"
#import "NXNetworkHelper.h"


#define FILEATTRCELLID (@"FileAttrCellID")

#define ERRORTABLEVIEW_TAG  2020
#define ERRORTABLECELLCOUNT  7

#define KB                  (1024)

#define HEADER_TITLE_BACKGROUND_COLOR ([UIColor colorWithRed:1.0 green:245.0/255.0 blue:204.0/255.0 alpha:1])
#define HEADER_TITLE_COLOR ([UIColor colorWithRed:194.0/255.0 green:127.0/255.0 blue:0 alpha:1])

@interface NXFileAttrViewController ()<UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource>
{
    NSMutableArray *_fileInfo;
    NSMutableArray *_rightsArray;
    NSString *_curFileLocalPath;
    NSInteger _previousPage;
}

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet NXAttrScrollView *scrollView;
@property (weak, nonatomic) UITableView *fileBasicInfoView;
@property (weak, nonatomic) UITableView *rightsView;

@end

@implementation NXFileAttrViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"FILEATTRIBUTE_ITEMTITLE1", NULL);
    
    // Do any additional setup after loading the view.
    
    self.scrollView.contentSize = self.scrollView.frame.size;
    
    //file's basic information
    UITableView *tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor whiteColor];
    self.fileBasicInfoView = tableView;
    self.fileBasicInfoView.estimatedRowHeight = 44.0; //using this line code to fix cell can not auto calculate height when rotation screen.
    if([self.fileBasicInfoView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
        self.fileBasicInfoView.cellLayoutMarginsFollowReadableWidth = NO;
    }
    
    [self.scrollView addPageView:tableView];

    if(self.isOpenThirdAPPFile) {
        _curFileLocalPath = _curFile.fullServicePath;
    } else {
        NXCacheFile *curFileCacheFile = [NXCommonUtils getCacheFile:self.curFile];
        _curFileLocalPath = curFileCacheFile.cache_path;
    }
    
    if ([NXMetaData isNxlFile:_curFileLocalPath]) {
        //nxl file's rights
        tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.backgroundColor = [UIColor whiteColor];
        self.rightsView = tableView;
        if([self.rightsView respondsToSelector:@selector(setCellLayoutMarginsFollowReadableWidth:)]) {
            self.rightsView.cellLayoutMarginsFollowReadableWidth = NO;
        }
        [self.scrollView addPageView:tableView];
    } else {
        self.pageControl.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fetchFileInfo];
    [self getRights];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - action method

- (IBAction)clickBack:(UIButton *)sender {
    [UIView  beginAnimations: @"animation2" context: nil];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5f];
    [self.navigationController popViewControllerAnimated:YES];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
    [UIView commitAnimations];
}

- (IBAction)pageChanged:(UIPageControl *)sender {
    NSInteger page = sender.currentPage;
    CGPoint offset = CGPointMake(self.scrollView.frame.size.width * page, 0);
    self.scrollView.contentOffset = offset;
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    NSInteger currentPage = self.pageControl.currentPage = self.scrollView.currentPage;
    if(currentPage == _previousPage) {
        return;
    }
    switch (currentPage) {
        case 0:
            self.navigationItem.title = NSLocalizedString(@"FILEATTRIBUTE_ITEMTITLE1", NULL);
            self.navigationItem.rightBarButtonItem = nil;
            break;
        case 1:
            self.navigationItem.title = NSLocalizedString(@"FILEATTRIBUTE_ITEMTITLE3", NULL);
            self.navigationItem.rightBarButtonItem = nil;
            break;
        default:
            break;
    }
    _previousPage = currentPage;
}

#pragma mark - private method

- (void)fetchFileInfo
{
    if(_fileInfo == nil) {
        _fileInfo = [[NSMutableArray alloc]init];
    } else {
        [_fileInfo removeAllObjects];
    }
    
    NSDictionary *fileName = [NSDictionary dictionaryWithObject:(_curFile.name ? _curFile.name : @"") forKey:NSLocalizedString(@"FILEATTRIBUTE_NAME", NULL)];
    [_fileInfo addObject:fileName];
    
    NSDictionary *fileFullPath = [NSDictionary dictionaryWithObject:(_curFile.fullPath ? _curFile.fullPath : @"") forKey:NSLocalizedString(@"FILEATTRIBUTE_Location", NULL)];
    [_fileInfo addObject:fileFullPath];
    
    NSString *fileSize = [NSByteCountFormatter stringFromByteCount:_curFile.size countStyle:NSByteCountFormatterCountStyleBinary];
    NSDictionary *fileSizeDic = [NSDictionary dictionaryWithObject:fileSize forKey:NSLocalizedString(@"FILEATTRIBUTE_SIZE", NULL)];
    [_fileInfo addObject:fileSizeDic];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    NSDate *localLastModifydate = [dateFormatter dateFromString:_curFile.lastModifiedTime];
    NSString *lastModifydateString = [NSDateFormatter localizedStringFromDate:localLastModifydate
                                                                    dateStyle:NSDateFormatterMediumStyle
                                                                    timeStyle:NSDateFormatterMediumStyle];
    NSDictionary *lastModofyDateStr = [NSDictionary dictionaryWithObject:lastModifydateString forKey:NSLocalizedString(@"FILEATTRIBUTE_MODIFYTIME", NULL)];
    [_fileInfo addObject:lastModofyDateStr];
    
    __block NSString *extension = nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        extension = [NXCommonUtils getExtension:_curFileLocalPath error:nil];
        if (extension) {
            NSDictionary *fileExtension = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@".%@", extension] forKey:NSLocalizedString(@"FILEATTRIBUTE_TYPE",NULL)];
            //insert because file extension postion in tableview.
            [_fileInfo insertObject:fileExtension atIndex:1];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fileBasicInfoView reloadData];
        });
    });
    [self.fileBasicInfoView reloadData];
}

- (void)getRights {
    if(_curFileLocalPath)
    {
        if ([NXMetaData isNxlFile:_curFileLocalPath])
        {
            _rightsArray = [[NSMutableArray alloc]init];
            NSArray *aryRights = [NXRights getSupportedContentRights];
            [aryRights enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *element = (NSDictionary *)obj;
                [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [_rightsArray addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[self.curRights getRight:[obj longValue]]] forKey:key]];
                }];
            }];
            
            aryRights = [NXRights getSupportedCollaborationRights];
            [aryRights enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *element = (NSDictionary *)obj;
                [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [_rightsArray addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[self.curRights getRight:[obj longValue]]] forKey:key]];
                }];
            }];
            
            aryRights = [NXRights getSupportedObs];
            [aryRights enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *element = (NSDictionary *)obj;
                [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                    [_rightsArray addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[self.curRights getObligation:[obj longValue]]] forKey:key]];
                }];
            }];
        }
    }
    
    [self.rightsView reloadData];
    return;
}

- (void)show:(NSString *)text inView:(UIView *)view
{
    if (view == nil)
    {
        view = [[UIApplication sharedApplication].windows lastObject];
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.labelText = text;
    hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]];
    hud.mode = MBProgressHUDModeCustomView;
    hud.removeFromSuperViewOnHide = YES;
    [hud hide:YES afterDelay:0.9];
}

- (void)showAlertView:(NSString*)title message:(NSString*)message
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(systemVersion >= 8.0)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BOX_OK", NULL)
                                                               style:UIAlertActionStyleCancel handler:nil];
        
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        UIAlertView* view = [[UIAlertView alloc] initWithTitle:title
                                                       message: message
                                                      delegate:NULL
                                             cancelButtonTitle:NSLocalizedString(@"BOX_OK", NULL)
                                             otherButtonTitles:NULL, nil];
        [view show];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(tableView == self.fileBasicInfoView)
    {
         return _fileInfo.count;
    }
    else if(tableView == self.rightsView)
    {
        return _rightsArray.count;
    }
    else if (tableView.tag == ERRORTABLEVIEW_TAG)
    {
        return ERRORTABLECELLCOUNT;
    }
    else
    {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView == self.fileBasicInfoView)
    {
        NXFileAttrTableViewCell *cell = [NXFileAttrTableViewCell fileAttrTableViewCellWithTableView:tableView];
        
        cell.infoName.textColor = [UIColor blueColor];
        cell.infoValue.lineBreakMode = NSLineBreakByWordWrapping;
        cell.infoValue.numberOfLines = 0;
        if(indexPath.row == _fileInfo.count - 1) {
            cell.showSeperator = NO;
        }
        
        NSDictionary *dic = _fileInfo[indexPath.row];
        cell.infoName.text = [[dic allKeys] objectAtIndex:0];
        cell.infoValue.text = [dic objectForKey:[[dic allKeys] objectAtIndex:0]];
        
        return cell;
    }
    else if(tableView == self.rightsView)
    {
        static NSString *rightsCell = @"rightsCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:rightsCell];
        if(cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:rightsCell];
        }
        
        NSDictionary *model = [_rightsArray objectAtIndex:indexPath.row];
        
        [model enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            cell.textLabel.text = key;
            if ([obj boolValue]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }];
        
        return cell;
    }
    else if (tableView.tag == ERRORTABLEVIEW_TAG)
    {
        static NSString *errorCell = @"errorCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:errorCell];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:errorCell];
        }
        if (indexPath.row == ERRORTABLECELLCOUNT - 1) {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"FAILED_GET_FILE_TAGS", NULL);
            cell.textLabel.textColor = [UIColor colorWithRed:0.800 green:0.800 blue:0.800 alpha:1.00];
        }
        return cell;
    }
    else
    {
        return nil;
    }

}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (self.isSteward && tableView == self.rightsView) {
        return NSLocalizedString(@"Steward_DESC_DETAIL", NULL);
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *)view;
    if (self.isSteward && tableView == self.rightsView) {
        headerView.textLabel.text= [self tableView:tableView titleForHeaderInSection:section];
        headerView.textLabel.numberOfLines = 0;
        headerView.textLabel.textColor = HEADER_TITLE_COLOR;
        headerView.textLabel.font = [UIFont systemFontOfSize:17];
        headerView.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        headerView.textLabel.textAlignment = NSTextAlignmentLeft;
        headerView.backgroundView.backgroundColor = HEADER_TITLE_BACKGROUND_COLOR;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (self.isSteward && tableView == self.rightsView) {
        return UITableViewAutomaticDimension;
    }
    return 0.01;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
