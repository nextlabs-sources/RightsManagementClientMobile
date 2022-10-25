//
//  DetailViewController.m
//  nxrmc_hd
//
//  Created by EShi on 7/21/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "DetailViewController.h"
#import "NXGLKViewController.h"
#import "NXMasterSplitViewController.h"
#import "NXMasterTabBarViewController.h"
#import "NXFileAttrViewController.h"

#import "NXPrintInteractionController.h"

#import "NXDownloadView.h"
#import "NXOverlayView.h"
#import "MobileSurfaceView.h"
#import "NXDropDownMenu.h"

#import <MediaPlayer/MediaPlayer.h>
#import "MobileSurfaceViewDelegate.h"
#import "UserMobileSurface.h"

#import "AppDelegate.h"
#import "NXLoginUser.h"
#import "NXPolicyEngineWrapper.h"
#import "NXMetaData.h"
#import "NXServiceOperation.h"
#import "NXDownloadManager.h"
#import "NXFile.h"
#import "NXNetworkHelper.h"
#import "NXCommonUtils.h"

//#import "NXSyncData.h"
#import "NXConvertFile.h"

#import "NXFile.h"
#import "NXSharePointFile.h"
#import "NXAdHocSharingViewController.h"

#import "NXLogAPI.h"
#import "NXSyncHelper.h"
#import "NXHeartbeatManager.h"
#import "NXTokenManager.h"

@interface NSData(FOOBAARUIDocumentInteractionControllerFix)

- (NSString *)description;

@end

@implementation NSData(FOOBAARUIDocumentInteractionControllerFix)

-(NSString *)description { return @"The fix for UIDocumentInteractionController`s bug."; }

@end

typedef NS_ENUM(NSInteger, NXServiceOperationStatus) {
    NXSERVICEOPERATIONSTATUS_UNSET = 0,
    
    NXSERVICEOPERATIONSTATUS_DOWNLOADFILE,
    NXSERVICEOPERATIONSTATUS_GETMETADATA,
};

typedef NS_ENUM(NSInteger, NXViewTagType) {
    NXVIEWTAGTYPE_UNSET         = 0,
    NXVIEWTAGTYPE_STATUSVIEW    = 8808,
    NXVIEWTAGTYPE_OVERLAY       = 8809,
    NXVIEWTAGTYPE_3DVIEW        = 8810,
    NXVIEWTAGTYPE_VDSVIEW       = 8811,
    NXVIEWTAGTYPE_MEDIAVIEW     = 8812,
    NXVIEWTAGTYPE_SELECT2DBUTTON = 8813
};

typedef NS_ENUM(NSInteger, NXChangePageTagType)
{
    NXCHANGPAGETAGTYPE_LEFT = 60001,
    NXCHANGPAGETAGTYPE_RIGHT = 60002,
};

typedef NS_ENUM(NSInteger, NXFileContentType)
{
    NXFILECONTENTTYPE_NOTSUPPORT        = 2000,
    NXFILECONTENTTYPE_NORMAL            = 2001,
    NXFILECONTENTTYPE_MEDIA             = 2002,
    NXFILECONTENTTYPE_PDF               = 2003,
    NXFILECONTENTTYPE_3D                = 2004,
    NXFILECONTENTTYPE_3D_NEED_CONVERT   = 2005,
};

typedef NS_ENUM(NSInteger, NXFileOpenControlType)
{
    NXFileOpenControlTypeUnSet          = 3000,
    NXFileOpenControlTypeWebView,               // webview open .pdf .doc etc. normal current file.
    NXFileOpenControlTypeVDSView,               // SAP sdk open .vds file.
    NXFileOpenControlTypeModelSurfaceView,      // Hoops Visualize open 3D pdf file.
    NXFileOpenControlTypeMediaOther,
};

@interface DetailViewController ()<UIDocumentInteractionControllerDelegate,/*NXSyncDataDelegate,*/ MobileSurfaceViewDelegate,UIWebViewDelegate, NXServiceOperationDelegate, NXConvertFileDelegate, NXDownloadManagerDelegate, UIWebViewDelegate, UINavigationControllerDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *fileContentWebView;

@property (weak, nonatomic) NXDownloadView *downloadView;
@property (weak, nonatomic) UIBarButtonItem *moreButton;
@property (weak, nonatomic) UILabel *titleLabel;

@property (weak, nonatomic) MobileSurfaceView *threeDFileView;
@property (strong, nonatomic) NXGLKViewController *vdsViewController;
@property (strong, nonatomic) MPMoviePlayerController *mediaPlayerController;
@property (assign, nonatomic) NXFileOpenControlType fileOpenControllerType;

@property (strong, nonatomic) UIDocumentInteractionController *documentController;
@property (strong, nonatomic) id<NXServiceOperation> serviceOperation;
@property (strong, nonatomic) NXConvertFile *convert;
@property (strong, nonatomic) NSString *localCachePath;

@property (strong, nonatomic) NXFileBase *metaData;
@property (strong, nonatomic) NXRights *curFileRights;

@property (assign, nonatomic) BOOL shownFile;
@property (assign, nonatomic) NXServiceOperationStatus serviceStatus;
@property (assign, nonatomic) BOOL isSimpleShadowSelected;
@property (assign, nonatomic) BOOL shownOpenInMenu;

@property (nonatomic) BOOL isOpenThirdAPPFile;
@property (nonatomic) BOOL isOpenNewProtectedFile;

@property (nonatomic) BOOL isSteward;

@property (nonatomic, strong) NSString *duid; // duid to identify the opening file operation when sync. if open file B when opening file A, the uuid will be changed, so we can stop open file A.

//this two property only used for PDF file.
@property(nonatomic, strong) NSString *converted3DfilePath; //filePath which convert from 3d pdf file
@property(nonatomic, strong) NSString *normalPDFfile; //current opened 3d filepath.
@property(nonatomic, assign) BOOL isPDFFile;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.isSteward = NO;
    
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerWillExitFullScreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerDidEnterFullScreen:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlayBackStateChanged:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    float ver = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (ver < 9.0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayerPlayDidExitFullScreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    }
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, MAXFLOAT, 35)];
    titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    titleLabel.numberOfLines = 1;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = self.curFile.name;
    self.navigationItem.titleView = titleLabel;
    self.titleLabel = titleLabel;
    
    self.fileContentWebView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.fileContentWebView.scalesPageToFit = YES;
    self.fileContentWebView.scrollView.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if ([self.splitViewController.viewControllers.firstObject isKindOfClass:[UINavigationController class]]) {
            
            UINavigationController *nav = (UINavigationController *)self.splitViewController.viewControllers.firstObject;
            nav.delegate = self;
        }
    }
}

- (void) leftSwipeButtonClick:(UIButton *) leftSwipeButton
{
    if (_serviceStatus == NXSERVICEOPERATIONSTATUS_DOWNLOADFILE || [self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(detailViewController:SwipeToNextFileFrom:inService:inFileListInfoView:)] && self.fileListInfoVC) {
        [self.delegate detailViewController:self SwipeToNextFileFrom:self.curFile inService:self.curService inFileListInfoView:self.fileListInfoVC];
    }
    
    if ([self.delegate respondsToSelector:@selector(detailViewController:SwipeToNextFileFrom:inService:inCustomFileListViewController:)] && self.customFileListVC) {
        [self.delegate detailViewController:self SwipeToNextFileFrom:self.curFile inService:self.curService inCustomFileListViewController:self.customFileListVC];
    }
    
}

