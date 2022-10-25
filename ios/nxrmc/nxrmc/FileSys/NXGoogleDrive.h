//
//  NXGoogleDrive.h
//  nxrmc
//
//  Created by nextlabs on 8/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NXServiceOperation.h"
#import "NXFile.h"

@interface NXGoogleDriveFile : NXFile
@property (nonatomic, copy) NSString *downloadURL;
@end

@interface NXGoogleDrive : NSObject<NXServiceOperation>
@property(nonatomic, strong)NSString *alias;
@property(nonatomic, strong) NXBoundService *boundService;

- (id) initWithUserId: (NSString *)userId;

@end
