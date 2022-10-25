//
//  NXSharepointOnlineAuthReply.m
//  nxrmc
//
//  Created by nextlabs on 6/24/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXSharepointOnlineAuthReply.h"

@interface NXSharepointOnlineAuthReply()
@property (nonatomic, strong) NSMutableData *data;
@end

@implementation NXSharepointOnlineAuthReply

- (id) init {
    if (self = [super init]) {
        _data = [[NSMutableData alloc] init];
    }
    return self;
}
#pragma mark NSURLSessionDataDelegate NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    [_data appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            if (_delegate && [_delegate respondsToSelector:@selector(nxsharepointOnelineReply:didFailWithError:)]) {
                [_delegate nxsharepointOnelineReply:self didFailWithError:error];
            }
        }else
        {
            if (_delegate && [_delegate respondsToSelector:@selector(nxsharepointOnelineReply:didReplysuccess:)]) {
                [_delegate  nxsharepointOnelineReply: self didReplysuccess: _data];
            }
        }
    });
}

@end
