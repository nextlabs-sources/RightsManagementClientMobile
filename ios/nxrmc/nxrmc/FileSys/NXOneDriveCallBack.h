//
//  NXOneDriveCallBack.h
//  nxrmc
//
//  Created by EShi on 3/22/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LiveSDK/LiveConnectClient.h"
#import "NXOneDrive.h"
#import "LiveSDk/LiveDownloadOperation.h"

@interface NXOneDriveCallBack : NSObject<LiveOperationDelegate,LiveDownloadOperationDelegate,LiveUploadOperationDelegate>
+(instancetype) sharedInstance;
-(void) addOneDriveOperator:(NXOneDrive *) oneDriveOperator operationKey:(LiveOperation *) operationKey;
-(void) removeOneDriveOperator:(LiveOperation *) operationKey;

-(void) addOneDriveOperation:(LiveOperation *) operation;
@end
