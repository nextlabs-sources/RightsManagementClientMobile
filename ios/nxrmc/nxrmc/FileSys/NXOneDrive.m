//
//  NXOneDrive.m
//  nxrmc
//
//  Created by helpdesk on 27/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXOneDrive.h"
#import "NXOneDriveCallBack.h"
#ifdef APPLE_DEV_HD
#import "../nxrmc_hd/AppDelegate.h"
#else
#import "../nxrmc/AppDelegate.h"
#endif
#import "NXFolder.h"
#import "NXFile.h"
#import "NXCacheManager.h"

#import "NXRMCDef.h"
#import "NXCommonUtils.h"

//define get info
#define NXONEDRIVE_ME @"me"
#define NXONEDRIVE_ROOT @"me/skydrive"
#define NXONEDRIVE_FILES @"files"
#define NXONEDRIVE_CONTENT @"content"

//noe drive file attribute
#define NXONEDRIVE_TYPE @"type"
#define NXONEDRIVE_NAME @"name"
#define NXONEDRIVE_SIZE @"size"
#define NXONEDRIVE_UPDATE_TIME @"updated_time"
#define NXONEDRIVE_ID @"id"

//one drive file type
#define NXONEDRIVE_ALBUM @"album"
#define NXONEDRIVE_FOLDER @"folder"


typedef NS_ENUM(NSInteger, USERSTATE)
{
    USERSTATE_UNSET = 0,
    USERSTATE_GETFILES,
    USERSTATE_DOWNLOADFILE,
    USERSTATE_UPLOADFILE,
    USERSTATE_GETMETADATA,
    USERSTATE_GET_USER_INFO,
    USERSTATE_GET_REPO_QUOTA,
};

typedef NS_ENUM(NSInteger, ONEDRIVE_ERRORCODE)
{
    ONEDRIVE_ERRORCODE_CANCEL = 1,
    ONEDRIVE_ERRORCODE_NOTFOUND= 5,
};


@interface NXOneDrive ()
{
    LiveConnectClient *_liveClient;
    NSString* _userID;
    
    NXFileBase* _curFileBase;
    
    NSString* _uploadFileName;
    NSString* _uploadSrcFilePath;
    NXFileBase *_overWriteFile; ////this used to store file which will be replace when upload file for type :NXUploadTypeOverWrite, if other type , this parameter is nil.
}
@property (nonatomic, weak) id delegate;
@property (nonatomic, weak) LiveOperation *liveOperation;
@property (nonatomic, weak) AppDelegate *app;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSNumber *totalQuota;
@property (nonatomic, strong) NSNumber *usedQuota;
@property (nonatomic, weak) NXOneDriveCallBack *oneDriveCallBack;
@end

@implementation NXOneDrive

-(NSString *) getServiceAlias
{
    return [NXCommonUtils serviceAliasByServiceType:self.boundService.service_type.integerValue ServiceAccountId:self.boundService.service_account_id];
}

-(void) setAlias:(NSString *) alias
{
    _alias = alias;
}

-(void) setLiveOperation:(LiveOperation *)liveOperation
{
    _liveOperation = liveOperation;
    if (liveOperation) {
        [self.oneDriveCallBack addOneDriveOperator:self operationKey:liveOperation];
        [self.oneDriveCallBack addOneDriveOperation:liveOperation];
    }
}

-(void) setBoundService:(NXBoundService *) boundService
{
    _boundService = boundService;
}

-(NXBoundService *) getOptBoundService
{
    return _boundService;
}

-(id) init
{
    if(self = [super init])
    {
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        self.app = app;

        _liveClient = app.liveClient;
        _oneDriveCallBack = [NXOneDriveCallBack sharedInstance];
    }
    return self;
}

- (id) initWithUserId: (NSString *)userId
{
    if(self = [super init])
    {
        if(self = [self init])
        {
            _userID = userId;
        }
    }
    return self;
}

- (void)dealloc
{
    
}

#pragma mark NXFilesInfo
-(BOOL) getFiles:(NXFileBase*)folder
{
    if(!folder || ![folder isKindOfClass:[NXFolder class]])
    {
        return NO;
    }
    
    _curFileBase = folder;
    if(folder.isRoot)
    {
        folder.fullPath = @"/";
        folder.fullServicePath = NXONEDRIVE_ROOT;
    }

    self.liveOperation = [_liveClient getWithPath:[NSString stringWithFormat:@"%@/%@", folder.fullServicePath, NXONEDRIVE_FILES]
                                         delegate:self.oneDriveCallBack
                                        userState:[NSNumber numberWithInteger:USERSTATE_GETFILES]];
    return (self.liveOperation ? YES : NO);
}

