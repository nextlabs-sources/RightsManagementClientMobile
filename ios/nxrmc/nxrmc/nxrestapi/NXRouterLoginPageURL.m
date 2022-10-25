//
//  NXRouterLoginPageURL.m
//  nxrmc
//
//  Created by Kevin on 16/6/29.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import "NXRouterLoginPageURL.h"
#import "NXCommonUtils.h"
#import "NXRMCDef.h"

@interface NXRouterLoginPageURL ()
{
    NSString* tenantName;
}

@end

@implementation NXRouterLoginPageURL

-(instancetype) initWithRequest:(NSString *)tenant
{
    if (self = [super init]) {
        tenantName = tenant;
    }
    
    return self;
}

- (NSURLRequest *)generateRequestObject:(id)object {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    NSString* url= [NSString stringWithFormat:@"%@/%@/%@", [NXCommonUtils currentSkyDrm], @"router/rs/q/tenant", tenantName];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    
    
    [request addValue:self.reqFlag forHTTPHeaderField:RESTAPIFLAGHEAD];
    
    return request;
}

- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSString *returnData, NSError *error) {
        //restCode
        NXRouterLoginPageURLResponse *response = [[NXRouterLoginPageURLResponse alloc] init];
        [response analysisResponseStatus:[returnData dataUsingEncoding:NSUTF8StringEncoding]];
        return  response;
    };
    return analysis;
}

@end


@implementation NXRouterLoginPageURLResponse

- (void)analysisResponseStatus:(NSData *)responseData {
    [self parseRouterLoginResponseJsonData:responseData];
}

- (void)parseRouterLoginResponseJsonData:(NSData *)responseData {
    NSError *error;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
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
        if ([results objectForKey:@"server"]) {
            self.loginPageURLstr = [results objectForKey:@"server"];
            [NXCommonUtils updateRMSAddress:self.loginPageURLstr];
        }
    }
}

@end
