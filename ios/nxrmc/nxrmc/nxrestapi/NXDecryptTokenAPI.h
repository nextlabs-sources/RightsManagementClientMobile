//
//  NXDecryptTokenAPI.h
//  nxrmc
//
//  Created by nextlabs on 6/23/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXSuperRESTAPI.h"

@interface NXDecryptTokenAPIRequestModel : NSObject

@property(nonatomic, strong) NSString *userid;
@property(nonatomic, strong) NSString *ticket;
@property(nonatomic, strong) NSString *owner;
@property(nonatomic, strong) NSString *agreement;
@property(nonatomic, strong) NSString *duid;
@property(nonatomic, strong) NSString *ml;
@property(nonatomic, strong) NSString *tenant;


- (NSData *)generateBodyData;

@end

@interface NXDecryptTokenResponse : NXSuperRESTAPIResponse

@property(nonatomic, strong) NSString *token;

@end

@interface NXDecryptTokenAPI : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

- (instancetype)initWithRequest:(NXDecryptTokenAPIRequestModel *)requestModel;

@end
