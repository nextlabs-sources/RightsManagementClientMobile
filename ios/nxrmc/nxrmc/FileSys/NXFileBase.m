//
//  NXFileSys.m
//  nxrmc
//
//  Created by Kevin on 15/5/7.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXFileBase.h"



#define NXFILESYSCODINGNAME                 @"NXFileSysCodingName"
#define NXFILESYSCODINGFULLPATH             @"NXFileSysCodingFullPath"
#define NXFILESYSCODINGFULLSERVICEPATH      @"NXFileSysCodingFullServicePath"
#define NXFILESYSCODINGLASTMODIFIEDTIME     @"NXFileSysCodingLastModifiedTime"
#define NXFILESYSCODINGLASTMODIFIEDDATE     @"NXFileSysCodingLastModifiedDate"
#define NXFILESYSCODINGSIZE                 @"NXFileSysCodingSize"
#define NXFILESYSCODINGREFRESHDATE          @"NXFileSysCodingRefreshDate"
#define NXFILESYSCODINGPARENT               @"NXFileSysCodingParent"
#define NXFILESYSCODINGISROOT               @"NXFileSysCodingIsRoot"
#define NXFILESYSCODINGSERVICEALIAS         @"NXFileSysCodingServiceAlias"
#define NXFILESYSCODINGSERVICEACCOUNTID     @"NXFileSysCodingServiceAccountId"
#define NXFILESYSCODINGSERVICETYPE          @"NXFileSysCodingServiceType"
#define NXFILESYSCODINGISFAVORITE           @"NXFileSysCodingIsFavorite"
#define NXFILESYSCODINGFAVORITEFILELIST     @"NXFileSysCodingFavoriteFileList"
#define NXFILESYSCODINGISOFFLINE            @"NXFileSysCodingIsOffline"
#define NXFILESYSCODINGOFFLINEFILELIST      @"NXFileSysCodingOfflineFileList"

#define NXFILESYSCODINGFAVORITEFILENODES     @"NXFileSysCodingFavoriteFileNODES"

@interface NXCustomFileList()

@property(nonatomic, strong) NSMutableArray *nodes;

@end

@implementation NXCustomFileList

- (instancetype) init
{
    if (self = [super init]) {
        _nodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) addNode:(NXFileBase *)node
{
    if (![self.nodes containsObject:node]) {
        [_nodes addObject:node];
    }
}

- (void) removeNode:(NXFileBase *)node
{
    if ([_nodes containsObject:node]) {
        [_nodes removeObject:node];
    }
}

- (NSArray *) allNodes
{
    return _nodes;
}

- (BOOL) containsObject:(NXFileBase *)node {
    return [_nodes containsObject:node];
}

- (NSInteger) count {
    return _nodes.count;
}

- (NXFileBase *) objectAtIndex:(NSInteger) index {
    return [_nodes objectAtIndex:index];
}

- (NSUInteger) IndexOfObject:(NXFileBase *) node
{
    return [_nodes indexOfObject:node];
}

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_nodes forKey:NXFILESYSCODINGFAVORITEFILENODES];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _nodes = [aDecoder decodeObjectForKey:NXFILESYSCODINGFAVORITEFILENODES];
    }
    return self;
}

@end



@implementation NXFileBase

- (id) init
{
    if (self = [super init]) {
        _isRoot = NO;
    }
    
    return self;
}

-(void) addChild:(NXFileBase *)child
{
    return;
}

- (void) removeChild:(NXFileBase*) child
{
    return;
}

-(NSArray*) getChildren
{
    return nil;
}

- (NXFileBase *) ancestor
{
    if (self.isRoot) {
        return self;
    } else {
        return [self.parent ancestor];
    }
}

- (void) setIsFavorite:(BOOL)isFavorite
{
    _isFavorite = isFavorite;
    if (isFavorite) {
        [[self ancestor].favoriteFileList addNode:self];
    } else {
        [[self ancestor].favoriteFileList removeNode:self];
    }
    return;
}

