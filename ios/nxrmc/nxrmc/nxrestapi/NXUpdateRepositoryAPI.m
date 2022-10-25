//
//  NXUpdateRepositoryAPI.m
//  nxrmc
//
//  Created by EShi on 8/10/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXUpdateRepositoryAPI.h"
#import "NXRMCDef.h"
#import "NXXMLDocument.h"
#import "XMLWriter.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"

@implementation NXUpdateRepositoryRequest
-(NSURLRequest *) generateRequestObject:(id) object
{
    if (object && [object isKindOfClass:[NXRMCRepoItem class]]) {
        NSData *bodyData = [self genRequestBodyData:object];
        NSString *url = [NSString stringWithFormat:@"%@/service/UpdateRepoService", [NXCommonUtils currentRMSAddress]];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:url]];
        [request setHTTPMethod:@"POST"];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:bodyData];
        // for RMS auth head
        [request setValue:[NXLoginUser sharedInstance].profile.userId forHTTPHeaderField:@"userId"];
        [request setValue:[NXLoginUser sharedInstance].profile.ticket forHTTPHeaderField:@"ticket"];
        [request setValue:[NXLoginUser sharedInstance].profile.defaultMembership.tenantId forHTTPHeaderField:@"tenantId"];
        self.reqRequest = request;

    }
    return self.reqRequest;
}
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSString *returnData, NSError* error){
    
        
        NXUpdateRepositoryResponse *response = [[NXUpdateRepositoryResponse alloc] init];
        NSData *contentData = [returnData dataUsingEncoding:NSUTF8StringEncoding];
        if (contentData) {
            [response analysisXMLResponseStatus:contentData];
        }
        return response;
    };
    return analysis;
}

-(NSData *) genRequestBodyData:(id)object
{
    NXRMCRepoItem *repoItem = (NXRMCRepoItem *) object;
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    [xmlWriter writeStartDocumentWithEncodingAndVersion:@"utf-8" version:@"1.0"];
    [xmlWriter writeStartElement:@"updateRepositoryRequest"];
    [xmlWriter writeAttribute:@"deviceId" value:[NXCommonUtils deviceID]];
    [xmlWriter writeAttribute:@"deviceType" value:@"MOBILE"];
    [xmlWriter writeAttribute:@"deviceOS" value:@"iOS"];
    [xmlWriter writeAttribute:@"APIVersion" value:@"1"];
    NSDate *nowTime = [NSDate date];
    NSString *timestamp = [NXCommonUtils convertToCCTimeFormat:nowTime];
    [xmlWriter writeAttribute:@"operationTime" value:timestamp];
    [xmlWriter writeAttribute:@"xmlns" value:@"http://nextlabs.com/rms/rmc"];
    {
        
        [xmlWriter writeStartElement:@"repoId"];
        [xmlWriter writeAttribute:@"xmlns" value:@""];
        [xmlWriter writeCharacters:repoItem.service_id];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"name"];
        [xmlWriter writeAttribute:@"xmlns" value:@""];
        //[xmlWriter writeCharacters:repoItem.service_alias];
        [xmlWriter writeEndElement];
        
        [xmlWriter writeStartElement:@"token"];
        [xmlWriter writeAttribute:@"xmlns" value:@""];
        [xmlWriter writeCharacters:repoItem.service_account_token];
        [xmlWriter writeEndElement];
        
    }
    [xmlWriter writeEndElement];
    [xmlWriter writeEndDocument];
    
    NSData *dataContent = [xmlWriter toData];
    return dataContent;
}
@end

#pragma mark - NXUpdateRepositoryResponse
@implementation NXUpdateRepositoryResponse
@end
