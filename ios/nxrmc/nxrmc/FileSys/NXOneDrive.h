//
//  NXOneDrive.h
//  nxrmc
//
//  Created by helpdesk on 27/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NXServiceOperation.h"
#import "LiveSDk/LiveDownloadOperation.h"
#import "LiveSDK/LiveConnectClient.h"

@interface NXOneDrive : NSObject<LiveOperationDelegate,LiveDownloadOperationDelegate,LiveUploadOperationDelegate, NXServiceOperation>
@property(nonatomic, strong)NSString *alias;
- (id) init;
- (id) initWithUserId: (NSString *)userId;
@property(nonatomic, strong) NXBoundService *boundService;
@end
