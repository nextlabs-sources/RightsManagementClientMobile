//
//  NXOneDriveCallBack.m
//  nxrmc
//
//  Created by EShi on 3/22/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXOneDriveCallBack.h"
#import "LiveSDk/LiveConstants.h"
#import "AppDelegate.h"

static NXOneDriveCallBack *oneDriveCallBack = nil;
NSLock* oneLock = nil;

@interface NXOneDriveCallBack()
@property(nonatomic, strong) NSMapTable *oneDriveOperatorsMap;
@property(nonatomic, strong) NSMutableArray *operationArray;
@property(nonatomic, strong) NSMutableArray *noAuthedOperationArray;
@end

@implementation NXOneDriveCallBack
#pragma mark - INIT/GETTER/SETTER
+(instancetype) sharedInstance
{
    static dispatch_once_t once_predicate;
    dispatch_once(&once_predicate, ^{
        oneDriveCallBack = [[super allocWithZone:nil] init];
        
        oneLock = [[NSLock alloc] init];
        
    });
    return oneDriveCallBack;
}


+(instancetype) allocWithZone:(struct _NSZone *)zone
{
    return nil;
}

-(NSMapTable *) oneDriveOperatorsMap
{
    if (_oneDriveOperatorsMap == nil) {
        _oneDriveOperatorsMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
    }
    return _oneDriveOperatorsMap;
}

-(NSMutableArray *) operationArray
{
    if (_operationArray == nil) {
        _operationArray = [[NSMutableArray alloc] init];
    }
    
    return _operationArray;
}

-(NSMutableArray *) noAuthedOperationArray
{
    if (_noAuthedOperationArray == nil) {
        _noAuthedOperationArray = [[NSMutableArray alloc] init];
    }
    
    return _noAuthedOperationArray;
}
#pragma mark - oneDriveOperator Dictionary operation
-(void) addOneDriveOperator:(NXOneDrive *) oneDriveOperator operationKey:(LiveOperation *) operationKey
{
    if (oneDriveOperator && operationKey) {
        NSString *key = [NSString stringWithFormat:@"%p", operationKey];
        [oneLock lock];
        [self.oneDriveOperatorsMap setObject:oneDriveOperator forKey:key];
        [oneLock unlock];
    }
}
-(void) removeOneDriveOperator:(LiveOperation *) operationKey
{
    if (operationKey) {
        NSString *key = [NSString stringWithFormat:@"%p", operationKey];
        [oneLock lock];
        [self.oneDriveOperatorsMap removeObjectForKey:key];
        [oneLock unlock];
    }
}

-(void) addOneDriveOperation:(LiveOperation *) operation
{
    if (operation) {
        [oneLock lock];
        [self.operationArray addObject:operation];
        [oneLock unlock];
    }
}

#pragma mark LiveOperationDelegate
- (void) liveOperationSucceeded:(LiveOperation *)operation
{
    
    NSString *key = [NSString stringWithFormat:@"%p", operation];
    [oneLock lock];
    __weak NXOneDrive *oneDriveOperator = [self.oneDriveOperatorsMap objectForKey:key];
    [self.operationArray removeObject:operation];
    [self.noAuthedOperationArray removeAllObjects];
    [oneLock unlock];
    [oneDriveOperator liveOperationSucceeded:operation];
    [self removeOneDriveOperator:operation];
    
}

- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation*)operation
{
    
    NSString *key = [NSString stringWithFormat:@"%p", operation];
    [oneLock lock];
    __weak NXOneDrive *oneDriveOperator = [self.oneDriveOperatorsMap objectForKey:key];
    // when user cancel operation, we should check if liveClient session is valid.
    // if liveClien session is not valid, the operation may doing auth, and auth delegate is operation,
    // In this case, we can not release operation, otherwise when auth callback, it's delegate is wild pointer, cause crash
    if ([error.domain isEqualToString:LIVE_ERROR_DOMAIN] && error.code == LIVE_ERROR_CODE_LOGIN_FAILED) { // if user cancel operation
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        if ([appDelegate.liveClient.session.expires timeIntervalSinceNow] < LIVE_AUTH_REFRESH_TIME_BEFORE_EXPIRE) {
            [self.noAuthedOperationArray addObject:operation];
        }
    }
    [self.operationArray removeObject:operation];
    [oneLock unlock];
    [oneDriveOperator liveOperationFailed:error operation:operation];
    [self removeOneDriveOperator:operation];
    
}

#pragma mark - LiveDownloadOperationDelegate
- (void) liveDownloadOperationProgressed:(LiveOperationProgress *)progress
                                    data:(NSData *)receivedData
                               operation:(LiveDownloadOperation *)operation
{
    
    NSString *key = [NSString stringWithFormat:@"%p", operation];
    [oneLock lock];
    __weak NXOneDrive *oneDriveOperator = [self.oneDriveOperatorsMap objectForKey:key];
    [oneLock unlock];
    [oneDriveOperator liveDownloadOperationProgressed:progress data:receivedData operation:operation];
}

#pragma mark - LiveUploadOperationDelegate
- (void) liveUploadOperationProgressed:(LiveOperationProgress *)progress
                             operation:(LiveOperation *)operation
{
    
    NSString *key = [NSString stringWithFormat:@"%p", operation];
    [oneLock lock];
    __weak NXOneDrive *oneDriveOperator = [self.oneDriveOperatorsMap objectForKey:key];
    [oneLock unlock];
    [oneDriveOperator liveUploadOperationProgressed:progress operation:operation];
}


@end
