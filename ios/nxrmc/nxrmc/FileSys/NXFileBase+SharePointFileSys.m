//
//  NXFileBase+SharePointFileSys.m
//  nxrmc
//
//  Created by ShiTeng on 15/6/2.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXFileBase+SharePointFileSys.h"

#import "NXSharePointFolder.h"
#import "NXSharePointFile.h"

@implementation NXFileBase (SharePointFileSys)
-(NSComparisonResult) compareItemType:(NXFileBase*) item;
{
    
    if ([item isKindOfClass:[NXSharePointFolder class]]) {
        if ([self isKindOfClass:[NXSharePointFolder class]]) {
            NXSharePointFolder* spSelf = (NXSharePointFolder*) self;
            NXSharePointFolder* spItem = (NXSharePointFolder*) item;
            
            if (spSelf.folderType > spItem.folderType) {
                return NSOrderedAscending;
            }else if(spSelf.folderType < spItem.folderType)
            {
                return NSOrderedDescending;
            }else
            {
                return NSOrderedSame;
            }
        }else  // item is folder, self is file, just return descending
            return NSOrderedDescending;
    }
    
    if ([item isKindOfClass:[NXSharePointFile class]]) {
        if ([self isKindOfClass:[NXSharePointFolder class]]) {
            return NSOrderedAscending;
        }
    }
    
    return NSOrderedSame;
}

-(NSComparisonResult) spSortContentByNameDesc:(NXFileBase*) item
{
    NSComparisonResult compResult = [self compareItemType:item];
    if (compResult == NSOrderedSame) {
        compResult = [self.name compare:item.name];
        if (compResult == NSOrderedAscending) {
            compResult = NSOrderedDescending;
        }else if(compResult == NSOrderedDescending)
        {
            compResult = NSOrderedAscending;
        }
    }
    
    return compResult;
}
-(NSComparisonResult) spSortContentByNameAsc:(NXFileBase*) item
{
    NSComparisonResult compResult = [self compareItemType:item];
    if (compResult == NSOrderedSame) {
        compResult = [self.name compare:item.name];
    }
    
    return compResult;
}

-(NSComparisonResult) spSortContentBySizeSmallest:(NXFileBase*) item
{
    NSComparisonResult compResult = [self compareItemType:item];
    if (compResult == NSOrderedSame) {
        if (self.size > item.size) {
            compResult = NSOrderedDescending;
        }else if(self.size < item.size){
            compResult = NSOrderedAscending;
        }
    }
    
    return compResult;
}

-(NSComparisonResult) spSortContentBySizeLargest:(NXFileBase*) item
{
    NSComparisonResult compResult = [self compareItemType:item];
    if (compResult == NSOrderedSame) {
        if (self.size > item.size) {
            compResult = NSOrderedAscending;
        }else if(self.size < item.size){
            compResult = NSOrderedDescending;
        }
    }
    
    return compResult;
}

-(NSComparisonResult) spSortContentByDateNewest:(NXFileBase*) item
{
    NSComparisonResult compResult = [self compareItemType:item];
    if (compResult == NSOrderedSame) {
        NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
        [dateFormtter setDateStyle:NSDateFormatterShortStyle];
        [dateFormtter setTimeStyle:NSDateFormatterFullStyle];
        
        NSDate* selfModifyDate = [dateFormtter dateFromString:self.lastModifiedTime];
        NSDate* itemModifyDate = [dateFormtter dateFromString:item.lastModifiedTime];
        NSComparisonResult result = [selfModifyDate compare:itemModifyDate];
        if (result == NSOrderedAscending) {
            compResult = NSOrderedDescending;
        }else if(result == NSOrderedDescending){
            compResult = NSOrderedAscending;
        }
    }
    
    return compResult;
}

-(NSComparisonResult) spSortContentByDateOldest:(NXFileBase*) item
{
    NSComparisonResult compResult = [self compareItemType:item];
    if (compResult == NSOrderedSame) {
        NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
        [dateFormtter setDateStyle:NSDateFormatterShortStyle];
        [dateFormtter setTimeStyle:NSDateFormatterFullStyle];
        
        NSDate* selfModifyDate = [dateFormtter dateFromString:self.lastModifiedTime];
        NSDate* itemModifyDate = [dateFormtter dateFromString:item.lastModifiedTime];
        compResult = [selfModifyDate compare:itemModifyDate];
       
    }
    return compResult;
}

@end
