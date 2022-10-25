//
//  NXSharePoint.m
//  nxrmc
//
//  Created by ShiTeng on 15/5/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXSharePoint.h"
#import "NXSharePointFolder.h"
#import "NXCacheManager.h"
#import "NXKeyChain.h"
#import "NXSharePointFile.h"
#import "NXFileBase+SharePointFileSys.h"
#import "NXCommonUtils.h"

@implementation NXSharePoint

#pragma mark INIT and INSTANCE

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

-(instancetype) initWithUserId:(NSString *)userId
{
    // for sharepoint, we need siteURL, userName, psw to init
    
    //step1. get psw from keychain by userId(siteURL^userName)
    NSString* psw = [NXKeyChain load:userId];
    
    //step2. The format of userId:  siteURL^userName  (^ is illegal character in URL, so use ^ to sperate)
    NSArray* array = [userId componentsSeparatedByString:@"^"];
    NSString* siteURL = array[0];
    NSString* userName = array[1];
    
    return [self initWithSiteURL:siteURL userName:userName passWord:psw];
}
-(instancetype) initWithSiteURL:(NSString*) siteURL userName:(NSString *)userName passWord:(NSString *)psw
{
    if (self = [super init]) {
        _spMgr = [[NXSharePointManager alloc] initWithSiteURL:siteURL userName:userName passWord:psw Type:kSPMgrSharePoint];
        _spMgr.delegate = self;
        _userId = [NSString stringWithFormat:@"%@^%@", siteURL, userName];
        
        
    }
    
    return self;
}
-(void) setSharePointSite:(NSString*) siteURL
{
    if (_spMgr) {
        _spMgr.siteURL = siteURL;
    }
}

#pragma mark ----------NXFileInfo Delegate-----------
-(void) setDelegate: (id) delegate
{
    _delegate = delegate;
}
- (BOOL) isProgressSupported
{
    return YES;
}

- (BOOL) getUserInfo
{
    [_spMgr getCurrentUserInfo];
    return YES;
}

- (BOOL) cancelGetUserInfo
{
    [_spMgr cancelAllQuery];
    return YES;
}

-(BOOL) getFiles:(NXFileBase *)folder
{
    if (!folder || (![folder isKindOfClass:NXFolder.class] && ![folder isKindOfClass:NXSharePointFolder.class])) {
        return NO;
    }
    self.curFolder = folder;
    // Check folder type: 1.root(The init site) 2.site 3.list 4.spfolder
    if (folder.isRoot) {
        [_spMgr allChildItemsOnSite];
        return YES;
    }
    
    if ([folder isMemberOfClass:[NXSharePointFolder class]]) {
        
        NXSharePointFolder* spSharePointFolder = (NXSharePointFolder*) folder;
        
        if (spSharePointFolder.folderType == kSPDocList) {
            // FIRST, we need change spMgr siteURL according to folder ownerSite
            _spMgr.siteURL = spSharePointFolder.ownerSiteURL;
            [_spMgr checkListExistForGetFiles:spSharePointFolder.fullServicePath];
            
           // [_spMgr allChildenItemsInRootFolderInList:spSharePointFolder.fullServicePath];
        }else if(spSharePointFolder.folderType == kSPSite)
        {
            _spMgr.siteURL = spSharePointFolder.fullServicePath;
            [_spMgr checkSiteExistForGetFiles:spSharePointFolder.fullServicePath];
            //[_spMgr allChildItemsOnSite];

        }else if(spSharePointFolder.folderType == kSPNormalFolder)
        {
            _spMgr.siteURL = spSharePointFolder.ownerSiteURL;
            
            [_spMgr checkFolderExistForGetFiles:spSharePointFolder.fullServicePath];
           // [_spMgr allChildItemsInFolder:spSharePointFolder.fullServicePath];
        }
        return YES;
    }
    // will never have folder type, except root folder
    if ([folder isMemberOfClass:[NXFolder class]]) {
        NSLog(@"getFiles can not have foler type!Something is wrong");
        return NO;
    }
    return NO;
}

