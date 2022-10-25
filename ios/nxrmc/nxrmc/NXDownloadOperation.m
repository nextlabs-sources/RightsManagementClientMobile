//
//  NXDownloadOperation.m
//  nxrmc
//
//  Created by nextlabs on 10/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXDownloadOperation.h"
#import "NXCommonUtils.h"

@interface NXDownloadOperation ()<NXServiceOperationDelegate>
{
    BOOL executing;
    BOOL cancelled;
    BOOL finished;
}

@end

@implementation NXDownloadOperation

+ (NXDownloadOperation *) downloadOperaion:(NXFileBase *) file
                             progressBlock:(NXProgressBlock) progressBlock
                           completionBlock:(NXCompletionBlock)completionBlock
{
    NXDownloadOperation *downloadOperaion = [[NXDownloadOperation alloc] init];
    
    NXBoundService *service = [NXCommonUtils getBoundServiceFromCoreData:file.serviceAccountId];
    NSLog(@"current download service %@", service.service_alias);
    id<NXServiceOperation> op = [NXCommonUtils createServiceOperation:service];
    [op setDelegate:downloadOperaion];
    
    downloadOperaion.operation = op;
    
    downloadOperaion.file = file;
    
    downloadOperaion.progressBlock = progressBlock;
    downloadOperaion.completitionBlock = completionBlock;
    
    return downloadOperaion;
}

- (void)start
{
    executing = YES;
    [self.operation downloadFile:self.file];
    NSLog(@"%@ is downloading", self.file.fullPath);
}

- (void)stop
{
    [self.operation cancelDownloadFile:self.file];
    cancelled = YES;
}

- (void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)startOperation
{
    NSLog(@"downloadmanager start download file %@ %@",self.file.fullPath,self.file.fullServicePath);
    [self.operation downloadFile:self.file];
    executing = YES;
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark -

- (void) downloadFileFinished:(NSString *)servicePath intoPath:(NSString *)localCachePath error:(NSError *)err {
    self.completitionBlock(self.file, localCachePath, err);
    [self finish];
}

- (void) downloadFileProgress:(CGFloat)progress forFile:(NSString *)servicePath {
    self.progressBlock(progress, self.file);
}

- (void) dealloc {
    NSLog(@"download operation %@ dealloc", self.file.fullPath);
}

@end
