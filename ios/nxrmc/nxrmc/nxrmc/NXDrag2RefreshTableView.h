//
//  Drag2RefreshTableView.h
//  DragToRefreshDemo
//
//  Created by ShiTeng on 15/5/6.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXDrag2RefreshView.h"

typedef void(^DragEndBlock) (Drag2RefreshViewType);

@interface NXDrag2RefreshTableView : UITableView<UITableViewDelegate, UIScrollViewDelegate>
@property(nonatomic, copy) DragEndBlock dragEndBlock;
@property(nonatomic) CGFloat headerRefreshViewHeight;
@property(nonatomic) CGFloat footerRefreshViewHeight;
@property(nonatomic) CGFloat tableViewHeightCorrector;
@property(nonatomic) CGFloat tableViewWidthCorrector;
@property(nonatomic, strong) UISearchDisplayController *searchDisplayController;
@property(nonatomic, strong) UISearchController *searchController;
@property(nonatomic, weak) UIView* navBar;
@property(nonatomic) BOOL isHomePage;
-(instancetype) initWithFrame:(CGRect)frame addHeaderRefreshView:(BOOL) showHeaderRefreshView addFooterRefreshView:(BOOL) showFooterRefeshView ContentViewController:(UIViewController *) contentVC NavBar:(UIView*) navBar isHomePage:(BOOL) isHomePage;

-(instancetype) initWithFrame:(CGRect)frame addHeaderRefreshView:(BOOL) showHeaderRefreshView addFooterRefreshView:(BOOL) showFooterRefeshView;
-(void) didRefreshDragTableView;
-(void) drag2RefreshTableViewBackToTop;

-(void) relayoutRefreshView;
-(void) ResponseToDeviceRotate;

-(void) moveRefreshViewBackToTop;
- (void) moveToOriginalContentInset;
@end
