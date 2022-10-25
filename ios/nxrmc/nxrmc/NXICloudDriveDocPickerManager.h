//
//  NXICloudDriveManager.h
//  nxrmc
//
//  Created by EShi on 9/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXDocPickerViewController.h"
@class NXICloudDriveDocPickerManager;
@protocol NXICloudDriveDocPickerMgrDelegate <NSObject>
@optional
-(void) nxICloudDriverDocPickerMgr:(NXICloudDriveDocPickerManager *) pkMgr didImportFile:(NSURL *) fileURL;
-(void) nxICloudDriverDocPickerMgr:(NXICloudDriveDocPickerManager *) pkMgr didExportFile:(NSURL *) fileURL;
@end

@interface NXICloudDriveDocPickerManager : NSObject<UIDocumentPickerDelegate>
@property(nonatomic, weak) id<NXICloudDriveDocPickerMgrDelegate> delegate;
-(NXDocPickerViewController *) docPickerForImportFile;
-(NXDocPickerViewController *) docPickerForExportFileToiCloud:(NSURL *) fileURL;

@end
