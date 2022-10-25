//
//  NXAutoLayoutTableViewCell.h
//  nxrmc
//
//  Created by EShi on 3/30/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NXAutoLayoutTableViewCell : UITableViewCell
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *bodyLabel;

@property(nonatomic, strong) UIImageView *cellImageView;
@property(nonatomic, strong) UIImageView *cellTitleImageView;
- (void)updateFonts;
@end
