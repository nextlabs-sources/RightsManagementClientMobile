//
//  NXDropBoxAuther.m
//  nxrmc
//
//  Created by EShi on 8/5/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXDropBoxAuther.h"
#import <DropboxSDK/DropboxSDK.h>
#import "NXCommonUtils.h"
#import "NXRMCDef.h"
#import "NXLoginUser.h"
#import "AppDelegate.h"

@interface NXDropBoxAuther()<DBRestClientDelegate>
@property(nonatomic, strong) DBRestClient *restClient;
@end
@implementation NXDropBoxAuther
-(instancetype) init
{
    self = [super init];
    if (self) {
        _repoType = kServiceDropbox;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectServiceFinished:) name:@"dropbox" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dropBoxBindCancel:) name:NOTIFICATION_DROP_BOX_CANCEL object:nil];

    }
    return self;
}

- (void) authRepoInViewController:(UIViewController *) vc
{
    self.authViewController = vc;
    [[DBSession sharedSession] linkFromController:vc];
}

#pragma mark - Dropbox DBRestClientDelegate
-(void) connectServiceFinished:(NSNotification*) notification {

    NSDictionary *inforDic = notification.userInfo;
    NSString *url = [[inforDic objectForKey:@"KEY_URL"] absoluteString];
    NSError *error = [inforDic objectForKey:@"KEY_ERROR"];
    if (error) {
        if([self.delegate respondsToSelector:@selector(repoAuther:authFailed:)])
        {
            [self.delegate repoAuther:self authFailed:error];
        }
    } else {
        NSDictionary *infor = [NXCommonUtils parseURLParams:url];
        NSString *usrid = [infor objectForKey:@"uid"];
        if (usrid) {
            _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession] userId:usrid];
            _restClient.delegate = self;
            [_restClient loadAccountInfo];
        }
    }
}

-(void) dropBoxBindCancel:(NSNotification *) notification
{
    if ([self.delegate respondsToSelector:@selector(repoAuthCanceled:)]) {
        [self.delegate repoAuthCanceled:self];
    }
}

- (void) restClient:(DBRestClient *)client loadedAccountInfo:(DBAccountInfo *)info {
    
    MPOAuthCredentialConcreteStore* credentialStore = [[DBSession sharedSession] credentialStoreForUserId:info.userId];
    NSString *accountToken = [NSString stringWithFormat:@"%@%@%@", credentialStore.accessToken, NXSYNC_REPO_SPERATE_KEY, credentialStore.accessTokenSecret];
    NSDictionary *authResult = @{AUTH_RESULT_ACCOUNT:info.email, AUTH_RESULT_ACCOUNT_ID:info.userId, AUTH_RESULT_ACCOUNT_TOKEN:accountToken};
    if ([self.delegate respondsToSelector:@selector(repoAuther:didFinishAuth:)]) {
        [self.delegate repoAuther:self didFinishAuth:authResult];
    }
}

- (void)restClient:(DBRestClient *)client loadAccountInfoFailedWithError:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(repoAuther:authFailed:)]) {
            [self.delegate repoAuther:self authFailed:error];
        }
    });
}


@end
