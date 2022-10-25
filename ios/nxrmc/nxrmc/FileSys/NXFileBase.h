//
//  NXFileProtocol.h
//  nxrmc
//
//  Created by Kevin on 15/5/7.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NXFileBase;

//for favorite and offline.
@interface NXCustomFileList : NSObject<NSCoding>

- (void) addNode:(NXFileBase *)node;
- (void) removeNode:(NXFileBase *)node;
- (NSArray *) allNodes;
- (BOOL) containsObject:(NXFileBase *)node;
- (NSInteger) count;
- (NXFileBase *) objectAtIndex:(NSInteger)index;
- (NSUInteger) IndexOfObject:(NXFileBase *) node;
@end

@interface  NXFileBase: NSObject <NSCoding>

@property(nonatomic, strong) NSString* name;
@property(nonatomic, strong) NSString* fullPath;  // format: /xxxx/xxxx
@property(nonatomic, strong) NSString* fullServicePath;  // dropbox, /xxx/xxx, onedrive: abdfadf
@property(nonatomic, strong) NSString* lastModifiedTime;
@property(nonatomic) long long size;
@property(nonatomic, strong) NSDate* refreshDate;
@property(nonatomic, strong) NSDate * lastModifiedDate;
@property(nonatomic, weak) NXFileBase* parent;
@property(nonatomic,) BOOL isRoot;

//this two property to define which service this file belong, rootFolder have null value for those.
@property(nonatomic, strong) NSString *serviceAlias;
@property(nonatomic, strong) NSString *serviceAccountId;
@property(nonatomic, strong) NSNumber *serviceType;

@property(nonatomic,) BOOL isFavorite;
@property(nonatomic,) BOOL isOffline;
@property(nonatomic, strong) NXCustomFileList* favoriteFileList;  //for file directory cache, only root folder have this property.
@property(nonatomic, strong) NXCustomFileList* offlineFileList;   //only root folder

-(void) addChild: (NXFileBase*) child;
-(void) removeChild: (NXFileBase*) child;
-(NSArray*) getChildren;

- (NXFileBase *) ancestor;

- (void) setIsFavorite:(BOOL)isFavorite;

- (void) setIsOffline:(BOOL)isOffline;

@end
