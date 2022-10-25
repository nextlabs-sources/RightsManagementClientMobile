//
//  NXOperationStatusView.m
//  nxrmc
//
//  Created by nextlabs on 10/22/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXOperationStatusView.h"


@interface NXOperationStatusView()
@property (strong, nonatomic) IBOutlet UIView *downloadConvertView;
@property (strong, nonatomic) IBOutlet UIView *blockView;

@property (weak, nonatomic) IBOutlet UIView *sizSupportView;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *filesizeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;

@property (weak, nonatomic) IBOutlet UILabel *secondFileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondFileSizeLabel;

@property (strong, nonatomic) NXFileBase *file;
@end

@implementation NXOperationStatusView

- (instancetype) initWithFrame:(CGRect)frame file:(NXFileBase *)file operationStatusType:(NXOperationStatusViewType) statusType {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        [[NSBundle mainBundle] loadNibNamed:@"NXOperationStatusView" owner:self options:nil];
        self.file = file;
        switch (statusType) {
            case NXOperationStatusViewTypeBLock:
            {
                self.secondFileNameLabel.text = file.name;
                self.secondFileSizeLabel.text = @"sdfsdf";
                self.blockView.frame = frame;
                [self addSubview:self.blockView];
                [self layoutView:self.blockView];
            }
                break;
            case NXOperationStatusViewTypeConvert:
            {
                self.statusLabel.text = NSLocalizedString(@"CONVERTINGFILE", NULL);
                self.fileNameLabel.text = file.name;
                [self setProgressBarvalue:0];
                [self.activityView startAnimating];
                
                
                self.downloadConvertView.frame = frame;
                
                [self addSubview:self.downloadConvertView];
                [self layoutView:self.downloadConvertView];
            }
                break;
            case NXOperationStatusViewTypeDownload:
            {
                self.statusLabel.text = NSLocalizedString(@"DOWNLOADINGFILE", NULL);
                self.fileNameLabel.text = file.name;
                [self setProgressBarvalue:0];
                [self.activityView startAnimating];
                
                self.downloadConvertView.frame = frame;
                
                [self addSubview:self.downloadConvertView];
                [self layoutView:self.downloadConvertView];
            }
                break;
            case NXOperationStatusViewTypeLoading:
            {
                self.downloadConvertView.frame = frame;
                [self.sizSupportView removeFromSuperview];
                [self.activityView startAnimating];
                [self addSubview:self.downloadConvertView];
                [self layoutView:self.downloadConvertView];
            }
                break;
            default:
                break;
        }
        self.fileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.secondFileNameLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    
    
    return self;
}

- (void) setProgressBarvalue:(CGFloat)progress {
    self.progressBar.progress = progress;
    self.filesizeLabel.text = [self fileSizeLabelText];
}

- (void) layoutView:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeTop
                              relatedBy:NSLayoutRelationEqual
                              toItem:self
                              attribute:NSLayoutAttributeTop
                              multiplier:1
                              constant:0]];
    
    [self addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeBottom
                              relatedBy:NSLayoutRelationEqual
                              toItem:self
                              attribute:NSLayoutAttributeBottom
                              multiplier:1
                              constant:0]];
    
    [self addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeTrailing
                              relatedBy:NSLayoutRelationEqual
                              toItem:self
                              attribute:NSLayoutAttributeTrailing
                              multiplier:1
                              constant:0]];
    [self addConstraint:[NSLayoutConstraint
                              constraintWithItem:view
                              attribute:NSLayoutAttributeLeading
                              relatedBy:NSLayoutRelationEqual
                              toItem:self
                              attribute:NSLayoutAttributeLeading
                              multiplier:1
                              constant:0]];
}

- (NSString *) fileSizeLabelText {
    NSString *fileSize = [NSByteCountFormatter stringFromByteCount:self.file.size countStyle:NSByteCountFormatterCountStyleBinary];
    
    NSString *tempSize = [NSByteCountFormatter stringFromByteCount:self.file.size * self.progressBar.progress countStyle:NSByteCountFormatterCountStyleBinary];
    
    return [NSString stringWithFormat:@"%@/%@", tempSize,fileSize];
}

@end
