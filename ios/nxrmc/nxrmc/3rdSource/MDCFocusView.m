//  MDCFocusView.m
//
//  Copyright (c) 2013 modocache
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#define USER_GUID_TITLE 90001
#import "MDCFocusView.h"

#import "MDCFocalPointView.h"
#import "MDCSpotlightView.h"
#import "NXFocusViewPlaceHolder.h"


@interface MDCFocusView ()
@property (nonatomic, strong) NSArray *focii;
@property (nonatomic, assign) BOOL focusViewFocused;
@property(nonatomic, strong) NSMutableArray *guidViews;
@end


@implementation MDCFocusView


#pragma mark - Object Initialization

- (id)init {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    self = [super initWithFrame:keyWindow.frame];
    if (self) {
        _focusDuration = 0.5;
        _focalPointViewClass = [MDCFocalPointView class];

        self.userInteractionEnabled = NO;
        self.opaque = NO;
        self.alpha = 0.0f;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onApplicationDidChangeStatusBarOrientationNotification:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}

-(NSMutableArray *) guidViews
{
    if (_guidViews == nil) {
        _guidViews = [[NSMutableArray alloc] init];
    }
    return _guidViews;
}
#pragma mark - UIView Overrides

- (void)drawRect:(CGRect)rect {
    [[UIColor clearColor] setFill];

    for (UIView *focus in self.focii) {
        UIRectFill(CGRectIntersection(focus.frame, rect));
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (MDCFocalPointView *focus in self.focii) {
        if (CGRectContainsPoint(focus.frame, point)) {
            if ([focus.focalView isKindOfClass:[NXFocusViewPlaceHolder class]]) {
                NXFocusViewPlaceHolder * phV = (NXFocusViewPlaceHolder *) focus.focalView;
                if (phV.holderBlock) {
                    phV.holderBlock();
                    return nil;
                }else
                {
                    return phV.holderView;
                }
            }
            return focus.focalView;
        }
        
    }

    return self.focusViewFocused ? self : nil;
}


#pragma mark - Public Interface

- (void)focus:(UIView *)views, ... {
    NSMutableArray *focii = [NSMutableArray new];

    va_list viewList;
    va_start(viewList, views);
    for (UIView *view = views; view != nil; view = va_arg(viewList, UIView *)) {
        [focii addObject:view];
    }
    va_end(viewList);

    [self focusOnViews:[focii copy]];
}

- (void)focusOnViews:(NSArray *)views {
    NSParameterAssert(views != nil);

    self.focusViewFocused = YES;

    [[UIApplication sharedApplication].keyWindow addSubview:self];
    [self adjustRotation];

    NSMutableArray *focii = [NSMutableArray arrayWithCapacity:[views count]];

    for (UIView *view in views) {
        MDCFocalPointView *focalPointView = [[self.focalPointViewClass alloc] initWithFocalView:view];
        [self addSubview:focalPointView];
        focalPointView.frame = [self convertRect:focalPointView.frame
                                        fromView:focalPointView.focalView.superview];
        CGRect labelFrame = CGRectZero;
        if (self.userGuidTitle) {
            switch (self.userGuidTitle.orientation) {
                case kUserGuidViewOrientUp:
                {
                    labelFrame = CGRectMake(focalPointView.frame.origin.x + focalPointView.frame.size.width / 2, focalPointView.frame.origin.y - focalPointView.frame.size.height / 2 - 20, 200, 300);
                }
                    break;
                case kUserGuidViewOrientDown:
                {
                    labelFrame = CGRectMake(focalPointView.frame.origin.x + focalPointView.frame.size.width / 2, focalPointView.frame.origin.y + focalPointView.frame.size.height / 2  + 20, 200, 300);
                }
                    break;
                case kUserGuidViewOrientLeft:
                {
                    labelFrame = CGRectMake(focalPointView.frame.origin.x - focalPointView.frame.size.width / 2 - 10, focalPointView.frame.origin.y + 20, 200, 300);
                }
                    break;
                case kUserGuidViewOrientRight:
                {
                    labelFrame = CGRectMake(focalPointView.frame.origin.x + focalPointView.frame.size.width / 2 + 10, focalPointView.frame.origin.y + 20, 200, 300);
                }
                    break;
                default:
                    break;
            }
            UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
            label.numberOfLines = 0;
            label.font = [UIFont boldSystemFontOfSize:16.0f];
            label.shadowColor = [UIColor grayColor];
            label.shadowOffset = CGSizeMake(0, 1);
            label.tag = USER_GUID_TITLE;
            label.text = self.userGuidTitle.title;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = [UIColor clearColor];
            if ([self viewWithTag:USER_GUID_TITLE]) {
                [[self viewWithTag:USER_GUID_TITLE] removeFromSuperview];
            }
            [self addSubview:label];
        }
        
        [focii addObject:focalPointView];
    }

    self.focii = [focii copy];
    [self setNeedsDisplay];

    [UIView animateWithDuration:self.focusDuration animations:^{
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        self.userInteractionEnabled = YES;
    }];
}

- (void)dismiss:(void (^)())completion {
    NSAssert(self.focusViewFocused, @"Cannot dismiss when focus is not applied in the first place.");

    [UIView animateWithDuration:self.focusDuration animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        for (MDCFocalPointView *view in self.focii) {
            [view removeFromSuperview];
        }
        self.focii = nil;

        self.userInteractionEnabled = NO;
        [self removeFromSuperview];

        self.focusViewFocused = NO;

        if (completion) {
            completion();
        }
    }];
}

- (void) addGuidView:(UIView *) guidView
{
    [self.guidViews addObject:guidView];
    [self addSubview:guidView];

}

#pragma mark - Internal Methods

- (void)onApplicationDidChangeStatusBarOrientationNotification:(NSNotification *)notification {
    if (!self.focusViewFocused) {
        return;
    }

    NSMutableArray *views = [NSMutableArray new];
    for (MDCFocalPointView *focalPointView in self.focii) {
        [views addObject:focalPointView.focalView];
    }

    [self dismiss:^{
        [self adjustRotation];
        [self focusOnViews:[views copy]];
    }];
}

- (void)adjustRotation {
//    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
//
//    CGFloat rotationAngle = 0.0f;
//    switch (orientation) {
//        case UIInterfaceOrientationPortrait:
//            rotationAngle = 0.0f;
//            break;
//        case UIInterfaceOrientationPortraitUpsideDown:
//            rotationAngle = M_PI;
//            break;
//        case UIInterfaceOrientationLandscapeLeft:
//            rotationAngle = -M_PI/2.0f;
//            break;
//        case UIInterfaceOrientationLandscapeRight:
//            rotationAngle = M_PI/2.0f;
//            break;
//    }

  //  self.transform = CGAffineTransformMakeRotation(rotationAngle);
    self.frame = self.superview.frame;
}

@end
