//
//  NXSharePointQueryBase.m
//  nxrmc
//
//  Created by ShiTeng on 15/6/3.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXSharePointQueryBase.h"


@implementation NXSharePointRemoteQueryBase

- (void) executeQueryWithRequestId:(NSInteger)requestid
{
    return;
}
- (void) executeQueryWithRequestId:(NSInteger)requestid withAdditionData:(id) additionData
{
    return;
}

- (void) executeQueryWithRequestId:(NSInteger)requestid Headers:(NSDictionary*)headers RequestMethod:(NSString*) rqMethod BodyData:(NSData*)bodyData withAdditionData:(id) additionData
{
    return;
}

-(void) cancelQueryWithRequestId:(NSInteger) requestid AdditionData:(id) additionData
{
    return;
}

-(NSURLSession*) spSession
{
    if (!_spSession) {
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _spSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    
    return _spSession;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
}
@end