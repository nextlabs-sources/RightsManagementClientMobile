//
//  NSTimer+NXBlockSupport.h
//  nxrmc
//
//  Created by nextlabs on 8/9/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (NXBlockSupport)

+ (NSTimer *)nx_scheduledTimerWithTimeInterval:(NSTimeInterval)interval block:(void(^)())block repeats:(BOOL)repeats;

@end
