//
//  NXDropDownMenu.m
//  NXDropDownMenuExample
//
//  Created by EShi on 6/30/15.
//  Copyright (c) 2015 EShi. All rights reserved.
//

#import "NXDropDownMenu.h"
#import  <QuartzCore/QuartzCore.h>

const CGFloat kArrowSize = 12.f;
@interface NXDropDownMenuView : UIView
- (void) dismissMenu:(BOOL) animation;
- (void) showMenuInView:(UIView *)view fromRect:(CGRect)rect menuItems:(NSArray *)menuItems;
@end

#pragma mark ///////////NXDropDownMenuOverlay/////////////////////////////////
@interface NXDropDownMenuOverlay : UIView
@end

@implementation NXDropDownMenuOverlay
- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UIView *touched = [[touches anyObject] view];
    if (touched == self) {
        for (UIView *v in self.subviews) {
            if ([v isKindOfClass:[NXDropDownMenuView class]] && [v respondsToSelector:@selector(dismissMenu:)]) {
                [v performSelector:@selector(dismissMenu:) withObject:@(YES)];
            }
        }
    }
}
@end
#pragma mark ///////////NXDropDownMenuView//////////////////////
typedef enum {
    
    NXMenuViewArrowDirectionNone,
    NXMenuViewArrowDirectionUp,
    NXMenuViewArrowDirectionDown,
    NXMenuViewArrowDirectionLeft,
    NXMenuViewArrowDirectionRight,
    
} NXMenuViewArrowDirection;



@interface NXDropDownMenuView()
@property(nonatomic) NXMenuViewArrowDirection arrowDirection;
@property(nonatomic) CGFloat arrowPosition;
@property(nonatomic, strong) UIView *contentView;
@property(nonatomic, strong) NSArray * menuItems;
@end

@implementation NXDropDownMenuView

- (instancetype)init
{
    self = [super initWithFrame:CGRectZero];
    
    // make menu view have shadow and backgroundColor transparent
    if(self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.opaque = YES;
        self.alpha = 0;
        
        self.layer.shadowOpacity = 0.5;
        self.layer.shadowOffset = CGSizeMake(2, 2);
        self.layer.shadowRadius = 2;
    }
    
    return self;
}

- (void) showMenuInView:(UIView *)view fromRect:(CGRect)rect menuItems:(NSArray *)menuItems
{
    _menuItems = menuItems;
    
    // step1. make content view
    _contentView = [self mkContentView];
    [self addSubview:_contentView];
    
    // step2. position the content view in menu view and position the drop down menu view in super view
    [self setupFrameInView:view fromRect:rect];
    
    // step3. add overlay to cover the super view to response to touch event
    NXDropDownMenuOverlay *overlay = [[NXDropDownMenuOverlay alloc]initWithFrame:view.bounds];
    [overlay addSubview:self];
    [view addSubview:overlay];
    
    // step4. Do animation to show drop down menu
    _contentView.hidden = YES;
    const CGRect toFrame = self.frame;
    self.frame = (CGRect){[self arrowPoint], 1, 1};
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1.0f;
        self.frame = toFrame;
    } completion:^(BOOL finished) {
        _contentView.hidden = NO;
    }];
}

- (CGPoint) arrowPoint
{
    CGPoint point = CGPointZero;
    if (_arrowDirection == NXMenuViewArrowDirectionUp) {
        point = (CGPoint){CGRectGetMinX(self.frame) + _arrowPosition, CGRectGetMinY(self.frame)};
    }else if(_arrowDirection == NXMenuViewArrowDirectionDown){
        point = (CGPoint){CGRectGetMinX(self.frame) + _arrowPosition, CGRectGetMaxY(self.frame)};
    }else if(_arrowDirection == NXMenuViewArrowDirectionLeft){
        point = (CGPoint){CGRectGetMinX(self.frame), CGRectGetMinY(self.frame) + _arrowPosition};
    }else if(_arrowDirection == NXMenuViewArrowDirectionRight){
        point = (CGPoint){CGRectGetMaxX(self.frame), CGRectGetMinY(self.frame) + _arrowPosition};
    }
    return point;
}

