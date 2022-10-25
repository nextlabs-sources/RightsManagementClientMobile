//
//  Header.h
//  nxrmc
//
//  Created by Kevin on 15/5/12.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#ifndef nxrmc_def_h
#define nxrmc_def_h

#import "HexColor.h"

#define APPLICATION_NAME                @"RMC iOS"
#define APPLICATION_PUBLISHER           @"NextLabs"
#define APPLICATION_PATH                @"RMC iOS"

#define  CACHERMS                       @"rms_"
#define  CACHEOPENEDIN                  @"openedIn"
#define  CACHEDROPBOX                   @"dropbox_"
#define  CACHESHAREPOINT                @"sharepoint_"
#define  CACHESHAREPOINTONLINE          @"sharepointonline_"
#define  CACHEONEDRIVE                  @"onedrive_"
#define  CACHEGOOGLEDRIVE               @"googledrive_"
#define  CACHEICLOUDDRIVE               @"iCloudDrive"
#define  CACHEDIRECTORY                 @"directory.cache"
#define  CACHEROOTDIR                   @"root"

#define  RMS_REST_DEVICE_TYPE_ID        @"3"
#define  RMC_DEFAULT_SERVICE_ID_UNSET   @"SERVICE_ID_UNSET"

#define  KEYCHAIN_PROFILES_SERVICE      @"com.nextlabs.nxrmc.service.profiles"
#define  KEYCHAIN_DEVICE_ID             @"Nextlabs.iOS.DeviceID"
#define  KEYCHAIN_PROFILES              @"com.nextlabs.nxrmc.profiles"

#define  NXLFILEEXTENSION               @".nxl"

// table name
#define TABLE_CACHEFILE                 @"CacheFile"
#define TABLE_BOUNDSERVICE              @"BoundService"


#define SYNCDATA_INTERVAL               5  // second


// REST API
#define DEFAULT_SKYDRM                 @"https://r.skydrm.com"

#define RESTAPITAIL                     @"/service"

#define RESTAPIFLAGHEAD                 @"REST-FLAG"
#define RESTCLIENT_ID_HEAD              @"client_id"
#define DEFAULT_TENANT                  @"skydrm.com"

#define RESTMEMBERSHIP                  @"rs/membership"
#define RESTTOKEN                       @"rs/token"  //both encryption and decryptioin

#define RESTSUPERBASE                   @"RESTSUPERBASE"

// UI Color
#define RMC_MAIN_COLOR                  [HXColor colorWithHexString:@"#399649"]
#define RMC_SUB_COLOR                   [UIColor colorWithRed:(153.0/255.0) green:(204.0/255.0) blue:(102.0/255.0) alpha:1.0]

// Auth repo error
#define AUTH_ERROR_ALREADY_AUTHED               [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_SERVICE_ALREADY_AUTHED userInfo:nil]
#define AUTH_ERROR_AUTH_FAILED                  [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_AUTHFAILED userInfo:nil]
#define AUTH_ERROR_ACCOUNT_DIFF_FROM_RMS        [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_AUTH_ACCOUNT_NOT_SAME userInfo:nil]
#define AUTH_ERROR_NO_NETWORK                   [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_NO_NETWORK userInfo:nil]
#define AUTH_ERROR_AUTH_CANCELED                [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_CANCEL userInfo:nil]



typedef NS_ENUM(NSInteger, ActivityOperation)
{
    kProtectOperation = 1,
    kShareOperation = 2,
    kRemoveUserOperation = 3,
    kViewOperation = 4,
    kPrintOpeartion = 5,
    kDownloadOperation = 6,
    kEditSaveOperation = 7,
    kRevokeOperation = 8,
    kDecryptOperation = 9,
    kCopyContentOpeartion = 10,
    kCaptureScreenOpeartion = 11,
    kClassifyOperation = 12,
};

typedef enum{
    kAccountRMS = 0
}LogInAccountType;

typedef NS_ENUM(NSInteger, ServiceType) {
    kServiceUnset = -1,
    kServiceDropbox = 0,
    kServiceSharepointOnline,
    kServiceSharepoint,
    kServiceOneDrive,
    kServiceGoogleDrive,
    kServiceICloudDrive,
};

// RMS Repository Type
#define RMS_REPO_TYPE_SHAREPOINT        @"SHAREPOINT_ONPREMISE"
#define RMS_REPO_TYPE_SHAREPOINTONLINE  @"SHAREPOINT_ONLINE"
#define RMS_REPO_TYPE_DROPBOX           @"DROPBOX"
#define RMS_REPO_TYPE_GOOGLEDRIVE       @"GOOGLE_DRIVE"
#define RMS_REPO_TYPE_ONEDRIVE          @"ONE_DRIVE"
#define RMS_REPO_TYPE_BOX               @"BOX"

