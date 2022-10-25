//
//  Profile.h
//  nxrmc
//
//  Created by Kevin on 15/4/29.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NXMembership : NSObject<NSCoding>

@property(atomic, strong) NSString *ID;
@property(atomic, strong) NSNumber *type;
@property(atomic, strong) NSString *tenantId;

- (BOOL)equalMembership:(NXMembership *)membership;

@end

@interface NXProfile : NSObject <NSCoding>

@property(atomic, strong) NSString *rmserver;

@property(atomic, strong) NSString *userName;
@property(atomic, strong) NSString *userId;
@property(atomic, strong) NSString *ticket;
@property(atomic, strong) NSNumber *ttl;
@property(atomic, strong) NSString *email;

@property(atomic, strong) NXMembership *defaultMembership;
@property(atomic, strong) NSArray *memberships;

- (BOOL)equalProfile:(NXProfile *)profile;

@end
