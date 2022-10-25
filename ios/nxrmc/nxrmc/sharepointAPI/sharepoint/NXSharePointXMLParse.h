//
//  NXSharePointXMLParse.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/26.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXSharePointXMLParse : NSObject

// document lib list
+(NSArray*) parseGetDocLibLists:(NSData*) data;
// folder, files
+(NSArray*) parseGetChildFolders:(NSData*) data;
+(NSArray*) parseGetChildFiles:(NSData*) data;
+(NSArray*) parseUploadFile:(NSData*) data;

+(NSDictionary*) parseGetFileMetaData:(NSData*) data;
+(NSDictionary*) parseGetFolderMetaData:(NSData*) data;
+(NSDictionary*) parseGetListMetaData:(NSData*) data;
+(NSDictionary*) parseGetSiteMetaData:(NSData*) data;
// user info
+(NSString *) parseGetCurrentUserId:(NSData *) data;
+(NSDictionary *) parseGetUserDetailInfo:(NSData *) data;

// site
+(NSArray*) parseGetChildSites:(NSData*) data;
+(NSDictionary *) parseSiteQuota:(NSData *) data;

//contextInfo(we need form digist to do post request)
+(NSArray*) parseContextInfo:(NSData*) data;
@end
