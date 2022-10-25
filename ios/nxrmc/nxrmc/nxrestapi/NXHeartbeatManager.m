//
//  NXHeartbeatManager.m
//  nxrmc
//
//  Created by nextlabs on 7/15/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXHeartbeatManager.h"
#import "NXHeartbeatAPI.h"
#import "NXOverlayTextInfo.h"
#import "NXCacheManager.h"

static NSLock* gLock = nil;

static NXHeartbeatManager *instance = nil;

@interface NXHeartbeatManager ()

@property(nonatomic, strong) NSTimer *heartbeatTimer;
@property(nonatomic, assign) BOOL needExit;
@property(nonatomic, assign) BOOL heartBeatStarted;

@end

@implementation NXHeartbeatManager

+ (instancetype)sharedInstance {
    static NXHeartbeatManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self  alloc] init];
        gLock = [[NSLock alloc] init];
    });
    return instance;
}

- (void)stop {
    _needExit = YES;
}

- (void)start {
    if (_heartBeatStarted) {
        return;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        @autoreleasepool {
            _needExit = NO;
            _heartBeatStarted = YES;
            _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:6000 target:self selector:@selector(getPolicyTimer:) userInfo:nil repeats:YES];
            [_heartbeatTimer fire];
            NSRunLoop* loop = [NSRunLoop currentRunLoop];
            do
            {
                @autoreleasepool
                {
                    [loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.2]];
                    if (_needExit) {
                        [_heartbeatTimer invalidate];
                        break;
                    }
                    
                    [NSThread sleepForTimeInterval:0.2f];
                }
            }while (true);
            NSLog(@"HeartBeart thread quite");
            _heartBeatStarted = NO;
        }
    });
}

- (void)getPolicyTimer : (NSTimer*) timer {
    NXHeartbeatAPI *api = [[NXHeartbeatAPI alloc] init];
    [api requestWithObject:nil Completion:^(id response, NSError *error) {
        if (error) {
            NSLog(@"NXHeartbeatAPI error: %@", error);
        } else {
            if ([response isKindOfClass:[NXHeartbeatAPIResponse class]]) {
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response];
                [self saveFile:data documentURL:[NXCacheManager getHeartbeatCacheURL]];

            }
        }
    }];
}

- (NXOverlayTextInfo *)getOverlayTextInfo {
    NSData *data = [self readFromFile];
    NXHeartbeatAPIResponse *response = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NXOverlayTextInfo *info = [[NXOverlayTextInfo alloc] initWithObligation:response];
    return info;
}

- (NSData *)readFromFile {
    NSURL * documentURL = [[NXCacheManager getHeartbeatCacheURL] URLByAppendingPathComponent:@"cache.file" isDirectory:NO];
    [gLock lock];
    NSData *data = [NSData dataWithContentsOfURL:documentURL];
    [gLock unlock];
    return data;
}
- (void)saveFile:(NSData*)data documentURL:(NSURL*)documentURL
{
    if (documentURL == nil || data == nil) {
        return;
    }
    documentURL = [documentURL URLByAppendingPathComponent:@"cache.file" isDirectory:NO];
    [gLock lock];
    NSError *error;
    BOOL bret = [data writeToURL:documentURL options:NSDataWritingFileProtectionNone error:&error];
    [gLock unlock];
    if(bret) {
        NSLog(@"restAPIResponse, saved to local disk successfully");
    } else {
        NSLog(@"restAPIResponse, saved to local disk fail");
    }
}
@end

