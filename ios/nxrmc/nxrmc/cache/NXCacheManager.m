//
//  NXCacheManager.m
//  nxrmc
//
//  Created by Kevin on 15/5/14.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXCacheManager.h"


#import "NXLoginUser.h"

#import "NXCommonUtils.h"
#import "NXGoogleDrive.h"

@implementation NXCacheManager



+ (void) cacheRESTReq:(NXSuperRESTAPI *) restAPI cacheURL:(NSURL *) cacheURL
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:restAPI];
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@":/\\?%*|\"<>"];
    NSString *fileName = [[restAPI.reqFlag componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
    cacheURL = [cacheURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", fileName, NXREST_CACHE_EXTENSION]];
    [data writeToURL:cacheURL atomically:YES];
}

+(NSURL *) getLogCacheURL
{
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    // cache format
    // document/rms service/user sid/rest cache/LogRest/
    cacheUrl = [[[[cacheUrl URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.rmserver] URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.userId] URLByAppendingPathComponent:@"restCache"] URLByAppendingPathComponent:@"LogRest"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheUrl.path]) {  // folder doesn't exist, create
        NSError* error = nil;
        BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:cacheUrl withIntermediateDirectories:YES attributes:nil error:&error];
        if (!rt) {
            NSLog(@"create folder failed, %@, %@", cacheUrl, error);
            return nil;
        }
    }
    return cacheUrl;
}

+(NSURL *) getRESTCacheURL
{
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    // cache format
    // document/rms service/user sid/rest cache
    cacheUrl = [[[cacheUrl URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.rmserver] URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.userId] URLByAppendingPathComponent:@"restCache"];
    
//    cacheUrl = [[cacheUrl URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.rmserver] URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.sid];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheUrl.path]) {  // folder doesn't exist, create
        NSError* error = nil;
        BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:cacheUrl withIntermediateDirectories:YES attributes:nil error:&error];
        if (!rt) {
            NSLog(@"create folder failed, %@, %@", cacheUrl, error);
            return nil;
        }
    }

    return cacheUrl;
}

+ (NSURL *) getSharingRESTCacheURL
{
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    // cache format
    // document/rms service/user sid/rest cache/SharingREST/
    cacheUrl = [[[[cacheUrl URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.rmserver] URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.userId] URLByAppendingPathComponent:@"restCache"] URLByAppendingPathComponent:@"SharingREST"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheUrl.path]) {  // folder doesn't exist, create
        NSError* error = nil;
        BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:cacheUrl withIntermediateDirectories:YES attributes:nil error:&error];
        if (!rt) {
            NSLog(@"create folder failed, %@, %@", cacheUrl, error);
            return nil;
        }
    }
    
    return cacheUrl;

}

+ (NSURL *) getHeartbeatCacheURL {
    if ([NXLoginUser sharedInstance].profile.rmserver && [NXLoginUser sharedInstance].profile.userId) {
        NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        // cache format
        // document/rms service/user sid/rest cache/SharingREST/
        cacheUrl = [[[cacheUrl URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.rmserver] URLByAppendingPathComponent:[NXLoginUser sharedInstance].profile.userId] URLByAppendingPathComponent:@"heartbeat"];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:cacheUrl.path]) {  // folder doesn't exist, create
            NSError* error = nil;
            BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:cacheUrl withIntermediateDirectories:YES attributes:nil error:&error];
            if (!rt) {
                NSLog(@"create folder failed, %@, %@", cacheUrl, error);
                return nil;
            }
        }
        return cacheUrl;
    }else
    {
        return nil;
    }
   
}

+ (void) cacheDirectory:(ServiceType)type serviceAccountId:(NSString*)sid directory:(NXFileBase *)directory
{
    if (![directory isKindOfClass:NXFolder.class]) {
        return;
    }
    
    NSURL* url = [self getSafeLocalUrlForServiceCache:type serviceAccountId:sid];
    if (!url) {
        return;
    }
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:directory];
    
    [data writeToURL:[url URLByAppendingPathComponent:CACHEDIRECTORY] atomically:YES];
    
}

+ (void) deleteCacheDirectory:(ServiceType)type serviceAccountId:(NSString *)sid
{
    NSURL *url = [self getSafeLocalUrlForServiceCache:type serviceAccountId:sid];
    [NXCommonUtils deleteFilesAtPath:url.path];
}

+ (NXFileBase*) getDirectory:(ServiceType)type serviceAccountId:(NSString *)sid
{
    NSURL* url = [self getSafeLocalUrlForServiceCache:type serviceAccountId:sid];
    if (!url) {
        return nil;
    }
    
    NSData* data = [NSData dataWithContentsOfURL:[url URLByAppendingPathComponent:CACHEDIRECTORY]];
    NXFileBase *rootFolder = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [NXCommonUtils unUnarchiverCacheDirectoryData:rootFolder];
    return rootFolder;
}

