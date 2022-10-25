//
//  AppDelegate.h
//  nxrmc
//
//  Created by Kevin on 15/4/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "LiveSDK/LiveConnectClient.h"
#import "DetailViewController.h"
#import "NXMasterSplitViewController.h"
#import "NXUserGuider.h"
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) UINavigationController* navigation;

@property (strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (strong, nonatomic) NSManagedObjectContext* managedObjectContext;

@property (strong, nonatomic) LiveConnectClient *liveClient;

@property (weak, nonatomic) DetailViewController *fileContentVC;
@property(weak, nonatomic) NXMasterSplitViewController *spliteViewController;
@property(strong, nonatomic) UINavigationController *detailNav;
@property(strong, nonatomic) NSURL* thirdAppFileURL;
@property(nonatomic) BOOL isFirstSignIn;
@property(nonatomic, strong) NXUserGuider *userGuider;

- (void) refreshLiveConnectionClient;
@end

