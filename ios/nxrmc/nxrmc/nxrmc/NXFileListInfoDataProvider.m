//
//  NXFileListInfoDataProvider.m
//  nxrmc
//
//  Created by EShi on 10/14/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//


#import "NXFileListInfoDataProvider.h"
#import "NXCacheManager.h"
typedef id<NXServiceOperation> NXServiceOpt;
@interface NXFileListInfoDataProvider()<NXServiceOperationDelegate>
@property(nonatomic, strong) NSMutableArray *serviceArray;
@property(nonatomic, strong) NSMutableArray *currentOptServiceArray;
@property(nonatomic, strong) NSMutableArray *fileInfoLists;
@property(nonatomic, strong) NXServiceOpt serviceOpt;
@property(nonatomic, strong) NXSyncData *syncData;
@property(nonatomic, strong) NSMutableDictionary *folderDict;
@property(nonatomic, strong) NSArray *fileListTemp;
@property(nonatomic, strong) NSMutableDictionary *additionalInfo;  // used to record error from multi-service
@end

@implementation NXFileListInfoDataProvider
#pragma mark public interface
-(void) getFileByServices:(NSArray *)services folders:(NSMutableDictionary *) foldersDict needReadCache:(BOOL) needReadCache
{
    // clear all caches
    [self.fileInfoLists removeAllObjects];
    
    // init var
    self.serviceArray = [services mutableCopy];
    self.folderDict = foldersDict;
    
    for (NXBoundService* service in self.serviceArray) {
        // step1. check root service, if have children, means have cache, we do not need get from net,
        // it will update by sync
        if (needReadCache) {
            NSString *key = [self getServiceKeyForFolderDirectory:service];
            NXFileBase *folder = foldersDict[key];
            self.curFolder = folder;
            if ([folder getChildren].count > 0) { // have cache, just store cache file
                [self.fileInfoLists addObjectsFromArray:[folder getChildren]];
            }else                               // do not have cache, store service in currentOptServiceArray to do getFile from net
            {
                if (![self.currentOptServiceArray containsObject:service] && service.service_isAuthed.boolValue == YES) {
                    [self.currentOptServiceArray addObject:service];
                }
            }
        }else
        {
            if (![self.currentOptServiceArray containsObject:service] && service.service_isAuthed.boolValue == YES) {
                [self.currentOptServiceArray addObject:service];
            }
        }
       
    }
    
    if (self.currentOptServiceArray.count > 0) {
       
        if ([[NXNetworkHelper sharedInstance] isNetworkAvailable]) {
            self.serviceOpt = [NXCommonUtils createServiceOperation:(NXBoundService*)self.currentOptServiceArray.firstObject];
            NSString *key = [self getServiceKeyForFolderDirectory:(NXBoundService*)self.currentOptServiceArray.firstObject];
            NXFileBase *folder = foldersDict[key];
            [self getFileListFromServiceOpt:self.serviceOpt WithFolder:folder];
            
        }else
        {   // net is not ok, just return
            NSError *error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_NO_NETWORK error:nil];
            [self notifyDelegateGetFileListDone:self.fileInfoLists error:error];
        }
        
    }else
    {
        [self notifyDelegateGetFileListDone:self.fileInfoLists error:nil];
    }
}

-(void) getFilesByService:(NXBoundService *) service Folder:(NXFileBase *) folder needReadCache:(BOOL) needReadCache
{
    NSArray* serviceArray = @[service];
    NSMutableDictionary *folders = [[NSMutableDictionary alloc] init];
    NSString* key = [self getServiceKeyForFolderDirectory:service];
    [folders setObject:folder forKey:key];
    [self getFileByServices:serviceArray folders:folders needReadCache:needReadCache];
}

-(void) syncFileByServices:(NSArray *)services withFolders:(NSMutableDictionary *) foldersDict
{
    self.serviceArray = [services mutableCopy];;
    [self.fileInfoLists removeAllObjects];
    self.folderDict = foldersDict;
    // Translate NXBoundServie to NXServiceOpt
    NSMutableArray * serviceOptArray = [[NSMutableArray alloc] init];
    for (NXBoundService *service in services) {
        if (service.service_isAuthed.boolValue == YES) {
            id<NXServiceOperation> serviceOpt = [NXCommonUtils createServiceOperation:(NXBoundService*)service];
            if (serviceOpt != nil) {
                [serviceOptArray addObject:serviceOpt];
            }
        }
    }
    if (serviceOptArray.count == 0) {
        return;
    }
    _syncData = [[NXSyncData alloc] init];
    _syncData.delegate = self;
    [_syncData startServicesSync:serviceOptArray withFolders:foldersDict];
}

-(void) syncFileByServices:(NSArray *)services withFolder:(NXFileBase *) folder
{
    // if have only one folder to update, it means now is not root folder, means only one service need to update
    NXBoundService *boundService = services.firstObject;
    NSString *key = [self getServiceKeyForFolderDirectory:boundService];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:folder forKey:key];
    [self syncFileByServices:services withFolders:dic];
}

