//
//  NXDropDownMenu.h
//  NXDropDownMenuExample
//
//  Created by EShi on 6/30/15.
//  Copyright (c) 2015 EShi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
@interface NXDropDownMenuItem : NSObject
@property(nonatomic, strong) UIImage* image;
@property(nonatomic, strong) NSString* title;
@property(nonatomic, weak) id target;
@property(nonatomic) SEL action;
@property(nonatomic, strong) UIColor* foreColor;
@property(nonatomic) NSTextAlignment alignment;

+ (instancetype) menuItem:(NSString *) tilte
                    image:(UIImage *) image
                   target:(id)target
                   action:(SEL) action;


- (BOOL) enabled;

- (void) performAction;
@end
@interface NXDropDownMenu : NSObject
+ (void) showMenuInView:(UIView*) view
               fromRect:(CGRect) rect
              menuItems:(NSArray*) menuItems;

+ (void) dismissMenu;

+ (UIColor *) tintColor;
+ (void) setTintColor: (UIColor*) tintColor;

+ (UIFont*) titleFont;
+ (void) setTitleFont: (UIFont *) titleFont;
@end