- (void) setIsOffline:(BOOL)isOffline {
    _isOffline = isOffline;
    
    if (isOffline) {
        [[self ancestor].offlineFileList addNode:self];
    } else {
        [[self ancestor].offlineFileList removeNode:self];
    }
    
    return;
}


#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_name forKey:NXFILESYSCODINGNAME];
    [aCoder encodeObject:_fullPath forKey:NXFILESYSCODINGFULLPATH];
    [aCoder encodeObject:_fullServicePath forKey:NXFILESYSCODINGFULLSERVICEPATH];
    [aCoder encodeObject:_lastModifiedTime forKey:NXFILESYSCODINGLASTMODIFIEDTIME];
    [aCoder encodeObject:_lastModifiedDate forKey:NXFILESYSCODINGLASTMODIFIEDDATE];
    [aCoder encodeObject:[NSNumber numberWithLongLong: _size ] forKey:NXFILESYSCODINGSIZE];
    [aCoder encodeObject:_refreshDate forKey:NXFILESYSCODINGREFRESHDATE];
    [aCoder encodeObject:_parent forKey:NXFILESYSCODINGPARENT];
    [aCoder encodeObject:[NSNumber numberWithBool:_isRoot] forKey:NXFILESYSCODINGISROOT];
    [aCoder encodeObject:_serviceAlias forKey:NXFILESYSCODINGSERVICEALIAS];
    [aCoder encodeObject:_serviceAccountId forKey:NXFILESYSCODINGSERVICEACCOUNTID];
    [aCoder encodeObject:[NSNumber numberWithBool:_isFavorite]forKey:NXFILESYSCODINGISFAVORITE];
    [aCoder encodeObject:_favoriteFileList forKey:NXFILESYSCODINGFAVORITEFILELIST];
    [aCoder encodeObject:[NSNumber numberWithBool:_isOffline] forKey:NXFILESYSCODINGISOFFLINE];
    [aCoder encodeObject:_offlineFileList forKey:NXFILESYSCODINGOFFLINEFILELIST];
    [aCoder encodeObject:_serviceType forKey:NXFILESYSCODINGSERVICETYPE];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _name = [aDecoder decodeObjectForKey:NXFILESYSCODINGNAME];
        _fullPath = [aDecoder decodeObjectForKey:NXFILESYSCODINGFULLPATH];
        _fullServicePath = [aDecoder decodeObjectForKey:NXFILESYSCODINGFULLSERVICEPATH];
        _lastModifiedTime = [aDecoder decodeObjectForKey:NXFILESYSCODINGLASTMODIFIEDTIME];
        _lastModifiedDate = [aDecoder decodeObjectForKey:NXFILESYSCODINGLASTMODIFIEDDATE];
        _size = [[aDecoder decodeObjectForKey:NXFILESYSCODINGSIZE] longLongValue];
        _refreshDate = [aDecoder decodeObjectForKey:NXFILESYSCODINGREFRESHDATE];
        _parent = [aDecoder decodeObjectForKey:NXFILESYSCODINGPARENT];
        _isRoot = [[aDecoder decodeObjectForKey:NXFILESYSCODINGISROOT] boolValue];
        _serviceAlias = [aDecoder decodeObjectForKey:NXFILESYSCODINGSERVICEALIAS];
        _serviceAccountId = [aDecoder decodeObjectForKey:NXFILESYSCODINGSERVICEACCOUNTID];
        _isFavorite = [[aDecoder decodeObjectForKey:NXFILESYSCODINGISFAVORITE] boolValue];
        _favoriteFileList = [aDecoder decodeObjectForKey:NXFILESYSCODINGFAVORITEFILELIST];
        _isOffline = [[aDecoder decodeObjectForKey:NXFILESYSCODINGISOFFLINE] boolValue];
        _offlineFileList = [aDecoder decodeObjectForKey:NXFILESYSCODINGOFFLINEFILELIST];
        _serviceType = [aDecoder decodeObjectForKey:NXFILESYSCODINGSERVICETYPE];
    }
    
    return self;
}

@end
