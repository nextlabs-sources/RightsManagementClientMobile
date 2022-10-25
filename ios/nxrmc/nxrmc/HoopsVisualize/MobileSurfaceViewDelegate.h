//
//  MobileSurfaceViewDelegate.h
//  nxrmc
//
//  Created by helpdesk on 24/6/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MobileSurfaceViewDelegate <NSObject>

@optional

- (void) segControlValueChanged:(UISegmentedControl *)sender;

- (void) buttonPressed:(UIButton *)sender withSelectedSegmentIndex:(NSInteger)selectedSegmentIndex;

@end
