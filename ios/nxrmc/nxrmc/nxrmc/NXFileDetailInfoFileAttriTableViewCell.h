//
//  NXFileDetailInfoFileAttriTableViewCell.h
//  nxrmc
//
//  Created by nextlabs on 1/19/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NXFileDetailInfoFileAttriTableViewCell : UITableViewCell

+ (instancetype)fileAttrTableViewCellWithTableView:(UITableView*)tableView;

@property (weak, nonatomic) IBOutlet UILabel *infoName;
@property (weak, nonatomic) IBOutlet UILabel *infoValue;

@end
