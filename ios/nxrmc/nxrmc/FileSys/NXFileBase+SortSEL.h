//
//  NXFileBase+SortSEL.h
//  nxrmc
//
//  Created by EShi on 6/18/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import "NXFileBase.h"
#import "NXFile.h"
#import "NXFolder.h"
@interface NXFileBase (SortSEL)
-(NSComparisonResult) sortContentByNameDesc:(NXFileBase*) item;
-(NSComparisonResult) sortContentByNameAsc:(NXFileBase*) item;
-(NSComparisonResult) sortContentByRepoAlians:(NXFileBase *) item;
-(NSComparisonResult) sortContentBySizeSmallest:(NXFileBase*) item;
-(NSComparisonResult) sortContentBySizeLargest:(NXFileBase*) item;
-(NSComparisonResult) sortContentByDateNewest:(NXFileBase*) item;
-(NSComparisonResult) sortContentByDateOldest:(NXFileBase*) item;
@end
