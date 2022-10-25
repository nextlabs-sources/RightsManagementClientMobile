//
//  NXSyncHelper.m
//  nxrmc
//
//  Created by EShi on 7/8/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSyncHelper.h"
#import "NXCacheManager.h"
#import "NXRMCDef.h"
#import "NXRMCStruct.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"
#import "NXRemoveRepositoryAPI.h"
@interface NXSyncHelper()
@property(nonatomic, readwrite, strong) dispatch_queue_t uploadPerviousFailedRESTQueue;
@end

@implementation NXSyncHelper
+(instancetype) sharedInstance
{
    static NXSyncHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self  alloc] init];
    });
    return instance;
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        NSString *queueName = [NSString stringWithFormat:@"com.nextlabs.rightsmanagementclient.%@", NSStringFromClass([self class])];
        _uploadPerviousFailedRESTQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


-(void) cacheRESTAPI:(NXSuperRESTAPI *) restAPI cacheURL:(NSURL *) cacheURL
{
    dispatch_async(_uploadPerviousFailedRESTQueue, ^{
        [NXCacheManager cacheRESTReq:restAPI cacheURL:cacheURL];

    });
}

-(void) uploadPreviousFailedRESTRequestWithCachedURL:(NSURL *) cachedURL mustAllSuccess:(BOOL) mustAllSuccess Complection:(UploadFailedRESTRequestComplection) complectionBlock
{
    dispatch_async(_uploadPerviousFailedRESTQueue, ^{
        
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        
        NSArray *fileList = [fileManager contentsOfDirectoryAtURL:cachedURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants error:&error];
        fileList = [fileList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"self.absoluteString ENDSWITH '%@'", NXREST_CACHE_EXTENSION]]];
        
        if (fileList.count == 0) {
            complectionBlock(nil, nil);
            return;
        }
        
        if (error) {
            complectionBlock(nil, error);
            return;
        }
        
        __block BOOL errOccured = NO;
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_apply(fileList.count, queue, ^(size_t index) {
            
            if (errOccured == YES && mustAllSuccess == YES) { // if error occured and mustAllSuccess is YES, just return
                return;
            }
            NSData *restReqData = [NSData dataWithContentsOfURL:fileList[index]];
            if (restReqData) {
                // although dispatch_apply is sync, but we still need wait all Network operation return
                // so there need semaphore to wait.
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                NXSuperRESTAPI *restAPI = [NSKeyedUnarchiver unarchiveObjectWithData:restReqData];
                [restAPI requestWithObject:restAPI.reqBodyData Completion:^(id response, NSError *error) {
                    if ([response isKindOfClass:[NXSuperRESTAPIResponse class]]) {
                        NXSuperRESTAPIResponse *restResponse = (NXSuperRESTAPIResponse *) response;
                        if (!error && restResponse.rmsStatuCode != 0 && restResponse.rmsStatuCode != 200) {  // no net error, but have service error
                            error = [NSError errorWithDomain:NX_ERROR_REST_DOMAIN code:NXRMC_ERROR_CODE_REST_UPLOAD_FAILED userInfo:nil];
                        }
                        if (restResponse.rmsStatuCode == 2 || restResponse.rmsStatuCode == 6 || restResponse.rmsStatuCode == 4) { //2 repo not found 6 User already has this repository  7 means the same display name of repo 4 means duplicate repo name
                            error = nil;  // tread as not error if repo not found at RMS
                        }
                    }
                    
                    if (error) {
                        errOccured = YES; // BOOL type do not need lock
                        
                    }else
                    {
                        // no error occur, delete the cache file
                        [fileManager removeItemAtURL:fileList[index] error:nil];
                    }
                    dispatch_semaphore_signal(semaphore);
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            
        }); // end of dispatch_apply
        
       
        // Only all rest api finished, we do next thing
        if (errOccured) {
            error = [NSError errorWithDomain:NX_ERROR_REST_DOMAIN code:NXRMC_ERROR_CODE_REST_UPLOAD_FAILED userInfo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complectionBlock) {
                    complectionBlock(nil, error);
                    
                }
            });
            
        }else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (complectionBlock) {
                    complectionBlock(nil, nil);
                }
            });
        }
    });
}

@end
