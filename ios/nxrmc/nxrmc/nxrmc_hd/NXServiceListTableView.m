//
//  NXServiceListTableView.m
//  nxrmc
//
//  Created by EShi on 12/25/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXServiceListTableView.h"
#import "NXFileListViewController.h"
#import "NXLoginUser.h"
#import "NXRMCDef.h"
#import "NXAutoLayoutTableViewCell.h"



@interface NXServiceListTableView()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property (strong, nonatomic) NSMutableDictionary *offscreenCells;
@property(nonatomic, strong) NSDictionary *repoIconDict;
@end


@implementation NXServiceListTableView
static NSString *CELL_IDENTITY = @"AUTO_LAYOUT_CELL_IDENTITY";
static NSString *NORMAL_CELL_IDENTITY = @"NARMAL_CELL_IDENTITY";

-(instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_tableView];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        self.offscreenCells = [NSMutableDictionary dictionary];
        NSDictionary *bindView = @{@"tableView":_tableView};
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:nil views:bindView]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:0 metrics:nil views:bindView]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToBoundServiceOpt:) name:NOTIFICATION_REPO_ADDED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToBoundServiceOpt:) name:NOTIFICATION_REPO_DELETED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(responseToBoundServiceOpt:) name:NOTIFICATION_REPO_CHANGED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contentSizeCategoryChanged:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
        
        _repoIconDict = @{[NSNumber numberWithInteger:kServiceDropbox]:[UIImage imageNamed:@"DropboxIcon"],
                          [NSNumber numberWithInteger:kServiceSharepointOnline]:[UIImage imageNamed:@"SharepointIcon"],
                          [NSNumber numberWithInteger:kServiceSharepoint]:[UIImage imageNamed:@"SharepointIcon"],
                          [NSNumber numberWithInteger:kServiceOneDrive]:[UIImage imageNamed:@"OneDriveIcon"],
                          [NSNumber numberWithInteger:kServiceGoogleDrive]:[UIImage imageNamed:@"GoogleDriveIcon"]};
    }
    
    
    return self;
}
- (void)contentSizeCategoryChanged:(NSNotification *)notification
{
    [self.tableView reloadData];
}

-(NSMutableArray *) selServiceArray
{
    if (_selServiceArray == nil) {
        _selServiceArray = [[NSMutableArray alloc] init];
        [self loadServiceArrayData];
    }
    
    return _selServiceArray;
}

