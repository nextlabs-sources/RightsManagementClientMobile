//
//  NXSharePoint.h
//  nxrmc
//
//  Created by ShiTeng on 15/5/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NXServiceOperation.h"
#import "NXSharePointManager.h"

@interface NXSharePoint : NSObject <NXServiceOperation, NXSharePointManagerDelegate>

@property(nonatomic, strong) NXSharePointManager* spMgr;
@property(nonatomic, strong) NSString* userId;
@property(nonatomic, strong) NXFileBase* curFolder;
@property(nonatomic, weak) id<NXServiceOperationDelegate> delegate;
@property(nonatomic, strong)NSString *alias;
@property(nonatomic, strong) NXBoundService *boundService;

- (instancetype) initWithUserId: (NSString *)userId;
-(void) setSharePointSite:(NSString*) siteURL;

@end
