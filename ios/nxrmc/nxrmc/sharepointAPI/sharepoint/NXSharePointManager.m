//
//  NXSharePointSDK.m
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/21.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXSharePointManager.h"
#import "NXSharePointXMLParse.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"

typedef void (^RemoteQueryResponseHandler) (NXSharePointRemoteQueryBase* query, NSData* data);



@interface NXSharePointManager()

@property(nonatomic, strong) NSString* user;
@property(nonatomic, strong) NSString* psw;
@property(nonatomic, strong) NSArray *cookies;
// used to tag getAllItems=========beg
// for site, need subsite, doclist
// for list and folder, need subfolders and subfiles
@property(nonatomic) BOOL getAllSiteItems;
@property(nonatomic) BOOL getAllItems;

@property(nonatomic) BOOL getFoldersDatas;
@property(nonatomic) BOOL getFilesDatas;

@property(nonatomic) BOOL getSitesDatas;
@property(nonatomic) BOOL getDocListDatas;

@property(nonatomic, strong) NSMutableArray* allItemsCache;
// used to tag getAllItems=========end

// used to getcontextinfo
@property(nonatomic) BOOL formDigestToUpload;

@property(nonatomic, strong) NSMutableDictionary* remoteQueryResponseHandlers;
@property(nonatomic, strong) NSString* formDigestValue; //To do POST request in Sharepoint, need post formdigest to do user identify
@property(nonatomic, strong) NSMutableArray* curSPQueryArray;
-(void) initRemoteQueryResponseHandler;
@end


@implementation NXSharePointManager
#pragma mark ALLOC and INIT and SETTER/GETTER
- (instancetype) initWithURL:(NSString *)siteURL cookies:(NSArray *)cookies Type:(SPManagerType)type {
    if (self = [super init]) {
        _siteURL = siteURL;
        _cookies = cookies;
        _spMgrType = type;
        [self initRemoteQueryResponseHandler];
        
       
    }
    return  self;
}

-(instancetype) initWithSiteURL:(NSString*) siteURL userName:(NSString*) userName passWord:(NSString*) psw Type:(SPManagerType) type
{
    if (self = [super init]) {
        _siteURL = siteURL;
        _user = userName;
        _psw = psw;
        _spMgrType = type;
        
        // siteURL is like 'https://pf1-w12-sps06/sites/spe/tyy/Forms/AllItems.aspx'
        // so servername is siteURLcontent[2];
        NSArray* siteURLcontent  = [siteURL componentsSeparatedByString:@"/"];
        if(siteURLcontent.count >= 3)
        {
             _serverName = siteURLcontent[2];
        }
       
        [self initRemoteQueryResponseHandler];
    }
    return self;
}
-(NSMutableArray*) curSPQueryArray
{
    if (!_curSPQueryArray) {
        _curSPQueryArray = [[NSMutableArray alloc] init];
    }
    return _curSPQueryArray;
}

