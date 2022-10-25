
//
//  NXRestAPI.m
//  nxrmc
//
//  Created by Kevin on 15/6/24.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXRestAPI.h"

#import <UIKit/UIDevice.h>


#import "NXLoginUser.h"
#import "NXRMCDef.h"
#import "GTMBase64.h"
#import "NXCommonUtils.h"
#import "XMLWriter.h"
#import "NSString+Utility.h"

#define SERVERRESPONSERATIOIN   0.2
#define SuccessHttpCode 200
#define FailureHttpCode 400

#define REQUESTURL @"responseURL"
#define REQUESTFLAG @"requestFlag"
#define PROGRESS @"progress"
#define NILDATA @"NIL"
#define RESPONSEDATA @"responseData"
#define RESPONSEDATATYPE @"responseDataType"
#define RESPONSEERR @"responseError"

@interface NSURLRequest (DummyInterface)

+(void) setAllowsAnyHTTPSCertificate:(BOOL) allow forHost: (NSString*)host;

@end

NXRestAPI* gRestAPI = nil;

@implementation NXRESTAPIVersion

@end


@interface NXURLConnection()<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
{
    NSMutableData*      _receivedData;
    NSInteger           _statusCode;
    long long           _downloadSize;
    CGFloat             _progress;
}
@property(nonatomic, strong) NSURLSession* connSession;
@property(nonatomic, strong) NSURLSessionDataTask* dataTask;
@property(nonatomic, strong) NSThread *callThread;
@end


@implementation NXURLConnection


- (void) dealloc
{
    
}
#pragma mark NXURLConnection GETTER/SETTER
-(NSURLSession*) connSession
{
    if (!_connSession) {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _connSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    
    return _connSession;
}

-(void) sendGetRequest: (NSURL*)url
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"GET"];
    
    _receivedData = nil;
    _statusCode = 200;
    _callThread = [NSThread currentThread];
    
    [self startNewDataTask:request];
}

-(void) sendPostRequest:(NSURL *)url postData:(NSData *)postData
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"text/plain, charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:postData];
    

    _receivedData = nil;
    _statusCode = 200;
    _callThread = [NSThread currentThread];

    [self startNewDataTask:request];
    
}

- (void) sendPostRequest:(NSURL *)url postData:(NSData *)postData contentType:(NSString *)type
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:type forHTTPHeaderField:@"Content-Type"];
    
    [request setHTTPBody:postData];
    
    
    _receivedData = nil;
    _statusCode = 200;
    _callThread = [NSThread currentThread];
    
    [self startNewDataTask:request];
    
}

- (void) sendRequest:(NSURLRequest *) request
{
    _receivedData = nil;
    _statusCode = 200;
    _callThread = [NSThread currentThread];
    
    [self startNewDataTask:request];

}

-(void) startNewDataTask:(NSURLRequest*) request
{
    self.dataTask = [self.connSession dataTaskWithRequest:request];
    [self.dataTask resume];
}


- (void) cancel
{
    if (self.dataTask.state == NSURLSessionTaskStateRunning || self.dataTask.state == NSURLSessionTaskStateSuspended) {
        [self.dataTask cancel];
        self.dataTask = nil;
    }
}

// This method must called by user, when every session is end, otherwise memory leak(self strong connSession, connSession delegate strong self)
- (void) invalidateSession
{
    [self.connSession invalidateAndCancel];
    self.connSession = nil;
}

