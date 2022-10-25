//
//  NXRESTAPIScheduleProtocol.h
//  nxrmc
//
//  Created by EShi on 6/7/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef id(^Analysis)(NSString *returnData, NSError *error);
@protocol NXRESTAPIScheduleProtocol

@required

-(NSURLRequest *) generateRequestObject:(id) object;
- (Analysis)analysisReturnData;
@end