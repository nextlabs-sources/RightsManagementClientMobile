//
//  NXAboutPageViewController.m
//  nxrmc
//
//  Created by EShi on 1/6/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXAboutPageViewController.h"

@interface NXAboutPageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *NXIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *softwareVersion;
@property (weak, nonatomic) IBOutlet UILabel *nextlabsWebSite;
@property (weak, nonatomic) IBOutlet UILabel *nextlabsAppName;

@end

@implementation NXAboutPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"HELP_TITLE", NULL);
    [self setAutomaticallyAdjustsScrollViewInsets:NO];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapWebSite:)];
    [_nextlabsWebSite addGestureRecognizer:tap];
    _nextlabsWebSite.userInteractionEnabled = YES;
    
    _softwareVersion.text = [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"VERSION", NULL), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        
  
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) tapWebSite:(UIGestureRecognizer *) gesture
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.nextlabs.com/about/contact-us/"]];
}


@end
