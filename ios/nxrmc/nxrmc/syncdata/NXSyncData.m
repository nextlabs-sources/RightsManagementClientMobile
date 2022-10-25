//
//  NXSyncData.m
//  nxrmc
//
//  Created by Kevin on 15/6/11.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXSyncData.h"

#import "NXCommonUtils.h"
#import "NXRMCDef.h"

@interface NXSyncData ()
{
    NXFileBase*             _curFileBase;
    NXBoundService*         _curService;
    BOOL                    _processing;
    id<NXServiceOperation>  _serviceOperation;
    BOOL                    _serviceChanged;
    BOOL                    _needExit;
    NSData*                 _folderBackup;
    NSTimer*                _timer;
    NSThread*               _backgroundThread;
    NXOperationType         _operationType;
}

@property(nonatomic, strong) NSMutableArray *serviceOptArray;
@property(nonatomic, strong) NSMutableArray *tempServiceOptArray;
@property(nonatomic, strong) NSMutableArray *tempFileList;
@property(nonatomic, strong) NSMutableDictionary *foldersDict;
@property(nonatomic, strong) NSError *summaryError;
@property(nonatomic) BOOL isSupportMultiService;
@property(nonatomic) BOOL isPrepareExit;
@property(nonatomic, strong) dispatch_semaphore_t semaphore;
@end

@implementation NXSyncData

- (id) init
{
    if (self = [super init]) {
        _needExit = NO;
        _operationType = NXOPERATION_GETFILES;
        _semaphore = dispatch_semaphore_create(0);
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async_f(queue, (void*)CFBridgingRetain(self), syncDataThread);
    }
    return self;
}

- (id) initWithOperationType:(NXOperationType)operationType
{
    if(self = [self init])
    {
        _operationType = operationType;
    }
    return self;
}

- (void) dealloc
{
    NSLog(@"NXSyncData dealloc _operationType = %li",(long)_operationType);
    dispatch_semaphore_signal(_semaphore);
   
}

-(NSMutableArray *) serviceOptArray
{
    if (_serviceOptArray == nil) {
        _serviceOptArray = [[NSMutableArray alloc] init];
    }
    return _serviceOptArray;
}

-(NSMutableArray *) tempServiceOptArray
{
    if (_tempServiceOptArray == nil) {
        _tempServiceOptArray = [[NSMutableArray alloc] init];
    }
    return _tempServiceOptArray;
}

-(NSMutableArray *) tempFileList
{
    if (_tempFileList == nil) {
        _tempFileList = [[NSMutableArray alloc] init];
    }
    return _tempFileList;
}

-(NSMutableDictionary *) foldersDict
{
    if (_foldersDict == nil) {
        _foldersDict = [[NSMutableDictionary alloc] init];
    }
    
    return _foldersDict;
}

// mostly will be invoked by main thread.
- (void) cancelSync
{
    @synchronized(self)
    {
        // cancel service operation
        switch (_operationType) {
            case NXOPERATION_GETFILES:
                self.isPrepareExit = YES;
                [_serviceOperation cancelGetFiles:_curFileBase];
                break;
            case NXOPERATION_GETMETADATA:
            {
                self.isPrepareExit = YES;
                [_serviceOperation cancelGetMetaData:_curFileBase];

            }
                break;
            default:
                break;
        }
        
    }
}

- (void) cancelMultiServiceSync
{
    _isPrepareExit = YES;
    for (id<NXServiceOperation> serviceOpt in self.serviceOptArray) {
        
        NSString *key = [NXCommonUtils getServiceFolderKeyForFolderDirectory:[serviceOpt getOptBoundService]];
        NXFileBase *queryFolder = self.foldersDict[key];
        [serviceOpt cancelGetFiles:queryFolder];
    }
    dispatch_semaphore_signal(_semaphore);
    NSLog(@"cancel MM %@", self);
}

