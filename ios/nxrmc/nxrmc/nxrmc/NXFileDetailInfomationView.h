//
//  NXFileDetailInfomationView.h
//  nxrmc
//
//  Created by nextlabs on 10/21/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXFileBase.h"
#import "NXBoundService.h"

@class NXFileDetailInfomationView;

@protocol NXFileDetailInfomationViewDelegate <NSObject>

- (void) fileDetailInfomationView:(NXFileDetailInfomationView *)view switchValuedidChanged:(BOOL)changedValue file:(NXFileBase *)file inService:(NXBoundService *)service;

@end

@interface NXFileDetailInfomationView : UIView

@property (nonatomic, strong) NXFileBase *file;
@property (nonatomic, strong) NXBoundService *fileService;
@property (nonatomic, weak) UIViewController *currentVc;

@property (nonatomic, weak) id<NXFileDetailInfomationViewDelegate> fileInfodelegate;

+ (instancetype) fileDetailInfoViewWithBounds:(CGRect)bounds file:(NXFileBase *)file filedelegate:(id<NXFileDetailInfomationViewDelegate>)delegate;
+ (instancetype) fileDetailInfoView:(NXFileBase *) file Service:(NXBoundService *) service filedelegate:(id<NXFileDetailInfomationViewDelegate>) delegate;

- (void) showFileDetailInfoView;

@end
