//
//  NXMasterTableBarViewController.m
//  nxrmc
//
//  Created by EShi on 7/27/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXMasterTabBarViewController.h"
#import "NXCustomFileListViewController.h"
#import "NXRMCDef.h"
#import "NXCommonUtils.h"

@interface NXMasterTabBarViewController ()


@end

@implementation NXMasterTabBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAutomaticallyAdjustsScrollViewInsets:NO];

    self.navigationController.navigationBarHidden = YES;
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    NXFileListViewController *fileListVC = [storyboard instantiateViewControllerWithIdentifier:@"FileListVC"];
    UINavigationController *fileListInfoNav = [[UINavigationController alloc] initWithRootViewController:fileListVC];
    self.fileListInfoNav = fileListInfoNav;
    
    
    
    NXAccountPageViewController *accountPageVC = [storyboard instantiateViewControllerWithIdentifier:@"AccountInfoVc"];
    
    UINavigationController *accountPageNav = [[UINavigationController alloc]initWithRootViewController:accountPageVC];
    accountPageNav.navigationBarHidden = YES;
    self.accountPageNav = accountPageNav;

    
    NXCustomFileListViewController *customFileListVCFav = [storyboard instantiateViewControllerWithIdentifier:@"CustomFileListVC"];
    customFileListVCFav.fileListType = CustomFileListTypeFavorite;
    UINavigationController *favoriteNav = [[UINavigationController alloc] initWithRootViewController:customFileListVCFav];
    
    NXCustomFileListViewController *customFileListVCOffline = [storyboard instantiateViewControllerWithIdentifier:@"CustomFileListVC"];
    customFileListVCOffline.fileListType = CustomFileListTypeOffline;
    UINavigationController *offlineNav = [[UINavigationController alloc] initWithRootViewController:customFileListVCOffline];

    
    NSArray *vcArray = [[NSArray alloc] initWithObjects:fileListInfoNav, favoriteNav,offlineNav, accountPageNav, nil];
    [self setViewControllers:vcArray];
    
    // Init tabbar items
 
    UITabBar *tabBar = self.tabBar;
    
    UITabBarItem *itemFile = [tabBar.items objectAtIndex:0];
    itemFile.title = NSLocalizedString(@"TAB_BAR_FILES_TITLE", NULL);
    itemFile.image = [UIImage imageNamed:@"Home"];
//    itemFile.selectedImage = [UIImage imageNamed:@"FileSEL"];
    
    UITabBarItem *itemFavorite = [tabBar.items objectAtIndex:1];
    itemFavorite.title = NSLocalizedString(@"TAB_BAR_FAV_TITLE", NULL);
    itemFavorite.image = [UIImage imageNamed:@"StarHD"];
    itemFavorite.selectedImage = [UIImage imageNamed:@"StarHDSEL"];
    
    UITabBarItem *itemOffline = [tabBar.items objectAtIndex:2];
    itemOffline.title = NSLocalizedString(@"TAB_BAR_OFFLINE_TITLE", NULL);
    itemOffline.image = [UIImage imageNamed:@"PinHD"];
//    itemOffline.selectedImage = [UIImage imageNamed:@"PinHDSEL"];
    
    UITabBarItem *itemAccount = [tabBar.items objectAtIndex:3];
    itemAccount.title = NSLocalizedString(@"TAB_BAR_ACCOUNT_TITLE", NULL);
    itemAccount.image = [UIImage imageNamed:@"Account"];
    itemAccount.selectedImage = [UIImage imageNamed:@"AccountSEL"];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
