//
//  NXFileListInfoViewController.h
//  nxrmc
//
//  Created by EShi on 10/15/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXDrag2RefreshTableView.h"

#import "NXLoginUser.h"
#import "NXFileListInfoDataProvider.h"
#import "NXFileBase.h"
#import "NXFileBase+SortSEL.h"
#import "NXFileBase+SharePointFileSys.h"
#import "NXFolder.h"
#import "NXFile.h"

#import "NXSharePointFolder.h"
#import "NXSharePointFile.h"
#import "NXFileListTableViewCell.h"
#import "NXFileDetailInfomationView.h"

@class NXFileListInfoViewController;
@protocol NXFileListInfoViewControllerDelegate <NSObject>

-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didSelectFolder:(NXFileBase *) folder inService:(NXBoundService *) service;
-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didSelectFile:(NXFileBase *)file inService:(NXBoundService *)service;

-(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc errorForFolderNotFound:(NSError *) error;
@optional -(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didAccessoryButtonTapped:(NXFileBase *)file inService:(NXBoundService *)service;
@optional -(void) fileListInfoViewVC:(NXFileListInfoViewController *)vc didAccessoryButtonTapped:(NXFileBase *)file inService:(NXBoundService *)service inPosition:(CGRect) position;
@optional -(void) fileListInfoViewVCWillDisappear:(NXFileListInfoViewController *)vc;
@optional -(void) fileListInfoViewVCDidUpdateData:(NXFileListInfoViewController *)vc;
@end

@interface NXFileListInfoViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate,NXFileDetailInfomationViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

-(instancetype) initWithFileServices:(NSArray *) services ContentFolder:(NXFileBase *) folder;
-(instancetype) initWithFileServices:(NSArray *) services ContentFolder:(NXFileBase *) folder ServiceRootFolders:(NSMutableDictionary *) rootFoldersDic;
-(void) reloadFileListTableView;
-(void) makeFileListTableViewBackToTop;
-(NXFileBase *) fileItemAtIndex:(NSIndexPath *) indexPath;
-(NXFileBase *) fileNextToFile:(NXFileBase *) file;
-(NXFileBase *) filePreToFile:(NXFileBase *) file;

@property(nonatomic, strong) NXDrag2RefreshTableView* drag2RefreshTableView;
@property(nonatomic, strong) NSMutableArray *contentDataArray;
@property(nonatomic, strong) NXFileListInfoDataProvider *fileListDataProvider;
@property(nonatomic, strong) NSMutableArray *serviceArray;
@property(nonatomic, strong) NXFileBase *contentFolder;
@property(nonatomic, weak) UIView* continerView;
@property(nonatomic, strong) NSString *defaultSortOptName;
@property(nonatomic, weak) id<NXFileListInfoViewControllerDelegate> delegate;
@property(nonatomic) BOOL isHomePage;

@property(nonatomic, strong) NSMutableDictionary *groupedFileListDic;
@property(nonatomic, strong) NSMutableArray *groupedKeys;




@end
