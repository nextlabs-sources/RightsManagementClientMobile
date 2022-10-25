//
//  NXFileDetailInfomationView.m
//  nxrmc
//
//  Created by nextlabs on 10/21/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXFileDetailInfomationView.h"

#import "NXFileAttrTableViewCell.h"
#import "NXFileDetailInfoActionTableViewCell.h"
#import "NXFileDetailInfoFileAttriTableViewCell.h"

#import "NXAdHocSharingViewController.h"

#import "NXCacheManager.h"
#import "NXCommonUtils.h"
#import "NXRMCDef.h"
#import "NXDownloadManager.h"

#import "NXFile.h"
#import "NXSharePointFile.h"
#import "NXFolder.h"
#import "NXSharePointFolder.h"

#import "NXNetworkHelper.h"
#import "NXLoginUser.h"
#import "NXPolicyEngineWrapper.h"
#import "AppDelegate.h"
#import "NXLogAPI.h"
#import "NXSyncHelper.h"

#define FAVORITE_SWITCH_TAG             1212
#define OFFLINE_SWITCH_TAG              1213
#define PROGRESSBAR_VIEW_TAG            1214
#define ACTION_VIEW_TAG                 1225

#define OBSERVERNAMEFAVORITE    @"isFavorite"
#define OBSERVERNAMEOFFLINE     @"isOffline"

#define WIDTHRATE   0.8

static NSString * const kFileBaseInfoCellIdentifier = @"baseInfoCellIdentifer";
static NSString * const kActionCellIdentifier       = @"actionCellIdentifier";
static NSString * const kSwitchCellIdentifier       = @"switchCellIdentifier";
static NSString * const kFileInfoCellIdentifier     = @"fileInfoCellIdentifier";
static NSString * const kRightsCellIdentifier       = @"rightsCellIdentifier";

@interface NXFileDetailInfomationView()<UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate,UICollectionViewDataSource, UICollectionViewDelegate, NXDownloadManagerDelegate, NXServiceOperationDelegate>

@property (strong, nonatomic) id<NXServiceOperation> serviceOperation;
@property (strong, nonatomic) NSString *localCachePath;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UITableView *fileInfoTableView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBarView;
@property (weak, nonatomic) IBOutlet UISwitch *offlineSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *favoriteSwitch;

@property (strong, nonatomic) NSMutableArray *tableViewData;

@property (strong, nonatomic) NSArray *swichSectionKeys;
@property (strong, nonatomic) NSArray *basicInfoKeys;
@property (strong, nonatomic) NSArray *actionValues;

@property (strong, nonatomic) NXRights *rights;
@property (nonatomic) BOOL isDownloaded;
@property (nonatomic) BOOL isNxl;
@property (nonatomic) BOOL isSteward;

@property (nonatomic) BOOL isShareFileClicked; //this bool is used to define user clicked share file. TRUE means shareFile.
@property (nonatomic) BOOL isProtectFileClicked; //this bool is used to define user clicked share file. TRUE means shareFile.

@end

@implementation NXFileDetailInfomationView

+ (instancetype)fileDetailInfoViewWithBounds:(CGRect)bounds file:(NXFileBase *)file filedelegate:(id<NXFileDetailInfomationViewDelegate>)delegate {
    NXBoundService *service = [NXCommonUtils getBoundServiceFromCoreData:file.serviceAccountId];
    NXFileDetailInfomationView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:nil options:nil]lastObject];
    view.file = file;
    view.fileService = service;
    view.fileInfodelegate = delegate;
    view.tag = FILEDETAILINFO_VIEW_TAG;
    view.clipsToBounds  = YES;
    [view initGesture];
    view.frame = bounds;
    view.containerView.frame = CGRectMake(view.frame.size.width, 0, view.frame.size.width * WIDTHRATE, view.frame.size.height);
    view.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    [view initData:file service:service];
    [view.file addObserver:view forKeyPath:OBSERVERNAMEFAVORITE options:NSKeyValueObservingOptionNew context:nil];
    [view.file addObserver:view forKeyPath:OBSERVERNAMEOFFLINE options:NSKeyValueObservingOptionNew context:nil];
    
    return view;
}