-(void) cancelSyncFileList
{
    NSLog(@"FileListDataProvider cancel %@", self.syncData);
    [self.syncData cancelMultiServiceSync];
}

-(BOOL) cancelServiceGetFiles
{
    return [self.serviceOpt cancelGetFiles:self.curFolder];
}

#pragma mark private method
-(void) getFileListFromServiceOpt:(NXServiceOpt) serviceOpt WithFolder:(NXFileBase *) folder
{
    if (serviceOpt == nil) {
        [self getFilesFinished:nil error:nil];
        return;
    }
    [serviceOpt setDelegate:self];
    self.curFolder = folder;
    BOOL ret = [serviceOpt getFiles:folder];
    if (ret == NO) {
        [self getFilesFinished:nil error:nil];
    }
}

-(void) notifyDelegateGetFileListDone:(NSArray *) files error:(NSError *) err
{
    self.fileListTemp = [files copy];
    NSDictionary *additionalInfo = [self.additionalInfo copy];
    if ([self.delegate respondsToSelector:@selector(fileListInfo:InServices:Folders:error:fromDataProvider:additionalInfo:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
              [self.delegate fileListInfo:self.fileListTemp InServices:self.serviceArray Folders:self.folderDict error:err fromDataProvider:self additionalInfo:additionalInfo];
        });
      
    }
    [self.additionalInfo removeAllObjects];
}

-(void) notifyDelegateUpdateData:(NSArray *) files error:(NSError *) err
{
    self.fileListTemp = [files copy];
    if ([self.delegate respondsToSelector:@selector(updateFileList:InServices:Folders:error:fromDataProvider:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate updateFileList:self.fileListTemp InServices:self.serviceArray Folders:self.folderDict error:err fromDataProvider:self];
        });
    }
    
   // [self.additionalInfo removeAllObjects];
    
}

#pragma mark SETTER/GETTER
-(NSMutableArray *) serviceArray
{
    if (_serviceArray == nil) {
        _serviceArray = [[NSMutableArray alloc] init];
    }
    return _serviceArray;
}

-(NSMutableDictionary *) additionalInfo
{
    if (_additionalInfo == nil) {
        _additionalInfo = [[NSMutableDictionary alloc] init];
    }
    
    return _additionalInfo;
}

-(NSMutableArray *) currentOptServiceArray
{
    if (_currentOptServiceArray == nil) {
        _currentOptServiceArray = [[NSMutableArray alloc] init];
    }
    return _currentOptServiceArray;
}

-(NSMutableArray *) fileInfoLists
{
    if (_fileInfoLists == nil) {
        _fileInfoLists = [[NSMutableArray alloc] init];
    }
    return _fileInfoLists;
}

-(NSMutableDictionary *) folderDict
{
    if (_folderDict == nil) {
        _folderDict = [[NSMutableDictionary alloc] init];
    }
    return _folderDict;
}



#pragma mark NXServiceOperationDelegate
-(void)getFilesFinished:(NSArray*) files error: (NSError*)err
{
    if (self.currentOptServiceArray.count) {
        NXBoundService *curService = self.currentOptServiceArray.firstObject;
        if (err) {
            // record error service alias to show in file list error dialog
            if (curService.service_account_id) { // check if curService is still exist, if not exist, do not need add error info
                [self.additionalInfo setValue:curService.service_alias forKey:curService.service_alias];
            }
        }
        
        [self.currentOptServiceArray removeObjectAtIndex:0];
        [self.fileInfoLists addObjectsFromArray:files];
        
        curService = [self.currentOptServiceArray firstObject];
        if (curService) {
            self.serviceOpt = [NXCommonUtils createServiceOperation:curService];
            NSString *key = [self getServiceKeyForFolderDirectory:curService];
            NXFolder *folder = self.folderDict[key];
            [self getFileListFromServiceOpt:self.serviceOpt WithFolder:folder];
            
        }else
        {
            
            [self notifyDelegateGetFileListDone:self.fileInfoLists error:err];
            self.serviceOpt = nil;
        }
        
        // after first get
    }else // logic error
    {
      //  abort();
    }
}

-(void)downloadFileFinished:(NSString*) servicePath intoPath:(NSString*)localCachePath error:(NSError*)err
{}

-(void)downloadFileProgress:(CGFloat) progress forFile:(NSString*)servicePath
{}

-(void)uploadFileFinished:(NSString*)servicePath fromPath:(NSString*)localCachePath error:(NSError*)err
{}
-(void)uploadFileProgress:(CGFloat)progress forFile:(NSString*)servicePath fromPath:(NSString*)localCachePath
{}

-(void)getMetaDataFinished:(NXFileBase*)metaData error:(NSError*)err
{}

#pragma mark NXSyncDataDelegate
- (void) syncFileListFromServices:(NSArray *) services WithFileList:(NSArray *) fileList Error:(NSError *) error
{
    [self notifyDelegateUpdateData:fileList error:error];
}

#pragma mark tool functions
-(NSString * ) getServiceKeyForFolderDirectory:(NXBoundService *) boundService
{
    return [NXCommonUtils getServiceFolderKeyForFolderDirectory:boundService];
}

@end
