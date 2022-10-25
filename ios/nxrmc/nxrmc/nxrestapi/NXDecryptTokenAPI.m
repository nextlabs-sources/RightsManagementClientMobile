//
//  NXDecryptTokenAPI.m
//  nxrmc
//
//  Created by nextlabs on 6/23/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXDecryptTokenAPI.h"
#include "NXRMCDef.h"
#import "NXCommonUtils.h"

@implementation NXDecryptTokenAPIRequestModel


- (NSData *)generateBodyData {
    NSDictionary *parameters = @{@"userId": self.userid,
                                 @"ticket": self.ticket,
                                 @"tenant": self.tenant,
                                 @"owner" : self.owner,
                                 @"agreement" : self.agreement,
                                 @"duid" : self.duid,
                                 @"ml" : self.ml};
////                                 @"pql" : self.pql,
//                                 @"sig" : self.sig};
////                                 @"ml" : self.ml};
    NSDictionary *bodyData = @{@"parameters" : parameters};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyData options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"generate Membership json request data failed");
    }
    NSString *str = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"The res str is %@", str);
    return jsonData;
}

@end

@implementation NXDecryptTokenResponse

- (void)analysisResponseStatus:(NSData *)responseData {
//    [super analysisResponseStatus:responseData];
    [self parseDecryptTokenResponseJsonData:responseData];
}

- (void)parseDecryptTokenResponseJsonData:(NSData *)data {
    NSError *error;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error) {
        NSLog(@"parse data failed:%@", error.localizedDescription);
        return;
    }
    if ([result objectForKey:@"statusCode"]) {
        self.rmsStatuCode = [[result objectForKey:@"statusCode"] integerValue];
    }
    
    if ([result objectForKey:@"message"]) {
        self.rmsStatuMessage = [result objectForKey:@"message"];
    }
    
    if ([result objectForKey:@"results"]) {
        NSDictionary *results = [result objectForKey:@"results"];
        if ([results objectForKey:@"token"]) {
            self.token = [results objectForKey:@"token"];
        }
    }
}

@end

@interface NXDecryptTokenAPI()

@property(nonatomic, strong) NXDecryptTokenAPIRequestModel *requestModel;

@end

@implementation NXDecryptTokenAPI

- (instancetype)initWithRequest:(NXDecryptTokenAPIRequestModel *)requestModel {
    if (self = [super init]) {
        self.requestModel = requestModel;
    }
    return self;
}

- (NSURLRequest *)generateRequestObject:(id)object {
    NSData *bodyData = [self.requestModel generateBodyData];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [NXCommonUtils currentRMSAddress], @"rs/token"]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"consume"];
    [request setHTTPBody:bodyData];
    [request addValue:self.reqFlag forHTTPHeaderField:RESTAPIFLAGHEAD];
    return request;
}

- (Analysis)analysisReturnData {
    Analysis analysis = (id)^(NSString *returnData, NSError *error) {
        //restCode
        NXDecryptTokenResponse *model = [[NXDecryptTokenResponse alloc]init];
        [model analysisResponseStatus:[returnData dataUsingEncoding:NSUTF8StringEncoding]];
        return  model;
    };
    return analysis;
}

@end
