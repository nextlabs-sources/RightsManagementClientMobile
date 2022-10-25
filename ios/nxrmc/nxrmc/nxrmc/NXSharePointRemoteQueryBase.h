//
//  NXSharePointRemoteQueryBase.h
//  nxrmc
//
//  Created by ShiTeng on 15/6/3.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#ifndef nxrmc_NXSharePointRemoteQueryBase_h
#define nxrmc_NXSharePointRemoteQueryBase_h

#import <Foundation/Foundation.h>
#import "NXSharePointDelegateProtocol.h"

@interface NXSharePointRemoteQueryBase : NSObject


@property (nonatomic, strong) NSString* queryUrl;
@property (nonatomic, strong) id additionData;
@property (nonatomic, retain) id<NXSharePointQueryDelegate> delegate;
@property(nonatomic) NSInteger queryID;

- (void) executeQueryWithRequestId:(NSInteger)requestid;
- (void) executeQueryWithRequestId:(NSInteger)requestid withAdditionData:(id) additionData;
-(instancetype) init;
@end

@implementation NXSharePointRemoteQueryBase

- (void) executeQueryWithRequestId:(NSInteger)requestid
{
    return;
}
- (void) executeQueryWithRequestId:(NSInteger)requestid withAdditionData:(id) additionData
{
    return;
}

-(instancetype) init
{
    self = [super init];
    return self;
}

@end
#endif
