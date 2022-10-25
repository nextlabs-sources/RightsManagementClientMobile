//
//  NXTransView.m
//  nxrmc
//
//  Created by EShi on 12/22/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXTransView.h"

@implementation NXTransView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    [self removeFromSuperview];
    return [self.coverView hitTest:point withEvent:event];
}
@end
