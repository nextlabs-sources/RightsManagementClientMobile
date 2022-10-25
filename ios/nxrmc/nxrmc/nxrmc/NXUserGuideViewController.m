//
//  NXUserGuideViewController.m
//  nxrmc
//
//  Created by nextlabs on 10/13/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXUserGuideViewController.h"
#import "NXLoginViewController.h"

#import "NXCommonUtils.h"

#define USERGUIDE_PAGE_COUNT   4

@interface NXUserGuideViewController ()<UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintWidth;

@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation NXUserGuideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initScrollView];
    [self initPageControl];
    [self initTimer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer  = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.scrollView.contentOffset = CGPointMake(0, 0);
}

#pragma mark - private method

- (void)initScrollView {
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleDefault;
    self.scrollView.delegate = self;
    
    [self generateWelcomePages];
}

- (void)initPageControl {
    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.numberOfPages = USERGUIDE_PAGE_COUNT;
    self.pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    self.pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    
    [self.view addSubview:self.pageControl];
    self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeBottom multiplier:1 constant:-20]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pageControl attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];

    
    [self.view bringSubviewToFront:self.pageControl];
}

- (void)initTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(autoPlayWelcomePage) userInfo:nil repeats:YES];
}

- (UIView *)createWelcomPageView:(NSInteger)pageNumber {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithRed:248.f/255.f green:248.f/255.f blue:253.f/255.f alpha:1.0];
    
    UIImageView *imageview = [[UIImageView alloc] init];
    imageview.image = [UIImage imageNamed:[NSString stringWithFormat:@"WelcomeImage%ld", (long)pageNumber]];
    imageview.contentMode = UIViewContentModeScaleAspectFit;
    
    UILabel *label1 =  [[UILabel alloc] init];
    label1.numberOfLines = 2;
    label1.textAlignment = NSTextAlignmentCenter;
    label1.font = [UIFont systemFontOfSize:24.0];
    label1.textColor = [UIColor colorWithRed:30.f/255.f green:39.f/255.f blue:48.f/255.f alpha:1];
    label1.adjustsFontSizeToFitWidth = YES;
    NSString *title1 =  [NSString stringWithFormat:@"USER_GUIDE_PAGE%dTITLE1", (int)pageNumber + 1];
    label1.text = NSLocalizedString(title1, NULL);
    
    UILabel *label2 =  [[UILabel alloc] init];
    label2.numberOfLines = 2;
    label2.textAlignment = NSTextAlignmentCenter;
    label2.font = [UIFont systemFontOfSize:22.0f];
    label2.textColor = RMC_MAIN_COLOR;
    label2.adjustsFontSizeToFitWidth = YES;
    
    NSString *title2 =  [NSString stringWithFormat:@"USER_GUIDE_PAGE%dTITLE2", (int)pageNumber + 1];
    label2.text = NSLocalizedString(title2, nil);

    [view addSubview:label2];
    [view addSubview:label1];
    [view addSubview:imageview];
    imageview.translatesAutoresizingMaskIntoConstraints = NO;
    label1.translatesAutoresizingMaskIntoConstraints = NO;
    label2.translatesAutoresizingMaskIntoConstraints = NO;
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:imageview attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:imageview attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:imageview attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeWidth multiplier:0.7 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:imageview attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:imageview attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:imageview attribute:NSLayoutAttributeBottom multiplier:1 constant:35]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeWidth multiplier:0.7 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:label1 attribute:NSLayoutAttributeWidth multiplier: 0.2 constant:0]];
    
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:label1 attribute:NSLayoutAttributeBottom multiplier:1 constant:35]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeWidth multiplier:0.7 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:label2 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:label2 attribute:NSLayoutAttributeWidth multiplier:0.2 constant:0]];
    return view;
}

- (void)generateWelcomePages {
    UIView *lastView = nil;
    for (int i = 0; i < USERGUIDE_PAGE_COUNT; ++i) {
        UIView *welcomePageView =  [self createWelcomPageView:i];
        [self.scrollView addSubview:welcomePageView];
        welcomePageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:welcomePageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:welcomePageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:welcomePageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
        
        if (i == 0) {
            [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:welcomePageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.scrollView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
            lastView = welcomePageView;
        } else {
            [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:welcomePageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:lastView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
            lastView = welcomePageView;
        }
    }
}

#pragma mark - implementation UIViewController (UIConstraintBasedLayoutCoreMethods)

- (void)updateViewConstraints {
    [super updateViewConstraints];
    self.constraintWidth.constant = CGRectGetWidth(self.view.frame) * USERGUIDE_PAGE_COUNT;
}

#pragma mark - action method

- (IBAction)clickSignIn:(id)sender {
    [NXCommonUtils saveFirstTimeLaunchSymbol];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    NXLoginViewController *vcs = [storyboard instantiateViewControllerWithIdentifier:@"NXLoginVC"];
    [self.navigationController pushViewController:vcs animated:YES];
}

- (void)autoPlayWelcomePage {
    static NSInteger page = 0;
    if (page < USERGUIDE_PAGE_COUNT - 1) {
        ++page;
    } else if (page == USERGUIDE_PAGE_COUNT - 1) {
        [self.timer invalidate];
        [self clickSignIn:nil];
    }
    
    CGPoint offSet = CGPointMake(page * CGRectGetWidth(self.view.frame), 0);
    
    [self.scrollView setContentOffset:offSet animated:YES];
}

#pragma mark - implementation UIViewController (UIViewControllerRotation)

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.pageControl.currentPage = self.scrollView.contentOffset.x / CGRectGetWidth(self.view.frame);
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.timer invalidate];
}

@end
