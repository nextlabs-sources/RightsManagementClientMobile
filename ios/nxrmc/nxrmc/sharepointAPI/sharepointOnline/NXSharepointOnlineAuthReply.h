//
//  NXSharepointOnlineAuthReply.h
//  nxrmc
//
//  Created by nextlabs on 6/24/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol NXSharepointOnlineReplyDelegate;

@interface NXSharepointOnlineAuthReply : NSObject<NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
@property (nonatomic, weak) id<NXSharepointOnlineReplyDelegate> delegate;
@end


@protocol NXSharepointOnlineReplyDelegate<NSObject>
@optional
- (void)nxsharepointOnelineReply:(NXSharepointOnlineAuthReply *) replay didReplysuccess:(NSData*) data;
- (void)nxsharepointOnelineReply:(NXSharepointOnlineAuthReply *) replay didFailWithError:(NSError*) error;
@end
