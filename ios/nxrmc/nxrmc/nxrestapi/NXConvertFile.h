//
//  NXConvertFile.h
//  nxrmc
//
//  Created by helpdesk on 7/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXConvertFileResponse : NSObject <NSXMLParserDelegate>

@property(nonatomic, strong) NSString* fileName;
@property(nonatomic, strong) NSString* binaryFile;
@property(nonatomic, strong) NSString* errorCode;
@property(nonatomic, strong) NSString* errorMsg;
@property(nonatomic, strong) NSString* checksum;

@end

typedef void(^completionBlock)(NSString* filename, NSError* error);

@protocol NXConvertFileDelegate;

@interface NXConvertFile : NSObject

@property(nonatomic, weak) id<NXConvertFileDelegate> delegate;

- (void)convertFile:(int) agentId fileName: (NSString *)filename data:(NSData*)data toFormat: (NSString*) fmt isNxl: (BOOL) nxl completion:(completionBlock)block;

-(void) cancel;

@end

@protocol NXConvertFileDelegate <NSObject>

@optional
- (void) nxConvertFile:(NXConvertFile *) convertFile convertProgress:(NSNumber *)progress forFile:(NSString *)fileName;

@end
