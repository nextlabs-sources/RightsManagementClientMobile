//
//  NXFileBase+SortSEL.m
//  nxrmc
//
//  Created by EShi on 6/18/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXFileBase+SortSEL.h"
#import "NXSharePointFile.h"
#import "NXSharePointFolder.h"

@implementation NXFileBase (SortSEL)
#pragma mark Sort curContentDataArray method

-(NSComparisonResult) sortContentByDateOldest:(NXFileBase*) item
{
    if ([item isKindOfClass:[NXFile class]]) {
        if ([self isKindOfClass:[NXFolder class]]) {
            return NSOrderedAscending;
        }
        
        if ([self isKindOfClass:[NXFile class]]) {
            NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
            [dateFormtter setDateStyle:NSDateFormatterShortStyle];
            [dateFormtter setTimeStyle:NSDateFormatterFullStyle];
            
            NSDate* selfModifyDate = [dateFormtter dateFromString:((NXFile*)self).lastModifiedTime];
            NSDate* itemModifyDate = [dateFormtter dateFromString:((NXFile*)item).lastModifiedTime];
            return [selfModifyDate compare:itemModifyDate];
        }
    }else  // item is a folder
    {
        if ([self isKindOfClass:[NXFile class]]) {
            return NSOrderedDescending;
        }
        
        if ([self isKindOfClass:[NXFolder class]]) {
            NSDateFormatter* dateFormtter = [[NSDateFormatter alloc] init];
            [dateFormtter setDateStyle:NSDateFormatterShortStyle];
            [dateFormtter setTimeStyle:NSDateFormatterFullStyle];
            
            NSDate* selfModifyDate = [dateFormtter dateFromString:((NXFolder*)self).lastModifiedTime];
            NSDate* itemModifyDate = [dateFormtter dateFromString:((NXFolder*)item).lastModifiedTime];
            return [selfModifyDate compare:itemModifyDate];
            
        }
    }
    return NSOrderedSame;
}

-(NSComparisonResult) sortContentByDateNewest:(NXFileBase*) item
{
    NSComparisonResult result = [((NXFileBase*)self).lastModifiedDate compare:((NXFileBase*)item).lastModifiedDate];
    if (result == NSOrderedAscending) {
        return NSOrderedDescending;
    }
    
    if (result == NSOrderedDescending) {
        return NSOrderedAscending;
    }
    return NSOrderedSame;
}

-(NSComparisonResult) sortContentBySizeLargest:(NXFileBase*) item
{
    if ([item isKindOfClass:[NXFile class]]) {
        if ([self isKindOfClass:[NXFolder class]]) {
            return NSOrderedAscending;
        }
        
        if ([self isKindOfClass:[NXFile class]]) {
            if (item.size < ((NXFile*)self).size) {
                return NSOrderedAscending;
            }else if(item.size > ((NXFile*)self).size)
            {
                return NSOrderedDescending;
            }else
            {
                return NSOrderedSame;
            }
        }
        
    }else  // item is a folder
    {
        if ([self isKindOfClass:[NXFile class]]) {
            return NSOrderedDescending;
        }
        
        if ([self isKindOfClass:[NXFolder class]]) {
            if (item.size < ((NXFolder*)self).size) {
                return NSOrderedAscending;
            }else if(item.size > ((NXFolder*)self).size)
            {
                return NSOrderedDescending;
            }else
            {
                return NSOrderedSame;
            }
            
        }
    }
    return NSOrderedSame;
}

-(NSComparisonResult) sortContentBySizeSmallest:(NXFileBase*) item
{
    if ([item isKindOfClass:[NXFile class]]) {
        if ([self isKindOfClass:[NXFolder class]]) {
            return NSOrderedAscending;
        }
        
        if ([self isKindOfClass:[NXFile class]]) {
            if (item.size > ((NXFile*)self).size) {
                return NSOrderedAscending;
            }else if(item.size < ((NXFile*)self).size)
            {
                return NSOrderedDescending;
            }else
            {
                return NSOrderedSame;
            }
        }
        
    }else  // item is a folder
    {
        if ([self isKindOfClass:[NXFile class]]) {
            return NSOrderedDescending;
        }
        
        if ([self isKindOfClass:[NXFolder class]]) {
            if (item.size > ((NXFolder*)self).size) {
                return NSOrderedAscending;
            }else if(item.size < ((NXFolder*)self).size)
            {
                return NSOrderedDescending;
            }else
            {
                return NSOrderedSame;
            }
            
        }
    }
    return NSOrderedSame;
}

-(NSComparisonResult) sortContentByNameAsc:(NXFileBase*) item
{
return [((NXFileBase*)self).name compare:item.name options:NSCaseInsensitiveSearch];
}

-(NSComparisonResult) sortContentByRepoAlians:(NXFileBase *) item
{
    
    if ([((NXFileBase*)self).serviceAlias compare:item.serviceAlias options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return [((NXFileBase*)self).name compare:item.name options:NSCaseInsensitiveSearch];
    }else
    {
        return [((NXFileBase*)self).serviceAlias compare:item.serviceAlias options:NSCaseInsensitiveSearch];
        
    }
}

-(NSComparisonResult) sortContentByNameDesc:(NXFileBase*) item
{
    NSComparisonResult result = [((NXFolder*)self).name compare:item.name options:NSCaseInsensitiveSearch];
    if (result == NSOrderedAscending) {
        return NSOrderedDescending;
    }
    
    if (result == NSOrderedDescending) {
        return NSOrderedAscending;
    }
    
    return result;
    

    //BOOL isSharePointFile = [self isKindOfSharePointFile:item];
//    if (isSharePointFile) {
//        NSComparisonResult compResult = [self compareItemType:item];
//        if (compResult == NSOrderedSame) {
//            compResult = [self.name compare:item.name];
//            if (compResult == NSOrderedAscending) {
//                compResult = NSOrderedDescending;
//            }else if(compResult == NSOrderedDescending)
//            {
//                compResult = NSOrderedAscending;
//            }
//        }
//        
//        return compResult;
//        
//    }else
//    {
//        if ([item isKindOfClass:[NXFile class]]) {
//            if ([self isKindOfClass:[NXFolder class]]) {
//                return NSOrderedAscending;
//            }
//            
//            if ([self isKindOfClass:[NXFile class]]) {
//                NSComparisonResult result = [((NXFile*)self).name compare:item.name];
//                if (result == NSOrderedAscending) {
//                    return NSOrderedDescending;
//                }
//                
//                if (result == NSOrderedDescending) {
//                    return NSOrderedAscending;
//                }
//            }
//            
//        }else  // item is a folder
//        {
//            if ([self isKindOfClass:[NXFile class]]) {
//                return NSOrderedDescending;
//            }
//            
//            if ([self isKindOfClass:[NXFolder class]]) {
//                NSComparisonResult result = [((NXFolder*)self).name compare:item.name];
//                if (result == NSOrderedAscending) {
//                    return NSOrderedDescending;
//                }
//                
//                if (result == NSOrderedDescending) {
//                    return NSOrderedAscending;
//                }
//                
//            }
//        }
//
//    }
//        return NSOrderedSame;
}

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

-(BOOL) isKindOfSharePointFile:(NXFileBase *) item
{
    if ([item isKindOfClass:[NXSharePointFile class]] || [item isKindOfClass:[NXSharePointFolder class]]) {
        return YES;
    }
    return NO;
}
@end
