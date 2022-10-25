//
//  NXAdHocSharingViewController.h
//  nxrmc
//
//  Created by Kevin on 16/6/13.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NXRights;
@class NXFileBase;
@class NXBoundService;

typedef NS_ENUM(NSUInteger, NXProtectType) {
    NXProtectTypeNormal = 0, //just for protect and upload.
    NXProtectTypeSharing,  //adhoc share.
};

@interface NXAdHocSharingViewController : UIViewController

@property(nonatomic) NXProtectType type;

@property (nonatomic, strong) NXFileBase *curFile;
@property (nonatomic, strong) NSString* curFilePath;
@property (nonatomic, strong) NXRights* rights;

//used when protect and upload.
@property(nonatomic, strong) NXBoundService *curService;
@property(nonatomic) BOOL isProtectThirdPartyAPPFile;

@end