+ (instancetype)fileDetailInfoView:(NXFileBase *)file Service:(NXBoundService *) service filedelegate:(id<NXFileDetailInfomationViewDelegate>) delegate {
    NXFileDetailInfomationView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:nil options:nil]lastObject];
    view.file = file;
    view.fileService = service;
    view.fileInfodelegate = delegate;
    view.tag = FILEDETAILINFO_VIEW_TAG;
    view.clipsToBounds  = YES;
    [view initGesture];
    view.frame = [NXCommonUtils getScreenBounds];
    view.containerView.frame = CGRectMake(view.frame.size.width, 0, view.frame.size.width * WIDTHRATE, view.frame.size.height);
    [view initData:file service:service];
    [view.file addObserver:view forKeyPath:OBSERVERNAMEFAVORITE options:NSKeyValueObservingOptionNew context:nil];
    [view.file addObserver:view forKeyPath:OBSERVERNAMEOFFLINE options:NSKeyValueObservingOptionNew context:nil];

    return view;
}

#pragma mark - init tableView dataSource method

- (void)initData:(NXFileBase *)file service:(NXBoundService *)service {
    NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:file];
    self.localCachePath = cacheFile.cache_path;
    if (cacheFile) {
        if ([[NXNetworkHelper sharedInstance] isNetworkAvailable] && [NXMetaData isNxlFile:cacheFile.cache_path]) {
            self.serviceOperation = [NXCommonUtils createServiceOperation:service];
            [self.serviceOperation setDelegate:self];
            [self.serviceOperation getMetaData:file];
            [self createWaitingView];
            self.isDownloaded = NO;
        } else {
            self.isDownloaded = YES;
        }
    } else {
        self.isDownloaded = NO;
    }
    self.isSteward = NO;
    [self initTableViewData:self.isDownloaded];
}

- (void)initTableViewData:(BOOL)useCache {
    NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:self.file];
    self.localCachePath = cacheFile.cache_path;
    if (useCache) {
        self.isDownloaded = YES;
        [self updateProgress:1.0f];
    } else {
        self.isDownloaded = NO;
        [NXDownloadManager attachListener:self file:self.file];
        NSString *extension = [self.file.fullPath pathExtension];
        NSString *markExtension = [NSString stringWithFormat:@".%@", extension];
        if ([markExtension compare:NXLFILEEXTENSION options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            _isNxl = YES;
        } else {
            _isNxl = NO;
        }
    }
    
    if (self.isDownloaded) {
        if (self.isNxl) {
            [self createWaitingView];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                __block NSDictionary *token;
                __block NSError *error;
                [NXMetaData getFileToken:cacheFile.cache_path tokenDict:&token error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self removeWaitingview];
                    if (error) {
                        // network error or no permission
                        NSLog(@"get file token failed: %@", error);
                        if (error.code == HTTP_ERROR_CODE_ACCESS_FORBIDDEN) {
                            //                        [NXCommonUtils showAlertViewInViewController:self.currentVc title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:@"NO_SHARE_RIGHT"];
                        } else {
                            [NXCommonUtils showAlertViewInViewController:self.currentVc title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"ALERT_MESSAGE_GET_RIGHTS_FAILED", NULL)];
                        }
                    } else {
                        NXRights *rights;
                        NSMutableDictionary *obs;
                        NSMutableArray *hitPolicy;
                        __block NSString *owner = nil;
                        [NXMetaData getOwner:self.localCachePath complete:^(NSString *ownerId, NSError *error) {
                            owner = ownerId;
                        }];
                        
                        self.isSteward = [NXCommonUtils isStewardUser:owner];
                        
                        [[NXPolicyEngineWrapper sharedPolicyEngine] getRights:cacheFile.cache_path username:[NXLoginUser sharedInstance].profile.userName uid:[NXLoginUser sharedInstance].profile.userId rights:&rights obligations:&obs hitPolicies:&hitPolicy];
                        self.rights = rights;
                    }
                    
                    if (self.isShareFileClicked) {
                        [self openShareFileView];
                        self.isShareFileClicked = NO;
                    }
                    if (self.isProtectFileClicked) {
                        [self openProtectFileView];
                        self.isProtectFileClicked = NO;
                    }
                    [self initTableViewDataSouce];
                });
            });
        }else{  // not nxl file
            if (self.isShareFileClicked) {
                [self openShareFileView];
                self.isShareFileClicked = NO;
            }
            if (self.isProtectFileClicked) {
                [self openProtectFileView];
                self.isProtectFileClicked = NO;
            }
            [self initTableViewDataSouce];
        }
    } else {
        [self initTableViewDataSouce];
    }
}

