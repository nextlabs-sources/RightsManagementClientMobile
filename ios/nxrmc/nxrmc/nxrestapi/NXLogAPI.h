//
//  NXLogAPI.h
//  nxrmc
//
//  Created by nextlabs on 7/14/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSuperRESTAPI.h"

@interface NXLogAPIRequestModel : NSObject

@property(nonatomic, strong) NSString *duid;
@property(nonatomic, strong) NSString *owner;
@property(nonatomic, strong) NSNumber *operation; // view, edit, share etc, the integer is same with NXRights.
@property(nonatomic, strong) NSString *repositoryId;
@property(nonatomic, strong) NSString *filePathId;
@property(nonatomic, strong) NSString *fileName;
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, strong) NSString *activityData;
@property(nonatomic, strong) NSNumber *accessTime;
@property(nonatomic, strong) NSNumber *accessResult;  // 1 means success, 0 means fail

@end

@interface NXLogAPI : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

@end


@interface NXLogAPIResponse : NXSuperRESTAPIResponse

@end