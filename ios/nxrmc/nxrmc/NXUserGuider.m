//
//  NXUserGuider.m
//  nxrmc
//
//  Created by EShi on 12/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXUserGuider.h"
#import "NXRMCDef.h"

#import "NXFileListViewController.h"

#define NXUSERGUIDERCODINGNAMEGUIDDICT @"NXUserGuiderCodingNameGuidDict"
typedef void(^NXUserGuiderOperationBlock)(UIViewController *);
@interface NXUserGuider()
@property(nonatomic, strong) NSMutableDictionary *guidOperationDict;
@end

@implementation NXUserGuider

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.userGuidDict forKey:NXUSERGUIDERCODINGNAMEGUIDDICT];
}
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _userGuidDict = [aDecoder decodeObjectForKey:NXUSERGUIDERCODINGNAMEGUIDDICT];
        [self initGuidOperations];
    }
    return self;
}

-(instancetype) init
{
    self = [super init];
    if (self) {
        [self initGuidOperations];
    }
    return self;
}
#pragma mark SETTER/GETTER
-(NSMutableDictionary *) userGuidDict
{
    if (_userGuidDict == nil) {
        _userGuidDict = [[NSMutableDictionary alloc] init];
    }
    return _userGuidDict;
}

-(NSMutableDictionary *) guidOperationDict
{
    if (_guidOperationDict == nil) {
        _guidOperationDict = [[NSMutableDictionary alloc] init];
    }
    return _guidOperationDict;
}

#pragma mark private method
+ (NSString *) userGuiderCachePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    return [documentDirectory stringByAppendingString:UserGuiderCachedName];
}

-(void) initGuidOperations
{
    // IPAD NXFile
    NXUserGuiderOperationBlock ipadFileListVCGuid = ^(UIViewController *vc){
        
        NSLog(@"the guid vc is %@", vc);
    };
    [self.guidOperationDict setObject:ipadFileListVCGuid forKey:NSStringFromClass([NXFileListViewController class])];
}

#pragma mark public method
- (void) saveUserGuiderStatus
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSString *storePath = [NXUserGuider userGuiderCachePath];
    [data writeToFile:storePath atomically:YES];
}

- (void) showUserGuidInViewController:(UIViewController *) vc
{
    NSString *viewControllerName = NSStringFromClass([vc class]);
    
    NSString *value = self.userGuidDict[viewControllerName];
    if (value == nil) { // value == nil, means user is first show this view
        NXUserGuiderOperationBlock optBlock = self.guidOperationDict[viewControllerName];
        optBlock(vc);
    }
}

+(instancetype) userGuiderInstance
{
    static NXUserGuider* instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSData *data = [NSData dataWithContentsOfFile:[NXUserGuider userGuiderCachePath]];
        if (data) {
            instance = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }else
        {
            instance =  [[NXUserGuider alloc] init];
        }
    });
    
    return instance;
    
}
@end
