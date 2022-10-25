//
//  NXSuperRESTAPI.h
//  nxrmc
//
//  Created by EShi on 6/7/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXRESTAPIScheduleProtocol.h"
#import "NXRMCStruct.h"

typedef void(^RequestCompletion)(id response, NSError *error);

@interface NXSuperRESTAPI : NSObject<NSCoding>
@property(nonatomic, strong) NSURLRequest *reqRequest;
@property(nonatomic, strong, readonly) NSString *reqFlag;
@property(nonatomic, strong, readonly) NSString *reqType;
@property(nonatomic, strong, readonly) NSString *reqService;
@property(nonatomic, strong, readonly) NSData *reqBodyData;
@property(nonatomic, copy) RequestCompletion completion;

-(void) requestWithObject:(id) object Completion:(RequestCompletion) completion;
-(NSString *) restRequestType;
-(NSString *) restRequestFlag;

// Just hold rest request object and save it. Used in the case do not send REST request, but only serialize it to disk. So need subclass generate restRequest and pass it to
// NXSuperRESTAPI to hold it
- (void) genRestRequest:(id) object;
- (NSData *) genRequestBodyData:(id) object; // need overwrite by subchild


// Generate URL Request Tools function
-(NSURLRequest *) generatePOSTRequestWithPostData:(NSData *) postData contentType:(NSString *) contentType;
@end

@interface NXSuperRESTAPIResponse: NSObject<NSCoding>

@property(nonatomic) NSInteger rmsStatuCode;
@property(nonatomic, strong) NSString *rmsStatuMessage;

-(void) analysisResponseStatus:(NSData *) responseData;
- (void) analysisXMLResponseStatus:(NSData *)responseData;

@end
