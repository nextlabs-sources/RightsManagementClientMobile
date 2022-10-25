//
//  NXMasterSplitViewController.m
//  nxrmc
//
//  Created by EShi on 7/28/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXMasterSplitViewController.h"
#import "NXMasterTabBarViewController.h"
#import "AppDelegate.h"
@interface NXMasterSplitViewController ()

@end

@implementation NXMasterSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    UINavigationController *detailNavigationController = [self.viewControllers lastObject];
    // store detail vc for filelistVC use
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    app.fileContentVC = [detailNavigationController.viewControllers lastObject];
    app.detailNav = detailNavigationController;
    app.spliteViewController = self;
 


    if (systemVersion >= 8.0){
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            detailNavigationController.topViewController.navigationItem.leftBarButtonItem = self.displayModeButtonItem;
        }
    }else
    {
        self.delegate = app.fileContentVC;
    }
    
   
    if (systemVersion >= 8.0){
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        }else
        {
            self.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;

        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) dealloc
{
    NSLog(@"MasterSpliteView dealloc");
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end