+ (NSURL *) getCacheUrlForOpenedInFile:(NSURL *) openedInFileUrl
{
    // The opened In File Url is
    // ../ApplicationPath/Cache/OpendIn/fileName
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *openedInFileName = openedInFileUrl.lastPathComponent;
    
    cacheUrl = [cacheUrl URLByAppendingPathComponent:CACHEOPENEDIN isDirectory:YES];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheUrl.path]) {  // folder doesn't exist, create
        NSError* error = nil;
        BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:cacheUrl withIntermediateDirectories:YES attributes:nil error:&error];
        if (!rt) {
            NSLog(@"create folder failed, %@, %@", cacheUrl, error);
            return nil;
        }
    }

    cacheUrl = [cacheUrl URLByAppendingPathComponent:openedInFileName isDirectory:NO];
    return cacheUrl;
}

+ (NSURL*) getLocalUrlForServiceCache:(ServiceType)type serviceAccountId:(NSString*)sid
{
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    return [self combinaFullLocalUrl:cacheUrl serviceType:type serviceAccountId:sid];
}

+ (NSURL*) getSafeLocalUrlForServiceCache:(ServiceType)type serviceAccountId:(NSString *)sid {
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [self combinaFullLocalUrl:cacheUrl serviceType:type serviceAccountId:sid];
}

+ (void) cacheFile:(NXFileBase *)file localPath:(NSString *)localPath
{
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    NSURL *url;
    NXBoundService *service = [NXCommonUtils getBoundServiceFromCoreData:file.serviceAccountId];
    if (file.isOffline) {
        url = [NXCacheManager getSafeLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    } else {
        url = [NXCacheManager getLocalUrlForServiceCache:[service.service_type integerValue] serviceAccountId:service.service_account_id];
    }
    
    url = [url URLByAppendingPathComponent:CACHEROOTDIR isDirectory:NO];
    if ([file isKindOfClass:[NXGoogleDriveFile class]]) {
            url = [url URLByAppendingPathComponent:file.parent.fullPath];
            url = [[url URLByAppendingPathComponent:file.fullServicePath] URLByAppendingPathComponent:file.name];
    } else {
        url = [url URLByAppendingPathComponent:file.fullPath];
    }
    
    if ([localPath isEqualToString:url.path]) {
        return;
    }
    
    NSString *cachePath = [url.path stringByDeletingLastPathComponent];
    if(![defaultManager fileExistsAtPath:cachePath isDirectory:nil])
    {
        [defaultManager createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSError *error;
    if ([defaultManager fileExistsAtPath:url.path isDirectory:nil]) {
        [NXCommonUtils storeCacheFileIntoCoreData:file cachePath:url.path];
        return;
    }
    
    BOOL ret = [defaultManager copyItemAtPath:localPath toPath:url.path error:&error];
    if (!ret) {
        NSLog(@"%@",error.description);
    } else {
        [NXCommonUtils storeCacheFileIntoCoreData:file cachePath:url.path];
        [defaultManager removeItemAtPath:localPath error:&error];
    }
}

+ (NSURL *) combinaFullLocalUrl:(NSURL *) cacheUrl serviceType:(ServiceType)type serviceAccountId:(NSString *)sid {
    NSString* uid = [NSString stringWithFormat:@"%@%@", CACHERMS, [NXLoginUser sharedInstance].profile.userId];
    NSURL* url = nil;
    switch (type) {
        case kServiceDropbox:
            url = [cacheUrl URLByAppendingPathComponent:uid isDirectory:YES];
            url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", CACHEDROPBOX, sid] isDirectory:YES];
            break;
        case kServiceSharepoint:
            url = [cacheUrl URLByAppendingPathComponent:uid isDirectory:YES];
            url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", CACHESHAREPOINT, sid] isDirectory:YES];
            break;
        case kServiceSharepointOnline:
            url = [cacheUrl URLByAppendingPathComponent:uid isDirectory:YES];
            url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", CACHESHAREPOINTONLINE, sid] isDirectory:YES];
            break;
        case kServiceOneDrive:
            url = [cacheUrl URLByAppendingPathComponent:uid isDirectory:YES];
            url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", CACHEONEDRIVE, sid] isDirectory:YES];
            break;
        case kServiceGoogleDrive:
            url = [cacheUrl URLByAppendingPathComponent:uid isDirectory:YES];
            url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", CACHEGOOGLEDRIVE ,sid] isDirectory:YES];
            break;
        case kServiceICloudDrive:
            url = [cacheUrl URLByAppendingPathComponent:uid isDirectory:YES];
            url = [url URLByAppendingPathComponent:CACHEICLOUDDRIVE isDirectory:YES];
            break;
        default:
            break;
    }
    
    if (!url) {
        return nil;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {  // folder doesn't exist, create
        NSError* error = nil;
        BOOL rt = [[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error];
        if (!rt) {
            NSLog(@"create folder failed, %@, %@", url, error);
            return nil;
        }
    }
    
    
    return url;
}

@end