-(void) initRemoteQueryResponseHandler
{
    __weak NXSharePointManager *weakself = self;
    
    RemoteQueryResponseHandler getAllDoclibListsHandler = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSArray* result = [NXSharePointXMLParse parseGetDocLibLists:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:result forQuery:kSPQueryGetAllDocLists];
    };
    
    RemoteQueryResponseHandler getAllChildrenFoldersHandler = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSArray* result = [NXSharePointXMLParse parseGetChildFolders:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:result forQuery:kSPQueryGetAllChildFilesInFolder];
    };
    
    RemoteQueryResponseHandler getAllChildrenFilesHandler = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSArray* result = [NXSharePointXMLParse parseGetChildFiles:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:result forQuery:kSPQueryGetAllChildFilesInFolder];
      
    };
    
    RemoteQueryResponseHandler getAllChildrenFoldersInRootFolderHandler = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSArray* result = [NXSharePointXMLParse parseGetChildFolders:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:result forQuery:kSPQueryGetAllChildFoldersInRootFolder];
    };
    
    RemoteQueryResponseHandler getAllChildrenFilesInRootFolderHandler = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSArray* result = [NXSharePointXMLParse parseGetChildFiles:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:result forQuery:kSPQueryGetAllChildFilesInRootFolder];
       
    };
    
    RemoteQueryResponseHandler getAllChildrenSites = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSArray* result = [NXSharePointXMLParse parseGetChildSites:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:result forQuery:kSPQueryGetAllChildSites];
        
    };
    
    RemoteQueryResponseHandler downloadFile = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        // 1. first get append data:FileName and destpath
        NSDictionary* appendDic = (NSDictionary*)query.additionData;
        NSString* fileName = appendDic[SP_DICTION_TAG_FILE_NAME];
        NSString* destPath = appendDic[SP_DICTION_TAG_DEST_PATH];
        NSString* fileRevURL = appendDic[SP_DICTION_TAG_FILE_REV_URL];
        
        // 2. convert data to file and store in dest path
        NSFileManager* fm = [NSFileManager defaultManager];
        [fm createFileAtPath:destPath contents:data attributes:nil];
        
        // 3. notify delegate
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didDownloadFile:fileName filePath:fileRevURL storePath:destPath];
    
        
    };
    
    RemoteQueryResponseHandler authentication = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        // notify delegate
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didAuthenticationSuccess];
    };
    
    RemoteQueryResponseHandler getContextInfo = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        // 1. parse data get formdigest
        NSArray* result = [NXSharePointXMLParse parseContextInfo:data];
        // 2. update formdigest
        NSDictionary* dic = result.firstObject;
        _formDigestValue = [dic valueForKey:SP_FORM_DIGEST_TAG];
        
        // 3. check appendDic
        NSDictionary* appendDic = (NSDictionary*)query.additionData;
        
        NSNumber* rqNum = appendDic[SP_DICTION_TAG_REQ_TYPE];
        NSInteger rqType = [rqNum integerValue];
        
        // 4. according rqType, call different method
        switch (rqType) {
            case kSPQueryUploadFile:
            {
                NSString* fileName = appendDic[SP_DICTION_TAG_FILE_NAME];
                NSString* folderURL = appendDic[SP_DICTION_TAG_FOLDER_REV_URL];
                NSString* fileSrcPath = appendDic[SP_DICTION_TAG_FILE_SRC_PATH];
                NSString* isRootFolder = appendDic[SP_DICTION_TAG_IS_ROOT_FOLDER];
                NSNumber *uploadType = appendDic[SP_DICTION_TAG_UPLOAD_TYPE];
                if ([isRootFolder isEqualToString:@"YES"]) {
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself uploadFile:fileName destFolderRelativeURL:folderURL fromPath:fileSrcPath isRootFolder:YES uploadType:uploadType.intValue];

                }else
                {
                    __strong NXSharePointManager *strongself = weakself;
                    [strongself uploadFile:fileName destFolderRelativeURL:folderURL fromPath:fileSrcPath isRootFolder:NO uploadType:uploadType.intValue];

                }
            }
            break;
        }
    };
    
    RemoteQueryResponseHandler uploadFile = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        // 1. parse data
        NSArray* result = [NXSharePointXMLParse parseUploadFile:data];
        // 2. get file server path
        NSDictionary* dic = result.firstObject;
        NSString* fileServicePath = [dic valueForKey:SP_SERV_RELT_URL_TAG];
        // 3. notify delegate
        NSDictionary* appendDic = (NSDictionary*)query.additionData;
        NSString* fileSrcPath = appendDic[SP_DICTION_TAG_FILE_SRC_PATH];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didUploadFileFinished:fileServicePath fromPath:fileSrcPath fileInfo:dic error:nil];
    };
    
    RemoteQueryResponseHandler checkFolderExist = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:nil forQuery:kSPQueryCheckFolderExistForGetFiles];
    };

    RemoteQueryResponseHandler checkListExist = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:nil forQuery:kSPQueryCheckListExistForGetFiles];
    };
    
    RemoteQueryResponseHandler checkSiteExist = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQuery:nil forQuery:kSPQueryCheckSiteExistForGetFiles];

    };
    
    RemoteQueryResponseHandler queryFileMetaData = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSDictionary* result = [NXSharePointXMLParse parseGetFileMetaData:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQueryFileMetaData:result error:nil forQuery:kSPQueryFileMetaData];
    };
    
    RemoteQueryResponseHandler queryFolderMetaData = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSDictionary* result = [NXSharePointXMLParse parseGetFolderMetaData:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQueryFileMetaData:result error:nil forQuery:kSPQueryFolderMetaData];
    };

    RemoteQueryResponseHandler queryListMetaData = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSDictionary* result = [NXSharePointXMLParse parseGetListMetaData:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQueryFileMetaData:result error:nil forQuery:kSPQueryListMetaData];
    };

    RemoteQueryResponseHandler querySiteMetaData = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        NSDictionary* result = [NXSharePointXMLParse parseGetSiteMetaData:data];
        __strong NXSharePointManager *strongself = weakself;
        [strongself.delegate didFinishSPQueryFileMetaData:result error:nil forQuery:kSPQuerySiteMetaData];
    };
    
    RemoteQueryResponseHandler queryCurrentUserInfo = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
         __strong NXSharePointManager *strongself = weakself;
        NSString * userId = [NXSharePointXMLParse parseGetCurrentUserId:data];
        if (userId) {
            
            [strongself getCurrentUserDetailInfo:userId];
            
        }else
        {
            if ([strongself.delegate respondsToSelector:@selector(didFinishGetUserInfoQUery:error:)]) {
                NSError * error = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_GET_USER_ACCOUNT_INFO_FAILED userInfo:nil];
                [strongself.delegate didFinishGetUserInfoQUery:nil error:error];
            }
        }
    };
    
    RemoteQueryResponseHandler queryCurrentUserDetailInfo = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        __strong NXSharePointManager *strongself = weakself;
        NSDictionary *userDetail = [NXSharePointXMLParse parseGetUserDetailInfo:data];
        if (userDetail) {
            [strongself getSiteQuota:userDetail];
        }else
        {
            if ([strongself.delegate respondsToSelector:@selector(didFinishGetUserInfoQUery:error:)]) {
                NSError * error = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_GET_USER_ACCOUNT_INFO_FAILED userInfo:nil];
                [strongself.delegate didFinishGetUserInfoQUery:nil error:error];
            }
        }
    };
    
    RemoteQueryResponseHandler queryGetSiteQuota = ^(NXSharePointRemoteQueryBase* query, NSData* data)
    {
        __strong NXSharePointManager *strongself = weakself;
        NSDictionary *siteQuota = [NXSharePointXMLParse parseSiteQuota:data];
        NSMutableDictionary *storedData = (NSMutableDictionary *) query.additionData;
        if (siteQuota) {
            
            [storedData addEntriesFromDictionary:siteQuota];
            
            if ([strongself.delegate respondsToSelector:@selector(didFinishGetUserInfoQUery:error:)]) {
                
                [strongself.delegate didFinishGetUserInfoQUery:[storedData copy] error:nil];
            }
        }else
        {
            if ([strongself.delegate respondsToSelector:@selector(didFinishGetUserInfoQUery:error:)]) {
                [strongself.delegate didFinishGetUserInfoQUery:[storedData copy] error:nil];
            }
        }
    };

    if (!_remoteQueryResponseHandlers) {
        
        _remoteQueryResponseHandlers = [[NSMutableDictionary alloc] init];
    }
    
    [_remoteQueryResponseHandlers setObject:[getAllDoclibListsHandler copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetAllDocLists]];
    [_remoteQueryResponseHandlers setObject:[getAllChildrenFoldersHandler copy]forKey: [[NSNumber alloc] initWithInt:kSPQueryGetAllChildFoldersInFolder]];
    [_remoteQueryResponseHandlers setObject:[getAllChildrenFilesHandler copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetAllChildFilesInFolder]];
    [_remoteQueryResponseHandlers setObject:[getAllChildrenFoldersInRootFolderHandler copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetAllChildFoldersInRootFolder]];
    [_remoteQueryResponseHandlers setObject:[getAllChildrenFilesInRootFolderHandler copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetAllChildFilesInRootFolder]];
    [_remoteQueryResponseHandlers setObject:[getAllChildrenSites copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetAllChildSites]];
    [_remoteQueryResponseHandlers setObject:[downloadFile copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryDownloadFile]];
    [_remoteQueryResponseHandlers setObject:[authentication copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryAuthentication]];
    [_remoteQueryResponseHandlers setObject:[getContextInfo copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryGetContextInfo]];
    [_remoteQueryResponseHandlers setObject:[uploadFile copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryUploadFile]];
    [_remoteQueryResponseHandlers setObject:[checkFolderExist copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryCheckFolderExistForGetFiles]];
    [_remoteQueryResponseHandlers setObject:[checkListExist copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryCheckListExistForGetFiles]];
    [_remoteQueryResponseHandlers setObject:[checkSiteExist copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryCheckSiteExistForGetFiles]];
    [_remoteQueryResponseHandlers setObject:[queryFileMetaData copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryFileMetaData]];
    [_remoteQueryResponseHandlers setObject:[queryFolderMetaData copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryFolderMetaData]];
    [_remoteQueryResponseHandlers setObject:[queryListMetaData copy] forKey: [[NSNumber alloc] initWithInt:kSPQueryListMetaData]];
    [_remoteQueryResponseHandlers setObject:[querySiteMetaData copy] forKey: [[NSNumber alloc] initWithInt:kSPQuerySiteMetaData]];
    [_remoteQueryResponseHandlers setObject:[queryCurrentUserInfo copy] forKey:[[NSNumber alloc] initWithInt:kSPQueryGetCurrentUserInfo]];
    [_remoteQueryResponseHandlers setObject:[queryCurrentUserDetailInfo copy] forKey:[[NSNumber alloc] initWithInt:kSPQueryGetCurrentUserDetailInfo]];
    [_remoteQueryResponseHandlers setObject:[queryGetSiteQuota copy] forKey:[[NSNumber alloc] initWithInt:kSPQueryGetSiteQuota]];

}

