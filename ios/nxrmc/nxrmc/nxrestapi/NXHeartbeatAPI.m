//
//  NXHeartbeatAPI.m
//  nxrmc
//
//  Created by nextlabs on 7/15/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXHeartbeatAPI.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"


#define TEXT_KEY                @"kText"
#define TRANSPARENT_RATION_KEY  @"kTransparentRatio"
#define FONT_NAME_KEY           @"kFontName"
#define FONT_SIZE_KEY           @"kFontSize"
#define FONT_COLOR_KEY          @"kFontColor"
#define ROTATION_KEY            @"kRotation"

@implementation NXHeartbeatAPI

- (NSURLRequest *)generateRequestObject:(id)object {
    
    NSData *bodyData = [self generateRequestBody:object];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [NXCommonUtils currentRMSAddress], @"rs/heartbeat"]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody:bodyData];
    self.reqRequest = request;
    
    return  self.reqRequest;
}

- (Analysis)analysisReturnData {
    Analysis analysis = (id)^(NSString *returnData, NSError *error) {
        //restCode
        NXHeartbeatAPIResponse *model = [[NXHeartbeatAPIResponse alloc]init];
        [model analysisResponseStatus:[returnData dataUsingEncoding:NSUTF8StringEncoding]];
        return  model;
    };
    return analysis;
}

- (NSData *)generateRequestBody:(id)object {
    NSDictionary *seria1 = @{@"name" : @"policyBundle",
                             @"serialNumber" : @""};
    NSDictionary *seria2 = @{@"name" : @"clientConfig",
                             @"seriaNumber" : @""};
    NSDictionary *seria3 = @{@"name" : @"classifyConfig",
                             @"serialNumber" : @""};
    NSDictionary *seria4 = @{@"name" : @"watermarkConfig",
                             @"serialNumber" : @""};
    NSArray *objects = @[seria1, seria2, seria3, seria4];
    
    NSDictionary *parmeters = @{@"ticket" : [NXLoginUser sharedInstance].profile.ticket,
                                @"objects" : objects,
                                @"platformId" : [NXCommonUtils getPlatformId],
                                @"userId": [NXLoginUser sharedInstance].profile.userId,
                                @"tenant" : [NXCommonUtils currentTenant]};
    
    NSDictionary *bodyDic = @{@"parameters" : parmeters};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDic options:NSJSONWritingPrettyPrinted error:&error];
    if (error) {
        NSLog(@"generate Membership json request data failed");
    }
    return jsonData;
}
@end

@implementation NXHeartbeatAPIResponse

- (void)analysisResponseStatus:(NSData *)responseData {
    [self parseHeartbeatResponseData:responseData];
}

- (void)parseHeartbeatResponseData:(NSData *)responseData {
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
        if ([results objectForKey:@"watermarkConfig"]) {
            NSDictionary *watermarkConfig = [results objectForKey:@"watermarkConfig"];
            if ([watermarkConfig objectForKey:@"content"]) {
                NSString *contentstr = [watermarkConfig objectForKey:@"content"];
                NSData *contentData = [contentstr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *obligations = [NSJSONSerialization JSONObjectWithData:contentData options:NSJSONReadingMutableLeaves error:&error];
                if ([obligations objectForKey:@"text"]) {
                    self.text = [obligations objectForKey:@"text"];
                }
                if ([obligations objectForKey:@"transparentRatio"]) {
                    self.transparentRatio = [obligations objectForKey:@"transparentRatio"];
                }
                if ([obligations objectForKey:@"fontName"]) {
                    self.fontName = [obligations objectForKey:@"fontName"];
                }
                if ([obligations objectForKey:@"fontSize"]) {
                    self.fontSize = [obligations objectForKey:@"fontSize"];
                }
                if ([obligations objectForKey:@"fontColor"]) {
                    self.fontColor = [obligations objectForKey:@"fontColor"];
                }
                if ([obligations objectForKey:@"rotation"]) {
                    self.rotation = [obligations objectForKey:@"rotation"];
                }
            }
        }
    }
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _text = [aDecoder decodeObjectForKey:TEXT_KEY];
        _transparentRatio = [aDecoder decodeObjectForKey:TRANSPARENT_RATION_KEY];
        _fontName = [aDecoder decodeObjectForKey:FONT_NAME_KEY];
        _fontSize = [aDecoder decodeObjectForKey:FONT_SIZE_KEY];
        _fontColor = [aDecoder decodeObjectForKey:FONT_COLOR_KEY];
        _rotation = [aDecoder decodeObjectForKey:ROTATION_KEY];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_text forKey:TEXT_KEY];
    [aCoder encodeObject:_transparentRatio forKey:TRANSPARENT_RATION_KEY];
    [aCoder encodeObject:_fontName forKey:FONT_NAME_KEY];
    [aCoder encodeObject:_fontSize forKey:FONT_SIZE_KEY];
    [aCoder encodeObject:_fontColor forKey:FONT_COLOR_KEY];
    [aCoder encodeObject:_rotation forKey:ROTATION_KEY];
}

@end
