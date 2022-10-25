//
//  NXLoginViewController.m
//  nxrmc
//
//  Created by nextlabs on 3/31/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXLoginViewController.h"

#import <WebKit/WebKit.h>

#import "AppDelegate.h"
#import "NXRMCDef.h"
#import "NXRouterLoginPageURL.h"
#import "NXProfile.h"
#import "NXRMSConfigViewController.h"

static NSString *kJSHandler;

@interface NXLoginViewController ()<UIWebViewDelegate, NSURLSessionDataDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) WKWebView *wkWebView;
@property (weak, nonatomic) IBOutlet UIView *activityCoverView;


@property (weak, nonatomic) UIBarButtonItem *refreshBarButtonItem;
@property (weak, nonatomic) UIBarButtonItem *configRMSButtonItem;

@property (nonatomic) BOOL barHidden;


@end

@implementation NXLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self commitInit];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotateScreen) name:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)rotateScreen {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.wkWebView.scrollView setZoomScale:0.5 animated:NO];
    }
  }
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _barHidden = self.navigationController.navigationBarHidden;
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startAuthentication];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = _barHidden;
}

#pragma mark - 

- (void)commitInit {
    
    [self.navigationItem setHidesBackButton:YES];
    self.navigationItem.title = NSLocalizedString(@"SIGNINTITLE", NULL);
    
    UIBarButtonItem *rightRefreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshURL:)];
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:rightRefreshButton, nil];
    _refreshBarButtonItem = rightRefreshButton;
    
    UIBarButtonItem *leftRMSConfigButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(configRMS:)];
    self.navigationItem.leftBarButtonItem = leftRMSConfigButton;
    _configRMSButtonItem = leftRMSConfigButton;
}

#pragma mark - target-action method

- (void)refreshURL:(id)sender {
    [self startAuthentication];
}

- (void)configRMS:(id)sener
{
    NXRMSConfigViewController *vc = [[NXRMSConfigViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - private method.

- (void)cleanWebViewCache {
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
    NSError *errors;
    [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
}

- (void)showActivityView {
    self.activityCoverView.hidden = NO;
    [self.activityIndicatorView startAnimating];
    self.refreshBarButtonItem.enabled = NO;
    self.wkWebView.userInteractionEnabled = NO;
}

- (void)hiddenActivityView {
    self.activityCoverView.hidden = YES;
    [self.activityIndicatorView stopAnimating];
    self.refreshBarButtonItem.enabled = YES;
    self.wkWebView.userInteractionEnabled = YES;
}

- (void)startAuthentication {
    //every time create a new WKWebview when loading login html page, the reason is we must delete cookies. for iOS8, we can not remove cookies directly. so we just follow three steps, 1, remove WKWebView, 2, delete cookies, 3,add new WKWebView, only this can delete cookies in iOS 8.
    //step 1.
    self.wkWebView.UIDelegate = nil;
    self.wkWebView.navigationDelegate = nil;
    [self.wkWebView removeFromSuperview];
    self.wkWebView = nil;
    
    //step2.
    [self cleanWebViewCache];

    //step3.
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.selectionGranularity = WKSelectionGranularityCharacter;
    config.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    [config.userContentController addScriptMessageHandler:self name:@"observe"];
    if (!kJSHandler) {
        kJSHandler = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"ajax_handler" withExtension:@"js"] encoding:NSUTF8StringEncoding error:nil];
    }
    
    WKUserScript *userScript = [[WKUserScript alloc]initWithSource:kJSHandler injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:userScript];
    WKWebView *wkView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    [self.view addSubview:wkView];
    self.wkWebView = wkView;
    self.wkWebView.navigationDelegate = self;
    self.wkWebView.UIDelegate = self;
    
    self.wkWebView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    
    [self.view bringSubviewToFront:self.activityCoverView];
    
    [self showActivityView];
    NXRouterLoginPageURL* router = [[NXRouterLoginPageURL alloc]initWithRequest:[NXCommonUtils currentTenant]];
    [router requestWithObject:nil Completion:^(id response, NSError *error) {
        NSLog(@"getLoginURL response: %@", response);
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:error.localizedDescription];
                [self hiddenActivityView];
            });
            
            return;
        }
        assert(response);
        NXRouterLoginPageURLResponse *pageURLResonse = (NXRouterLoginPageURLResponse *)response;
        if (pageURLResonse.rmsStatuCode != 200) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:pageURLResonse.rmsStatuMessage];
                [self hiddenActivityView];
            });
            return;
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pageURLResonse.loginPageURLstr]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.wkWebView loadRequest:request];
        });
    }];
}

- (void)parseLoginResult:(NSString *)result {
    if (result == nil) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL)  message:@"message"];
        return;
    }
    NSDictionary *ret = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    
    NSDictionary *userInfo = [ret objectForKey:@"extra"];
    
    NXProfile *profile = [[NXProfile alloc] init];
    NSString *tenantId = [userInfo objectForKey:@"tenantId"];
    
    NSMutableArray *memberships = [[NSMutableArray alloc]init];
    [[userInfo objectForKey:@"memberships"] enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NXMembership *membership = [[NXMembership alloc] init];
        membership.ID = [obj objectForKey:@"id"];
        membership.type = [obj objectForKey:@"type"];
        membership.tenantId = [obj objectForKey:@"tenantId"];
        if ([membership.tenantId isEqualToString:tenantId]) {
            profile.defaultMembership = membership;
        }
        [memberships addObject:membership];
    }];
    
    profile.memberships = memberships;
    profile.rmserver = [NXCommonUtils currentRMSAddress];
    
    NSNumber *userid = [userInfo objectForKey:@"userId"];
    profile.userId = [NSString stringWithFormat:@"%ld", userid.longValue];
    profile.userName = [userInfo objectForKey:@"name"];
    profile.ticket = [userInfo objectForKey:@"ticket"];
    profile.ttl = [userInfo objectForKey:@"ttl"];
    profile.email = [userInfo objectForKey:@"email"];
    
    [[NXLoginUser sharedInstance] loginWithUser:profile];
    
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NXMasterSplitViewController* c = [storyboard instantiateViewControllerWithIdentifier:@"SPVC"];
    c.delegate = (id<UISplitViewControllerDelegate>)app.navigation;
    app.window.rootViewController = c;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.wkWebView loadHTMLString:@"" baseURL:nil];
    [self parseLoginResult:message.body];

}

#pragma mark - WKNavigationDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self hiddenActivityView]; 
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [webView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO]; //otherwise top of website is sometimes hidden under Navigation Bar
    
    [webView.scrollView zoomToRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height) animated:YES];
    
     [self hiddenActivityView];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    // [self showActivityView];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler {    decisionHandler(WKNavigationActionPolicyAllow);
    if ([navigationAction.request.URL.absoluteString containsString:@"mailto"]) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
      }
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
//    [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:message];
    completionHandler();
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    //TBD
    completionHandler(nil);
}
- ( WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
    return nil;
}

@end
