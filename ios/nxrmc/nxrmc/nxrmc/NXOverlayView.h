//
//  NXOverlayView.h
//  nxrmc
//
//  Created by nextlabs on 7/20/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXOverlayTextInfo.h"

@interface NXOverlayView : UIView

- (instancetype) initWithFrame:(CGRect)frame Obligation:(NXOverlayTextInfo *)obligation;

@end
