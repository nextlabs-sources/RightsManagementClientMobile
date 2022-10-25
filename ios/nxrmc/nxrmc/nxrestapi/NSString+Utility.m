//
//  NSString+Utility.m
//  xmlparser
//
//  Created by helpdesk on 3/7/15.
//  Copyright (c) 2015 test123. All rights reserved.
//

#import "NSString+Utility.h"

@implementation NSString (Utility)
- (NSString*)lowercaseFirstChar
{
    NSString *firstChar = [[self substringToIndex:1] lowercaseString];
    NSString *keypath = [NSString stringWithFormat:@"%@%@",firstChar,[self substringFromIndex:1]];
    return keypath;
}

+ (NSString *) toBOOLString:(BOOL) boolValue
{
    return (boolValue ? @"true":@"false");
}

@end