- (void) rightSwipeButtonClick:(UIButton *) rightSwipeButton
{
    if (_serviceStatus == NXSERVICEOPERATIONSTATUS_DOWNLOADFILE || [self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(detailViewController:SwipeToPreFileFrom:inService:inFileListInfoView:)] && self.fileListInfoVC) {
        [self.delegate detailViewController:self SwipeToPreFileFrom:self.curFile inService:self.curService inFileListInfoView:self.fileListInfoVC] ;
    }
    
    if ([self.delegate respondsToSelector:@selector(detailViewController:SwipeToPreFileFrom:inService:inCustomFileListViewController:)] && self.customFileListVC) {
        [self.delegate detailViewController:self SwipeToPreFileFrom:self.curFile inService:self.curService inCustomFileListViewController:self.customFileListVC];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.splitViewController.collapsed) {
        self.splitViewController.displayModeButtonItem.enabled = YES;

    }
    
    [_vdsViewController viewDidAppear:animated];
    
    if (self.curFile == nil) {
        [self showNoFileContentView];
    }
    [self.navigationController.navigationBar setTranslucent:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_mediaPlayerController) {
        [_mediaPlayerController pause];
    }
    self.splitViewController.displayModeButtonItem.enabled = NO;
    
//    [[NXTokenManager sharedInstance] cleanUserCacheData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self closeFile];
    
    [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_MEMORY_WARNING", nil)];
    
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    // cancel the operation and stop background thread
    [self cancelOperation];
//    [self cancelSyncMetaData];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public method------open file

- (void)openFile:(NXFileBase *)file currentService:(NXBoundService *)service isOpen3rdAPPFile:(BOOL) isOpen3rdAPPFile isOpenNewProtectedFile:(BOOL) isOpenNewProtectedFile
{
    UIImageView * iconView = (UIImageView *)[self.fileContentWebView viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG];
    if (iconView) {
        [iconView removeFromSuperview];
    }
    [NXDropDownMenu dismissMenu];
    
    //fix bug, make caller not hang-up.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{});
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isOpenNewProtectedFile = isOpenNewProtectedFile;
        self.isOpenThirdAPPFile = isOpen3rdAPPFile;
        //when is not content view page show, navigation to contentViewController;
        if ([self.navigationController.viewControllers containsObject:self] && ![self.navigationController.topViewController isKindOfClass:[self class]]) {
            [self.navigationController popToViewController:self animated:YES];
        };
        
        if ([self.presentedViewController isKindOfClass:[NSClassFromString(@"_UIDocumentActivityViewController") class]]) {
            [self.documentController dismissMenuAnimated:YES];
            self.shownOpenInMenu = NO;
        }
        
        // before open we need do some work,like clearn the webview's content,cancel sync and so on...
        [self closeFile];
        
        self.curFile = file;
        self.curService = service;
        self.duid = [[NSUUID UUID] UUIDString];
        
        self.serviceOperation = [NXCommonUtils createServiceOperation:self.curService];
        [self.serviceOperation setDelegate:self];
        
        //Notification UI to update the selected cell
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_OPEN_FILE object:nil];
        
        self.shownFile = NO;
        self.serviceStatus = NXSERVICEOPERATIONSTATUS_UNSET;
        
        self.titleLabel.text = self.curFile.name;
        
        //current is open third file,directly open the file
        if (self.curService.service_type.intValue == kServiceICloudDrive || self.isOpenThirdAPPFile) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                sleep(1);
                // there wait for the DetailViewController really show on window(For iOS may change splitview async, if bellow codes called before DetailViewController appear, the alert view will not show up)
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.localCachePath = self.curFile.fullServicePath;
                    [self doOpenFile];

                });
                }
            );
        }
        else
        {
            NXCacheFile *file = [NXCommonUtils getCacheFile:self.curFile];
            // first check the network status
            if([[NXNetworkHelper sharedInstance] isNetworkAvailable])
            {
                if(file)
                {
                    self.localCachePath = file.cache_path;
                    
                    // if network is ok then get metedata from service
                    if([self.serviceOperation getMetaData:_curFile])
                    {
                        [self addDownloadStatusView:NO fileName:[_curFile.fullPath lastPathComponent]];
                        self.serviceStatus = NXSERVICEOPERATIONSTATUS_GETMETADATA;
                    }
                    else
                    {
                        // return NO,indicate that in the inner service this method fail,so deal with this case
                        // now just open this local cache file
                        [self doOpenFile];
                        return;
                    }
                }
                else
                {
                    // newwork is ok and no cache file ,directly download this file
                    //                BOOL bRet = [_serviceOperation downloadFile:_curFile];
                    BOOL bRet = [NXDownloadManager startDownloadFile:_curFile];
                    [NXDownloadManager attachListener:self file:_curFile];
                    if(!bRet)
                    {
                        // do something when call downloadFile fail
                        NSLog(@"NXFileContentViewController viewDidLoad downloadFile fail");
                        [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_DOWNLOADFAIL", nil)];
                        [self closeFile];
                        return;
                    }
                    else
                    {
                        BOOL showDownloadView = [_serviceOperation isProgressSupported];
                        [self addDownloadStatusView:showDownloadView fileName:[_curFile.fullPath lastPathComponent]];
                        _serviceStatus = NXSERVICEOPERATIONSTATUS_DOWNLOADFILE;
                    }
                }
            }
            else
            {
                if (file)
                {
                    // has cache file, show directly
                    self.localCachePath = file.cache_path;
                    [self doOpenFile];
                }
                else
                {
                    //there is no network and also no cache file,we show alert view to user
                    [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_CANNOTOPENFILE", nil)];
                    [self closeFile];
                }
            }
        }
    });
}

- (void)openFile:(NXFileBase *)file currentService:(NXBoundService *)service inFileListInfoViewController:(NXFileListInfoViewController *) fileListInfoVC isOpen3rdAPPFile:(BOOL) isOpen3rdAPPFile isOpenNewProtectedFile:(BOOL) isOpenNewProtectedFile
{
    self.fileListInfoVC = fileListInfoVC;
    self.customFileListVC = nil;
    [self openFile:file currentService:service isOpen3rdAPPFile:isOpen3rdAPPFile isOpenNewProtectedFile:isOpenNewProtectedFile];
}

- (void)openFile:(NXFileBase *)file currentService:(NXBoundService *)service inCustomFileListViewController:(NXCustomFileListViewController *) customFileListVC isOpen3rdAPPFile:(BOOL) isOpen3rdAPPFile isOpenNewProtectedFile:(BOOL) isOpenNewProtectedFile
{
    
    self.fileListInfoVC = nil;
    self.customFileListVC = customFileListVC;
    [self openFile:file currentService:service isOpen3rdAPPFile:isOpen3rdAPPFile isOpenNewProtectedFile:isOpenNewProtectedFile];

}

-(void) showAutoDismissLabel:(NSString *) labelContent
{
    if([self.fileContentWebView viewWithTag:AUTO_DISMISS_LABLE_TAG])
    {
        return;
    }
    __block UILabel *displayLab = [[UILabel alloc] init];
    displayLab.text = labelContent;
    displayLab.translatesAutoresizingMaskIntoConstraints = NO;
    displayLab.textAlignment = NSTextAlignmentCenter;
    displayLab.textColor = [UIColor whiteColor];
    displayLab.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.6];
    displayLab.tag = AUTO_DISMISS_LABLE_TAG;
    displayLab.layer.cornerRadius = 20;
    displayLab.layer.masksToBounds = YES;
    [displayLab setFont:[UIFont fontWithName:@"Helvetica" size:18]];
    
    [self.fileContentWebView addSubview:displayLab];
    
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:displayLab attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:260]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:displayLab attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:displayLab attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
     [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:displayLab attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    
    [UIView animateWithDuration:0.5 delay:1.0 options:UIViewAnimationOptionTransitionNone animations:^{
        displayLab.alpha = 0;
    } completion:^(BOOL finished) {
        [displayLab  removeFromSuperview];
    }];
}

- (void)doOpenFile
{
    self.isSteward = NO;
    self.moreButton.enabled = YES;
    UIView *noContentView = [self.fileContentWebView viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG];
    [noContentView removeFromSuperview];
    BOOL isNxlFile = [NXMetaData isNxlFile:self.localCachePath];
    
    if (isNxlFile) {
        [self openNxlFile];
    }else
    {
        [self openNormalFile:NO];
    }
}

- (void)closeFile
{
    if(self.shownFile)
    {
        // cancel sync
        //        [self cancelSyncMetaData];
        
        // clearn the webview's content
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
        [self.fileContentWebView loadRequest:request];
        self.shownFile = NO;
    }
//     self.obligations = nil;
    // cancel the current service's operation
    [self cancelOperation];
    [self.serviceOperation setDelegate:nil];
    //if previous fils is downloading or getting metadata just remove the view
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
    
    //if is 3D file,need remove the 3D view
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_3DVIEW] removeFromSuperview];
    
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_VDSVIEW] removeFromSuperview];
    if (_mediaPlayerController) {
        [_mediaPlayerController stop];
        _mediaPlayerController = nil;
        [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_MEDIAVIEW] removeFromSuperview];
    }
    self.vdsViewController = nil;
    
    //if the previous file has overlay just remove it
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_OVERLAY] removeFromSuperview];
    UILabel *label = (UILabel*)self.navigationItem.titleView;
    label.text = NSLocalizedString(@"TITLE_DETAIL", NULL);
    
    // clean the temp the convert file
    [NXCommonUtils cleanTempFile];
    
