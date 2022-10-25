//
//  NXUserGuider.h
//  nxrmc
//
//  Created by EShi on 12/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface NXUserGuider : NSObject<NSCoding>
+(instancetype) userGuiderInstance;
- (void) saveUserGuiderStatus;
- (void) showUserGuidInViewController:(UIViewController *) vc;

@property(nonatomic, strong) NSMutableDictionary *userGuidDict;
@end
