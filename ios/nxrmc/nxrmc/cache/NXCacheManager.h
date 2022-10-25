//
//  NXCacheManager.h
//  nxrmc
//
//  Created by Kevin on 15/5/14.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXRMCDef.h"
#import "NXBoundService.h"
#import "NXFolder.h"
#import "NXSuperRESTAPI.h"

@interface NXCacheManager : NSObject


+ (void) cacheRESTReq:(NXSuperRESTAPI *) restAPI cacheURL:(NSURL *) cacheURL;

+ (NSURL *) getRESTCacheURL;
+ (NSURL *) getSharingRESTCacheURL;
+ (NSURL *) getLogCacheURL;

+ (NSURL *) getHeartbeatCacheURL;

+ (void) cacheDirectory: (ServiceType)type serviceAccountId:(NSString*)sid directory: (NXFileBase*)directory;
+ (void) deleteCacheDirectory:(ServiceType)type serviceAccountId:(NSString*)sid;

+ (NXFileBase*) getDirectory: (ServiceType)type serviceAccountId:(NSString*)sid;

+ (NSURL*) getLocalUrlForServiceCache:(ServiceType)type serviceAccountId:(NSString *)sid;
+ (NSURL*) getSafeLocalUrlForServiceCache:(ServiceType)type serviceAccountId:(NSString *)sid;
+ (NSURL*) getCacheUrlForOpenedInFile:(NSURL *)openedInFileUrl;

+ (void) cacheFile:(NXFileBase *)file localPath:(NSString *)localPath;
@end