//    self.shareBtn.enabled = YES;
    // set the variable to nil
    self.curFile = nil;
    self.curFileRights = nil;
    self.curService = nil;
    self.localCachePath = nil;
    self.metaData = nil;
    self.threeDFileView = nil;
    self.shownOpenInMenu = NO;
    self.duid = nil;
    
    self.converted3DfilePath = nil;
    self.normalPDFfile = nil;
    self.isPDFFile = NO;
    [self removeSelect2DPDFFileButton];
    
    // set up no content view
//    [self showNoFileContentView];
    
    [self removeChangePageButton];
    
    [self.convert cancel];
}

- (void)afterOpenFile
{
    _shownFile = YES;
    //overlay test code. if you do not want to show overlay, please comment this line.
    [self showOverlay];
    
    [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
        NSLog(@"upload log infomation");
    }];
}

- (void)cancelOperation
{
    if(self.serviceStatus == NXSERVICEOPERATIONSTATUS_DOWNLOADFILE)
    {
        [NXDownloadManager detachListener:self];
    }
    else if(self.serviceStatus == NXSERVICEOPERATIONSTATUS_GETMETADATA)
    {
        [self.serviceOperation cancelGetMetaData:self.curFile];
    }
}

#pragma mark - relayout UI

- (void)configureView {
    UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"More"] style:UIBarButtonItemStylePlain target:self action:@selector(didPressMoreBtn:)];
    self.moreButton = moreButton;
    self.navigationItem.rightBarButtonItem = moreButton;
}

#pragma mark - button click event

- (void)didPressMoreBtn:(id)sender {
    //do not pop menu when file is not open.
    if (!self.shownFile) {
        return;
    }
    if (self.shownOpenInMenu) {
        [self.documentController dismissMenuAnimated:YES];
        self.shownOpenInMenu = NO;
        return;
    }
    
    BOOL isNXLFile = [NXMetaData isNxlFile:self.localCachePath];
    
    //protect Item.
    NXDropDownMenuItem *protectItem = nil;
    protectItem  = [NXDropDownMenuItem menuItem:NSLocalizedString(@"ACTION_PROTECT", nil) image:[UIImage imageNamed:@"Protect"] target:self action:@selector(protectBtnClickd:)];
    protectItem.foreColor = RMC_MAIN_COLOR;
    
    NXDropDownMenuItem *shareItem = nil;
    if (!isNXLFile || (isNXLFile && (self.isSteward || [self.curFileRights SharingRight]))) {
       shareItem = [NXDropDownMenuItem menuItem:NSLocalizedString(@"Share", nil) image:[UIImage imageNamed:@"OpenIn"] target:self action:@selector(shareBtnPressed:)];
        shareItem.foreColor = RMC_MAIN_COLOR;
    } else {
        shareItem = [NXDropDownMenuItem menuItem:NSLocalizedString(@"Share", nil) image:[UIImage imageNamed:@"OpenIn"] target:nil action:nil];
        shareItem.foreColor = [UIColor lightGrayColor];
    }
    
    //Printing Item
    NXDropDownMenuItem *printItem = nil;
    if (!isNXLFile || (isNXLFile && (self.isSteward || [self.curFileRights PrintRight]))) {
        printItem  = [NXDropDownMenuItem menuItem:NSLocalizedString(@"Print", nil) image:[UIImage imageNamed:@"PrintIcon"] target:self action:@selector(printBtnPressed:)];
        printItem.foreColor = RMC_MAIN_COLOR;
    } else {
        printItem  = [NXDropDownMenuItem menuItem:NSLocalizedString(@"Print", nil) image:[UIImage imageNamed:@"PrintIcon"] target:nil action:nil];
        printItem.foreColor = [UIColor lightGrayColor];
    }
    
    //Property Item
    NXDropDownMenuItem *propertyItem = [NXDropDownMenuItem menuItem:NSLocalizedString(@"Property", nil) image:[UIImage imageNamed:@"FileProperty"] target:self action:@selector(detailBtnPressed:)];
    propertyItem.foreColor = RMC_MAIN_COLOR;
    
    
    [NXDropDownMenu setTintColor:[UIColor whiteColor]];
    CGRect rect = CGRectMake(self.navigationController.navigationBar.frame.size.width - 50, - self.navigationController.navigationBar.frame.size.height, 50, 50);
    if (isNXLFile) {
        [NXDropDownMenu showMenuInView:self.view fromRect:rect menuItems:@[shareItem, printItem, propertyItem]];
    } else {
        [NXDropDownMenu showMenuInView:self.view fromRect:rect menuItems:@[protectItem, shareItem, printItem, propertyItem]];
    }
}

- (void)shareBtnPressed:(id)sender
{
    NXAdHocSharingViewController* vc = [[NXAdHocSharingViewController alloc]init];
    vc.type = NXProtectTypeSharing;
    vc.curFile = self.curFile;
    vc.curFilePath = _localCachePath;
    vc.rights = self.curFileRights;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)protectBtnClickd:(id)sender
{
    NXAdHocSharingViewController* vc = [[NXAdHocSharingViewController alloc]init];
    vc.type = NXProtectTypeNormal;
    vc.curFile = self.curFile;
    vc.curFilePath = _localCachePath;
    vc.rights = self.curFileRights;
    
    vc.curService = self.curService;
    vc.isProtectThirdPartyAPPFile = self.isOpenThirdAPPFile;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)printBtnPressed:(id)sender
{
    // should add overlay or not.
    NXOverlayTextInfo *overlayInfo = nil;
    if ([NXMetaData isNxlFile:self.localCachePath]) {
        if (!self.isSteward && ![self.curFileRights PrintRight]) {
            [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"NO_PRINTING_RIGHT", NULL)];
            return;
        }
        
        if (!self.isSteward && [self.curFileRights getObligation:OBLIGATIONWATERMARK]) {
            overlayInfo = [[NXHeartbeatManager sharedInstance]getOverlayTextInfo];
        }
    }
    
    
    switch (self.fileOpenControllerType) {
        case NXFileOpenControlTypeModelSurfaceView:
        {
            UIImage *snapshotImage = [self.threeDFileView snapshotImage];
            [[NXPrintInteractionController sharedInstance] printImage:snapshotImage withOverlay:overlayInfo];
        }
            break;
        case NXFileOpenControlTypeVDSView:
        {
            UIImage *snapshotImage = [self.vdsViewController snapshotImage];
            [[NXPrintInteractionController sharedInstance] printImage:snapshotImage withOverlay:overlayInfo];
        }
            break;
        case NXFileOpenControlTypeWebView:
        {
            [[NXPrintInteractionController sharedInstance] print:[self.fileContentWebView viewPrintFormatter] withOverlay:overlayInfo];
        }
            break;
        default:
        {
            [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_PRINTING_NOT_SUPPOT", NULL)];
            return;
        }
            break;
    }
    //show print view.
    UIPrintInteractionCompletionHandler handle = ^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError * __nullable error){
//        if (self.coverView) {
//            [self.coverView removeFromSuperview];
//                   }
        if([NXMetaData isNxlFile:self.localCachePath])
        {
            NXLogAPIRequestModel *model = [[NXLogAPIRequestModel alloc]init];
            model.duid = self.curNXLFileDUID;
            model.owner = self.curNXLFileOwner;
            model.operation = [NSNumber numberWithInteger:kPrintOpeartion];
            model.repositoryId = @"";
            model.filePathId = self.curFile.fullServicePath;
            model.filePath = self.curFile.fullServicePath;
            model.fileName = self.curFile.fullServicePath;
            model.activityData = @"TestData";
            model.accessTime = [NSNumber numberWithLongLong:([[NSDate date] timeIntervalSince1970] * 1000)];
            model.accessResult = [NSNumber numberWithInteger:1];
            
            NXLogAPI *logAPI = [[NXLogAPI alloc]init];
            [logAPI generateRequestObject:model];
            [[NXSyncHelper sharedInstance] cacheRESTAPI:logAPI cacheURL:[NXCacheManager getLogCacheURL]];
            [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
                
            }];
        }
       
        
        if (error) {
            NSLog(@"error when print document: %@", error.localizedDescription);
        }
    };
    
    if ([NXCommonUtils isiPad]) {
//        if ([NXCommonUtils iosVersion]<9.0) {
//            self.coverView = [[UIView alloc]initWithFrame:self.view.bounds];
//            self.coverView.backgroundColor = [UIColor whiteColor];
//            [self.view addSubview:self.coverView];
//           
//        }
        
        [[NXPrintInteractionController sharedInstance].printer presentFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES completionHandler:handle]; //iPad
        
    } else {
        [[NXPrintInteractionController sharedInstance].printer presentAnimated:YES completionHandler:handle];  //iPhone
    }
}

