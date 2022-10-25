//
//  NXAddRepositoryAPIRequest.h
//  nxrmc
//
//  Created by EShi on 6/8/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSuperRESTAPI.h"
#import "NXRESTAPIScheduleProtocol.h"
#import "NXBoundService.h"

@interface NXAddRepositoryAPIRequest : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>
// should use initWithAddRepoItem for init a NXAddRepositoryAPIRequest!!!!
// for before send NXAddRepositoryAPIRequest, it's property NXRMCRepoItem *addedService; should not be nil
// The NXRESTAPITransferCenter need 'addedService' to generate request flag, if 'addedService' if nil, crash
-(instancetype) initWithAddRepoItem:(NXRMCRepoItem *) repoItem;

// NXRESTAPIScheduleProtocol
-(NSURLRequest *) generateRequestObject:(id) object;
- (Analysis)analysisReturnData;
// for generate reqFlag which is correspond the repo info
@property(nonatomic, strong) NXRMCRepoItem *addedService;
// overwirte NXSuperRESTAPI
- (NSData *) genRequestBodyData:(id) object;
@end







@interface NXAddRepositoryAPIResponse : NXSuperRESTAPIResponse
@property(nonatomic, strong) NSString *repoId;

@end
