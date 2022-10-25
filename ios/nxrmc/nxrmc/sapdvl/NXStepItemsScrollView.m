//
//  NXStepItemsScrollView.m
//  scrollviewtest
//
//  Created by nextlabs on 9/16/15.
//  Copyright (c) 2015 zhuimengfuyun. All rights reserved.
//

#import "NXStepItemsScrollView.h"
#import "NXStepItemView.h"


CGFloat kStepItemSpace = 5;
CGFloat kStepItemWidth = 50;
CGFloat kButtonScrollViewSpace = 30;

@interface NXStepItemsScrollView()<NXStepItemDelegate, UIGestureRecognizerDelegate>

@property (strong ,nonatomic) NSMutableArray *stepItems;
@property (assign, nonatomic) NSInteger currentItem;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation NXStepItemsScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (instancetype) stepItemsScrollView {
    NXStepItemsScrollView *view = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:self options:nil] lastObject];
    view.stepItems = [[NSMutableArray alloc] init];
    view.scrollView.showsHorizontalScrollIndicator = NO;
    return view;
}

- (void)addStepItem:(NSNumber *) tag image:(UIImage *)image; {
    NXStepItemView *stepItemView = [NXStepItemView initWithImage:image];
    stepItemView.deletage = self;
    stepItemView.tag = [tag integerValue];
    [stepItemView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.scrollView addSubview:stepItemView];
    
    UIView * previousPageView;
    
    if (self.stepItems.count > 0) {
        previousPageView = self.stepItems[self.stepItems.count - 1];
    }
    
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:stepItemView
                                                                      attribute:NSLayoutAttributeTop
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.scrollView
                                                                      attribute:NSLayoutAttributeTop
                                                                     multiplier:1
                                                                       constant:0];
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:stepItemView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.scrollView
                                                                         attribute:NSLayoutAttributeHeight
                                                                        multiplier:1
                                                                          constant:0];
    
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:stepItemView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1
                                                                        constant:kStepItemWidth];
    NSLayoutConstraint * leftConstraint;
    
    if (previousPageView) {
        leftConstraint = [NSLayoutConstraint constraintWithItem:stepItemView
                                                      attribute:NSLayoutAttributeLeft
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:previousPageView
                                                      attribute:NSLayoutAttributeRight
                                                     multiplier:1
                                                       constant:kStepItemSpace];
    } else {
        leftConstraint = [NSLayoutConstraint constraintWithItem:stepItemView
                                                      attribute:NSLayoutAttributeLeft
                                                      relatedBy:NSLayoutRelationEqual
                                                         toItem:self.scrollView
                                                      attribute:NSLayoutAttributeLeft
                                                     multiplier:1
                                                       constant:0];
    }
    
    [self.scrollView addConstraints:@[topConstraint, leftConstraint, widthConstraint, heightConstraint]];
    
    //suport scroll for drnamic add item.
    [self layoutSubviews];
    
    [self.stepItems addObject:stepItemView];
}

- (NSInteger) stepItemCount {
    return self.stepItems.count;
}

- (void) layoutSubviews {
//    if (self.scrollView.contentSize.width != (kStepItemSpace + kStepItemWidth) * self.stepItems.count)
    {
        [self.scrollView setContentSize:CGSizeMake((kStepItemSpace + kStepItemWidth) * self.stepItems.count, self.scrollView.contentSize.height)];
    }
    
    [super layoutSubviews];
}

- (IBAction)leftButtonClicked:(id)sender {
    if (self.stepItems.count == 0) {
        return;
    }
    if (self.currentItem > 0) {
        [self.stepItems[self.currentItem] setSelected:NO];
        self.currentItem--;
        [self.stepItems[self.currentItem] setSelected:YES];
    }
    
}

- (IBAction)rightButtonClicked:(id)sender {
    if (self.stepItems.count == 0) {
        return;
    }
    if (self.currentItem < self.stepItems.count - 1) {
        [self.stepItems[self.currentItem] setSelected:NO];
        self.currentItem++;
        [self.stepItems[self.currentItem] setSelected:YES];
    }
}

- (void) nxStepItemDidClicked:(NXStepItemView *)stepItem state:(BOOL)isSelected {
    if (isSelected) {
        for (int i = 0; i < self.stepItems.count; ++i) {
            NXStepItemView *v = self.stepItems[i];
            if (v.tag == stepItem.tag) {
                self.currentItem = i;
            } else {
                [v setSelected:NO];
            }
        }
        CGFloat offsetPositinoX = self.scrollView.contentOffset.x;
        
        CGFloat rightorigin = CGRectGetMaxX(stepItem.frame);
        
        if (rightorigin - offsetPositinoX > self.scrollView.bounds.size.width) {
            [self.scrollView setContentOffset:CGPointMake(CGRectGetMaxX(stepItem.frame) - CGRectGetWidth(self.scrollView.frame), self.scrollView.contentOffset.y)];
        }
        
        if (rightorigin - offsetPositinoX < stepItem.frame.size.width) {
            [self.scrollView setContentOffset:CGPointMake(CGRectGetMinX(stepItem.frame), self.scrollView.contentOffset.y)];
        }
        
        
        if (_delegate && [_delegate respondsToSelector:@selector(nxStepItemScrollView:didStepItemChanged:)]) {
            [_delegate nxStepItemScrollView:self didStepItemChanged:stepItem];
        }
    }
}

- (void) dealloc {
    
}

@end
