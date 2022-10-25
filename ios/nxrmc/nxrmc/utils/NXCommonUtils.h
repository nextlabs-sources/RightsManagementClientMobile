//
//  NXCommonUtils.h
//  nxrmc
//
//  Created by Kevin on 15/5/12.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NXRMCDef.h"
#import "NXBoundService.h"
#import "NXProfile.h"
#import "NXCacheFile.h"
#import "NXServiceOperation.h"
#import "NXMetaData.h"
#import "NXLoginUser.h"

#define NXDIVKEY @"NX_DIV_KEY" // use for connect service_type and sservice_account to gen rootFoler service dict key

@interface NXCommonUtils : NSObject

+ (UIView*) createWaitingView;
+ (UIView*) createWaitingView:(CGFloat)sidelength;
+ (UIView*) createWaitingViewWithCancel: (id) target selector: (SEL)selector inView:(UIView*)view;

+(NSString *) currentRMSAddress;
+(NSString *) currentTenant;
+(NSString *) currentSkyDrm;

+(void) updateRMSAddress:(NSString *) rmsAddress;
+(void) updateRMSTenant:(NSString *) tenant;
+(void) updateSkyDrm:(NSString *) skyDrmAddress;

/**
 *  create waitting view and add to view(support auto layout)
 *
 *  @param view the parent view that want to add waiting view
 *
 *  @return the waiting view
 */
+ (UIView*) createWaitingViewInView:(UIView*)view;
+ (void) removeWaitingViewInView:(UIView *) view;
+(BOOL) waitingViewExistInView:(UIView *)view;

+ (void)showAlertView:(NSString *)title
              message:(NSString *)message
                style:(UIAlertControllerStyle)style
        OKActionTitle:(NSString *)okTitle
    cancelActionTitle:(NSString *)cancelTitle
       OKActionHandle:(void (^)(UIAlertAction *action))OKActionHandler
   cancelActionHandle:(void (^)(UIAlertAction *action))cancelActionHandler inViewController:(UIViewController *)controller
             position:(UIView *)sourceView;

+ (BOOL)isValidateEmail:(NSString *)email;

+ (NSArray*) fetchData: (NSString*) table predicate: (NSPredicate*) pred;
+ (int) getIndex: (NSString*)table;
+ (void) updateIndex: (NSString*) table;

+ (NSString *) serviceAliasByServiceType:(ServiceType) serviceType ServiceAccountId:(NSString *) accountId;
+(NXBoundService *) boudServiceByServiceType:(ServiceType) serviceType ServiceAccountId:(NSString *) accountId;

+ (NXBoundService*) getBoundServiceFromCoreData:(NSString *) serviceId;
+ (NXBoundService *) storeServiceIntoCoreData:(NXRMCRepoItem *) serviceObj;
+ (void) updateBoundServiceInCoreData:(NXBoundService *) boundService;
+ (BOOL)updateService:(ServiceType) type serviceAccount:(NSString *)sa serviceAccountId:(NSString *)sai serviceAccountToken:(NSString *)sat isAuthed:(BOOL) isAuthed;
+ (BOOL) deleteServiceFromCoreData: (NXBoundService*) boundService;
+ (BOOL) cleanUpTable:(NSString *) tableName;

//+ (NXCacheFile*) storeCacheFileIntoCoreData:(NXBoundService *)service  sourcePath:(NSString*)sPath cachePath: (NSString*)cPath;
+ (NXCacheFile*) storeCacheFileIntoCoreData:(NXFileBase *)file cachePath:(NSString *)cPath;
//+ (NXCacheFile*) getCacheFile: (NXBoundService*) service servicePath: (NSString*) servicePath;
+ (NXCacheFile*) getCacheFile: (NXFileBase *) file;
+ (void) deleteCacheFileFromCoreData: (NXCacheFile*) cacheFile;
+ (void) deleteCacheFilesFromCoreDataForService: (NXBoundService*) service;
+ (void) deleteAllCacheFilesFromCoreData;

+ (void) deleteCachedFilesOnDisk;
+ (void) deleteFilesAtPath:(NSString *)directory;
+ (NSNumber *) calculateCachedFileSize;
+ (NSNumber *) calculateCachedFileSizeAtPath:(NSString *)folderPath;

