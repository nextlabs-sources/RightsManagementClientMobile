//
//  NXGoogleDrive.m
//  nxrmc
//
//  Created by nextlabs on 8/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXGoogleDrive.h"

#import "GTLDrive.h"
#import "GTMOAuth2Authentication.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "NXFile.h"
#import "NXFolder.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"
#import "NXCacheManager.h"
#import "NXCommonUtils.h"

static NSString *const kKeyGoogleDriveFileURL       = @"NXGoogleDriveFileDownloadURL";
static NSString *const kKeyGoogleDriveRoot          = @"root";

static NSString *const kKeyGetFiles                 = @"getfiles";
static NSString *const kKeyDownloadFile             = @"downloadfile";
static NSString *const kKeyDonwloadDstPath          = @"downloadDstPath";
static NSString *const kKeyUploadFileDstPath        = @"uploadfiledstpath";
static NSString *const kKeyUploadFileFolder         = @"uploadfilefolder";
static NSString *const kKeyUploadFileSrcPath        = @"uploadfilesrcpath";
static NSString *const kKeyUploadFileOverWriteFile  = @"uploadfileOverWriteFile";
static NSString *const kKeyGetMetaData              = @"getmetadata";

static NSString *const kGoogleDriveFolderMimetype   = @"application/vnd.google-apps.folder";

#pragma mark -  NXGoogleDriveFile -

@implementation NXGoogleDriveFile

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_downloadURL forKey:kKeyGoogleDriveFileURL];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _downloadURL = [aDecoder decodeObjectForKey:kKeyGoogleDriveFileURL];
    }
    return self;
}

@end

#pragma mark - class NXGoogleDrive -

@interface NXGoogleDrive()
{
    GTLServiceDrive *_driveService;
    NSString *_userId;
    BOOL _isLinked;
    GTLServiceTicket *_getUserInfoTicket;
    
    NSMutableDictionary *_listFilesTickets;
    NSMutableDictionary *_downFileTickets;
    NSMutableDictionary *_uploadFileTickets;
    NSMutableDictionary *_metaDataTickets;
}

@property(nonatomic, weak)id<NXServiceOperationDelegate> delegate;

@end

@implementation NXGoogleDrive

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

- (instancetype) initWithUserId:(NSString *)userId {
    if (self = [super init]) {
        NSError *error;
        _userId = userId;
        _driveService = [[GTLServiceDrive alloc] init];
        _boundService = [NXCommonUtils getBoundServiceFromCoreData:userId];
        _driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:_boundService.service_account_token clientID:GOOGLEDRIVECLIENTID clientSecret:GOOGLEDRIVECLIENTSECRET error:&error];
        if (_driveService.authorizer.canAuthorize) {
            NSLog(@"Google Drive Authentication successed");
            _isLinked = YES;
            _listFilesTickets = [[NSMutableDictionary alloc] init];
            _downFileTickets = [[NSMutableDictionary alloc] init];
            _uploadFileTickets  = [[NSMutableDictionary alloc] init];
            _metaDataTickets = [[NSMutableDictionary alloc] init];
        } else {
            NSLog(@"Google Drive Authentication failed");
            _isLinked = NO;
        }
    }
    return self;
}

#pragma mark - NXServiceOperation

- (BOOL) getFiles:(NXFileBase *)folder {
    if (!folder || ![folder isKindOfClass:[NXFolder class]]) {
        return NO;
    }
    
    if([folder isRoot]) {
        folder.fullPath = @"/";
        folder.fullServicePath = kKeyGoogleDriveRoot;
    }
    
    // the max file default is 100, it means if count is > 100, it will only list 100.
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"trashed = false and '%@' IN parents", folder.fullServicePath];
    _driveService.shouldFetchNextPages = YES;
    GTLServiceTicket *fileTicket = [_driveService executeQuery:query delegate:self didFinishSelector:@selector(getFilesFinishedwithTicket:fileList:error:)];
    fileTicket.properties = [NSDictionary dictionaryWithObjectsAndKeys:folder, kKeyGetFiles, nil];
    if (fileTicket) {
        [_listFilesTickets setObject:fileTicket forKey:folder.fullServicePath];
    }
    return  YES;
}

