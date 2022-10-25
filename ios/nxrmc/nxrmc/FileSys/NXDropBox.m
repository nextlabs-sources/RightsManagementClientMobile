//
//  NXDropBox.m
//  nxrmc
//
//  Created by Kevin on 15/5/11.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXDropBox.h"

#import "NXFolder.h"
#import "NXFile.h"
#import "NXCacheManager.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"

#define  GETMEDADATA  "getMedaData"

static const NSString* kFile = @"kFile";
static const NSString* kError = @"kError";

static NSString *const kKeyDropBoxRev = @"NXDropBoxRev";

typedef NS_ENUM(NSInteger, DROPBOX_REPLY)
{
    DROPBOX_REPLY_GETMEDADATA = 1,
};

typedef NS_ENUM(NSInteger, DROPBOXERRORCODE)
{
    DROPBOXERRORCODENOTFOUND = 404,
};


#pragma mark - class NXDropboxResponse

@interface NXDropboxResponse : NSObject
@property (nonatomic, strong) NSObject *object;
@end

#pragma mark - class NXDropBoxFile

@interface NXDropBoxFile : NXFile
@property (nonatomic, copy) NSString *rev;
@end

#pragma mark - class NXDropBox

@interface NXDropBox() <DBRestClientDelegate>
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) DBRestClient *MedaDataClient;
@property (nonatomic, strong) NXDropboxResponse *response;
@end

@implementation NXDropBox

-(NSString *) getServiceAlias
{
    return [NXCommonUtils serviceAliasByServiceType:self.boundService.service_type.integerValue ServiceAccountId:self.boundService.service_account_id];
}

-(void) setAlias:(NSString *) alias
{
    _alias = alias;
}

-(void) setBoundService:(NXBoundService *) boundService
{
    _boundService = boundService;
}

-(NXBoundService *) getOptBoundService
{
    return _boundService;
}

- (id) init {
    
    return nil;
}


- (id) initWithUserId: (NSString *)userId
{
    if (self = [super init]) {
        _response = [NXDropboxResponse alloc];
        _response.object = self;
        
        NXBoundService *boundService = [NXCommonUtils getBoundServiceFromCoreData:userId];
        NSArray *tokens = [boundService.service_account_token componentsSeparatedByString:NXSYNC_REPO_SPERATE_KEY];
        NSString *accessToken = tokens[0];
        NSString *accessTokenSecret = tokens[1];
        [[DBSession sharedSession] updateAccessToken:accessToken accessTokenSecret:accessTokenSecret forUserId:userId];

        if([[DBSession sharedSession] isLinked])
        {
            _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:userId];
            _isLinked = YES;
            _restClient.delegate = self;
            _userId = userId;
        }
        else
        {
            _restClient = nil;
            _isLinked = NO;
            _restClient.delegate =self;
        }
    }
    
    return self;

}

- (void)showAlertView{
    UIAlertView* view = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message: NSLocalizedString(@"ERROR_NOT_LINKIN_DROPBOX", NULL) delegate:NULL cancelButtonTitle:NSLocalizedString(@"BOX_OK", NULL) otherButtonTitles:NULL, nil];
    [view show];
}

- (void)setDelegate:(id)delegate {
    _delegate = delegate;
}

- (void) handleReplyId:(NSInteger)replyid data:(NSData*)data error:(NSError *) error
{
    if (replyid == DROPBOX_REPLY_GETMEDADATA) {
        DBMetadata *metadata = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NXFileBase* file = nil;
        if (metadata) {
            if (metadata.isDeleted) {
                error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:error];
            }  else {
                if (metadata.isDirectory) {
                    file = [[NXFolder alloc] init];
                } else {
                    file = [[NXDropBoxFile alloc] init];
                }
                [self fetchFileInfo:file MetaData:metadata];
            }
        }
        if (_delegate && [_delegate respondsToSelector:@selector(getMetaDataFinished:error:)]) {
            [_delegate getMetaDataFinished:file error:error];
        }
    }
}

#pragma mark - NXServiceOperation

- (BOOL)getFiles:(NXFileBase *)folder
{
    if (!folder || ![folder isKindOfClass:NXFolder.class]) {
        return NO;
    }
    
    if (_isLinked) {
        if (folder.isRoot) {
            folder.fullPath = @"/";
            folder.fullServicePath = @"/";
        }
        
        [_restClient loadMetadata:folder.fullServicePath];
        _curFolder = folder;
    }
    else
    {
        [self showAlertView];
        return NO;
    }
    
    return YES;
}

-(BOOL) cancelGetFiles:(NXFileBase*)folder
{
    if (_isLinked) {
        [_restClient cancelAllRequests];
        NSError *error = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_CANCEL userInfo:nil];
        if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
            [_delegate getFilesFinished:nil error:error];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:nil error:error];
        }
        return YES;
    }
    return NO;
}

