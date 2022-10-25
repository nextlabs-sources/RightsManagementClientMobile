//
//  DetailViewController.h
//  nxrmc_hd
//
//  Created by EShi on 7/21/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXFileListInfoViewController.h"
#import "NXCustomFileListViewController.h"
@class NXFileBase;
@class NXBoundService;
@class DetailViewController;

@protocol DetailViewControllerDelegate <NSObject>
@optional
- (void) detailViewController:(DetailViewController *) detailVC SwipeToNextFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inFileListInfoView:(NXFileListInfoViewController *) fileListInfoVC;
- (void) detailViewController:(DetailViewController *) detailVC SwipeToPreFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inFileListInfoView:(NXFileListInfoViewController *) fileListInfoVC;

- (void) detailViewController:(DetailViewController *) detailVC SwipeToNextFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inCustomFileListViewController:(NXCustomFileListViewController *) customFileListVC;
- (void) detailViewController:(DetailViewController *) detailVC SwipeToPreFileFrom:(NXFileBase *) file inService:(NXBoundService *) service inCustomFileListViewController:(NXCustomFileListViewController *) customFileListVC;


@end

@interface DetailViewController : UIViewController<UISplitViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NXFileBase* curFile;
@property (nonatomic, strong) NSString *curNXLFileOwner;
@property (nonatomic, strong) NSString *curNXLFileDUID;
@property (nonatomic, weak) NXBoundService* curService;
@property (nonatomic, weak) NXFileListInfoViewController *fileListInfoVC;
@property (nonatomic, weak) NXCustomFileListViewController *customFileListVC;
@property (nonatomic, weak) id<DetailViewControllerDelegate> delegate;

- (void)openFile:(NXFileBase *)file currentService:(NXBoundService *)service isOpen3rdAPPFile:(BOOL) isOpen3rdAPPFile isOpenNewProtectedFile:(BOOL) isOpenNewProtectedFile;
- (void)openFile:(NXFileBase *)file currentService:(NXBoundService *)service inFileListInfoViewController:(NXFileListInfoViewController *) fileListInfoVC isOpen3rdAPPFile:(BOOL) isOpen3rdAPPFile isOpenNewProtectedFile:(BOOL) isOpenNewProtectedFile;
- (void)openFile:(NXFileBase *)file currentService:(NXBoundService *)service inCustomFileListViewController:(NXCustomFileListViewController *) customFileListVC isOpen3rdAPPFile:(BOOL) isOpen3rdAPPFile isOpenNewProtectedFile:(BOOL) isOpenNewProtectedFile;

-(void) showAutoDismissLabel:(NSString *) labelContent;
@end