#pragma mark NSURLSession Delegate
/*- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if (challenge.previousFailureCount == 0) {
        NSLog(@"willSendRequestForAuthentiationChallenge: %@", challenge.protectionSpace.authenticationMethod);
        if ([challenge.protectionSpace.authenticationMethod isEqualToString: NSURLAuthenticationMethodServerTrust]) {
            NSLog(@"cert host: %@", challenge.protectionSpace.host);
            //     SecTrustResultType t;
            //     SecTrustEvaluate(challenge.protectionSpace.serverTrust, &t);
            NSURLCredential* cred = [NSURLCredential credentialForTrust:[[challenge protectionSpace] serverTrust]];
            completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
        }else
        {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    }else
    {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
    
}*/



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    _progress = (float)totalBytesSent/(float)totalBytesExpectedToSend * (1 - SERVERRESPONSERATIOIN)/2;
    if (_delegate && [_delegate respondsToSelector:@selector(postResponse:progress:)]) {
        
        NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:task.currentRequest.URL,  REQUESTURL, [[NSNumber alloc] initWithFloat:_progress], PROGRESS, nil];
        if (self.callThread.isExecuting) {
            [self performSelector:@selector(performDelegateProgress:) onThread:self.callThread withObject:dic waitUntilDone:YES];
        }
        
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:task.currentRequest.URL forKey:REQUESTURL];
    
    if (error == nil  && _statusCode != 200) {
        error = [[NSError alloc] initWithDomain:@"rest api fail" code:_statusCode userInfo:nil];
    }
    
    if (error) {
        if(error.code == NSURLErrorCancelled)
        {
            return;
        }
        
        [dic setObject:error forKey:RESPONSEERR];
        
    }
    
    NSString* data = [[NSString alloc] initWithData:_receivedData encoding:NSUTF8StringEncoding];
    if (data) {
        [dic setObject:data forKey:RESPONSEDATA];
    }
    
    if (_receivedData) {
        [dic setObject:[_receivedData copy] forKey:RESPONSEDATATYPE];
    }
    
    NSString *reqFlag = [task.currentRequest valueForHTTPHeaderField:RESTAPIFLAGHEAD];
    if (reqFlag) {
        [dic setObject:reqFlag forKey:REQUESTFLAG];
    }
    
    if (self.callThread.isExecuting) {
        [self performSelector:@selector(performDelegatePostResponse:) onThread:self.callThread withObject:dic waitUntilDone:YES];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *re = (NSHTTPURLResponse *)response;
        NSLog(@"%@", re);
        _statusCode = [(NSHTTPURLResponse *)response statusCode];
        if (_statusCode != 200) {
            NSLog(@"%s failed status code %ld", __FUNCTION__, (long)_statusCode);
            
        }
        else
        {
            _downloadSize = response.expectedContentLength;
        }
        
    }
    
    _receivedData = nil;
    
    completionHandler(NSURLSessionResponseAllow);
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
  
    if (!_receivedData) {
        _receivedData = [[NSMutableData alloc] initWithData:data];
    }
    else
    {
        [_receivedData appendData:data];
    }
    
    _progress = (float)dataTask.countOfBytesReceived /(float)dataTask.countOfBytesExpectedToReceive * (1 - SERVERRESPONSERATIOIN)/2 + (1 + SERVERRESPONSERATIOIN)/2;
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:dataTask.currentRequest.URL,  REQUESTURL, [[NSNumber alloc] initWithFloat:_progress], PROGRESS, nil];
    if (self.callThread.isExecuting) {
        [self performSelector:@selector(performDelegateProgress:) onThread:self.callThread withObject:dic waitUntilDone:YES];
    }
    

}

-(void) performDelegatePostResponse:(NSDictionary *) dic
{
    NSURL *url = dic[REQUESTURL];
    NSString* data = dic[RESPONSEDATA];
    NSError* error = dic[RESPONSEERR];
    NSString *reqFlag = dic[REQUESTFLAG];
    NSData * dataContent = dic[RESPONSEDATATYPE];
    
    if (reqFlag) {
        if ([self.delegate respondsToSelector:@selector(postResponse:requestFlag:result:error:)]) {
            [self.delegate postResponse:url requestFlag:reqFlag result:data error:error];
        }
    }else
    {
        [_delegate postResponse:url result:data data:dataContent error:error];

    }
}

-(void) performDelegateProgress:(NSDictionary *) dic
{
    NSURL *url = dic[REQUESTURL];
    NSNumber *progress = dic[PROGRESS];
    if (_delegate && [_delegate respondsToSelector:@selector(postResponse:progress:)]) {
        [_delegate postResponse:url progress:progress];
    }

}

@end


@interface NXRestAPI ()
{
    NXURLConnection* _conn;
}

@end

@implementation NXRestAPI

+ (NXRESTAPIVersion*) versionMake:(int)major minor:(int)minor maintenance:(int)maintenance patch:(int)patch build:(int)build
{
    NXRESTAPIVersion* v = [[NXRESTAPIVersion alloc]init];
    v.major = major;
    v.minor = minor;
    v.maintenance = maintenance;
    v.patch = patch;
    v.build = build;
    
    return v;
}

