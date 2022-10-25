//
//  NXSharingAPI.m
//  nxrmc
//
//  Created by EShi on 7/4/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSharingAPI.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"

#pragma mark - -------------NXSharingAPIRequest-------------
@implementation NXSharingAPIRequest

-(NSURLRequest *) generateRequestObject:(id) object
{
    if (object && [object isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *parameters =(NSDictionary *) object;
        
        NSDictionary *jsonDict = @{@"parameters" : parameters};
        NSError *error;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&error];
        
        
        NSString* urlStr= [NSString stringWithFormat:@"%@/%@", [NXCommonUtils currentRMSAddress], @"rs/share"];

        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlStr]];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"consume"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:bodyData];
        
        self.reqRequest = request;
    }
    
    return self.reqRequest;  // return self.reqRequest for if we decode from cached file, the self.reqRequest is from cache file, not above codes
}
- (Analysis)analysisReturnData
{
    Analysis ret = (id)^(NSString *returnData, NSError *error)
    {
         NXSharingAPIResponse *response = [[NXSharingAPIResponse alloc] init];
        if (returnData) {
            NSData *data = [returnData dataUsingEncoding:NSUTF8StringEncoding];
           
            [response analysisResponseStatus:data];
        }
        return response;
    };
    
    return ret;
}
@end

#pragma mark - -------------NXSharingAPIResponse-------------
@implementation NXSharingAPIResponse
@end
