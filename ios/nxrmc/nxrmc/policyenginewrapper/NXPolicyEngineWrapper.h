//
//  NXPolicyEngineWrapper.h
//  nxrmc
//
//  Created by Kevin on 15/6/5.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXRights.h"


@interface NXPolicyEngineWrapper : NSObject

+ (NXPolicyEngineWrapper*) sharedPolicyEngine;


// uid: for rms, uid is sid.
- (void) getRights: (NSString*) nxlPath username: (NSString*) uname uid: (NSString*) uid rights:(NXRights**)rights obligations:(NSMutableDictionary **)obligations hitPolicies:(NSMutableArray **) hitPolicies;

@end
