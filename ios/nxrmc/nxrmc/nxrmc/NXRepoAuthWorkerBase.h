//
//  NXRepoAuthWorkerBase.h
//  nxrmc
//
//  Created by EShi on 8/5/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NXRMCDef.h"


#define AUTH_RESULT_ACCOUNT          @"AUTH_RESULT_ACCOUNT"
#define AUTH_RESULT_ACCOUNT_ID       @"AUTH_RESULT_ACCOUNT_ID"
#define AUTH_RESULT_ACCOUNT_TOKEN    @"AUTH_RESULT_ACCOUNT_TOKEN"

@protocol NXRepoAutherBase;

@protocol NXRepoAutherDelegate <NSObject>
@required
-(void) repoAuther:(id<NXRepoAutherBase>) repoAuther didFinishAuth:(NSDictionary *) authInfo;
-(void) repoAuther:(id<NXRepoAutherBase>) repoAuther authFailed:(NSError *) error;
-(void) repoAuthCanceled:(id<NXRepoAutherBase>) repoAuther;
@end

@protocol NXRepoAutherBase <NSObject>
@property(nonatomic, weak) id<NXRepoAutherDelegate> delegate;
@property(nonatomic) NSInteger repoType;
@required
- (void) authRepoInViewController:(UIViewController *) vc;

@end
