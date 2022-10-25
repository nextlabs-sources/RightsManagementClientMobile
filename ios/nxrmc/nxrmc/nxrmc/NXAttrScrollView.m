//
//  NXScrollView.m
//  nxrmc
//
//  Created by helpdesk on 22/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXAttrScrollView.h"

@interface NXAttrScrollView ()

@property (nonatomic, strong)NSMutableArray * pageViews;

@property (nonatomic, assign)NSInteger previousPage;

@end


@implementation NXAttrScrollView

- (void)addPageView:(UIView*)pageView
{
    [pageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:pageView];
    
    UIView * previousPageView;
    
    if (self.pageViews.count > 0) {
        previousPageView = self.pageViews[self.pageViews.count - 1];
    }
    
    NSLayoutConstraint * topConstraint = [NSLayoutConstraint constraintWithItem:pageView
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1
                                                                       constant:0];
    NSLayoutConstraint * widthConstraint = [NSLayoutConstraint constraintWithItem:pageView
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeWidth
                                                                       multiplier:1
                                                                         constant:0];
    NSLayoutConstraint * heightConstraint = [NSLayoutConstraint constraintWithItem:pageView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1
                                                                          constant:0];
    NSLayoutConstraint * leftConstraint;
    
    if (previousPageView) {
        leftConstraint = [NSLayoutConstraint constraintWithItem:pageView
                                                      attribute:NSLayoutAttributeLeft
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:previousPageView
                                                      attribute:NSLayoutAttributeRight
                                                     multiplier:1
                                                       constant:0];
    } else {
        leftConstraint = [NSLayoutConstraint constraintWithItem:pageView
                                                      attribute:NSLayoutAttributeLeft
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self
                                                      attribute:NSLayoutAttributeLeft
                                                     multiplier:1
                                                       constant:0];
    }
    
    [self addConstraints:@[topConstraint, leftConstraint, widthConstraint, heightConstraint]];
    
    [self.pageViews addObject:pageView];
}

- (void)layoutSubviews {
    if (self.contentSize.width != self.frame.size.width * self.pageViews.count) {
        [self setContentSize:CGSizeMake(self.frame.size.width * self.pageViews.count, self.contentSize.height)];
        [self setContentOffset:CGPointMake(self.frame.size.width * self.previousPage, self.contentOffset.y)];
    } else {
        self.previousPage = [self currentPage];
    }
    if (self.contentSize.height != self.frame.size.height) {
        [self setContentSize:CGSizeMake(self.contentSize.width, self.frame.size.height)];
    }
    
    [super layoutSubviews];
}


#pragma mark private method
- (NSInteger)currentPage
{
    NSInteger currentPage = self.contentOffset.x / self.frame.size.width;
    return currentPage;
}

- (NSMutableArray*)pageViews
{
    if(_pageViews == nil)
    {
        _pageViews = [NSMutableArray array];
    }
    return _pageViews;
}
@end