-(void) siteURL:(NSString*) newSiteURL
{
    if (newSiteURL) {
        _siteURL = newSiteURL;
        
        // siteURL is like 'https://pf1-w12-sps06/sites/spe/tyy/Forms/AllItems.aspx'
        // so servername is siteURLcontent[2];
        NSArray* siteURLcontent  = [_siteURL componentsSeparatedByString:@"/"];
        _serverName = siteURLcontent[2];
    }
}

- (NXSharePointRemoteQueryBase*) initializeQuery:(NSString *)queryURLStr {
    NXSharePointRemoteQueryBase *spQuery = nil;
    switch (_spMgrType) {
        case kSPMgrSharePoint:
            spQuery = [[NXSharePointRemoteQuery alloc] initWithURL:queryURLStr userName:self.user passWord:self.psw];
            break;
        case kSPMgrSharePointOnline:
            spQuery = [[NXSharepointOnlineRemoteQuery alloc] initWithURL:queryURLStr cookies:self.cookies];
            break;
        default:
            break;
    }
    
    spQuery.delegate = self;
    [self.curSPQueryArray addObject:spQuery];
    
    return spQuery;
}

#pragma mark SharePoint SDK public interface
-(void) allDocumentLibListsOnSite
{
    NSString* queryURLStr = [NSString stringWithFormat:[NXSharePointRestTemp SPGetAllListsTemp], self.siteURL];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryURLStr];
    [spQuery executeQueryWithRequestId:kSPQueryGetAllDocLists];
}

