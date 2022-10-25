//
//  NXMasterTableBarViewController.h
//  nxrmc
//
//  Created by EShi on 7/27/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXFileListViewController.h"
#import "NXCustomFileListViewController.h"
#import "NXAccountPageViewController.h"


@interface NXMasterTabBarViewController : UITabBarController

@property(nonatomic, weak) UINavigationController *fileListInfoNav;
@property(nonatomic, weak) UINavigationController *accountPageNav;
@property(nonatomic, weak) UINavigationController *helpPageNav;
@property(nonatomic, weak) UINavigationController *offlineNav;
@property(nonatomic, weak) UINavigationController *favoriteNav;

@end