-(BOOL) downloadFile:(NXFileBase*)file
{
    if(!file || ![file isKindOfClass:NXFile.class])
    {
        return NO;
    }
    
    _curFileBase = file;
    
    self.liveOperation = [_liveClient downloadFromPath:[NSString stringWithFormat:@"%@/%@",file.fullServicePath, NXONEDRIVE_CONTENT]
                                              delegate:self.oneDriveCallBack
                                             userState:[NSNumber numberWithInteger:USERSTATE_DOWNLOADFILE]];
    
    return (self.liveOperation ? YES : NO);
}

-(BOOL) uploadFile:(NSString*)filename toPath:(NXFileBase*)folder fromPath:(NSString *)srcPath uploadType:(NXUploadType)type overWriteFile:(NXFileBase *)overWriteFile
{
    if(!filename || !srcPath || ![folder isKindOfClass:NXFolder.class])
    {
        return NO;
    }
    _uploadFileName = filename;
    _uploadSrcFilePath = srcPath;
    _curFileBase = folder;
    NSData *fileToUpload = [[NSData alloc]initWithContentsOfFile:srcPath];
    if (type == NXUploadTypeOverWrite) {
        _overWriteFile = overWriteFile;
        self.liveOperation = [_liveClient uploadToPath:folder.fullServicePath
                                              fileName:filename
                                                  data:fileToUpload
                                             overwrite:LiveUploadOverwrite
                                              delegate:self.oneDriveCallBack
                                             userState:[NSNumber numberWithInteger:USERSTATE_UPLOADFILE]];
    } else if (type == NXUploadTypeNormal) {
        _overWriteFile = nil;
        self.liveOperation = [_liveClient uploadToPath:folder.fullServicePath
                                              fileName:filename
                                                  data:fileToUpload
                                             overwrite:LiveUploadRename
                                              delegate:self.oneDriveCallBack
                                             userState:[NSNumber numberWithInteger:USERSTATE_UPLOADFILE]];
    }
    
    return (self.liveOperation ? YES : NO);
}

-(BOOL)getMetaData:(NXFileBase *)file
{
    if(!file || ![file isKindOfClass:NXFileBase.class])
    {
        return NO;
    }
    _curFileBase = file;
    self.liveOperation = [_liveClient getWithPath:file.fullServicePath
                                             delegate:self.oneDriveCallBack
                                            userState:[NSNumber numberWithInteger:USERSTATE_GETMETADATA]];
    return (self.liveOperation ? YES : NO);
}

-(BOOL) cancelDownloadFile:(NXFileBase*)path
{
    [self cancel:path];
    return YES;
}

-(BOOL) cancelUploadFile:(NSString*)filename toPath:(NXFileBase*)folder
{
    [self cancel:folder];
    return YES;
}

-(BOOL) cancelGetFiles:(NXFileBase*)folder
{
    [self cancel:folder];
    return YES;
}

-(BOOL) cancelGetMetaData:(NXFileBase*)file
{
    [self cancel:file];
    return YES;
}

-(void) setDelegate: (id) delegate
{
    _delegate = delegate;
}

-(BOOL) isProgressSupported
{
    return YES;
}

- (BOOL) getUserInfo
{
    self.userEmail = nil;
    self.userName = nil;
    self.usedQuota = nil;
    self.totalQuota = nil;
    
    self.liveOperation = [_liveClient getWithPath:@"me"
                                         delegate:self.oneDriveCallBack
                                        userState:[NSNumber numberWithInteger:USERSTATE_GET_USER_INFO]];
    
    [self getUserQuota];
    return (self.liveOperation ? YES : NO);
}

- (BOOL) cancelGetUserInfo
{
    [self.liveOperation cancel];
    return YES;
}

