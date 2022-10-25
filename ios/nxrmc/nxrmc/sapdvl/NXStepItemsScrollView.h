//
//  NXStepItemsScrollView.h
//  scrollviewtest
//
//  Created by nextlabs on 9/16/15.
//  Copyright (c) 2015 zhuimengfuyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXStepItemView.h"

@protocol NXStepItemsScrollViewDelegate;

@interface NXStepItemsScrollView : UIView

@property (weak, nonatomic) id<NXStepItemsScrollViewDelegate> delegate;

+ (instancetype) stepItemsScrollView;
- (void)addStepItem:(NSNumber *)tag image:(UIImage *)image;
- (NSInteger) stepItemCount;
@end

@protocol NXStepItemsScrollViewDelegate <NSObject>

- (void) nxStepItemScrollView:(NXStepItemsScrollView *) scrollView didStepItemChanged:(NXStepItemView *) stepItemView;

@end