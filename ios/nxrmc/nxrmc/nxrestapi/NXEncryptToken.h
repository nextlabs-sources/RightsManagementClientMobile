//
//  NXCryptoToken.h
//  nxrmc
//
//  Created by Kevin on 16/6/16.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NXSuperRESTAPI.h"

@interface NXEncryptTokenAPIRequestModel : NSObject

@property(nonatomic, strong) NSString *userid;
@property(nonatomic, strong) NSString *ticket;
@property(nonatomic, strong) NSString *membership;
@property(nonatomic, strong) NSString *agreement;
@property(nonatomic) NSInteger count;

- (instancetype)initWithUserId:(NSString *)userid ticket:(NSString *)ticket membership:(NSString *)membership agreement:(NSString *)agreement;
- (NSData *)generateBodyData;
 
@end

@interface NXEncryptTokenAPIResponse : NXSuperRESTAPIResponse

@property(nonatomic, strong) NSDictionary *tokens;
@property(nonatomic, strong) NSString *ml;

@end

@interface NXEncryptTokenAPI : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

- (instancetype)initWithRequest:(NXEncryptTokenAPIRequestModel *)requestModel;

@end
