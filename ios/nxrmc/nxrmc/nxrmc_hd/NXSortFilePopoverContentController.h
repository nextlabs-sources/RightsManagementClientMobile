//
//  NXSortFilePopoverContentController.h
//  nxrmc
//
//  Created by EShi on 7/30/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^SortOperationBlock)();

@class NXFileListViewController;
@class NXSortFilePopoverContentController;

@protocol NXSortFilePopoverContentControllerDelegate <NSObject>
@required
- (void) contentController:(NXSortFilePopoverContentController *) contentController selectSortTitle:(NSString *) sortTitle;

@end

@interface NXSortFilePopoverContentController : UITableViewController
-(instancetype) initWithFileListVC:(NXFileListViewController *) fileListVC isRootFolder:(BOOL) isRootFolder;

@property(weak, nonatomic) NXFileListViewController *fileListVC;

@end