- (UIView *) mkContentView
{
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    
    if (!_menuItems.count) {
        return nil;
    }
    
    const CGFloat kMinMenuItemHeight = 32.f;
    const CGFloat kMinMenuItemWidth = 32.f;
    const CGFloat kMarginX = 10.f;
    const CGFloat kMarginY = 5.f;
    
    UIFont *titleFont = [NXDropDownMenu titleFont];
    if (!titleFont) {
        titleFont = [UIFont boldSystemFontOfSize:16];
    }
    
    CGFloat maxImageWidth = 0;
    CGFloat maxItemHeight = 0;
    CGFloat maxItemWidth = 0;
    
    // find the largest width size of item image
    for (NXDropDownMenuItem *menuItem in _menuItems) {
        const CGSize imageSize = menuItem.image.size;
        if (imageSize.width > maxImageWidth) {
            maxImageWidth = imageSize.width;
        }
    }
    
    // find the max width and height for menu item
    for (NXDropDownMenuItem *menuItem in _menuItems) {
        const CGSize titleSize = [menuItem.title sizeWithAttributes:@{NSFontAttributeName : titleFont}];
        const CGSize imageSize = menuItem.image.size;
        
        const CGFloat itemHeight = MAX(titleSize.height, imageSize.height) + kMarginY * 2;
        const CGFloat itemWidth = (menuItem.image ? maxImageWidth + kMarginX : 0) + titleSize.width + kMarginX * 4;
        
        if (itemHeight > maxItemHeight) {
            maxItemHeight = itemHeight;
        }
        
        if (itemWidth > maxItemWidth) {
            maxItemWidth = itemWidth;
        }
    }
    
    maxItemWidth = MAX(maxItemWidth, kMinMenuItemWidth);
    maxItemHeight = MAX(maxItemHeight, kMinMenuItemHeight);
    
    const CGFloat titleX = kMarginX * 2 + (maxImageWidth > 0 ? maxImageWidth + kMarginX : 0);
    const CGFloat titleWidth = maxItemWidth - titleX - kMarginX;
    
    // get back ground image when buttom itme pressed
    UIImage *selectedImage = [NXDropDownMenuView selectedImage:(CGSize){maxItemWidth, maxItemHeight + 2}];
    // get gradientLine Image
    UIImage *gradientLine = [NXDropDownMenuView gradientLine:(CGSize){maxItemWidth - kMarginX*4, 1}];
    
    // The content view to store all menu items
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectZero];
    contentView.autoresizingMask = UIViewAutoresizingNone;
    contentView.backgroundColor = [UIColor clearColor];
    
    CGFloat itemY = kMarginY * 2;
    NSUInteger itemNum = 0;
    
    for (NXDropDownMenuItem *menuItem in _menuItems) {
        
        const CGRect itemFrame = (CGRect){0, itemY, maxItemWidth, maxItemHeight};
        
        UIView *itemView = [[UIView alloc] initWithFrame:itemFrame];
        itemView.autoresizingMask = UIViewAutoresizingNone;
        itemView.backgroundColor = [UIColor clearColor];
        itemView.opaque = NO;
        
        [contentView addSubview:itemView];
        // add button
        if (menuItem.enabled) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = itemNum;
            button.frame = itemView.bounds;
            button.enabled = menuItem.enabled;
            button.backgroundColor = [UIColor clearColor];
            button.opaque = NO;
            button.autoresizingMask = UIViewAutoresizingNone;
            
            [button addTarget:self
                       action:@selector(performAction:)
             forControlEvents:UIControlEventTouchUpInside];
            
            [button setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
            
            [itemView addSubview:button];
            
        }
        // add button title label
        if (menuItem.title.length) {
            CGRect titleFrame;
            
            // no enable and no image
            if (!menuItem.enabled && !menuItem.image) {
                titleFrame = (CGRect){kMarginX*2, kMarginY, maxItemWidth - kMarginX * 4, maxItemHeight - kMarginY*2};
            
            }else
            {
                titleFrame = (CGRect){titleX, kMarginY, titleWidth, maxItemHeight - kMarginY * 2};
            }
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleFrame];
            titleLabel.text = menuItem.title;
            titleLabel.font = titleFont;
            titleLabel.textAlignment = menuItem.alignment;
            titleLabel.textColor = menuItem.foreColor ? menuItem.foreColor : [UIColor whiteColor];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.autoresizingMask = UIViewAutoresizingNone;
            [itemView addSubview:titleLabel];
        }
        
        if (menuItem.image) {
            const CGRect imageFrame = {kMarginX * 2, kMarginY, maxImageWidth, maxItemHeight - kMarginY * 2};
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageFrame];
            imageView.image = menuItem.image;
            imageView.clipsToBounds = YES;
            imageView.contentMode = UIViewContentModeCenter;
            imageView.autoresizingMask = UIViewAutoresizingNone;
            
            //change image color
            UIImage *newImage = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIGraphicsBeginImageContextWithOptions(menuItem.image.size, NO, newImage.scale);
            [menuItem.foreColor set];
            [newImage drawInRect:CGRectMake(0, 0, menuItem.image.size.width, newImage.size.height)];
            newImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            imageView.image = newImage;
            
            [itemView addSubview:imageView];
        }
        
        if (itemNum < _menuItems.count - 1) {
            UIImageView *gradientView = [[UIImageView alloc] initWithImage:gradientLine];
            gradientView.frame = (CGRect){kMarginX * 2, maxItemHeight + 1, gradientLine.size};
            gradientView.contentMode = UIViewContentModeLeft;
            [itemView addSubview:gradientView];
            
            itemY += 2;
        }
        
        itemY += maxItemHeight;
        ++itemNum;
    }
    
    contentView.frame = (CGRect){0, 0, maxItemWidth, itemY + kMarginY * 2};
    return contentView;
    
}

