//
//  AppDelegate.m
//  nxrmc
//
//  Created by Kevin on 15/4/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "AppDelegate.h"

#import <CoreData/CoreData.h>
#import "NXLoginViewController.h"
#import "NXMasterSplitViewController.h"
#import "NXMasterTabBarViewController.h"
#import "NXUserGuideViewController.h"
#import "NXCommonUtils.h"
#import "NXLoginUser.h"
#import "NXFile.h"
#import "NXNetworkHelper.h"
#import "MobileApp.h"
#import "NXCacheManager.h"
#import "GTMOAuth2ViewControllerTouch.h"

#import "NXSyncHelper.h"
#import "NXCacheManager.h"
@interface AppDelegate ()<LiveAuthDelegate>
{
    DBRestClient *_restClient;
    UIDeviceOrientation _deviceOrientation;
}
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UINavigationBar appearance].tintColor = RMC_MAIN_COLOR;
    [UITabBar appearance].tintColor = RMC_MAIN_COLOR;
    [UITableView appearance].tintColor = RMC_MAIN_COLOR;

    
    // Override point for customization after application launch.
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:DROPBOXCLIENTID
                            appSecret:DROPBOXCLIENTSECRET
                            root:kDBRootDropbox]; // either kDBRootAppFolder or kDBRootDropbox
    [DBSession setSharedSession:dbSession];

    //init one drive liveclinet
    // 
    self.liveClient = [[LiveConnectClient alloc]initWithClientId:ONEDRIVECLIENTID
                                                          scopes:[NSArray arrayWithObjects:@"wl.signin", @"wl.basic", @"wl.offline_access", @"wl.skydrive",@"wl.emails", @"wl.skydrive_update", nil]
                                                        delegate:self
                                                       userState:@"Authenticate"];
    // core data
    [self appContext];
    
    [[NXNetworkHelper sharedInstance] startNotifier];
    
    // listen to the net work statues change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NetStatusChanged:) name:kReachabilityChangedNotification object:nil];
    
    
    // Locate ts3d.ttf font directory and pass to MobileApp
    NSString *ts3dFontPath = [[NSBundle mainBundle] pathForResource:@"ts3d" ofType:@"ttf"];
    NSString *fontDir = [ts3dFontPath stringByDeletingLastPathComponent];
    MobileApp::inst().setFontDirectory(fontDir.UTF8String);
    
    _deviceOrientation = [[UIDevice currentDevice] orientation];
    
    _userGuider = [NXUserGuider userGuiderInstance];
    
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(NSString *)source annotation:(id)annotation {

    NSString *cancleURL = [NSString stringWithFormat:@"db-%@://1/cancel", DROPBOXCLIENTID];
    //for Dropbox link session
    if ([url.absoluteString rangeOfString:@"oauth_token_secret"].location != NSNotFound) {
        if ([[DBSession sharedSession] handleOpenURL:url]) {
            NSMutableDictionary *infordic = [[NSMutableDictionary alloc] init];
            NSString* err = nil;
            if ([[DBSession sharedSession] isLinked]) {
                NSLog(@"App linked successfully!");
            }
            else
            {
                err = NSLocalizedString(@"SERVICE_CONNECT_ERROR", nil);
                [infordic setObject:err forKey:@"KEY_ERROR"];
            }
            [infordic setObject:url forKey:@"KEY_URL"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"dropbox" object:nil userInfo:infordic];
            return YES;
        }
    }else if([url.absoluteString isEqualToString:cancleURL])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DROP_BOX_CANCEL object:nil];
        return YES;
    }
    
    [self ipadToOpenThirdAppFile:url];
    
    // Add whatever other url handling code your app requires here
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    self.thirdAppFileURL = nil;
    
    [self.userGuider saveUserGuiderStatus];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [NXCommonUtils cleanTempFile];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if (![[NXLoginUser sharedInstance] isAutoLogin]) {
        [[NXLoginUser sharedInstance] logOut];
        for (UIViewController* viewController in self.navigation.viewControllers) {
            if ([viewController isKindOfClass: [NXLoginViewController class]]) {
                [self.navigation popToViewController:viewController animated:YES];
            }
        }
        self.window.rootViewController = self.navigation;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // clean the tmp file
    [NXCommonUtils cleanTempFile];
    
    [[NXNetworkHelper sharedInstance] stopNotifier];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - Split view
- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]]) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}

#pragma mark -------------core data------------------
-(NSManagedObjectContext*) appContext
{
    
#pragma mark  here may be appear crash bug. this cause by NSManagedObjectContext not support thread sync. but NSPersistentStoreCoordinator support that.
#pragma makk so we some crash when writing or reading coredata. this may be reason. so we can do thread sync when write or read.

    if (self.managedObjectContext) {
        return self.managedObjectContext;
    }
    
    NSPersistentStoreCoordinator* coordinator = [self appStoreCoordinator];
    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setUndoManager:nil];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator*) appStoreCoordinator
{
    if (self.persistentStoreCoordinator) {
        return self.persistentStoreCoordinator;
    }
    
    NSURL* storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"rmc.sqlite"];
    
    NSError* error = nil;
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:[self appModel]];
    
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        abort();
    }
    
    return self.persistentStoreCoordinator;
}

- (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel*) appModel
{
    if (self.managedObjectModel) {
        return self.managedObjectModel;
    }
    
    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"RMCModel" withExtension:@"momd"];
    self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
    return self.managedObjectModel;
}

#pragma mark LiveAuthDelegate about after auth
- (void) authCompleted:(LiveConnectSessionStatus)status
               session:(LiveConnectSession *)session
             userState:(id)userState
{
    if([(NSString*)userState isEqualToString:@"Authenticate"])
    {
        NSLog(@"Authenticate ok");
        if(self.liveClient.session != nil)
        {
            NSLog(@"session is not nil");
        }
        else
        {
            NSLog(@"session is nil");
        }
    }
}

