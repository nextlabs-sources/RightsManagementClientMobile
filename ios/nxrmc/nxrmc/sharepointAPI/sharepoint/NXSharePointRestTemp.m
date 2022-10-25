//
//  NXSharePointRestTemp.m
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/22.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXSharePointRestTemp.h"

@implementation NXSharePointRestTemp
+(NSString*) SPGetAllListsTemp
{
    // [http(s)://baseSite]/_api/web/lists?$select=BaseTemplate,Title&$filter=BaseTemplate eq 101 700
   NSString* strTemp = @"%@/_api/web/lists?$select=BaseTemplate,Title,Hidden,Id,Created,ParentWebUrl&$filter=(BaseTemplate eq 101) or (BaseTemplate eq 700)";
    return strTemp;
}
+(NSString*) SPGetChildenFolderTemp
{
    // [http(s)://baseSite]/_api/web/GetFolderByServerRelativeUrl('[folderRelativeURL]'/Folders)
    NSString* strTemp = @"%@/_api/web/GetFolderByServerRelativeUrl('%@')/Folders";
    return strTemp;
}

+(NSString*) SPGetChildenFileTemp
{
    // [http(s)://baseSite]/_api/web/GetFolderByServerRelativeUrl('[folderRelativeURL]'/Files)
    NSString* strTemp = @"%@/_api/web/GetFolderByServerRelativeUrl('%@')/Files";
    return strTemp;
}

+(NSString*) SPGetRootFolderChildenFolderTemp
{
    // [http(s)://baseSite]/_api/web/lists(guid'%@')/rootFolder/Folders?$filter=Name ne 'Forms'
    // NOTE exclude system folder:Forms
    NSString* strTemp = @"%@/_api/web/lists(guid'%@')/rootFolder/Folders?$filter=Name ne 'Forms'";
    return strTemp;
}

+(NSString*) SPGetRootFolderChildenFileTemp
{
    // [http(s)://baseSite]/_api/web/lists/getbytitle('[listTitle]')/rootFolder/Files
    NSString* strTemp = @"%@/_api/web/lists(guid'%@')/rootFolder/Files";
    return strTemp;
}

+(NSString*) SPGetChildenSitesTemp
{
    // [http(s)://siteURL]/_api/web/webs
    NSString* strTemp = @"%@/_api/web/webs";
    return strTemp;
}

+(NSString*) SPDownloadFileTemp
{
    // [http(s)://siteURL]/_api/web/GetFileByServerRelativeUrl('[fileRelativeURL]')/$value
    NSString* strTemp = @"%@/_api/web/GetFileByServerRelativeUrl('%@')/$value";
    return strTemp;
}

+(NSString*) SPAuthenticateTemp
{
    // [http(s)://siteURL]
    NSString* strTemp = @"%@";
    return strTemp;
}

+(NSString*) SPUploadFileTemp
{
    
    // [http(s)://siteURL]/_api/web/GetFolderByServerRelativeUrl('[folderRelativeURL]')/files/add(overwrite=true, url='[filename(like 'test.doc')]')
    NSString* strTemp = @"%@/_api/web/GetFolderByServerRelativeUrl('%@')/files/add(overwrite=false, url='%@')";
    return strTemp;
    
}

+(NSString*) SPUploadRootFolderFileTemp
{
    // [http(s)://siteURL]/_api/web/lists(guid'[rootFolderGuid]')/files/add(overwrite=true, url='[filename(like 'test.doc')]')
    NSString* strTemp = @"%@/_api/web/lists(guid'%@')/rootFolder/files/add(overwrite=false, url='%@')";
    return strTemp;
}

+(NSString*) SPUploadFileTempOverWriteTemp
{
    
    // [http(s)://siteURL]/_api/web/GetFolderByServerRelativeUrl('[folderRelativeURL]')/files/add(overwrite=true, url='[filename(like 'test.doc')]')
    NSString* strTemp = @"%@/_api/web/GetFolderByServerRelativeUrl('%@')/files/add(overwrite=true, url='%@')";
    return strTemp;
    
}

+(NSString*) SPUploadRootFolderFileTempOverWriteTemp
{
    // [http(s)://siteURL]/_api/web/lists(guid'[rootFolderGuid]')/files/add(overwrite=true, url='[filename(like 'test.doc')]')
    NSString* strTemp = @"%@/_api/web/lists(guid'%@')/rootFolder/files/add(overwrite=true, url='%@')";
    return strTemp;
}

+(NSString*) SPGetContextInfo
{
    // [http(s)://siteURL]/_api/contextinfo
    NSString* strTemp = @"%@/_api/contextinfo";
    return strTemp;
    
}

+(NSString*) SPGetFolderTemp
{
    // [http(s)://siteURL]/_api/web/GetFolderByServerRelativeUrl('[folderRelativeURL]'))
    NSString* strTemp = @"%@/_api/web/GetFolderByServerRelativeUrl('%@')";
    return strTemp;
}

+(NSString*) SPGetListTemp
{
    // [http(s)://baseSite]/_api/web/lists/getbytitle('[listTitle]')
    NSString* strTemp = @"%@/_api/web/lists(guid'%@')";
    return strTemp;
}

+(NSString*) SPQueryFilePropertyTemp
{
    // [http(s)://siteURL]/_api/web/GetFileByServerRelativeUrl('[fileRelativeURL]')/[property name]
    NSString* strTemp = @"%@/_api/web/GetFileByServerRelativeUrl('%@')";
    return strTemp;
}

+(NSString*) SPQuerySitePropertyTemp
{
    // [http(s)://siteURL]/_api/web
    NSString* strTemp = @"%@/_api/web";
    return strTemp;
}

+(NSString *) SPGetCurrentUserInfoTemp
{
    NSString *strTemp = @"%@/_api/Web/CurrentUser";
    //NSString *strTemp = @"/_api/SP.AppContextSite(@target)/Web/CurrentUser?$select=Id&@target='";
    return strTemp;
}

+(NSString *) SPGetCurrentUserDetailTemp
{
    NSString *strTemp = @"%@/_api/Web/SiteUserInfoList/Items(%@)";
    return strTemp;
}

+(NSString *) SPSiteQuotaTemp
{
    NSString *strTemp = @"%@/_api/site/usage";
    return strTemp;
}
@end
