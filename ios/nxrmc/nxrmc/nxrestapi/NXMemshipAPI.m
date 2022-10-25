//
//  NXMemshipAPI.m
//  nxrmc
//
//  Created by nextlabs on 6/24/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXMemshipAPI.h"
#import "NXLoginUser.h"

@implementation NXMemshipAPIRequestModel

- (instancetype)initWithUserId:(NSString *)userid ticket:(NSString *)ticket membership:(NSString *)membership publickey:(NSString *)publickey {
    if (self = [super init]) {
        self.userId = userid;
        self.tickect = ticket;
        self.membership = membership;
        self.publicKey = publickey;
    }
    return self;
}
- (NSData *)generateBodyData {
    NSDictionary *parameters = @{@"userId": self.userId,
                                 @"ticket": self.tickect,
                                 @"membership" : self.membership,
                                 @"publicKey" : self.publicKey};
    
    NSDictionary *bodyData = @{@"parameters" : parameters};
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyData options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"generate Membership json request data failed");
    }
    return jsonData;
}

@end

@implementation NXMemshipAPIResponse

- (void)analysisResponseStatus:(NSData *)responseData {
//    [super analysisResponseStatus:responseData];
    [self parseMembershipResponseJsonData:responseData];
}
- (void)parseMembershipResponseJsonData:(NSData *)data {
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
        NSDictionary *certificatesResult = [result objectForKey:@"results"];
        NSString *certficatesStr = [certificatesResult objectForKey:@"certficates"];
        if (certficatesStr) {
            NSArray *array = [certficatesStr componentsSeparatedByString:@"-----BEGIN CERTIFICATE-----"];
            self.results = [[NSMutableDictionary alloc]init];
            int index = 0;
            for (int i = 0; i < array.count; i++) {
                if ([[array objectAtIndex:i] compare:@""] != NSOrderedSame) {
                    NSString *result = [NSString stringWithFormat:@"-----BEGIN CERTIFICATE-----%@", [array objectAtIndex:i]];
                    [self.results setValue:result forKey:[NSString stringWithFormat:@"certficate%d",index+1]];
                    ++index;
                }
            }
        }
    }
}

@end

@interface NXMemshipAPI()

@property(nonatomic, strong) NXMemshipAPIRequestModel *requestModel;

@end

@implementation NXMemshipAPI

- (instancetype)initWithRequest:(NXMemshipAPIRequestModel *)requestModel {
    if (self =[super init]) {
        self.requestModel = requestModel;
    }
    return self;
}

- (NSURLRequest *)generateRequestObject:(id)object {
    NSData *bodyData = [self.requestModel generateBodyData];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [NXLoginUser sharedInstance].profile.rmserver, @"rs/membership"]];
    [request setURL: url];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/json" forHTTPHeaderField:@"consume"];
    [request setHTTPBody:bodyData];
    
    [request addValue:self.reqFlag forHTTPHeaderField:RESTAPIFLAGHEAD];
    
    return request;
}

- (Analysis)analysisReturnData {
    Analysis analysis = (id)^(NSString *returnData, NSError *error) {
            NXMemshipAPIResponse *model = [[NXMemshipAPIResponse alloc]init];
            [model analysisResponseStatus:[returnData dataUsingEncoding:NSUTF8StringEncoding]];
            return  model;
    };
    return analysis;
}

@end
