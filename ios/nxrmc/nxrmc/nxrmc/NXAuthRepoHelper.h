//
//  NXAuthRepoHelper.h
//  nxrmc
//
//  Created by EShi on 7/28/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NXBoundService.h"

typedef void(^authCompletion)(id userAppendData, NSError * error);
@interface NXAuthRepoHelper : NSObject
+(instancetype) sharedInstance;

- (void) authBoundService:(NXBoundService *) service inViewController:(UIViewController *) authViewController completion:(authCompletion) compBlock;
@end
