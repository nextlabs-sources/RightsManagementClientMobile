//
//  NXGetRepositoryDetailAPI.h
//  nxrmc
//
//  Created by EShi on 6/13/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSuperRESTAPI.h"

@interface NXRMSRepoItem : NSObject
@property(nonatomic, strong) NSString * repoId;
@property(nonatomic, strong) NSString *displayName;
@property(nonatomic, strong) NSString *repoType;
@property(nonatomic) BOOL isShared;
@property(nonatomic) BOOL isAuthed;
@property(nonatomic, strong) NSString *account;
@property(nonatomic, strong) NSString *accountId;
@property(nonatomic, strong) NSString *refreshToken;
@end

@interface NXGetRepositoryDetailsAPIRequest : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>
// NXRESTAPIScheduleProtocol
-(NSURLRequest *) generateRequestObject:(id) object;
- (Analysis)analysisReturnData;
@end

@interface NXGetRepositoryDetailsAPIResponse : NXSuperRESTAPIResponse
@property(nonatomic, strong) NSMutableArray * rmsRepoList;

@end