- (BOOL) cancelGetFiles:(NXFileBase *)folder {
    GTLServiceTicket *fileTicket =  [_listFilesTickets objectForKey:folder.fullServicePath];
    if (!fileTicket) {
        return  NO;
    }
    [fileTicket cancelTicket];
    [_listFilesTickets removeObjectForKey:folder.fullServicePath];
    
    NSError *error = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_CANCEL userInfo:nil];
    if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
        [_delegate getFilesFinished:nil error:error];
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
        [_delegate serviceOpt:self getFilesFinished:nil error:error];
    }
    return YES;
}

- (BOOL) downloadFile:(NXFileBase *)file {
    if (![file isKindOfClass:[NXGoogleDriveFile class]]) {
        return NO;
    }
    NXGoogleDriveFile *googleDriveFile = (NXGoogleDriveFile*)file;
    GTMBridgeFetcher *fetcher = [_driveService.fetcherService fetcherWithURLString:googleDriveFile.downloadURL];
    if (!fetcher) {
        //if download url is nil. fetcher is nil.
        return NO;
    }
    
    NSURL* url = [NXCacheManager getLocalUrlForServiceCache:kServiceGoogleDrive serviceAccountId:_userId];
    url = [url URLByAppendingPathComponent:CACHEROOTDIR isDirectory:NO];
    if ([file isKindOfClass:[NXFile class]]) {
        url = [url URLByAppendingPathComponent:file.parent.fullPath];
        url = [[url URLByAppendingPathComponent:file.fullServicePath] URLByAppendingPathComponent:file.name];
    } else {
        NSLog(@"You are download a folder. please do not do that");
    }
    
    NSString *cachePath = [url.path stringByDeletingLastPathComponent];
    if(![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:nil]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSMutableDictionary *property = [[NSMutableDictionary alloc] initWithObjectsAndKeys:file, kKeyDownloadFile,url.path, kKeyDonwloadDstPath, nil];
    fetcher.properties = property;
    [fetcher beginFetchWithDelegate:self didFinishSelector:@selector(downLoadFinishedwithFetch: data: error:)];
    if (fetcher) {
        [_downFileTickets setObject:fetcher forKey:googleDriveFile.downloadURL];
    }
    return YES;
}

- (BOOL) cancelDownloadFile:(NXFileBase *)file {
    if (![file isKindOfClass:[NXGoogleDriveFile class]]) {
        return NO;
    }
    
    NXGoogleDriveFile *googleDriveFile = (NXGoogleDriveFile*)file;
    GTMBridgeFetcher *fetcher = [_downFileTickets objectForKey:googleDriveFile.downloadURL];
    if (!fetcher) {
        return NO;
    }
    [fetcher stopFetching];
    [_downFileTickets removeObjectForKey:googleDriveFile.downloadURL];
    return YES;
}

- (BOOL) uploadFile:(NSString *)filename toPath:(NXFileBase *)folder fromPath:(NSString *)srcPath uploadType:(NXUploadType)type overWriteFile:(NXFileBase *)overWriteFile {
    
    NSString *mimeType = [NXCommonUtils getMiMeType:srcPath];
    NSData *data = [NSData dataWithContentsOfFile:srcPath];
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:mimeType];
    GTLDriveParentReference *parentRef = [GTLDriveParentReference object];
    parentRef.identifier = folder.fullServicePath;
    
    GTLDriveFile *metaData = [GTLDriveFile object];
    metaData.title = filename;
    metaData.parents = @[parentRef];
    
    GTLQueryDrive *query = nil;
    if (type == NXUploadTypeNormal) {
        
        query = [GTLQueryDrive queryForFilesInsertWithObject:metaData uploadParameters:uploadParameters];
        
        
    } else if (type == NXUploadTypeOverWrite) {
        query = [GTLQueryDrive queryForFilesUpdateWithObject:metaData fileId:overWriteFile.fullServicePath uploadParameters:uploadParameters];
    }
    
    [_driveService setUploadProgressSelector:@selector(uploadProgresswithticket: totalBytesUpload: expectedUpload:)];
    if (query == nil) {
        return NO;
    }
    GTLServiceTicket *uploadTicket = [_driveService executeQuery:query
                                                        delegate:self
                                               didFinishSelector:@selector(uploadFileFinishedwithTicket:file:error:)];
    NSString *destPath = [folder.fullPath stringByAppendingPathComponent:filename];
    uploadTicket.properties = [NSDictionary dictionaryWithObjectsAndKeys:folder,kKeyUploadFileFolder,srcPath, kKeyUploadFileSrcPath, destPath, kKeyUploadFileDstPath,overWriteFile,kKeyUploadFileOverWriteFile, nil];
    if (uploadTicket) {
        [_uploadFileTickets setObject:uploadTicket forKey:[folder.fullPath stringByAppendingPathComponent:filename]];
    }
    return YES;
}

