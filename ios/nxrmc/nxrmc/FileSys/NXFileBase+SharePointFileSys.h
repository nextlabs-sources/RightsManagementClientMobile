//
//  NXFileSys+SharePointFileSys.h
//  nxrmc
//
//  Created by ShiTeng on 15/6/2.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXFileBase.h"

@interface NXFileBase (SharePointFileSys)
-(NSComparisonResult) compareItemType:(NXFileBase*) item;

-(NSComparisonResult) spSortContentByNameDesc:(NXFileBase*) item;
-(NSComparisonResult) spSortContentByNameAsc:(NXFileBase*) item;
-(NSComparisonResult) spSortContentBySizeSmallest:(NXFileBase*) item;
-(NSComparisonResult) spSortContentBySizeLargest:(NXFileBase*) item;
-(NSComparisonResult) spSortContentByDateNewest:(NXFileBase*) item;
-(NSComparisonResult) spSortContentByDateOldest:(NXFileBase*) item;
@end
