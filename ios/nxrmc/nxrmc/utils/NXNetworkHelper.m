//
//  NXNetworkHelper.m
//  nxrmc
//
//  Created by helpdesk on 11/6/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXNetworkHelper.h"

static NXNetworkHelper* sharedObj = nil;

@interface NXNetworkHelper()
{
    Reachability *_reach;
    NSInteger _index;
}

@property(nonatomic,strong) NSMutableDictionary *blocks;

@end

@implementation NXNetworkHelper

+ (NXNetworkHelper*) sharedInstance
{
    @synchronized(self)
    {
        if (sharedObj == nil) {
            sharedObj = [[super allocWithZone:nil] init];
        }
    }

    return sharedObj;
}

+ (id) allocWithZone:(struct _NSZone *)zone
{
    return nil;
}

- (id) init
{
    if (self = [super init]) {
        _reach = [Reachability reachabilityWithHostName:@"www.apple.com"];
        _index = 0;
    }
    
    return self;
}

- (BOOL)isNetworkAvailable
{
    return [_reach isReachable];
}

- (BOOL)isWWANEnabled
{
    return [_reach isReachableViaWWAN];
}

- (BOOL)isWifiEnabled
{
    return [_reach isReachableViaWiFi];
}

- (NetworkStatus)getNetworkStatus
{
    return [_reach currentReachabilityStatus];
}

- (void)startNotifier
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [_reach startNotifier];
}
- (void)stopNotifier
{
    [[NSNotificationCenter defaultCenter]removeObserver:self
                                                   name:kReachabilityChangedNotification
                                                 object:nil];
    [_reach stopNotifier];
}

- (void)addNotifier:(NetWorkChangedBlock)block withIndex:(NSInteger*)index
{
    *index = _index++;
    [self.blocks setObject:block forKey:[NSNumber numberWithInteger:*index]];
}

- (void)removeNotifier:(NSInteger)index
{
    [self.blocks removeObjectForKey:[NSNumber numberWithInteger:index]];
}

#pragma mark private method and will be called when the network status changed
- (void)reachabilityChanged:(NSNotification *)note
{
    Reachability *curReach = [note object];
    if([curReach isKindOfClass:[Reachability class]])
    {
        [self.blocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            ((NetWorkChangedBlock)self.blocks[key])(curReach);
        }];
    }
}

// blocks getter method
-(NSMutableDictionary*)blocks
{
    if(_blocks == nil)
    {
        _blocks = [NSMutableDictionary  dictionary];
    }
    return _blocks;
}

@end