- (void)initTableViewDataSouce {
    //this initData order can not be changed.
    self.tableViewData = [[NSMutableArray alloc] init];
    [self initActionSectionDataSource];
    [self initRightsSectionDataSource];
    [self initSwitchInfoSectionDataSource];
    [self initFileBasicSectionDataSource];
    [self.fileInfoTableView reloadData];
}

- (void)initActionSectionDataSource {
    if (_isNxl) {
//        self.actionValues = @[@[NSLocalizedString(@"ACTION_SHARE", NULL),[UIImage imageNamed:@"OpenIn"]],
//                              @[NSLocalizedString(@"ACTION_CLASSIFY", NULL),[UIImage imageNamed:@"Content"]]];
//        
        self.actionValues = @[@[NSLocalizedString(@"ACTION_SHARE", NULL),[UIImage imageNamed:@"OpenIn"]]];
        
    } else {
//        self.actionValues = @[@[NSLocalizedString(@"ACTION_SHARE", NULL),[UIImage imageNamed:@"OpenIn"]],
//                              @[NSLocalizedString(@"ACTION_PROTECT", NULL),[UIImage imageNamed:@"Content"]]];
//        
        self.actionValues = @[@[NSLocalizedString(@"ACTION_SHARE", NULL),[UIImage imageNamed:@"OpenIn"]]];

    }
    if ([self.file isKindOfClass:[NXFolder class]] || [self.file isKindOfClass:[NXSharePointFolder class]]) {
        [self.tableViewData addObject:@[@""]];
    } else {
        [self.tableViewData addObject:@[@"", @""]];
    }
}

- (void)initSwitchInfoSectionDataSource {
    if ([self.file isKindOfClass:[NXFile class]] || [self.file isKindOfClass:[NXSharePointFile class]]) {
        self.swichSectionKeys = @[NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL), NSLocalizedString(@"TAB_BAR_OFFLINE_TITLE", NULL)];
    } else {
        self.swichSectionKeys = @[NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL)];
    }
//    self.swichSectionKeys = @[NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL)];
    
    NSMutableDictionary *switchSectionValues = [[NSMutableDictionary alloc] init];
    if ([self.file isKindOfClass:[NXFolder class]] || [self.file isKindOfClass:[NXSharePointFolder class]]) {
        [switchSectionValues setObject:[NSNumber numberWithBool:self.file.isFavorite] forKey:NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL)];
    } else {
        [switchSectionValues setObject:[NSNumber numberWithBool:self.file.isFavorite] forKey:NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL)];
        [switchSectionValues setObject:[NSNumber numberWithBool:self.file.isOffline] forKey:NSLocalizedString(@"TAB_BAR_OFFLINE_TITLE", NULL)];
    }
    [self.tableViewData addObject:switchSectionValues];
}

- (void)initRightsSectionDataSource {
    
    NSMutableArray *rightsData = [[NSMutableArray alloc] init];
    
    if (self.isNxl) {
        [rightsData addObject:[NSDictionary dictionaryWithObject:NSLocalizedString(@"RIGHTSTITLE", NULL) forKey:NSLocalizedString(@"RIGHTSTITLE", NULL)]];
    }
    if (self.isDownloaded && self.isNxl) {
        NSArray *aryRights = [NXRights getSupportedContentRights];
        [aryRights enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *element = (NSDictionary *)obj;
            [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([self.rights getRight:[obj longValue]]) {
                    [rightsData addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:key]];
                }
            }];
        }];
        
        aryRights = [NXRights getSupportedCollaborationRights];
        [aryRights enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *element = (NSDictionary *)obj;
            [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([self.rights getRight:[obj longValue]]) {
                    [rightsData addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:key]];
                }
            }];
        }];
        
        aryRights = [NXRights getSupportedObs];
        [aryRights enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *element = (NSDictionary *)obj;
            [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([self.rights getObligation:[obj longValue]]) {
                    [rightsData addObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:key]];
                }
            }];
        }];
    }
    
    if (self.isNxl) {
        [self.tableViewData addObject:rightsData];
    }
}

