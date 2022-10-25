//
//  NXAutoLayoutTableViewCell.m
//  nxrmc
//
//  Created by EShi on 3/30/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXAutoLayoutTableViewCell.h"

#define kLabelHorizontalInsets      15.0f
#define kLabelVerticalInsets        10.0f
#define kLabelMargin                5.0f
#define kLabelRightInsets           45.0f
#define kCellImageSize              30.0f
@interface NXAutoLayoutTableViewCell()

@property (nonatomic) BOOL didSetupConstraints;

@end

@implementation NXAutoLayoutTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.titleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.titleLabel setNumberOfLines:1];
        [self.titleLabel setTextAlignment:NSTextAlignmentLeft];
        [self.titleLabel setTextColor:[UIColor blackColor]];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        self.bodyLabel = [[UILabel alloc] init];
        self.bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.bodyLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [self.bodyLabel setNumberOfLines:0];
        [self.bodyLabel setTextAlignment:NSTextAlignmentLeft];
        [self.bodyLabel setTextColor:[UIColor darkGrayColor]];
        self.bodyLabel.backgroundColor = [UIColor clearColor];
        
        self.cellImageView = [[UIImageView alloc] init];
        self.cellImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cellImageView.backgroundColor = [UIColor clearColor];
        
        self.cellTitleImageView = [[UIImageView alloc] init];
        self.cellTitleImageView.translatesAutoresizingMaskIntoConstraints = NO;
        self.cellTitleImageView.backgroundColor = [UIColor clearColor];
        
        self.contentView.backgroundColor = [UIColor clearColor];
        
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.bodyLabel];
        [self.contentView addSubview:self.cellImageView];
        [self.contentView addSubview:self.cellTitleImageView];
        
        [self updateFonts];
    }
    
    return self;
}

-(void) updateConstraints
{
    if (!self.didSetupConstraints) {

        [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellTitleImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:kLabelVerticalInsets]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellTitleImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kCellImageSize]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellTitleImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:kLabelHorizontalInsets]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellTitleImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kCellImageSize]];
        
        
        
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:kLabelVerticalInsets]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.cellTitleImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:kLabelHorizontalInsets]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-kLabelRightInsets]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.bodyLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.titleLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:kLabelMargin]];
        
        [self.bodyLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
      
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.bodyLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.titleLabel attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0.0]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.bodyLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-kLabelRightInsets]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.bodyLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-kLabelVerticalInsets]];
        
        
  
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.bodyLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-15.0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kCellImageSize]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:kCellImageSize]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.cellImageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-5.0]];
        
        
        self.didSetupConstraints = YES;
    }
    
    [super updateConstraints];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Make sure the contentView does a layout pass here so that its subviews have their frames set, which we
    // need to use to set the preferredMaxLayoutWidth below.
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    
    // Set the preferredMaxLayoutWidth of the mutli-line bodyLabel based on the evaluated width of the label's frame,
    // as this will allow the text to wrap correctly, and as a result allow the label to take on the correct height.
    self.bodyLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.bodyLabel.frame);
}

- (void)updateFonts
{
    self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.bodyLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
}


@end