-(void) allChildItemsInFolder:(NSString*) folderPath
{
    self.getAllItems = YES;
    self.getFilesDatas = NO; self.getFoldersDatas = NO;
    [self allChildenFilesInFolder:folderPath];
}

-(void) allChildenFoldersInFolder:(NSString*) folderPath
{
    NSString* queryAllFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetChildenFolderTemp], self.siteURL, folderPath];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFolder];
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildFoldersInFolder];
}

-(void) allChildenFilesInFolder:(NSString*) folderPath
{
    NSString* queryAllFiles = [NSString stringWithFormat:[NXSharePointRestTemp SPGetChildenFileTemp], self.siteURL, folderPath];
    
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFiles];
    spQuery.additionData = folderPath;
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildFilesInFolder];
}

-(void) allChildenItemsInRootFolderInList:(NSString*) listTitle
{
    self.getAllItems = YES;
    self.getFilesDatas = NO; self.getFoldersDatas = NO;
    [self allChildenFilesInRootFolderInList:listTitle];
}

-(void) checkFolderExistForGetFiles:(NSString *)folderPath
{
    NSString* queryFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetFolderTemp], self.siteURL, folderPath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryFolder];
    [spQuery executeQueryWithRequestId:kSPQueryCheckFolderExistForGetFiles];
}

