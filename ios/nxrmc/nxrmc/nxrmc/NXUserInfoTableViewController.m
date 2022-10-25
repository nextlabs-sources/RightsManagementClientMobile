//
//  NXUserInfoTableViewController.m
//  nxrmc
//
//  Created by nextlabs on 12/22/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXUserInfoTableViewController.h"
#import "NXFileAttrTableViewCell.h"

#import "NXLoginUser.h"
#import "NXCommonUtils.h"

static NSString * const kCellIdentifier = @"cellIdentifier";

@interface NXUserInfoTableViewController ()

@property(strong ,nonatomic) NSArray *dataArray;

@end

@implementation NXUserInfoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"ACCOUNTINFOTITLE", NULL);
    NSString* userName = [NXLoginUser sharedInstance].profile.userName;
    if (!userName || userName.length == 0) {
        userName = @"";
    }
    _dataArray = @[@{NSLocalizedString(@"ACCOUNTINFONAME", NULL) : userName},
                   @{NSLocalizedString(@"ACCOUNTINFOEMAIL", NULL) : [NXLoginUser sharedInstance].profile.email},
                   @{NSLocalizedString(@"ACCOUNTINFOTENANTID", NULL) : [NXCommonUtils currentTenant]}];
    
    self.tableView.estimatedRowHeight = 44.0; //using this line code to fix cell can not auto calculate height when rotation screen.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NXFileAttrTableViewCell *cell = [NXFileAttrTableViewCell fileAttrTableViewCellWithTableView:tableView];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.infoName.textColor = [UIColor blueColor];
    cell.infoValue.numberOfLines = 0;
    cell.infoValue.lineBreakMode = NSLineBreakByWordWrapping;
    
    NSDictionary *model = self.dataArray[indexPath.row];
    [model enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        cell.infoName.text = key;
        cell.infoValue.text = obj;
    }];
    
    if(indexPath.row == _dataArray.count - 1) {
        cell.showSeperator = NO;
    }
    return cell;
}

@end
