//
//  Profile.m
//  nxrmc
//
//  Created by Kevin on 15/4/29.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXProfile.h"

#define kProfileRmserver    @"ProfileCodingRmserver"

#define kProfileUsername            @"ProfileCodingUsername"
#define kProfileUserId              @"ProfileCodingUserId"
#define kProfileTicket              @"ProfileCodingTicket"
#define kProfileTTL                 @"ProfileCodingTtl"
#define kProfileEmail               @"ProfileCodingEmail"
#define kProfileDefaultMembership   @"ProfileCodingDefaultMembership"
#define kProfileMemberships         @"ProfileCodingMemberships"


#define kMembershipId          @"MembershipsCodingId"
#define kMembershipType        @"MembershipsCodingType"
#define kMembershipTenantId    @"MembershipsCodingTenantId"


#pragma mark
@implementation NXMembership

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.ID = [aDecoder decodeObjectForKey:kMembershipId];
        self.type = [aDecoder decodeObjectForKey:kMembershipType];
        self.tenantId = [aDecoder decodeObjectForKey:kMembershipTenantId];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_ID forKey:kMembershipId];
    [aCoder encodeObject:_type forKey:kMembershipType];
    [aCoder encodeObject:_tenantId forKey:kMembershipTenantId];
}

- (BOOL)equalMembership:(NXMembership *)membership {
    if ([self.ID caseInsensitiveCompare:membership.ID] == NSOrderedSame ){
        return YES;
    } else {
        return NO;
    }
}

@end

#pragma mark
@implementation NXProfile

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.rmserver = [aDecoder decodeObjectForKey:kProfileRmserver];
        self.userName = [aDecoder decodeObjectForKey:kProfileUsername];
        self.userId = [aDecoder decodeObjectForKey:kProfileUserId];
        self.ticket = [aDecoder decodeObjectForKey:kProfileTicket];
        self.ttl = [aDecoder decodeObjectForKey:kProfileTTL];
        self.email = [aDecoder decodeObjectForKey:kProfileEmail];
        self.defaultMembership = [aDecoder decodeObjectForKey:kProfileDefaultMembership];
        self.memberships = [aDecoder decodeObjectForKey:kProfileMemberships];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_rmserver forKey:kProfileRmserver];
    [aCoder encodeObject:_userName forKey:kProfileUsername];
    [aCoder encodeObject:_userId forKey:kProfileUserId];
    [aCoder encodeObject:_ticket forKey:kProfileTicket];
    [aCoder encodeObject:_ttl forKey:kProfileTTL];
    [aCoder encodeObject:_email forKey:kProfileEmail];
    [aCoder encodeObject:_defaultMembership forKey:kProfileDefaultMembership];
    [aCoder encodeObject:_memberships forKey:kProfileMemberships];
}

- (BOOL)equalProfile:(NXProfile *)profile {
    if ([self.userId caseInsensitiveCompare:profile.userId] == NSOrderedSame) {
        return YES;
    } else {
        return NO;
    }
}

@end
