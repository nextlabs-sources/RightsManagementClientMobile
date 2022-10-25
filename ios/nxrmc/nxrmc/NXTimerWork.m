//
//  NXTimerWork.m
//  TimerWork
//
//  Created by EShi on 9/28/15.
//  Copyright © 2015 Eren. All rights reserved.
//



#import "NXTimerWork.h"

static NXTimerWork *sharedInstance = nil;

@interface NXTimerWork()
@property(nonatomic, strong) dispatch_source_t timer;
@property(nonatomic, strong) NSThread *timerThread;

@end
@implementation NXTimerWork

+(NXTimerWork *) sharedInstance
{
    @synchronized(self)
    {
        if (sharedInstance == nil) {
            sharedInstance = [[super allocWithZone:nil] init];
        }
    }
    
    return sharedInstance;
}

-(NSMutableArray *) workQueue
{
    if (_workQueue == nil) {
        _workQueue = [[NSMutableArray alloc] init];
    }
    
    return _workQueue;
}

-(void) startTimeWork
{
    @synchronized(self) {
        if (self.timer == nil) {
            dispatch_queue_t  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
            dispatch_source_set_timer(_timer, dispatch_walltime(NULL, 0), 10 * NSEC_PER_SEC, 5* NSEC_PER_SEC);
            
            dispatch_source_set_event_handler(_timer, ^{
                
                // stuff performed on background queue goes here
                
                [self timerWork:_timer];
                
                // if you need to also do any UI updates, synchronize model updates,
                // or the like, dispatch that back to the main queue:
                
                //        dispatch_async(dispatch_get_main_queue(), ^{
                //           // NSLog(@"done on main queue");
                //        });
            });
            dispatch_resume(_timer);
        }
    }
   
}

-(void) stopTimerWork
{
    @synchronized(self) {
        if (_timer) {
            dispatch_source_cancel(_timer);
            _timer = nil;
        }
      
    }
    
}

-(void)dealloc
{
    [self stopTimerWork];
}


-(void) timerWork:(dispatch_source_t ) timer
{
    @synchronized(self) {
        for (workItem work in self.workQueue) {
            work();
        }
    }
}
-(void) addWorkItem:(workItem) work
{
    @synchronized(self) {
        [self.workQueue addObject:work];
    }
}

-(void) removeWorkItem:(workItem) work
{
    @synchronized(self) {
        [self.workQueue removeObject:work];
    }
}

-(void) clearAllWorkItems
{
    @synchronized(self) {
        [self.workQueue removeAllObjects];
    }
}


@end
