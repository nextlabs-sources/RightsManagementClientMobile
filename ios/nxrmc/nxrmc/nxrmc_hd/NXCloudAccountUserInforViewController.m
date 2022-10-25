//
//  NXCloudAccountUserInforViewController.m
//  nxrmc
//
//  Created by ShiTeng on 15/5/29.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXCloudAccountUserInforViewController.h"
#import "NXSharePointManager.h"
#import "NXSharepointOnlineAuthentication.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"
#import "NXKeyChain.h"
#import "NXAccountPageViewController.h"
#import "NXNetworkHelper.h"

#define SITE_URL_TEXT_FIELD_TAG   50001
#define USER_NAME_TEXT_FIELD_TAG  50002
#define PASS_WORD_TEXT_FIELD_TAG  50003

@interface NXCloudAccountUserInforViewController ()<UITextFieldDelegate, NXSharePointManagerDelegate, NXSharepointOnlineDelegete>

@property (weak, nonatomic) IBOutlet UITextField *spSiteURL;
@property (weak, nonatomic) IBOutlet UITextField *spUserName;
@property (weak, nonatomic) IBOutlet UITextField *spPassword;
@property (weak, nonatomic) IBOutlet UILabel *spServiceType;

@property (nonatomic) BOOL isConnecting;
@property (nonatomic, strong) NXSharePointManager* spMgr;
@property (nonatomic, strong) NXSharepointOnlineAuthentication *auth;
@property (nonatomic, strong) NSString *sharepointOnlineAccountId;
@property (nonatomic, strong) NSString *sharepointOnlineToken;

@end

@implementation NXCloudAccountUserInforViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _spSiteURL.delegate = self;
    _spSiteURL.tag = SITE_URL_TEXT_FIELD_TAG;
    _spUserName.delegate = self;
    _spUserName.tag = USER_NAME_TEXT_FIELD_TAG;
    _spPassword.delegate = self;
    _spPassword.tag = PASS_WORD_TEXT_FIELD_TAG;
    
    _isConnecting = false;
    
    [_addAccount.layer setMasksToBounds:YES];
    [_addAccount.layer setCornerRadius:28];
    _addAccount.backgroundColor = [UIColor colorWithRed:25.f/255.f green:184.f/255.f blue:121.f/255.f alpha:1.0f];
    
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    switch (_serviceBindType) {
       case kServiceSharepointOnline:
           _spServiceType.text = NSLocalizedString(@"CLOUDSERVICE_SHAREPOINTONLINE", nil);
//            _spSiteURL.text = @"https://nextlabs.sharepoint.com/sites/4test";
//            _spUserName.text = @"eshi@nextlabs.onmicrosoft.com";
//            _spPassword.text = @"next123!";
            break;
        case kServiceSharepoint:
           _spServiceType.text = NSLocalizedString(@"CLOUDSERVICE_SHAREPOINT", nil);
//            _spSiteURL.text = @"https://mysite.nextlabs.com/personal/eshi";
//            _spUserName.text = @"nextlabs\\eshi";
//            _spPassword.text = @"Sw1985123";
            
//            _spSiteURL.text = @"https://rms-sp2013.qapf1.qalab01.nextlabs.com/sites/business1/ew";
//            _spUserName.text = @"qapf1\\john.tyler";
//            _spPassword.text = @"john.tyler";
            
            _spSiteURL.text = @"https://rms-sp2013.qapf1.qalab01.nextlabs.com/sites/dev";
            _spUserName.text = @"qapf1\\Abraham.lincoln";
            _spPassword.text = @"abraham.lincoln";
            break;
       default:
            break;
   }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickBackground:(id)sender {
    [_spSiteURL resignFirstResponder];
    [_spUserName resignFirstResponder];
    [_spPassword resignFirstResponder];
}

- (IBAction)clickCancel:(id)sender {
    switch (_serviceBindType) {
        case kServiceSharepointOnline:
            [_auth cancelLogin];
            break;
        case kServiceSharepoint:
            //TBD authentication
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(cloudAccountUserInfoVCDidPressCancelBtn:)]) {
        [self.delegate cloudAccountUserInfoVCDidPressCancelBtn:self];
    }
}