-(void) loadServiceArrayData
{
    [_selServiceArray removeAllObjects];
    for(NXBoundService *service in [NXLoginUser sharedInstance].boundServices)
    {
         if (service.service_selected.boolValue && service.service_isAuthed.boolValue)
         {
             [_selServiceArray addObject:service];
         }
    }
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [NXLoginUser sharedInstance].boundServices.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:NORMAL_CELL_IDENTITY];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NORMAL_CELL_IDENTITY];
        }


        cell.textLabel.text = NSLocalizedString(@"SLIDEMENU_ADD_REPOSITORY", NULL);
        cell.imageView.image = [UIImage imageNamed:@"AddRepositoryBlue"];
        cell.backgroundColor = [UIColor clearColor];
        
    }else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTITY];
        if (cell == nil) {
            cell = [[NXAutoLayoutTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTITY];
        }
        
        NXAutoLayoutTableViewCell *autoLayoutCell = (NXAutoLayoutTableViewCell *) cell;
        [autoLayoutCell updateFonts];
        
        NXBoundService *boundService = [NXLoginUser sharedInstance].boundServices[indexPath.row - 1];
        autoLayoutCell.titleLabel.text = boundService.service_alias;
        autoLayoutCell.bodyLabel.text = boundService.service_account;
        if (boundService.service_type.integerValue == kServiceSharepoint || boundService.service_type.integerValue == kServiceSharepointOnline) {
            
            NSString *spURL = [boundService.service_account_id componentsSeparatedByString:@"^"].firstObject;
            autoLayoutCell.bodyLabel.text = [NSString stringWithFormat:@"%@\n%@", autoLayoutCell.bodyLabel.text,spURL];
        
        }
        
        if (boundService.service_selected.boolValue) {
            autoLayoutCell.cellImageView.image = [UIImage imageNamed:@"CheckSel"];
          //  autoLayoutCell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }else
        {
            //autoLayoutCell.accessoryType = UITableViewCellAccessoryNone;
            autoLayoutCell.cellImageView.image = nil;
  
        }
        
        if(boundService.service_isAuthed.boolValue == NO)
        {
            autoLayoutCell.cellImageView.image = [UIImage imageNamed:@"HighPriority"];
        }
        
        autoLayoutCell.cellTitleImageView.image = self.repoIconDict[boundService.service_type];
       
        [autoLayoutCell setNeedsUpdateConstraints];
        [autoLayoutCell updateConstraintsIfNeeded];
        
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 50.0;
    }else
    {
        // This project has only one cell identifier, but if you are have more than one, this is the time
        // to figure out which reuse identifier should be used for the cell at this index path.
        NSString *reuseIdentifier = CELL_IDENTITY;
        
        // Use the dictionary of offscreen cells to get a cell for the reuse identifier, creating a cell and storing
        // it in the dictionary if one hasn't already been added for the reuse identifier.
        // WARNING: Don't call the table view's dequeueReusableCellWithIdentifier: method here because this will result
        // in a memory leak as the cell is created but never returned from the tableView:cellForRowAtIndexPath: method!
        NXAutoLayoutTableViewCell *cell = [self.offscreenCells objectForKey:reuseIdentifier];
        if (!cell) {
            cell = [[NXAutoLayoutTableViewCell alloc] init];
            [self.offscreenCells setObject:cell forKey:reuseIdentifier];
        }
        
        // Configure the cell for this indexPath
        [cell updateFonts];
        
        NXBoundService *boundService = [NXLoginUser sharedInstance].boundServices[indexPath.row - 1];
        if (boundService.service_selected.boolValue) {
            cell.cellImageView.image = [UIImage imageNamed:@"CheckSel"];
           // cell.accessoryType = UITableViewCellAccessoryCheckmark;
            
        }else
        {
            cell.cellImageView.image = nil;
         //   cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        cell.titleLabel.text = boundService.service_alias;
        cell.bodyLabel.text = boundService.service_account;
        
        
        if (boundService.service_type.integerValue == kServiceSharepoint || boundService.service_type.integerValue == kServiceSharepointOnline) {
            
            NSString *spURL = [boundService.service_account_id componentsSeparatedByString:@"^"].firstObject;
            cell.bodyLabel.text = [NSString stringWithFormat:@"%@\n%@", cell.bodyLabel.text, spURL];
        }
        
        
        
        // Make sure the constraints have been added to this cell, since it may have just been created from scratch
        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
        
        // The cell's width must be set to the same size it will end up at once it is in the table view.
        // This is important so that we'll get the correct height for different table view widths, since our cell's
        // height depends on its width due to the multi-line UILabel word wrapping. Don't need to do this above in
        // -[tableView:cellForRowAtIndexPath:] because it happens automatically when the cell is used in the table view.
        cell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.bounds), CGRectGetHeight(cell.bounds));
        // NOTE: if you are displaying a section index (e.g. alphabet along the right side of the table view), or
        // if you are using a grouped table view style where cells have insets to the edges of the table view,
        // you'll need to adjust the cell.bounds.size.width to be smaller than the full width of the table view we just
        // set it to above. See http://stackoverflow.com/questions/3647242 for discussion on the section index width.
        
        // Do the layout pass on the cell, which will calculate the frames for all the views based on the constraints
        // (Note that the preferredMaxLayoutWidth is set on multi-line UILabels inside the -[layoutSubviews] method
        // in the UITableViewCell subclass
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        // Get the actual height required for the cell
        CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        // Add an extra point to the height to account for the cell separator, which is added between the bottom
        // of the cell's contentView and the bottom of the table view cell.
        height += 1;
        
        return height;

    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        if([self.serviceListTableViewdelegate respondsToSelector:@selector(serviceListTableViewDidSelectAddService:)]){
            [self.serviceListTableViewdelegate serviceListTableViewDidSelectAddService:self];
        }
    }else
    {
        NXAutoLayoutTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        NXBoundService *service = [NXLoginUser sharedInstance].boundServices[indexPath.row - 1];
        if (service.service_isAuthed.boolValue == NO) {
            [self.serviceListTableViewdelegate serviceListTableView:self didSelectUnAuthedService:service];
            return;
        }
        
        if (cell.cellImageView.image == nil) {
            cell.cellImageView.image = [UIImage imageNamed:@"CheckSel"];
            
            
            NXBoundService *service = [NXLoginUser sharedInstance].boundServices[indexPath.row - 1];
            if (service.service_isAuthed.boolValue == NO) {
                [self.serviceListTableViewdelegate serviceListTableView:self didSelectUnAuthedService:service];
                return;
            }
            
            service.service_selected = [NSNumber numberWithBool:YES];
            [[NXLoginUser sharedInstance] updateService:service];
            
            if (![self.selServiceArray containsObject:service]) {
                [self.selServiceArray addObject:service];
            }
            
        }else
        {
           // cell.accessoryType = UITableViewCellAccessoryNone;
            cell.cellImageView.image = nil;
            NXBoundService *service = [NXLoginUser sharedInstance].boundServices[indexPath.row - 1];
            service.service_selected = [NSNumber numberWithBool:NO];
            [[NXLoginUser sharedInstance] updateService:service];
            [self.selServiceArray removeObject:service];
        }
        
        if ([self.serviceListTableViewdelegate respondsToSelector:@selector(serviceListTableView:didSelectServices:)]) {
            [self.serviceListTableViewdelegate serviceListTableView:self didSelectServices:self.selServiceArray];
        }

    }
}

-(void) responseToBoundServiceOpt:(NSNotification *) notification
{
    [self loadServiceArrayData];
    [self.tableView reloadData];
}
@end
