//
//  NSTimer+NXBlockSupport.m
//  nxrmc
//
//  Created by nextlabs on 8/9/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NSTimer+NXBlockSupport.h"

@implementation NSTimer (NXBlockSupport)
+ (NSTimer *)nx_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void(^)())block repeats:(BOOL)repeats {
    return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(nx_blockInvoke:) userInfo:[block copy] repeats:repeats];
}

+ (void)nx_blockInvoke:(NSTimer *)timer {
    void (^block)() = timer.userInfo;
    if (block) {
        block();
    }
}
@end