- (BOOL)downloadFile:(NXFileBase*) file{
    NSURL* url = [NXCacheManager getLocalUrlForServiceCache:kServiceDropbox serviceAccountId:_userId];
    url = [url URLByAppendingPathComponent:CACHEROOTDIR isDirectory:NO];
    url = [url URLByAppendingPathComponent:file.fullPath];
    
    NSString* dest = url.path;
    NSRange range = [dest rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        NSString* dir = [dest substringToIndex:range.location];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:nil] ) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    if (_isLinked) {
        [_restClient loadFile:file.fullServicePath intoPath:dest];
    }
    else
    {
        [self showAlertView];
        return NO;
    }
    return YES;
}

- (BOOL)cancelDownloadFile:(NXFileBase *)file {
    if (_isLinked) {
        [_restClient cancelFileLoad:file.fullServicePath];
    }
    else
    {
        [self showAlertView];
        return NO;
    }
    return YES;
}

-(BOOL)getMetaData:(NXFileBase *)file
{
    if (_isLinked) {
        _MedaDataClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:_userId];
        _MedaDataClient.delegate = (id)_response;
        [_MedaDataClient loadMetadata:file.fullServicePath];
    } else {
        [self showAlertView];
        return NO;
    }
    return YES;
}

- (BOOL)cancelGetMetaData:(NXFileBase *)file {
    [_MedaDataClient cancelAllRequests];
    if (_delegate && [_delegate respondsToSelector:@selector(getMetaData:)]) {
        NSError *error = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_CANCEL userInfo:nil];
        [_delegate getMetaDataFinished:file error:error];
    }
    return YES;
}

- (BOOL) isProgressSupported {
    return YES;
}

- (BOOL) uploadFile:(NSString *)filename toPath:(NXFileBase*)folder fromPath:(NSString *)srcPath uploadType:(NXUploadType)type overWriteFile:(NXFileBase *)overWriteFile {
    
    if (_isLinked) {
        _curFolder = folder;
        if (type == NXUploadTypeOverWrite) {
            _overWriteFile = overWriteFile;
            if ([overWriteFile isKindOfClass:[NXDropBoxFile class]]) {
                _overWriteFile = overWriteFile;
            }
            [_restClient uploadFile:filename toPath:folder.fullServicePath withParentRev:((NXDropBoxFile*)overWriteFile).rev fromPath:srcPath];
        } else {
            _overWriteFile = nil;
            [_restClient uploadFile:filename toPath:folder.fullServicePath withParentRev: nil fromPath:srcPath];
        }
    }
    else
    {
        [self showAlertView];
        return NO;
    }
    return YES;
}

-(BOOL) cancelUploadFile:(NSString *)filename toPath:(NXFileBase *)folder
{
    if (_isLinked) {
        NSString* dropboxPath = [NSString stringWithFormat:@"%@/%@", folder.fullServicePath, filename];
        [_restClient cancelFileUpload:dropboxPath];
    }
    else
    {
        [self showAlertView];
        return NO;
    }
    return YES;
}

-(BOOL) getUserInfo
{
    if(_isLinked)
    {
        [_restClient loadAccountInfo];
        
    }else
    {
        return NO;
    }
    return YES;
}

-(BOOL) cancelGetUserInfo
{
    if (_isLinked) {
        [_restClient cancelAllRequests];
    }
    return YES;
}



