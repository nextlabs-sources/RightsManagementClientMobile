//
//  NXFilesInfo.h
//  nxrmc
//
//  Created by Kevin on 15/5/11.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NXBoundService.h"



typedef NS_ENUM(NSInteger, NXUploadType)
{
    NXUploadTypeNormal = 0,    //normal upload, upload a file. if file(same name)exist in server, the uploaded file will be renamed, both files exist,
    NXUploadTypeOverWrite,     //overwrite upload, uoload a file. if file(same name)exist in server, the exist file will be replaced by new uploaded file, only uploaded file existed.
    //TBD add other situation eg, when after protect normal file, delete the normal file, only nxl file will existed in server.
};

@class NXFileBase;
@protocol NXServiceOperation <NSObject>

@required -(BOOL) getFiles:(NXFileBase*)folder;
@required -(BOOL) cancelGetFiles:(NXFileBase*)folder;

@required -(BOOL) downloadFile:(NXFileBase*)file;
@required -(BOOL) cancelDownloadFile:(NXFileBase*)file;

/**
 *  upload file to service
 *  filename : name of new uploading file.
 *  folder: where the file to upload.
 *  srcPath: local file path.
 *  overWriteFile: if user select NXUploadTypeOverWrite, this will be overwrite by new uploaded file. if select others ,this parameter is useless.
 *
 */
@required -(BOOL) uploadFile:(NSString*)filename toPath:(NXFileBase*)folder fromPath:(NSString *)srcPath uploadType:(NXUploadType) type overWriteFile:(NXFileBase *)overWriteFile;;
@required -(BOOL) cancelUploadFile:(NSString*)filename toPath:(NXFileBase*)folder;

@required -(BOOL) getMetaData:(NXFileBase*)file;
@required -(BOOL) cancelGetMetaData:(NXFileBase*)file;

@required -(void) setDelegate: (id) delegate;
@required -(BOOL) isProgressSupported;

@required -(void) setAlias:(NSString *) alias;

@required -(void) setBoundService:(NXBoundService *) boundService;
@required -(NXBoundService *) getOptBoundService;


@required -(NSString *) getServiceAlias;
@required -(BOOL) getUserInfo;
@required -(BOOL) cancelGetUserInfo;
@end


@protocol NXServiceOperationDelegate <NSObject>

@optional -(void)getFilesFinished:(NSArray*) files error: (NSError*)err;
@optional -(void)serviceOpt:(id<NXServiceOperation>) serviceOpt getFilesFinished:(NSArray *) files error:(NSError *) err;

@optional -(void)downloadFileFinished:(NSString*) servicePath intoPath:(NSString*)localCachePath error:(NSError*)err;
@optional -(void)downloadFileProgress:(CGFloat) progress forFile:(NSString*)servicePath;

@optional -(void)uploadFileFinished:(NSString*)servicePath fromPath:(NSString*)localCachePath error:(NSError*)err;
@optional -(void)uploadFileProgress:(CGFloat)progress forFile:(NSString*)servicePath fromPath:(NSString*)localCachePath;

@optional -(void)getMetaDataFinished:(NXFileBase*)metaData error:(NSError*)err;

@optional -(void) getUserInfoFinished:(NSString *) userName userEmail:(NSString *) email totalQuota:(NSNumber *) totalQuota usedQuota:(NSNumber *) usedQuota error:(NSError *) error;

@end
