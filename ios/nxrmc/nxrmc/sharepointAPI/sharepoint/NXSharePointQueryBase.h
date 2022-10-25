//
//  NXSharePointQueryBase.h
//  nxrmc
//
//  Created by ShiTeng on 15/6/3.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXSharePointDelegateProtocol.h"

@interface NXSharePointRemoteQueryBase : NSObject<NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>


@property (nonatomic, strong) NSString* queryUrl;
@property (nonatomic, strong) id additionData;
@property (nonatomic, retain) id<NXSharePointQueryDelegate> delegate;
@property(nonatomic) NSInteger queryID;
@property(nonatomic, strong) NSURLSession* spSession;

- (void) executeQueryWithRequestId:(NSInteger)requestid;
- (void) executeQueryWithRequestId:(NSInteger)requestid withAdditionData:(id) additionData;

- (void) executeQueryWithRequestId:(NSInteger)requestid Headers:(NSDictionary*)headers RequestMethod:(NSString*) rqMethod BodyData:(NSData*)bodyData withAdditionData:(id) additionData;

-(void) cancelQueryWithRequestId:(NSInteger) requestid AdditionData:(id) additionData;
@end
