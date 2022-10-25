//
//  NXHeartbeatManager.h
//  nxrmc
//
//  Created by nextlabs on 7/15/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXOverlayTextInfo.h"

@interface NXHeartbeatManager : NSObject

+ (instancetype)sharedInstance;

- (void)start;
- (void)stop;
- (NXOverlayTextInfo *)getOverlayTextInfo;

@end