// NXErrorDomain
#define NXHTTPSTATUSERROR               @"NXHttpStatusError"
#define NXHTTPAUTOREDIRECTERROR         @"NXHttpAutoRedirectError"
#define NX_ERROR_SERVICEDOMAIN          @"NXRMCServicesErrorDomain"
#define NX_ERROR_NETWORK_DOMAIN         @"NXNetworkErrorDomain"
#define NX_ERROR_REST_DOMAIN            @"NXRESTErrorDomain"
#define NX_ERROR_NXLFILE_DOMAIN         @"NXNXFILEDOMAIN"
// NXError code
typedef NS_ENUM(NSInteger, NXRMC_ERROR_CODE) {
    NXRMC_ERROR_CODE_NOSUCHFILE = 10000,
    NXRMC_ERROR_CODE_AUTHFAILED,
    NXRMC_ERROR_CODE_CANCEL,
    NXRMC_ERROR_CODE_CONVERTFILEFAILED,
    NXRMC_ERROR_CODE_CONVERTFILEFAILED_NOSUPPORTED,
    NXRMC_ERROR_CODE_CONVERTFILE_CHECKSUM_NOTMATCHED,
    NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED,
    NXRMC_ERROR_NO_NETWORK,
    NXRMC_ERROR_BAD_REQUEST,
    NXRMC_ERROR_GET_USER_ACCOUNT_INFO_FAILED,
    NXRMC_ERROR_CODE_GET_NO_KEY_BLOB,
    NXRMC_ERROR_CODE_NOT_NXL_FILE,
    NXRMC_ERROR_CODE_TRANS_BYTES_FAILED,
    NXRMC_ERROR_CODE_REST_UPLOAD_FAILED,
    NXRMC_ERROR_CODE_REST_MEMBERSHIP_FAILED,
    NXRMC_ERROR_CODE_REST_MEMBERSHIP_CERTIFICATES_NOTENOUGH,
    NXRMC_ERROR_CODE_SERVICE_ALREADY_AUTHED,
    NXRMC_ERROR_CODE_AUTH_ACCOUNT_NOT_SAME,
    
    //nxl file related error, such as encrypt/decrypt
    NXRMC_ERROR_CODE_NXFILE_ISNXL = 20000,
    NXRMC_ERROR_CODE_NXFILE_ISNOTNXL,
    NXRMC_ERROR_CODE_NXFILE_NO_TOKEN, // can not get token from keychain, memory cache.
    NXRMC_ERROR_CODE_NXFILE_ENCRYPT,
    NXRMC_ERROR_CODE_NXFILE_DECRYPT,
    NXRMC_ERROR_CODE_NXFILE_GETFILETYPE,
    NXRMC_ERROR_CODE_NXFILE_ADDPOLICY,
    NXRMC_ERROR_CODE_NXFILE_GETPOLICY,
    NXRMC_ERROR_CODE_NXFILE_UNKNOWN,
    NXRMC_ERROR_CODE_NXFILE_TOKENINFO,
    NXRMC_ERROR_CODE_NXFILE_OWNER,

};

// http error code
#define HTTP_ERROR_CODE_ACCESS_FORBIDDEN  403
#define SHARE_POINT_HTTP_ERROR_CODE_NO_SUCH_FILE  500

typedef NS_ENUM(NSInteger, NXRMS_STATUS_CODE) {
    NXRMS_STATUS_CODE_SUCCESS = 0,
};

// define 3d file format,like hsf
#define FILEEXTENSION_JT        @"jt"
#define FILEEXTENSION_PRT       @"prt"
#define FILEEXTENSION_HSF       @"hsf"
#define FILEEXTENSION_VDS       @"vds"
#define FILEEXTENSION_RH        @"rh"
#define FILEEXTENSION_PDF       @"pdf"

//file type supported to open
#define FILESUPPORTOPEN         @".jt.prt.hsf.vds.pdf.jpg.png.bmp.gif.txt.java.h.cpp.c.js.xml.htm.html.mp4.mp3.xlsx.xls.ppt.pptx.doc.docx.log.tiff.tif."

// define DropBox client ID
#define DROPBOXCLIENTID                 @"7iw0a6cmfshsxxk"
#define DROPBOXCLIENTSECRET             @"tiy7hlct3fnmsk2"



// define One Drive client ID
#define ONEDRIVECLIENTID                @"00000000481767DB"
// OneDrive local plist file key
#define LIVE_AUTH_CLIENTID              @"client_id"
#define LIVE_AUTH_REFRESH_TOKEN         @"refresh_token"

//define GoogleDrive client ID
#define GOOGLEDRIVECLIENTID             @"595918485197-cvl70gr7lgpfbsdp02ub7e4oficfip52.apps.googleusercontent.com"
#define GOOGLEDRIVECLIENTSECRET         @"Uz-x1sWHnO7oUcfuAttscswg"
#define GOOGLEDRIVEKEYCHAINITEMLENGTH   20   //random string length

// notification RMS server address changed
#define NOTIFICATION_RMSSERVER_CHANGED  @"RMS_Server_Changed"
#define NOTIFICATION_NXRMC_LOG_OUT @"NXRMC_USER_LOG_OUT"

