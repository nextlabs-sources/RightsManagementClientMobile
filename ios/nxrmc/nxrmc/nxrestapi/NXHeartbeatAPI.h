//
//  NXHeartbeatAPI.h
//  nxrmc
//
//  Created by nextlabs on 7/15/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NXSuperRESTAPI.h"

@interface NXHeartbeatAPI : NXSuperRESTAPI<NXRESTAPIScheduleProtocol>

@end

@interface NXHeartbeatAPIResponse : NXSuperRESTAPIResponse<NSCoding>

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSNumber *transparentRatio;
@property (nonatomic, strong) NSString *fontName;
@property (nonatomic, strong) NSNumber *fontSize;
@property (nonatomic, strong) NSString *fontColor;
@property (nonatomic, strong) NSString *rotation;

@end