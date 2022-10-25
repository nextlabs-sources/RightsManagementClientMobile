//
//  CheckBoxCellModel.m
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import "CheckBoxCellModel.h"

@implementation CheckBoxCellModel

- (instancetype)initWithTitle:(NSString *)title value:(long)value modelType:(MODELTYPE)type isChecked:(BOOL)isChecked{
    if (self = [super init]) {
        _title = title;
        _checked = isChecked;
        
        _modelType = type;
        _value = value;
    }
    return self;
}
@end
