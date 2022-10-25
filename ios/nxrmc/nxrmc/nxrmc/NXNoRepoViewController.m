//
//  NXNoRepoViewController.m
//  nxrmc
//
//  Created by EShi on 11/4/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXNoRepoViewController.h"

@interface NXNoRepoViewController ()
@property(nonatomic, strong) UIImageView *repoIconsView;
@property(nonatomic, strong) UIView  *labelAndActionView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *detailLabel;
@end

@implementation NXNoRepoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.97 green:0.97 blue:0.99 alpha:1.0];
   // self.view.backgroundColor = [UIColor yellowColor];
//    // Do any additional setup after loading the view.
//    _repoIconsView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RepoEmptyState"]];
//    _repoIconsView.translatesAutoresizingMaskIntoConstraints = NO;
//    
//    _labelAndActionView = [[UIView alloc] init];
//    _labelAndActionView.translatesAutoresizingMaskIntoConstraints = NO;
//    _labelAndActionView.backgroundColor = [UIColor grayColor];
//    
//    [self.view addSubview:_repoIconsView];
//    _repoIconsView.backgroundColor = [UIColor yellowColor];
//    //[self.view addSubview:_labelAndActionView];
//    
////    NSDictionary *bindings = @{@"repoIconsView":_repoIconsView, @"labelAndActionView":_labelAndActionView};
////    NSArray *constraintsV = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[repoIconsView]-|" options:0 metrics:nil views:bindings];
////    [self.view addConstraints:constraintsV];
//    
//    [self.view addConstraint:[NSLayoutConstraint
//                              constraintWithItem:_repoIconsView
//                              attribute:NSLayoutAttributeWidth
//                              relatedBy:NSLayoutRelationEqual
//                              toItem:self.view
//                              attribute:NSLayoutAttributeWidth
//                              multiplier:0.6
//                              constant:0.0]];
//    
//    [self.view addConstraint:[NSLayoutConstraint
//                              constraintWithItem:_repoIconsView
//                              attribute:NSLayoutAttributeHeight
//                              relatedBy:NSLayoutRelationEqual
//                              toItem:self.view
//                              attribute:NSLayoutAttributeWidth
//                              multiplier:0.6
//                              constant:0.0]];
//    
//    
//    [self.view addConstraint:[NSLayoutConstraint
//                              constraintWithItem:_repoIconsView
//                              attribute:NSLayoutAttributeCenterX
//                              relatedBy:NSLayoutRelationEqual
//                              toItem:self.view
//                              attribute:NSLayoutAttributeCenterX
//                              multiplier:1.0
//                              constant:0.0]];
//
//    
    // Listen to the device rotate
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ResponseToDeviceRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.view.frame = self.continerView.frame;
  
}

-(void) ResponseToDeviceRotate:(NSNotification *) notification
{
    self.view.frame = self.continerView.frame;
}

@end
