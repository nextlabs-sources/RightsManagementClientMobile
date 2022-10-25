//
//  NXSharePointSDK.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/21.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXServiceOperation.h"
#import "NXSharePointDelegateProtocol.h"
#import "NXSharePointRestTemp.h"
#import "NXSharePointRemoteQuery.h"
#import "NXSharepointOnlineRemoteQuery.h"

#import "NXFileBase.h"
#import "NXFile.h"
#import "NXFolder.h"
#import "NXSharePointFile.h"

typedef enum{
    kSPMgrSharePoint = 1,
    kSPMgrSharePointOnline,
    
} SPManagerType;

@interface NXSharePointManager : NSObject<NXSharePointQueryDelegate>
@property(nonatomic, weak) id<NXSharePointManagerDelegate> delegate;
@property(nonatomic, strong) NSString* siteURL;
@property(nonatomic, strong) NSString* serverName;
@property(nonatomic) SPManagerType spMgrType;

-(instancetype) initWithSiteURL:(NSString*) siteURL userName:(NSString*) userName passWord:(NSString*) psw Type:(SPManagerType) type;
-(instancetype) initWithURL:(NSString *)siteURL cookies:(NSArray *)cookies Type:(SPManagerType)type;
//  SharePoint SDK
// site
-(void) allDocumentLibListsOnSite;
-(void) allChildenSitesOnSite;
-(void) allChildItemsOnSite; // (subSites + doc lists)
-(void) checkSiteExistForGetFiles:(NSString*) sitePath;
-(void) querySiteMetaData:(NSString*) sitePath;
// folder
-(void) allChildItemsInFolder:(NSString*) folderPath;
-(void) allChildenFoldersInFolder:(NSString*) folderPath;
-(void) allChildenFilesInFolder:(NSString*) folderPath;
-(void) checkFolderExistForGetFiles:(NSString*) folderPath;
-(void) queryFolderMetaData:(NSString*) folderPath;
// list
-(void) allChildenItemsInRootFolderInList:(NSString*) listTitle;
-(void) allChildenFilesInRootFolderInList:(NSString*) listTitle;
-(void) allChildenFoldersInRootFolderInList:(NSString*) listTitle;
-(void) checkListExistForGetFiles:(NSString*) listPath;
-(void) queryListMetaData:(NSString*) listPath;
// file
-(void) downloadFile:(NXSharePointFile*) spFile fileRelativeURL:(NSString*) fileUrl destPath:(NSString*) destPath;
-(void) cancelDownloadFile:(NXSharePointFile*) spFile;
-(void) uploadFile:(NSString*) fileName destFolderRelativeURL:(NSString*) folderUrl fromPath:(NSString*) fileSrcPath isRootFolder:(BOOL) isRootFolder uploadType:(NXUploadType) uploadType;
-(void) queryFileMetaData:(NSString*) filePath;
// authenticate
-(void) authenticate;
// Information about site
-(void) getContextInfo:(NSMutableDictionary*)appendData;
// get user info
- (void) getCurrentUserInfo;

// cancel all current query
-(void) cancelAllQuery;
@end
