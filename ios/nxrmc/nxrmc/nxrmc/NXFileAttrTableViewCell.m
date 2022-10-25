//
//  NXFileAttrTableViewCell.m
//  nxrmc
//
//  Created by helpdesk on 11/5/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXFileAttrTableViewCell.h"

@implementation NXFileAttrTableViewCell

+ (instancetype)fileAttrTableViewCellWithTableView:(UITableView*)tableView
{
    static NSString *attrCell = @"attrCell";
    NXFileAttrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:attrCell];
    if(cell == nil)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self.class) owner:nil options:nil] lastObject];
    }
    return cell;
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

//-(void)drawRect:(CGRect)rect
//{
//    if(self.showSeperator)
//    {
//        CGContextRef context = UIGraphicsGetCurrentContext();
//        
//        //draw the bottom seperator line
//        CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
//        CGContextStrokeRect(context, CGRectMake(5, rect.size.height, rect.size.width - 20, 1));
//    }
//}

//- (void)setFrame:(CGRect)frame {
//    CGRect newFrame = CGRectMake(frame.origin.x + 10, frame.origin.y + 0.5, frame.size.width - 2* 10, frame.size.height + 1);
//    [super setFrame:newFrame];
//}

@end
