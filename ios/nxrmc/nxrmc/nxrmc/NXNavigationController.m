//
//  NXNavigationController.m
//  nxrmc
//
//  Created by Kevin on 15/4/30.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXNavigationController.h"
#import "NXLoginViewController.h"
#import "NXLoginViewController.h"
#import "NXMasterSplitViewController.h"
#import "NXUserGuideViewController.h"
#import "NXLoginUser.h"
#import "AppDelegate.h"
#import "NXCommonUtils.h"
#import "NXDropDownMenu.h"
#import "NXMasterTabBarViewController.h"
#import "NXKeyChain.h"

@interface NXNavigationController ()<UISplitViewControllerDelegate, UIGestureRecognizerDelegate>

@end

@implementation NXNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AppDelegate* ad = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [ad setNavigation:self];
   
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    if ([NXCommonUtils isFirstTimeLaunching]) {
        ad.isFirstSignIn = YES;
        // delete the older user profile info, in case user auto login if the app is reinstall
        [NXKeyChain delete:KEYCHAIN_PROFILES_SERVICE];
        
        NXUserGuideViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"UserGuideVC"];
        self.viewControllers = [NSArray arrayWithObject:vc];
        ad.window.rootViewController = ad.navigation;
    } else {
        NXLoginViewController *c = [storyboard instantiateViewControllerWithIdentifier:@"NXLoginVC"];
        if ([[NXLoginUser sharedInstance] isAutoLogin]) {
            // if auto login, do not forget load previous data
            [[NXLoginUser sharedInstance] loadUserAccountData];
            NXMasterSplitViewController* sp = [storyboard instantiateViewControllerWithIdentifier:@"SPVC"];
           // NXMasterSplitViewController* sp = [[NXMasterSplitViewController alloc] init];
            sp.delegate = self;
            self.viewControllers = [NSArray arrayWithObject:c];
            ad.window.rootViewController = sp;
        } else {
            self.viewControllers = [NSArray arrayWithObject:c];
            ad.window.rootViewController = ad.navigation;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)shouldAutorotate {
    return YES;
}

-(UIInterfaceOrientationMask) supportedInterfaceOrientations{
    if ([[self.viewControllers lastObject] isKindOfClass:[NXLoginViewController class]]) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    
    if ([NXCommonUtils isFirstTimeLaunching]) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

#pragma mark UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    NSLog(@"Primary is %@", ((UINavigationController *)primaryViewController).topViewController);
    NSLog(@"Second is %@", ((UINavigationController *)secondaryViewController).topViewController);
    
    ((UINavigationController *)primaryViewController).interactivePopGestureRecognizer.delegate = self;
    
    if ([((UINavigationController *)secondaryViewController).topViewController isKindOfClass:[DetailViewController class]]) {
        DetailViewController *detailVC = (DetailViewController *)((UINavigationController *)secondaryViewController).topViewController;
        if (detailVC.curFile != nil) {
            if ([((UINavigationController *)primaryViewController).topViewController isKindOfClass:[NXMasterTabBarViewController class]]) {
                ((UINavigationController *)primaryViewController).navigationBarHidden = NO;
            }
            detailVC.tabBarController.navigationController.navigationBarHidden = NO;
            return NO;
        }else
        {
            return YES;
        }
    }
    NSLog(@"The tabbar  nav is %@", ((UINavigationController *)primaryViewController).topViewController.navigationController);
    ((UINavigationController *)primaryViewController).topViewController.navigationController.navigationBarHidden = NO;
    return NO;
   
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController showDetailViewController:(UIViewController *)vc sender:(id)sender {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        ((UINavigationController *)vc).interactivePopGestureRecognizer.delegate = self;
    }
    return NO;
}

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
       [NXDropDownMenu dismissMenu];
}
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

// Return the view controller which is to become the primary view controller after the `splitViewController` is expanded due to a transition
// to the horizontally-regular size class. If you return `nil`, then the argument will perform its default behavior (i.e. to use its current
// primary view controller.)


//- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController
//{
//    NSLog(@"SpliteViewController is %@", splitViewController.viewControllers);
//    DetailViewController *detailVC = (DetailViewController *)((UINavigationController *)splitViewController.viewControllers.lastObject).topViewController;
//    if (detailVC.curFile != nil) {
//        NSLog(@"The return vc is %@", ((UINavigationController *)splitViewController.viewControllers.lastObject).topViewController);
//        return splitViewController.viewControllers.lastObject;
//    }else
//    {
//       [((UINavigationController *)splitViewController.viewControllers.firstObject) popToRootViewControllerAnimated:NO];
//        for (UIViewController * vc in ((UINavigationController *)splitViewController.viewControllers.firstObject).viewControllers) {
//            NSLog(@"VC is %@", vc);
//        }
//        return splitViewController.viewControllers.firstObject;
//    }
//}

@end