- (void)initFileBasicSectionDataSource {
    if ([self.file isKindOfClass:[NXFile class]] || [self.file isKindOfClass:[NXSharePointFile class]]) {
        self.basicInfoKeys= @[NSLocalizedString(@"INFO", NULL),
                              NSLocalizedString(@"FILE_INFO_ACCOUNT", NULL),
                              NSLocalizedString(@"FILE_INFO_DRIVETYPE", NULL),
                              NSLocalizedString(@"FILE_INFO_LOCATION", NULL),
                              NSLocalizedString(@"FILE_INFO_SIZE", NULL),
                              NSLocalizedString(@"FILE_INFO_MODIFIED", NULL)];
    } else {
        self.basicInfoKeys= @[NSLocalizedString(@"INFO", NULL),
                              NSLocalizedString(@"FILE_INFO_ACCOUNT", NULL),
                              NSLocalizedString(@"FILE_INFO_DRIVETYPE", NULL),
                              NSLocalizedString(@"FILE_INFO_LOCATION", NULL),
                              NSLocalizedString(@"FILE_INFO_MODIFIED", NULL)];
    }
    NSMutableDictionary *basicInfoValues = [[NSMutableDictionary alloc] init];
    [basicInfoValues setObject:@""forKey:NSLocalizedString(@"FILE_INFO_INFO", NULL)];
    if (self.fileService.service_account) {
        [basicInfoValues setObject:self.fileService.service_account forKey:NSLocalizedString(@"FILE_INFO_ACCOUNT", NULL)];
    } else{
        [basicInfoValues setObject:@"" forKey:NSLocalizedString(@"FILE_INFO_ACCOUNT", NULL)];
    }
   
    [basicInfoValues setObject: [NXCommonUtils convertRepoTypeToDisplayName:self.fileService.service_type] forKey:NSLocalizedString(@"FILE_INFO_DRIVETYPE", NULL)];

    NSString *location = self.file.fullPath;
//    if ([self.file isKindOfClass:[NXFile class]] || [self.file isKindOfClass:[NXSharePointFile class]]) {
//        location = [self.file.fullPath stringByDeletingLastPathComponent];
//    }
    if (![location isEqualToString:@""]) {
         [basicInfoValues setObject:location forKey:NSLocalizedString(@"FILE_INFO_LOCATION", NULL)];
    } else {
         [basicInfoValues setObject:@"/" forKey:NSLocalizedString(@"FILE_INFO_LOCATION", NULL)];
    }
    
    if ([self.file isKindOfClass:[NXFile class]] || [self.file isKindOfClass:[NXSharePointFile class]]) {
        NSString *strSize = [NSByteCountFormatter stringFromByteCount:self.file.size countStyle:NSByteCountFormatterCountStyleBinary];
        if (strSize) {
            [basicInfoValues setObject:strSize forKey:NSLocalizedString(@"FILE_INFO_SIZE", NULL)];
        } else {
            [basicInfoValues setObject:@"" forKey:NSLocalizedString(@"FILE_INFO_SIZE", NULL)];
        }
    }
    if (self.file.lastModifiedTime) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
        NSDate *localLastModifydate = [dateFormatter dateFromString:self.file.lastModifiedTime];
        NSString *lastModify = [NSDateFormatter localizedStringFromDate:localLastModifydate
                                                                        dateStyle:NSDateFormatterMediumStyle
                                                                        timeStyle:NSDateFormatterMediumStyle];
        NSString *str = [NSString stringWithFormat:@"%@", lastModify];
        if (str) {
            [basicInfoValues setObject:str forKey:NSLocalizedString(@"FILE_INFO_MODIFIED", NULL)];
        } else {
            [basicInfoValues setObject:@"" forKey:NSLocalizedString(@"FILE_INFO_MODIFIED", NULL)];
        }
        
    } else {
        [basicInfoValues setObject:@"" forKey:NSLocalizedString(@"FILE_INFO_MODIFIED", NULL)];
    }
    
    [self.tableViewData addObject:basicInfoValues];
}

