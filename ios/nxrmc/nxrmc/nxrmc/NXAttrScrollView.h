//
//  NXScrollView.h
//  nxrmc
//
//  Created by helpdesk on 22/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NXAttrScrollView : UIScrollView

- (void)addPageView:(UIView*)pageView;
- (NSInteger)currentPage;
@end
