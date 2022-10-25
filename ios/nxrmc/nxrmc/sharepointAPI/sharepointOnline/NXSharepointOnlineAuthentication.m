//
//  NXSharepointOnlineAuthentication.m
//  NXsharepointonline
//
//  Created by nextlabs on 5/28/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXSharepointOnlineAuthentication.h"
#import "NXXMLDocument.h"
#import "NXSharepointOnlineAuthReply.h"

#ifndef NXSHAREPOINTONLINE_MACRO
#define NXSHAREPOINTONLINE_MACRO

// identify node type
#define SP_BODY_TAG @"Body"
#define SP_REQUEST_SECURITY_TOKEN_RESPONSE_TAG @"RequestSecurityTokenResponse"
#define SP_REQUEST_SECURITY_TOKEN @"RequestedSecurityToken"
#define SP_BINARY_SECURITY_TOKEN @"BinarySecurityToken"
#define SP_FAULT_TAG @"Fault"
#define SP_DETAIL_TAG @"Detail"
#define SP_ERROR_TAG @"error"
#define SP_INTERNAL_ERROR_TAG @"internalerror"
#define SP_TEXT_TAG @"text"

// identify node type
#define SP_COOKIE_FEDAUTH @"FedAuth"
#define SP_COOKIE_RTFA @"rtFa"

// URL Request method
#define SP_METHOD_POST @"POST"
#define SP_METHOD_GET @"GET"

// url for sharepointonline authentication
#define SP_AUTH_URL_LOGIN @"https://login.microsoftonline.com/extSTS.srf"
#define SP_AUTH_URL_SPO @"/_forms/default.aspx?wa=wsignin1.0"

#endif

@implementation NXSharePointOnlineUser

- (instancetype) init {
    if(self = [super init]) {
        
    }
    return self;
}

@end

@interface NXSharepointOnlineAuthentication()<NXSharepointOnlineReplyDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, retain) NSString *bodyTemplate;
@property (nonatomic, retain) NSMutableData *responseData;

@property (nonatomic, retain) NSString *siteurl;
@property (nonatomic, retain) NXSharePointOnlineUser *user;

@property (nonatomic, strong) NXSharepointOnlineAuthReply *reply;

@property(nonatomic, strong) NSURLSession* securityTokenSession;
@property(nonatomic, strong) NSURLSessionDataTask* securityTokenDataTask;

@property(nonatomic, strong) NSURLSession* getCookiesSession;
@property(nonatomic, strong) NSURLSessionDataTask* getCookiesDataTask;

@end

@implementation NXSharepointOnlineAuthentication

#pragma mark - public interface

- (id) initwithUsernamePasswordSite:(NSString *)username password:(NSString *)password site:(NSString *)site {
    _bodyTemplate = @"<?xml version=\"1.0\" encoding=\"utf-8\" ?><s:Envelope xmlns:s=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:a=\"http://www.w3.org/2005/08/addressing\" xmlns:u=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd\"><s:Header><a:Action s:mustUnderstand=\"1\">http://schemas.xmlsoap.org/ws/2005/02/trust/RST/Issue</a:Action><a:ReplyTo><a:Address>http://www.w3.org/2005/08/addressing/anonymous</a:Address></a:ReplyTo><a:To s:mustUnderstand=\"1\">https://login.microsoftonline.com/extSTS.srf</a:To><o:Security s:mustUnderstand=\"1\" xmlns:o=\"http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd\"><o:UsernameToken><o:Username>%@</o:Username><o:Password>%@</o:Password></o:UsernameToken></o:Security></s:Header><s:Body><t:RequestSecurityToken xmlns:t=\"http://schemas.xmlsoap.org/ws/2005/02/trust\"><wsp:AppliesTo xmlns:wsp=\"http://schemas.xmlsoap.org/ws/2004/09/policy\"><a:EndpointReference><a:Address>%@/_forms/default.aspx?wa=wsignin1.0</a:Address></a:EndpointReference></wsp:AppliesTo><t:KeyType>http://schemas.xmlsoap.org/ws/2005/05/identity/NoProofKey</t:KeyType><t:RequestType>http://schemas.xmlsoap.org/ws/2005/02/trust/Issue</t:RequestType><t:TokenType>urn:oasis:names:tc:SAML:1.0:assertion</t:TokenType></t:RequestSecurityToken></s:Body></s:Envelope>";
    _user = [[NXSharePointOnlineUser alloc] init];
    _user.username = username;
    _user.password = password;
    _user.siteurl = site;
    _siteurl = site;
    
    _bodyTemplate = [NSString stringWithFormat:_bodyTemplate, username, password, site];
    
    return  self;
}

- (void) cancelLogin {
    if (_securityTokenDataTask) {
        if (_securityTokenDataTask.state == NSURLSessionTaskStateRunning || _securityTokenDataTask.state == NSURLSessionTaskStateSuspended) {
            [_securityTokenDataTask cancel];
        }
        _securityTokenDataTask = nil;
        _securityTokenSession = nil;
    }
    if (_getCookiesDataTask) {
        if (_getCookiesDataTask.state == NSURLSessionTaskStateRunning || _getCookiesDataTask.state == NSURLSessionTaskStateSuspended) {
            [_getCookiesDataTask cancel];
        }
        _getCookiesDataTask = nil;
        _getCookiesSession = nil;
    }
}