- (void) setupFrameInView:(UIView *)view
                 fromRect:(CGRect)fromRect
{
    const CGSize contentSize = _contentView.frame.size;
    const CGFloat outerWidth = view.bounds.size.width;
    const CGFloat outerHeight = view.bounds.size.height;
    
    const CGFloat rectX0 = fromRect.origin.x;
    const CGFloat rectX1 = fromRect.origin.x + fromRect.size.width;
    const CGFloat rectXM = fromRect.origin.x + fromRect.size.width * 0.5;
    
    const CGFloat rectY0 = fromRect.origin.y;
    const CGFloat rectY1 = fromRect.origin.y + fromRect.size.height;
    const CGFloat rectYM = fromRect.origin.y + fromRect.size.height * 0.5;
    
    const CGFloat widthPlusArrow = contentSize.width + kArrowSize;
    const CGFloat heightPlusArrow = contentSize.height + kArrowSize;
    const CGFloat widthHalf = contentSize.width * 0.5f;
    const CGFloat heightHalf = contentSize.height * 0.5f;
    
    const CGFloat kMargin = 5.f;
    
    // arrow up
    if (heightPlusArrow < (outerHeight - rectY1)) {
        
        _arrowDirection = NXMenuViewArrowDirectionUp;
        
        // step1. the menuview origin point in super view
        CGPoint point = (CGPoint){rectXM - widthHalf, rectY1};
        
        if (point.x < kMargin) {
            point.x = kMargin;
        }
        
        if (point.x + kMargin + contentSize.width > outerWidth) {
            point.x = outerWidth - kMargin - contentSize.width;
        }
        
        // step2. arrowPosition
        _arrowPosition = rectXM - point.x;
        
        // step3. set contentview frame in menu view
        _contentView.frame = (CGRect){0, kArrowSize, contentSize};
        
        // step4. the menuview frame in super view
        self.frame = (CGRect){point, contentSize.width, contentSize.height + kArrowSize};
        
    }else if (heightPlusArrow < rectY0) // arrow down
    {
        _arrowDirection = NXMenuViewArrowDirectionDown;
        
        CGPoint point = (CGPoint){rectXM - widthHalf, rectY0};
        if (point.x < kMargin) {
            point.x = kMargin;
        }
        
        if (point.x + kMargin + contentSize.width > outerWidth) {
            point.x = outerWidth - kMargin - contentSize.width;
        }
        
        _arrowPosition = rectXM - point.x;
        
        _contentView.frame = (CGRect){CGPointZero, contentSize};
        
        self.frame = (CGRect){point, contentSize.width, contentSize.height + kArrowSize};

    }else if (widthPlusArrow < rectX0) // arrow right
    {
        _arrowDirection = NXMenuViewArrowDirectionRight;
        CGPoint point = (CGPoint){rectX0 - widthPlusArrow, rectYM - heightHalf};
        
        if (point.y < kMargin) {
            point.y = kMargin;
        }
        
        if ((point.y + kMargin + contentSize.height) > outerHeight) {
            point.y = outerHeight - kMargin - contentSize.height;
        }
        
        _arrowPosition = rectYM - point.y;
        
        _contentView.frame = (CGRect){CGPointZero, contentSize};
        
        self.frame = (CGRect){
            point,
            contentSize.width + kArrowSize,
            contentSize.height
        };
        
    }else if (widthPlusArrow < (outerWidth - rectX1)) // arrow left
    {
        _arrowDirection = NXMenuViewArrowDirectionLeft;
        
        CGPoint point = (CGPoint){rectX1, rectYM - heightHalf};
        
        if (point.y < kMargin) {
            point.y = kMargin;
        }
        
        if ((point.y + kMargin + contentSize.height) > outerHeight) {
            point.y = outerHeight - kMargin - contentSize.height;
        }
        
        _arrowPosition = rectYM - point.y;
        
        _contentView.frame = (CGRect){kArrowSize, 0, contentSize};
        
        self.frame = (CGRect){
            point,
            contentSize.width + kArrowSize,
            contentSize.height
        };
        
    }else  // none arrow
    {
        _arrowDirection = NXMenuViewArrowDirectionNone;
        self.frame = (CGRect){
            (outerWidth - contentSize.width) * 0.5f,
            (outerHeight - contentSize.height) * 0.5f,
            contentSize
        };
    }
}

