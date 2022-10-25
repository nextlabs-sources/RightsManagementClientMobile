//
//  NXAccountPageViewController.m
//  nxrmc
//
//  Created by nextlabs on 7/29/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXAccountPageViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "NXUserInfoTableViewController.h"
#import "MBProgressHUD.h"
#import "NXAboutPageViewController.h"
#import  <DropboxSDK/DropboxSDK.h>

#import "NXLoginUser.h"
#import "NXCommonUtils.h"
#import "AppDelegate.h"
#import "NXSettingViewController.h"

#define KEY_TITLE   @"title"
#define KEY_VALUE   @"value"
#define DATA_PICKER_DAY_COLUMN_NAME @"DAY"
#define DATA_PICKER_HOUR_COLUMN_NAME @"HOUR"
#define CLEANCACHE   1000

static NSString * const kCellIdentifier = @"cell";

@interface NXAccountPageViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *sectionTitles;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@end

@implementation NXAccountPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _sectionTitles = [NSArray arrayWithObjects:@"", @"", @"", @"", nil];
    self.tableview.delegate = self;
    self.tableview.dataSource = self;
    self.tableview.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    self.tableview.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.99 alpha:1.0];

}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = NSLocalizedString(@"TAB_BAR_ACCOUNT_TITLE", nil);
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor whiteColor];
    
    self.tabBarController.navigationController.navigationBarHidden = YES;
    
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.shouldShowAddService) {
        self.shouldShowAddService = NO;
        NXSettingViewController *vc = [[NXSettingViewController alloc] init];
        vc.shouldShowAddAcountPage = YES;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.splitViewController showDetailViewController:nav sender:self];
    }
    
    // User guid
//    AppDelegate *ad = [UIApplication sharedApplication].delegate;
//    if (ad.isFirstSignIn) {
//        if ([NXLoginUser sharedInstance].boundServices.count > 0) {
//            [self.tabBarController setSelectedIndex:0];  // back to file list view
//        }
//    }
}
- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
}
-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 0)
    {
        return 3;
        
    }else
    {
        return 1;
    }
   
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [_sectionTitles objectAtIndex:section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *myLabel = [[UILabel alloc] init];
    myLabel.frame = CGRectMake(20, 8, 320, 20);
    myLabel.font = [UIFont boldSystemFontOfSize:14];
    myLabel.text = [self tableView:tableView titleForHeaderInSection:section];
    UIView *headerView = [[UIView alloc] init];
    
    [headerView addSubview:myLabel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier: kCellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
            {
                cell.textLabel.text = NSLocalizedString(@"SET_TITLE", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
            }
                break;
            case 1:
            {
                cell.textLabel.text = NSLocalizedString(@"ACCOUNT_TITLE", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
                break;
            case 2:
            {
                cell.textLabel.text = NSLocalizedString(@"HELP_TITLE", nil);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
                break;
            default:
                break;
        }

    }else if(indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"ACCOUNT_SIGNOUT", nil);
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.textColor =  [UIColor blueColor];
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:  // Settings
            {
                NXSettingViewController *vc = [[NXSettingViewController alloc] init];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.splitViewController showDetailViewController:nav sender:self];
            }
                break;
            case 1:  // My Account
            {
                NXUserInfoTableViewController *vc = [[NXUserInfoTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                [self.splitViewController showDetailViewController:nav sender:self];
            }
                break;
            case 2: // Help
            {
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                NXAboutPageViewController *aboutPageVC = [storyboard instantiateViewControllerWithIdentifier:@"AboutPageVC"];
                
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:aboutPageVC];
                [self.splitViewController showDetailViewController:nav sender:self];
            }
                break;
            default:
                break;
        }
    }
    if (indexPath.section == 1) {
        if (indexPath.row == 0) { // Sign Off
            [self signout:nil];
        }
    }
}


- (void)signout:(id) sender {
    [NXCommonUtils showAlertView:NSLocalizedString(@"ALERTVIEW_TITLE", NULL) message:NSLocalizedString(@"SIGNOUTALERTMESSAGE", NULL) style:UIAlertControllerStyleAlert OKActionTitle:NSLocalizedString(@"BOX_OK", NULL) cancelActionTitle:NSLocalizedString(@"BOX_CANCEL", NULL) OKActionHandle:^(UIAlertAction *action)  {
        if ([[NXLoginUser sharedInstance] isLogInState]) {
            [[NXLoginUser sharedInstance] logOut];
        }
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        app.window.rootViewController = app.navigation;
    } cancelActionHandle:nil inViewController:self position:sender];
}




@end