- (void)detailBtnPressed:(id)sender
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NXFileAttrViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"FileAttributeVC"];
    vc.curFile = self.curFile;
    vc.curService = self.curService;
    vc.isOpenThirdAPPFile = self.isOpenThirdAPPFile;
    vc.curRights = self.curFileRights;
    vc.isSteward = self.isSteward;
    [UIView  beginAnimations: @"animation" context: nil];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
    [UIView setAnimationDuration:0.5f];
    [self.navigationController pushViewController:vc animated:NO];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
    [UIView commitAnimations];
}

#pragma mark

- (void)moviePlayerWillExitFullScreen:(NSNotification *)notification {
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    [[window viewWithTag:NXVIEWTAGTYPE_OVERLAY] removeFromSuperview];
}

// using fix bug when exit fullscreen in ios 8 after clicked back/next button, the progress slider would not show
- (void)moviePlayerPlayDidExitFullScreen:(NSNotification *)notification {
    UIViewController *con = [[UIViewController alloc] init];
    con.view.backgroundColor = [UIColor blackColor];
    //avoid navigationbar blindness.
    con.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc]initWithFrame:CGRectZero]];
    con.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:[[UIView alloc]initWithFrame:CGRectZero]];
    con.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems;
    UILabel *titleLable = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 35)];
    titleLable.lineBreakMode = NSLineBreakByTruncatingMiddle;
    titleLable.numberOfLines = 1;
    titleLable.textAlignment = NSTextAlignmentCenter;
    titleLable.text = self.curFile.name;
    
    con.navigationItem.titleView = titleLable;
    [self.navigationController pushViewController:con animated:NO];
    
    [self performSelector:@selector(popviewController) withObject:nil afterDelay:0.1];
}
// push/pop nil viewcontroller to fix MPMoviePlayerController.view redraw bug.
- (void)popviewController {
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController popViewControllerAnimated:NO];
    if (self.mediaPlayerController.playbackState == MPMoviePlaybackStatePaused) {
        [self.mediaPlayerController play];
    }
}

- (void)moviePlayerDidEnterFullScreen:(NSNotification *)notificatioin {
    if (_mediaPlayerController.playbackState != MPMoviePlaybackStatePlaying ) {
        [_mediaPlayerController play];
    }
    
    UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
    if (![self.curFileRights getObligation:OBLIGATIONWATERMARK] || self.isSteward) {
        // on watermark, just return.
        return;
    }
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.fileContentWebView.frame), CGRectGetHeight(self.fileContentWebView.frame));
    NXOverlayView *view = [[NXOverlayView alloc] initWithFrame:frame Obligation:[NXHeartbeatManager sharedInstance].getOverlayTextInfo];
    [window addSubview:view];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.tag = NXVIEWTAGTYPE_OVERLAY;
    
    id views = @{ @"overlayview": view};
    [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[overlayview]|" options:0 metrics:nil views:views]];
    [window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[overlayview]|" options:0 metrics:nil views:views]];
    
    [window bringSubviewToFront:view];
}

- (void)moviePlayerPlayBackStateChanged:(NSNotification *)notification {
    if(!self.shownFile)
    {
        return;
    }
    NSURL *contentURL = self.mediaPlayerController.contentURL;
    if (self.mediaPlayerController.loadState == MPMovieLoadStateUnknown) {
        if (!contentURL.path) {
            return;
        }
        self.mediaPlayerController.contentURL = contentURL;
        [self.mediaPlayerController prepareToPlay];
        [self.mediaPlayerController play];
    }
}

//#pragma mark - public method for update progress,
//
//- (void)protectBtnPressed:(CGFloat)progress
//{
//    [self.downloadView.progressBar setProgress:progress];
//}

#pragma mark - add subviews for filecontentview and do layout

- (void)addConvertFileWaitView:(NSString *)fileName
{
    NSString *info = [NSString stringWithFormat:@"%@%@", @"ConvertFile:", fileName];
    [self addDownloadStatusView:YES fileName:info];
}

- (void)addDownloadStatusView:(BOOL)showDownloadView fileName:(NSString *)fileName;
{
    CGRect rect = self.fileContentWebView.frame;
    NXDownloadView *downloadView = [[NXDownloadView alloc]initWithFrame:rect showDownloadView:showDownloadView];
    downloadView.translatesAutoresizingMaskIntoConstraints = NO;
    downloadView.tag = NXVIEWTAGTYPE_STATUSVIEW;
    self.downloadView = downloadView;
    
    //auto layout
    [self.fileContentWebView addSubview:downloadView];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:downloadView
                              attribute:NSLayoutAttributeTop
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeTop
                              multiplier:1
                              constant:64]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:downloadView
                              attribute:NSLayoutAttributeBottom
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeBottom
                              multiplier:1
                              constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:downloadView
                              attribute:NSLayoutAttributeTrailing
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeTrailing
                              multiplier:1
                              constant:0]];
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:downloadView
                              attribute:NSLayoutAttributeLeading
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeLeading
                              multiplier:1
                              constant:0]];
    if(showDownloadView)
    {
        [downloadView.progressBar setProgress:0.0f];
        [downloadView.fileName setText:fileName];
    }
    else
    {
        [downloadView.activityView startAnimating];
    }
}

- (void)addVDSSubView:(NXGLKViewController *)vc {
    [_fileContentWebView addSubview:vc.view];
    vc.view.translatesAutoresizingMaskIntoConstraints = NO;
    vc.view.tag = NXVIEWTAGTYPE_VDSVIEW;
    [self.fileContentWebView addConstraint:[NSLayoutConstraint
                                            constraintWithItem:vc.view
                                            attribute:NSLayoutAttributeTop
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.fileContentWebView
                                            attribute:NSLayoutAttributeTop
                                            multiplier:1
                                            constant:0]];
    
    [self.fileContentWebView addConstraint:[NSLayoutConstraint
                                            constraintWithItem:vc.view
                                            attribute:NSLayoutAttributeBottom
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.fileContentWebView
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1
                                            constant:0]];
    
    [self.fileContentWebView addConstraint:[NSLayoutConstraint
                                            constraintWithItem:vc.view
                                            attribute:NSLayoutAttributeTrailing
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.fileContentWebView
                                            attribute:NSLayoutAttributeTrailing
                                            multiplier:1
                                            constant:0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint
                                            constraintWithItem:vc.view
                                            attribute:NSLayoutAttributeLeading
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:self.fileContentWebView
                                            attribute:NSLayoutAttributeLeading
                                            multiplier:1
                                            constant:0]];
}

- (void)showAlertView:(NSString*)title message:(NSString*)message
{
    [NXCommonUtils showAlertView:title message:message style:UIAlertControllerStyleAlert OKActionTitle:nil cancelActionTitle:NSLocalizedString(@"BOX_OK", NULL) OKActionHandle:nil cancelActionHandle:nil inViewController:self position:self.view];
}

- (void)hintUserOpenInOtherApp:(BOOL)isNxlFile
{
    [NXCommonUtils showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"HINT_USER_MESSAGE", NULL) style:UIAlertControllerStyleAlert OKActionTitle:NSLocalizedString(@"BOX_OK", NULL) cancelActionTitle:nil OKActionHandle:^(UIAlertAction *action) {
        if (!isNxlFile) {
            [self shareFile];
        }
    } cancelActionHandle: nil inViewController:self position:self.fileContentWebView];
}



- (void)showOverlay {
    
//    NSDictionary *obligation = [self.obligations objectForKey:@"OB_OVERLAY"];
//    if (!obligation) {
//        return;
//    }
    if (self.isSteward || ![self.curFileRights getObligation:OBLIGATIONWATERMARK]) {
        return;
    }
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_OVERLAY] removeFromSuperview];
   
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.fileContentWebView.frame), CGRectGetHeight(self.fileContentWebView.frame));
    NXOverlayView *view = [[NXOverlayView alloc] initWithFrame:frame Obligation:[NXHeartbeatManager sharedInstance].getOverlayTextInfo];
//    NXOverlayView *view = [[NXOverlayView alloc] initWithFrame:frame];
    [self.fileContentWebView addSubview:view];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.tag = NXVIEWTAGTYPE_OVERLAY;
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeTop
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeTop
                              multiplier:1
                              constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeBottom
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeBottom
                              multiplier:1
                              constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeTrailing
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeTrailing
                              multiplier:1
                              constant:0]];
    [self.view addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeLeading
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.fileContentWebView
                              attribute:NSLayoutAttributeLeading
                              multiplier:1
                              constant:0]];
}