- (void) dismissMenu:(BOOL)animation
{
    if (self.superview) {
        if (animation) {
            _contentView.hidden = YES;
            const CGRect toFrame = (CGRect){[self arrowPoint], 1, 1};
            
            [UIView animateWithDuration:0.2 animations:^{
                self.alpha = 0;
                self.frame = toFrame;
            } completion:^(BOOL finished) {
                if ([self.superview isKindOfClass:[NXDropDownMenuOverlay class]]) {
                    [self.superview removeFromSuperview];
                }
                [self removeFromSuperview];
            }];
        }else
        {
            if ([self.superview isKindOfClass:[NXDropDownMenuOverlay class]]) {
                [self.superview removeFromSuperview];
            }
            [self removeFromSuperview];
        }
    }
}

- (void) performAction:(id) sender
{
    [self dismissMenu:YES];
    UIButton *button = (UIButton *)sender;
    NXDropDownMenuItem *menuItem = _menuItems[button.tag];
    [menuItem performAction];
}
+ (UIImage *) selectedImage: (CGSize) size
{
    const CGFloat locations[] = {0,1};
    const CGFloat components[] = {
        0.216, 0.471, 0.871, 1,
        0.059, 0.353, 0.839, 1,
    };
    
    return [self gradientImageWithSize:size locations:locations components:components count:2];

}

+ (UIImage *) gradientLine: (CGSize) size
{
    const CGFloat locations[5] = {0,0.2,0.5,0.8,1};
    
    const CGFloat R = 0.44f, G = 0.44f, B = 0.44f;
    
    const CGFloat components[20] = {
        R,G,B,0.1,
        R,G,B,0.4,
        R,G,B,0.7,
        R,G,B,0.4,
        R,G,B,0.1
    };
    
    return [self gradientImageWithSize:size locations:locations components:components count:5];
}

+ (UIImage *) gradientImageWithSize:(CGSize) size
                          locations:(const CGFloat []) locations
                         components:(const CGFloat []) components
                              count:(NSUInteger)count
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef colorGradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawLinearGradient(context, colorGradient, (CGPoint){0, 0}, (CGPoint){size.width, 0}, 0);
    CGGradientRelease(colorGradient);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void) drawRect:(CGRect)rect
{
    [self drawBackground:rect inContext:UIGraphicsGetCurrentContext()];
}

