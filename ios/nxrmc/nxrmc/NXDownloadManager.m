//
//  NXDownloadManager.m
//  nxrmc
//
//  Created by nextlabs on 10/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXDownloadManager.h"
#import "NXDownloadOperation.h"
#import "NXDownloadHandler.h"
#import "NXFolder.h"
#import "NXSharePointFolder.h"
#import "NXCommonUtils.h"

@interface NXDownloadManager ()

@property (nonatomic, strong) NSMutableDictionary *downloadOperations;
@property (nonatomic, strong) NSMutableDictionary *downloadHandlers;

@end

@implementation NXDownloadManager

void (^globalProgressBlock)(float progress, NXFileBase *file, NXDownloadManager *mange) =
^(float progress, NXFileBase *file, NXDownloadManager *mange){
    NSMutableArray *handlers = [mange.downloadHandlers objectForKey:file.fullServicePath];
    for(int i = 0; i < handlers.count; ++i) {
        NXDownloadHandler *handler = handlers[i];
        if([handler.delegate respondsToSelector:@selector(downloadManagerDidProgress:file:)]){
            dispatch_queue_t mainQueue= dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                [handler.delegate downloadManagerDidProgress:progress file:file];
            });
        }
    }
};

void (^globalCompletionBlock)(NXFileBase *file, NSString *localCachePath, NSError *error,NXDownloadManager *mange) =
^(NXFileBase *file, NSString *localCachePath, NSError *error, NXDownloadManager *mange) {
    
    if (!error) {
        [NXCommonUtils setLocalFileLastModifiedDate:localCachePath date:file.lastModifiedDate];
        [NXCommonUtils storeCacheFileIntoCoreData:file cachePath:localCachePath];
        NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:file];
        if (cacheFile) {
            localCachePath = cacheFile.cache_path;
        }
    }
    
    NSMutableArray *handlers = [mange.downloadHandlers objectForKey:file.fullServicePath];
    for(int i = 0; i < handlers.count; ++i) {
        NXDownloadHandler *handler = handlers[i];
        if([handler.delegate respondsToSelector:@selector(downloadManagerDidFinish:intoPath:error:)]){
            dispatch_queue_t mainQueue= dispatch_get_main_queue();
            dispatch_async(mainQueue, ^{
                [handler.delegate downloadManagerDidFinish:file intoPath:localCachePath error:error];
            });
        }
    }
    [mange.downloadHandlers removeObjectForKey:file.fullServicePath];
    [mange.downloadOperations removeObjectForKey:file.fullServicePath];
};


+ (NXDownloadManager *) sharedInstance
{
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    
    return instance;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        self.downloadOperations = [NSMutableDictionary new];
        self.downloadHandlers = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - public method.

+ (BOOL) startDownloadFile:(NXFileBase *) file {
  return [[self sharedInstance] startDownloadFile:file];
}

+ (void) cancelDownloadFile:(NXFileBase *) file {
    [[NXDownloadManager sharedInstance] cancelDownloadFile:file];
}

+ (BOOL) isDownloadingFile:(NXFileBase *) file {
    return [[NXDownloadManager sharedInstance] isDownloadingFile: file];
}

+ (void) attachListener:(id<NXDownloadManagerDelegate>)listener file:(NXFileBase *) file {
    [[NXDownloadManager sharedInstance] attachListener:listener file:file];
}

+ (void) detachListener:(id<NXDownloadManagerDelegate>)listener {
    [[NXDownloadManager sharedInstance] detachListener:listener];
}

#pragma mark -

- (BOOL) startDownloadFile:(NXFileBase *) file {
    if ([file isKindOfClass:[NXFolder class]] || [file isKindOfClass:[NXSharePointFolder class]]) {
        return NO;
    }
    
    if ([self isDownloadingFile:file]) {
        return YES;
    }
    
    NXCacheFile *cacheFile = [NXCommonUtils getCacheFile:file];
    if (cacheFile) {
        return NO;
    }
    
    NXDownloadOperation *op = [NXDownloadOperation downloadOperaion:file progressBlock:^(float progress, NXFileBase *file) {
        globalProgressBlock(progress, file, self);
    } completionBlock:^(NXFileBase *file, NSString *localCachePath, NSError *error) {
        globalCompletionBlock(file, localCachePath, error, self);
    }];
    
    if (op) {
        [op start];
        [self.downloadOperations setObject:op forKey:file.fullServicePath];
    }
    return YES;
}

- (void) cancelDownloadFile:(NXFileBase *) file {
    
    //remove all listener.
    NXDownloadOperation *op = [self.downloadOperations objectForKey:file.fullServicePath];
    if (op) {
        [op stop];
    }
    [self.downloadHandlers removeObjectForKey:file.fullServicePath];
    [self.downloadOperations removeObjectForKey:file.fullServicePath];
}

- (void) attachListener:(id<NXDownloadManagerDelegate>)listener file:(NXFileBase *) file {
    if (![self isDownloadingFile:file]) {
        return;
    }
    //one delegate only listen one file
    [self removeHandlewithDelegate:listener];
    
    NSMutableArray *handlers = [self.downloadHandlers objectForKey:file.fullServicePath];
    if (!handlers) {
        handlers = [[NSMutableArray alloc] init];
    }
    NXDownloadHandler *handler = [NXDownloadHandler downloadHandlewithFile:file delegate:listener];
    [handlers addObject:handler];
    [self.downloadHandlers setObject:handlers forKey:file.fullServicePath];
    
}

- (void) detachListener:(id<NXDownloadManagerDelegate>)listener {
    [self removeHandlewithDelegate:listener];
}

- (BOOL) isDownloadingFile:(NXFileBase *) file {
    NXDownloadOperation *op = [self.downloadOperations objectForKey:file.fullServicePath];
    if (op) {
        return YES;
    } else {
        return NO;
    }
}

- (void) removeHandlewithDelegate:(id<NXDownloadManagerDelegate>) delegate {
    for (int i = 0; i < self.downloadHandlers.allKeys.count; ++i)
    {
        NSString *key = self.downloadHandlers.allKeys[i];
        NSMutableArray *array = [self.downloadHandlers objectForKey:key];
        
        for (int j = 0; j < array.count; ++j)
        {
            NXDownloadHandler *handler = array[j];
            if ([handler.delegate isEqual:delegate])
            {
                [array removeObject:handler];
                NSLog(@"this may be cause crash bug");
            }
        }
    }
}

@end
