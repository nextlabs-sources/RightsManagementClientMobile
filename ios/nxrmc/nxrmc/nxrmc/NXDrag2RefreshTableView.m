//
//  Drag2RefreshTableView.m
//  DragToRefreshDemo
//
//  Created by ShiTeng on 15/5/6.
//  Copyright (c) 2015年 ShiTeng. All rights reserved.
//

#import "NXDrag2RefreshTableView.h"
#import "NXCommonUtils.h"

@interface NXDrag2RefreshTableView()

@property(nonatomic, strong) NXDrag2RefeshView* headerRefeshView;
@property(nonatomic, strong) NXDrag2RefeshView* footerRefeshView;

// The refresh state of refresh table
@property(nonatomic) BOOL headRefreshing;
@property(nonatomic) BOOL footRefreshing;

// the flag use header refresh view or footer refresh view
@property(nonatomic) BOOL shouldShowHeaderRefreshView;
@property(nonatomic) BOOL shouldShowFooterRefreshView;

// the outer delegate, for we set scollview delegate = self to response to
// scollview scoll events, so we need outer delegate, which will send tableview
// event to outer view
@property(nonatomic, weak) id<UITableViewDelegate> outerDelegate;
@property(nonatomic) UIEdgeInsets originalContentInset;
@property(nonatomic) BOOL refreshViewHide;

-(void) addHeaderRefeshView;
@end


@implementation NXDrag2RefreshTableView

-(instancetype) initWithFrame:(CGRect)frame addHeaderRefreshView:(BOOL) showHeaderRefreshView addFooterRefreshView:(BOOL) showFooterRefeshView
{
    self = [super initWithFrame:frame];
    if (self) {
        // init the height of refresh view
        _headerRefreshViewHeight = 100.f;
        _footerRefreshViewHeight = 65.f;
        _refreshViewHide = YES;
        
        //
        _shouldShowHeaderRefreshView = showHeaderRefreshView;
        _shouldShowFooterRefreshView = showFooterRefeshView;
        
        // add header/footer refreshview if nesscessary
        
        if (_shouldShowHeaderRefreshView) {
            
            [self addHeaderRefeshView];
        }
        
        if (_shouldShowFooterRefreshView) {
            
            [self addFooterRefeshView];
        }
        // set delegate is self(The drag2RefreshTableview will response to himself)!!!
        self.delegate = self;
        self.scrollsToTop = YES;
        
        self.originalContentInset = self.contentInset;
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

-(instancetype) initWithFrame:(CGRect)frame addHeaderRefreshView:(BOOL) showHeaderRefreshView addFooterRefreshView:(BOOL) showFooterRefeshView ContentViewController:(UIViewController *) contentVC NavBar:(UIView*) navBar isHomePage:(BOOL)isHomePage{
    self = [super initWithFrame:frame];
    if (self) {
        // init the height of refresh view
        _headerRefreshViewHeight = 150.f;
        _footerRefreshViewHeight = 65.f;
        
        _navBar = navBar;
        _isHomePage = isHomePage;
        _refreshViewHide = YES;
        //
        _shouldShowHeaderRefreshView = showHeaderRefreshView;
        _shouldShowFooterRefreshView = showFooterRefeshView;
        
        // add header/footer refreshview if nesscessary
        
        if (_shouldShowHeaderRefreshView) {
           
            [self addHeaderRefeshView];
        }
        
        if (_shouldShowFooterRefreshView) {
            
            [self addFooterRefeshView];
        }
        // set delegate is self(The drag2RefreshTableview will response to himself)!!!
        self.delegate = self;
        
        // add search bar
       // float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
       // if (systemVersion < 8.0) {
            UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
            searchBar.placeholder = NSLocalizedString(@"SEARCH_PLACE_HOLDER", NULL);
            self.tableHeaderView = searchBar;

            _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:contentVC];
            _searchDisplayController.searchResultsDataSource = (id<UITableViewDataSource>)contentVC;
            _searchDisplayController.searchResultsDelegate = (id<UITableViewDelegate>)contentVC;
        _searchDisplayController.delegate = (id<UISearchDisplayDelegate>) contentVC;
        
//        }else
//        {
//            _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
//            _searchController.searchResultsUpdater = (id<UISearchResultsUpdating>)contentVC;
//            _searchController.searchBar.frame = CGRectMake(_searchController.searchBar.frame.origin.x, _searchController.searchBar.frame.origin.y, _searchController.searchBar.frame.size.width, 44.0);
//           // _searchController.dimsBackgroundDuringPresentation = NO;
//            _searchController.delegate = (id <UISearchControllerDelegate>)contentVC;
//            self.tableHeaderView = _searchController.searchBar;
//            
//            
//        }
      
        self.backgroundColor = [UIColor whiteColor];
        // Listen to the device rotate
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ResponseToDeviceRotate) name:UIDeviceOrientationDidChangeNotification object:nil];
        self.scrollsToTop = YES;
        
        self.originalContentInset = self.contentInset;
    }
    
    return self;
}

