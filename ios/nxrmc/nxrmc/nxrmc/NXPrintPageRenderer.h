//
//  NXPrintPageRenderer.h
//  PrintWebView
//
//  Created by nextlabs on 7/24/15.
//
//

#import <UIKit/UIKit.h>
#import "NXOverlayTextInfo.h"

@interface NXPrintPageRenderer : UIPrintPageRenderer

- (instancetype)initwithObligation:(NXOverlayTextInfo *)obligation printFormat:(UIPrintFormatter *)printFormatter;
- (instancetype)initWithObligation:(NXOverlayTextInfo *)obligation image:(UIImage *)image;

@end