#pragma mark -

- (void)showFileDetailInfoView {
    
    if (self.superview) {
        CGRect frame = self.bounds;
        [UIView animateWithDuration:0.3 animations:^{
            self.containerView.frame = CGRectMake(frame.size.width * (1 - WIDTHRATE), 0, frame.size.width * WIDTHRATE, frame.size.height);
            self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        }];
    }
    [self addTapGesture];
    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }
}

#pragma mark

- (void)removeFileInfoView {
    if (!self.superview) {
        return;
    }
    CGRect frame = self.bounds;
    [UIView animateWithDuration:0.3 animations:^{
        self.containerView.frame = CGRectMake(frame.size.width, 0, frame.size.width *WIDTHRATE, frame.size.height);
        self.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
    
    //this code block shoud be peform only when offline flag changed. TBD
    NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:self.file];
    if (cacheFile) {
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [NXCommonUtils storeCacheFileIntoCoreData:self.file cachePath:cacheFile.cache_path];
        });
    }
    
    if (self.file.isOffline && !cacheFile) {
        [NXDownloadManager startDownloadFile:self.file];
    }
    [NXDownloadManager detachListener:self];
}

- (void)updateProgress:(CGFloat) progress {
    [self.progressBarView setProgress:progress];
}

- (void)downloadCurrentFile {
    if (![[NXNetworkHelper sharedInstance] isNetworkAvailable]) {
        [NXCommonUtils showAlertViewInViewController:self.currentVc title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"NETWORK_UNREACH_MESSAGE", NULL)];
        return;
    }
    
    if ([NXDownloadManager startDownloadFile:self.file]) {
        [self createWaitingView];
        [NXDownloadManager attachListener:self file:self.file];
    }
}

- (void)createWaitingView {
    UIView *waitingView = [NXCommonUtils createWaitingViewInView:self.containerView];
    waitingView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:waitingView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:waitingView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
}

- (void)removeWaitingview {
    UIView *waitingView = [self.containerView viewWithTag:8808];
    [waitingView removeFromSuperview];
}

#pragma mark

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.fileInfoTableView layoutSubviews];
}

- (void)dealloc {
    [self.file removeObserver:self forKeyPath:OBSERVERNAMEFAVORITE];
    [self.file  removeObserver:self forKeyPath:OBSERVERNAMEOFFLINE];
}

#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:OBSERVERNAMEFAVORITE]) {
        [_favoriteSwitch setOn:self.file.isFavorite animated:YES];
    } else if ([keyPath isEqualToString:OBSERVERNAMEOFFLINE]) {
        [_offlineSwitch setOn:self.file.isOffline animated:YES];
    }
}

#pragma mark -

- (void)initGesture {
    UISwipeGestureRecognizer *oneFingerSwipeleft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(oneFingerSwipeUp:)];
    oneFingerSwipeleft.numberOfTouchesRequired = 1;
    [oneFingerSwipeleft setDirection:UISwipeGestureRecognizerDirectionRight];
    [self addGestureRecognizer:oneFingerSwipeleft];
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handeTap:)];
    tap.delegate = self;
    [tap setNumberOfTapsRequired:1];
    [self addGestureRecognizer:tap];
}

#pragma mark - action method

- (void)handeTap:(UIGestureRecognizer*) gesture {
    [self removeFileInfoView];
}

- (IBAction)DoneButtonItemClicked:(UIButton *)sender {
    [self removeFileInfoView];
}

- (void)switchAction:(UISwitch *)switcher {
    if (switcher.tag == OFFLINE_SWITCH_TAG) {
        self.file.isOffline = switcher.isOn;
    }
    if (switcher.tag == FAVORITE_SWITCH_TAG) {
        self.file.isFavorite = switcher.isOn;
    }

    if (self.fileInfodelegate && [self.fileInfodelegate respondsToSelector:@selector(fileDetailInfomationView:switchValuedidChanged:file:inService:)]) {
        [self.fileInfodelegate fileDetailInfomationView:self switchValuedidChanged:[switcher isOn] file:self.file inService:self.fileService];
    }
}

