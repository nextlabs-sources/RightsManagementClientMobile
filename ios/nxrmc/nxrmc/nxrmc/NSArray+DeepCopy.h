//
//  NSArray+DeepCopy.h
//  nxrmc
//
//  Created by nextlabs on 7/9/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (DeepCopy)

- (NSArray*) deepCopy;
- (NSMutableArray*) mutableDeepCopy;

@end
