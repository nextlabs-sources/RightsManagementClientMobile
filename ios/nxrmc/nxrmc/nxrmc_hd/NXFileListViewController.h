//
//  NXFileListViewController.h
//  nxrmc
//
//  Created by EShi on 7/27/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewController.h"
#import "NXSortFilePopoverContentController.h"
#import "NXServiceListPopoverController.h"

typedef void (^SortOperationBlock)();
#define SORT_OPT_NAME @"SortOptName"
#define SORT_OPT_BLOCK @"SortOptBlock"
#define SORT_OPT_ICON @"SortOptIcon"
#define SORT_OPT_NAME_DESC_ICON @"SortByNameDesc"
#define SORT_OPT_NAME_ASC_ICON @"SortByNameAsc"
#define SORT_OPT_DATE_NEWSET_ICON @"SortByDateNewest"
#define SORT_OPT_DATE_OLDEST_ICON @"SortByDateOldest"
#define SORT_OPT_SIZE_LARGEST_ICON @"SortBySizeLargest"
#define SORT_OPT_SIZE_SMALLEST_ICON @"SortBySizeSmallest"

@interface NXFileListViewController : UIViewController<NXSortFilePopoverContentControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *selectServiceBtn;
@property (weak, nonatomic) IBOutlet UIButton *sortFileBtn;
@property(nonatomic, strong) DetailViewController *fileContentVC;
// sort operation
@property(nonatomic, strong) NSMutableArray* sortOperationArray;
@property(nonatomic, copy) SortOperationBlock curSortOptBlock;
@property(nonatomic, strong) NSString *curSortOptName;

- (void) responseToBoundServiceOpt;
@end
