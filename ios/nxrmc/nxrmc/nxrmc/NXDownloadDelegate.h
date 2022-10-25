//
//  NXDownloadDelegate.h
//  nxrmc
//
//  Created by helpdesk on 20/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol NXDownloadDelegate <NSObject>

@required

-(void)startDownload;
-(void)cancleDownload;
-(BOOL) isProgressSupported;
@end
