//
//  NXOverlayView.m
//  nxrmc
//
//  Created by nextlabs on 7/20/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXOverlayView.h"
#import "NXCommonUtils.h"

#define HORIZONTAL_SPACE_PIXEL          10  // horizontal space between two label, 10 pixel.
#define VERTICAL_DUPLICATE_FONTHEIGHT   10   // vertial space between two label, 10 pixel

#define  DEFAULTROTATIONANGLE  M_PI_4   //default rotatioin angle.

@interface NXOverlayView()
{
    NSString *_displayText;
    CGFloat _transparency;  // 0.0 ~ 1.0
    UIFont *_font;          // contents fontSize and FontName.
    UIColor *_textColor;
    CGFloat _rotation;
    CGSize _labelSize;
    CGSize _rotationSize;
    BOOL _clockRotation;
}

@end

@implementation NXOverlayView

- (instancetype)initWithFrame:(CGRect)frame Obligation:(NXOverlayTextInfo *)overlaytextInfo{
    if (self = [super initWithFrame:frame]) {
        _rotation = DEFAULTROTATIONANGLE;
        [self initProperty:overlaytextInfo];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _rotation = DEFAULTROTATIONANGLE;
        NXOverlayTextInfo *info = [[NXOverlayTextInfo alloc] init];
        [self initProperty:info];
    }
    return self;
}

#pragma mark

- (void)initProperty:(NXOverlayTextInfo *) obligation {
    _displayText = obligation.text;
    _transparency = 1 - [obligation.transparency floatValue]/100;
    _font = obligation.font;
    _textColor = obligation.textColor;
    _clockRotation = obligation.isclockwiserotation;
    _labelSize = [self calculateLabelSize:_displayText];
    _rotationSize = [self caculateRotationSize:_labelSize];
}

- (CGSize)calculateLabelSize:(NSString *)displayText {
    return [displayText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_font} context:nil].size;
}

- (void)setOverlayLabels {
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    for (CGFloat x = 0; x < (self.bounds.size.width + _rotationSize.width); x += _rotationSize.width + HORIZONTAL_SPACE_PIXEL) {
        for (CGFloat y = 0; y < (self.bounds.size.height + _rotationSize.height); y += _rotationSize.height + VERTICAL_DUPLICATE_FONTHEIGHT) {
            CGRect frame = CGRectMake(x, y, _labelSize.width, _labelSize.height);
            UIView *label = [self generateOverlayLabelwithFrame:frame];
            [self addSubview:label];
        }
    }
}

- (UILabel *)generateOverlayLabelwithFrame:(CGRect)frame {
    CGPoint point = frame.origin;
    
    UILabel *overlayLabel = [[UILabel alloc] initWithFrame:frame];
    overlayLabel.numberOfLines = 0;
    overlayLabel.textAlignment = NSTextAlignmentCenter;

    overlayLabel.text = _displayText;
    overlayLabel.font = _font;
    overlayLabel.textColor = [_textColor colorWithAlphaComponent:_transparency];
    overlayLabel.opaque = NO;
    if (_clockRotation) {
        overlayLabel.transform = CGAffineTransformMakeRotation(_rotation);
    } else {
        overlayLabel.transform = CGAffineTransformMakeRotation(-_rotation);
    }
    overlayLabel.center = CGPointMake(point.x + _rotationSize.width/2, point.y + _rotationSize.height/2);
    
    return overlayLabel;
}

- (CGSize)caculateRotationSize:(CGSize)orginSize {
    CGFloat width = orginSize.width * cosf(_rotation) + orginSize.height * sinf(_rotation);
    CGFloat height = orginSize.width * sinf(_rotation) + orginSize.height * cosf(_rotation);
    return CGSizeMake(width, height);
}

#pragma mark - overwrite UIView method.

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        return nil;
    } else {
        return hitView;
    }
}

- (void)layoutSubviews {
    [self setOverlayLabels];
}

@end
