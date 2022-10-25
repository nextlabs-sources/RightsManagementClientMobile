//
//  NXCloudServicesViewController.h
//  nxrmc
//
//  Created by Bill on 5/7/15.
//  Copyright (c) 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NXCloudServicesViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
    NSArray *_cloudServices;
}

@end
