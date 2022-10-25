//
//  NXSharePointDelegateProtocol.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/25.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#ifndef RecordWebRequest_NXSharePointDelegateProtocol_h
#define RecordWebRequest_NXSharePointDelegateProtocol_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//////////////////////////////////////NXSharePointManager define
typedef enum
{
    kSPQueryGetAllDocLists = 1,
    kSPQueryGetAllChildFoldersInFolder,
    kSPQueryGetAllChildFilesInFolder,
    kSPQueryGetAllChildFilesInRootFolder,
    kSPQueryGetAllChildFoldersInRootFolder,
    kSPQueryGetAllChildSites,
    kSPQueryGetAllItemsInSite,
    kSPQueryGetAllItemsInFolder,
    kSPQueryGetFilesEnd,   // end
    /////NOTE!!! THE END OF GET FILE ENUM!!!!!!!//////////
    kSPQueryCheckFolderExistForGetFiles,
    kSPQueryCheckListExistForGetFiles,
    kSPQueryCheckSiteExistForGetFiles,
    kSPQueryFileMetaData,
    kSPQueryListMetaData,
    kSPQueryFolderMetaData,
    kSPQuerySiteMetaData,
    kSPQueryGetFileFolderDataInfoEnd,
    /////NOTE!!!!THE END OF GET FILE , FOLDER DATA INFO!!!!!!////////
    kSPQueryDownloadFile,
    kSPQueryAuthentication,
    kSPQueryUploadFile,
    kSPQueryGetContextInfo,
    kSPQueryGetCurrentUserInfo,
    kSPQueryGetCurrentUserDetailInfo,
    kSPQueryGetSiteQuota,
}SPQueryIdentify;

#define SP_DICTION_TAG_FILE_NAME @"fileName"
#define SP_DICTION_TAG_FILE_SIZE @"fileSize"
#define SP_DICTION_TAG_REQ_TYPE @"requestType"
#define SP_DICTION_TAG_FILE_REV_URL @"fileRelativeURL"
#define SP_DICTION_TAG_FILE_SRC_PATH @"fileSrcPath"
#define SP_DICTION_TAG_IS_ROOT_FOLDER @"IsRootFolder"
#define SP_DICTION_TAG_UPLOAD_TYPE @"uploadType"
#define SP_DICTION_TAG_FOLDER_REV_URL @"folderRelativeURL"
#define SP_DICTION_TAG_DEST_PATH @"destPath"
#define SP_DICTION_TAG_FORM_DIGEST @"formDigest"

//////////////////////////////////////NXSharePointXMLParse define
#define SP_ENTRY_TAG  @"entry"
#define SP_PROPERTY_TAG @"properties"
#define SP_HIDDEN_TAG @"Hidden"
#define SP_ID_TAG @"Id"
#define SP_CREATED_TAG @"Created"
#define SP_PARENT_WEB_URL @"ParentWebUrl"
#define SP_TITLE_TAG @"Title"
#define SP_CONTENT_TAG @"content"
#define SP_NAME_TAG @"Name"
#define SP_SERV_RELT_URL_TAG @"ServerRelativeUrl"
#define SP_CONTENT_VERSION_TAG @"ContentTag"
#define SP_FILE_SIZE_TAG @"Length"
#define SP_TIME_LAST_MODIFY @"TimeLastModified"
#define SP_URL_TAG @"Url"
#define SP_DOC_LIB_TEMP_TYPE @"101"
#define SP_CONTEXT_WEB_INFO_TAG @"GetContextWebInformation"
#define SP_FORM_DIGEST_TAG @"FormDigestValue"
#define SP_EMAIL_TAG @"EMail"
#define SP_USAGE_TAG @"Usage"
#define SP_STORAGE_TAG @"Storage"
#define SP_STORAGE_USED_TAG @"StorageUsed"
#define SP_STORAGE_PERCENT_USAGE @"StoragePercentageUsed"
// used to identify the type of node
#define SP_NODE_TYPE @"SPNodeType"
#define SP_NODE_SITE @"SITE"
#define SP_NODE_DOC_LIST @"DOC_LIST"
#define SP_NODE_FOLDER @"FOLDER"
#define SP_NODE_FILE @"FILE"



@class NXSharePointRemoteQueryBase;

// NOTE: the delegate called in subthread, if operate UIKit, we need change them into main thread!!!!!!
@protocol NXSharePointQueryDelegate<NSObject>

@optional
-(void) authentication:(NXSharePointRemoteQueryBase*) spQuery didFailedWithError:(NSError*) error;
-(void) authenticationed:(NXSharePointRemoteQueryBase*) spQuery;

@required
-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery didCompleteQuery:(NSData*) data;
-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery didFailedWithError:(NSError*) error;
-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery didFailedWithAuthenFailure:(NSError*) error;
-(void) remoteQuery:(NXSharePointRemoteQueryBase*) spQuery downloadProcess:(CGFloat)progress forFile:(NSString*) filePath;
@end

@protocol NXSharePointManagerDelegate <NSObject>
@optional
-(void) didFinishSPQuery:(NSArray*) result forQuery:(SPQueryIdentify) type;
-(void) didDownloadFile:(NSString*) fileName filePath:(NSString*) fileURL storePath:(NSString*) destPath;
-(void) updataDownloadProcess:(CGFloat)progress forFile:(NSString*) filePath;
-(void) didUploadFileFinished:(NSString*)servicePath fromPath:(NSString*)localCachePath fileInfo:(NSDictionary*) uploadedFileInfo error:(NSError*)err;
-(void) didFinishSPQueryWithError:(NSError*) error forQuery:(SPQueryIdentify) type;
-(void) didFinishSPQueryFileMetaData:(NSDictionary*) result error:(NSError*) error forQuery:(SPQueryIdentify) type;
-(void) didAuthenticationFail:(NSError*) error forQuery:(SPQueryIdentify) type;
-(void) didAuthenticationSuccess;
-(void) didFinishGetUserInfoQUery:(NSDictionary *) result error:(NSError *) error;
@end
#endif
