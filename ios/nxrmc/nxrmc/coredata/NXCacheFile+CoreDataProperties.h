//
//  NXCacheFile+CoreDataProperties.h
//  nxrmc
//
//  Created by EShi on 6/21/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NXCacheFile.h"

NS_ASSUME_NONNULL_BEGIN

@interface NXCacheFile (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *access_time;
@property (nullable, nonatomic, retain) NSNumber *cache_id;
@property (nullable, nonatomic, retain) NSString *cache_path;
@property (nullable, nonatomic, retain) NSNumber *cache_size;
@property (nullable, nonatomic, retain) NSDate *cached_time;
@property (nullable, nonatomic, retain) NSNumber *favorite_flag;
@property (nullable, nonatomic, retain) NSNumber *offline_flag;
@property (nullable, nonatomic, retain) NSString *safe_path;
@property (nullable, nonatomic, retain) NSString *service_id;
@property (nullable, nonatomic, retain) NSString *source_path;
@property (nullable, nonatomic, retain) NSNumber *user_id;

@end

NS_ASSUME_NONNULL_END
