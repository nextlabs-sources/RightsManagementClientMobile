//
//  NXInputModel.m
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import "NXInputModel.h"

@implementation NXInputModel

- (instancetype)initWithDisplayText:(NSString *)displayText context:(NSString *)context {
    
    if (self = [super init]) {
        self.displayText = displayText;
        self.context = context;
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[NXInputModel class]]) {
        return NO;
    }
    
    NXInputModel *otherObject = (NXInputModel *)object;
    if ([otherObject.displayText isEqualToString:self.displayText] &&
        [otherObject.context isEqual:self.context]) {
        return YES;
    }
    return NO;
}

@end
