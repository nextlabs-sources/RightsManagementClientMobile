//
//  NXAddRepositoryAPIRequest.m
//  nxrmc
//
//  Created by EShi on 6/8/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXAddRepositoryAPI.h"
#import "NXRMCDef.h"
#import "NXXMLDocument.h"
#import "XMLWriter.h"
#import "NXLoginUser.h"
#import "NXCommonUtils.h"

#pragma mark ---------- NXAddRepositoryAPIRequest ----------
@interface NXAddRepositoryAPIRequest()

@end
@implementation NXAddRepositoryAPIRequest
#pragma mark - INIT
-(instancetype) initWithAddRepoItem:(NXRMCRepoItem *) repoItem
{
    self = [super init];
    if (self) {
        _addedService = repoItem;
    }
    return self;
}

#pragma mark - overwrite NXSuperRESTAPI SETTER/GETTER
-(NSString *) restRequestType
{
    return @"AddRepoService";
}

-(NSString *) restRequestFlag
{
    assert(self.addedService);
    return NXREST_UUID(self.addedService);
}

-(void) genRestRequest:(id)object
{
    // if the request is new create not from cached file, objcet should be NXBoudService type
    self.addedService = (NXRMCRepoItem *) object;
    
    NSData *dataContent = [self genRequestBodyData:object];
    
    NSString *url = [NSString stringWithFormat:@"%@/service/%@", [NXCommonUtils currentRMSAddress], self.reqType];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[dataContent length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:dataContent];
    
    
    // for RMS auth head
    [request setValue:[NXLoginUser sharedInstance].profile.userId forHTTPHeaderField:@"userId"];
    [request setValue:[NXLoginUser sharedInstance].profile.ticket forHTTPHeaderField:@"ticket"];
    [request setValue:[NXLoginUser sharedInstance].profile.defaultMembership.tenantId forHTTPHeaderField:@"tenantId"];
    self.reqRequest = request;

}

#pragma mark -  NXRESTAPIScheduleProtocol
-(NSURLRequest *) generateRequestObject:(id) object
{
    // if self.reqRequest is nil, means the object is from cached files
    // directly use it.
    if (self.reqRequest == nil) {
        [self genRestRequest:object];
    }
    
    return self.reqRequest;
}

- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSString *returnData, NSError* error)
    {
        NXAddRepositoryAPIResponse *response = [[NXAddRepositoryAPIResponse alloc] init];
        NSData *contentData = [returnData dataUsingEncoding:NSUTF8StringEncoding];
        if (contentData) {
            [response analysisXMLResponseStatus:contentData];
            NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:contentData error:nil];
            NXXMLElement* root = xmlDoc.root;
            NXXMLElement* repoIdNode = [root childNamed:@"repoId"];
            if (repoIdNode.value) {
                response.repoId = repoIdNode.value;
            }
        }
        return response;
    };
    
    return analysis;
}

#pragma mark - overwrite NXSuperRESTAPI
- (NSData *) genRequestBodyData:(id) object
{
    NXRMCRepoItem *repoItem = (NXRMCRepoItem *)object;
    XMLWriter *xmlWriter = [[XMLWriter alloc] init];
    [xmlWriter writeStartDocument];
    [xmlWriter writeStartElement:@"addRepositoryRequest"];
    [xmlWriter writeAttribute:@"deviceId" value:[NXCommonUtils deviceID]];
    [xmlWriter writeAttribute:@"deviceType" value:@"MOBILE"];
    [xmlWriter writeAttribute:@"deviceOS" value:@"iOS"];
    [xmlWriter writeAttribute:@"APIVersion" value:@"7"];
    NSDate *nowTime = [NSDate date];
    NSString *timestamp = [NXCommonUtils convertToCCTimeFormat:nowTime];
    [xmlWriter writeAttribute:@"operationTime" value:timestamp];
    [xmlWriter writeAttribute:@"xmlns" value:@"http://nextlabs.com/rms/rmc"];
    {
        
        
        [xmlWriter writeStartElement:@"repository"];
        [xmlWriter writeAttribute:@"xmlns" value:@""];
        {
            [xmlWriter writeStartElement:@"repoId"];
            [xmlWriter writeCharacters:RMC_DEFAULT_SERVICE_ID_UNSET];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"name"];
            // For RMS do not accept repo with the same name, we need make one
            // unified name with account
            [xmlWriter writeCharacters:repoItem.service_alias];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"type"];
            [xmlWriter writeCharacters:[NXCommonUtils rmcToRMSRepoType:repoItem.service_type]];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"isShared"];
            [xmlWriter writeCharacters:@"false"];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"preference"];
            [xmlWriter writeCharacters:@"preference"];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"accountName"];
            [xmlWriter writeCharacters:repoItem.service_account];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"accountId"];
            [xmlWriter writeCharacters:repoItem.service_account_id];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"token"];
            [xmlWriter writeCharacters:repoItem.service_account_token];
            [xmlWriter writeEndElement];
            
            [xmlWriter writeStartElement:@"creationTime"];
            [xmlWriter writeCharacters:[NSString stringWithFormat:@"%lld", (long long)([nowTime timeIntervalSince1970] * 1000)]];
            [xmlWriter writeEndElement];

            [xmlWriter writeStartElement:@"updatedTime"];
            [xmlWriter writeCharacters:[NSString stringWithFormat:@"%lld", (long long)([nowTime timeIntervalSince1970] * 1000)]];
            [xmlWriter writeEndElement];
            
        }
        [xmlWriter writeEndElement];
    }
    [xmlWriter writeEndElement];
    [xmlWriter writeEndDocument];
    
    NSData *dataContent = [xmlWriter toData];
    return dataContent;
}


@end


#pragma mark ---------- NXAddRepositoryAPIResponse ----------
@implementation NXAddRepositoryAPIResponse
@end
