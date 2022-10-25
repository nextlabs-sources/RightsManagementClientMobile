//
//  NXGetRepositoryDetailAPI.m
//  nxrmc
//
//  Created by EShi on 6/13/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXGetRepositoryDetailsAPI.h"
#import "XMLWriter.h"
#import "NXXMLDocument.h"

#import "NXLoginUser.h"
#import "NXCommonUtils.h"


@implementation NXRMSRepoItem

@end


#pragma mark ---------- NXGetRepositoryDetailsAPIRequest ----------
@interface NXGetRepositoryDetailsAPIRequest()
@end

@implementation NXGetRepositoryDetailsAPIRequest
#pragma mark - overwrite NXSuperRESTAPI SETTER/GETTER
-(NSString *) restRequestType
{
    return @"GetRepositoryDetailsService";
}

#pragma mark -  NXRESTAPIScheduleProtocol
-(NSURLRequest *) generateRequestObject:(id) object
{
    if (self.reqRequest == nil) {
        XMLWriter *xmlWriter = [[XMLWriter alloc] init];
        [xmlWriter writeStartDocument];
        [xmlWriter writeStartElement:@"getRepositoryDetailsRequest"];
        [xmlWriter writeAttribute:@"deviceId" value:[NXCommonUtils deviceID]];
        [xmlWriter writeAttribute:@"deviceType" value:@"MOBILE"];
        [xmlWriter writeAttribute:@"deviceOS" value:@"iOS"];
        [xmlWriter writeAttribute:@"APIVersion" value:@"7"];
        NSDate *nowTime = [NSDate date];
        NSString *timestamp = [NXCommonUtils convertToCCTimeFormat:nowTime];
        [xmlWriter writeAttribute:@"operationTime" value:timestamp];
        [xmlWriter writeAttribute:@"xmlns" value:@"http://nextlabs.com/rms/rmc"];
        {
            [xmlWriter writeStartElement:@"fetchSinceGMTTimestamp"];
            [xmlWriter writeAttribute:@"xmlns" value:@""];
            [xmlWriter writeCharacters:@"1970-01-01T01:01:01+08:00"];
            [xmlWriter writeEndElement];
        }
        
        [xmlWriter writeEndElement];
        [xmlWriter writeEndDocument];
        
        NSData *requestData = [xmlWriter toData];
        NSString *toStr = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", toStr);
        
        NSURL *apiURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/service/%@", [NXCommonUtils currentRMSAddress], self.reqType]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:apiURL];
        
        [request setHTTPMethod:@"POST"];
        NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]];
        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:requestData];
        
        // for RMS auth
        [request setValue:[NXLoginUser sharedInstance].profile.userId forHTTPHeaderField:@"userId"];
        [request setValue:[NXLoginUser sharedInstance].profile.ticket forHTTPHeaderField:@"ticket"];
        [request setValue:[NXLoginUser sharedInstance].profile.defaultMembership.tenantId  forHTTPHeaderField:@"tenantId"];
        self.reqRequest = request;

    }
    
    return self.reqRequest;
   
}

- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSString *returnData, NSError *error)
    {
        NXGetRepositoryDetailsAPIResponse *rmsResponse = [[NXGetRepositoryDetailsAPIResponse alloc] init];
        
        // analysis the return data
        NSData *contentData = [returnData dataUsingEncoding:NSUTF8StringEncoding];
        if (contentData) {
            
            NXXMLDocument* xmlDoc = [NXXMLDocument documentWithData:contentData error:nil];
            NXXMLElement* root = xmlDoc.root;
            NXXMLElement* repoItemsNode = [root childNamed:@"repoItems"];
            NSArray *repoItems = [repoItemsNode children];
            for (NXXMLElement *repo in repoItems) {
                NXRMSRepoItem *repoItem = [[NXRMSRepoItem alloc] init];
            repoItem.repoId = [repo childNamed:@"repoId"].value;
                repoItem.displayName = [repo childNamed:@"name"].value;
                repoItem.repoType = [repo childNamed:@"type"].value;
               
                NSString *isSharedStr = [repo childNamed:@"isShared"].value;
                [isSharedStr isEqualToString:@"true"]?(repoItem.isShared = YES) : (repoItem.isShared = NO);
                repoItem.account = [repo childNamed:@"accountName"].value;
                repoItem.accountId = [repo childNamed:@"accountId"].value;
                repoItem.refreshToken = [repo childNamed:@"token"].value;
                if (repoItem.refreshToken) {
                    repoItem.isAuthed = YES;
                }else
                {
                    repoItem.isAuthed = NO;
                }
                [rmsResponse.rmsRepoList addObject:repoItem];
            
            }
            
            // get status code
            [rmsResponse analysisXMLResponseStatus:contentData];
        }
        return rmsResponse;
        
    };
    
    return analysis;
}

@end

#pragma mark ---------- NXGetRepositoryDetailsAPIResponse ----------
@implementation NXGetRepositoryDetailsAPIResponse

#pragma mark - GETTER/SETTER
-(NSMutableArray *) rmsRepoList
{
    if (_rmsRepoList == nil) {
        _rmsRepoList = [[NSMutableArray alloc] init];
    }
    return _rmsRepoList;
}







@end


