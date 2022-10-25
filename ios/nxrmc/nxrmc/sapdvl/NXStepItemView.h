//
//  NXStepItemView.h
//  scrollviewtest
//
//  Created by nextlabs on 9/16/15.
//  Copyright (c) 2015 zhuimengfuyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NXStepItemDelegate;

@interface NXStepItemView : UIView

@property (weak, nonatomic) id<NXStepItemDelegate> deletage;

+ (instancetype) initWithImage:(UIImage *) image;
- (void) setSelected:(BOOL) selected;

@end

@protocol NXStepItemDelegate <NSObject>

@optional
- (void) nxStepItemDidClicked:(NXStepItemView *) stepItem state:(BOOL) isSelected;

@end