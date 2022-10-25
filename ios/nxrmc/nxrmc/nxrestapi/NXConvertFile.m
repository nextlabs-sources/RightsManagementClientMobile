//
//  NXConvertFile.m
//  nxrmc
//
//  Created by helpdesk on 7/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXConvertFile.h"
#import "NXRestAPI.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"

#import "GTMBase64.h"

@interface NXConvertFile ()<NXRestAPIDelegate>

@property (nonatomic, strong) NXRestAPI* restAPI;
@property (nonatomic, copy) completionBlock block;
@property (nonatomic, copy) NSString *fileName;

@end


static NSString *gFileType_HSF = @"hsf";

@implementation NXConvertFile

- (instancetype)init
{
    if(self = [super init])
    {
        
    }
    return self;
}


- (void)convertFile:(int)agentId fileName:(NSString *)filename data:(NSData *)data toFormat:(NSString *)fmt isNxl:(BOOL)nxl completion:(completionBlock)block
{
    [self.restAPI convertFile:agentId fileContent:data fileName:filename toFormat:fmt isNxl:nxl];
   
    self.block = block;
    _fileName = filename;
}

-(void) cancel
{
    [self.restAPI cancel];
}


#pragma mark - NXRestAPIDelegate

- (void) restAPIResponse:(NSURL*) url result: (NSString*)result data:(NSData *) data error: (NSError*)err
{
    NSLog(@"NXConvertFile restAPIResponse");
    NSString *path = nil;
    if(!err && data)
    {
        //need override,the new file name TBD,now it's need to save the file in local disk,because HOOPS Visualize dose not support file content from memory
     //   NXConvertFileResponse* response = [[NXConvertFileResponse alloc] init];
//        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:[result dataUsingEncoding:NSUTF8StringEncoding]];
//        parser.delegate = response;
//        if ([parser parse]) {
//            if ((response.errorCode == nil || [response.errorCode compare:@"0"] == NSOrderedSame)) {
//                NSData* binary = [GTMBase64 decodeString:response.binaryFile];
//                
//                NSString* md5 = [NXCommonUtils md5Data:binary];
//                
//                if ([response.checksum compare:md5 options:NSCaseInsensitiveSearch] != NSOrderedSame) {
//                    err = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_CONVERTFILE_CHECKSUM_NOTMATCHED error:err];
//                }
//                else {
                if(![self saveFile:data fileName:@"tempConvert.hsf" fullPath:&path])
                {
                    err = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_CONVERTFILEFAILED error:err];
                }
              //  }
//            } else {
//                NSDictionary *userInfoDict = @{NSLocalizedDescriptionKey:response.errorMsg};
//                err = [NSError errorWithDomain:NX_ERROR_SERVICEDOMAIN code:NXRMC_ERROR_CODE_CONVERTFILEFAILED_NOSUPPORTED userInfo:userInfoDict];
//            }
//        }
//        else {
//            NSLog(@"convert failed, %@", response.errorMsg);
//            err = [NXCommonUtils getNXErrorFromErrorCode:NXRMC_ERROR_CODE_CONVERTFILEFAILED error:err];
//        }
    }
    else
    {
        NSLog(@"convert file fail");
    }
    
    dispatch_queue_t mainQueue= dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        self.block(path,err);
    });
}

- (void) restAPIResponse:(NSURL *)url progress:(NSNumber *)progress
{
    if (_delegate && [_delegate respondsToSelector:@selector(nxConvertFile:convertProgress:forFile:)]) {
        [_delegate nxConvertFile:self convertProgress:progress forFile:_fileName];
    }
}

- (BOOL)saveFile:(NSData*)binary fileName:(NSString*)fileName fullPath:(NSString**)fullPath
{
    // detect the directory if is exist,if not create a new directory named "ConvertFile" in tmp
    NSString *path = [NXCommonUtils getConvertFileTempPath];
    
    // save the file to local disk,like /tmp/nxrmcTmp/xxxx.hsf
    path = [path stringByAppendingPathComponent:fileName];
    if([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        //if this name's file exist,now just delete this file,in the future maybe need change
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }

    if(![binary writeToFile:path atomically:YES])
    {
        NSLog(@"convert file receive data  but write file fail");
        return NO;
    }
    
    *fullPath = path;
    return YES;
}

// override the get method
- (id)restAPI
{
    if(_restAPI == nil)
    {
        _restAPI = [[NXRestAPI alloc] init];
        _restAPI.delegate = self;
    }
    return _restAPI;
}
@end

#pragma mark - NXConvertFileResponse

#define FILENAME            @"filename"
#define BINARYFILE          @"binaryfile"
#define ERRORCODE           @"errorCode"
#define ERRORMSG            @"errorMessage"
#define CHECKSUM            @"checksum"


@interface NXConvertFileResponse ()
{
    NSMutableString*    _workingPropertyString;
}

@end


@implementation NXConvertFileResponse

#pragma mark - NSXMLParser delegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    _workingPropertyString = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName compare:FILENAME options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        self.fileName = _workingPropertyString;
    }
    
    if ([elementName compare:BINARYFILE options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        self.binaryFile = _workingPropertyString;
    }
    
    if ([elementName compare:ERRORCODE options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        self.errorCode = _workingPropertyString;
    }
    
    if ([elementName compare:ERRORMSG options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        self.errorMsg = _workingPropertyString;
    }
    
    if ([elementName compare:CHECKSUM options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        self.checksum = _workingPropertyString;
    }
    
    _workingPropertyString = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (_workingPropertyString) {
        [_workingPropertyString appendString:string];
    }
}



@end