#pragma mark - DBRestClientDelegate

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    NSMutableArray *filelist = [NSMutableArray array];
    
    NSDate* now = [NSDate date];
    for (DBMetadata *file in metadata.contents){
        NXFileBase *f = nil;
        if (file.isDirectory) {
            f = [[NXFolder alloc] init];
        }
        else {  // is file
            f = [[NXDropBoxFile alloc] init];
            f.refreshDate = now;
        }
        [self fetchFileInfo:f MetaData:file];
        f.parent = _curFolder;
        [filelist addObject:f];
    }
    [NXCommonUtils updateFolderChildren:_curFolder newChildren:filelist];
    
    if (metadata.isDeleted) {
        NSError *error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:nil];
        if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
            [_delegate getFilesFinished:nil error:error];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:nil error:error];
        }
        
    } else {
        if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
            [_delegate getFilesFinished:[_curFolder getChildren] error:nil];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:[_curFolder getChildren] error:nil];
        }
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    error = [self convertErrorIntoNXError:error];
    if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
        [_delegate getFilesFinished:nil error:error];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
        [_delegate serviceOpt:self getFilesFinished:nil error:error];
    }
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSLog(@"File %@ download into path:%@", localPath, contentType);
    NSString* filepath = metadata.path;
    
    if (_delegate && [_delegate respondsToSelector:@selector(downloadFileFinished:intoPath:error:)]) {
        [_delegate downloadFileFinished:filepath intoPath:localPath error:nil];
    }
}

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath{
    NSLog(@"File: %@ download prograss prograss %f",destPath, progress);
    
    if (_delegate && [_delegate respondsToSelector:@selector(downloadFileProgress:forFile:)]) {
        [_delegate downloadFileProgress:progress forFile:destPath];
    }
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"Error download file %@", error);
    
    NSDictionary *userinfo =  error.userInfo;
    NSString *path = [userinfo objectForKey:@"path"];
    NSString *destPath = [userinfo objectForKey:@"destinationPath"];
    NSError *rmcError;
    if (error.code == DROPBOXERRORCODENOTFOUND) {
        
         rmcError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:error];
        
    }else if(error.code < 0 && error.code != NSURLErrorCancelled) // NSURL Load error
    {
        rmcError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error] ;
    }else {
        rmcError = [self convertErrorIntoNXError:error];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(downloadFileFinished:intoPath:error:)]) {
        [_delegate downloadFileFinished:path intoPath:destPath error:rmcError];
    }
}

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
          metadata:(DBMetadata*)metadata {
    
    NXFileBase* uploadedfile = [[NXDropBoxFile alloc] init];
    if (_overWriteFile) {
        [self fetchFileInfo:_overWriteFile MetaData:metadata];
        [self cacheNewUploadFile:_overWriteFile sourcePath:srcPath];
        if (_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
            [_delegate uploadFileFinished: _overWriteFile.fullServicePath fromPath:srcPath error:nil];
        }
    } else {
        [self fetchFileInfo:uploadedfile MetaData:metadata];
        [self cacheNewUploadFile:uploadedfile sourcePath:srcPath];
        //add new uploaded file into FileSys cache.
        uploadedfile.parent = _curFolder;
        [_curFolder addChild:uploadedfile];
        if (_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
            [_delegate uploadFileFinished: uploadedfile.fullServicePath fromPath:srcPath error:nil];
        }
    }
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath {
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFileProgress:forFile:fromPath:)]) {
        [_delegate uploadFileProgress:progress forFile:destPath fromPath:srcPath];
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error{
    NSLog(@"%@", error.localizedDescription);
    NSDictionary *userInfo = error.userInfo;
    NSString *path = [userInfo objectForKey:@"sourcePath"];
    NSString *destPath = [userInfo objectForKey:@"destinationPath"];
    if (error.code < 0 && error.code != NSURLErrorCancelled) {
        error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error];
    }else
    {
        error = [self convertErrorIntoNXError:error];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
        [_delegate uploadFileFinished:destPath fromPath:path error:error];
    }
}

- (BOOL)cacheNewUploadFile:(NXFileBase *) uploadFile sourcePath:(NSString *)srcpath {
    
    NSURL *url = [NXCacheManager getLocalUrlForServiceCache:kServiceDropbox serviceAccountId:_userId];
    
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
        NSLog(@"Dropbox service cache file %@ failed", localPath);
    }
    
    return YES;
}

- (void) fetchFileInfo:(NXFileBase *)file MetaData:(DBMetadata *) metaData {
    if ([file isKindOfClass:[NXDropBoxFile class]]) {
        ((NXDropBoxFile*)file).rev = metaData.rev;
    }
    file.fullPath = metaData.path;
    file.fullServicePath = metaData.path;
    NSString *dateString = [NSDateFormatter localizedStringFromDate:metaData.lastModifiedDate
                                                          dateStyle:NSDateFormatterShortStyle
                                                         timeStyle:NSDateFormatterFullStyle];
    
    file.lastModifiedDate = metaData.lastModifiedDate;
    file.lastModifiedTime = dateString;
    file.size = metaData.totalBytes;
    file.name = metaData.filename;
    file.isRoot = NO;
    file.serviceAccountId = _userId;
    file.serviceType = [NSNumber numberWithInteger:kServiceDropbox];
    file.serviceAlias = [self getServiceAlias];
}

- (void) restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    if ([self.delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
        [self.delegate getUserInfoFinished:info.displayName userEmail:info.email totalQuota:[NSNumber numberWithLongLong:info.quota.totalBytes] usedQuota:[NSNumber numberWithLongLong:info.quota.totalConsumedBytes] error:nil];
    }
}

- (void)restClient:(DBRestClient*)client loadAccountInfoFailedWithError:(NSError*)error
{
    if ([self.delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
        [self.delegate getUserInfoFinished:nil userEmail:nil totalQuota:nil usedQuota:nil error:error];
    }
}

#pragma mark - Private method
- (NSError *) convertErrorIntoNXError:(NSError *) error
{
    if (error == nil) {
        return nil;
    }
    if (error.code == 401) {
        error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED error:error];
    }
    
    if (error.code < 0 && error.code != NSURLErrorCancelled) {
        error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error] ;
    }
    
    return error;
}

@end

#pragma mark - NXDropboxResponse

@implementation NXDropboxResponse

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata
{
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:metadata];
    [(NXDropBox*)_object handleReplyId:DROPBOX_REPLY_GETMEDADATA data:data error:nil];
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error
{
    [(NXDropBox*)_object handleReplyId:DROPBOX_REPLY_GETMEDADATA data:nil error:error];
}

@end

#pragma mark - NXDropBoxFile

@implementation NXDropBoxFile

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_rev forKey:kKeyDropBoxRev];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _rev = [aDecoder decodeObjectForKey:kKeyDropBoxRev];
    }
    return self;
}

@end
