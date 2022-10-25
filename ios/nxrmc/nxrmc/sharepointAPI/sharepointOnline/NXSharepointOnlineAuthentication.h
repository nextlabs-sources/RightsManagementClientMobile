//
//  NXSharepointOnlineAuthentication.h
//  NXsharepointonline
//
//  Created by nextlabs on 5/28/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//


#import <Foundation/Foundation.h>

@class NXSharePointOnlineUser;
@class NXSharepointOnlineAuthentication;

@protocol NXSharepointOnlineDelegete<NSObject>

@optional - (void) Authentication:(NXSharepointOnlineAuthentication*) auth didAuthenticateSuccess:(NXSharePointOnlineUser*) user;
@optional - (void) Authentication:(NXSharepointOnlineAuthentication*) auth didAuthenticateFailWithError:(NSString*) error;

@end

@interface NXSharePointOnlineUser : NSObject

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

@property (nonatomic, retain) NSString *siteurl;
@property (nonatomic, retain) NSString *fedauthInfo;
@property (nonatomic, retain) NSString *rtfaInfo;

@end

@interface NXSharepointOnlineAuthentication : NSObject

@property (nonatomic, weak) id<NXSharepointOnlineDelegete> delegate;

- (id) initwithUsernamePasswordSite:(NSString*)username password:(NSString*)password site:(NSString*)site;
- (void) cancelLogin;
- (void) login;
@end

