//
//  NXSharePointRemoteQuery.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/25.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXSharePointQueryBase.h"

@interface NXSharePointRemoteQuery : NXSharePointRemoteQueryBase

@property(nonatomic, strong) NSString* userName;
@property(nonatomic, strong) NSString* psw;



-(instancetype) initWithURL:(NSString*) url userName:(NSString*) name passWord:(NSString*) psw;

@end
