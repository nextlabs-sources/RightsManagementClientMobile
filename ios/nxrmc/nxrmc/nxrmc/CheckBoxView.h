//
//  CheckBoxView.h
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CheckBoxCellModel.h"

@interface CheckBoxView : UIView

@property(nonatomic, strong) NSArray *dataArray;
@property(nonatomic, strong) NSArray *titlesArray;

@property(nonatomic, readonly) CGSize contentSize;

- (void)reloadData;
@end
