//
//  serviceListController.m
//  nxrmc
//
//  Created by EShi on 7/22/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXServiceListPopoverController.h"
#import "NXFileListViewController.h"
#import "NXLoginUser.h"
#import "NXRMCDef.h"


@interface NXServiceListPopoverController ()

@end

@implementation NXServiceListPopoverController
- (instancetype) initWithServiceArray:(NSArray *)boundServices FileListVC:(NXFileListViewController *)fileListVC
{
    self = [super init];
    if (self) {
       
        _fileListVC = fileListVC;
        self.clearsSelectionOnViewWillAppear = YES;
        if ([NXLoginUser sharedInstance].boundServices.count == 0) {
            self.preferredContentSize = CGSizeMake(240.0, 50.0);

        }else
        {
            self.preferredContentSize = CGSizeMake(240.0, [NXLoginUser sharedInstance].boundServices.count*50.0 + 50);

        }
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSMutableArray *) selServiceArray
{
    if (_selServiceArray == nil) {
        _selServiceArray = [[NSMutableArray alloc] init];
    }
    
    return _selServiceArray;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [NXLoginUser sharedInstance].boundServices.count + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CELL_IDENTITY = @"ServiceCellIdentity";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTITY];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CELL_IDENTITY];
    }
    
    if(indexPath.row +1 <= [NXLoginUser sharedInstance].boundServices.count)
    {
        NXBoundService *boundService = [NXLoginUser sharedInstance].boundServices[indexPath.row];
        if (boundService.service_selected.boolValue) {
            
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            if (![self.selServiceArray containsObject:boundService]) {
                [self.selServiceArray addObject:boundService];
            }
            
        }else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            [self.selServiceArray removeObject:boundService];
        }
        cell.textLabel.text = boundService.service_alias;
        cell.detailTextLabel.text = boundService.service_account;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }else // ADD Service
    {
        static NSString *ADD_REPOSITORY_CELL_IDNETITY = @"AddRepositoryCellIndentiy";
        cell = [tableView dequeueReusableCellWithIdentifier:ADD_REPOSITORY_CELL_IDNETITY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ADD_REPOSITORY_CELL_IDNETITY];
        }
        
        cell.textLabel.text = NSLocalizedString(@"SLIDEMENU_ADD_REPOSITORY", NULL);
        cell.imageView.image = [UIImage imageNamed:@"AddRepositoryBlue"];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row + 1 <= [NXLoginUser sharedInstance].boundServices.count)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.accessoryType == UITableViewCellAccessoryNone) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
            NXBoundService *service = [NXLoginUser sharedInstance].boundServices[indexPath.row];
            service.service_selected = [NSNumber numberWithBool:YES];
            [[NXLoginUser sharedInstance] updateService:service];
            
            if (![self.selServiceArray containsObject:service]) {
                [self.selServiceArray addObject:service];
            }
            
        }else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            NXBoundService *service = [NXLoginUser sharedInstance].boundServices[indexPath.row];
            service.service_selected = [NSNumber numberWithBool:NO];
            [[NXLoginUser sharedInstance] updateService:service];
            [self.selServiceArray removeObject:service];
        }
        
        if ([self.delegate respondsToSelector:@selector(serviceListPopoverController:didSelectServices:)]) {
            [self.delegate serviceListPopoverController:self didSelectServices:self.selServiceArray];
        }

    }else
    {
        if([self.delegate respondsToSelector:@selector(serviceListPopoverControllerDidSelectAddService:)]){
            [self.delegate serviceListPopoverControllerDidSelectAddService:self];
        }
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}


@end
