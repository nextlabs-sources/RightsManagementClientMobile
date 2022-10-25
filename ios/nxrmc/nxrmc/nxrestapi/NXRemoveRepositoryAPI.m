//
//  NXRemoveRepositoryAPI.m
//  nxrmc
//
//  Created by EShi on 6/13/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXRemoveRepositoryAPI.h"
#import "NXRMCDef.h"
#import "NXBoundService.h"
#import "NXXMLDocument.h"
#import "XMLWriter.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"

#pragma mark ---------- NXRemoveRepositoryAPIRequest ----------
@implementation NXRemoveRepositoryAPIRequest
#pragma mark - overwrite NXSuperRESTAPI
-(NSString *) restRequestType
{
    return @"RemoveRepoService";
}

-(void) genRestRequest:(id)object
{
    NSData *bodyData = [self genRequestBodyData:object];
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/service/%@", [NXCommonUtils currentRMSAddress], self.restRequestType]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPBody:bodyData];
    [request setHTTPMethod:@"POST"];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[bodyData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // for RMS auth head
    [request setValue:[NXLoginUser sharedInstance].profile.userId forHTTPHeaderField:@"userId"];
    [request setValue:[NXLoginUser sharedInstance].profile.ticket forHTTPHeaderField:@"ticket"];
    [request setValue:[NXLoginUser sharedInstance].profile.defaultMembership.tenantId  forHTTPHeaderField:@"tenantId"];
    self.reqRequest = request;
}
#pragma mark -  NXRESTAPIScheduleProtocol
-(NSURLRequest *) generateRequestObject:(id) object
{
    // if object class is NSData, means the object is from cached files
    // directly use it.
    if (self.reqRequest == nil) {
        [self genRestRequest:object];
    }
    
    
    return self.reqRequest;

}

- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSString *returnData, NSError *error)
    {
        NXRemoveRepositoryAPIResponse *response = [[NXRemoveRepositoryAPIResponse alloc] init];
        NSData *contentData = [returnData dataUsingEncoding:NSUTF8StringEncoding];
        if (contentData) {
            [response analysisXMLResponseStatus:contentData];
        }
        return response;
    };
    
    return analysis;
}

#pragma mark - overwrite NXSuperRESTAPI
- (NSData *) genRequestBodyData:(id)object
{
    
    NSString *deleteServiceId = (NSString *) object;
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    [xmlWriter writeStartDocument];
    [xmlWriter writeStartElement:@"removeRepositoryRequest"];
    [xmlWriter writeAttribute:@"deviceId" value:[NXCommonUtils deviceID]];
    [xmlWriter writeAttribute:@"deviceType" value:@"MOBILE"];
    [xmlWriter writeAttribute:@"deviceOS" value:@"iOS"];
    [xmlWriter writeAttribute:@"APIVersion" value:@"7"];
    NSDate *nowTime = [NSDate date];
    NSString *timestamp = [NXCommonUtils convertToCCTimeFormat:nowTime];
    [xmlWriter writeAttribute:@"operationTime" value:timestamp];
    [xmlWriter writeAttribute:@"xmlns" value:@"http://nextlabs.com/rms/rmc"];
    {
        [xmlWriter writeStartElement:@"repoId"];
        [xmlWriter writeAttribute:@"xmlns" value:@""];
        {
            [xmlWriter writeCharacters:deleteServiceId];
        }
        [xmlWriter writeEndElement];
    }
    [xmlWriter writeEndElement];
    [xmlWriter writeEndDocument];
    
    NSData *bodyData = [xmlWriter toData];
    return bodyData;

}
@end

#pragma mark ---------- NXRemoveRepositoryAPIResponse ----------
@implementation NXRemoveRepositoryAPIResponse
@end

