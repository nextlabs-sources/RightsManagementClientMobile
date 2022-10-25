//
//  NXDownloadOperation.h
//  nxrmc
//
//  Created by nextlabs on 10/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "NXDownloadManager.h"
#import "NXFileBase.h"
#import "NXServiceOperation.h"

@interface NXDownloadOperation : NSOperation

@property (strong, nonatomic) NXFileBase *file;
@property (strong, nonatomic) id<NXServiceOperation> operation;

@property (nonatomic, copy) NXProgressBlock progressBlock;
@property (nonatomic, copy) NXCompletionBlock completitionBlock;

+ (NXDownloadOperation *) downloadOperaion:(NXFileBase *) file
                             progressBlock:(NXProgressBlock) progressBlock
                           completionBlock:(NXCompletionBlock)completionBlock;

- (void) start;
- (void) stop;
@end