- (BOOL) cancelUploadFile:(NSString *)filename toPath:(NXFileBase *)folder {
    GTLServiceTicket *ticket = [_uploadFileTickets  objectForKey:[folder.fullPath stringByAppendingPathComponent:filename]];
    if (!ticket) {
        return NO;
    }
    [ticket cancelTicket];
    [_uploadFileTickets removeObjectForKey:[folder.fullPath stringByAppendingPathComponent:filename]];
    return YES;
}

- (BOOL) getMetaData:(NXFileBase *)file {
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesGetWithFileId:file.fullServicePath];
    GTLServiceTicket *ticket = [_driveService executeQuery:query
                                                  delegate:self
                                         didFinishSelector:@selector(getMetaDataFinishedwithTicket:file:error:)];
    ticket.properties = [NSDictionary dictionaryWithObjectsAndKeys:file, kKeyGetMetaData, nil];
    if (ticket) {
        [_metaDataTickets setObject:ticket forKey:file.fullServicePath];
    }
    return  YES;
}

- (BOOL) cancelGetMetaData:(NXFileBase *)file {
    GTLServiceTicket *ticket = [_metaDataTickets objectForKey:file.fullServicePath];
    if (!ticket) {
        return NO;
    }
    [ticket cancelTicket];
    [_metaDataTickets removeObjectForKey:file.fullServicePath];
    return YES;
}

- (void) setDelegate:(id)delegate {
    _delegate = delegate;
}

- (BOOL) isProgressSupported {
    return NO;
}

-(BOOL) getUserInfo
{
    GTLQueryDrive *query = [GTLQueryDrive queryForAboutGet];
    _getUserInfoTicket = [_driveService executeQuery:query
                                                  delegate:self
                                         didFinishSelector:@selector(getUserInfoWithTicket:info:error:)];
    if (!_getUserInfoTicket) {
        return NO;
    }
    
    return YES;
}

-(BOOL) cancelGetUserInfo
{
    [_getUserInfoTicket cancelTicket];
    return YES;
}

#pragma mark - GoogleDrive operaton Delegate

- (void)getFilesFinishedwithTicket:(GTLServiceTicket *)ticket fileList:(GTLDriveFileList *)fileList error:(NSError *)error {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSDictionary *property = ticket.properties;
    NXFileBase *folder = [property objectForKey:kKeyGetFiles];
    if (error == nil) {
        for (GTLDriveFile *file in fileList) {
            if ([file.explicitlyTrashed boolValue] == YES) {
                continue;
            }
            NXFileBase *nxfile = nil;
            if ([file.mimeType isEqualToString: kGoogleDriveFolderMimetype]) {
                nxfile = [[NXFolder alloc] init];
            } else {
                nxfile = [[NXGoogleDriveFile alloc] init];
            }
            [self fetchFile:nxfile fromGoogleDriveFile:file withFileParent:folder];
            nxfile.parent = folder;
            [array addObject:nxfile];
        }
        
        [NXCommonUtils updateFolderChildren:folder newChildren:array];
        
        if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
            [_delegate getFilesFinished:[folder getChildren] error:nil];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:[folder getChildren] error:nil];
        }
        
    } else {
        error = [self convertErrorIntoNXError:error];
        if (_delegate && [_delegate respondsToSelector:@selector(getFilesFinished:error:)]) {
            [_delegate getFilesFinished:nil error:error];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:nil error:error];
        }
        
    }
}

- (void)downLoadFinishedwithFetch:(GTMBridgeFetcher*) fetcher data:(NSData*) data error:(NSError*)error {
    NSDictionary *property = fetcher.properties;
    NXGoogleDriveFile *downloadfile = [property objectForKey:kKeyDownloadFile];
    NSString *srcPath = [property objectForKey:kKeyDonwloadDstPath];
    
    NSError *rmcError;
    if (error) {
        if (error.code == 404) {
            rmcError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:error];
        }else if(error.code < 0 && error.code !=NSURLErrorCancelled)
        {
            rmcError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error];
        }else {
            rmcError = [self convertErrorIntoNXError:error];
        }
    } else {
        BOOL ret = [data writeToFile:srcPath atomically:YES];
        if (!ret) {
            rmcError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_CONVERTFILEFAILED error:nil];
        }
    }
    if (_delegate && [_delegate respondsToSelector:@selector(downloadFileFinished:intoPath:error:)]) {
        [_delegate downloadFileFinished:downloadfile.fullServicePath intoPath:srcPath error:rmcError];
    }
}

