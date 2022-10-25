//
//  NXCustomFileListViewController.h
//  文件属性列表测试
//
//  Created by nextlabs on 10/19/15.
//  Copyright © 2015 zhuimengfuyun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NXFile.h"
#import "NXFolder.h"

typedef NS_ENUM(NSInteger, CustomFileListType)
{
    CustomFileListTypeFavorite,
    CustomFileListTypeOffline
};


@interface NXCustomFileListViewController : UIViewController

@property CustomFileListType fileListType;
@property(nonatomic, strong) NSArray *serviceToRootFoldeArray;

- (NXFileBase *) fileNextToFile:(NXFileBase *) file;
- (NXFileBase *) filePreToFile:(NXFileBase *) file;
@end
