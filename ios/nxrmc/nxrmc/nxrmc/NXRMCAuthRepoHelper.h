//
//  NXAuthRepoHelperNew.h
//  nxrmc
//
//  Created by EShi on 8/10/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NXBoundService.h"

typedef void(^authCompletion)(NSDictionary * repoAuthInfo, NSError * error);

@interface NXRMCAuthRepoHelper : NSObject
+(instancetype) sharedInstance;
- (void) authBoundService:(NXBoundService *) service inViewController:(UIViewController *) authViewController completion:(authCompletion) compBlock;
@end