-(void) cancelAllGetFiles
{
    for (id<NXServiceOperation> serviceOpt in self.serviceOptArray) {
        
        NSString *key = [NXCommonUtils getServiceFolderKeyForFolderDirectory:[serviceOpt getOptBoundService]];
        NXFileBase *queryFolder = self.foldersDict[key];
        [serviceOpt cancelGetFiles:queryFolder];
    }
    NSLog(@"cancel MM %@", self);
}


// this is a timer function
- (void) syncData: (NSTimer*) timer
{
   // NSLog(@"syncData, timer: %f", timer.timeInterval);

    @synchronized(self)
    {
        if (!_curService || [_curService.service_type intValue] == kServiceUnset ){
            _timer = [NSTimer scheduledTimerWithTimeInterval:SYNCDATA_INTERVAL target:self selector:@selector(syncData:) userInfo:timer.userInfo repeats:NO];
            return;
        }
        switch ([timer.userInfo integerValue]) {
            case NXOPERATION_GETFILES:
                {
                    if (_serviceChanged) {
                        _serviceChanged = NO;
                        _serviceOperation = [NXCommonUtils createServiceOperation: _curService];
                        [_serviceOperation setDelegate:self];
                    }
                    
                    if (![_serviceOperation getFiles:_curFileBase]) {
                      //  NSLog(@"syncData timer, calling getFiles failed");
                        _timer = [NSTimer scheduledTimerWithTimeInterval:SYNCDATA_INTERVAL target:self selector:@selector(syncData:) userInfo:nil repeats:NO];
                        
                        return;
                    }
                    else
                    {
                       // NSLog(@"syncData timer, calling getFiles successfully, waiting for callback");
                    }
                }
                break;
            case NXOPERATION_GETMETADATA:
                {
                    if (![_serviceOperation getMetaData:_curFileBase]) {
                       // NSLog(@"syncMetaData timer, calling getMetaData failed");
                        _timer = [NSTimer scheduledTimerWithTimeInterval:SYNCDATA_INTERVAL target:self selector:@selector(syncData:) userInfo:nil repeats:NO];
                        
                        return;
                    }
                    else
                    {
                       // NSLog(@"syncMetaData timer, calling getMetaData successfully, waiting for callback");
                    }
                }
                break;
            default:
                break;
        }
    }
}

-(void) syncMultiServiceData:(NSTimer *) timer
{
    @synchronized(self)
    {
        if (self.isPrepareExit) { // because timer may fired after cancelSync, so we should check whether cancelSync is called. if called, just exit the loop thread
            _needExit = YES;
            return;
        }
       // NSLog(@"***syncMultiServiceData");
        self.isSupportMultiService = YES;
        
        [self.tempServiceOptArray removeAllObjects];
        self.tempServiceOptArray = [self.serviceOptArray mutableCopy];
        
        NSMutableArray * delArray = [[NSMutableArray alloc] init];
        for (id<NXServiceOperation> serviceOpt in self.tempServiceOptArray) {
            [serviceOpt setDelegate:self];
            
            NSString *key  = [NXCommonUtils getServiceFolderKeyForFolderDirectory:[serviceOpt getOptBoundService]];
            NXFileBase *queryFolder = self.foldersDict[key];
          //  NSLog(@"Sync timer work, folder name is %@",  queryFolder.name);
            BOOL ret = [serviceOpt getFiles:queryFolder];
            if (!ret) {
                [delArray addObject:serviceOpt];
            }
        }
        
        for (id<NXServiceOperation> delServiceOpt in delArray) {
            [self.tempServiceOptArray removeObject:delServiceOpt];
        }
        
        if (self.tempServiceOptArray.count <=0) {
           // NSLog(@"syncData timer, multi-service calling getFiles failed");
            _timer = [NSTimer scheduledTimerWithTimeInterval:SYNCDATA_INTERVAL target:self selector:@selector(syncMultiServiceData:) userInfo:nil repeats:NO];
            return;
            
        }else
        {
            //NSLog(@"syncData timer, multi-service calling getFiles successfully, waiting for callback %@", self);
        }
    }
}

