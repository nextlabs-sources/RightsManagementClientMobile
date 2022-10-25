//
//  NXCustomTextView.h
//  AdhocTest
//
//  Created by nextlabs on 6/14/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NXCustomTextView : UITextView

@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, strong) UIFont* placeholderFont;
@property(nonatomic, strong) UIColor* placeholderColor;

@end
