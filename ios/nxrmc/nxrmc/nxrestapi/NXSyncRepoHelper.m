//
//  NXSyncRepoHelper.m
//  nxrmc
//
//  Created by EShi on 6/12/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSyncRepoHelper.h"
#import "NXCacheManager.h"
#import "NXRMCDef.h"
#import "NXRMCStruct.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"
#import "NXRemoveRepositoryAPI.h"


@interface NXSyncRepoHelper()

@end

@implementation NXSyncRepoHelper

+(instancetype) sharedInstance
{
    static NXSyncRepoHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


-(instancetype) init
{
    self = [super init];
    return self;
}




-(void) deletePreviousFailedAddRepoRESTRequest:(NSString *) cachedFileFlag
{
    if (cachedFileFlag) {
        NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@":/\\?%*|\"<>"];
        NSString *fileName = [[cachedFileFlag componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
        
        NSURL *cachedURL = [NXCacheManager getRESTCacheURL];
        cachedURL = [cachedURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", fileName, NXREST_CACHE_EXTENSION]];;
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtURL:cachedURL error:nil];
    }
}


-(void) downloadServiceRepoInfoWithComplection:(DownloadLocalRepoInfoComplection) complectionBlcok
{
}

-(void) intergateRMSRepoInfoWithRMSRepoDetail:(NXGetRepositoryDetailsAPIResponse * )getRepoResponse addRepoList:(NSMutableArray **) addRMCReposList delRepoList:(NSMutableArray **) delRMCReposList updateRepoList:(NSMutableArray **) updateRMCReposList
{
    *addRMCReposList = [[NSMutableArray alloc] init];
    *delRMCReposList = [NSMutableArray arrayWithArray:[NXLoginUser sharedInstance].boundServices];
    *updateRMCReposList = [[NSMutableArray alloc] init];
    
    NSMutableArray *addRMSReposList = [NSMutableArray arrayWithArray:getRepoResponse.rmsRepoList];
    
    NSMutableArray *needLessOneDriveList = [[NSMutableArray alloc] init];  // for we only support one onedrive account, we need make sure there is only one account on RMS
    
    BOOL needDelOldOneDriveAccount = NO;
    
    for (NXRMSRepoItem *rmsRepoItem in getRepoResponse.rmsRepoList) {
        
        for (NXBoundService *boundService in [NXLoginUser sharedInstance].boundServices) {
            if ([[NXCommonUtils rmcToRMSRepoType:boundService.service_type] isEqualToString:rmsRepoItem.repoType] && [boundService.service_account_id isEqualToString:rmsRepoItem.accountId]) {  // repo type is same and accountId is same, so same repo
                [addRMSReposList removeObject:rmsRepoItem];
                [*delRMCReposList removeObject:boundService];
                
                // if only repoId or dispaly name is different, make local repoId the same as RMS
                if (![boundService.service_id isEqualToString:rmsRepoItem.repoId] || ![boundService.service_alias isEqualToString:rmsRepoItem.displayName]) {
                    boundService.service_id = rmsRepoItem.repoId;
                    if (![boundService.service_alias isEqualToString:rmsRepoItem.displayName]) {
                        NSString *serviceAlias = boundService.service_alias;
                        boundService.service_alias = rmsRepoItem.displayName;
                        // There need notify others service alias changed
                        NSDictionary *userInfo = @{serviceAlias:boundService.service_alias};
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_REPO_ALIAS_UPDATED object:nil userInfo:userInfo];
                        });
                    }
                    [*updateRMCReposList addObject:boundService];
                }
                     
            } // if repo type same and accountId same
            
            if (boundService.service_type.integerValue == kServiceOneDrive) { // means RMC have one new Onedrive accout, do not need get the RMS onedrive account
                needDelOldOneDriveAccount = YES;
            }
        } // for every [NXLoginUser sharedInstance].boundServices
    } // for every getRepoResponse.rmsRepoList
    
    // =========== special for OneDrive =================
    for (NXRMSRepoItem *repoItem in addRMSReposList) {
        if ([repoItem.repoType isEqualToString:RMS_REPO_TYPE_ONEDRIVE]) {
            //                NXRemoveRepositoryAPIRequest *removeReq = [[NXRemoveRepositoryAPIRequest alloc] init];
            //                [removeReq requestWithObject:repoItem.repoId Completion:^(id response, NSError *error) {
            //
            //                }];
            [needLessOneDriveList addObject:repoItem];
        }
    }
    // do delete useless Onedrive account on RMS
    if (needDelOldOneDriveAccount) {
        for (NXRMSRepoItem *repoItem in needLessOneDriveList) {
            [addRMSReposList removeObject:repoItem];
        }
        
    }else if(needLessOneDriveList.count > 1)// only store one one drive account on local
    {
        for (int i = 1; i < needLessOneDriveList.count; ++i) {
            [addRMSReposList removeObject:needLessOneDriveList[i]];
        }
    }
    
   
    
    
    //2. convert NXRMSRepoItem stored in addRMSReposList into NXBoundService type
    for (NXRMSRepoItem *rmsAddRepoItem in addRMSReposList) {
        NXRMCRepoItem *rmcAddRepoItem = [[NXRMCRepoItem alloc] init];
        rmcAddRepoItem.service_id = rmsAddRepoItem.repoId;
        rmcAddRepoItem.service_type = [NXCommonUtils rmsToRMCRepoType:rmsAddRepoItem.repoType];
        rmcAddRepoItem.service_alias =rmsAddRepoItem.displayName;
        rmcAddRepoItem.service_account = rmsAddRepoItem.account;
        rmcAddRepoItem.service_isAuthed = rmsAddRepoItem.isAuthed;
        rmcAddRepoItem.service_account_id = rmsAddRepoItem.accountId;
        rmcAddRepoItem.service_account_token = rmsAddRepoItem.refreshToken;
        rmcAddRepoItem.user_id = [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId];
        
        [*addRMCReposList addObject:rmcAddRepoItem];
    }

}
@end