-(BOOL) cancelGetFiles:(NXFileBase*)folder
{
    if (folder && _curFolder == folder) {
        [_spMgr cancelAllQuery];
    }
    return YES;
}

- (BOOL) downloadFile:(NXFileBase *)file
{
    // url is like
    // Cache/rms_userToken/SharePoint_sid/root/SPserver/sites/site/list/folder/file.txt
    
    if (![file isKindOfClass:[NXSharePointFile class]]) {
        NSLog(@"Not a SPFile, ERROR");
        return NO;
    }
    //// FIRST, we need change spMgr siteURL according to file ownerSite
    NXSharePointFile* spFile = (NXSharePointFile*)file;
    _spMgr.siteURL = spFile.ownerSiteURL;
    
    NSURL* url = [NXCacheManager getLocalUrlForServiceCache:kServiceSharepoint serviceAccountId:_userId];
    url = [url URLByAppendingPathComponent:CACHEROOTDIR isDirectory:NO];
    //url = [url URLByAppendingPathComponent:_spMgr.serverName isDirectory:NO];
    url = [url URLByAppendingPathComponent:file.fullServicePath];
    
    NSString* dest = url.path;
    NSRange range = [dest rangeOfString:@"/" options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
        NSString* dir = [dest substringToIndex:range.location];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:nil] ) {
            [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    
    [self.spMgr downloadFile:spFile fileRelativeURL:file.fullServicePath destPath:dest];

    return YES;
}

- (BOOL) cancelDownloadFile:(NXFileBase *)file
{
    if (![file isKindOfClass:[NXSharePointFile class]]) {
        NSLog(@"Not a SPFile, ERROR");
        return NO;
    }
    //// FIRST, we need change spMgr siteURL according to file ownerSite
    NXSharePointFile* spFile = (NXSharePointFile*)file;
    _spMgr.siteURL = spFile.ownerSiteURL;

    [self.spMgr cancelDownloadFile:spFile];
    return YES;
}
-(BOOL) uploadFile:(NSString*)filename toPath:(NXFileBase*)folder fromPath:(NSString *)srcPath uploadType:(NXUploadType)type overWriteFile:(NXFileBase *)overWriteFile
{
    _curFolder = folder;
     NXSharePointFolder* spSharePointFolder = (NXSharePointFolder*) folder;
    if (spSharePointFolder.folderType == kSPDocList) {
        
        _spMgr.siteURL = spSharePointFolder.ownerSiteURL;
        [self.spMgr uploadFile:filename destFolderRelativeURL:spSharePointFolder.fullServicePath fromPath:srcPath isRootFolder:YES uploadType:type];
        
    }else if(spSharePointFolder.folderType == kSPNormalFolder)
    {
         _spMgr.siteURL = spSharePointFolder.ownerSiteURL;
        [self.spMgr uploadFile:filename destFolderRelativeURL:spSharePointFolder.fullServicePath fromPath:srcPath isRootFolder:NO uploadType:type];
    
    }else
    {
        return NO;
    }
    
    return YES;
}
-(BOOL) cancelUploadFile:(NSString*)filename toPath:(NXFileBase*)folder
{
     [_spMgr cancelAllQuery];
    return YES;
}

-(BOOL)getMetaData:(NXFileBase *)file
{
    if (![file isKindOfClass:[NXSharePointFile class]] && ![file isKindOfClass:[NXSharePointFolder class]]) {
        NSLog(@"Error! getMetaData is not a sharepoint file or Folder!");
        return NO;
    }
    
    self.spMgr.siteURL = ((NXSharePointFile*)file).ownerSiteURL;
    
    if ([file isKindOfClass:[NXSharePointFile class]]) {
        [self.spMgr queryFileMetaData:file.fullServicePath];
    }else if([file isKindOfClass:[NXSharePointFolder class]]){
        
        SPFolderType folderType = ((NXSharePointFolder*) file).folderType;
        switch (folderType) {
            case kSPNormalFolder:
                [self.spMgr queryFolderMetaData:file.fullServicePath];
                break;
            case kSPDocList:
                [self.spMgr queryListMetaData:file.fullServicePath];
                break;
            case kSPSite:
                [self.spMgr querySiteMetaData:file.fullServicePath];
                break;
        }
    }
    
    return YES;
}

-(BOOL) cancelGetMetaData:(NXFileBase*)file
{
    if (file) {
        [_spMgr cancelAllQuery];
    }
    return YES;
}

#pragma mark NXSharePointManagerDelegate
-(void) didFinishSPQuery:(NSArray*) result forQuery:(SPQueryIdentify) type
{
    if (type < kSPQueryGetFilesEnd) {
        NSMutableArray* nxFileArray = [[NSMutableArray alloc] init];
        
        for (NSDictionary* dicNode in result) {
            NXSharePointFolder* spFolder = nil;
            NXSharePointFile* spFile = nil;
            // step1. check node type
            NSString* nodeType = dicNode[SP_NODE_TYPE];
            
            if ([nodeType isEqualToString:SP_NODE_SITE] || [nodeType isEqualToString:SP_NODE_DOC_LIST] || [nodeType isEqualToString:SP_NODE_FOLDER]) {
                spFolder = [[NXSharePointFolder alloc] init];
                [self fetchFile:spFolder InfoFrom:dicNode];
                
            }else if([nodeType isEqualToString:SP_NODE_FILE])
            {
                spFile = [[NXSharePointFile alloc]init];
                [self fetchFile:spFile InfoFrom:dicNode];
            }
            
            if(spFolder)
            {
                [nxFileArray addObject:spFolder];
                spFolder.parent = self.curFolder;
                ///[self.curFolder addChild:spFolder];
            }
            if (spFile) {
                [nxFileArray addObject:spFile];
                spFile.parent = self.curFolder;
                ///[self.curFolder addChild:spFile];
            }
        }
        [NXCommonUtils updateFolderChildren:_curFolder newChildren:nxFileArray];

        NSMutableArray* mutablrChildren = (NSMutableArray*)[_curFolder getChildren];
        [mutablrChildren sortUsingSelector:@selector(compareItemType:)];
        [self.delegate getFilesFinished:[_curFolder getChildren] error:nil];
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:[_curFolder getChildren] error:nil];
        }

    }
    
    if (type == kSPQueryCheckFolderExistForGetFiles) {
        [_spMgr allChildItemsInFolder:self.curFolder.fullServicePath];
    }
    
    if (type == kSPQueryCheckListExistForGetFiles) {
        [_spMgr allChildenItemsInRootFolderInList:self.curFolder.fullServicePath];
    }
    
    if (type == kSPQueryCheckSiteExistForGetFiles) {
        [_spMgr allChildItemsOnSite];
    }
}

