//
//  NXDocPickerViewController.h
//  nxrmc
//
//  Created by EShi on 9/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum{
    kDocPickerImport = 1,
    kDocPickerExport,
} DocPickerViewControllerType;

@interface NXDocPickerViewController : UIDocumentPickerViewController
@property(nonatomic) DocPickerViewControllerType type;
@end
