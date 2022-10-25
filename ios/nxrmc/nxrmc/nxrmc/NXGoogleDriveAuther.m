//
//  NXGoogleDriveAuther.m
//  nxrmc
//
//  Created by EShi on 8/5/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXGoogleDriveAuther.h"

#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "NXCommonUtils.h"
@interface NXGoogleDriveAuther()

@end
@implementation NXGoogleDriveAuther
- (void) authRepoInViewController:(UIViewController *) vc
{
    GTMOAuth2ViewControllerTouch *authController;
    NSString *keychainItemName = [NXCommonUtils randomStringwithLength:GOOGLEDRIVEKEYCHAINITEMLENGTH];
    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeDrive, nil];
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:[scopes componentsJoinedByString:@" "]
                                                                clientID:GOOGLEDRIVECLIENTID
                                                            clientSecret:GOOGLEDRIVECLIENTSECRET
                                                        keychainItemName:keychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
 
    //root viewcontroller is new becasue only this can make authController has a back button.
    UIViewController *rootController = [[UIViewController alloc] init];
    rootController.view.backgroundColor = [UIColor whiteColor];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:rootController];
    [nav pushViewController:authController animated:YES];
    
    [vc.navigationController presentViewController:nav animated:YES completion:nil];
    self.authViewController = vc;
    self.repoType = kServiceGoogleDrive;
    
}

#pragma mark - GoogleDrive Delegate
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController finishedWithAuth:(GTMOAuth2Authentication *)authResult error:(NSError *)error {
    if (error == nil) {
        [self.authViewController dismissViewControllerAnimated:NO completion:nil];
        NSString *userId = [NSString stringWithFormat:@"%@",authResult.userID];
        if ([self.delegate respondsToSelector:@selector(repoAuther:didFinishAuth:)]) {
            NSDictionary *authResultDict = @{ AUTH_RESULT_ACCOUNT:authResult.userEmail,
                                              AUTH_RESULT_ACCOUNT_ID: userId,
                                              AUTH_RESULT_ACCOUNT_TOKEN : viewController.keychainItemName};
            [self.delegate repoAuther:self didFinishAuth:authResultDict];
        }
    } else {

        [viewController.navigationController dismissViewControllerAnimated:NO completion:^{
            NSInteger errorCode = error.code;
            if (errorCode != -1000) { // -1000 means canceled
                if ([self.delegate respondsToSelector:@selector(repoAuther:authFailed:)]) {
                    [self.delegate repoAuther:self authFailed:AUTH_ERROR_AUTH_FAILED];
                }
            }else
            {
                if ([self.delegate respondsToSelector:@selector(repoAuthCanceled:)]) {
                    [self.delegate repoAuthCanceled:self];
                }
            }
        }];
    }
}

@end
