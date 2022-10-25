//
//  NXFileDetailInfoFileAttriTableViewCell.m
//  nxrmc
//
//  Created by nextlabs on 1/19/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXFileDetailInfoFileAttriTableViewCell.h"

@implementation NXFileDetailInfoFileAttriTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

+ (instancetype)fileAttrTableViewCellWithTableView:(UITableView*)tableView {
    static NSString *attrCell = @"NXFileDetailInfoFileAttriTableViewCellIdentifier";
    NXFileDetailInfoFileAttriTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:attrCell];
    if(cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:nil options:nil] lastObject];
    }
    return cell;
}


@end