// it will be run in gcd thread.
void syncDataThread(void* param)
{
    @autoreleasepool {

        NXSyncData* context = CFBridgingRelease(param);
      
        // record sync thread, make sure all startNewSyncDataTimer are called in background thread
        context->_backgroundThread = [NSThread currentThread];
        // run runloop
        NSRunLoop* loop = [NSRunLoop currentRunLoop];
        
        dispatch_semaphore_signal(context->_semaphore);
        do
        {
            @autoreleasepool
            {
                [loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow: 0.2]];
                if (context->_needExit) {
                    break;
                }

                [NSThread sleepForTimeInterval:0.2f];
            }
        }while (true);
        
        [context->_timer invalidate];
       // NSLog(@"sync data thread exits %@", context);
    }
}

// invoked by calling thread, mostly is main thread
- (void) updateSync:(NXBoundService *)service curFolder:(NXFileBase *)folder
{
    @synchronized(self)
    {
        [_serviceOperation cancelGetFiles:_curFileBase];
        
        if (_curService != service) {
            _serviceChanged = YES;
        }
               
        _curFileBase = folder;
        _curService = service;
        
        _folderBackup = [NSKeyedArchiver archivedDataWithRootObject:_curFileBase];
        // schedule another timer to sync data.
        if (_backgroundThread.isExecuting) {
            [self performSelector:@selector(startNewSyncDataTimer) onThread:_backgroundThread withObject:nil waitUntilDone:NO];

        }
    }
    
}

-(void) startServicesSync:(NSArray *)services withFolders:(NSMutableDictionary *) foldersDict
{
    @synchronized(self) {
       // NSLog(@"I want start a new sync to get folders");
        for (id<NXServiceOperation> serviceOpt in self.serviceOptArray) {
            
            NSString *key = [NXCommonUtils getServiceFolderKeyForFolderDirectory:[serviceOpt getOptBoundService]];
            NXFileBase *queryFolder = self.foldersDict[key];
            [serviceOpt cancelGetFiles:queryFolder];
           
        }
        
        self.serviceOptArray = [services mutableCopy];
        self.foldersDict = foldersDict;
        
        
        // schedule another timer to sync data.
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
            if (_backgroundThread.isExecuting) {
                [self performSelector:@selector(startNewMultiServiceSync) onThread:_backgroundThread withObject:nil waitUntilDone:NO];
            }
        });
    }
}

- (void) updateMetaDataSync:(NXBoundService *)service curFile:(NXFileBase *)file
{
    @synchronized(self)
    {
        _curFileBase= file;
        _curService = service;
        _serviceOperation = [NXCommonUtils createServiceOperation: _curService];
        NSLog(@"sync metadata service = %@",_serviceOperation);
        [_serviceOperation setDelegate:self];
        _folderBackup = [NSKeyedArchiver archivedDataWithRootObject:_curFileBase];
        if (_backgroundThread.isExecuting) {
            [self performSelector:@selector(startNewSyncDataTimer) onThread:_backgroundThread withObject:nil waitUntilDone:NO];
        }
    }
}
/*
- (BOOL) handleResult
{
    NXFileBase* folder = [NSKeyedUnarchiver unarchiveObjectWithData:_folderBackup];
    
    // check if there are any changes under current folder.
    if ([folder getChildren].count != [_curFolder getChildren].count) {
        return true;
    }
    
    for (NXFileBase* f in [folder getChildren]) {
        
    }
}*/

-(void) startNewSyncDataTimer
{
    @synchronized(self)
    {
        if(_operationType == NXOPERATION_GETFILES) // now use startNewMultiServiceSync to sync filelist
        {
            return;
        }
        [_timer invalidate];
        NSNumber *userInfo = [NSNumber numberWithInteger:_operationType];
        _timer = [NSTimer scheduledTimerWithTimeInterval:SYNCDATA_INTERVAL target:self selector:@selector(syncData:) userInfo:userInfo repeats:NO];
    }
}

