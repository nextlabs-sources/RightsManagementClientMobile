//
//  NXDropBox.h
//  nxrmc
//
//  Created by Kevin on 15/5/11.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NXBoundService.h"

#import <DropboxSDK/DropboxSDK.h>
#import "NXServiceOperation.h"

@interface NXDropBox : NSObject <NXServiceOperation>
{
    BOOL _isLinked;
    NXFileBase *_overWriteFile;  //this used to store file which will be replace when upload file for type :NXUploadTypeOverWrite, if other type , this parameter is nil.
    NXFileBase* _curFolder;
    NSString* _userId;
}
@property(nonatomic, weak) id delegate;
@property(nonatomic, strong) NSString* alias;
@property(nonatomic, strong) NXBoundService *boundService;

- (id) initWithUserId: (NSString *)userId;
- (void) handleReplyId:(NSInteger)replyid data:(NSData *) data error:(NSError *) error;
@end
