//
//  NXPrintInteractionController.h
//  PrintWebView
//
//  Created by nextlabs on 7/24/15.
//
//

#import <UIKit/UIKit.h>
#import "NXOverlayTextInfo.h"

@interface NXPrintInteractionController : NSObject

@property (nonatomic, assign, readonly) UIPrintInteractionController *printer;

@property (nonatomic, weak) id<UIPrintInteractionControllerDelegate> delegate;

+ (NXPrintInteractionController *)sharedInstance;

- (void)print:(UIViewPrintFormatter *)viewFormatter withOverlay:(NXOverlayTextInfo *)obligation;
- (void)printImage:(UIImage *)data withOverlay:(NXOverlayTextInfo *)overlayText; //only support .png

@end