-(void) startNewMultiServiceSync
{
    @synchronized(self)
    {
        [_timer invalidate];
       // NSLog(@"***startNewMultiServiceSync");
        _timer = [NSTimer scheduledTimerWithTimeInterval:SYNCDATA_INTERVAL target:self selector:@selector(syncMultiServiceData:) userInfo:nil repeats:NO];
    }
}
#pragma mark -------------------NXServiceOperationDelegate-------------------------

// this function will be invoked in main thread.
- (void) getFilesFinished:(NSArray *)files error:(NSError *)err
{
    if (_operationType == NXOPERATION_GETFILES) { // now get file sync use new delegate , this delegate only for meta data
        return;
    }
    if (self) {
        // There work thread is set exit flag, but the per sdk queue may return getFilesFinished, so we directly return
        return;
    }
    if (self.isSupportMultiService) {
        return;
    }
    
    NSLog(@"getfiles finished");
    if (err.code == NXRMC_ERROR_CODE_CANCEL) {
        NSLog(@"User cancel get file, stop the timer");
        return;
        
    } else {
        // notify ui thread to update
        if (_delegate && [_delegate respondsToSelector:@selector(syncDataUpdateUI:error:)]) {
            [_delegate syncDataUpdateUI: _curFileBase error:err];
        }
    }
    
    // schedule another timer to sync data.
    if (_backgroundThread.isExecuting) {
        [self performSelector:@selector(startNewSyncDataTimer) onThread:_backgroundThread withObject:nil waitUntilDone:NO];
    }
}

-(void)serviceOpt:(id<NXServiceOperation>) serviceOpt getFilesFinished:(NSArray *) files error:(NSError *) err
{
    @synchronized(self) {
        if (self.isPrepareExit) {
            if ([err.domain isEqualToString:NX_ERROR_SERVICEDOMAIN] && err.code == NXRMC_ERROR_CODE_CANCEL) {
                // There work thread is set exit flag, but the per sdk queue may return getFilesFinished, so we directly return
                [self.tempServiceOptArray removeObject:serviceOpt];
                if (self.tempServiceOptArray.count == 0) {
                    _needExit = YES;
                }
            }
            return;
        }
       // NSLog(@"multi-service getFile one back! is %@", serviceOpt);
        if (err.code != NXRMC_ERROR_CODE_CANCEL) {
            if(err)
            {
                self.summaryError = err;
            }
            
            if (files.count > 0) {
                [self.tempFileList addObjectsFromArray:files];
            }
            [self.tempServiceOptArray removeObject:serviceOpt];
            if (self.tempServiceOptArray.count <= 0) { // All service have data back, notify user
                
                if ([self.delegate respondsToSelector:@selector(syncFileListFromServices:WithFileList:Error:)]) {
                    // NSLog(@"Get all file back, notify user!! error is %@", self.summaryError);
                    
                    [self.delegate syncFileListFromServices:self.serviceOptArray WithFileList:self.tempFileList Error:self.summaryError];
                }
                self.summaryError = nil;
                [self.tempFileList removeAllObjects];
                // schedule another timer to sync data.
                if (_backgroundThread.isExecuting) {
                    [self performSelector:@selector(startNewMultiServiceSync) onThread:_backgroundThread withObject:nil waitUntilDone:NO];
                }
            }
        }else
        {
            [self.tempFileList removeAllObjects];
        }

    }
}

-(void)getMetaDataFinished:(NXFileBase*)metaData error:(NSError*)err
{
    if (self.isPrepareExit) {
        _needExit = YES;
        return;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(syncMetaDataUpdateUI:error:)]) {
        [_delegate syncMetaDataUpdateUI:metaData error:err];
    }
    // schedule another timer to sync data.
    if (_backgroundThread.isExecuting) {
        [self performSelector:@selector(startNewSyncDataTimer) onThread:_backgroundThread withObject:nil waitUntilDone:NO];
    }
}


#pragma mark ---------------Add for support multi services sync---------------------

@end
