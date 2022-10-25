//
//  CheckboxCollectionViewCell.h
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CheckBoxCellModel.h"

typedef void (^ButtonClickedBlock)(BOOL);

@interface CheckboxCollectionViewCell : UICollectionViewCell

@property(nonatomic, weak) UIButton *button;

@property(nonatomic, strong) NSString *title;
@property(nonatomic) NSInteger index;
@property(nonatomic, getter = isChecked) BOOL checked;

@property(nonatomic, copy) ButtonClickedBlock buttonClickedBlock;

@end