-(void) queryFolderMetaData:(NSString*) folderPath
{
    NSString* queryFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetFolderTemp], self.siteURL, folderPath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryFolder];
    [spQuery executeQueryWithRequestId:kSPQueryFolderMetaData];

}

-(void) allChildenFilesInRootFolderInList:(NSString*) listTitle
{
    NSString* queryAllFiles = [NSString stringWithFormat:[NXSharePointRestTemp SPGetRootFolderChildenFileTemp], self.siteURL, listTitle];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFiles];
    spQuery.additionData = listTitle;
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildFilesInRootFolder];
}

-(void) allChildenFoldersInRootFolderInList:(NSString*) listTitle
{
    NSString* queryAllFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetRootFolderChildenFolderTemp], self.siteURL, listTitle];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFolder];
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildFoldersInRootFolder];
}

-(void) checkListExistForGetFiles:(NSString*) listPath
{
    NSString* queryAllFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetListTemp], self.siteURL, listPath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFolder];
    [spQuery executeQueryWithRequestId:kSPQueryCheckListExistForGetFiles];
}
-(void) queryListMetaData:(NSString*) listPath
{
    NSString* queryAllFolder = [NSString stringWithFormat:[NXSharePointRestTemp SPGetListTemp], self.siteURL, listPath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllFolder];
    [spQuery executeQueryWithRequestId:kSPQueryListMetaData];

}
-(void) allChildenSitesOnSite
{
    NSString* queryAllChildrenSites = [NSString stringWithFormat:[NXSharePointRestTemp SPGetChildenSitesTemp], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAllChildrenSites];
    [spQuery executeQueryWithRequestId:kSPQueryGetAllChildSites];
    
}

-(void) allChildItemsOnSite
{
    self.getAllSiteItems = YES;
    self.getDocListDatas = NO;
    self.getSitesDatas = NO;
    
    [self allChildenSitesOnSite];
}

-(void) checkSiteExistForGetFiles:(NSString*) sitePath
{
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:sitePath];
    [spQuery executeQueryWithRequestId:kSPQueryCheckSiteExistForGetFiles];
}

-(void) querySiteMetaData:(NSString*) sitePath
{
    NSString* querySiteProperty = [NSString stringWithFormat:[NXSharePointRestTemp SPQuerySitePropertyTemp], sitePath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:querySiteProperty];
    [spQuery executeQueryWithRequestId:kSPQuerySiteMetaData];

}

-(void) downloadFile:(NXSharePointFile*) spFile fileRelativeURL:(NSString*) fileUrl destPath:(NSString*) destPath
{
    NSString* queryDownloadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPDownloadFileTemp], self.siteURL, fileUrl];
    NSNumber* fileSize = [[NSNumber alloc] initWithLongLong:spFile.size];
    NSDictionary* appendData = [NSDictionary dictionaryWithObjects:@[spFile.name, fileUrl, fileSize, destPath] forKeys:@[SP_DICTION_TAG_FILE_NAME, SP_DICTION_TAG_FILE_REV_URL, SP_DICTION_TAG_FILE_SIZE, SP_DICTION_TAG_DEST_PATH]];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryDownloadFile];
    [spQuery executeQueryWithRequestId:kSPQueryDownloadFile withAdditionData:(id)appendData];
    
}