- (void)oneFingerSwipeUp:(UISwipeGestureRecognizer *) gesture {
    [self DoneButtonItemClicked:nil];
}

- (void)rightButtonClicked:(UIButton *)sender {
    if (!self.isDownloaded) {
        [self downloadCurrentFile];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isDescendantOfView:self.containerView ]) {
        return NO;
    }
    return YES;
}

#pragma mark - CollectionViewCell action method

- (void)shareFile
{
    self.isShareFileClicked = YES;
    self.isProtectFileClicked = NO;
    if (!self.isDownloaded) {
        [self downloadCurrentFile];
        return;
    }
    [self openShareFileView];
}

//- (void)protectFile {
//    self.isProtectFileClicked = YES;
//    self.isShareFileClicked = NO;
//    if (!self.isDownloaded) {
//        [self downloadCurrentFile];
//        return;
//    }
//    [self openProtectFileView];
//}

- (void)openShareFileView {
    NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:self.file];
    
    __block BOOL isCurrentUser = NO;
     __block BOOL isNotNxlFile = NO;// this bool is used to define cacheFile is not nxlFile
    [NXMetaData getOwner:cacheFile.cache_path complete:^(NSString *ownerId, NSError *error) {
        if (error && error.code == NXRMC_ERROR_CODE_NXFILE_ISNOTNXL) {
            isNotNxlFile = YES;
        } else {
            isCurrentUser = [NXCommonUtils isStewardUser:ownerId];
        };
    }];
    
   if (isNotNxlFile || isCurrentUser || [self.rights SharingRight]) {
        NXAdHocSharingViewController* vc = [[NXAdHocSharingViewController alloc]init];
        vc.type = NXProtectTypeSharing;
        vc.curFilePath = cacheFile.cache_path;
        vc.curFile = self.file;
        vc.rights = self.rights;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        
        [self.currentVc.navigationController presentViewController:nav animated:YES completion:nil];
        
    } else {
        
        [NXCommonUtils showAlertViewInViewController:self.currentVc title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"NO_SHARE_RIGHT", NULL)];
        
        if (!isNotNxlFile) {  // when nxl file deny, should add log
            NSError *error = nil;
            NSString *duid = nil;
            NSData *pubKey = nil;
            NSString *owner = nil;
            NSString *ml = nil;
            
            [NXMetaData getNxlFile:cacheFile.cache_path duid:&duid publicAgrement:&pubKey owner:&owner ml:&ml error:&error];
            if (!error && duid && owner) {
                NXLogAPIRequestModel *model = [[NXLogAPIRequestModel alloc]init];
                model.duid = duid;
                model.owner = owner;
                model.operation = [NSNumber numberWithInteger:kShareOperation];
                model.repositoryId = @"";
                model.filePathId = self.file.fullServicePath;
                model.filePath = self.file.fullServicePath;
                model.fileName = self.file.fullServicePath;
                model.activityData = @"TestData";
                model.accessTime = [NSNumber numberWithLongLong:([[NSDate date] timeIntervalSince1970] * 1000)];
                model.accessResult = [NSNumber numberWithInteger:0];
        
                NXLogAPI *logAPI = [[NXLogAPI alloc]init];
                [logAPI generateRequestObject:model];
                [[NXSyncHelper sharedInstance] cacheRESTAPI:logAPI cacheURL:[NXCacheManager getLogCacheURL]];
                [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
                    
                }];
            }
            
        }

//
        
    }
//    [self removeFileInfoView];
}

- (void)openProtectFileView {
    // check if we have got the policy and labels file,if not,just hint user connect to the policy server
//    NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:self.file];
//    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    NXProtectViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"ProtectVC"];
//    vc.fileLocalCachePath = cacheFile.cache_path;
//    vc.curFile = self.file;
//    vc.curService = self.fileService;
//
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
// 
//   [self.currentVc.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - private method for generate UITableViewCell

- (UITableViewCell *)cellforActionSection:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        NXFileDetailInfoActionTableViewCell *cell = (NXFileDetailInfoActionTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kActionCellIdentifier];
        if (!cell) {
            cell = [[NXFileDetailInfoActionTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellIdentifier];
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFileBaseInfoCellIdentifier];
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kFileBaseInfoCellIdentifier];
            cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
            cell.textLabel.numberOfLines = 0;
            cell.backgroundColor = tableView.backgroundColor;
            cell.textLabel.font = [UIFont systemFontOfSize:15];
        }

        if ([self.file isKindOfClass:[NXFile class]] || [self.file isKindOfClass:[NXSharePointFile class]]) {
            NSString *imageName = [NXCommonUtils getImagebyExtension:self.file.fullPath];
            cell.imageView.image = [UIImage imageNamed:imageName];
        } else {
            cell.imageView.image = [UIImage imageNamed:@"Folder"];
        }
        cell.textLabel.text = self.file.name;
        
        return cell;
    }
}

