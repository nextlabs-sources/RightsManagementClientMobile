//
//  NXRestAPI.h
//  nxrmc
//
//  Created by Kevin on 15/6/24.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NXLoginUser;
@protocol NXURLConnectionDelegate <NSObject>

@required
-(void) postResponse: (NSURL*) url result: (NSString*)result data:(NSData *) data error: (NSError*)err;
@optional
-(void) postResponse: (NSURL*) url progress:(NSNumber *)progress;
-(void) postResponse:(NSURL *)url requestFlag:(NSString *) reqFlag result:(NSString *)result error:(NSError *)err;

@end
@interface NXURLConnection : NSObject

//- (void) sendGetRequest: (NSURL*)url cert: (NSString *)cert;
//- (void) sendPostRequest: (NSURL*)url cert: (NSString*)cert postData: (NSData*)postData;
//- (void) sendPostRequest: (NSURL *)url cert:(NSString*)cert postData:(NSData *)postData contentType:(NSString *)type;
- (void) sendRequest:(NSURLRequest *) request;
- (void) cancel;

@property (nonatomic, weak) id<NXURLConnectionDelegate> delegate;


@end

@interface NXRESTAPIVersion : NSObject

@property (nonatomic, assign) int major;
@property (nonatomic, assign) int minor;
@property (nonatomic, assign) int maintenance;
@property (nonatomic, assign) int patch;
@property (nonatomic, assign) int build;

@end

@protocol NXRestAPIDelegate <NSObject>

@required
- (void) restAPIResponse:(NSURL*) url result: (NSString*)result data:(NSData *) data error: (NSError*)err;
@optional
- (void) restAPIResponse:(NSURL *)url progress:(NSNumber *)progress;
- (void) restAPIResponse:(NSURL *)url requestFlag:(NSString *) reqFlag result:(NSString *)result error:(NSError *)err;

@end
@interface NXRestAPI : NSObject <NXURLConnectionDelegate>

+ (NXRESTAPIVersion*) versionMake: (int) major minor: (int)minor maintenance: (int)maintenance patch: (int) patch build: (int)build;

- (void) convertFile: (int) agentId fileContent: (NSData*) data fileName: (NSString*)name toFormat: (NSString*)fmt isNxl: (BOOL)nxl;


- (void) sendRESTRequest:(NSURLRequest *) restRequest;

- (void) cancel;

// new Restful API
- (void) getEncryptionTokens;

@property(nonatomic, weak) id<NXRestAPIDelegate> delegate;
@property (nonatomic) NSInteger increateId;
@end