#pragma mark LiveOperationDelegate
- (void) liveOperationSucceeded:(LiveOperation *)operation
{
    NSInteger userState = [(NSNumber*)operation.userState integerValue];
    NSLog(@"liveOperationSucceeded, userState = %li",(long)userState);
    switch (userState) {
        case USERSTATE_GETFILES:
            {
                NSArray *data = [operation.result valueForKey:@"data"];
                dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^(void)
                               {
                                   [self getFilesFinished:data];
                               });
            }
            break;
        case USERSTATE_DOWNLOADFILE:
            {
                NSData *data = ((LiveDownloadOperation*)operation).data;
                dispatch_queue_t globalQueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^(void)
                               {
                                   [self downloadFileFinished:data];
                               });
            }
            break;
        case USERSTATE_UPLOADFILE:
            {
                NSDictionary *result = operation.result;
                [self uploadFileFinished:result];
            }
            break;
        case USERSTATE_GETMETADATA:
            {
                NSDictionary *result = operation.result;
                [self getMetaDataFinished:result];
            }
            break;
        case USERSTATE_GET_USER_INFO:
            {
                
                NSDictionary *result = operation.result;
                self.userName = result[@"name"];
                self.userEmail = result[@"emails"][@"preferred"];
                //[self getUserQuota];
                if (self.totalQuota && self.usedQuota) {
                    if ([self.delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
                        [self.delegate getUserInfoFinished:self.userName userEmail:self.userEmail totalQuota:self.totalQuota usedQuota:self.usedQuota error:nil];
                        
                    }

                }
            }
            break;
        case USERSTATE_GET_REPO_QUOTA:
        {
            NSDictionary *result = operation.result;
            self.totalQuota = result[@"quota"];
            NSNumber *available = result[@"available"];
            long long used = [self.totalQuota longLongValue] - [available longLongValue];
            self.usedQuota = [NSNumber numberWithLongLong:used];
            if (self.userName && self.userEmail) {
                if ([self.delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
                    [self.delegate getUserInfoFinished:self.userName userEmail:self.userEmail totalQuota:self.totalQuota usedQuota:self.usedQuota error:nil];
                }
            }
        }
            break;
        case USERSTATE_UNSET:
            break;
        default:
            break;
    }
}

- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation*)operation
{
    NSInteger userState = [(NSNumber*)operation.userState integerValue];
    NSLog(@"liveOperationFailed userState = %li",(long)userState);
    switch ([operation.userState integerValue]) {
        case USERSTATE_GETFILES:
            {
                NSError *err = [self onedriveError2NXError:error];
                if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)])
                {
                    [_delegate getFilesFinished:nil error:err];
                }
                
                if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
                    [_delegate serviceOpt:self getFilesFinished:nil error:err];
                }
            }
            break;
        case USERSTATE_DOWNLOADFILE:
            {
                NSError *err = [self onedriveError2NXError:error];
                if(err.code != NXRMC_ERROR_CODE_CANCEL)
                {
                    if([_delegate respondsToSelector:@selector(downloadFileFinished:intoPath:error:)])
                    {
                        [_delegate downloadFileFinished:_curFileBase.fullServicePath intoPath:nil error: err];
                    }
                }
            }
            break;
        case USERSTATE_UPLOADFILE:
            {
                NSError *err = [self onedriveError2NXError:error];
                if(err.code != NXRMC_ERROR_CODE_CANCEL)
                {
                    if(_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)])
                    {
                        [_delegate uploadFileFinished:nil fromPath:_uploadSrcFilePath error:err];
                    }
                }
            }
            break;
        case USERSTATE_GETMETADATA:
            {
                NSError *err = [self onedriveError2NXError:error];
                if(_delegate && [_delegate respondsToSelector:@selector(getMetaDataFinished: error:)])
                {
                    dispatch_queue_t mainQueue= dispatch_get_main_queue();
                    dispatch_async(mainQueue, ^{
                        [_delegate getMetaDataFinished:nil error:err];
                    });

                }
            }
            break;
        case USERSTATE_GET_USER_INFO:
            {
                if ([_delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
                    [_delegate getUserInfoFinished:nil userEmail:nil totalQuota:nil usedQuota:nil error:error];
                }
            }
            break;
        case USERSTATE_GET_REPO_QUOTA:
        {
            if ([_delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
                [_delegate getUserInfoFinished:nil userEmail:nil totalQuota:nil usedQuota:nil error:error];
            }
        }
            break;
        case USERSTATE_UNSET:
        default:
            break;
    }
}

