//
//  NXLogAPI.m
//  nxrmc
//
//  Created by nextlabs on 7/14/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXLogAPI.h"
#import "NXRMCDef.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"

#import "NSData+zip.h"

@implementation NXLogAPIRequestModel
-(instancetype) init
{
    self = [super init];
    if (self) {
        _duid = @"";
        _owner = @"";
        _repositoryId = @"";
        _filePathId = @"";
        _fileName = @"";
        _filePath = @"";
        _activityData = @"";
    }
    
    return self;
    
}
@end

@implementation NXLogAPI

- (NSURLRequest *)generateRequestObject:(id)object {
    
    if (object && [object isKindOfClass:[NXLogAPIRequestModel class]]) {
        NXLogAPIRequestModel *requestModel = (NXLogAPIRequestModel *)object;
        NSString *separator = @",";
        NSArray *array = @[requestModel.duid,
                           requestModel.owner,
                           [NXLoginUser sharedInstance].profile.userId,
                           requestModel.operation,
                           [NXCommonUtils deviceID],
                           [NXCommonUtils getPlatformId],   //deviceType
                           requestModel.repositoryId,
                           requestModel.filePathId,
                           requestModel.fileName,
                           requestModel.filePath,
                           APPLICATION_NAME,
                           APPLICATION_PATH,
                           APPLICATION_PUBLISHER,
                           requestModel.accessResult,  //accessresult.
                           requestModel.accessTime,
                           requestModel.activityData];
        
        NSString *str = [array componentsJoinedByString:separator];
        str = [str stringByAppendingString:@"\n"];
        NSData *bodyData = [str dataUsingEncoding:NSUTF8StringEncoding];//TBD
        NSData *gzCompressedData = [bodyData gzip];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@", [NXCommonUtils currentRMSAddress], @"rs/log/activity", [NXLoginUser sharedInstance].profile.userId, [NXLoginUser sharedInstance].profile.ticket]]];
        [request setHTTPMethod:@"PUT"];
        [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Consume"];
        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        [request setValue:@"text/csv" forHTTPHeaderField:@"Consume"];

        [request setHTTPBody:gzCompressedData];
        
        [request addValue:self.reqFlag forHTTPHeaderField:RESTAPIFLAGHEAD];
        
        self.reqRequest = request;
    }
    return self.reqRequest;
}

- (Analysis)analysisReturnData {
    Analysis analysis = (id)^(NSString *returnData, NSError *error) {
        //restCode
        NXLogAPIResponse *model = [[NXLogAPIResponse alloc]init];
        [model analysisResponseStatus:[returnData dataUsingEncoding:NSUTF8StringEncoding]];
        return  model;
    };
    return analysis;
}

@end


@implementation NXLogAPIResponse

- (void)analysisResponseStatus:(NSData *)responseData {
    [self parseLogResponseJsonData: responseData];
}

- (void)parseLogResponseJsonData:(NSData *)data {
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
}

@end