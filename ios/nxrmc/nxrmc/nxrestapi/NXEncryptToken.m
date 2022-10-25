//
//  NXCryptoToken.m
//  nxrmc
//
//  Created by Kevin on 16/6/16.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import "NXEncryptToken.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"

@implementation NXEncryptTokenAPIRequestModel

- (instancetype)initWithUserId:(NSString *)userid ticket:(NSString *)ticket membership:(NSString *)membership agreement:(NSString *)agreement {
    if (self =[self init]) {
        self.userid = userid;
        self.ticket = ticket;
        self.membership = membership;
        self.agreement = agreement;
        self.count = 100;
    }
    return self;
}

- (NSData *)generateBodyData {
    NSDictionary *parameters = @{@"userId": self.userid,
                                 @"ticket": self.ticket,
                                 @"membership" : self.membership,
                                 @"agreement" : self.agreement,
                                 @"count" : [NSNumber numberWithInteger:self.count]};
    
    NSDictionary *bodyData = @{@"parameters" : parameters};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyData options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"generate Membership json request data failed");
    }
    return jsonData;
}

@end

@implementation NXEncryptTokenAPIResponse

- (void)analysisResponseStatus:(NSData *)responseData {
//    [super analysisResponseStatus:responseData];
    [self parseEncrypTokenResponseJsonData:responseData];
}

- (void)parseEncrypTokenResponseJsonData:(NSData *)data {
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
        if ([results objectForKey:@"tokens"]) {
            self.tokens = [results objectForKey:@"tokens"];
        }
        
        if ([results objectForKey:@"ml"]) {
            self.ml = [results objectForKey:@"ml"];
        }
    }
    
    
}

@end

@interface NXEncryptTokenAPI()

@property(nonatomic, strong) NXEncryptTokenAPIRequestModel *requestModel;

@end

@implementation NXEncryptTokenAPI

- (instancetype)initWithRequest:(NXEncryptTokenAPIRequestModel *)requestModel {
    if (self = [super init]) {
        self.requestModel = requestModel;
    }
    return self;
}

- (NSURLRequest *)generateRequestObject:(id)object {
    NSData *bodyData = [self.requestModel generateBodyData];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [NXCommonUtils currentRMSAddress], @"rs/token"]]];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/json" forHTTPHeaderField:@"consume"];
    [request setHTTPBody:bodyData];
    
    [request addValue:self.reqFlag forHTTPHeaderField:RESTAPIFLAGHEAD];
    
    return request;
}

- (Analysis)analysisReturnData {
    Analysis analysis = (id)^(NSString *returnData, NSError *error) {
        //restCode
        NXEncryptTokenAPIResponse *model = [[NXEncryptTokenAPIResponse alloc]init];
        [model analysisResponseStatus:[returnData dataUsingEncoding:NSUTF8StringEncoding]];
        return  model;
    };
    return analysis;
}

@end
