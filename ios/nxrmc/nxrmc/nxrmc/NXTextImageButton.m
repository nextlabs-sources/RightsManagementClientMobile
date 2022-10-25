//
//  TextImageButton.m
//  HomePageAndView
//
//  Created by ShiTeng on 15/5/5.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXTextImageButton.h"

#define BUTTON_IMAGE_HEIGHT (22)
#define BUTTON_DEFAUTLE_TITLE (@"Button")

#define BUTTON_INSET_LEFT (40)

@implementation NXTextImageButton

-(instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.imageView.contentMode = UIViewContentModeLeft;
    }
    return self;
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        self.titleLabel.textAlignment = NSTextAlignmentRight;
        self.imageView.contentMode = UIViewContentModeLeft;

    }
    return self;
}

-(void) awakeFromNib
{
   // [super awakeFromNib];
    self.titleLabel.textAlignment = NSTextAlignmentRight;
    // self.titleLabel.textColor = self.tintColor;
    self.imageView.contentMode = UIViewContentModeLeft;
}

-(void)setTitle:(NSString *)title forState:(UIControlState)state
{
    CATransition *animation = [CATransition animation];
    animation.type = @"cube";
    [self.layer addAnimation:animation forKey:nil];
    
    [super setTitle:title forState:state];
}

#pragma -mark Overwrite parents method
-(CGRect) titleRectForContentRect:(CGRect)contentRect
{
    NSString *titleText = [super titleForState:UIControlStateNormal];
    if([titleText isEqualToString:BUTTON_DEFAUTLE_TITLE])
    {
        return [super titleRectForContentRect:contentRect];
    }
    else
    {
        CGSize size = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.titleLabel.font, NSFontAttributeName, nil]];
        CGFloat maxWidth = self.superview.frame.size.width - BUTTON_INSET_LEFT * 2;
        if(size.width > maxWidth)
        {
            size = CGSizeMake(maxWidth, size.height);
        }
        CGFloat titleX = (self.frame.size.width - size.width - BUTTON_IMAGE_HEIGHT) / 2;
        CGFloat titleW = size.width;
        CGFloat titleH = self.frame.size.height;
        CGFloat titleY = 0;
        return (CGRect){{titleX, titleY}, {titleW, titleH}};
    }
}

-(CGRect) imageRectForContentRect:(CGRect)contentRect
{
    NSString *titleText = [super titleForState:UIControlStateNormal];
    if([titleText isEqualToString:BUTTON_DEFAUTLE_TITLE] || ![super imageForState:UIControlStateNormal])
    {
        return [super titleRectForContentRect:contentRect];
    }
    else
    {
        CGSize size = [titleText sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:self.titleLabel.font, NSFontAttributeName, nil]];
        CGFloat maxWidth = self.superview.frame.size.width - BUTTON_INSET_LEFT * 2;
        if(size.width > maxWidth)
        {
            size = CGSizeMake(maxWidth, size.height);
        }
        CGFloat imageX = (self.frame.size.width - size.width - BUTTON_IMAGE_HEIGHT) / 2 + size.width;
        CGFloat imageW = BUTTON_IMAGE_HEIGHT;
        CGFloat imageH = self.frame.size.height;
        CGFloat imageY = 0;
        return (CGRect){{imageX, imageY}, {imageW, imageH}};
    }
}
@end