-(void) didFinishSPQueryWithError:(NSError*) error forQuery:(SPQueryIdentify) type
{
    if (type < kSPQueryGetFilesEnd) {
        [self.delegate getFilesFinished:nil error:error];
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:nil error:error];
        }
        
    }else if(type == kSPQueryDownloadFile)
    {
        [self.delegate downloadFileFinished:nil intoPath:nil error:error];
        
    }else if(type == kSPQueryCheckListExistForGetFiles || type == kSPQueryCheckFolderExistForGetFiles || type == kSPQueryCheckSiteExistForGetFiles)
    {
        [self.delegate getFilesFinished:nil error:error];
        
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:nil error:error];
        }
        
    }else if(type == kSPQueryUploadFile || type == kSPQueryGetContextInfo)
    {
        if ([self.delegate respondsToSelector:@selector(uploadFileFinished:fromPath:error:)]) {
            [self.delegate uploadFileFinished:nil fromPath:nil error:error];
        }
    }else if(type ==  kSPQueryGetCurrentUserInfo || type == kSPQueryGetCurrentUserDetailInfo)
    {
        if ([self.delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
            [self.delegate getUserInfoFinished:nil userEmail:nil totalQuota:nil usedQuota:nil error:error];
        }
    }
}

-(void) didDownloadFile:(NSString*) fileName filePath:(NSString*) fileURL storePath:(NSString*) destPath
{
    
    [self.delegate downloadFileFinished:fileURL intoPath:destPath error:nil];
}

