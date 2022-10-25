//
//  CLTokenView.h
//  CLTokenInputView
//
//  Created by Rizwan Sattar on 2/24/14.
//  Copyright (c) 2014 Cluster Labs, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#include "NXInputModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CLTokenView;
@protocol CLTokenViewDelegate <NSObject>

@required
- (void)tokenViewDidRequestDelete:(CLTokenView *)tokenView replaceWithText:(nullable NSString *)replacementText;
- (void)tokenViewDidRequestSelection:(CLTokenView *)tokenView;

@end


@interface CLTokenView : UIView <UIKeyInput>

@property (weak, nonatomic, nullable) NSObject <CLTokenViewDelegate> *delegate;
@property (assign, nonatomic) BOOL selected;
@property (assign, nonatomic) BOOL hideUnselectedComma;
@property (copy, nonatomic) NSString *displayText;
@property (strong, nonatomic) NXInputModel *model;
@property (strong, nonatomic) UIFont *font;

- (id)initWithToken:(NXInputModel *)token font:(nullable UIFont *)font;

- (void)setSelected:(BOOL)selected animated:(BOOL)animated;

// For iOS 6 compatibility, provide the setter tintColor
- (void)setTintColor:(nullable UIColor *)tintColor;

@end

NS_ASSUME_NONNULL_END