- (void) authFailed:(NSError *)error
          userState:(id)userState
{
    if([(NSString*)userState isEqualToString:@"Authenticate"])
    {
        NSLog(@"Authenticate fail");
    }
}
#pragma mark others

- (void) ipadToOpenThirdAppFile:(NSURL *) fileUrl
{
    NSURL *destUrl = [NXCacheManager getCacheUrlForOpenedInFile:fileUrl];
    NSError *error;
    BOOL ret = [[NSFileManager defaultManager] copyItemAtURL:fileUrl toURL:destUrl error:&error];
    if (!ret) {
        NSLog(@"Copy inbox file out fail! scrUrl = %@ destUrl = %@, error is %@", fileUrl, destUrl, error);
        return;
    }

    if([NXLoginUser sharedInstance].isLogInState)
    {
        if (![self canOpenThirdPartyFile]) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"ALERTVIEW_MESSAGE_OPENTHIRDFILEFAILED", NULL) delegate:nil cancelButtonTitle:NSLocalizedString(@"BOX_OK", NULL) otherButtonTitles: nil];
            [alertView show];
            return;
        }
        
        NXFileBase *file = [NXCommonUtils fetchFileInfofromThirdParty:destUrl];
        NSArray *controllers = self.spliteViewController.viewControllers;
        if ([[controllers lastObject] isKindOfClass:[UINavigationController class]]) {
           UIViewController *vc = ((UINavigationController *)controllers.lastObject).topViewController;
            if ([vc isKindOfClass:[UINavigationController class]]) {
                UINavigationController *nav = (UINavigationController *)vc;
                if (nav.viewControllers.count) {
                    UIViewController *right = [nav.viewControllers objectAtIndex:0];
                    if (![right isKindOfClass:[DetailViewController class]]) {
                        [self.spliteViewController showDetailViewController:self.detailNav sender:self];
                    }
                }
            } else {
                [self.spliteViewController showDetailViewController:self.detailNav sender:self];
            }
        }
        DetailViewController* fileContentVC = nil;
        for(UIViewController *vc in self.detailNav.viewControllers)
        {
            if ([vc isKindOfClass:[DetailViewController class]]) {
                fileContentVC = (DetailViewController*)vc;
                break;
            }
        }
        if (fileContentVC) {
            [fileContentVC openFile:file currentService:nil isOpen3rdAPPFile:YES isOpenNewProtectedFile:NO];
            
        }

    }else
    {
        // the user did not login, so store the url, we fileContentVC appear, it will check thirdAppFileURL
        self.thirdAppFileURL = destUrl;
    }
  
}

//this function used to dismiss presentedViewcontroller when open third party file.
- (BOOL)canOpenThirdPartyFile {
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    UIViewController *vc = app.window.rootViewController;
    if ([vc isKindOfClass:[NXMasterSplitViewController class]]) {
        NXMasterSplitViewController* rootViewController = (NXMasterSplitViewController *)vc;
        if (rootViewController.viewControllers.count) {
            UINavigationController *nav = [rootViewController.viewControllers objectAtIndex:0];
            if ([[nav.viewControllers objectAtIndex:0] isKindOfClass:[NXMasterTabBarViewController class]]) {
                NXMasterTabBarViewController *masterTabViewController = [nav.viewControllers objectAtIndex:0];
                UIViewController *vc = masterTabViewController.selectedViewController;
                UINavigationController *nav;
                if ([vc isKindOfClass:[UINavigationController class]]) {
                    nav = (UINavigationController*)vc;
                    UIViewController *v = nav.topViewController.presentedViewController;
                    if ([v isKindOfClass:[UINavigationController class]]) {
                        NSArray *array = ((UINavigationController *)v).viewControllers;//LiveAuthDialog6
                        if (array.count) {
                            if ([[array objectAtIndex:0] isKindOfClass:NSClassFromString(@"LiveAuthDialog")]) {
                                    return NO;
                            }
                        }
                    }
                    [nav.topViewController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
                }
            }
        }
    }
    return YES;
}

-(void) refreshLiveConnectionClient
{
    //init one drive liveclinet
    self.liveClient = [[LiveConnectClient alloc]initWithClientId:ONEDRIVECLIENTID
                                                          scopes:[NSArray arrayWithObjects:@"wl.signin", @"wl.basic", @"wl.offline_access", @"wl.skydrive",@"wl.emails", @"wl.skydrive_update", nil]
                                                        delegate:self
                                                       userState:@"Authenticate"];

}


- (NSUInteger) application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{

    UIDeviceOrientation curOrientation = [[UIDevice currentDevice] orientation];
    
    if (_deviceOrientation != curOrientation) {
        _deviceOrientation = curOrientation;
    }
        
    if ([self.navigation.topViewController isKindOfClass:[NXUserGuideViewController class]]) {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskAll;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    if (CGRectContainsPoint(statusBarFrame, location) && touch.window.windowLevel == UIWindowLevelStatusBar) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_USER_TAP_STATUS_BAR object:nil];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark - Observer
- (void) NetStatusChanged:(NSNotification *) notification
{
    if ([[NXNetworkHelper sharedInstance]  isNetworkAvailable] && [NXLoginUser sharedInstance].isLogInState) {
        [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getSharingRESTCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
            
        }];
        [[NXSyncHelper sharedInstance] uploadPreviousFailedRESTRequestWithCachedURL:[NXCacheManager getLogCacheURL] mustAllSuccess:NO Complection:^(id object, NSError *error) {
            ;
        }];
    }
}


@end
