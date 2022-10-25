//
//  NXFileAttrTableViewCell.h
//  nxrmc
//
//  Created by helpdesk on 11/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NXFileAttrTableViewCell : UITableViewCell

@property (nonatomic,assign) BOOL showSeperator;

@property (weak, nonatomic) IBOutlet UILabel *infoName;
@property (weak, nonatomic) IBOutlet UILabel *infoValue;

+ (instancetype)fileAttrTableViewCellWithTableView:(UITableView*)tableView;

@end
