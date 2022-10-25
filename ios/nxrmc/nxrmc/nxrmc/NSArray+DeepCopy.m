//
//  NSArray+DeepCopy.m
//  nxrmc
//
//  Created by nextlabs on 7/9/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NSArray+DeepCopy.h"

@implementation NSArray (DeepCopy)

- (NSArray*) deepCopy {
    NSUInteger count = [self count];
    id cArray[count];
    
    for (int i = 0; i < count; ++i) {
        id obj = [self objectAtIndex:i];
        if ([obj respondsToSelector:@selector(deepCopy)]) {
            cArray[i] = [obj deepCopy];
        } else {
            cArray[i] = [obj copy];
        }
    }
    
    NSArray *ret = [NSArray arrayWithObjects:cArray count:count];
    return ret;
}

- (NSMutableArray*) mutableDeepCopy {
    NSUInteger count = [self count];
    id cArray[count];
    
    for (int i = 0; i < count; ++i) {
        id obj = [self objectAtIndex:i];
        
        // Try to do a deep mutable copy, if this object supports it
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            cArray[i] = [obj mutableDeepCopy];
        } else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)]) {
            cArray[i] = [obj mutableCopy];
        } else if ([obj respondsToSelector:@selector(deepCopy)]) {
            cArray[i] = [obj deepCopy];
        } else {
            cArray[i] = [obj copy];
        }
    }
    
    NSMutableArray *ret = [NSMutableArray arrayWithObjects:cArray count:count];
    return ret;
}

@end
