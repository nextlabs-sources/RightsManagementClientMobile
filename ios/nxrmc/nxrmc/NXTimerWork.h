//
//  NXTimerWork.h
//  TimerWork
//
//  Created by EShi on 9/28/15.
//  Copyright © 2015 Eren. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^workItem)() ;
@interface NXTimerWork : NSObject
@property(nonatomic, strong) NSMutableArray *workQueue;
+(NXTimerWork *) sharedInstance;

-(void) startTimeWork;
-(void) stopTimerWork;

-(void) addWorkItem:(workItem) work;
-(void) removeWorkItem:(workItem) work;
-(void) clearAllWorkItems;
@end
