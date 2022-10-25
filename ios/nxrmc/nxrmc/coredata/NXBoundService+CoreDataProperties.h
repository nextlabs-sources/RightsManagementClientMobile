//
//  NXBoundService+CoreDataProperties.h
//  nxrmc
//
//  Created by EShi on 7/28/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NXBoundService.h"

NS_ASSUME_NONNULL_BEGIN

@interface NXBoundService (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *service_account;
@property (nullable, nonatomic, retain) NSString *service_account_id;
@property (nullable, nonatomic, retain) NSString *service_account_token;
@property (nullable, nonatomic, retain) NSString *service_alias;
@property (nullable, nonatomic, retain) NSString *service_id;
@property (nullable, nonatomic, retain) NSNumber *service_selected;
@property (nullable, nonatomic, retain) NSNumber *service_type;
@property (nullable, nonatomic, retain) NSNumber *user_id;
@property (nullable, nonatomic, retain) NSNumber *service_isAuthed;

@end

NS_ASSUME_NONNULL_END