#pragma mark - share file

- (void)shareFile
{
    self.documentController.URL = [[NSURL alloc]initFileURLWithPath:self.localCachePath];
    NSString *uti = [NXCommonUtils getUTIForFile:self.localCachePath];
    self.documentController.UTI = uti ? uti : @"public.content";
    self.shownOpenInMenu = YES;
    [self.documentController presentOptionsMenuFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}

-(void)updateProgress:(CGFloat)progress
{
    [self.downloadView.progressBar setProgress:progress];
}

#pragma mark
#pragma mark the private method about operation files
#pragma mark the method about 3d files,load 3d file content,like hsf,3d pdf,but is not office,normal pdf ,txt
- (BOOL)load3DFile:(NSString *)filename
{
    NSString *extension = [NXCommonUtils getExtension:filename error:nil];
    bool result = false;
    if ([extension compare:FILEEXTENSION_VDS options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        result = [self load3DVDSFile:filename];
    } else {
        result = [self loadHPSFile:filename];
        //if load 3d pdf file. just show select button.
        if (result &&  self.isPDFFile) {
            [self showSelect2DPDFFileButton];
            //show overlay when switch 2D pdf to 3D pdf.
            [self showOverlay];
        }
    }
    if(!result) {
        [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_LOADFAIL", nil)];
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)loadHPSFile:(NSString *)filename {
    if(self.threeDFileView == nil) {
        CGRect frame = self.fileContentWebView.bounds;
        MobileSurfaceView *threeDFileView = [MobileSurfaceView mobileSurfaceViewWithXibFile];
        threeDFileView.frame = frame;
        threeDFileView.delegate = self;
        threeDFileView.tag = NXVIEWTAGTYPE_3DVIEW;
        [self.fileContentWebView addSubview:threeDFileView];
        self.threeDFileView = threeDFileView;
    }
    self.fileOpenControllerType = NXFileOpenControlTypeModelSurfaceView;
    UserMobileSurface *mobileSurface = (UserMobileSurface*)self.threeDFileView.surfacePointer;
    [self ShowChangePageButton];
    return mobileSurface->loadFile(filename.UTF8String);
}

- (BOOL)load3DVDSFile:(NSString*)filename {
    if (!_vdsViewController) {
        NXGLKViewController *vdsViewController = [[NXGLKViewController alloc] initWithNibName:@"NXGLKViewController" bundle:nil];
        [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_VDSVIEW]removeFromSuperview];
        vdsViewController.view.frame = self.fileContentWebView.frame;
        vdsViewController.view.tag = NXVIEWTAGTYPE_VDSVIEW;
        [self addVDSSubView:vdsViewController];
        
        self.vdsViewController = vdsViewController;
    }
    self.fileOpenControllerType = NXFileOpenControlTypeVDSView;
    return [_vdsViewController loadVDSFile:filename];
}


- (void)convert3DFileFormat:(NSData *)data
{
    if (!self.shownFile) {
        [self addConvertFileWaitView:[_curFile.fullPath lastPathComponent]];
    }
    
    _convert = [[NXConvertFile alloc]init];
    _convert.delegate = self;
    
    NSString *fileName = nil;
    if([NXMetaData isNxlFile:_localCachePath])
    {
        fileName = [self getFileNameFromNxlFile];
    }
    else
    {
        fileName = [_localCachePath lastPathComponent];
    }

    [self.convert convertFile:0
                     fileName:fileName
                         data:data toFormat:@"hsf"
                        isNxl:NO
                   completion:^(NSString *filename, NSError *error) {
                        if(error)
                        {
                            [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
                            if (!self.shownFile) {
                                if (error.code != NXRMC_ERROR_CODE_CANCEL) {
                                    if (error.code == NXRMC_ERROR_CODE_CONVERTFILEFAILED_NOSUPPORTED) {
                                         [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:error.localizedDescription];
                                    } else {
                                        [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_CONVERT_FILE_FAIL", nil)];
                                    }
                                }
                            }
                            [self ShowChangePageButton];
                        }
                        else
                        {
                            [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
                            self.converted3DfilePath = filename;
                            if([self open3DFile:filename])
                            {
                                [self afterOpenFile];
                            }
                            else
                            {
                                [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_LOADFAIL", nil)];
                                [self ShowChangePageButton];
                            }
                            
                        }
                    }];
}

- (BOOL)isNeedUpdateConvertCacheFile
{
//    NSString *hsfFile = [self.localCachePath stringByAppendingPathExtension:FILEEXTENSION_HSF];
//    if([[NSFileManager defaultManager] fileExistsAtPath:hsfFile])
//    {
//        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:self.localCachePath error:nil];
//        NSDate *orignalFileTime = attr[NSFileModificationDate];
//        attr = [[NSFileManager defaultManager] attributesOfItemAtPath:hsfFile error:nil];
//        NSDate *hsfFileTime = attr[NSFileModificationDate];
//
//        NSLog(@"%@",orignalFileTime);
//        NSLog(@"%@",hsfFileTime);
//
//        return [hsfFileTime compare:orignalFileTime] == NSOrderedAscending ? YES : NO;
//    }
    return YES;
}

- (NSString *)getConvertedFilePath
{
    NSString *path = [self.localCachePath stringByAppendingPathExtension:FILEEXTENSION_HSF];
    return (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) ? path : nil;
}

- (NSString *)getFileNameFromNxlFile
{
    NSString *tmpName = [self.localCachePath lastPathComponent];
    NSString *extension = [NXCommonUtils getExtension:self.localCachePath error:nil];
    NSRange location = [tmpName rangeOfString:extension];
    
    NSString *fileName = [tmpName substringToIndex:location.location + location.length];
    return fileName;
}

- (BOOL)savePlainDataToFile:(NSData*)plain filePath:(NSString **)path
{
    NSString* tmpPath = [NXCommonUtils getConvertFileTempPath];
    tmpPath = [[tmpPath stringByAppendingPathComponent:[self.localCachePath lastPathComponent]]stringByAppendingPathExtension:@"hsf"];
    *path = tmpPath;
    return [plain writeToFile:tmpPath atomically:YES];
}

- (BOOL)loadMediaFile:(NSString *)filePath {
    self.mediaPlayerController.contentURL = [[NSURL alloc]initFileURLWithPath:filePath];
    self.mediaPlayerController.view.backgroundColor = [UIColor colorWithRed:248/255.f green:248.f/255.f blue:253.f/255.f alpha:1.0f];
    
    [self.fileContentWebView addSubview:self.mediaPlayerController.view];
    self.mediaPlayerController.view.tag = NXVIEWTAGTYPE_MEDIAVIEW;
    self.mediaPlayerController.view.translatesAutoresizingMaskIntoConstraints = NO;
    id views = @{ @"player": self.mediaPlayerController.view };
    [self.fileContentWebView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[player]|" options:0 metrics:nil views:views]];
    
    [self.fileContentWebView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[player]|" options:0 metrics:nil views:views]];
    [self.mediaPlayerController prepareToPlay];
    
    [self.mediaPlayerController play];
    
    self.fileOpenControllerType = NXFileOpenControlTypeMediaOther;
    return YES;
}


#pragma mark - load file content,like office,wd pdf,txt, not 3d file

- (BOOL)loadFile:(NSData *)content MIMEType:(NSString *)mimetype textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL filePath:(NSString *)filePath
{
    if ([self checkFileFormat:mimetype]) {
        //clean the webview's content
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]];
        [self.fileContentWebView loadRequest:request];
        [self.fileContentWebView loadData:content MIMEType:mimetype textEncodingName:textEncodingName baseURL:[NSURL fileURLWithPath:filePath]];
        //remove 3D PDF view when show selected pdf button
        [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_3DVIEW] removeFromSuperview];
        self.threeDFileView = nil;
    } else {
        [self.fileContentWebView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.localCachePath]]];
    }
    self.fileOpenControllerType = NXFileOpenControlTypeWebView;
    return YES;
}
- (BOOL)checkFileFormat:(NSString *)mimetype
{
    // check the file format,we need to decide what file format nxrmc will support,now just judge the mimetype and file extension
    if([mimetype isEqualToString:@"application/octet-stream"] &&
       ![NXCommonUtils is3DFileFormat:[NXCommonUtils getExtension:self.localCachePath error:nil]])
    {
        return NO;
    }
    return YES;
}

#pragma mark - sync file content method

-(BOOL)isFileModified:(NXFileBase *)metaData
{
    //now just compare the file's lastmodifiedtime,in the future can overwrite this method
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    NSDate *metadataLastModifydate = [dateFormatter dateFromString:metaData.lastModifiedTime];
    NSDate *localLastModifydate = [NXCommonUtils getLocalFileLastModifiedDate:_localCachePath];
    
//    NSLog(@"metadataLastModifydate = %@",metadataLastModifydate);
//    NSLog(@"localLastModifydate = %@",localLastModifydate);
    
    //for save, when the local modified time is nil, return YES to notify than file last modif
    if (localLastModifydate) {
        return ([metadataLastModifydate compare:localLastModifydate] == NSOrderedDescending);
    } else {
        return YES;
    }
}

- (void)updateMetaData:(NXFileBase *)metaData
{
    // can update more file information
    if(![self.curFile.lastModifiedTime isEqualToString:metaData.lastModifiedTime])
    {
        self.curFile.lastModifiedTime = metaData.lastModifiedTime;
    }
    if(self.curFile.size != metaData.size)
    {
        self.curFile.size = metaData.size;
    }
    if(![self.curFile.name isEqualToString:metaData.name])
    {
        self.curFile.name = metaData.name;
    }
    
    if(![self.curFile.lastModifiedDate isEqualToDate:metaData.lastModifiedDate])
    {
        self.curFile.lastModifiedDate = metaData.lastModifiedDate;
    }
}

- (void)dealWithGetMetaDataError:(NSError *)error
{
    if(!error)
    {
        return;
    }
    if(!self.shownFile)
    {
        switch (error.code)
        {
            case NXRMC_ERROR_CODE_CANCEL:
                //in this case,if error code is cancel,indicate that user open a new file,so do nothing
                return;
            case NXRMC_ERROR_CODE_NOSUCHFILE:  // the file has been deleted
            {
                [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
                [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_NOSUCHFILE", nil)];
            }
                break;
            default:
            {
                if(!self.shownFile)
                {
                    [self doOpenFile];
                }
            }
                break;
        }
    }
    else
    {
        if(error.code == NXRMC_ERROR_CODE_NOSUCHFILE)
        {
            NSLog(@"file has been opened but in this duration,the file is deleted,now just print a log and cancel the sync metadata thread");
            //cancel sync metadata
//            [self cancelSyncMetaData];
            [self cleanCacheFile];
        }
        else
        {
            NSLog(@"file has been opened but in this duration,get file metadata fail,this case do nothing now");
        }
    }
    // set current service status
    self.serviceStatus = NXSERVICEOPERATIONSTATUS_UNSET;
}

- (void)dealWithDownloadFileError:(NSError *)error
{
    if(!error)
    {
        return;
    }
    if(!_shownFile)
    {
        //first time open file and download fail,just shou alert view to user
        switch (error.code) {
            case NXRMC_ERROR_CODE_NOSUCHFILE:
            {
                [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_NOSUCHFILE", nil)];
                [self cleanCacheFile];
            }
                break;
            case NXRMC_ERROR_CODE_CANCEL:
                break;
            default:
                if (error.localizedDescription) {
                    [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:error.localizedDescription];
                }else
                {
                    [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_DOWNLOADFAIL", nil)];
                }
                
                break;
        }
        
        [self closeFile];
    }
    else
    {
        NSLog(@"if the file has been opened and download fail,do nothing now");
    }
}

- (void)cleanCacheFile
{
    //delete cache in coredata
    NXCacheFile *file = [NXCommonUtils getCacheFile:self.curFile];
    if(file)
    {
        [NXCommonUtils deleteCacheFileFromCoreData:file];
    }
    
    //detele cache file in disk
    if(self.localCachePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.localCachePath error:nil];
    }
}

//#pragma mark start and stop background thread about sync filecontent
//- (void)startSyncMetaData
//{
//    if(!self.sync)
//    {
//        self.sync = [[NXSyncData alloc]initWithOperationType:NXOPERATION_GETMETADATA];
//        self.sync.delegate = self;
//        [self.sync updateMetaDataSync:self.curService curFile:self.curFile];
//    }
//}
//
//- (void)cancelSyncMetaData
//{
//    if(self.sync)
//    {
//        [self.sync cancelSync];
//        self.sync = nil;
//    }
//}

#pragma  mark - overrite the get method

- (UIDocumentInteractionController *)documentController
{
    if(_documentController == nil)
    {
        _documentController = [[UIDocumentInteractionController alloc]init];
        _documentController.delegate = self;
    }
    return _documentController;
}

- (NXConvertFile *)convert
{
    if(_convert == nil)
    {
        _convert = [[NXConvertFile alloc]init];
    }
    return _convert;
}

- (MPMoviePlayerController *)mediaPlayerController {
    if (!_mediaPlayerController) {
        _mediaPlayerController = [[MPMoviePlayerController alloc]init];
        _mediaPlayerController.controlStyle = MPMovieControlStyleEmbedded;
        _mediaPlayerController.scalingMode = MPMovieScalingModeAspectFit;
        _mediaPlayerController.view.frame = self.view.frame;
    }
    return _mediaPlayerController;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([request.URL isFileURL]) {
            return  YES;
        } else {
            //link clicked such www.google.com
            [[UIApplication sharedApplication] openURL:request.URL];
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    // disable webview touch action
    [self.fileContentWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
    
    [self.fileContentWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"webView load error");
}

#pragma mark - NXServiceOperationDelegate

-(void)getMetaDataFinished:(NXFileBase*)metaData error:(NSError*)err
{
    self.metaData = metaData;
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
    [self syncMetaDataUpdateUI:_metaData error:err];
}

- (void) syncMetaDataUpdateUI: (NXFileBase*)metaData error: (NSError*)error
{
    if(error)
    {
        [self dealWithGetMetaDataError:error];
        return;
    }
    //set current setvice status
    self.serviceStatus = NXSERVICEOPERATIONSTATUS_UNSET;
    
    if(!self.shownFile)
    {
        [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
    }
    
    if(![self isFileModified:metaData])  //the file is not be modified and open cache file
    {
        if(!self.shownFile)
        {
            [self doOpenFile];
        }
    }
    else
    {
        //cancel sync metadata
//        [self cancelSyncMetaData];
        
        [self cleanCacheFile];
        
        //update the file's metedata
        [self updateMetaData:metaData];
        
        //detect that the file had been modified and need download again
        if(!self.shownFile)
        {
            BOOL showDownloadView = [_serviceOperation isProgressSupported];
            [self addDownloadStatusView:showDownloadView fileName:[_curFile.fullPath lastPathComponent]];
        }
//        BOOL bRet = [self.serviceOperation downloadFile:self.curFile];
        BOOL bRet = [NXDownloadManager startDownloadFile:self.curFile];
        [NXDownloadManager attachListener:self file:self.curFile];
        if(!bRet && !self.shownFile)
        {
            // do something when call downloadFile fail when first time download the file
            NSLog(@"NXFileContentViewController viewDidLoad downloadFile fail");
        }
        self.serviceStatus= NXSERVICEOPERATIONSTATUS_DOWNLOADFILE;
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
       willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"willBeginSendingToApplication");
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application
{
    NSLog(@"didEndSendingToApplication");
}

-(void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    NSLog(@"documentInteractionControllerDidDismissOpenInMenu");
}

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    NSLog(@"documentInteractionControllerDidDismissOptionsMenu");
    self.shownOpenInMenu  = NO;
}

#pragma mark - MobileSurfaceViewDelegate

- (void)segControlValueChanged:(UISegmentedControl *)sender
{
    UserMobileSurface *mobileSurface = (UserMobileSurface*)self.threeDFileView.surfacePointer;
    mobileSurface->segControlValueChanged(sender.selectedSegmentIndex);
}

- (void) buttonPressed:(UIButton *)sender withSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    // Connect button presses with UserMobileSurface actions
    UserMobileSurface *mobileSurface = (UserMobileSurface*)self.threeDFileView.surfacePointer;
    if (selectedSegmentIndex == TOOLBAR_OPERATORS) {
        if (sender.tag == 1) {
            mobileSurface->setOperatorOrbit();
        } else if (sender.tag == 2) {
            mobileSurface->setOperatorZoomArea();
        } else if (sender.tag == 3) {
            mobileSurface->setOperatorSelectPoint();
        } else if (sender.tag == 4) {
            mobileSurface->setOperatorSelectArea();
        } else if (sender.tag == 5) {
            mobileSurface->setOperatorFly();
        }
    } else if (selectedSegmentIndex == TOOLBAR_MODES) {
        if (sender.tag == 1) {
            self.isSimpleShadowSelected = !self.isSimpleShadowSelected;
            mobileSurface->onModeSimpleShadow(self.isSimpleShadowSelected);
        } else if (sender.tag == 2) {
            mobileSurface->onModeSmooth();
        } else if (sender.tag == 3) {
            mobileSurface->onModeHiddenLine();
        } else if (sender.tag == 4) {
            mobileSurface->onModeFrameRate();
        }
    } else if (selectedSegmentIndex == TOOLBAR_USER_CODE) {
        if (sender.tag == 1) {
            mobileSurface->onUserCode1();
        } else if (sender.tag == 2) {
            mobileSurface->onUserCode2();
        } else if (sender.tag == 3) {
            mobileSurface->onUserCode3();
        } else if (sender.tag == 4) {
            mobileSurface->onUserCode4();
        }
    }
}

#pragma mark - NXConvertFileDelegate

- (void)nxConvertFile:(NXConvertFile *)convertFile convertProgress:(NSNumber *)progress forFile:(NSString *)fileName
{
    [self updateProgress:[progress floatValue]];
}

#pragma mark - NXDownloadManagerDelegate

- (void)downloadManagerDidFinish:(NXFileBase *)file intoPath:(NSString *)localCachePath error:(NSError *)error
{
    [[self.fileContentWebView viewWithTag:NXVIEWTAGTYPE_STATUSVIEW] removeFromSuperview];
    _serviceStatus = NXSERVICEOPERATIONSTATUS_UNSET;
    
    if (error) {
        [self dealWithDownloadFileError:error];
        return;
    }
    // show on ui
    self.localCachePath = localCachePath;
    [self doOpenFile];
}

- (void)downloadManagerDidProgress:(float)progress file:(NXFileBase *)file
{
    [self updateProgress:progress];
}

#pragma mark - NO file content view

- (void)showNoFileContentView
{
    UIImageView *noContentView = (UIImageView *)[self.view viewWithTag:FILE_CONTENT_NO_CONTENT_VIEW_TAG];
    if (noContentView == nil) {
        noContentView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NXIcon"]];
        noContentView.translatesAutoresizingMaskIntoConstraints = NO;
        noContentView.tag = FILE_CONTENT_NO_CONTENT_VIEW_TAG;
        [self.fileContentWebView addSubview:noContentView];
        [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200.0]];
        [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:noContentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:200.0]];

    }
    
}

#pragma mark - UISplitViewControllerDelegate

-(void) splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.image = [UIImage imageNamed:@"Back"];
    self.navigationItem.leftBarButtonItem = barButtonItem;
}

-(void) splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if (barButtonItem == self.navigationItem.leftBarButtonItem) {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if([viewController isKindOfClass:[NXMasterTabBarViewController class]])
    {
        if(self.splitViewController.isCollapsed)
        {
            [self closeFile];
        }
    }
}

#pragma mark - Show Change Page button
-(void) ShowChangePageButton
{
    [self removeChangePageButton];
    if(self.isOpenThirdAPPFile || self.isOpenNewProtectedFile)
    {
        return;
    }
    UIButton *leftChangeButton = [[UIButton alloc] init];
    leftChangeButton.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3];
    leftChangeButton.translatesAutoresizingMaskIntoConstraints = NO;
    leftChangeButton.tag = NXCHANGPAGETAGTYPE_LEFT;
    [leftChangeButton setImage:[UIImage imageNamed:@"prePageIcon"] forState:UIControlStateNormal];
    [leftChangeButton addTarget:self action:@selector(rightSwipeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.fileContentWebView addSubview:leftChangeButton];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:leftChangeButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:leftChangeButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:leftChangeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:32.0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:leftChangeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:65.0]];
    
    UIButton *rightChangeButton = [[UIButton alloc] init];
    rightChangeButton.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.3];
    rightChangeButton.translatesAutoresizingMaskIntoConstraints = NO;
    rightChangeButton.tag = NXCHANGPAGETAGTYPE_RIGHT;
    [rightChangeButton setImage:[UIImage imageNamed:@"nextPageIcon"] forState:UIControlStateNormal];
    [rightChangeButton addTarget:self action:@selector(leftSwipeButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.fileContentWebView addSubview:rightChangeButton];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:rightChangeButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:rightChangeButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.fileContentWebView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0.0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:rightChangeButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:32.0]];
    [self.fileContentWebView addConstraint:[NSLayoutConstraint constraintWithItem:rightChangeButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:65.0]];
}

-(void) removeChangePageButton
{
    UIView *leftBtn = [self.fileContentWebView viewWithTag:NXCHANGPAGETAGTYPE_LEFT];
    [leftBtn removeFromSuperview];
    UIView *rightBtn = [self.fileContentWebView viewWithTag:NXCHANGPAGETAGTYPE_RIGHT];
    [rightBtn removeFromSuperview];
}

- (void)showSelect2DPDFFileButton
{
    //if existed, just return.
    if ([self.view viewWithTag:NXVIEWTAGTYPE_SELECT2DBUTTON]) {
        return;
    }
    //add button.
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    
    button.layer.cornerRadius = button.frame.size.width/2;
    [button setTitle:@"2D" forState:UIControlStateNormal];
    [button setTitle:@"3D" forState:UIControlStateSelected];
    
    button.backgroundColor = RMC_MAIN_COLOR;
    [button setTitleColor:RMC_SUB_COLOR forState:UIControlStateSelected | UIControlStateNormal | UIControlStateHighlighted];
    
    [button addTarget:self action:@selector(showSelect2DPdfFileButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button];
    [self.view bringSubviewToFront:button];
    button.tag = NXVIEWTAGTYPE_SELECT2DBUTTON;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:-16]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-16]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:50]];
    [button addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:0 constant:50]];
}

