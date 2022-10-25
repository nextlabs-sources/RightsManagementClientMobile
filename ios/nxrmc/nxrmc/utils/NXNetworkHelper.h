//
//  NXNetworkHelper.h
//  nxrmc
//
//  Created by helpdesk on 11/6/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"

typedef void (^NetWorkChangedBlock)(Reachability * reachability);

@interface NXNetworkHelper : NSObject

+ (NXNetworkHelper*) sharedInstance;

- (BOOL)isNetworkAvailable;  // detec network if is ok
- (BOOL)isWWANEnabled;       // detect network if is WWAN
- (BOOL)isWifiEnabled;       // detect network if is WiFi
- (NetworkStatus)getNetworkStatus;  // get network status : NotReachable = 0,ReachableViaWWAN = 1,ReachableViaWiFi = 2,

- (void)startNotifier;
- (void)stopNotifier;

- (void)addNotifier:(NetWorkChangedBlock)block withIndex:(NSInteger*)index;
- (void)removeNotifier:(NSInteger)index;
@end
