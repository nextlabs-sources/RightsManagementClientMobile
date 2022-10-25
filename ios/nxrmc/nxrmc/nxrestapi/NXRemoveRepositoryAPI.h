//
//  NXRemoveRepositoryAPI.h
//  nxrmc
//
//  Created by EShi on 6/13/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSuperRESTAPI.h"

@interface NXRemoveRepositoryAPIRequest : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

// NXRESTAPIScheduleProtocol
-(NSURLRequest *) generateRequestObject:(id) object;
- (Analysis)analysisReturnData;
// overwrite NXSuperRESTAPI
- (NSData *) genRequestBodyData:(id)object;

@end

@interface NXRemoveRepositoryAPIResponse : NXSuperRESTAPIResponse
@end
