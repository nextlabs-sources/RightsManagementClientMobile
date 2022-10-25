//
//  LogIndex+CoreDataProperties.h
//  nxrmc
//
//  Created by EShi on 3/15/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NXLogIndex.h"

NS_ASSUME_NONNULL_BEGIN

@interface NXLogIndex (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *log_index;

@end

NS_ASSUME_NONNULL_END
