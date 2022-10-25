//
//  NXDownloadHandle.h
//  nxrmc
//
//  Created by nextlabs on 10/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXFileBase.h"
#import "NXDownloadManager.h"

@interface NXDownloadHandler : NSObject

@property(nonatomic, strong) NXFileBase *file;
@property(nonatomic, assign) id<NXDownloadManagerDelegate> delegate;

+(NXDownloadHandler *) downloadHandlewithFile:(NXFileBase *)file delegate:(id<NXDownloadManagerDelegate>) delegate;

@end
