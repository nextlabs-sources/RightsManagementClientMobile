//
//  NXFileListInfoDataProvider.h
//  nxrmc
//
//  Created by EShi on 10/14/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NXFileBase.h"
#import "NXFile.h"
#import "NXFolder.h"
#import "NXServiceOperation.h"
#import "NXCommonUtils.h"
#import "NXRMCDef.h"
#import "NXCacheManager.h"
#import "NXSyncData.h"
#import "NXNetworkHelper.h"

@class NXFileListInfoDataProvider;
@protocol NXFileListInfoDataProviderDelegate <NSObject>

@required
- (void) fileListInfo: (NSArray *)files
            InServices:(NSArray *)services
               Folders:(NSMutableDictionary *) folders
                error:(NSError *)err
      fromDataProvider:(NXFileListInfoDataProvider *) dataProvider
       additionalInfo:(NSDictionary *) additionalInfo;

-(void) updateFileList:(NSArray *) files InServices:(NSArray *) services Folders:(NSMutableDictionary *) folders error:(NSError *) err fromDataProvider:(NXFileListInfoDataProvider *) dataProvider;

@end

@interface NXFileListInfoDataProvider : NSObject<NXSyncDataDelegate>
@property(nonatomic, weak) id<NXFileListInfoDataProviderDelegate> delegate;
@property(nonatomic, strong) NXFileBase *curFolder;


-(void) getFilesByService:(NXBoundService *) service Folder:(NXFileBase *) folder needReadCache:(BOOL) needReadCache;
-(void) getFileByServices:(NSArray *)services folders:(NSMutableDictionary *) foldersDict needReadCache:(BOOL) needReadCache;

-(void) syncFileByServices:(NSArray *)services withFolders:(NSMutableDictionary *) foldersDict;
-(void) syncFileByServices:(NSArray *)services withFolder:(NXFileBase *) folder;

-(void) cancelSyncFileList;
-(BOOL) cancelServiceGetFiles;
@end