+ (NSArray*) getStoredProfiles;
+ (void) storeProfile: (NXProfile*) profile;
+ (void) deleteProfile:(NXProfile*) profile;

+ (id<NXServiceOperation>) createServiceOperation: (NXBoundService*) service;

+ (NXFileBase*) storeThirdPartyFileAndGetNXFile:(NSURL*)fileURL;

+ (NSString*) getMiMeType:(NSString*)filepath;
+ (NSString*) getUTIForFile:(NSString*) filepath;
+ (NSString*) getExtension:(NSString*) fullpath error:(NSError **)error;

+ (NSString *) convertToCCTimeFormat:(NSDate *) date;
+ (NSString *) convertRepoTypeToDisplayName:(NSNumber *) repoType;
+ (BOOL) is3DFileWithMimeType:(NSString*)mimeType;
+ (BOOL) is3DFileFormat:(NSString*)extension;
+ (BOOL) is3DFileNeedConvertFormat:(NSString*)extension;
+ (BOOL) isTheSupportedFormat:(NSString*)extension;

+ (float) iosVersion;
+ (BOOL) isiPad;
+ (NSString *) deviceID;
+ (NSNumber*) getPlatformId;

+ (void)showAlertViewInViewController:(UIViewController*)vc title:(NSString*)title message:(NSString*)message;

+ (NSArray *) updateFolderChildren:(NXFileBase *)folder newChildren:(NSArray *)newFileList;

//get device screenbounds.
+ (CGRect) getScreenBounds;



/**
 *  protect normal file to nxl file
 *
 *  @param filePath    normal file full path.
 *  @param nxlFilePath nxl file path which to be saved to.
 *  @param nxlFiletags set to nxl file
 *
 *  @return true means generate nxl file success.
 */
+ (BOOL) SaveFile:(NSString*) filePath toNxlFile:(NSString*) nxlFilePath withtags:(NSDictionary*)nxlFiletags;

//only used for dropbox.
+ (NSDictionary*)parseURLParams:(NSString *)query;

+ (NSString*) randomStringwithLength:(NSUInteger)length;

+ (NSString*) getConvertFileTempPath;

+ (void)cleanTempFile;

+ (NSString*) md5Data: (NSData*) data;

+ (NSString *) getRmServer;

+ (void) saveRmserver:(NSString *)rmserver;

+ (BOOL) isFirstTimeLaunching;

+ (void) saveFirstTimeLaunchSymbol;

+ (void) unUnarchiverCacheDirectoryData:(NXFileBase *) rootFolder;

+ (NXFileBase*)fetchFileInfofromThirdParty:(NSURL*)fileURL;

/**
 *  create service root folder key which is used in root folders directory
 *   to support multi-service get root folderview and add to view(support auto layout)
 *
 */

+(NSString *) getServiceFolderKeyForFolderDirectory:(NXBoundService *) boundService;

/**
 *  get NXError from nxrmc error code, which have localized description to let user
 *  make sence
 *
 */
+(NSError *) getNXErrorFromErrorCode:(NXRMC_ERROR_CODE) NXErrorCode error:(NSError *) error;

+ (NSString *)getImagebyExtension:(NSString *)extension;

+ (void)setLocalFileLastModifiedDate:(NSString *)localFilePath date:(NSDate *)date;

+ (NSDate *)getLocalFileLastModifiedDate:(NSString *)localFilePath;

+ (UIUserInterfaceIdiom) getUserInterfaceIdiom;

/**
 *  get Log index send to RMS server
 *
 */

+ (NSUInteger) getLogIndex;


/**
 *  RMS <-> RMC Repo sync
 *
 */
+ (NSString *) rmcToRMSRepoType:(NSNumber *) rmcRepoType;
+ (NSNumber *) rmsToRMCRepoType:(NSString *) rmsRepoType;

+ (NSString *) rmsToRMCDisplayName:(NSString *) rmsRepoType;

+(NSString *) userSyncDateDefaultsKey;

+ (NSString *) ISO8601Format:(NSDate *)date;
+ (NSString *)decodedURLString:(NSString *)encodedString;

+ (NSNumber *)converttoNumber:(NSString *)string;

+ (BOOL)ispdfFileContain3DModelFormat:(NSString *)pdfFilePath;


+ (BOOL)isStewardUser:(NSString *)userId;
@end