- (void)removeSelect2DPDFFileButton
{
    [[self.view viewWithTag:NXVIEWTAGTYPE_SELECT2DBUTTON] removeFromSuperview];
}

- (void)showSelect2DPdfFileButtonClicked:(UIButton *)sender
{
    sender.selected = !sender.isSelected;
    sender.enabled = NO;
    sender.backgroundColor = [UIColor lightGrayColor];
    if (sender.selected) {
        [self openNormalSupportFile:self.normalPDFfile];
    } else {
        //3d
        [self load3DFile:self.converted3DfilePath];
    }
    //avoid user click button many times.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
        sender.backgroundColor = RMC_MAIN_COLOR;
    });
}

#pragma mark - Open New
- (void)openNxlFile
{
    // try to get token
    __block NSDictionary* token;
    __block NSError* err = nil;
    
    UIView *waitingView = [NXCommonUtils createWaitingViewInView:self.fileContentWebView];
    
    //it is current user. have all rights.
    __block NSString *owner = nil;
    [NXMetaData getOwner:self.localCachePath complete:^(NSString *ownerId, NSError *error) {
        owner = ownerId;
    }];
    
    self.isSteward = [NXCommonUtils isStewardUser:owner];
    
    __weak DetailViewController *weakSelf = self;
    NSString *curFileDuid = self.duid;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NXMetaData getFileToken:_localCachePath tokenDict:&token error:&err];
        dispatch_async(dispatch_get_main_queue(), ^{
            [waitingView removeFromSuperview];
            //for this if statement, when open another file. the main queue will be stoped. fix bug 36460
            if (![curFileDuid isEqualToString:self.duid]) {
                return;
            }
            
            BOOL isFailedToken = NO;
            if (err) {
                if (err.code == HTTP_ERROR_CODE_ACCESS_FORBIDDEN) {
                    // means current login user doesn't have rights
                    weakSelf.moreButton.enabled = NO;
                    [weakSelf showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"NO_VIEW_RIGHT", nil)];
                    [weakSelf ShowChangePageButton];
                    isFailedToken = YES;
                }
                else if (err.code == 404)
                {
                    weakSelf.moreButton.enabled = NO;
                    [weakSelf showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"NO_ACCESS_RIGHT", NULL)];
                    [weakSelf ShowChangePageButton];
                    isFailedToken = YES;
                }
                else {
                    [weakSelf showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_CANNOTOPENFILE", nil)];
                    [weakSelf closeFile];
                    return;
                }
            }
            
            NXLogAPIRequestModel *model = [[NXLogAPIRequestModel alloc]init];
            model.duid = [[token allKeys] firstObject];
            model.owner = owner;
            model.operation = [NSNumber numberWithInteger:kViewOperation];
            model.repositoryId = @"";
            model.filePathId = weakSelf.curFile.fullServicePath;
            model.filePath = weakSelf.curFile.fullServicePath;
            model.fileName = weakSelf.curFile.fullServicePath;
            model.activityData = @"TestData";
            model.accessTime = [NSNumber numberWithLongLong:([[NSDate date] timeIntervalSince1970] * 1000)];
            
            weakSelf.curNXLFileOwner = owner;
            weakSelf.curNXLFileDUID =  [[token allKeys] firstObject];

            if (isFailedToken) {
                model.accessResult = [NSNumber numberWithInteger:0];
            } else {
                model.accessResult = [NSNumber numberWithInteger:1];
            }
            
            NXLogAPI *logAPI = [[NXLogAPI alloc]init];
            [logAPI generateRequestObject:model];
            [[NXSyncHelper sharedInstance] cacheRESTAPI:logAPI cacheURL:[NXCacheManager getLogCacheURL]];
            [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
                
            }];
            if (isFailedToken) {
                return;
            }
            
            NSMutableDictionary *obligations;
            NXRights *right;
            NSMutableArray *hitPolicies;
            [[NXPolicyEngineWrapper sharedPolicyEngine] getRights:_localCachePath username:[NXLoginUser sharedInstance].profile.userName uid:[NXLoginUser sharedInstance].profile.userId rights:&right obligations:&obligations hitPolicies:&hitPolicies];
            
            weakSelf.curFileRights = right;
            
            NSString* tmpPath = [self getTempFilePath];
            if (tmpPath == nil) {
                [weakSelf showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"FAILED_DECRYPT_NXL_FILE", nil)];
                [weakSelf ShowChangePageButton];
                return;
            }
            
            //    dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            // we need a copy of _localCachePath in block.
            // So that the value of blockLocalCachePath won't changed by _localCachePath which outside block
            // then in afterDecryptNxlFile method we can check if the async decrypted file is the opening file.
            NSString *blockLocalCachePath = [NSString stringWithString:_localCachePath];
            UIView *waitingView = [NXCommonUtils createWaitingViewInView:self.fileContentWebView];
            [NXMetaData decrypt:blockLocalCachePath destPath:tmpPath complete:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [waitingView removeFromSuperview];
                    if (![curFileDuid isEqualToString:weakSelf.duid]) {
                        return;
                    }
                    [weakSelf afterDecryptNxlFile:error nxlFilePath:blockLocalCachePath];
                });
            }];
        });
    });
}

