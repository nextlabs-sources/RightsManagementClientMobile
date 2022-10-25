//
//  NXGLKViewController.h
//  vdstest6
//
//  Created by nextlabs on 9/7/15.
//  Copyright (c) 2015 zhuimengfuyun. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface NXGLKViewController : GLKViewController

- (bool)loadVDSFile:(NSString *)filePath;

- (UIImage *)snapshotImage;
@end
