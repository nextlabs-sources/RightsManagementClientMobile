//
//  NXRMSConfigViewController.m
//  nxrmc
//
//  Created by EShi on 7/25/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXRMSConfigViewController.h"
#import "NXCommonUtils.h"

@interface NXRMSConfigViewController ()
//@property (strong, nonatomic)  UITextField *rmsSiteURLTextField;
@property (strong, nonatomic)  UITextField *tenantNameTextField;
@property (strong, nonatomic) UIButton *configButton;
@property (strong, nonatomic) UIButton *resetToDefaultButton;
@end

@implementation NXRMSConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.automaticallyAdjustsScrollViewInsets = NO;
   
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self commitInit];
}

-(void) commitInit
{
    self.navigationItem.title = NSLocalizedString(@"RMS_CONFIG", nil);
    self.navigationController.navigationBarHidden = NO;
    self.view.backgroundColor = [UIColor whiteColor];

    
//    _rmsSiteURLTextField = [[UITextField alloc] initWithFrame:CGRectZero];
//    _rmsSiteURLTextField.translatesAutoresizingMaskIntoConstraints = NO;
//    _rmsSiteURLTextField.borderStyle = UITextBorderStyleRoundedRect;
//    _rmsSiteURLTextField.placeholder = NSLocalizedString(@"RMS_URL", nil);
//    _rmsSiteURLTextField.clearButtonMode = UITextFieldViewModeAlways;
//    _rmsSiteURLTextField.text = [NXCommonUtils currentSkyDrm];
//    [_rmsSiteURLTextField setFont:[UIFont systemFontOfSize:14.0]];
//    [self.view addSubview:_rmsSiteURLTextField];
    
    UILabel *tenantIdLabel = [[UILabel alloc]initWithFrame:CGRectZero];
    tenantIdLabel.text = [NSString stringWithFormat:@"%@:", NSLocalizedString(@"ACCOUNTINFOTENANTID", NULL)];
    [self.view addSubview:tenantIdLabel];
    tenantIdLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    _tenantNameTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    _tenantNameTextField.translatesAutoresizingMaskIntoConstraints = NO;
    _tenantNameTextField.borderStyle = UITextBorderStyleRoundedRect;
    _tenantNameTextField.clearButtonMode = UITextFieldViewModeAlways;
    _tenantNameTextField.text = [NXCommonUtils currentTenant];
//    _tenantNameTextField.placeholder = NSLocalizedString(@"TENANT_NAME", nil);
    [_tenantNameTextField setFont:[UIFont systemFontOfSize:14.0]];
    [self.view addSubview:_tenantNameTextField];
    
    _configButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _configButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_configButton setTitle:NSLocalizedString(@"BOX_OK", nil) forState:UIControlStateNormal];
    [_configButton addTarget:self action:@selector(userDidClickOK:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_configButton];
    
    [_configButton.layer setMasksToBounds:YES];
    [_configButton.layer setCornerRadius:20];
    _configButton.backgroundColor = [UIColor colorWithRed:25.f/255.f green:184.f/255.f blue:121.f/255.f alpha:1.0f];
    

    
    _resetToDefaultButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _resetToDefaultButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_resetToDefaultButton setTitle:NSLocalizedString(@"RESET_TO_DEFAULT_RMS", nil) forState:UIControlStateNormal];
    [_resetToDefaultButton addTarget:self action:@selector(userDidClickResetToDefaultConfig:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_resetToDefaultButton];
    [_resetToDefaultButton.layer setMasksToBounds:YES];
    [_resetToDefaultButton.layer setCornerRadius:20];
    _resetToDefaultButton.backgroundColor = [UIColor redColor];

    
    NSDictionary *viewDict = @{@"tenantidLabel":tenantIdLabel, @"tenantNameTextField":_tenantNameTextField, @"configButton":_configButton, @"resetToDefaultButton":_resetToDefaultButton};
   // NSDictionary *viewMetricDict = @{@"textFieldTopMargin":@40, @"textFieldLeftRightMargin":@30, @""}
    
   
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[rmsSiteURLTextField]-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[tenantidLabel(80)][tenantNameTextField]-|" options:0 metrics:nil views:viewDict]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:tenantIdLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_tenantNameTextField attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
//    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_rmsSiteURLTextField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:40.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_tenantNameTextField attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_resetToDefaultButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_tenantNameTextField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:30]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_configButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_tenantNameTextField attribute:NSLayoutAttributeBottom multiplier:1.0 constant:30]];
    
   
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_resetToDefaultButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-20]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_resetToDefaultButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:120]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_resetToDefaultButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:40]];

    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_configButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:20]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_configButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:120]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_configButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:40]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userDidTapBackgroundView:)];
    [self.view addGestureRecognizer:tap];
}

#pragma mark - Response to User interface
-(void) userDidClickOK:(UIButton *) button
{
//    [_rmsSiteURLTextField resignFirstResponder];
    [_configButton resignFirstResponder];
    
//    if ([self.rmsSiteURLTextField.text isEqualToString:@""]) {
//        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:@"Please enter RMS URL"];
//        return;
//    }
    
    if ([self.tenantNameTextField.text isEqualToString:@""]) {
        [NXCommonUtils showAlertViewInViewController:self title:NSLocalizedString(@"ALERTVIEW_TITLE", nil) message:@"Please enter tenant name"];
        return;
    }
    
//    [NXCommonUtils updateSkyDrm:self.rmsSiteURLTextField.text];
    [NXCommonUtils updateRMSTenant:self.tenantNameTextField.text];
    
    [self.navigationController popViewControllerAnimated:YES];
}


-(void) userDidClickResetToDefaultConfig:(UIButton *) button
{
//    [_rmsSiteURLTextField resignFirstResponder];
    [_configButton resignFirstResponder];
    
    [NXCommonUtils updateSkyDrm:DEFAULT_SKYDRM];
    [NXCommonUtils updateRMSTenant:DEFAULT_TENANT];
    
//    self.rmsSiteURLTextField.text = DEFAULT_SKYDRM;
    self.tenantNameTextField.text = DEFAULT_TENANT;
}

-(void) userDidTapBackgroundView:(UITapGestureRecognizer *) tapGesture
{
//    [_rmsSiteURLTextField resignFirstResponder];
    [_configButton resignFirstResponder];
}

@end