-(void) didUploadFileFinished:(NSString *)servicePath fromPath:(NSString *)localCachePath fileInfo:(NSDictionary *)uploadedFileInfo error:(NSError *)err {
    if (!err) {
        
        NXFileBase *overWriteFile;
        //for sharepoint online and sharepoint, uploadfile will overwrite if same file(it mean same name) exist. so we should delete old file.
        for (NXFileBase * child in [_curFolder getChildren] ) {
            if ([servicePath isEqualToString: child.fullServicePath]) {
//                [_curFolder removeChild:child];
                overWriteFile = child;
                break;
            }
        }
        if (overWriteFile) {
            [self fetchFile:overWriteFile InfoFrom:uploadedFileInfo];
            [self cacheNewUploadFile:overWriteFile sourcePath:localCachePath];
        } else {
            NXSharePointFile *uploadedFile = [[NXSharePointFile alloc] init];
            [self fetchFile:uploadedFile InfoFrom:uploadedFileInfo];
            uploadedFile.parent = _curFolder;
            [_curFolder addChild:uploadedFile];
            [self cacheNewUploadFile:uploadedFile sourcePath:localCachePath];
        }
        
    }
    
    [self.delegate uploadFileFinished:servicePath fromPath:localCachePath error:err];
}

-(void) didAuthenticationFail:(NSError*) error forQuery:(SPQueryIdentify) type
{
    if (type < kSPQueryGetFilesEnd) {
        [self.delegate getFilesFinished:nil error:error];
        if (_delegate && [_delegate respondsToSelector:@selector(serviceOpt:getFilesFinished:error:)]) {
            [_delegate serviceOpt:self getFilesFinished:nil error:error];
        }
        
    }else if(type == kSPQueryDownloadFile)
    {
        [self.delegate downloadFileFinished:nil intoPath:nil error:error];
    }

}
-(void) didFinishSPQueryFileMetaData:(NSDictionary*) result error:(NSError*) error forQuery:(SPQueryIdentify) type
{
    
    if (error) {
        
        [self.delegate getMetaDataFinished:nil error:error];
        
    }else
    {
        if (type == kSPQueryListMetaData || type == kSPQuerySiteMetaData || type == kSPQueryFolderMetaData) {
            NXSharePointFolder* spFolder = [[NXSharePointFolder alloc] init];
            [self fetchFile:spFolder InfoFrom:result];
            [self.delegate getMetaDataFinished:(NXFileBase *)spFolder error:nil];

        }else if(type == kSPQueryFileMetaData)
        {
            NXSharePointFile* spFile = [[NXSharePointFile alloc] init];
            [self fetchFile:spFile InfoFrom:result];
            [self.delegate getMetaDataFinished:(NXFileBase *)spFile error:nil];
        }else
        {
            NSLog(@"Error!!!! Sharepoint getmetadata from error query type");
        }
        
    }
}
-(void) updataDownloadProcess:(CGFloat)progress forFile:(NSString*) filePath
{
    [self.delegate downloadFileProgress:progress forFile:filePath];
}
-(void) didAuthenticationSuccess
{
}

-(void) didFinishGetUserInfoQUery:(NSDictionary *) result error:(NSError *) error
{
    if ([self.delegate respondsToSelector:@selector(getUserInfoFinished:userEmail:totalQuota:usedQuota:error:)]) {
         [self.delegate getUserInfoFinished:result[SP_TITLE_TAG] userEmail:result[SP_EMAIL_TAG] totalQuota:result[SP_STORAGE_TAG] usedQuota:result[SP_STORAGE_USED_TAG] error:error];
    }
}

