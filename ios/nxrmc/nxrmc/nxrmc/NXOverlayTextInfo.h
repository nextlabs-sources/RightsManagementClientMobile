//
//  NXOverlayTextInfo.h
//  nxrmc
//
//  Created by nextlabs on 8/19/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NXHeartbeatAPI.h"

@interface NXOverlayTextInfo : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong) NSNumber *transparency;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic) BOOL isclockwiserotation;

- (instancetype)initWithObligation:(NXHeartbeatAPIResponse *)heartbeatResponse;
@end