-(void) cancelDownloadFile:(NXSharePointFile*) spFile
{
    [self cancelAllQuery];
}

-(void) uploadFile:(NSString*) fileName destFolderRelativeURL:(NSString*) folderUrl fromPath:(NSString*) fileSrcPath isRootFolder:(BOOL) isRootFolder uploadType:(NXUploadType) uploadType
{
    if (self.formDigestToUpload) {
        self.formDigestToUpload = NO;
        NSDictionary* headers = [NSDictionary dictionaryWithObject:_formDigestValue forKey:@"X-RequestDigest"];
        NSString* queryUploadFile = nil;
        if (uploadType == NXUploadTypeNormal) {
            if (isRootFolder) {
                queryUploadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPUploadRootFolderFileTemp], self.siteURL, folderUrl, fileName];
            }else
            {
                queryUploadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPUploadFileTemp], self.siteURL, folderUrl, fileName];
                
            }
        }else if(uploadType == NXUploadTypeOverWrite)
        {
            if (isRootFolder) {
                queryUploadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPUploadRootFolderFileTempOverWriteTemp], self.siteURL, folderUrl, fileName];
            }else
            {
                queryUploadFile = [NSString stringWithFormat:[NXSharePointRestTemp SPUploadFileTempOverWriteTemp], self.siteURL, folderUrl, fileName];
                
            }
        }
        
        NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryUploadFile];
        // get src file data
        NSData* fileData = [NSData dataWithContentsOfFile:fileSrcPath];
        
        NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[fileName, folderUrl, fileSrcPath] forKeys:@[SP_DICTION_TAG_FILE_NAME, SP_DICTION_TAG_FOLDER_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH]];

        [spQuery executeQueryWithRequestId:kSPQueryUploadFile Headers:headers RequestMethod:@"POST" BodyData:fileData withAdditionData:appendData];

    }else
    {
        self.formDigestToUpload = YES;
        NSString* strIsRootFolder = nil;
        if (isRootFolder) {
            strIsRootFolder = @"YES";
        }else
        {
            strIsRootFolder = @"NO";
        }

        NSMutableDictionary* appendData = [[NSMutableDictionary alloc] initWithObjects:@[[[NSNumber alloc] initWithInteger:kSPQueryUploadFile], fileName, folderUrl, fileSrcPath, strIsRootFolder, @(uploadType)] forKeys:@[SP_DICTION_TAG_REQ_TYPE, SP_DICTION_TAG_FILE_NAME, SP_DICTION_TAG_FOLDER_REV_URL, SP_DICTION_TAG_FILE_SRC_PATH, SP_DICTION_TAG_IS_ROOT_FOLDER, SP_DICTION_TAG_UPLOAD_TYPE]];
        
        [self getContextInfo:appendData];
    }
}

-(void) queryFileMetaData:(NSString*) filePath
{
    NSString* queryFileProperty = [NSString stringWithFormat:[NXSharePointRestTemp SPQueryFilePropertyTemp], self.siteURL, filePath];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryFileProperty];
    [spQuery executeQueryWithRequestId:kSPQueryFileMetaData];
}


-(void) authenticate
{
    NSString* queryAuthenticate = [NSString stringWithFormat:[NXSharePointRestTemp SPAuthenticateTemp], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryAuthenticate];
    [spQuery executeQueryWithRequestId:kSPQueryAuthentication];
}

-(void) getContextInfo:(NSMutableDictionary*)appendData;
{
    NSString* queryContextInfo = [NSString stringWithFormat:[NXSharePointRestTemp SPGetContextInfo], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryContextInfo];
    [spQuery executeQueryWithRequestId:kSPQueryGetContextInfo Headers:nil RequestMethod:@"POST" BodyData:nil withAdditionData:appendData];
}

- (void) getCurrentUserInfo
{
    NSString* queryCurrentUserInfo = [NSString stringWithFormat:[NXSharePointRestTemp SPGetCurrentUserInfoTemp], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryCurrentUserInfo];
    [spQuery executeQueryWithRequestId:kSPQueryGetCurrentUserInfo];
}

