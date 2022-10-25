//
//  NXFolder.m
//  nxrmc
//
//  Created by Kevin on 15/5/7.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXFolder.h"


#define NXFILESYSCODINGCHIDREN              @"NXFileSysCodingChildren"

@implementation NXFolder

- (id) init
{
    if (self = [super init]) {
        _children = [NSMutableArray array];
    }
    
    return self;
}

+ (NXFileBase*) createRootFolder
{
    NXFileBase* root = [[NXFolder alloc] init];
    root.isRoot = YES;
    root.fullPath = @"/";
    root.favoriteFileList = [[NXCustomFileList alloc] init];
    root.offlineFileList = [[NXCustomFileList alloc] init];
    return root;
}

#pragma mark implementation of NXFileProtocol

- (void) addChild: (NXFileBase*) child
{
    for (NXFileBase* f in _children) {
        if ([f.fullServicePath isEqualToString:child.fullServicePath]) {
            [_children removeObject:f];
            [self removeAllFavoriteChildren:f];
            break;
        }
    }
    
    
    [_children addObject:child];
}

- (void) removeChild:(NXFileBase *)child
{
    if ([_children containsObject:child]) {
        [_children removeObject:child];
    }
    [self removeAllFavoriteChildren:child];
}

- (NSArray*) getChildren
{
    return _children;
}

-(void) removeAllFavoriteChildren:(NXFileBase *)file
{
    if ([file isKindOfClass:[NXFolder class]]) {
        for (NXFileBase *child in [file getChildren]) {
            [self removeAllFavoriteChildren:child];
        }
    }
    [[self ancestor].favoriteFileList removeNode:file];
    [[self ancestor].offlineFileList removeNode:file];
}

#pragma mark - NSCoding protocol

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_children forKey:NXFILESYSCODINGCHIDREN];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _children = [aDecoder decodeObjectForKey:NXFILESYSCODINGCHIDREN];
    }
    return self;
}

@end