// notifcation User pressed sort button
#define NOTIFICATION_USER_PRESSED_SORT_BTN @"User_Pressed_Sort_Btn"

// notification User open new file
#define NOTIFICATION_USER_OPEN_FILE @"USER_OPEN_FILE_NOTIFICATION"

// notification User tap status bar
#define NOTIFICATION_USER_TAP_STATUS_BAR @"User_Tap_StatusBar"

#define NOTIFICATION_DROP_BOX_CANCEL @"Drop_Box_Cancel"

// notification Response Add
#define NOTIFICATION_REPO_ADDED @"notification_repo_added"
#define NOTIFICATION_REPO_ADDED_ERROR_KEY @"NOTIFICATION_REPO_ADDED_ERROR_KEY"

#define RMS_ADD_REPO_ERROR_NET_ERROR @"RMS_ADD_REPO_ERROR_NET_ERROR"
#define RMS_ADD_REPO_DUPLICATE_NAME @"RMS_ADD_REPO_DUPLICATE_NAME"
#define RMS_ADD_REPO_RMS_OTHER_ERROR @"RMS_ADD_REPO_RMS_OTHER_ERROR"
#define RMS_ADD_REPO_ALREADY_EXIST @"RMS_ADD_REPO_ALREADY_EXIST"

// notification Response Update
#define NOTIFICATION_REPO_UPDATED @"notification_repo_updated"
#define NOTIFICATION_REPO_UPDATED_ERROR_KEY @"NOTIFICATION_REPO_UPDATED_ERROR_KEY"

#define RMS_UPDATE_REPO_ERROR @"RMS_UPDATE_REPO_ERROR"

// notification Response Deleted
#define NOTIFICATION_REPO_DELETED @"notification_repo_deleted"
#define NOTIFICATION_REPO_DELETE_ERROR_KEY @"NOTIFICATION_REPO_DELETE_ERROR_KEY"
#define RMS_DELETE_REPO_FAILED @"RMS_DELETE_REPO_FAILED"

// notification Response Repository changed
#define NOTIFICATION_REPO_CHANGED @"notification_repo_changed"
// notification Detail View Change
#define NOTIFICATION_DETAILVIEW_CHANGED @"notification_detailView_changed"

// notification Repo update
#define NOTIFICATION_REPO_ALIAS_UPDATED @"notification_repo_alias_updated"

//========The view's TAGs
#define SEARCH_COVER_VIEW_TAG 90001
#define SERVICETABLE_COVER_VIEW_TAG 90002
#define SERVICETABLE_COVER2_VIEW_TAG 90003
#define FILEDETAILINFO_VIEW_TAG 90004
#define NO_REPO_VIEW_TAG 90005
#define FILE_LIST_NAV_VIEW_TAG 90006
#define ALERT_VIEW_RENAME_FILE_TAG 90007
//===Home page TAGs
#define HOME_TOUCH_DISABLE_COVER_VIEW 90008
#define HOME_PAGE_FILE_DETAIL_VIEW_TAG 90009
#define HOME_PAGE_ADD_REPO_BTN_TAG 90010
#define HOME_PAGE_NX_ICON_TAG 90011
#define HOME_PAGE_NO_SEL_REPO_LAB_TAG 90012
//===Account page TAGs
#define ACCOUNT_PAGE_COVER_VIEW_TAG 70001
#define ACCOUNT_PAGGE_DATA_PICKER_TAG 70002
//===File Content TAGs
#define FILE_CONTENT_NO_CONTENT_VIEW_TAG 80001
#define AUTO_DISMISS_LABLE_TAG 80002

//=====iPad
//===File List Page TAGs
#define FILE_LIST_NO_REPO_BTN_TAG 60001
#define FILE_LIST_SERVICE_TABLE_VIEW_TAG 60002
#define FILE_LIST_COVER_VIEW_TAG 60003


// The side menu section tag
#define SERVICES_SECTION    0
#define PAGES_VIEWS_SECTION 1
#define SlideMenuMyOffline 0
#define SlideMenuMyFavorite 1
#define SlideMenuMyAccount 2
#define SlideMenuHelp 3

// The user guider
#define UserGuiderCachedName @"userGuider.archive"

// The REST Request NX_UUID
#define NXREST_UUID(boundService)   [NSString stringWithFormat:@"%@-%@", boundService.service_type, boundService.service_account_id]

// The extension of REST API cache file
#define NXREST_CACHE_EXTENSION @".rest"

// The keyword for sync repo date in NSUserDefaults
#define NXSYNC_REPO_DATE_USERDEFAULTS_KEY @"SYNC_REPO_DATE"

// The Sperate string for service token used in sync repo
#define NXSYNC_REPO_SPERATE_KEY @"NEXTLABS_SPERATE_KEY"

// The RMS config NSUserProfile Key
#define NXRMS_ADDRESS_KEY @"NXRMS_ADDRESS_KEY"
#define NXRMS_SKY_DRM_KEY @"NXRMS_SKY_DRM_KEY"
#define NXRMS_TENANT_KEY @"NXRMS_TENANT_KEY"
#endif