- (void)downloadProgresswithFetcher:(GTMBridgeFetcher *)fetcher receivedData:(NSData *)dataReceivedSoFar {
    NSString *dstPath = [fetcher.properties objectForKey:kKeyDonwloadDstPath];
    CGFloat progress = (CGFloat)fetcher.downloadedLength/ fetcher.response.expectedContentLength;
    if (_delegate && [_delegate respondsToSelector:@selector(downloadFileProgress:forFile:)]) {
        [_delegate downloadFileProgress:progress forFile:dstPath];
    }
}

- (void)uploadFileFinishedwithTicket:(GTLServiceTicket *)ticket file:(GTLDriveFile*)file error:(NSError*)error {
    NSDictionary *property = ticket.properties;
    NXFileBase *folder = [property objectForKey:kKeyUploadFileFolder];
    NSString *srcFilePath = [property objectForKey:kKeyUploadFileSrcPath];
    NXFileBase *overWriteFile = [property objectForKey:kKeyUploadFileOverWriteFile];
    NSString *filefullPath = [folder.fullPath stringByAppendingPathComponent:file.title];
    if (error) {
        if (error.code < 0 && error.code != NSURLErrorCancelled) {
            error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error];
        }else{
            error = [self convertErrorIntoNXError:error];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
            [_delegate uploadFileFinished: filefullPath fromPath:srcFilePath error:error];
        }
    } else {
        NXGoogleDriveFile* uploadedfile = [[NXGoogleDriveFile alloc] init];
        if (overWriteFile) {
            [self fetchFile:overWriteFile fromGoogleDriveFile:file withFileParent:folder];
            [self cacheNewUploadFile:overWriteFile sourcePath:srcFilePath];
            if (_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
                [_delegate uploadFileFinished: overWriteFile.fullServicePath fromPath:srcFilePath error:error];
            }
        } else {
            
            [self fetchFile:uploadedfile fromGoogleDriveFile:file withFileParent:folder];
            uploadedfile.parent = folder;
            [folder addChild:uploadedfile];
            [self cacheNewUploadFile:uploadedfile sourcePath:srcFilePath];
            if (_delegate && [_delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
                [_delegate uploadFileFinished: uploadedfile.fullServicePath fromPath:srcFilePath error:error];
            }
        }
    }
}

- (void) uploadProgresswithticket:(GTLServiceTicket*) ticket totalBytesUpload:(unsigned long long)uploadedBytes expectedUpload:(unsigned long long) expectedUploadBytes {

    float progress = (float) uploadedBytes/expectedUploadBytes;
    
    NSDictionary *property = ticket.properties;
    NSString *destFilePath = [property objectForKey:kKeyUploadFileDstPath];
    NSString *srcFilePath = [property objectForKey:kKeyUploadFileSrcPath];
    if (_delegate && [_delegate respondsToSelector:@selector(uploadFileProgress:forFile:fromPath:)]) {
        [_delegate uploadFileProgress:progress forFile:destFilePath fromPath:srcFilePath];
    }
}

- (void) getMetaDataFinishedwithTicket:(GTLServiceTicket*)ticket file:(GTLDriveFile*)file error:(NSError*)error {
    if (error) {
        if (_delegate && [_delegate respondsToSelector:@selector(getMetaDataFinished:error:)]) {
            [_delegate getMetaDataFinished:nil error:error];
        }
    } else {
        NSDictionary *property = ticket.properties;
        NXFileBase *folder = [property objectForKey:kKeyGetMetaData];
        if ([file.explicitlyTrashed boolValue]) {
            NSError *error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:nil];
            if (_delegate && [_delegate respondsToSelector:@selector(getMetaDataFinished:error:)]) {
                [_delegate getMetaDataFinished:nil error:error];
            }
        } else {
            NXFileBase *nxfile = nil;
            if ([file.mimeType isEqualToString:kGoogleDriveFolderMimetype]) {
                nxfile = [[NXFolder alloc] init];
            } else {
                nxfile = [[NXGoogleDriveFile alloc] init];
            }
            [self fetchFile:nxfile fromGoogleDriveFile:file withFileParent:folder];
            //update cache file infomation.
            if (_delegate && [_delegate respondsToSelector:@selector(getMetaDataFinished:error:)]) {
                [_delegate getMetaDataFinished:nxfile error:nil];
            }
        }
    }
}

