//
//  NXICloudDriveManager.m
//  nxrmc
//
//  Created by EShi on 9/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXICloudDriveDocPickerManager.h"
@interface NXICloudDriveDocPickerManager()
@property(nonatomic, strong) NXDocPickerViewController *iCloudDocPicker;
@end


@implementation NXICloudDriveDocPickerManager
-(NXDocPickerViewController *) docPickerForImportFile
{
    NSArray *supportFileTypesArray = @[@"public.item"];
    _iCloudDocPicker = [[NXDocPickerViewController alloc] initWithDocumentTypes:supportFileTypesArray inMode:UIDocumentPickerModeImport];
    _iCloudDocPicker.delegate = self;
    _iCloudDocPicker.type = kDocPickerImport;
    return _iCloudDocPicker;
}
-(NXDocPickerViewController *) docPickerForExportFileToiCloud:(NSURL *) fileURL
{
    _iCloudDocPicker = [[NXDocPickerViewController alloc] initWithURL:fileURL inMode:UIDocumentPickerModeExportToService];
    _iCloudDocPicker.delegate = self;
    _iCloudDocPicker.type = kDocPickerExport;
    return _iCloudDocPicker;
}
#pragma mark UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    switch (((NXDocPickerViewController *) controller).type) {
        case kDocPickerImport:
        {
            if ([self.delegate respondsToSelector:@selector(nxICloudDriverDocPickerMgr:didImportFile:)]) {
                [self.delegate nxICloudDriverDocPickerMgr:self didImportFile:url];
            }
        }
            break;
        case kDocPickerExport:
        {
            if ([self.delegate respondsToSelector:@selector(nxICloudDriverDocPickerMgr:didExportFile:)]) {
                [self.delegate nxICloudDriverDocPickerMgr:self didExportFile:url];
            }
        }
            break;
        default:
            break;
    }
}
@end