-(void) cancelAllQuery
{
    for (NXSharePointRemoteQueryBase* spQuery in self.curSPQueryArray) {
        [spQuery cancelQueryWithRequestId:spQuery.queryID AdditionData:nil];
    }
    
    [self.curSPQueryArray removeAllObjects];
}

-(void) getCurrentUserDetailInfo:(NSString *) userId
{
    NSString *queryCurrentUserDetailInfo = [NSString stringWithFormat:[NXSharePointRestTemp SPGetCurrentUserDetailTemp], self.siteURL, userId];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:queryCurrentUserDetailInfo];
    [spQuery executeQueryWithRequestId:kSPQueryGetCurrentUserDetailInfo];
}

-(void) getSiteQuota:(NSDictionary *) userDetailInfo
{
    NSString *querySiteQuota = [NSString stringWithFormat:[NXSharePointRestTemp SPSiteQuotaTemp], self.siteURL];
    NXSharePointRemoteQueryBase *spQuery = [self initializeQuery:querySiteQuota];
    [spQuery executeQueryWithRequestId:kSPQueryGetSiteQuota withAdditionData:userDetailInfo];
}

#pragma mark NXSharePointQueryDelegate Implement
-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery didCompleteQuery:(NSData*) data
{
    [self.curSPQueryArray removeObject:spQuery];
    // list, folder get all items
    if (self.getAllItems) {
        
        if (spQuery.queryID == kSPQueryGetAllChildFilesInFolder || spQuery.queryID == kSPQueryGetAllChildFilesInRootFolder) {
            self.getFilesDatas = YES;
            
            NSArray* fileArray = [NXSharePointXMLParse parseGetChildFiles:data];
            if (_allItemsCache) {
                
                [_allItemsCache addObjectsFromArray:fileArray];
                
            }else
            {
                _allItemsCache = [NSMutableArray arrayWithArray:fileArray];
            }
            if(spQuery.queryID == kSPQueryGetAllChildFilesInFolder)
            {
                [self allChildenFoldersInFolder:(NSString *) spQuery.additionData];
                
            }else if(spQuery.queryID == kSPQueryGetAllChildFilesInRootFolder)
            {
                [self allChildenFoldersInRootFolderInList:(NSString *)spQuery.additionData];
            }
            
        }
        
        if (spQuery.queryID == kSPQueryGetAllChildFoldersInFolder || spQuery.queryID == kSPQueryGetAllChildFoldersInRootFolder) {
            self.getFoldersDatas = YES;
            NSArray* folderArray = [NXSharePointXMLParse parseGetChildFolders:data];
            if (_allItemsCache) {
                
                [_allItemsCache addObjectsFromArray:folderArray];
                
            }else
            {
                _allItemsCache = [NSMutableArray arrayWithArray:folderArray];
            }
            
        }
        
        if (self.getFilesDatas && self.getFoldersDatas) {
            self.getAllItems = NO;
            self.getFilesDatas = NO;
            self.getFoldersDatas = NO;
            // notify user
            [self.delegate didFinishSPQuery:[_allItemsCache copy] forQuery:kSPQueryGetAllItemsInFolder];
            [_allItemsCache removeAllObjects];
        }
        
    }else if(self.getAllSiteItems)
    {
        if (spQuery.queryID == kSPQueryGetAllChildSites) {
           
            self.getSitesDatas = YES;
            NSArray* sitesArray = [NXSharePointXMLParse parseGetChildSites:data];
            if (_allItemsCache) {
                
                [_allItemsCache addObjectsFromArray:sitesArray];
                
            }else
            {
                _allItemsCache = [NSMutableArray arrayWithArray:sitesArray];
            }
            
            [self allDocumentLibListsOnSite];
        }
        
        if (spQuery.queryID == kSPQueryGetAllDocLists) {
            self.getDocListDatas = YES;
            NSArray* docListsArray = [NXSharePointXMLParse parseGetDocLibLists:data];
            if (_allItemsCache) {
                
                [_allItemsCache addObjectsFromArray:docListsArray];
                
            }else
            {
                _allItemsCache = [NSMutableArray arrayWithArray:docListsArray];
            }
        }
        
        if (self.getSitesDatas && self.getDocListDatas) {
            
            self.getAllSiteItems = NO;
            self.getSitesDatas = NO;
            self.getDocListDatas = NO;
            // notify user
            [self.delegate didFinishSPQuery:[_allItemsCache copy] forQuery:kSPQueryGetAllItemsInSite];
            [_allItemsCache removeAllObjects];
        }
        
    }
    else  // NOT get all items
    {
        RemoteQueryResponseHandler handlerBlcok = _remoteQueryResponseHandlers[[[NSNumber alloc] initWithInteger:spQuery.queryID]];
        handlerBlcok(spQuery, data);
    }
    [spQuery.spSession invalidateAndCancel];
    spQuery = nil;
    
}