- (id) init
{
    if (self = [super init]) {
        _conn = [[NXURLConnection alloc] init];
        _conn.delegate = self;
    }
    
    return self;
}

- (NSString *)makeRmserver:(NSString *)rmserver {
    return [NSString stringWithFormat:@"%@%@", rmserver, RESTAPITAIL];
}


- (void) convertFile:(int) agentId fileContent: (NSData *)data fileName:(NSString *)name toFormat:(NSString *)fmt isNxl:(BOOL)nxl
{    
    NSString *rmsAddress = [NXCommonUtils currentRMSAddress];  // JUST TEMP SOLUTION, for RMS API format not unified
    NSString* url = [NSString stringWithFormat:@"%@/rs/convert/file/%@/%@?fileName=%@&toFormat=hsf", rmsAddress, [NXLoginUser sharedInstance].profile.userId, [NXLoginUser sharedInstance].profile.ticket, name];
    url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[data length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"consume"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    
    [_conn sendRequest:request];
}


- (void) sendRESTRequest:(NSURLRequest *) restRequest
{
    [_conn sendRequest:restRequest];
}

- (void) cancel
{
    [_conn invalidateSession];
}

#pragma mark - NXURLConnectionDelegate
-(void) postResponse:(NSURL *)url result:(NSString *)result data:(NSData *)data error:(NSError *)err
{
    [_conn invalidateSession]; // put invalidateSession before call delegate method, otherwise the delegate may call connection again, there may be mulit-thread operation on _conn
    [_delegate restAPIResponse:url result:result data:data error:err];
    
}

-(void) postResponse:(NSURL *)url requestFlag:(NSString *)reqFlag result:(NSString *)result error:(NSError *)err
{
    [_conn invalidateSession];
    if ([_delegate respondsToSelector:@selector(restAPIResponse:requestFlag:result:error:)]) {
        [_delegate restAPIResponse:url requestFlag:reqFlag result:result error:err];
    }
}

-(void) postResponse:(NSURL *)url progress:(NSNumber *)progress
{
    if (_delegate && [_delegate respondsToSelector:@selector(restAPIResponse:progress:)]) {
        [_delegate restAPIResponse:url progress:progress];
    }
}

#pragma mark - private method

- (NSString *) generateRegisterAgentXml:(NSString*) rmserver host: (NSString *)host version:(NXRESTAPIVersion *)ver
{
    XMLWriter *w = [[XMLWriter alloc] init];
    [w writeStartElement:@"RegisterAgentRequest"];
    {
        [w writeStartElement:@"RegistrationData"];
        {
            [w writeStartElement:@"host"];
            [w writeCharacters:host];
            [w writeEndElement];
            
            [w writeStartElement:@"version"];
            {
                [w writeStartElement:@"major"];
                [w writeCharacters:[NSString stringWithFormat:@"%d",ver.major]];
                [w writeEndElement];
                
                [w writeStartElement:@"minor"];
                [w writeCharacters:[NSString stringWithFormat:@"%d",ver.minor]];
                [w writeEndElement];
                
                [w writeStartElement:@"maintenance"];
                [w writeCharacters:[NSString stringWithFormat:@"%d",ver.maintenance]];
                [w writeEndElement];
                
                [w writeStartElement:@"patch"];
                [w writeCharacters:[NSString stringWithFormat:@"%d",ver.patch]];
                [w writeEndElement];
                
                [w writeStartElement:@"build"];
                [w writeCharacters:[NSString stringWithFormat:@"%d",ver.build]];
            }
        }
    }
    [w writeEndDocument];
    return [w toString];
}

- (NSString *) generateConvertFileXml:(int) agentId fileContent: (NSData *)data fileName:(NSString *)name toFormat:(NSString *)fmt isNxl:(BOOL)nxl
{
    NSString* base64 = [GTMBase64 stringByEncodingData:data];
    NSString* md5 = [NXCommonUtils md5Data:data];
    
    XMLWriter *w = [[XMLWriter alloc] init];
    [w writeStartDocumentWithEncodingAndVersion:@"utf-8" version:@"1.0"];
    
    [w writeStartElement:@"convertFileService"];
    [w writeAttribute:@"tenantId" value:[NXLoginUser sharedInstance].profile.defaultMembership.tenantId];
    [w writeAttribute:@"agentId" value:[NSString stringWithFormat:@"%d", agentId]];
    [w writeAttribute:@"version" value:@"1"];
    {
        [w writeStartElement:@"convertFileRequest"];
        {
            [w writeStartElement:@"fileName"];
            [w writeCharacters:name.lastPathComponent];
            [w writeEndElement];
            
            [w writeStartElement:@"toFormat"];
            [w writeCharacters:fmt];
            [w writeEndElement];
            
            [w writeStartElement:@"checksum"];
            [w writeCharacters:md5];
            [w writeEndElement];
            
            [w writeStartElement:@"isNxl"];
            [w writeCharacters:[NSString toBOOLString:nxl]];
            [w writeEndElement];
            
            [w writeStartElement:@"binaryFile"];
            [w writeCharacters:base64];
            [w writeEndElement];
        }
        [w writeEndDocument];
    }
    return [w toString];
}

- (NSString *) generateLoginRmserverXml:(NSString *)rmServer agentId:(int)agentId userName:(NSString *)username password:(NSString *)password domain:(NSString *)domain lapType:(NSString *)lapType cert:(NSString *)cert
{
    XMLWriter *w = [[XMLWriter alloc] init];
    [w writeStartDocumentWithEncodingAndVersion:@"utf-8" version:@"1.0"];
    
    [w writeStartElement:@"LoginService"];
    [w writeAttribute:@"tenantId" value:@"str1234"];
    [w writeAttribute:@"agentId" value:[NSString stringWithFormat:@"%d", agentId]];
    [w writeAttribute:@"version" value:@"123"];
    {
        [w writeStartElement:@"LoginRequest"];
        {
            [w writeStartElement:@"UserName"];
            [w writeCharacters:username];
            [w writeEndElement];
            
            [w writeStartElement:@"Password"];
            [w writeCharacters:password];
            [w writeEndElement];
            
            [w writeStartElement:@"Domain"];
            [w writeCharacters:domain];
            [w writeEndElement];
            
            [w writeStartElement:@"IdpType"];
            [w writeCharacters:@"AD"];
            [w writeEndElement];
        }
        [w writeEndDocument];
    }
    
    return [w toString];
}
- (NSString *) generateGetLoginUserAttributesXml:(NSString *)requestId
{
    //TBD
    NSString *str = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
                    <p:UserAttributeRequest authRequestId=\"%@\"\
                    xmlns:p=\"http://nextlabs.com/rms/rmc\" xmlns:types=\"http://nextlabs.com/rms/rmc/types\"\
                    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\
                    xsi:schemaLocation=\"http://nextlabs.com/rms/rmc UserAttributeService.xsd \">\
                    </p:UserAttributeRequest>", requestId];
    return str;
}

- (NSData *)generateGetAuthURLJsonData:(NSString *)tenant authReqId:(NSString *)authReqId {
    NSDictionary *dic = [[NSDictionary alloc]initWithObjectsAndKeys:authReqId, @"authReqId", tenant, @"tenant", nil];
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"generate GetAuthURL failed: %@", error.localizedDescription);
        return nil;
    }
    return data;
}

- (NSData *)generateGetLoginUserAttributesJsonData:(NSString *)authReqId hash:(NSString *)hashValue
{
    NSDictionary *dic = [[NSDictionary alloc]initWithObjectsAndKeys:authReqId, @"authReqId", hashValue, @"hash", nil];
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"generate GetAuthURL failed: %@", error.localizedDescription);
        return nil;
    }
    return data;
}


-(NSString *) convertToCCTimeFormat:(NSDate *) date
{
    if (date) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.sssZZ"];
        NSMutableString *timestamp = [NSMutableString stringWithString:[dateFormatter stringFromDate:date]];
        [timestamp insertString:@":" atIndex:(timestamp.length - 2)];
        return timestamp;
    }
    return nil;
}

#pragma mark ------------------------ new Restful APIs ------------------------------

-(void) getEncryptionTokens
{
    
}


@end