- (void) drawBackground:(CGRect) frame inContext:(CGContextRef) context
{
    CGFloat R0 = 1.0, G0 = 1.0, B0 = 1.0;
    CGFloat R1 = 1.0, G1 = 1.0, B1 = 1.0;
    
    UIColor *tintColor = [NXDropDownMenu tintColor];
    if (tintColor) {
        
        CGFloat a;
        [tintColor getRed:&R0 green:&G0 blue:&B0 alpha:&a];
    }
    
    CGFloat X0 = frame.origin.x;
    CGFloat X1 = frame.origin.x + frame.size.width;
    CGFloat Y0 = frame.origin.y;
    CGFloat Y1 = frame.origin.y + frame.size.height;
    
    // render arrow
    
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    
    // fix the issue with gap of arrow's base if on the edge
    const CGFloat kEmbedFix = 3.f;
    
    if (_arrowDirection == NXMenuViewArrowDirectionUp) {
        
        const CGFloat arrowXM = _arrowPosition;
        const CGFloat arrowX0 = arrowXM - kArrowSize;
        const CGFloat arrowX1 = arrowXM + kArrowSize;
        const CGFloat arrowY0 = Y0;
        const CGFloat arrowY1 = Y0 + kArrowSize + kEmbedFix;
        
        [arrowPath moveToPoint:    (CGPoint){arrowXM, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowXM, arrowY0}];
        
        [[UIColor colorWithRed:R0 green:G0 blue:B0 alpha:1] set];
        
        Y0 += kArrowSize;
        
    } else if (_arrowDirection == NXMenuViewArrowDirectionDown) {
        
        const CGFloat arrowXM = _arrowPosition;
        const CGFloat arrowX0 = arrowXM - kArrowSize;
        const CGFloat arrowX1 = arrowXM + kArrowSize;
        const CGFloat arrowY0 = Y1 - kArrowSize - kEmbedFix;
        const CGFloat arrowY1 = Y1;
        
        [arrowPath moveToPoint:    (CGPoint){arrowXM, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowXM, arrowY1}];
        
        [[UIColor colorWithRed:R1 green:G1 blue:B1 alpha:1] set];
        
        Y1 -= kArrowSize;
        
    } else if (_arrowDirection == NXMenuViewArrowDirectionLeft) {
        
        const CGFloat arrowYM = _arrowPosition;
        const CGFloat arrowX0 = X0;
        const CGFloat arrowX1 = X0 + kArrowSize + kEmbedFix;
        const CGFloat arrowY0 = arrowYM - kArrowSize;;
        const CGFloat arrowY1 = arrowYM + kArrowSize;
        
        [arrowPath moveToPoint:    (CGPoint){arrowX0, arrowYM}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowYM}];
        
        [[UIColor colorWithRed:R0 green:G0 blue:B0 alpha:1] set];
        
        X0 += kArrowSize;
        
    } else if (_arrowDirection == NXMenuViewArrowDirectionRight) {
        
        const CGFloat arrowYM = _arrowPosition;
        const CGFloat arrowX0 = X1;
        const CGFloat arrowX1 = X1 - kArrowSize - kEmbedFix;
        const CGFloat arrowY0 = arrowYM - kArrowSize;;
        const CGFloat arrowY1 = arrowYM + kArrowSize;
        
        [arrowPath moveToPoint:    (CGPoint){arrowX0, arrowYM}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY0}];
        [arrowPath addLineToPoint: (CGPoint){arrowX1, arrowY1}];
        [arrowPath addLineToPoint: (CGPoint){arrowX0, arrowYM}];
        
        [[UIColor colorWithRed:R1 green:G1 blue:B1 alpha:1] set];
        
        X1 -= kArrowSize;
    }
    
    [arrowPath fill];
    
    // render body
    
    const CGRect bodyFrame = {X0, Y0, X1 - X0, Y1 - Y0};
    
    UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:bodyFrame
                                                          cornerRadius:8];
    
    const CGFloat locations[] = {0, 1};
    const CGFloat components[] = {
        R0, G0, B0, 1,
        R1, G1, B1, 1,
    };
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace,
                                                                 components,
                                                                 locations,
                                                                 sizeof(locations)/sizeof(locations[0]));
    CGColorSpaceRelease(colorSpace);
    
    
    [borderPath addClip];
    
    CGPoint start, end;
    
    if (_arrowDirection == NXMenuViewArrowDirectionLeft ||
        _arrowDirection == NXMenuViewArrowDirectionRight) {
        
        start = (CGPoint){X0, Y0};
        end = (CGPoint){X1, Y0};
        
    } else {
        
        start = (CGPoint){X0, Y0};
        end = (CGPoint){X0, Y1};
    }
    
    CGContextDrawLinearGradient(context, gradient, start, end, 0);
    
    CGGradientRelease(gradient);
}
@end
#pragma mark ///////////NXDropDownMenu////////////////////