#pragma mark Fetch SPQuery Resutl
-(void) fetchFile:(NXFileBase*) file InfoFrom:(NSDictionary*) dicNode
{
    NSString* nodeType = dicNode[SP_NODE_TYPE];
    
    if ([nodeType isEqualToString:SP_NODE_SITE]) {
        file.name = dicNode[SP_TITLE_TAG];
        file.fullServicePath = dicNode[SP_URL_TAG];
        file.fullPath = dicNode[SP_SERV_RELT_URL_TAG];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        NSDate* lastModifydate = [dateFormatter dateFromString:dicNode[SP_CREATED_TAG]];
        NSString *lastModifydateString = [NSDateFormatter localizedStringFromDate:lastModifydate
                                                                        dateStyle:NSDateFormatterShortStyle
                                                                        timeStyle:NSDateFormatterFullStyle];
        file.lastModifiedDate = lastModifydate;
        file.lastModifiedTime = lastModifydateString;
        ((NXSharePointFolder*)file).ownerSiteURL = _spMgr.siteURL;
        ((NXSharePointFolder*)file).folderType = kSPSite;
        
    }else if([nodeType isEqualToString:SP_NODE_DOC_LIST]){
        
        file.name = dicNode[SP_TITLE_TAG];
        file.fullServicePath = dicNode[SP_ID_TAG];
       
        file.fullPath = dicNode[SP_PARENT_WEB_URL];
        
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate* lastModifydate = [dateFormatter dateFromString:dicNode[SP_CREATED_TAG]];
        NSString *lastModifydateString = [NSDateFormatter localizedStringFromDate:lastModifydate
                                                                        dateStyle:NSDateFormatterShortStyle
                                                                        timeStyle:NSDateFormatterFullStyle];
        file.lastModifiedDate = lastModifydate;
        file.lastModifiedTime = lastModifydateString;
        ((NXSharePointFolder*)file).folderType =kSPDocList;
        ((NXSharePointFolder*)file).ownerSiteURL = _spMgr.siteURL;
        
    }else if ([nodeType isEqualToString:SP_NODE_FOLDER]){
        file.name = dicNode[SP_NAME_TAG];
        file.fullServicePath = dicNode[SP_SERV_RELT_URL_TAG];
        file.fullPath = dicNode[SP_SERV_RELT_URL_TAG];
        ((NXSharePointFolder*)file).folderType = kSPNormalFolder;
        ((NXSharePointFolder*)file).ownerSiteURL = _spMgr.siteURL;
        
    }else if([nodeType isEqualToString:SP_NODE_FILE])
    {
        file.name = dicNode[SP_NAME_TAG];
        file.fullServicePath = dicNode[SP_SERV_RELT_URL_TAG];
        file.fullPath = dicNode[SP_SERV_RELT_URL_TAG];
        file.size = [dicNode[SP_FILE_SIZE_TAG] longLongValue];
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate* lastModifydate = [dateFormatter dateFromString:dicNode[SP_TIME_LAST_MODIFY]];
        NSString *lastModifydateString = [NSDateFormatter localizedStringFromDate:lastModifydate
                                                                        dateStyle:NSDateFormatterShortStyle
                                                                        timeStyle:NSDateFormatterFullStyle];
        file.lastModifiedDate = lastModifydate;
        ((NXSharePointFolder*)file).lastModifiedTime = lastModifydateString;
        ((NXSharePointFolder*)file).ownerSiteURL = _spMgr.siteURL;
    }
    file.serviceAccountId = _userId;
    if ([self isMemberOfClass:[NXSharePoint class]]) {
        
        file.serviceType = [NSNumber numberWithInteger:kServiceSharepoint];
        
    }else
    {
        file.serviceType = [NSNumber numberWithInteger:kServiceSharepointOnline];
    }
    
    file.serviceAlias = [self getServiceAlias];
    
    
}

- (BOOL)cacheNewUploadFile:(NXFileBase *) uploadFile sourcePath:(NSString *)srcpath {
    
    NSURL *url = [NXCacheManager getLocalUrlForServiceCache:kServiceSharepoint serviceAccountId:_userId];
    
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
        NSLog(@"Sharepoint service cache file %@ failed", localPath);
    }
    
    return YES;
}

@end
