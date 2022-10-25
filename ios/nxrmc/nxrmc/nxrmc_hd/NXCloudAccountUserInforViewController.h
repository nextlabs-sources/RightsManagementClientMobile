//
//  NXCloudAccountUserInforViewController.h
//  nxrmc
//
//  Created by ShiTeng on 15/5/29.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXRMCDef.h"
@class NXCloudAccountUserInforViewController;
@protocol NXCloudAccountUserInforViewControllerDelegate <NSObject>
-(void) cloudAccountUserInfoVCDidPressCancelBtn:(NXCloudAccountUserInforViewController *)cloudAccountInfoVC;
@end
@interface NXCloudAccountUserInforViewController : UIViewController

@property (nonatomic) ServiceType serviceBindType;
@property (nonatomic, copy) void (^dismissBlock)(BOOL);
@property (weak, nonatomic) IBOutlet UIButton *addAccount;
@property(nonatomic, weak) id<NXCloudAccountUserInforViewControllerDelegate> delegate;

@end
