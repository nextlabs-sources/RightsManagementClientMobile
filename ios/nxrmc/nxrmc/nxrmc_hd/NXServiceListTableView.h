//
//  NXServiceListTableView.h
//  nxrmc
//
//  Created by EShi on 12/25/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXBoundService.h"
@class NXFileListViewController;
@class NXServiceListTableView;

@protocol NXServiceListTableViewDelegate <NSObject>

@required
- (void) serviceListTableView:(NXServiceListTableView *) serviceTableView didSelectServices:(NSArray *) services;
- (void) serviceListTableViewDidSelectAddService:(NXServiceListTableView *) serviceTableView;
- (void) serviceListTableView:(NXServiceListTableView *)serviceTableView didSelectUnAuthedService:(NXBoundService *)service;
@end

@interface NXServiceListTableView : UIView
@property(weak, nonatomic) NXFileListViewController *fileListVC;
@property(nonatomic, strong) NSMutableArray *selServiceArray;
@property(nonatomic, weak) id<NXServiceListTableViewDelegate> serviceListTableViewdelegate;
@end