- (UITableViewCell *)cellforSwitchInfoSection:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kSwitchCellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kSwitchCellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
    }
    NSDictionary *switchData = [self.tableViewData objectAtIndex:indexPath.section];
    NSNumber *value = [switchData objectForKey:self.swichSectionKeys[indexPath.row]];
    cell.textLabel.text = self.swichSectionKeys[indexPath.row];
    
    UISwitch *s = [[UISwitch alloc] init];
    [s setOn:value.boolValue];
    [s addTarget:self action:@selector(switchAction:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = s;
    if (indexPath.row == 0) {
        s.tag = FAVORITE_SWITCH_TAG;
        _favoriteSwitch = s;
    } else {
        s.tag = OFFLINE_SWITCH_TAG;
        _offlineSwitch  = s;
    }
    return cell;
}

- (UITableViewCell *)cellforRightsSection:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kRightsCellIdentifier];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kRightsCellIdentifier];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    NSArray *rightMode = self.tableViewData[indexPath.section];
    NSDictionary *element = [rightMode objectAtIndex:indexPath.row];
    
    [element enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        cell.textLabel.text = (NSString *)key;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }];
    
    if (indexPath.row == 0) {
        cell.backgroundColor = tableView.backgroundColor;
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, cell.contentView.frame.size.height)];
        [button setTitle:NSLocalizedString(@"RIGHTSSUBTITLE", NULL) forState:UIControlStateNormal];
        [button setTitleColor:RMC_MAIN_COLOR forState:UIControlStateNormal];
        [button addTarget:self action:@selector(rightButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (!self.isDownloaded) {
            cell.accessoryView = button;
        } else {
            cell.accessoryView = nil;
        }
        if (self.isSteward) {
            cell.detailTextLabel.text = NSLocalizedString(@"Steward_DESC", NULL);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        } else {
            cell.detailTextLabel.text = nil;
        }
    }
    
    return cell;
}

- (UITableViewCell *)cellforBasicInfoSection:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    NXFileDetailInfoFileAttriTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kFileInfoCellIdentifier];
    if (cell == nil) {
        cell = [NXFileDetailInfoFileAttriTableViewCell fileAttrTableViewCellWithTableView:tableView];
        cell.infoValue.textColor = [UIColor grayColor];
    }
    if (indexPath.row == 0) {
        cell.backgroundColor = tableView.backgroundColor;
        cell.infoName.font = [UIFont fontWithName:@"Helvetica-Bold" size:15];
    }
    NSDictionary *basicInfo = [self.tableViewData objectAtIndex:indexPath.section];
    NSString *value = [basicInfo objectForKey:self.basicInfoKeys[indexPath.row]];
    
    cell.infoName.text = self.basicInfoKeys[indexPath.row];
    cell.infoValue.text = value;
    return cell;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableDictionary *sectionData = self.tableViewData[section];
    return sectionData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1 && indexPath.section == 0) {
        return 70;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 5;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 5;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(NXFileDetailInfoActionTableViewCell*)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0 && indexPath.row == 1) {
         [cell setCollectionViewDataSourceDelegate:self indexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    switch (indexPath.section) {
        case 0:
        {
            cell = [self cellforActionSection:tableView atIndexPath:indexPath];
        }
            break;
        case 1:
        {
            if (self.isNxl) {
                cell = [self cellforRightsSection:tableView atIndexPath:indexPath];
            } else {
                cell = [self cellforSwitchInfoSection:tableView atIndexPath:indexPath];
            }
        }
            break;
        case 2:
        {
            if (self.isNxl) {
                cell = [self cellforSwitchInfoSection:tableView atIndexPath:indexPath];
            } else {
                cell = [self cellforBasicInfoSection:tableView atIndexPath:indexPath];
            }
        }
            break;
        case 3:
        {
            cell =[self cellforBasicInfoSection:tableView atIndexPath:indexPath];
        }
            break;
        default:
            break;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.layer.borderColor = [UIColor lightGrayColor].CGColor;
    cell.layer.borderWidth = 0.5f;
    return cell;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.actionValues.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *) collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    NSArray *celldata = [self.actionValues objectAtIndex:indexPath.row];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    view.tag = ACTION_VIEW_TAG;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[celldata objectAtIndex:1]];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [celldata objectAtIndex:0];
    label.font = [UIFont systemFontOfSize:12];
    label.textAlignment = NSTextAlignmentCenter;
    
    [view addSubview:imageView];
    [view addSubview:label];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = @{@"imageView" :imageView, @"sectionView": view, @"labelView": label};
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[imageView(30)]-5-[labelView]|" options:0 metrics:nil views:views]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[imageView(30)]-15-|" options:0 metrics:nil views:views]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[labelView]|" options:0 metrics:nil views:views]];
    
    [[cell.contentView viewWithTag:ACTION_VIEW_TAG] removeFromSuperview];
    [cell.contentView addSubview:view];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sectionView]|" options:0 metrics:nil views:views]];
    [cell.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sectionView]|" options:0 metrics:nil views:views]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [self shareFile];
        return;
    }