-(void) getUserInfoWithTicket:(GTLServiceTicket *) ticket info:(GTLDriveAbout *) info error:(NSError *) error
{
    if (!error) {
        NSString *name = info.user.displayName;
        NSString *email = info.user.emailAddress;
        NSNumber *totalQuota = info.quotaBytesTotal;
        NSNumber *usedQuota = info.quotaBytesUsed;
        
        if ([_delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
            [_delegate getUserInfoFinished:name userEmail:email totalQuota:totalQuota usedQuota:usedQuota error:nil];
        }
        
    }else
    {
        if ([_delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
            [_delegate getUserInfoFinished:nil userEmail:nil totalQuota:nil usedQuota:nil error:error];
        }
    }
}

#pragma mark - private method

- (void) fetchFile:(NXFileBase*) nxfilebase fromGoogleDriveFile:(GTLDriveFile*) file withFileParent:(NXFileBase*)parent {
    nxfilebase.name = file.title;
    NSString *fullpath = [parent.fullPath stringByAppendingPathComponent:file.title];
    nxfilebase.fullPath = fullpath;
    nxfilebase.fullServicePath= file.identifier;
    nxfilebase.serviceAccountId = _userId;
    nxfilebase.serviceAlias = [self getServiceAlias];
    if ([nxfilebase isKindOfClass:[NXGoogleDriveFile class]]) {
        if (!file.downloadUrl) {
            GTLDriveFileExportLinks *fileExportLinks;
            NSString *exportFormat = @"application/pdf";
            fileExportLinks = [file exportLinks];
            ((NXGoogleDriveFile*)nxfilebase).downloadURL = [fileExportLinks JSONValueForKey:exportFormat];
        } else {
            ((NXGoogleDriveFile*)nxfilebase).downloadURL= file.downloadUrl;
        }
    }
    
    NSString *dateString = [NSDateFormatter localizedStringFromDate:file.modifiedDate.date
                                                          dateStyle:NSDateFormatterShortStyle
                                                          timeStyle:NSDateFormatterFullStyle];
    
    nxfilebase.lastModifiedDate = file.modifiedDate.date;
    nxfilebase.lastModifiedTime = dateString;
    nxfilebase.size = [file.fileSize longLongValue];
    nxfilebase.serviceType = [NSNumber numberWithInteger:kServiceGoogleDrive];
    nxfilebase.isRoot = NO;
}

- (BOOL) cacheNewUploadFile:(NXFileBase *) uploadFile sourcePath:(NSString *)srcpath {
    
    NSURL *url = [NXCacheManager getLocalUrlForServiceCache:kServiceGoogleDrive serviceAccountId:_userId];
    
    NSString *localPath = [[url.path stringByAppendingPathComponent:CACHEROOTDIR] stringByAppendingPathComponent:[uploadFile.fullPath stringByDeletingLastPathComponent]];
    localPath = [localPath stringByAppendingPathComponent:uploadFile.fullServicePath];
    NSFileManager *manager = [NSFileManager defaultManager];
    //crete new directory for cache new upload file.
    if(![manager fileExistsAtPath:localPath isDirectory:nil]) {
        [manager createDirectoryAtPath:localPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    localPath = [localPath stringByAppendingPathComponent:uploadFile.name];
    NSError *error;
    if ([manager fileExistsAtPath:localPath]) {
        [manager removeItemAtPath:localPath error:&error];
    }
    
    BOOL ret = [manager moveItemAtPath:srcpath toPath:localPath error:&error];
    if (ret) {
        [NXCommonUtils storeCacheFileIntoCoreData:uploadFile cachePath:localPath];
        [NXCommonUtils setLocalFileLastModifiedDate:localPath date:uploadFile.lastModifiedDate];
    } else {
        NSLog(@"GoogleDrive service cache file %@ failed", localPath);
    }
    return ret;
}

- (NSError *) convertErrorIntoNXError:(NSError *) error
{
    if (error == nil) {
        return nil;
    }
    
    if (error.code == 400) {
        if ([error.userInfo[@"json"][@"error"] isEqualToString:@"invalid_grant"]) {
            error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED error:error];
        }
    }else if(error.code == 401 || error.code == 403)
    {
        error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED error:error];
    }else if(error.code < 0 && error.code != NSURLErrorCancelled)
    {
        error = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error];

    }
    
    return error;
}
@end
