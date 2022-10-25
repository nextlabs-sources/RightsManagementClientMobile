//
//  NXDownloadManager.h
//  nxrmc
//
//  Created by nextlabs on 10/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXFileBase.h"

@class NXDownloadOperation;

typedef void (^NXProgressBlock)(float progress, NXFileBase *file);
typedef void (^NXCompletionBlock)(NXFileBase *file, NSString *localCachePath, NSError *error);

@protocol NXDownloadManagerDelegate <NSObject>

@optional
- (void) downloadManagerDidProgress:(float)progress file:(NXFileBase *) file;
- (void) downloadManagerDidFinish:(NXFileBase *) file intoPath:(NSString *) localCachePath error:(NSError *) error;

@end


@interface NXDownloadManager : NSObject

+ (BOOL) startDownloadFile:(NXFileBase *) file;

+ (void) cancelDownloadFile:(NXFileBase *) file;

+ (BOOL) isDownloadingFile:(NXFileBase *) file;

+ (void) attachListener:(id<NXDownloadManagerDelegate>)listener file:(NXFileBase *) file;

+ (void) detachListener:(id<NXDownloadManagerDelegate>)listener;
@end
