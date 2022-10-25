//
//  NXSyncRepoHelper.h
//  nxrmc
//
//  Created by EShi on 6/12/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXSyncHelper.h"
#import "NXGetRepositoryDetailsAPI.h"

typedef void(^DownloadLocalRepoInfoComplection)(id object, NSError *error);

@interface NXSyncRepoHelper : NXSyncHelper
+(instancetype) sharedInstance;

-(void) deletePreviousFailedAddRepoRESTRequest:(NSString *) cachedFileFlag;
-(void) downloadServiceRepoInfoWithComplection:(DownloadLocalRepoInfoComplection) complectionBlcok;

-(void) intergateRMSRepoInfoWithRMSRepoDetail:(NXGetRepositoryDetailsAPIResponse * )getRepoResponse addRepoList:(NSMutableArray **) addRMCReposList delRepoList:(NSMutableArray **) delRMCReposList updateRepoList:(NSMutableArray **) updateRMCReposList;
@end
