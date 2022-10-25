//
//  NXDataPassDelegate.h
//  nxrmc
//
//  Created by Bill on 5/6/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NXDataPassDelegate <NSObject>

@optional
- (void) passContentsOfInteger:(NSInteger) value;

- (void) passContentsOfBOOL:(BOOL) boolValue;

@end
