//
//  NXLoginHelperViewController.m
//  nxrmc
//
//  Created by nextlabs on 7/1/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXLoginHelperViewController.h"

@interface NXLoginHelperViewController ()<WKNavigationDelegate>

@property(nonatomic, strong) WKWebView *wkWebView;

@property(nonatomic, assign) BOOL barHidden;

@end

@implementation NXLoginHelperViewController

- (instancetype)initWIthWKWebView:(WKWebView *)wkWebView {
    if (self = [super init]) {
        self.wkWebView = wkWebView;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self cleanWebViewCache];
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    // Do any additional setup after loading the view.
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"BOX_CANCEL", NULL) style:UIBarButtonItemStylePlain target:self action:@selector(backBarButtonItemClicked:)];
    self.navigationItem.leftBarButtonItem = backItem;
    self.navigationController.navigationBarHidden = NO;
    
    [self.view addSubview:self.wkWebView];
    self.wkWebView.translatesAutoresizingMaskIntoConstraints = NO;
    self.wkWebView.navigationDelegate = self; 
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.wkWebView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)cleanWebViewCache {
    //    cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
}

#pragma mark

- (void)backBarButtonItemClicked:(id)sender {
    [self.wkWebView stopLoading];
    [self.wkWebView loadHTMLString:@"" baseURL:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dealloc {
    NSLog(@"dealloc: login help vc");
    [self.wkWebView loadHTMLString:@"" baseURL:nil];
    [self.wkWebView removeFromSuperview];
    self.wkWebView = nil;
}

#pragma mark - 

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(nonnull WKNavigationAction *)navigationAction decisionHandler:(nonnull void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