- (IBAction)btnAddAccount:(id)sender {
    if (_isConnecting) {
        return;
    }
    if (![[NXNetworkHelper sharedInstance] isNetworkAvailable]) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"NETWORK_UNREACH_MESSAGE", NULL)];
        return;
    }
    
    // trim the last '/' of url
    NSInteger count = 0;
    NSInteger stringLength = self.spSiteURL.text.length;
    unichar charBuffer[self.spSiteURL.text.length];
    [self.spSiteURL.text getCharacters:charBuffer];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"/"];
    for (NSInteger i = stringLength - 1; i >= 0; i--) {
        if (![charSet characterIsMember:charBuffer[i]]) {
            break;
        }
        count++;
    }
    
    self.spSiteURL.text = [self.spSiteURL.text substringToIndex:(stringLength - count)];
    
    NSString* err = nil;
    if (self.spSiteURL.text.length == 0) {
        err = NSLocalizedString(@"SHAREPOINT_SITE_EMPTYERROR", NULL);;
    }else if(self.spUserName.text.length == 0){
        err = NSLocalizedString(@"ERROR_EMPTYUSERNAME", NULL);
    }else if(self.spPassword.text.length == 0){
        err = NSLocalizedString(@"ERROR_EMPTYPASSWORD", NULL);
    }
    
    if (err) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:err];
        return;
    }
    
    
    if (self.spSiteURL.text && self.spPassword.text && self.spUserName.text) {
        switch (_serviceBindType) {
            case kServiceSharepoint:
            {
                _spMgr = [[NXSharePointManager alloc] initWithSiteURL:self.spSiteURL.text userName:self.spUserName.text passWord:self.spPassword.text Type:kSPMgrSharePoint];
                _spMgr.delegate = self;
                [_spMgr authenticate];
            }
                break;
            case kServiceSharepointOnline:
            {
                _auth = [[NXSharepointOnlineAuthentication alloc] initwithUsernamePasswordSite:_spUserName.text password:_spPassword.text site:_spSiteURL.text];
                _auth.delegate = self;
                [_auth login];
            }
                break;
            default:
                break;
        }
        _isConnecting = YES;
        UIView* waiting = [ NXCommonUtils createWaitingView:60.0f];
        waiting.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:waiting];
        
        //add constraints to make sure the waiting view always at the center of the screen when orientation.
        [self.view addConstraint:[NSLayoutConstraint
                                           constraintWithItem:waiting
                                           attribute:NSLayoutAttributeCenterX
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.view
                                           attribute:NSLayoutAttributeCenterX
                                           multiplier:1.0
                                           constant:-waiting.frame.size.width/2]];
        [self.view addConstraint:[NSLayoutConstraint
                                           constraintWithItem:waiting
                                           attribute:NSLayoutAttributeCenterY
                                           relatedBy:NSLayoutRelationEqual
                                           toItem:self.view
                                           attribute:NSLayoutAttributeCenterY
                                           multiplier:1.0
                                           constant: -waiting.frame.size.height/2]];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == SITE_URL_TEXT_FIELD_TAG) {
        [_spUserName becomeFirstResponder];
        return NO;
    }else if(textField.tag == USER_NAME_TEXT_FIELD_TAG)
    {
        [_spPassword becomeFirstResponder];
        return NO;
    }else if(textField.tag == PASS_WORD_TEXT_FIELD_TAG)
    {
        [_spPassword resignFirstResponder];
        [self btnAddAccount:nil];
        return YES;
    }
    return YES;
}



#pragma mark - NXSharePointManagerDelegate
-(void) didAuthenticationFail:(NSError*) error forQuery:(SPQueryIdentify)type
{
    _isConnecting = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[self.view viewWithTag:8808] removeFromSuperview];
        
        NSString* err;
        if (error) {
            err = NSLocalizedString(@"Sharepoint_SITE_URL_ERROR", nil);
        }else
        {
            err = NSLocalizedString(@"Sharepoint_SIGNIN_ERROR", nil);
        }
        
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:err];
    }); // main thread
}

-(void) didAuthenticationSuccess
{
    _isConnecting = NO;
    __block BOOL ret = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        // account authen success, store it
        // step1. sotre siteUrl as account and account_id
        // Sharepoint accountid:  siteURL^userName
        NSString* sharepointAccountId = [NSString stringWithFormat:@"%@^%@", self.spSiteURL.text, self.spUserName.text];
        [self inputServiceDisplayName:^(NSString *displayName) {
            ret = [[NXLoginUser sharedInstance] addService:kServiceSharepoint serviceAccount:self.spUserName.text serviceAccountId:sharepointAccountId serviceAccountToken: sharepointAccountId isAuthed:YES displayName:displayName];
        }];
  
        [[self.view viewWithTag:8808] removeFromSuperview];
        if (ret) {
            // step2. store password in keychain, key is account_id
            [NXKeyChain save:sharepointAccountId data:self.spPassword.text];
        }
        __weak typeof(self) weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            weakSelf.dismissBlock(ret);
        }];
    }); // main thread
}