- (void)afterDecryptNxlFile:(NSError *)error nxlFilePath:(NSString *) nxlFilePath
{
    if ([self.localCachePath isEqualToString:nxlFilePath]) {
        if(error == nil)
        {
           [self openNormalFile:YES];
            
        }else
        {
            // decypet nxl file fail,need hit user some error occured
            [self showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_DECRYPTFAIL", nil)];
            [self ShowChangePageButton];
        }
    }
}

- (NSString *)getTempFilePath {
    NSString *tmpPath = [NXCommonUtils getConvertFileTempPath];
    tmpPath = [tmpPath stringByAppendingPathComponent:[_localCachePath lastPathComponent]];
    NSError *error = nil;
    
    // there get file token from RMS, may failed for no right or network error
    NSString *fileExtension = [NXCommonUtils getExtension:_localCachePath error:&error];
    if (error) {
        return nil;
    }
    
    tmpPath = [tmpPath stringByAppendingPathExtension:fileExtension];
    return tmpPath;
}

-(void) openNormalFile:(BOOL) isConvertedFromNXL
{
    NSString *fileContentPath = nil;
    if (isConvertedFromNXL) {
        fileContentPath = [self getTempFilePath];
    }else
    {
        fileContentPath = self.localCachePath;
    }
    NSError *error = nil;
    [NXCommonUtils getExtension:fileContentPath error:&error];
    if (error) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_GETFILEEXTENSION_FAILED", nil)];
        return;
    }
    
    NXFileContentType fileContentType = [self checkFileContentType:self.localCachePath]; // check file type use loacalCachePath, because if nxl file, decrypt file only be check by extersion, it is not the same from the original nxl file type.
    [self dispatchToOpenFile:fileContentType fileContentPath:fileContentPath isConvertFromNXL:isConvertedFromNXL];
}