#pragma mark LiveDownloadOperationDelegate
- (void) liveDownloadOperationProgressed:(LiveOperationProgress *)progress
                                    data:(NSData *)receivedData
                               operation:(LiveDownloadOperation *)operation
{
    NSLog(@"File: %@ download prograss %f",_curFileBase.fullPath, progress.progressPercentage);
    if (_delegate && [_delegate respondsToSelector:@selector(downloadFileProgress:forFile:)]) {
        [_delegate downloadFileProgress:progress.progressPercentage forFile:_curFileBase.fullServicePath];
    }
}

#pragma  mark LiveUploadOperationDelegate
- (void) liveUploadOperationProgressed:(LiveOperationProgress *)progress
                             operation:(LiveOperation *)operation
{
    NSLog(@"File: %@ upload prograss %f",operation.path, progress.progressPercentage);
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFileProgress:forFile:fromPath:)]) {
        [_delegate uploadFileProgress:progress.progressPercentage forFile:_uploadFileName fromPath:_uploadSrcFilePath];
    }
}

-(void)getFilesFinished:(NSArray*)data
{
    NSMutableArray *fileList = [NSMutableArray array];
    for(NSDictionary* fileData in data)
    {
        NXFileBase *file = nil;
        NSString *fileType = [fileData valueForKeyPath:NXONEDRIVE_TYPE];
        BOOL isFolder = [self isFolder:fileType];
        if(isFolder)
        {
            file = [[NXFolder alloc]init];
        }
        else
        {
            file = [[NXFile alloc]init];
        }
        [self fetchFileInfo:file andFileData:fileData];
        [fileList addObject:file];
    }

    [NXCommonUtils updateFolderChildren:_curFileBase newChildren:fileList];
    
    if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
        dispatch_queue_t mainQueue= dispatch_get_main_queue();
        dispatch_sync(mainQueue, ^{
            [_delegate getFilesFinished:[_curFileBase getChildren] error:nil];
        });
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
        dispatch_queue_t mainQueue= dispatch_get_main_queue();
        dispatch_sync(mainQueue, ^{
            [_delegate serviceOpt:self getFilesFinished:[_curFileBase getChildren] error:nil];

        });
    }
}

#pragma mark private method
-(void)downloadFileFinished:(NSData*)data
{
    NSURL* url = [NXCacheManager getLocalUrlForServiceCache:kServiceOneDrive serviceAccountId:_userID];
    url = [url URLByAppendingPathComponent:CACHEROOTDIR isDirectory:NO];
    url = [url URLByAppendingPathComponent:_curFileBase.fullPath];
    
    NSString *cachePath = [url.path stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:nil])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSError *error = nil;
    [data writeToURL:url options:NSDataWritingAtomic error:&error];
    
    if([_delegate respondsToSelector:@selector(downloadFileFinished:intoPath:error:)])
    {
        dispatch_queue_t mainQueue= dispatch_get_main_queue();
        dispatch_sync(mainQueue, ^{
            [_delegate downloadFileFinished:_curFileBase.fullServicePath intoPath:url.path error: error];
        });
    }
}

-(void)uploadFileFinished:(NSDictionary*)result
{
    _uploadFileName = result[NXONEDRIVE_NAME];
    NSString *fullpath = [_curFileBase.fullPath stringByAppendingPathComponent:_uploadFileName];
    
    NXFileBase *file;
    
    if (_overWriteFile) {
        file = _overWriteFile;
    } else {
        file = [[NXFile alloc]init];
        file.parent = _curFileBase;
    }
    
    file.name = _uploadFileName;
    file.fullPath = fullpath;
    file.fullServicePath = result[NXONEDRIVE_ID];
    file.serviceAccountId = _userID;
    file.serviceAlias = [self getServiceAlias];
    file.serviceType = [NSNumber numberWithInteger:kServiceOneDrive];
    
    // only all file property is set, add it to file tree.
    if (!_overWriteFile) {
        [_curFileBase addChild:file];
    }

    
    [self cacheNewUploadFile:file sourcePath:_uploadSrcFilePath];
    
    if(_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)])
    {
        [_delegate uploadFileFinished:file.fullServicePath fromPath:_uploadSrcFilePath error:nil];
    }
}