- (void) login {
    NSURL *url = [NSURL URLWithString:SP_AUTH_URL_LOGIN];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:SP_METHOD_POST];
    [request setHTTPBody:[_bodyTemplate dataUsingEncoding:NSUTF8StringEncoding]];
    
    _reply = [[NXSharepointOnlineAuthReply alloc] init];
    _reply.delegate = self;
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _securityTokenSession = [NSURLSession sessionWithConfiguration:config delegate:_reply delegateQueue:nil];
    _securityTokenDataTask = [_securityTokenSession dataTaskWithRequest:request];
    [_securityTokenDataTask resume];
}

#pragma mark - private interface

- (NSURLRequest*) initializeGetCookiesRequest:(NSString *) securityToken {
    NSURL *url = [NSURL URLWithString:_siteurl];
    NSString *server = [NSString stringWithFormat:@"%@%@%@%@", url.scheme, @"://", url.host, SP_AUTH_URL_SPO];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:server]];
    
    [request setHTTPMethod:SP_METHOD_POST];
    [request setHTTPBody:[securityToken dataUsingEncoding:NSUTF8StringEncoding]];
    return request;
}

- (NSString*)parseSecuritoyToken:(NSData*)data {
    NSError *error;
    NXXMLDocument *document = [NXXMLDocument documentWithData:data error:&error];
    
    NXXMLElement *bodyElement = [document.root childNamed:SP_BODY_TAG];
    NXXMLElement *tokenResponseElement = [bodyElement childNamed:SP_REQUEST_SECURITY_TOKEN_RESPONSE_TAG];
    
    NXXMLElement *requestedTokenElement = [tokenResponseElement childNamed:SP_REQUEST_SECURITY_TOKEN];
    NSString *securityToken = [requestedTokenElement valueWithPath:SP_BINARY_SECURITY_TOKEN];
    if (securityToken) {
        NSLog(@"got the security token success");
    }
    return securityToken;
}

# pragma mark - NXSharepointOnlineReplyDelegate

- (void) nxsharepointOnelineReply:(NXSharepointOnlineAuthReply *)replay didReplysuccess:(NSData *)data {
    NSString* securityToken = [self parseSecuritoyToken:data];
    NSURLRequest* request = [self initializeGetCookiesRequest:securityToken];
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    _getCookiesSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    _getCookiesDataTask = [_getCookiesSession dataTaskWithRequest:request];
    [_getCookiesDataTask resume];
}

- (void) nxsharepointOnelineReply:(NXSharepointOnlineAuthReply *)replay didFailWithError:(NSError *)error {
    if ([_delegate respondsToSelector:@selector(Authentication:didAuthenticateFailWithError:)]) {
        [_delegate Authentication:self didAuthenticateFailWithError:error.description];
    }
}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [_responseData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * __nullable))completionHandler
{
    NSString* responsestr = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    if([responsestr rangeOfString:SP_FAULT_TAG].location != NSNotFound)
    {
        NSLog(@"Error logging in");
        
        NSError *error;
        NXXMLDocument *responseDoc = [NXXMLDocument documentWithData:_responseData error:&error];
        
        NSString *strerror = [NSString stringWithString:[[[[[[responseDoc.root childNamed:SP_BODY_TAG] childNamed:SP_FAULT_TAG] childNamed:SP_DETAIL_TAG] childNamed:SP_ERROR_TAG] childNamed:SP_INTERNAL_ERROR_TAG] valueWithPath:SP_TEXT_TAG]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_delegate respondsToSelector:@selector(Authentication:didAuthenticateFailWithError:)]) {
                [_delegate Authentication:self didAuthenticateFailWithError:strerror];
            }
        });
    }
    
   
    
    NSMutableString *site = [[NSMutableString alloc] initWithString:_siteurl];
    [site appendString:SP_AUTH_URL_SPO];
    
    NSArray *cookies = [NSHTTPCookie cookiesWithResponseHeaderFields:[response allHeaderFields] forURL:[NSURL URLWithString:site]];
    
    for(NSHTTPCookie *cookie in cookies) {
        if([cookie.name isEqualToString:SP_COOKIE_FEDAUTH]) {
            _user.fedauthInfo = cookie.value;
        }
        else if ([cookie.name isEqualToString:SP_COOKIE_RTFA]) {
            _user.rtfaInfo = cookie.value;
        }
    }
    
    completionHandler(request);

}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    if(error)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_delegate respondsToSelector:@selector(Authentication:didAuthenticateFailWithError:)]) {
                [_delegate Authentication:self didAuthenticateFailWithError:error.description];
            }
        });
    }
    else
    {
        if (_user.rtfaInfo && _user.fedauthInfo) {
            NSLog(@"get cookies success");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if([_delegate respondsToSelector:@selector(Authentication:didAuthenticateSuccess:)]){
                    [_delegate Authentication:self didAuthenticateSuccess:_user];
                }

            });
            return;
        }
        
        NSString* error = @"get cookies failed";
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_delegate respondsToSelector:@selector(Authentication:didAuthenticateFailWithError:)]) {
                [_delegate Authentication:self didAuthenticateFailWithError:error];
            }
        });
    }
}
@end
