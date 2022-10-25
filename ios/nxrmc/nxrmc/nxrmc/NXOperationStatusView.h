//
//  NXOperationStatusView.h
//  nxrmc
//
//  Created by nextlabs on 10/22/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXFileBase.h"

typedef NS_ENUM(NSInteger, NXOperationStatusViewType)
{
    NXOperationStatusViewTypeDownload = 2000,
    NXOperationStatusViewTypeConvert,
    NXOperationStatusViewTypeLoading,
    NXOperationStatusViewTypeBLock,
};

@interface NXOperationStatusView : UIView

- (instancetype) initWithFrame:(CGRect)frame file:(NXFileBase *)file operationStatusType:(NXOperationStatusViewType) statusType;

- (void) setProgressBarvalue:(CGFloat) progress;

@end
