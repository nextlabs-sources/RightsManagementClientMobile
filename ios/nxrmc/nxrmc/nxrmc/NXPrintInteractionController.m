//
//  NXPrintInteractionController.m
//  PrintWebView
//
//  Created by nextlabs on 7/24/15.
//
//

#import "NXPrintInteractionController.h"
#import "NXPrintPageRenderer.h"

static NXPrintInteractionController *sharedInstance = nil;

@interface NXPrintInteractionController()<UIPrintInteractionControllerDelegate>
@end

@implementation NXPrintInteractionController

+ (NXPrintInteractionController *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init {
    _printer = [UIPrintInteractionController sharedPrintController];
    return self;
}

- (void)print:(UIViewPrintFormatter *)viewFormatter withOverlay:(NXOverlayTextInfo *)obligation {
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.duplex = UIPrintInfoDuplexLongEdge;
    
    _printer.printInfo = printInfo;
    _printer.showsPageRange = YES;
    
    NXPrintPageRenderer *pageRenderer = [[NXPrintPageRenderer alloc] initwithObligation:obligation printFormat:viewFormatter];
    
    _printer.printPageRenderer = pageRenderer;
    _printer.delegate = self;
}

- (void)printImage:(UIImage *)image withOverlay:(NXOverlayTextInfo *)obligation {
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.duplex = UIPrintInfoDuplexNone;
    
    _printer.printInfo = printInfo;
    _printer.showsPageRange = NO;
    
    NXPrintPageRenderer *pageRenderer = [[NXPrintPageRenderer alloc] initWithObligation:obligation image:image];
    
    _printer.printPageRenderer = pageRenderer;
    _printer.delegate = self;
}

#pragma mark - UIPrintInteractionControllerDelegate

- (void)printInteractionControllerWillStartJob:(UIPrintInteractionController *)printInteractionController {
    if (_delegate) {
        [self.delegate printInteractionControllerWillStartJob:printInteractionController];
    }
}
- (void)printInteractionControllerDidFinishJob:(UIPrintInteractionController *)printInteractionController {
    if (_delegate) {
        [self.delegate printInteractionControllerDidFinishJob:printInteractionController];
    }
}
@end
