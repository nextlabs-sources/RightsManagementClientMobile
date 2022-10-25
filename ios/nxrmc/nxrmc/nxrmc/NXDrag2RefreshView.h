//
//  Drag2RefeshView.h
//  DragToRefreshDemo
//
//  Created by ShiTeng on 15/5/6.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <UIKit/UIKit.h>

// The kind of refeshView
typedef enum
{
    kHeaderRefeshView,
    kFooterRefeshView
    
}Drag2RefreshViewType;

// The state of refreshView
typedef enum
{
    kDrag2RefreshViewStateDragToRefresh,    // The init state
    kDrag2RefreshViewStateLooseToRefresh,   // Only for headerview
    kDrag2RefreshViewStateRefreshing        // Refreshing
    
}Drag2RefreshViewState;

@interface NXDrag2RefeshView : UIView
@property(nonatomic) Drag2RefreshViewState state;
-(instancetype) initWithFrame:(CGRect)frame refeshViewType:(Drag2RefreshViewType) viewType;
-(void)flipImageAnimated:(BOOL)animated;

-(void) relayoutInterface;

@end