#pragma mark - NXSharepointOnlineDelegete

- (void) Authentication:(NXSharepointOnlineAuthentication *)auth didAuthenticateSuccess:(NXSharePointOnlineUser *)user {
    _isConnecting = NO;
    //token = fedauthInfo + rtfaInfo; accountId = siturl + username(distinguish different sharepointonline user)
    NSLog(@"SharepointOnline Authentication success username:%@, siteurl:%@", user.username, user.siteurl);
    
   _sharepointOnlineAccountId = [NSString stringWithFormat:@"%@^%@", self.spSiteURL.text, self.spUserName.text];
   _sharepointOnlineToken = [NSString stringWithFormat:@"%@^%@", user.fedauthInfo, user.rtfaInfo];
    
    //
    NSDictionary *fedAuthCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                                   user.siteurl, NSHTTPCookieOriginURL,
                                   @"FedAuth", NSHTTPCookieName,
                                   @"/", NSHTTPCookiePath,
                                   user.fedauthInfo, NSHTTPCookieValue,
                                   nil];
    
    NSDictionary *rtFaCookie = [NSDictionary dictionaryWithObjectsAndKeys:
                                user.siteurl, NSHTTPCookieOriginURL,
                                @"rtFa", NSHTTPCookieName,
                                @"/", NSHTTPCookiePath,
                                user.rtfaInfo, NSHTTPCookieValue,
                                nil];
    
    
    NSHTTPCookie *fedAuthCookieObj = [NSHTTPCookie cookieWithProperties:fedAuthCookie];
    NSHTTPCookie *rtFaCookieObj = [NSHTTPCookie cookieWithProperties:rtFaCookie];
    
    NSArray *cookiesArray = @[fedAuthCookieObj, rtFaCookieObj];
    _spMgr = [[NXSharePointManager alloc] initWithURL:user.siteurl cookies:cookiesArray Type:kSPMgrSharePointOnline];
    _spMgr.delegate = self;
    [_spMgr allDocumentLibListsOnSite];
    
}

- (void) Authentication:(NXSharepointOnlineAuthentication *)auth didAuthenticateFailWithError:(NSString *)error {
    _isConnecting = NO;
    NSLog(@"SharepointOnline Authentication failed %@", error);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.view viewWithTag:8808] removeFromSuperview];
        if ([error isEqualToString:@"get cookies failed"]) {
            [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"SharepointOnline_SIGNIN_ERROR", NULL)];
        }else
        {
            [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"SharepointOnline_SITE_URL_ERROR", NULL)];
        }
        
    }); // main thread
}

-(void) didFinishSPQuery:(NSArray*) result forQuery:(SPQueryIdentify) type
{
    BOOL ret = [[NXLoginUser sharedInstance] addService:kServiceSharepointOnline serviceAccount:self.spUserName.text serviceAccountId:self.sharepointOnlineAccountId serviceAccountToken:self.sharepointOnlineToken isAuthed:YES displayName:@"DisplayName"];
    
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.view viewWithTag:8808] removeFromSuperview];
        [self dismissViewControllerAnimated:YES completion:^{
            weakSelf.dismissBlock(ret);
        }];
    }); // main thread

}

-(void) didFinishSPQueryWithError:(NSError*) error forQuery:(SPQueryIdentify) type
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.view viewWithTag:8808] removeFromSuperview];
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"SharepointOnline_SITE_URL_ERROR", NULL)];
    }); //
}

-(void) inputServiceDisplayName:(void(^)(NSString *))finishBlock
{
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"ALERTVIEW_TITLE", NULL)
                                                                              message: NSLocalizedString(@"INPUT_REPO_NAME", NULL)
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"name";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
    }];
    
    __weak typeof(self) weakSelf = self;
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"BOX_OK", NULL) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * displayName = textfields[0];
        if ([displayName.text isEqualToString:@""]) {
            return;
        }
        finishBlock(displayName.text);
        __strong NXCloudAccountUserInforViewController* strongSelf = weakSelf;
        [strongSelf dismissViewControllerAnimated:YES completion:^{
            
        }];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}




@end