static NXDropDownMenu *gMenu;
static UIColor *gTintColor;
static UIFont *gTitleFont;

@interface NXDropDownMenu()
@property(nonatomic, strong) NXDropDownMenuView *menuView;
@property(nonatomic) BOOL observing;
@end

@implementation NXDropDownMenu
+ (instancetype) sharedMenu
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gMenu = [[NXDropDownMenu alloc] init];
    });
    return gMenu;
}

- (instancetype) init
{
    NSAssert(!gMenu, @"singleton object");
    self = [super init];
    if (self) {
        //do something
    }
    return self;
}

- (void) dealloc
{
    if (_observing) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void) showMenuInView:(UIView *) view
               fromRect:(CGRect) rect
              menuItems:(NSArray*) menuItems
{
    NSParameterAssert(view);
    NSParameterAssert(menuItems.count);
    
    if (_menuView) {
        [_menuView dismissMenu:NO];
        _menuView = nil;
    }
    
    if (!_observing) {
        _observing = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationWillChange:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    
    _menuView = [[NXDropDownMenuView alloc] init];
    [_menuView showMenuInView:view fromRect:rect menuItems:menuItems];
}

- (void) orientationWillChange:(NSNotification *) n
{
    [self dismissMenu];
}
- (void) dismissMenu
{
    if (_menuView) {
        [_menuView dismissMenu:NO];
        _menuView = nil;
    }
    
    if (_observing) {
        _observing = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

+ (void) dismissMenu
{
    [[self sharedMenu] dismissMenu];
}

+ (void) showMenuInView:(UIView *)view fromRect:(CGRect)rect menuItems:(NSArray *)menuItems
{
    [[self sharedMenu] showMenuInView:view fromRect:rect menuItems:menuItems];
}
+ (UIColor *) tintColor
{
    return gTintColor;
}

+ (void) setTintColor: (UIColor *) tintColor
{
    if (tintColor != gTintColor) {
        gTintColor = tintColor;
    }
}

+ (UIFont *) titleFont
{
    return gTitleFont;
}

+ (void) setTitleFont: (UIFont *) titleFont
{
    if (titleFont != gTitleFont) {
        gTitleFont = titleFont;
    }
}
@end

#pragma mark /////////NXDropDownMenuItem////////////////////
@implementation NXDropDownMenuItem
+ (instancetype) menuItem:(NSString *) tilte
                    image:(UIImage *) image
                   target:(id)target
                   action:(SEL) action
{
    return [[NXDropDownMenuItem alloc] init:tilte image:image target:target action:action];
}

- (instancetype) init:(NSString*) title image:(UIImage *) image target:(id) target action:(SEL) action
{
    self = [super init];
    if (self) {
        _title = title;
        _image = image;
        _target = target;
        _action = action;
    }
    
    return self;
}

- (BOOL) enabled
{
    return _target != nil && _action != nil;
}

- (void) performAction
{
    __strong id target = self.target;
    if (target && [target respondsToSelector:_action]) {
        [target performSelectorOnMainThread:_action withObject:self waitUntilDone:YES];
    }
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@ #%p %@>", [self class], self, _title];
}
@end
