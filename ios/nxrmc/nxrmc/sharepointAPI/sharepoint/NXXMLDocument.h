//
//  NXXMLDocument.h
//  RecordWebRequest
//
//  Created by ShiTeng on 15/5/27.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXXMLElement : NSObject<NSXMLParserDelegate>
@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSDictionary* attributes;
@property(nonatomic, strong) NSMutableString* value;
@property(nonatomic, strong) NSMutableArray* children;
@property(nonatomic, weak) NXXMLElement* parent;

-(NXXMLElement*) childNamed:(NSString*) nodeName;
-(NSArray*) childrenNamed:(NSString*) nodeName;
-(NSString*) valueWithPath:(NSString *)path;
@end

@interface NXXMLDocument : NSObject<NSXMLParserDelegate>
@property(nonatomic, strong) NXXMLElement* root;

+(instancetype) documentWithData:(NSData*) data error:(NSError**)outError;
@end
