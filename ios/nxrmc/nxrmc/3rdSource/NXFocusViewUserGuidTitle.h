//
//  NXFocusViewUserGuidTitle.h
//  nxrmc
//
//  Created by EShi on 12/17/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum
{
    kUserGuidViewOrientUp = 1,
    kUserGuidViewOrientDown,
    kUserGuidViewOrientLeft,
    kUserGuidViewOrientRight,
    
}NXFocusUserGuidViewOrient;
@interface NXFocusViewUserGuidTitle : UIView
@property(nonatomic) NXFocusUserGuidViewOrient orientation;
@property(nonatomic, nonnull) NSString *title;
@end