//    if (indexPath.row == 1) {
//        [self protectFile];
//    }
}

#pragma mark - NXDownloadManagerDelegate

- (void)downloadManagerDidFinish:(NXFileBase *)file intoPath:(NSString *)localCachePath error:(NSError *)error {
    [self removeWaitingview];
    if (error) {
        [NXCommonUtils showAlertViewInViewController:self.currentVc title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"PROTECTANDSHARE_OPERATION_FAILED", NULL)];
        return;
    }
    [self initTableViewData:YES];
}

- (void)downloadManagerDidProgress:(float)progress file:(NXFileBase *)file {
    [self updateProgress:progress];
}

#pragma mark - NXServiceOperationDelegate

- (void)getMetaDataFinished:(NXFileBase *)metaData error:(NSError *)err {
    [self removeWaitingview];
       if (!err && [self isFileModified:metaData]) {
        [self cleanCacheFile];
        [self updateMetaData:metaData];
        self.isDownloaded = NO;
    } else {
        self.isDownloaded = YES;
    }
    [self initTableViewData:self.isDownloaded];
}

-(BOOL)isFileModified:(NXFileBase *)metaData
{
    //now just compare the file's lastmodifiedtime,in the future can overwrite this method
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    NSDate *metadataLastModifydate = [dateFormatter dateFromString:metaData.lastModifiedTime];
    NSDate *localLastModifydate = [NXCommonUtils getLocalFileLastModifiedDate:_localCachePath];
    if (localLastModifydate) {
        return ([metadataLastModifydate compare:localLastModifydate] == NSOrderedDescending);
    } else {
        return YES;
    }
}

- (void)cleanCacheFile {
    //delete cache in coredata
    NXCacheFile *file = [NXCommonUtils getCacheFile:self.file];
    if(file) {
        [NXCommonUtils deleteCacheFileFromCoreData:file];
    }
    
    //detele cache file in disk
    if(self.localCachePath) {
        [[NSFileManager defaultManager] removeItemAtPath:self.localCachePath error:nil];
    }
}
- (void)updateMetaData:(NXFileBase *)metaData {
    // can update more file information
    if(![self.file.lastModifiedTime isEqualToString:metaData.lastModifiedTime]) {
        self.file.lastModifiedTime = metaData.lastModifiedTime;
    }
    if(self.file.size != metaData.size) {
        self.file.size = metaData.size;
    }
    if(![self.file.name isEqualToString:metaData.name]) {
        self.file.name = metaData.name;
    }
    
    if(![self.file.lastModifiedDate isEqualToDate:metaData.lastModifiedDate]) {
        self.file.lastModifiedDate = metaData.lastModifiedDate;
    }
}

@end