-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery downloadProcess:(CGFloat)progress forFile:(NSString*) filePath
{
    [self.delegate updataDownloadProcess:progress forFile:filePath];
}

-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery didFailedWithError:(NSError*) error
{
    NSError* nxError = error;
    
    if (error.code == NSURLErrorCancelled) {
        nxError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_CANCEL error:error];
        
    }else if(error.code == HTTP_ERROR_CODE_ACCESS_FORBIDDEN)
    {
        nxError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED error:error];
        
    }else if (error.code == SHARE_POINT_HTTP_ERROR_CODE_NO_SUCH_FILE && spQuery.queryID < kSPQueryGetFileFolderDataInfoEnd) // only get file and folder info query need nosuch file error
    {
        nxError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_NOSUCHFILE error:error];
    }else if (error.code < 0 && error.code != NSURLErrorCancelled)
    {
        nxError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_TRANS_BYTES_FAILED error:error];
    }
    
    
    [self.curSPQueryArray removeObject:spQuery];
    [self resetQueryFlag];
    if (spQuery.queryID == kSPQueryAuthentication)
    {
        [self remoteQuery:spQuery didFailedWithAuthenFailure:nxError];
        
    }else if(spQuery.queryID == kSPQueryFileMetaData || spQuery.queryID == kSPQueryFolderMetaData || spQuery.queryID == kSPQueryListMetaData || spQuery.queryID == kSPQuerySiteMetaData)
    {
        [self.delegate didFinishSPQueryFileMetaData:nil error:nxError forQuery:(SPQueryIdentify)spQuery.queryID];
    }else if(spQuery.queryID == kSPQueryGetSiteQuota) // for siteQuota, we can return user Name and email as success result
    {
        if ([self.delegate respondsToSelector:@selector(didFinishGetUserInfoQUery:error:)]) {
            [self.delegate didFinishGetUserInfoQUery:[((NSDictionary *)spQuery.additionData) copy] error:nil];
        }
    }
    else
    {
        // notify delegate, query fail
        [self.delegate didFinishSPQueryWithError:nxError forQuery:(SPQueryIdentify)spQuery.queryID];
    }
    [spQuery.spSession invalidateAndCancel];
    spQuery = nil;
    
}
-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery didFailedWithAuthenFailure:(NSError*) error
{
    [self.curSPQueryArray removeObject:spQuery];
    [self resetQueryFlag];
    // notify delegate, authentication fail
    NSError *nxError = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_AUTHFAILED error:error];
    [self.delegate didAuthenticationFail:nxError forQuery:(SPQueryIdentify)spQuery.queryID];
    [spQuery.spSession invalidateAndCancel];
    spQuery = nil;
}
#pragma mark Query flag property
-(void) resetQueryFlag
{
    _getAllSiteItems = NO;
    _getAllItems = NO;
    
    _getFoldersDatas = NO;
    _getFilesDatas = NO;
    
    _getSitesDatas = NO;
    _getDocListDatas = NO;
    
    if (_allItemsCache) {
        [_allItemsCache removeAllObjects];
    }
    _formDigestToUpload = NO;
}
@end