- (NXFileContentType) checkFileContentType:(NSString *) filePath
{
    NSString *extension = [NXCommonUtils getExtension:filePath error:nil];
    
    if (![NXCommonUtils isTheSupportedFormat:extension]) {
        return NXFILECONTENTTYPE_NOTSUPPORT;
    }
    
    if ([extension isEqualToString:FILEEXTENSION_PDF]) {
        return NXFILECONTENTTYPE_PDF;
    }
    
    if ([NXCommonUtils is3DFileFormat:extension]) {
        if ([NXCommonUtils is3DFileNeedConvertFormat:extension]) {
            return NXFILECONTENTTYPE_3D_NEED_CONVERT;
        }else
        {
            return NXFILECONTENTTYPE_3D;
        }
    }
    
    NSString* mimetype = [NXCommonUtils getMiMeType:filePath];
    if ([[mimetype lowercaseString] hasPrefix:@"audio/"] || [[mimetype lowercaseString] hasPrefix:@"video/"]) {
        return NXFILECONTENTTYPE_MEDIA;
    } else{
        return NXFILECONTENTTYPE_NORMAL;
    }
}

-(void) dispatchToOpenFile:(NXFileContentType) fileContentType fileContentPath:(NSString *) fileContentPath isConvertFromNXL:(BOOL) isConvertFromNXL
{
    switch (fileContentType) {
        case NXFILECONTENTTYPE_NOTSUPPORT:
        {
            [self openNotSupportFile:fileContentPath isNXLFile:isConvertFromNXL];
            self.shownFile = YES;
        }
            break;
        case NXFILECONTENTTYPE_NORMAL:
        {
            BOOL ret = [self openNormalSupportFile:fileContentPath];
            if (ret) {
                [self afterOpenFile];
            }
        }
            break;
        case NXFILECONTENTTYPE_MEDIA:
        {
            BOOL ret = [self openMediaFile:fileContentPath];
            if (ret) {
                [self afterOpenFile];
            }
        }
            break;
        case NXFILECONTENTTYPE_PDF:
        {
            self.isPDFFile = YES;
            [self openPDFFile:fileContentPath];
        }
            break;
        case NXFILECONTENTTYPE_3D:
        {
            BOOL ret = [self open3DFile:fileContentPath];
            if (ret) {
                [self afterOpenFile];
            }
        }
            break;
        case NXFILECONTENTTYPE_3D_NEED_CONVERT:
        {
            [self open3DNeedConvertFile:fileContentPath];
        }
            break;
        default:
            break;
    }
}

-(void) openNotSupportFile:(NSString *) fileContentPath isNXLFile:(BOOL) isNXL
{
    [self hintUserOpenInOtherApp:isNXL];
    [self ShowChangePageButton];
}

-(void) openPDFFile:(NSString *) fileContentPath
{
    BOOL is3Dpdf = [NXCommonUtils ispdfFileContain3DModelFormat:fileContentPath];
    if (is3Dpdf) {
        self.normalPDFfile = fileContentPath;
        [self open3DNeedConvertFile:fileContentPath];
    } else {
        BOOL bOpened = [self openNormalSupportFile:fileContentPath];
        if (bOpened) {
            [self afterOpenFile];
        }
    }
}
-(void) open3DNeedConvertFile:(NSString *) fileContentPath
{
    NSData *plain = [NSData dataWithContentsOfFile:fileContentPath];
    [self convert3DFileFormat:plain];
}

-(BOOL) openNormalSupportFile:(NSString *) fileContentPath
{
    NSString* mimetype = [NXCommonUtils getMiMeType:_localCachePath];
    NSData *plain = [NSData dataWithContentsOfFile:fileContentPath];
    BOOL ret = [self loadFile:plain MIMEType:mimetype textEncodingName:@"UTF-8" baseURL:nil filePath:fileContentPath];
    [self ShowChangePageButton];
    return ret;
}

-(BOOL) openMediaFile:(NSString *) fileContentPath
{
    BOOL ret =  [self loadMediaFile:fileContentPath];
    [self ShowChangePageButton];
    return ret;
}

-(BOOL) open3DFile:(NSString *) fileContentPath
{
    BOOL ret = [self load3DFile:fileContentPath];
    [self ShowChangePageButton];
    return ret;
}

@end
