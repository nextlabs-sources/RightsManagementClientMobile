//
//  NXPolicyEngineWrapper.m
//  nxrmc
//
//  Created by Kevin on 15/6/5.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXPolicyEngineWrapper.h"

#import <map>
#import <vector>

#import "NXPolicyEngine.h"
#import "NXLoginUser.h"
#import "NXMetaData.h"

static NXPolicyEngineWrapper* sharedObj = nil;


@implementation NXPolicyEngineWrapper


+ (NXPolicyEngineWrapper*) sharedPolicyEngine
{
    @synchronized(self)
    {
        if (sharedObj == nil) {
            sharedObj = [[super allocWithZone:nil] init];
        }
    }
    
    return sharedObj;
}

+ (id) allocWithZone:(struct _NSZone *)zone
{
    return nil;
}

- (void) getRights:(NSString *)nxlPath username:(NSString *)uname uid:(NSString *)uid rights:(NXRights *__autoreleasing *)rights obligations:(NSMutableDictionary *__autoreleasing *)obligations hitPolicies:(NSMutableArray *__autoreleasing *)hitPolicies
{
    dispatch_semaphore_t semi = dispatch_semaphore_create(0);
    
    // get rights from ad-hoc section in nxl
    __block NSDictionary *blockPolicySection = nil;
    [NXMetaData getPolicySection:nxlPath complete:^(NSDictionary *policySection, NSError *error) {
        if (error) {
            //
        } else {
            blockPolicySection = policySection;
        }
        dispatch_semaphore_signal(semi);
    }];
    dispatch_semaphore_wait(semi, DISPATCH_TIME_FOREVER);
    
    if (blockPolicySection == nil) {
        return;
    }
    
    
    NSArray* policies = [blockPolicySection objectForKey:@"policies"];
    if (policies.count == 0) {
        return;
    }
    
    NSDictionary* policy = [policies objectAtIndex:0];
    NSArray* namedRights = [policy objectForKey:@"rights"];
    NSArray* namedObs = [policy objectForKey:@"obligations"];
    *rights = [[NXRights alloc]initWithRightsObs:namedRights obligations:namedObs];
}

@end



