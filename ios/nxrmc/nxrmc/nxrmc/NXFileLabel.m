//
//  NXLabel.m
//  nxrmc
//
//  Created by nextlabs on 7/12/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXFileLabel.h"

@interface NXFileLabel ()
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

@end

@implementation NXFileLabel

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.edgeInsets = UIEdgeInsetsMake(10, 5, 10, 5);
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.edgeInsets)];
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    size.width  += self.edgeInsets.left + self.edgeInsets.right;
    size.height += self.edgeInsets.top + self.edgeInsets.bottom;
    return size;
}

@end
