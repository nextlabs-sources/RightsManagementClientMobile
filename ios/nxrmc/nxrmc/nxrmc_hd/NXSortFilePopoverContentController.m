//
//  NXSortFilePopoverContentController.m
//  nxrmc
//
//  Created by EShi on 7/30/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXSortFilePopoverContentController.h"
#import "NXFileListViewController.h"

@interface NXSortFilePopoverContentController ()
@property(nonatomic) NSInteger selRow;
@property(nonatomic) BOOL isRootFolder;
@end

@implementation NXSortFilePopoverContentController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.selRow = -1;
    
    self.clearsSelectionOnViewWillAppear = YES;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TableViewCell"];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(instancetype) initWithFileListVC:(NXFileListViewController *) fileListVC isRootFolder:(BOOL) isRootFolder
{
    self = [super init];
    if (self) {
        _fileListVC = fileListVC;
        _isRootFolder = isRootFolder;
        if (_isRootFolder) {
            self.preferredContentSize = CGSizeMake(320.0, self.fileListVC.sortOperationArray.count*50.0);
        }else
        {
            self.preferredContentSize = CGSizeMake(320.0, (self.fileListVC.sortOperationArray.count - 1)*50.0);
        }
        
    }
    return self;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

   
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (self.isRootFolder) {
        return [self.fileListVC.sortOperationArray count];
    }else
    {
        // if is not root folder, delete the sort by repository, it is at the end of sortOperationArray
        return [self.fileListVC.sortOperationArray count] - 1;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TableViewCell" forIndexPath:indexPath];
    
    NSDictionary *sortOptDic = self.fileListVC.sortOperationArray[indexPath.row];
    NSString *cellImageName = sortOptDic[SORT_OPT_ICON];
    NSString *cellTitle = sortOptDic[SORT_OPT_NAME];
    if (self.selRow == -1) {
        if ([cellTitle isEqualToString:self.fileListVC.curSortOptName]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }else
    {
        if (indexPath.row == self.selRow) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
  
    cell.imageView.image = [UIImage imageNamed:cellImageName];
    cell.textLabel.text = cellTitle;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sortOptDic = self.fileListVC.sortOperationArray[indexPath.row];
    self.selRow = indexPath.row;
    [tableView reloadData];
   
    
    NSString* sortTitle = sortOptDic[SORT_OPT_NAME];
    if ([self.fileListVC respondsToSelector:@selector(contentController:selectSortTitle:)]) {
        [self.fileListVC contentController:self selectSortTitle:sortTitle];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

@end