#pragma mark - UIScrollViewDelegate
-(CGFloat) looseToRefreshThreshold
{
    return self.headerRefreshViewHeight;
}
// Scroll step1 用户拖动
-(void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    // 当用户向下拖时， 判断是否超过阈值（-[self looseToRefreshThreshold]），超过 则更新headerview为“松手可更新”状态，
    // 此处注意，实际不更新，需等到用户放手之后，才执行更新操作
    if (self.shouldShowHeaderRefreshView
        && self.headerRefeshView
        && self.contentOffset.y < -[self looseToRefreshThreshold]
        && self.headerRefeshView.state == kDrag2RefreshViewStateDragToRefresh
        && !self.headRefreshing
        && !self.footRefreshing) {
        
        self.headerRefeshView.state = kDrag2RefreshViewStateLooseToRefresh;
        [self.headerRefeshView flipImageAnimated:YES]; // 翻转箭头
    }
    
    // 当用户向上拖时，若正在执行headerRefreshing, 则可以上拉遮挡住刷新动画
    if (self.shouldShowHeaderRefreshView
        && self.headerRefeshView
        && self.headRefreshing
        && self.headerRefeshView.state == kDrag2RefreshViewStateRefreshing
        && !self.refreshViewHide) {
        
        // tableview 向上拖，隐蔽刷新view
        if (self.contentOffset.y >= -self.contentInset.top && self.contentOffset.y < 0) {
            self.contentInset = UIEdgeInsetsMake(-self.contentOffset.y, self.contentInset.left, self.contentInset.bottom, self.contentInset.right);
        }else if(self.contentOffset.y > 0){ // 已经拖动到上面，固定content的位置
            [self moveRefreshViewBackToTop];
        }
    }
    
    // 当用户向上拖时，判断是否该执行上拉加载更多
    if(self.shouldShowFooterRefreshView && self.footerRefeshView)
    {
        CGFloat distance = self.contentSize.height - self.contentOffset.y - self.frame.size.height;
        if (distance <=0                    // tableview的内容已经拉到了头,这时应该加载更多操作
            && self.contentOffset.y > 0.f  // 向上拉
            && self.footerRefeshView.state == kDrag2RefreshViewStateDragToRefresh
            && !self.headRefreshing         // 一次只能执行一个刷新动作
            && !self.footRefreshing) {
            
            self.footerRefeshView.state = kDrag2RefreshViewStateRefreshing;
            self.footRefreshing = YES;
            self.dragEndBlock(kFooterRefeshView);
        }
    }
    
}
// Scroll step2 用户拖动完毕，手指离开屏幕
-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // user finish drag table view
    // first check wether drag enough
    if (self.shouldShowHeaderRefreshView && self.headerRefeshView){
        
        if (self.contentOffset.y < -[self looseToRefreshThreshold]   //是否拖得足够多
            && self.headerRefeshView.state == kDrag2RefreshViewStateLooseToRefresh  // 和“是否拖得足够多” 一样的判断
            && !self.headRefreshing
            && !self.footRefreshing) {
            
            // 固定显示加载界面
            if (self.isHomePage) {
                  NSLog(@"Before contentInset is %@", NSStringFromUIEdgeInsets(self.contentInset));
                self.originalContentInset = self.contentInset;
                self.contentInset = UIEdgeInsetsMake(self.headerRefreshViewHeight + self.navBar.frame.size.height + self.contentInset.top, self.contentInset.left, self.contentInset.bottom, self.contentInset.right);
            }else
            {
                NSLog(@"Before contentInset is %@", NSStringFromUIEdgeInsets(self.contentInset));
                self.originalContentInset = self.contentInset;
                self.contentInset = UIEdgeInsetsMake(self.headerRefreshViewHeight + self.contentInset.top, self.contentInset.left, self.contentInset.bottom, self.contentInset.right);

            }
            
            // 更新headview状态为正在加载
            self.refreshViewHide = NO;
            self.headerRefeshView.state = kDrag2RefreshViewStateRefreshing;
            self.headRefreshing = YES;
            self.dragEndBlock(kHeaderRefeshView);
            

        }
    }
}

