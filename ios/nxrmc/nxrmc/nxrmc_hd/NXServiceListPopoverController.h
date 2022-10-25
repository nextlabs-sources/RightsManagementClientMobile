//
//  serviceListController.h
//  nxrmc
//
//  Created by EShi on 7/22/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXBoundService.h"

@class NXFileListViewController;
@class NXServiceListPopoverController;

@protocol NXServiceListPopoverDelegate <NSObject>

@required
- (void) serviceListPopoverController:(NXServiceListPopoverController *) controller didSelectServices:(NSArray *) services;
- (void) serviceListPopoverControllerDidSelectAddService:(NXServiceListPopoverController *) controller;
@end



@interface NXServiceListPopoverController : UITableViewController
- (instancetype) initWithServiceArray:(NSArray *)boundServices FileListVC:(NXFileListViewController *) fileListVC;
@property(weak, nonatomic) NXFileListViewController *fileListVC;
@property(nonatomic, strong) NSMutableArray *selServiceArray;
@property(nonatomic, weak) id<NXServiceListPopoverDelegate> delegate;
@end
