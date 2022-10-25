//
//  CheckBoxCellModel.h
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(long, MODELTYPE)
{
    MODELTYPERIGHTS = 0,
    MODELTYPEOBS,
};

@interface CheckBoxCellModel : NSObject

@property(nonatomic, strong, readonly) NSString *title;
@property(nonatomic) BOOL checked;
@property(nonatomic, readonly) MODELTYPE modelType;
@property(nonatomic, assign, readonly) long value;

- (instancetype)initWithTitle:(NSString *)title value: (long) value modelType: (MODELTYPE)type isChecked:(BOOL)isChecked;

@end
