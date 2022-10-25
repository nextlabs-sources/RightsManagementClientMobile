//
//  NXRouterLoginPageURL.h
//  nxrmc
//
//  Created by Kevin on 16/6/29.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXSuperRESTAPI.h"

@interface NXRouterLoginPageURL : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

- (instancetype)initWithRequest:(NSString*)tenant;

@end


@interface NXRouterLoginPageURLResponse : NXSuperRESTAPIResponse

@property(nonatomic, strong) NSString *loginPageURLstr;

@end