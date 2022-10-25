//
//  NXDownloadView.h
//  iostest123
//
//  Created by helpdesk on 20/5/15.
//  Copyright (c) 2015 test123. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NXDownloadView : UIView

- (id)initWithFrame:(CGRect)frame showDownloadView:(BOOL)show;
@property (strong, nonatomic) IBOutlet UIView *downloadBarView;
@property (weak, nonatomic) IBOutlet UILabel *fileName;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (strong, nonatomic) IBOutlet UIView *waittingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@end
