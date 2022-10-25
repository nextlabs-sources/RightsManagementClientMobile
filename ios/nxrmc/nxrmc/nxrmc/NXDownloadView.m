//
//  NXDownloadView.m
//  iostest123
//
//  Created by helpdesk on 20/5/15.
//  Copyright (c) 2015 test123. All rights reserved.
//

#import "NXDownloadView.h"

@implementation NXDownloadView

- (id)initWithFrame:(CGRect)frame showDownloadView:(BOOL)show
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clipsToBounds = YES;
        [[NSBundle mainBundle] loadNibNamed:@"NXDownloadView" owner:self options:nil];
        if(show)
        {
            self.downloadBarView.frame = frame;
            [self addSubview:self.downloadBarView];
        }
        else
        {
            self.waittingView.frame = frame;
            [self addSubview:self.waittingView];
        }
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
