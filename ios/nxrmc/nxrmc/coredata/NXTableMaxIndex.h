//
//  TableMaxIndex.h
//  nxrmc
//
//  Created by Kevin on 15/5/12.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NXTableMaxIndex : NSManagedObject

@property (nonatomic, retain) NSString * table_name;
@property (nonatomic, retain) NSNumber * max_index;

@end