#pragma mark - TableView delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.outerDelegate) {
        [self.outerDelegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.outerDelegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        return [self.outerDelegate tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return 44;
}

-(void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (self.outerDelegate && [self.outerDelegate respondsToSelector:@selector(tableView:accessoryButtonTappedForRowWithIndexPath:)]) {
        return [self.outerDelegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}

#pragma mark - addHeaderRefeshView , addFooterRefeshView
-(void) addHeaderRefeshView{
    
    if (self.shouldShowHeaderRefreshView && !_headerRefeshView) {
        CGRect rect = CGRectMake(0, -self.headerRefreshViewHeight, self.bounds.size.width, self.headerRefreshViewHeight);
        _headerRefeshView = [[NXDrag2RefeshView alloc] initWithFrame:rect refeshViewType:kHeaderRefeshView];
        [self addSubview:_headerRefeshView];

    }
}

-(void) addFooterRefeshView{
    if (self.shouldShowFooterRefreshView && !_footerRefeshView) {
        CGFloat height = MAX(self.contentSize.height, self.frame.size.height);
        CGRect rect = CGRectMake(0, height, self.bounds.size.width, self.footerRefreshViewHeight);
        _footerRefeshView = [[NXDrag2RefeshView alloc] initWithFrame:rect refeshViewType:kFooterRefeshView];
        self.tableFooterView = _footerRefeshView;
    }
}

-(void) drag2RefreshTableViewBackToTop
{
   [self scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

#pragma mark - when finish tableview refresh
-(void) didRefreshDragTableView
{
    NXDrag2RefeshView* dragView = self.headerRefeshView;
    if (dragView) {
        self.headRefreshing = NO;
        [self moveRefreshViewBackToTop];
        dragView.state = kDrag2RefreshViewStateDragToRefresh;
        [dragView flipImageAnimated:NO];
    }
    
}

-(void) moveRefreshViewBackToTop
{
    NXDrag2RefeshView* dragView = self.headerRefeshView;
    if (dragView) {
        if (!self.refreshViewHide) {
            self.refreshViewHide = YES;
            [UIView animateWithDuration:0.3f animations:^{
                self.contentInset = self.originalContentInset;
                NSLog(@"After contentInset is %@", NSStringFromUIEdgeInsets(self.contentInset));
            } completion:^(BOOL finished) {
                
            }];
        }
    }
}

- (void) moveToOriginalContentInset
{
    self.contentInset = self.originalContentInset;
}
#pragma mark - relayout the refresh view to fit device rotate
-(void) relayoutRefreshView
{
    if (self.headerRefeshView) {
        [self.headerRefeshView relayoutInterface];
    }
    if(self.footerRefeshView) {
        [self.footerRefeshView relayoutInterface];
    }
    
    
}
#pragma mark - Response to  notify
-(void) ResponseToDeviceRotate
{
    
    if (self.superview) {
        [self relayoutRefreshView];
    }
    
}



#pragma mark - delloc
-(void) dealloc
{
    // remove the notify receiver
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - overwrite super function to set outer delegete
-(void) setDelegate:(id<UITableViewDelegate>)delegate
{
    if ([delegate isEqual:self]) {
        super.delegate = self;
    }else{
        self.outerDelegate = delegate;
    }
}

@end