-(void)getMetaDataFinished:(NSDictionary*)result
{
    NXFileBase *metaData = [[NXFileBase alloc]init];
    [self fetchFileInfo:metaData andFileData:result];
    if(_delegate && [_delegate respondsToSelector:@selector(getMetaDataFinished: error:)])
    {
        dispatch_queue_t mainQueue= dispatch_get_main_queue();
        dispatch_async(mainQueue, ^{
            [_delegate getMetaDataFinished:metaData error:nil];
        });
    }
}

-(void)fetchFileInfo:(NXFileBase*)file andFileData:(NSDictionary*)fileData
{
    NSString *name = [fileData valueForKeyPath:NXONEDRIVE_NAME];
    file.name = name;
    file.fullPath = [_curFileBase.fullPath stringByAppendingPathComponent:name];
    NSString *fileID = [fileData valueForKey:NXONEDRIVE_ID];
    file.fullServicePath = fileID;
    NSString *size = [fileData valueForKeyPath:NXONEDRIVE_SIZE];
    file.size = [size integerValue];
    NSString *updateTime = [fileData valueForKeyPath:NXONEDRIVE_UPDATE_TIME];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZ"];
    NSDate* lastModifydate = [dateFormatter dateFromString:updateTime];
    NSString *lastModifydateString = [NSDateFormatter localizedStringFromDate:lastModifydate
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterFullStyle];

    file.lastModifiedDate = lastModifydate;
    file.lastModifiedTime = lastModifydateString;
    file.serviceAccountId = _userID;
    file.serviceType = [NSNumber numberWithInteger:kServiceOneDrive];
    file.parent = _curFileBase;
    file.serviceAlias = [self getServiceAlias];
}

- (BOOL)cacheNewUploadFile:(NXFileBase *) uploadFile sourcePath:(NSString *)srcpath {
    
    NSURL *url = [NXCacheManager getLocalUrlForServiceCache:kServiceOneDrive serviceAccountId:_userID];
    
    NSString *localPath = [[[url path] stringByAppendingPathComponent:CACHEROOTDIR] stringByAppendingPathComponent:uploadFile.fullPath];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    if ([manager fileExistsAtPath:localPath]) {
        [manager removeItemAtPath:localPath error:&error];
    }
    
    BOOL ret = [manager moveItemAtPath:srcpath toPath:localPath error:&error];
    if (ret) {
        [NXCommonUtils storeCacheFileIntoCoreData:uploadFile cachePath:localPath];
        [NXCommonUtils setLocalFileLastModifiedDate:localPath date:uploadFile.lastModifiedDate];
    } else {
        NSLog(@"OneDrive service cache file %@ failed", localPath);
    }
    
    return YES;
}

-(NSError*)onedriveError2NXError:(NSError*) onedriveError
{
    NSError *err = onedriveError;
    if(onedriveError.code == ONEDRIVE_ERRORCODE_CANCEL)  //user cancel this operation
    {
        err = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_CANCEL userInfo:nil];
    }
    else if (onedriveError.code == ONEDRIVE_ERRORCODE_NOTFOUND)
    {
        if (_liveClient.session.accessToken == nil) { // means the APP Access permission is delete by user
            err = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED error:err];
            
        }else
        {
            err = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:err];
        }
    }else if (err.code < 0 && err.code != NSURLErrorCancelled)
    {
        err = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:err];
    }
    return err;
}

//do cancel opetation
-(void)cancel:(NXFileBase*)f
{
    if(self.liveOperation && f == _curFileBase)
    {
        [self.liveOperation cancel];
    }
}

- (BOOL) getUserQuota
{
    self.liveOperation = [_liveClient getWithPath:@"me/skydrive/quota"
                                         delegate:self.oneDriveCallBack
                                        userState:[NSNumber numberWithInteger:USERSTATE_GET_REPO_QUOTA]];
    return (self.liveOperation ? YES : NO);

}

#pragma mark judge filesys if is a folder or file
-(BOOL)isFolder:(NSString *)file
{
    if([file isEqualToString:NXONEDRIVE_ALBUM] || [file isEqualToString:NXONEDRIVE_FOLDER])
    {
        return YES;
    }
    return NO;
}

#pragma mark show alertview,when operation failed
- (void)showAlertView{
    UIAlertView* view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message: NSLocalizedString(@"ERROR_NOT_SIGNIN_ONEDRIVE", NULL) delegate:NULL cancelButtonTitle:NSLocalizedString(@"BOX_OK", NULL) otherButtonTitles:NULL, nil];
    [view show];
}

@end
