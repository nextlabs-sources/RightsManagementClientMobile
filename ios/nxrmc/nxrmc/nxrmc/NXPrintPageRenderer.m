//
//  NXPrintPageRenderer.m
//  PrintWebView
//
//  Created by nextlabs on 7/24/15.
//
//

#import "NXPrintPageRenderer.h"
#import "UIImage+Cutting.h"

#define HORIZONTAL_SPACE_PIXEL          10  // horizontal space between two label, 10 pixel.
#define VERTICAL_DUPLICATE_FONTHEIGHT   6   // vertial space between two label, 6*font.size.height

#define kRotationAngle M_PI_4

@interface NXPrintPageRenderer()

@property (nonatomic, strong) NXOverlayTextInfo *obligation;
@property (nonatomic, strong) UIImage *image;
@end

@implementation NXPrintPageRenderer

- (instancetype)initwithObligation:(NXOverlayTextInfo *)obligation printFormat:(UIPrintFormatter *)printFormatter {
    if ([super init]) {
        _obligation = obligation;
        [self addPrintFormatter:printFormatter startingAtPageAtIndex:0];
    }
    return self;
}

- (instancetype)initWithObligation:(NXOverlayTextInfo *)obligation image:(UIImage *)image {
    if ([super init]) {
        _obligation = obligation;
        _image = image;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"");
}

- (void)drawContentForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)contentRect {
    
    // 1,if print image draw image, if not do nothing
    if (_image) {
        UIImage *image = [self imageCompressWithSimple:_image CGSize:self.printableRect.size];
        [image drawInRect:CGRectMake(CGRectGetMinX(self.printableRect), CGRectGetMinY(self.printableRect), image.size.width, image.size.height)];
    }
    
    //2, draw overlay
    if (self.obligation) {
        CGSize overlaySize = [_obligation.text sizeWithAttributes:@{NSFontAttributeName:_obligation.font}];
        CGSize drawSize = [self caculateRotationSize:CGSizeMake(overlaySize.width, overlaySize.height)];
        for (CGFloat x = 0; x < contentRect.size.width + drawSize.width; x += drawSize.width + HORIZONTAL_SPACE_PIXEL) {
            for (CGFloat y = 0; y < contentRect.size.height + drawSize.height; y += drawSize.height + VERTICAL_DUPLICATE_FONTHEIGHT) {
                [self draw:_obligation.text WithRect:CGRectMake(x, y, drawSize.width, drawSize.height)];
            }
        }
    }
}

//resize image to scale one page.
- (UIImage *)imageCompressWithSimple:(UIImage *)image CGSize:(CGSize)size {
    // 1 calculate the scale of image.
    CGFloat scaledWidth = size.width / image.size.width;
    CGFloat scaledHeight = size.height / image.size.height;
    
    CGFloat scale = scaledWidth > scaledHeight ? scaledHeight : scaledWidth;
    
    CGSize newSize = CGSizeMake(image.size.width * scale, image.size.height * scale);
    
    return [image imageScaleToSize:newSize];
}

- (NSInteger)numberOfPages {
    //print image. 1 page. if UIPrintFormatter, return proper page number
    if (self.image) {
        return 1;
    } else {
        return [super numberOfPages];
    }
}

- (void)draw:(NSString *)text WithRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGAffineTransform translation = CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y);
    CGAffineTransform rotation;
    if (_obligation.isclockwiserotation) {
        rotation = CGAffineTransformMakeRotation(kRotationAngle);
    } else {
        rotation = CGAffineTransformMakeRotation(-kRotationAngle);
    }
    CGContextConcatCTM(context, translation);
    CGContextConcatCTM(context, rotation);
    
    const CGFloat* components = CGColorGetComponents(_obligation.textColor.CGColor);
    UIColor *textColor = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:[_obligation.transparency floatValue]/100];
    [text drawAtPoint:CGPointMake(0, 0) withAttributes:@{NSFontAttributeName:_obligation.font, NSForegroundColorAttributeName:textColor}];
    
    CGContextConcatCTM(context, CGAffineTransformInvert(rotation));
    CGContextConcatCTM(context, CGAffineTransformInvert(translation));
}

- (CGSize)caculateRotationSize:(CGSize)orginSize {
    CGFloat width = orginSize.width * cosf(kRotationAngle) + orginSize.height * sinf(kRotationAngle);
    CGFloat height = orginSize.width * sinf(kRotationAngle) + orginSize.height * cosf(kRotationAngle);
    return CGSizeMake(width, height);
}

@end

