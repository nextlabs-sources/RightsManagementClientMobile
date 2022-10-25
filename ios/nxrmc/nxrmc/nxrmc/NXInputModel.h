//
//  NXInputModel.h
//  AdhocTest
//
//  Created by nextlabs on 6/27/16.
//  Copyright © 2016 zhuimengfuyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXInputModel : NSObject

@property(nonatomic, strong) NSString *displayText;
@property(nonatomic, strong) NSString *context;

- (instancetype) initWithDisplayText:(NSString *)displayText context:(NSString *)context;
@end
