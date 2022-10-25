//
//  NXMemshipAPI.h
//  nxrmc
//
//  Created by nextlabs on 6/24/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSuperRESTAPI.h"

@interface NXMemshipAPIRequestModel : NSObject

@property(nonatomic, strong) NSString *userId;
@property(nonatomic, strong) NSString *tickect;
@property(nonatomic, strong) NSString *membership;
@property(nonatomic, strong) NSString *publicKey;

- (instancetype)initWithUserId:(NSString *)userid ticket:(NSString *)ticket membership:(NSString *)membership publickey:(NSString *)publicKey;

- (NSData *)generateBodyData;

@end

@interface NXMemshipAPIResponse : NXSuperRESTAPIResponse

@property(nonatomic, strong) NSMutableDictionary *results;

@end

@interface NXMemshipAPI : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

- (instancetype)initWithRequest:(NXMemshipAPIRequestModel *)requestModel;

@end
