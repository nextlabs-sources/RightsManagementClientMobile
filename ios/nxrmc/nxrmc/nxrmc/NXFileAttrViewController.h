//
//  NXFileAttrViewController.h
//  nxrmc
//
//  Created by helpdesk on 11/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NXFileBase;
@class NXBoundService;
@class NXRights;

@interface NXFileAttrViewController : UIViewController

@property(nonatomic, strong) NXFileBase* curFile;
@property(nonatomic, weak) NXBoundService* curService;
@property(nonatomic, weak) NXRights *curRights;
@property(nonatomic) BOOL isSteward;

@property(nonatomic) BOOL isOpenThirdAPPFile;
@end
