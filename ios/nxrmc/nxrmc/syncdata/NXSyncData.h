//
//  NXSyncData.h
//  nxrmc
//
//  Created by Kevin on 15/6/11.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NXServiceOperation.h"
#import "NXFile.h"
#import "NXFolder.h"
#import "NXBoundService.h"

typedef NS_ENUM(NSInteger, NXOperationType)
{
    NXOPERATION_UNSET = 0,
    NXOPERATION_GETFILES = 1,
    NXOPERATION_GETMETADATA,
};

@protocol NXSyncDataDelegate <NSObject>

@optional
- (void) syncDataUpdateUI: (NXFileBase*)folder error: (NSError*)error;
- (void) syncFileListFromServices:(NSArray *) services WithFileList:(NSArray *) fileList Error:(NSError *) error;
- (void) syncMetaDataUpdateUI: (NXFileBase*)metaData error: (NSError*)error;
@end

@interface NXSyncData : NSObject <NXServiceOperationDelegate>

@property (nonatomic, weak) id<NXSyncDataDelegate> delegate;

- (id) initWithOperationType:(NXOperationType)operationType;


- (void) updateSync: (NXBoundService*)service curFolder: (NXFileBase*)folder;
-(void) startServicesSync:(NSArray *)services withFolders:(NSMutableDictionary *) foldersDict;


- (void) updateMetaDataSync:(NXBoundService *)service curFile:(NXFileBase *)file;

- (void) cancelSync;
- (void) cancelMultiServiceSync;

@end


