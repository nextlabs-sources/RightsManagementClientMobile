//
//  NXSharePointRestTemp.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/22.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXSharePointRestTemp : NSObject
// Get SharePoint Infor
+(NSString*) SPGetAllListsTemp;
+(NSString*) SPGetChildenFolderTemp;
+(NSString*) SPGetChildenFileTemp;
+(NSString*) SPGetRootFolderChildenFolderTemp;
+(NSString*) SPGetRootFolderChildenFileTemp;
+(NSString*) SPGetChildenSitesTemp;
+(NSString*) SPGetFolderTemp;
+(NSString*) SPGetListTemp;
+(NSString*) SPQueryFilePropertyTemp;
+(NSString*) SPQuerySitePropertyTemp;

// Download
+(NSString*) SPDownloadFileTemp;

// Authenticate
+(NSString*) SPAuthenticateTemp;

// Upload
+(NSString*) SPUploadFileTemp;
+(NSString*) SPUploadRootFolderFileTemp;
+(NSString*) SPUploadRootFolderFileTempOverWriteTemp;
+(NSString*) SPUploadFileTempOverWriteTemp;
// getContextinfo
+(NSString*) SPGetContextInfo;
// current user info
+(NSString *) SPGetCurrentUserInfoTemp;
+(NSString *) SPGetCurrentUserDetailTemp;
// site quota
+(NSString *) SPSiteQuotaTemp;
@end
