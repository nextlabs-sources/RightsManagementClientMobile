//
//  CheckboxCollectionViewCell.m
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import "CheckboxCollectionViewCell.h"

#define kSpace 5
#define KCheckBoxWidth 25

@implementation CheckboxCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commitInit];
        self.selected = NO;
    }
    return self;
}

- (void)commitInit {
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:button];
    self.button = button;
    
    self.button.translatesAutoresizingMaskIntoConstraints = NO;
    
    //check box position autolayout
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
    
    [self.button addTarget:self action:@selector(selectButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.button.titleLabel.font = [UIFont systemFontOfSize:17];
    
    [self.button setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
}

- (void)selectButtonClicked:(UIButton *)sender {
    self.checked = !_checked;
    if (self.buttonClickedBlock) {
        self.buttonClickedBlock(self.checked);
    }
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled {
    [super setUserInteractionEnabled:userInteractionEnabled];
    self.button.enabled = userInteractionEnabled;
    if (userInteractionEnabled) {
        [self.button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.button.tintColor = [UIColor blackColor];
    } else {
        [self.button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.button.tintColor = [UIColor lightGrayColor];
    }
}
- (void)setChecked:(BOOL)checked {
    _checked = checked;
    if (self.checked) {
        [self.button setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
    } else {
        [self.button setImage:[UIImage imageNamed:@"uncheckbox"] forState:UIControlStateNormal];
    }
}

- (void)setTitle:(NSString *)title {
    _title = title;
    [self.button setTitle:title forState:UIControlStateNormal];
}

@end
