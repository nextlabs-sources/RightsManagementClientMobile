//
//  NXFileListTableViewCell.m
//  nxrmc
//
//  Created by EShi on 8/28/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXFileListTableViewCell.h"

@implementation NXFileListTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self SubImageViews];
        
    }
    return self;
}

- (void) SubImageViews {
    _leftImageView = [[UIImageView alloc] init];
    _rightImageView = [[UIImageView alloc] init];
    _leftImageView.contentMode = UIViewContentModeScaleAspectFill;
    _rightImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    _leftImageView.translatesAutoresizingMaskIntoConstraints = NO;
    _rightImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.imageView addSubview:_leftImageView];
    [self.imageView addSubview:_rightImageView];
    
    //left view
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_leftImageView
                                   attribute:NSLayoutAttributeWidth
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeWidth
                                   multiplier:0.5
                                   constant:0]];
    
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_leftImageView
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeBottom
                                   multiplier:1
                                   constant:0]];
    
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_leftImageView
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeHeight
                                   multiplier:0.5
                                   constant:0]];
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_leftImageView
                                   attribute:NSLayoutAttributeCenterX
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeLeading
                                   multiplier:1
                                   constant:0]];
    //right view.
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_rightImageView
                                   attribute:NSLayoutAttributeWidth
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeWidth
                                   multiplier:0.5
                                   constant:0]];
    
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_rightImageView
                                   attribute:NSLayoutAttributeCenterY
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeBottom
                                   multiplier:1
                                   constant:0]];
    
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_rightImageView
                                   attribute:NSLayoutAttributeHeight
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeHeight
                                   multiplier:0.5
                                   constant:0]];
    [self.imageView addConstraint:[NSLayoutConstraint
                                   constraintWithItem:_rightImageView
                                   attribute:NSLayoutAttributeCenterX
                                   relatedBy:NSLayoutRelationEqual
                                   toItem:self.imageView
                                   attribute:NSLayoutAttributeTrailing
                                   multiplier:1
                                   constant:0]];
}

@end
