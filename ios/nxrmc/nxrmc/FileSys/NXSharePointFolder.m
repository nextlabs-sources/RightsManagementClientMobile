//
//  NXSharePointFolder.m
//  nxrmc
//
//  Created by ShiTeng on 15/5/28.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXSharePointFolder.h"
#define NXSHAREPOINTCODINGCHIDREN              @"NXSharePointSiteCodingChildren"
#define NXSHAREPOINTCODINGFOLDERTYPE           @"NXSharePointSiteCodingFolderType"
#define NXSHAREPOINTCODINGOWNERSITE            @"NXSharePointSiteCodingOwnerSite"
@implementation NXSharePointFolder

- (id) init
{
    if (self = [super init]) {
        _children = [NSMutableArray array];
    }
    
    return self;
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

- (void)removeChild:(NXFileBase *)child
{
    if ([_children containsObject: child]) {
        [_children removeObject:child];
        [self removeAllFavoriteChildren:child];
    }
}

- (NSArray*) getChildren
{
    return _children;
}

-(void) removeAllFavoriteChildren:(NXFileBase *)file
{
    if ([file isKindOfClass:[NXSharePointFolder class]]) {
        for (NXFileBase *child in [file getChildren]) {
            [self removeAllFavoriteChildren:child];
        }
    }
    [[self ancestor].favoriteFileList removeNode:file];
    [[self ancestor].offlineFileList removeNode:file];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_children forKey:NXSHAREPOINTCODINGCHIDREN];
    [aCoder encodeObject:[NSNumber numberWithInt:_folderType] forKey:NXSHAREPOINTCODINGFOLDERTYPE];
    [aCoder encodeObject:_ownerSiteURL forKey:NXSHAREPOINTCODINGOWNERSITE];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        _children = [aDecoder decodeObjectForKey:NXSHAREPOINTCODINGCHIDREN];
        _folderType = [[aDecoder decodeObjectForKey:NXSHAREPOINTCODINGFOLDERTYPE] intValue];
        _ownerSiteURL = [aDecoder decodeObjectForKey:NXSHAREPOINTCODINGOWNERSITE];
    }
    return self;
}


@end
