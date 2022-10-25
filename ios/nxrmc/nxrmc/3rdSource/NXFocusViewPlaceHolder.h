//
//  NXFocusViewPlaceHolder.h
//  nxrmc
//
//  Created by EShi on 12/16/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^PlaceHolderBlock)();
@interface NXFocusViewPlaceHolder : UIView
@property(nonatomic, weak) UIView *holderView;
@property(nonatomic, strong) PlaceHolderBlock holderBlock;
@end
