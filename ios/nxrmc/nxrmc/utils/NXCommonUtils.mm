//
//  NXCommonUtils.m
//  nxrmc
//
//  Created by Kevin on 15/5/12.
//  Copyright (c) 2015年 nextlabs. All rights reserved.
//

#import "NXCommonUtils.h"

#import <CoreData/CoreData.h>
#import <string>

#ifdef APPLE_DEV_HD
#import "../nxrmc_hd/AppDelegate.h"
#else
#import "../nxrmc/AppDelegate.h"
#endif

#import "NXCacheManager.h"
#import "NXTableMaxIndex.h"
#import "NXBoundService.h"
#import "NXRMCDef.h"
#import "NXRMCCommon.h"
#import "NXKeyChain.h"
#import "NXServiceOperation.h"
#import "NXOneDrive.h"
#import "NXSharePoint.h"
#import "NXSharepointOnline.h"
#import "NXSharePointFolder.h"
#import "NXDropBox.h"
#import "NXGoogleDrive.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonCrypto.h>
#import "NSString+Codec.h"
#import "NXTokenManager.h"

#define FILETYPE_HSF            @"hoopsviewer/x-hsf"

const static CGFloat kSystemVersion = 8.0;

@implementation NXCommonUtils

+ (UIView*) createWaitingView
{
    CGRect r = [UIScreen mainScreen].applicationFrame;
    UIView* bg = [[UIView alloc] initWithFrame: r];
    [bg setTag:8808];
    
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    //  activityView.activityIndicatorViewStyle= UIActivityIndicatorViewStyleWhiteLarge;
    
    activityView.frame = CGRectMake(r.size.width /2 - 15, r.size.height /2 - 15, 30.0f, 30.0f);
    
    UIImageView* waitingbg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WaitingBk"]];
    waitingbg.frame = CGRectMake(r.size.width/2 -30, r.size.height /2 - 30, 60, 60);
    
    [bg addSubview:waitingbg];
    [bg addSubview:activityView];
    
    
    [activityView startAnimating];
    
    return bg;
    
}

+ (UIView*) createWaitingView:(CGFloat)sidelength {
    CGRect r = [UIScreen mainScreen].applicationFrame;
    CGRect frame = CGRectMake(r.size.width/2 - sidelength/2, r.size.height/2 - sidelength/2, sidelength, sidelength);
    
    UIView* bg = [[UIView alloc] initWithFrame:frame];
    [bg setTag:8808];
    
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    //  activityView.activityIndicatorViewStyle= UIActivityIndicatorViewStyleWhiteLarge;
    
    activityView.frame = CGRectMake(0, 0, sidelength, sidelength);
    
    UIImageView* waitingbg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WaitingBk"]];
    waitingbg.frame = CGRectMake(0,0, sidelength, sidelength);
    
    [activityView startAnimating];
    [bg addSubview:waitingbg];
    [bg addSubview:activityView];
    
    return bg;
}

+ (UIView*) createWaitingViewWithCancel:(id)target selector:(SEL)selector inView:(UIView*)view
{
    UIView* bg = [[UIView alloc] init];
    [bg setTag:8808];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.backgroundColor = [UIColor clearColor];
    
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView* waitingbg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WaitingBk"]];
    waitingbg.translatesAutoresizingMaskIntoConstraints = NO;
    
    //add subview
    [bg addSubview:waitingbg];
    [bg addSubview:activityView];
    [view addSubview:bg];
    
    
    // add cancel buttonr
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btn setTitle:@"Cancel" forState:UIControlStateNormal];
    [btn addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [btn setBackgroundColor:[UIColor redColor]];
    [bg addSubview:btn];
    
    //do auto layout
    [self doAutoLayoutForWaitingView:view backgroundView:bg waitingBg:waitingbg activityView:activityView];
    
    //do auto layout for cancel button
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:btn
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:100]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:btn
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:30]];
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:btn
                       attribute:NSLayoutAttributeCenterX
                       relatedBy:NSLayoutRelationEqual
                       toItem:bg
                       attribute:NSLayoutAttributeCenterX
                       multiplier:1
                       constant:0]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:btn
                       attribute:NSLayoutAttributeTop
                       relatedBy:NSLayoutRelationEqual
                       toItem:waitingbg
                       attribute:NSLayoutAttributeBottom
                       multiplier:1
                       constant:20]];
    [activityView startAnimating];
    
    return bg;
}

+(NSString *) currentRMSAddress
{
    NSString *RMSAddress = [[NSUserDefaults standardUserDefaults] objectForKey:NXRMS_ADDRESS_KEY];
    return (RMSAddress?RMSAddress:@"");
    
}
+(NSString *) currentTenant
{
    NSString *tenant = [[NSUserDefaults standardUserDefaults] objectForKey:NXRMS_TENANT_KEY];
    return (tenant?tenant:DEFAULT_TENANT);

}

+(NSString *) currentSkyDrm
{
    NSString *skyDrm = [[NSUserDefaults standardUserDefaults] objectForKey:NXRMS_SKY_DRM_KEY];
    return (skyDrm?skyDrm:DEFAULT_SKYDRM);
}

+(void) updateRMSAddress:(NSString *) rmsAddress
{
    if (rmsAddress && ![rmsAddress isEqualToString:@""] && ![rmsAddress isEqualToString:[self currentRMSAddress]]) {
        [[NXTokenManager sharedInstance] deleteEncryptTokensInkeyChain];
        
        [self cleanUpTable:TABLE_BOUNDSERVICE];
        [self cleanUpTable:TABLE_CACHEFILE];
        
        NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSError *error = nil;
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error]) {
            [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:file] error:&error];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:rmsAddress forKey:NXRMS_ADDRESS_KEY];
    }
}
+(void) updateRMSTenant:(NSString *) tenant
{
    if (tenant && ![tenant isEqualToString:@""] && ![tenant isEqualToString:[self currentTenant]]) {
         [[NXTokenManager sharedInstance] deleteEncryptTokensInkeyChain];
         [self cleanUpTable:TABLE_BOUNDSERVICE];
         [self cleanUpTable:TABLE_CACHEFILE];
        
        NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSError *error = nil;
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error]) {
            [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:file] error:&error];
        }

        [[NSUserDefaults standardUserDefaults] setObject:tenant forKey:NXRMS_TENANT_KEY];
    }
}

+(void) updateSkyDrm:(NSString *) skyDrmAddress
{
    if (skyDrmAddress && ![skyDrmAddress isEqualToString:@""] && ![skyDrmAddress isEqualToString:[self currentSkyDrm]]) {
         [[NXTokenManager sharedInstance] deleteEncryptTokensInkeyChain];
         [self cleanUpTable:TABLE_BOUNDSERVICE];
         [self cleanUpTable:TABLE_CACHEFILE];
        
        NSString *folderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSError *error = nil;
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folderPath error:&error]) {
            [[NSFileManager defaultManager] removeItemAtPath:[folderPath stringByAppendingPathComponent:file] error:&error];
        }

         [[NSUserDefaults standardUserDefaults] setObject:skyDrmAddress forKey:NXRMS_SKY_DRM_KEY];
    }
}


+ (void) removeWaitingViewInView:(UIView *) view
{
    if ([view viewWithTag:8808]) {
        [[view viewWithTag:8808] removeFromSuperview];
    }
}

+(BOOL) waitingViewExistInView:(UIView *)view
{
    if([view viewWithTag:8808])
    {
        return YES;
    }else
    {
        return NO;
    }
}

+ (UIView*) createWaitingViewInView:(UIView*)view
{
    if ([view viewWithTag:8808]) {
        return [view viewWithTag:8808];
    }
    
    UIView* bg = [[UIView alloc] init];
    [bg setTag:8808];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.backgroundColor = [UIColor clearColor];
    
    UIActivityIndicatorView* activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activityView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImageView* waitingbg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"WaitingBk"]];
    waitingbg.translatesAutoresizingMaskIntoConstraints = NO;
    
    //add subview
    [bg addSubview:waitingbg];
    [bg addSubview:activityView];
    [view addSubview:bg];
    
    //do autolay out
    [self doAutoLayoutForWaitingView:view backgroundView:bg waitingBg:waitingbg activityView:activityView];
    
    //start animating
    [activityView startAnimating];
    
    return bg;
}

//barButtonItem only for iPad, other please pass nil.
+ (void)showAlertView:(NSString *)title
              message:(NSString *)message
                style:(UIAlertControllerStyle)style
        OKActionTitle:(NSString *)okTitle
    cancelActionTitle:(NSString*)cancelTitle
       OKActionHandle:(void (^ __nullable)(UIAlertAction *action))OKActionHandler
   cancelActionHandle:(void (^ __nullable)(UIAlertAction *action))cancelActionHandler
     inViewController:(UIViewController *)controller
             position:(UIView *)sourceView;
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:style];
    if (okTitle) {
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:OKActionHandler];
        [alertController addAction:OKAction];
    }
    if (cancelTitle) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:cancelActionHandler];
        [alertController addAction:cancelAction];
    }
    if ([NXCommonUtils isiPad] && sourceView != nil) {
        alertController.popoverPresentationController.barButtonItem = nil;
        alertController.popoverPresentationController.sourceView = sourceView;
    }
    [controller presentViewController:alertController animated:YES completion:nil];
}

+ (void)doAutoLayoutForWaitingView:(UIView*)view backgroundView:(UIView*)bg waitingBg:(UIView*)waitingbg activityView:(UIView*)activityView
{
    // do autlayout
    // add activityView
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:activityView
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:30]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:activityView
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:30]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:activityView
                       attribute:NSLayoutAttributeCenterX
                       relatedBy:NSLayoutRelationEqual
                       toItem:bg
                       attribute:NSLayoutAttributeCenterX
                       multiplier:1
                       constant:0]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:activityView
                       attribute:NSLayoutAttributeCenterY
                       relatedBy:NSLayoutRelationEqual
                       toItem:bg
                       attribute:NSLayoutAttributeCenterY
                       multiplier:1
                       constant:0]];
    
    // add bg
    [view addConstraint:[NSLayoutConstraint
                         constraintWithItem:bg
                         attribute:NSLayoutAttributeTop
                         relatedBy:NSLayoutRelationEqual
                         toItem:view
                         attribute:NSLayoutAttributeTop
                         multiplier:1
                         constant:0]];
    
    [view addConstraint:[NSLayoutConstraint
                         constraintWithItem:bg
                         attribute:NSLayoutAttributeBottom
                         relatedBy:NSLayoutRelationEqual
                         toItem:view
                         attribute:NSLayoutAttributeBottom
                         multiplier:1
                         constant:0]];
    
    [view addConstraint:[NSLayoutConstraint
                         constraintWithItem:bg
                         attribute:NSLayoutAttributeTrailing
                         relatedBy:NSLayoutRelationEqual
                         toItem:view
                         attribute:NSLayoutAttributeTrailing
                         multiplier:1
                         constant:0]];
    [view addConstraint:[NSLayoutConstraint
                         constraintWithItem:bg
                         attribute:NSLayoutAttributeLeading
                         relatedBy:NSLayoutRelationEqual
                         toItem:view
                         attribute:NSLayoutAttributeLeading
                         multiplier:1
                         constant:0]];
    
    // add waitingbg
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:waitingbg
                       attribute:NSLayoutAttributeWidth
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:60]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:waitingbg
                       attribute:NSLayoutAttributeHeight
                       relatedBy:NSLayoutRelationEqual
                       toItem:nil
                       attribute:NSLayoutAttributeNotAnAttribute
                       multiplier:1
                       constant:60]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:waitingbg
                       attribute:NSLayoutAttributeCenterX
                       relatedBy:NSLayoutRelationEqual
                       toItem:bg
                       attribute:NSLayoutAttributeCenterX
                       multiplier:1
                       constant:0]];
    
    [bg addConstraint:[NSLayoutConstraint
                       constraintWithItem:waitingbg
                       attribute:NSLayoutAttributeCenterY
                       relatedBy:NSLayoutRelationEqual
                       toItem:bg
                       attribute:NSLayoutAttributeCenterY
                       multiplier:1
                       constant:0]];

}

+ (BOOL)isValidateEmail:(NSString *)email
{
    if (!email.length) {
        return NO;
    }
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES%@",emailRegex];
    
    return [emailTest evaluateWithObject:email];
}

+ (NSArray*) fetchData:(NSString *)table predicate:(NSPredicate *)pred
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSEntityDescription* entity = [NSEntityDescription entityForName:table inManagedObjectContext:app.managedObjectContext];
    
    NSFetchRequest* fetchReq = [[NSFetchRequest alloc] init];
    [fetchReq setPredicate:pred];
    [fetchReq setEntity:entity];
    
    NSError* error = nil;
    NSArray* fetchObjects = [app.managedObjectContext executeFetchRequest:fetchReq error:&error];
    
    return fetchObjects;
}

+ (int) getIndex:(NSString *)table
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"TableMaxIndex" inManagedObjectContext:app.managedObjectContext];
    
    NSFetchRequest* fetchReq = [[NSFetchRequest alloc] init];
    [fetchReq setPredicate:[NSPredicate predicateWithFormat:@"table_name=%@", table]];
    [fetchReq setEntity:entity];
    
    NSError* error = nil;
    NSArray* fetchObjects = [app.managedObjectContext executeFetchRequest:fetchReq error:&error];
    
    int index = 0;
    if (fetchObjects.count > 0) {
        NXTableMaxIndex* rd = (NXTableMaxIndex*)[fetchObjects lastObject];
        index = rd.max_index.intValue;
    }
    
    return index;
}

+ (void) updateIndex: (NSString*) table
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"TableMaxIndex" inManagedObjectContext:app.managedObjectContext];
    
    NSFetchRequest* fetchReq = [[NSFetchRequest alloc] init];
    [fetchReq setPredicate:[NSPredicate predicateWithFormat:@"table_name=%@", table]];
    [fetchReq setEntity:entity];
    
    NSError* error = nil;
    NSArray* fetchObjects = [app.managedObjectContext executeFetchRequest:fetchReq error:&error];
    
    if (fetchObjects.count > 0) {
        NXTableMaxIndex* rd = (NXTableMaxIndex*)[fetchObjects lastObject];
        int index = rd.max_index.intValue;
        rd.max_index = [NSNumber numberWithInt:index + 1];
        [app.managedObjectContext save:nil];
    }
    else
    {
        NXTableMaxIndex* newRd = [NSEntityDescription insertNewObjectForEntityForName:@"TableMaxIndex" inManagedObjectContext:app.managedObjectContext];
        newRd.table_name = table;
        newRd.max_index = [NSNumber numberWithInt:1];
        [app.managedObjectContext save:nil];
    }
}

+ (NSString *) serviceAliasByServiceType:(ServiceType) serviceType ServiceAccountId:(NSString *)accountId
{
    for (NXBoundService *boundService in [NXLoginUser sharedInstance].boundServices) {
        if ([boundService.service_account_id isEqualToString:accountId] && boundService.service_type.integerValue == serviceType) {
            return boundService.service_alias;
        }
    }
    return @"NOT SET ALIAS";
}

+(NXBoundService *) boudServiceByServiceType:(ServiceType) serviceType ServiceAccountId:(NSString *) accountId
{
    for (NXBoundService *boundService in [NXLoginUser sharedInstance].boundServices) {
        if ([boundService.service_id isEqualToString:accountId] && boundService.service_type.integerValue == serviceType) {
            return boundService;
        }
    }
    return nil;

}


+ (NXBoundService*) getBoundServiceFromCoreData:(NSString *) serviceId {
    NXBoundService *boundService;
    NSArray *services = [NXLoginUser sharedInstance].boundServices;
    for (NXBoundService*s in services) {
        if ([s.service_account_id isEqualToString:serviceId]) {
            boundService = s;
            break;
        }
    }
    return boundService;
}

+ (NXBoundService *) storeServiceIntoCoreData:(NXRMCRepoItem *) serviceObj
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NXBoundService *service = nil;
    NSArray* objects = [self fetchData:TABLE_BOUNDSERVICE predicate:[NSPredicate predicateWithFormat:@"user_id=%@ AND service_type=%d AND service_account_id=%@", [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId], serviceObj.service_type.integerValue, serviceObj.service_account_id]];
    if (objects.count > 0) {
        service = (NXBoundService *)[objects lastObject];
        service.service_id = serviceObj.service_id;
        service.service_account = serviceObj.service_account;
        service.service_account_token = serviceObj.service_account_token;
        service.service_selected = [NSNumber numberWithBool:YES]; // default service is selected when add service
        service.service_alias = serviceObj.service_alias;
        service.service_isAuthed = [NSNumber numberWithBool:serviceObj.service_isAuthed];
        [app.managedObjectContext save:nil];
    }
    else
    {
        service = (NXBoundService *)[NSEntityDescription insertNewObjectForEntityForName:TABLE_BOUNDSERVICE inManagedObjectContext:app.managedObjectContext];
        if (serviceObj.service_id) {
            
            service.service_id = serviceObj.service_id;
        }else
        {
            service.service_id = RMC_DEFAULT_SERVICE_ID_UNSET;
        }
         
        service.user_id = [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId];
        service.service_type = serviceObj.service_type;
        service.service_account = serviceObj.service_account;
        service.service_account_id = serviceObj.service_account_id;
        service.service_account_token = serviceObj.service_account_token;
        service.service_alias = serviceObj.service_alias;
        service.service_selected = [NSNumber numberWithBool:YES]; // default service is selected when add service
        service.service_isAuthed = [NSNumber numberWithBool:serviceObj.service_isAuthed];
        
        [app.managedObjectContext save:nil];
    }
    
    return service;

}


+ (BOOL)updateService:(ServiceType) type serviceAccount:(NSString *)sa serviceAccountId:(NSString *)sai serviceAccountToken:(NSString *)sat isAuthed:(BOOL) isAuthed
{
    NSArray* objects = [self fetchData:TABLE_BOUNDSERVICE predicate:[NSPredicate predicateWithFormat:@"user_id=%@ AND service_type=%d AND service_account_id=%@", [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId], type, sai]];
    
    NXBoundService *service = [objects lastObject];
    if(service != nil)
    {
        service.user_id = [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId];
        
        service.service_account = sa;
        service.service_account_id = sai;
        service.service_account_token = sat;
        service.service_isAuthed = [NSNumber numberWithBool:isAuthed];
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.managedObjectContext save:nil];
        return YES;
    }
    return NO;

}
+(void) updateBoundServiceInCoreData:(NXBoundService *) boundService
{
    NSArray* objects = [self fetchData:TABLE_BOUNDSERVICE predicate:[NSPredicate predicateWithFormat:@"user_id=%@ AND service_type=%d AND service_account_id=%@", [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId], boundService.service_type.intValue, boundService.service_account_id]];
    NXBoundService *service = [objects lastObject];
    if(service != nil)
    {
        service.user_id = boundService.user_id;
        service.service_type = boundService.service_type;
        service.service_account = boundService.service_account;
        service.service_account_id = boundService.service_account_id;
        service.service_account_token = boundService.service_account_token;
        service.service_alias = boundService.service_alias;
        service.service_selected = boundService.service_selected;
        service.service_id = boundService.service_id;
        service.service_isAuthed = boundService.service_isAuthed;
        
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.managedObjectContext save:nil];
    }
}


+ (BOOL) deleteServiceFromCoreData:(NXBoundService *)boundService
{
    NSPredicate *predicate = nil;
    if (boundService.service_type.integerValue == kServiceOneDrive) {
        // NOTE WE ONLY SUPPORT ONE ACCOUNT FOR ONE DRIVE, SO DO NOT NEED TAKE userID into consider
        predicate = [NSPredicate predicateWithFormat:@"service_type=%d AND service_account_id=%@ AND service_id=%@", boundService.service_type.intValue, boundService.service_account_id, boundService.service_id];
    }else
    {
        predicate = [NSPredicate predicateWithFormat:@"user_id=%@ AND service_type=%d AND service_account_id=%@ AND service_id=%@", [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId], boundService.service_type.intValue, boundService.service_account_id, boundService.service_id];
    }
    NSArray* objects = [self fetchData:TABLE_BOUNDSERVICE predicate:predicate];
    
    NXBoundService *service = [objects lastObject];
    
    if (service) {
        AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
        [app.managedObjectContext deleteObject:service];
        [app.managedObjectContext save:nil];
        return YES;
    }else
    {
        return NO;
    }
}

+ (BOOL) cleanUpTable:(NSString *) tableName
{
     AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    NSFetchRequest *allItmesRequest = [[NSFetchRequest alloc] init];
    [allItmesRequest setEntity:[NSEntityDescription entityForName:tableName inManagedObjectContext:app.managedObjectContext]];
    [allItmesRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *allItems = [app.managedObjectContext executeFetchRequest:allItmesRequest error:&error];
   
    //error handling goes here
    for (NSManagedObject *item in allItems) {
        [app.managedObjectContext deleteObject:item];
    }
    NSError *saveError = nil;
    return [app.managedObjectContext save:&saveError];
}

+ (void) deleteCacheFileFromCoreData:(NXCacheFile *)cacheFile
{
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [app.managedObjectContext deleteObject:cacheFile];
    [app.managedObjectContext save:nil];
}

+ (void) deleteCacheFilesFromCoreDataForService:(NXBoundService *)service
{
    NSArray* objects = [ self fetchData:TABLE_CACHEFILE predicate:[NSPredicate predicateWithFormat:@"user_id=%@ AND service_id=%@", service.user_id, NXREST_UUID(service)]];
    
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    for (NXCacheFile* file in objects) {
        if (![file.offline_flag boolValue]) {
            [app.managedObjectContext deleteObject:file];
        }
    }
    [app.managedObjectContext save:nil];
}

+ (void) deleteAllCacheFilesFromCoreData {
    NSMutableArray *boundServices = [NXLoginUser sharedInstance].boundServices;
    for (NXBoundService *service in boundServices) {
        [self deleteCacheFilesFromCoreDataForService:service];
    }
}

+ (void) deleteCachedFilesOnDisk
{
    //only delete cached files in ../Library/Cachees/rms_sid
    NSURL* cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSString* uid = [NSString stringWithFormat:@"%@%@", CACHERMS, [NXLoginUser sharedInstance].profile.userId];
    NSString *cachePath = [cacheUrl URLByAppendingPathComponent:uid].path;
    [self deleteFilesAtPath:cachePath];
    
//    //delete cache file in Application_Home/tmp
//    NSURL *tmpPath = [NSURL URLWithString:NSTemporaryDirectory()];
//    [self removeAllFilesAtPath:tmpPath.path];
    
    // delele db  in db.
    [self deleteAllCacheFilesFromCoreData];
}

+ (void) deleteFilesAtPath:(NSString *) directory
{
    NSFileManager *fileManager=[NSFileManager defaultManager];
    BOOL ret = [fileManager removeItemAtPath:directory error:nil];
    if (!ret) {
        NSLog(@"delete %@ failed", directory);
    }
}

+ (NSNumber *) calculateCachedFileSize {
    //only caculate dirctory ../Library/Cachees/rms_sid
    NSURL *cacheUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *uid = [NSString stringWithFormat:@"%@%@", CACHERMS, [NXLoginUser sharedInstance].profile.userId];
    NSString *cachePath = [cacheUrl URLByAppendingPathComponent:uid].path;
    NSNumber *cacheSize = [self calculateCachedFileSizeAtPath:cachePath];
    
      //cached files in Application_Home/tmp
//    NSURL *tmpPath = [NSURL URLWithString:NSTemporaryDirectory()];
//    cacheSize = @([cacheSize unsignedLongLongValue] + [self calculateCacheSizeAtPath:tmpPath.path].unsignedLongLongValue);
    
    return cacheSize;
}

+ (NSNumber *) calculateCachedFileSizeAtPath:(NSString *)folderPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSNumber *folderSize = [NSNumber numberWithUnsignedLongLong:0];
    
    NSArray* array = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    for(int i = 0; i < array.count; i++)
    {
        NSString *fullPath = [folderPath stringByAppendingPathComponent:[array objectAtIndex:i]];
        
        BOOL isDir;
        if ( !([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && isDir) )
        {
            NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:fullPath error:nil];
            folderSize = [NSNumber numberWithUnsignedLongLong:[folderSize unsignedLongLongValue] + fileAttributeDic.fileSize];
        }
        else
        {
            folderSize = [NSNumber numberWithUnsignedLongLong:[folderSize unsignedLongLongValue] + [[self calculateCachedFileSizeAtPath:fullPath] unsignedLongLongValue]];
        }
    }
    return folderSize;
}

//+ (NXCacheFile*) storeCacheFileIntoCoreData: (NXBoundService*) service sourcePath:(NSString*)sPath cachePath: (NSString*) cPath
//{
//    NSArray* objects = [self fetchData:TABLE_CACHEFILE predicate:[NSPredicate predicateWithFormat:@"user_id = %@ AND service_id = %@ AND cache_path= %@", [NXLoginUser sharedInstance].userProfile.user_id, service.service_id, cPath]];
//    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
//    
//    NSURL* url = [NSURL fileURLWithPath:cPath];
//    NSNumber* fileSize = nil;
//    NSError* err = nil;
//    [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&err];
//    
//    NSLog(@"file size of %@, size: %@", url, fileSize);
//    
//    NXCacheFile* file = nil;
//    if (objects.count > 0 ) {
//        file = [objects lastObject];
//        file.cached_time = [NSDate date];
//        file.access_time = [NSDate date];
//        
//        file.cache_size = fileSize;
//        
//        [app.managedObjectContext save:nil];
//    }
//    else
//    {
//        
//        file = [NSEntityDescription insertNewObjectForEntityForName:TABLE_CACHEFILE inManagedObjectContext:app.managedObjectContext];
//        file.cache_id = [NSNumber numberWithInt:[self getIndex:TABLE_CACHEFILE]];
//        file.user_id = [NXLoginUser sharedInstance].userProfile.user_id;
//        file.service_id = service.service_id;
//        file.source_path = sPath;
//        file.cache_path = cPath;
//        file.cached_time = [NSDate date];
//        file.access_time = [NSDate date];
//        file.cache_size = fileSize;
//        file.offline_flag = [NSNumber numberWithInteger:0];
//        file.favorite_flag = [NSNumber numberWithInteger:0];
//        file.safe_path = @"";
//        
//        [self updateIndex:TABLE_CACHEFILE];
//        
//        [app.managedObjectContext save:nil];
//    }
//    
//    return file;
//    
//}

+ (NXCacheFile*) storeCacheFileIntoCoreData: (NXFileBase *)fileBase cachePath :(NSString*) cPath;
{
    NXBoundService *service = [NXCommonUtils getBoundServiceFromCoreData:fileBase.serviceAccountId];
    
    NSArray* objects = [self fetchData:TABLE_CACHEFILE predicate:[NSPredicate predicateWithFormat:@"user_id = %@ AND service_id = %@ AND cache_path= %@", [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId], NXREST_UUID(service), cPath]];
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    NSURL* url = [NSURL fileURLWithPath:cPath];
    NSNumber* fileSize = nil;
    NSError* err = nil;
    [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:&err];
    
    NSLog(@"file size of %@, size: %@", url, fileSize);
    
    NXCacheFile* file = nil;
    if (objects.count > 0 ) {
        file = [objects lastObject];
        file.cached_time = [NSDate date];
        file.access_time = [NSDate date];
        
        file.cache_size = fileSize;
        
        file.offline_flag = [NSNumber numberWithBool:fileBase.isOffline];
        file.favorite_flag = [NSNumber numberWithBool:fileBase.isFavorite];
        file.cache_path = cPath;
        
        [app.managedObjectContext save:nil];
    }
    else
    {
        
        file = [NSEntityDescription insertNewObjectForEntityForName:TABLE_CACHEFILE inManagedObjectContext:app.managedObjectContext];
        file.cache_id = [NSNumber numberWithInt:[self getIndex:TABLE_CACHEFILE]];
        file.user_id = [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId];
        file.service_id = NXREST_UUID(service);
        file.source_path = fileBase.fullServicePath;
        file.cache_path = cPath;
        file.cached_time = [NSDate date];
        file.access_time = [NSDate date];
        file.cache_size = fileSize;
        file.offline_flag = [NSNumber numberWithBool:fileBase.isOffline];
        file.favorite_flag = [NSNumber numberWithBool:fileBase.isFavorite];
        file.safe_path = @"";
        
        [self updateIndex:TABLE_CACHEFILE];
        
        [app.managedObjectContext save:nil];
    }
    //when file is offline flag change, when should move file from folder to anther folder.
    [NXCacheManager cacheFile:fileBase localPath:cPath];
    return file;
    
}

+ (NXCacheFile*) getCacheFile: (NXFileBase *) file
{
    NXBoundService *service = [NXCommonUtils getBoundServiceFromCoreData:file.serviceAccountId];
    NSArray* objects = [ self fetchData:TABLE_CACHEFILE predicate:[NSPredicate predicateWithFormat:@"user_id=%@ AND service_id=%@ AND source_path=%@", [NXCommonUtils converttoNumber:[NXLoginUser sharedInstance].profile.userId], NXREST_UUID(service), file.fullServicePath]];
    
    if (objects.count > 0) {
        NXCacheFile* cache = [objects lastObject];
        NSLog(@"get cache record from database, %@, cached time: %@", cache.cache_path, cache.cached_time);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:cache.cache_path]) {
            // cache file doesn't exist, maybe deleted by ios. then need to delete record in cache table.
            [self deleteCacheFileFromCoreData:cache];
            NSLog(@"cache file was deleted, need to erase db, and caller has to download file again");
            return nil;
        }
        else
        {
            NSLog(@"has cache file, can used directly");
            return cache;
        }
    }
    return nil;
}

//+ (NXCacheFile*) getCacheFile: (NXBoundService*) service servicePath: (NSString*)servicePath
//{
//   NSArray* objects = [ self fetchData:TABLE_CACHEFILE predicate:[NSPredicate predicateWithFormat:@"user_id=%@ AND service_id=%@ AND source_path=%@", [NXLoginUser sharedInstance].userProfile.user_id, service.service_id, servicePath]];
//    
//    if (objects.count > 0) {
//        NXCacheFile* cache = [objects lastObject];
//        NSLog(@"get cache record from database, %@, cached time: %@", cache.cache_path, cache.cached_time);
//        
//        if (![[NSFileManager defaultManager] fileExistsAtPath:cache.cache_path]) {
//            // cache file doesn't exist, maybe deleted by ios. then need to delete record in cache table.
//            [self deleteCacheFileFromCoreData:cache];
//            NSLog(@"cache file was deleted, need to erase db, and caller has to download file again");
//            return nil;
//        }
//        else
//        {
//            NSLog(@"has cache file, can used directly");
//            return cache;
//        }
//    }
//    
//    return nil;
//}

+ (NSArray*) getStoredProfiles
{
    NSMutableDictionary* dict = [NXKeyChain load:KEYCHAIN_PROFILES_SERVICE];  // get info from key chain
    NSData* data = [dict objectForKey:KEYCHAIN_PROFILES];  // get stored value, this is binary data of all profiles
    NSArray* profiles = [NSKeyedUnarchiver unarchiveObjectWithData:data];  // unarchive
    
    NSMutableArray* ary = [NSMutableArray array];
    for (NXProfile* profile in profiles) {
//        NSLog(@"uname: %@, domain: %@, sid: %@, rmserver: %@", profile.userName, profile.domain, profile.sid, profile.rmserver);
        
        [ary addObject:profile];
    }
    
    return ary;
    
}

+ (void) storeProfile:(NXProfile *)profile
{
    if (!profile) {
        return;
    }
    
    NSArray* profiles = [NXCommonUtils getStoredProfiles];  // get existing profiles
    NSMutableArray* newProfiles = [NSMutableArray arrayWithArray:profiles];
    for (NXProfile* p in newProfiles) {
        if ([p equalProfile:profile]) {
            [newProfiles removeObject:p];
            break;
        }
    }
    
    [newProfiles insertObject:profile atIndex:0];  // add new profile
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:newProfiles];  // archive all profiles
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:data forKey:KEYCHAIN_PROFILES];
    
    [NXKeyChain save:KEYCHAIN_PROFILES_SERVICE data:dict];
}

+ (void) deleteProfile:(NXProfile*)profile {
    if (!profile) {
        return;
    }
    NSArray* profiles = [NXCommonUtils getStoredProfiles];
    NSMutableArray* newProfiles = [NSMutableArray arrayWithArray:profiles];
    
    for (NXProfile*p in newProfiles) {
        if ([p equalProfile:profile]) {
            [newProfiles removeObject:p];
            break;
        }
    }
    
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:newProfiles];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:data forKey:KEYCHAIN_PROFILES];
    
    [NXKeyChain save:KEYCHAIN_PROFILES_SERVICE data:dict];
}


+ (id<NXServiceOperation>) createServiceOperation:(NXBoundService *)service
{
    id<NXServiceOperation> so = nil;
    if (service.service_account_id) {  // add check service.service_account_id for the service may deleted, if is deleted, service.service_type = nil, [nil intvalue] = 0
        switch ([service.service_type intValue]) {
            case kServiceDropbox:
                so = [[NXDropBox alloc] initWithUserId:service.service_account_id];
                break;
            case kServiceOneDrive:
                so = [[NXOneDrive alloc]initWithUserId:service.service_account_id];
                break;
            case kServiceSharepoint:
                so = [[NXSharePoint alloc] initWithUserId:service.service_account_id];
                break;
            case kServiceSharepointOnline:
                so = [[NXSharepointOnline alloc] initWithUserId:service.service_account_id];
                break;
            case kServiceGoogleDrive:
                so = [[NXGoogleDrive alloc] initWithUserId:service.service_account_id];
                break;
            default:
                break;
        }
        [so setAlias:service.service_alias];
        [so setBoundService:service];

    }
    return so;
}


+ (NXFileBase*) storeThirdPartyFileAndGetNXFile:(NSURL*)fileURL
{

    // TBD!!!!!!!!!!!!!!!
    
    
    return nil;
}



+ (NSString*) getMiMeType:(NSString*)filepath
{
    if (filepath == nil) {
        return nil;
    }
    
    NSString *fileExtension = [NXCommonUtils getExtension:filepath error:nil];
    if (fileExtension == nil) {
        return nil;
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    NSString *mimeTypeStr = (__bridge_transfer NSString *)mimeType;
    if (mimeTypeStr == nil) {
        if([fileExtension compare:@"java" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return @"text/x-java-source";
        }
        NSString *extentensionText = @"cpp, c, h";
        NSRange foundOjb = [extentensionText rangeOfString:fileExtension options:NSCaseInsensitiveSearch];
        if (foundOjb.length > 0) {
            return @"text/plain";
        }
        return @"application/octet-stream";
    }
    return mimeTypeStr;
}

+ (NSString*) getUTIForFile :(NSString*) filepath
{
    if (filepath == nil) {
        return  nil;
    }
    NSString *extension = [self getExtension:filepath error:nil];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    return (__bridge_transfer NSString *)UTI;
}

+ (NSString *)getExtension:(NSString *)fullpath error:(NSError **)error;
{
    if (fullpath == nil) {
        if (error) {
            *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN  code:NXRMC_ERROR_CODE_NOSUCHFILE userInfo:nil];
        }
        return  nil;
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:fullpath]) {
        if (error) {
            *error = [NSError errorWithDomain:NX_ERROR_NXLFILE_DOMAIN  code:NXRMC_ERROR_CODE_NOSUCHFILE userInfo:nil];
        }
        return nil;
    }
    if ([NXMetaData isNxlFile:fullpath]) {
        __block NSString *fileType = @"";
        __block NSError *tempError = nil;
        dispatch_semaphore_t semi = dispatch_semaphore_create(0);
        [NXMetaData getFileType:fullpath complete:^(NSString *type, NSError *error) {
            fileType = type;
            tempError = error;
            dispatch_semaphore_signal(semi);
        }];
        dispatch_semaphore_wait(semi, DISPATCH_TIME_FOREVER);
        if (tempError && error) {
            *error = [NSError errorWithDomain:tempError.domain code:tempError.code userInfo:tempError.userInfo];
        }
        return fileType;
    } else {
        return [[fullpath pathExtension] lowercaseString];
    }
}

+(NSString *) convertToCCTimeFormat:(NSDate *) date
{
    if (date) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.sssZZ"];
        NSMutableString *timestamp = [NSMutableString stringWithString:[dateFormatter stringFromDate:date]];
        [timestamp insertString:@":" atIndex:(timestamp.length - 2)];
        return timestamp;
    }
    return nil;
}

+ (NSString *) convertRepoTypeToDisplayName:(NSNumber *) repoType
{
    if (repoType) {
        NSDictionary *dic = @{[NSNumber numberWithInteger:kServiceDropbox]:@"DropBox",
                              [NSNumber numberWithInteger:kServiceSharepointOnline]:@"SharePointOnline",
                              [NSNumber numberWithInteger:kServiceSharepoint]:@"SharePoint",
                              [NSNumber numberWithInteger:kServiceOneDrive]:@"OneDrive",
                              [NSNumber numberWithInteger:kServiceGoogleDrive]:@"GoogleDrive"};
        return dic[repoType];
    }
    return @"";
}

// operation for folder.children,
// remove objects which newFileList does not have
// add objects which newFilelist have, folder,children does not have
// update objects's base infomation which both of them have.

+ (NSArray *) updateFolderChildren:(NXFileBase *) folder newChildren:(NSArray *)newFileList
{
    NSMutableArray *newList = [[NSMutableArray alloc] initWithArray:newFileList];

    NSMutableArray *tempDeleteChildren = [[NSMutableArray alloc] init];
    for (NXFileBase *child in [folder getChildren]) {
        BOOL isfind = NO;
        NXFileBase *tempFile;
        for (NXFileBase *file in newList) {
            if ([child.fullServicePath isEqualToString:file.fullServicePath]) {
                isfind = YES;
                
                tempFile = file;
                //update file's basic information.
                child.lastModifiedTime =  file.lastModifiedTime;
                child.lastModifiedDate = file.lastModifiedDate;
                child.size = file.size;
                child.refreshDate = file.refreshDate;
                child.isRoot = file.isRoot;
                child.name = file.name;
                child.serviceAlias = file.serviceAlias;
                continue;
            }
        }
        if (!isfind) {
            [tempDeleteChildren addObject:child];
        } else {
            [newList removeObject:tempFile];
        }
    }
    for (NXFileBase *file in tempDeleteChildren) {
        [folder removeChild:file];
    }
    
    for (NXFileBase *newchild in newList) {
        [folder addChild:newchild];
    }
    
    return [folder getChildren];
}

// need to add more file type
+ (BOOL) is3DFileWithMimeType:(NSString*)mimeType
{
    if(mimeType == nil)
    {
        return NO;
    }
    if([mimeType isEqualToString:FILETYPE_HSF] )
    {
        return YES;
    }
    return NO;
}

//
+ (BOOL) is3DFileFormat:(NSString*)extension
{
    if(extension == nil) {
        return NO;
    }
    
    if ([extension compare:FILEEXTENSION_HSF options:NSCaseInsensitiveSearch] == NSOrderedSame ||
        [extension compare:FILEEXTENSION_VDS options:NSCaseInsensitiveSearch] == NSOrderedSame ||
        [extension compare:FILEEXTENSION_RH options:NSCaseInsensitiveSearch] == NSOrderedSame )
    {
        return YES;
    }
    if ([self is3DFileNeedConvertFormat:extension]) {
        return YES;
    }
    return NO;
}
// according to the file type or other file information,judge this 3D format if need convert by service
+ (BOOL) is3DFileNeedConvertFormat:(NSString*)extension
{
    if(extension == nil)
    {
        return NO;
    }
    NSArray *supportedCadformats = @[@".jt", @".prt", @".sldprt", @".sldasm",@".catpart", @".catshape", @".cgr",@".neu",
                                     @".par", @".psm",@".x_b", @".x_t", @".xmt_txt",@".pdf", @".ipt", @".igs",
                                     @".stp", @".stl", @".step",@".3dxml", @".dxf", @".iges", @".vsd"];
    
    for (NSString *format in supportedCadformats) {
        if ([format compare:[NSString stringWithFormat:@".%@", extension] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
            return YES;
        }
    }
    return NO;
}

// judge our app if suppport this format,now just accorind to the mimetype,in futere can change the implemetion
+ (BOOL)isTheSupportedFormat:(NSString*)extension
{
    if(extension == nil) {
        NO;
    }
    
    NSString *supportFileTypes = FILESUPPORTOPEN;
    NSRange foundOjb = [supportFileTypes rangeOfString:[NSString stringWithFormat:@".%@.",extension] options:NSCaseInsensitiveSearch];
    if (foundOjb.length > 0) {
        return YES;
    }
    if ([self is3DFileNeedConvertFormat:extension]) {
        return YES;
    }
    return NO;
}

+ (float) iosVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];;
}

+ (BOOL) isiPad
{
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

+ (NSString *) deviceID
{
    NSString *deviceID = (NSString *)[NXKeyChain load:KEYCHAIN_DEVICE_ID];
    if (deviceID == nil) {
        deviceID = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        [NXKeyChain save:KEYCHAIN_DEVICE_ID data:deviceID];
    }
   
    return deviceID;
}

+ (NSNumber*) getPlatformId
{
    long idStart = 0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        idStart = 600;
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        idStart = 700;
    }
    else
    {
        idStart = 600;
    }
    
    long plus = 0;
    NSString* v = [UIDevice currentDevice].systemVersion;
    if ([v hasPrefix:@"9"]) {
        plus = 5;
    }else if ([v hasPrefix:@"8"])
    {
        plus = 4;
    }else if ([v hasPrefix:@"7"])
    {
        plus = 3;
    }else if ([v hasPrefix:@"6"])
    {
        plus = 2;
    }
    
    
    return [NSNumber numberWithLong:(idStart + plus)];
}


+ (void)showAlertViewInViewController:(UIViewController*)vc title:(NSString*)title message:(NSString*)message
{
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if(systemVersion >= kSystemVersion)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BOX_OK", NULL)
                                                               style:UIAlertActionStyleCancel handler:nil];
        
        [alertController addAction:cancelAction];
        
        [vc presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        UIAlertView* view = [[UIAlertView alloc] initWithTitle:title
                                                       message: message
                                                      delegate:NULL
                                             cancelButtonTitle:NSLocalizedString(@"BOX_OK", NULL)
                                             otherButtonTitles:NULL, nil];
        [view show];
    }
}

+ (CGRect) getScreenBounds
{
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    if (([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        screenBounds.size = CGSizeMake(screenBounds.size.height, screenBounds.size.width);
    }
    return screenBounds;
}



+ (BOOL) SaveFile:(NSString*) filePath toNxlFile:(NSString*) nxlFilePath withtags:(NSDictionary*)nxlFiletags
{
    __block BOOL ret = NO;
    
    if ([NXMetaData isNxlFile:filePath]) {
        NSError *error = nil;
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL retValue = YES;
        if (![fm contentsEqualAtPath:filePath andPath:nxlFilePath]) {
            if ([fm fileExistsAtPath:nxlFilePath isDirectory:nil]) {
                [fm removeItemAtPath:nxlFilePath error:&error];
            }
            retValue = [fm copyItemAtPath:filePath toPath:nxlFilePath error:&error];
        }
        if (retValue) {
            ret = [NXMetaData setTags:nxlFiletags forFile:nxlFilePath];
        } else {
            ret = retValue;
        }
    }
    else
    {
        dispatch_semaphore_t semi = dispatch_semaphore_create(0);
        [NXMetaData encrypt:filePath destPath:nxlFilePath complete:^(NSError *error, id appendInfo) {
            error?ret = NO : ret = YES;
        }];
        dispatch_semaphore_wait(semi, DISPATCH_TIME_FOREVER);
//        ret = [NXMetaData encrypt:filePath destPath:nxlFilePath];
        if (ret) {
            ret = [NXMetaData setTags:nxlFiletags forFile:nxlFilePath];
        }
    }
    
    return ret;
}

+ (NSDictionary*) parseURLParams:(NSString *)query
{
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    NSMutableArray *info = [NSMutableArray arrayWithArray:pairs];
    [info removeObjectAtIndex:0];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for (NSString *pair in info) {
        NSArray *kv = [pair componentsSeparatedByString:@"="];
        NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [params setObject:val forKey:[kv objectAtIndex:0]];
    }
    return params;
}

+ (NSString*) randomStringwithLength:(NSUInteger)length
{
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123467890";
    NSMutableString *randomStr = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < length; ++i) {
        u_int32_t r = arc4random() % alphabet.length;
        unichar c = [alphabet characterAtIndex:r];
        [randomStr appendFormat:@"%C",c];
    }
    return [NSString stringWithString:randomStr];
}

+ (NSString*) getConvertFileTempPath
{
    NSString *path = [NSTemporaryDirectory()stringByAppendingPathComponent:@"nxrmcTmp"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        // folder is not exist,so create a new folder
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

/**
 *  clean temp file,like the file after encrypt and convert for 3D files
 */
+ (void)cleanTempFile
{
    NSString *tmppath = [NXCommonUtils getConvertFileTempPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *files = [fileManager contentsOfDirectoryAtPath:tmppath error:nil];
    for(NSString* file in files)
    {
        [fileManager removeItemAtPath:[tmppath stringByAppendingPathComponent:file] error:nil];
    }
}


+ (NSString*) md5Data:(NSData *)data
{    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( data.bytes, (int)data.length, result ); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSString *) getRmServer
{
    NSString *rmserver = [[NSUserDefaults standardUserDefaults] stringForKey:@"rmserver"];
    return rmserver;
}

+ (void) saveRmserver:(NSString *)rmserver
{
    [[NSUserDefaults standardUserDefaults] setObject:rmserver forKey:@"rmserver"];
}

+ (BOOL) isFirstTimeLaunching
{
    NSString *prevStartupVersion = [[NSUserDefaults standardUserDefaults] stringForKey:@"prevStartupVersion"];
    if (prevStartupVersion) {
        NSString *currentVersion = (NSString*)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (![prevStartupVersion isEqualToString:currentVersion]) {
            return YES;
        }
    } else {
        return YES;
    }
    return NO;
}

+ (void) saveFirstTimeLaunchSymbol
{
    NSString *currentVersion = (NSString*)[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:@"prevStartupVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void) unUnarchiverCacheDirectoryData:(NXFileBase *) rootFolder {
    if (!rootFolder.isRoot) {
        return;
    }
    rootFolder.favoriteFileList = [[NXCustomFileList alloc] init];
    rootFolder.offlineFileList = [[NXCustomFileList alloc] init];
    for (NXFileBase *file in [rootFolder getChildren]) {
        [NXCommonUtils unUnarchiverAllNodes:file];
    }
}

+ (void)unUnarchiverAllNodes:(NXFileBase *) file {
    if (file.isFavorite) {
        [[file ancestor].favoriteFileList addNode:file];
    }
    if (file.isOffline) {
        [[file ancestor].offlineFileList addNode:file];
    }
    for (NXFileBase *child in [file getChildren]) {
        [NXCommonUtils unUnarchiverAllNodes:child];
    }
}

+ (NXFileBase*)fetchFileInfofromThirdParty:(NSURL*)fileURL
{
    NXFile *file = [[NXFile alloc] init];
    
    file.name = fileURL.lastPathComponent;
    NSError *error;
    NSDictionary *fileAttributs = [[NSFileManager defaultManager] attributesOfItemAtPath:fileURL.path error:&error];
    if (fileAttributs) {
        
        NSString *dateString = [NSDateFormatter localizedStringFromDate:[fileAttributs fileModificationDate]
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterFullStyle];
        file.isRoot = NO;
        file.lastModifiedTime = dateString;
        file.lastModifiedDate = [fileAttributs fileModificationDate];
        file.size = [fileAttributs fileSize];
        file.fullPath = [NSString stringWithFormat:@"%@/%@", @"/Inbox", fileURL.lastPathComponent];
        ;
    }
    file.fullServicePath = fileURL.path;
    
    return file;
 }

+(NSString *) getServiceFolderKeyForFolderDirectory:(NXBoundService *) boundService
{
     return [NSString stringWithFormat:@"%@%@%@", boundService.service_type, NXDIVKEY, boundService.service_account_id];
}

+(NSError *) getNXErrorFromErrorCode:(NXRMC_ERROR_CODE) NXErrorCode error:(NSError *)error
{
    NSError *retError = nil;
    NSDictionary *userInfoDict = nil;
    NSString *localStr = nil;
    NSString *errorDomain = nil;
    if (NXErrorCode == NXRMC_ERROR_NO_NETWORK) {
       localStr = [NSString stringWithFormat:@"(%ld)", (long)NXErrorCode];
       errorDomain = NX_ERROR_NETWORK_DOMAIN;

    }else if(NXErrorCode == NXRMC_ERROR_CODE_TRANS_BYTES_FAILED)
    {
        localStr = [NSString stringWithFormat:@"(%ld)", (long)error.code];
        errorDomain = NX_ERROR_SERVICEDOMAIN;
    }
    else
    {
        localStr = [NSString stringWithFormat:@"(%ld)", (long)NXErrorCode];
        errorDomain = NX_ERROR_SERVICEDOMAIN;
    }
    
    switch (NXErrorCode) {
        case NXRMC_ERROR_CODE_NOSUCHFILE:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_NO_SUCH_FILE_DESC", nil)];
        }
            break;
        case NXRMC_ERROR_CODE_AUTHFAILED:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_AUTH_FAILED_DESC", nil)];
        }
            break;
        case NXRMC_ERROR_CODE_CONVERTFILEFAILED:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_CONVERT_FILE_FAILED_DESC", nil)];
        }
            break;
        case NXRMC_ERROR_CODE_CONVERTFILE_CHECKSUM_NOTMATCHED:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_CONVERTFILE_CHECKSUM_NOTMATCHED_DESC", nil)];
        }
            break;
        case NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_ACCESS_UNAUTHORIZED_DESC", nil)];
        }
            break;
        case NXRMC_ERROR_NO_NETWORK:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_NO_NETWORK_DESC", nil)];
        }
            break;
        case NXRMC_ERROR_CODE_TRANS_BYTES_FAILED:
        {
            localStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"ERROR_URL_TRANS_FAILED", nil)];
        }
            break;
        default:
            break;
    }
    
    userInfoDict = @{NSLocalizedDescriptionKey:localStr};
    retError = [NSError errorWithDomain:errorDomain code:NXErrorCode userInfo:userInfoDict];
    return retError;
}

+(NSString *)getImagebyExtension:(NSString *)fullPath {
    NSString *markExtension = [NSString stringWithFormat:@".%@.", [fullPath pathExtension]];

    NSString *wordString = @".docx.docm.doc.dotx.dotm.dot.";
    NSString *pptString = @".pptx.pptm.ppt.potx.potm.pot.ppsx.ppsm.pps.ppam.ppa.";
    NSString *excelString = @".xlsx.xlsb.xls.xltx.xltm.xlt.xlam.";

    if ([markExtension compare:@".pdf." options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return @"FilePDFIcon";
    }
    if ([markExtension compare:@".nxl." options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return @"FileNXLIcon";
    }
    if ([markExtension compare:@".txt." options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        return @"FileTXTIcon";
    }
    
    NSRange foundOjb = [wordString rangeOfString:markExtension options:NSCaseInsensitiveSearch];
    if (foundOjb.length > 0) {
        return @"FileMSWordIcon";
    }
    foundOjb = [pptString rangeOfString:markExtension options:NSCaseInsensitiveSearch];
    if (foundOjb.length > 0) {
        return @"FileMSPPTIcon";
    }
    foundOjb = [excelString rangeOfString:markExtension options:NSCaseInsensitiveSearch];
    if (foundOjb.length > 0) {
        return @"FileMSExcelIcon";
    }
    return @"Document";
}

+ (void)setLocalFileLastModifiedDate:(NSString *)localFilePath date:(NSDate *)date {
    NSError *error;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [defaultManager attributesOfItemAtPath:localFilePath error:&error];
    if (error) {
        NSLog(@"get file attribute failed, error message: %@", error.localizedDescription);
        return;
    }
    NSMutableDictionary *fileMutableDictory = [NSMutableDictionary dictionaryWithDictionary:fileAttributes];
    if (date) {
        [fileMutableDictory setObject:date forKey:@"NSFileModificationDate"];
        [defaultManager setAttributes:fileMutableDictory ofItemAtPath:localFilePath error:&error];
    } else { 
        NSLog(@"file modified time is null");
        return;
    }

    if(error) {
        NSLog(@"modify last modify date failed,error message :%@", error.localizedDescription);
    }
}

+ (NSDate *)getLocalFileLastModifiedDate:(NSString *)localFilePath {
    NSError *error;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [defaultManager attributesOfItemAtPath:localFilePath error:&error];
    if (error) {
        NSLog(@"get file attribute failed, error message: %@", error.localizedDescription);
        return nil;
    }
    NSDate *lastModifiedTime = [fileAttributes objectForKey:@"NSFileModificationDate"];
    return lastModifiedTime;
}

+ (UIUserInterfaceIdiom) getUserInterfaceIdiom
{
//    return [[UIDevice currentDevice] userInterfaceIdiom];
    return UIUserInterfaceIdiomPad;
}

+ (NSUInteger) getLogIndex
{
    NSUInteger retVal = arc4random();
    return retVal;
}

+ (NSString *) rmcToRMSRepoType:(NSNumber *) rmcRepoType
{
    NSDictionary *mapDict = @{[NSNumber numberWithInteger:kServiceDropbox]:RMS_REPO_TYPE_DROPBOX,
                              [NSNumber numberWithInteger:kServiceSharepointOnline]:RMS_REPO_TYPE_SHAREPOINTONLINE,
                              [NSNumber numberWithInteger:kServiceSharepoint]:RMS_REPO_TYPE_SHAREPOINT,
                              [NSNumber numberWithInteger:kServiceOneDrive]:RMS_REPO_TYPE_ONEDRIVE,
                              [NSNumber numberWithInteger:kServiceGoogleDrive]:RMS_REPO_TYPE_GOOGLEDRIVE};
    
    return mapDict[rmcRepoType];
}

+ (NSNumber *) rmsToRMCRepoType:(NSString *) rmsRepoType
{
    NSDictionary *mapDict = @{RMS_REPO_TYPE_DROPBOX:[NSNumber numberWithInteger:kServiceDropbox],
                              RMS_REPO_TYPE_SHAREPOINTONLINE:[NSNumber numberWithInteger:kServiceSharepointOnline],
                              RMS_REPO_TYPE_SHAREPOINT:[NSNumber numberWithInteger:kServiceSharepoint],
                              RMS_REPO_TYPE_ONEDRIVE:[NSNumber numberWithInteger:kServiceOneDrive],
                              RMS_REPO_TYPE_GOOGLEDRIVE:[NSNumber numberWithInteger:kServiceGoogleDrive]};
    
    return mapDict[rmsRepoType];
}


+ (NSString *) rmsToRMCDisplayName:(NSString *) rmsRepoType
{
    NSDictionary *mapDict = @{RMS_REPO_TYPE_DROPBOX:NSLocalizedString(@"CLOUDSERVICE_DROPBOX", nil),
                              RMS_REPO_TYPE_SHAREPOINTONLINE:NSLocalizedString(@"CLOUDSERVICE_SHAREPOINTONLINE", nil),
                              RMS_REPO_TYPE_SHAREPOINT:NSLocalizedString(@"CLOUDSERVICE_SHAREPOINT", nil),
                              RMS_REPO_TYPE_ONEDRIVE:NSLocalizedString(@"CLOUDSERVICE_ONEDRIVE", nil),
                              RMS_REPO_TYPE_GOOGLEDRIVE:NSLocalizedString(@"CLOUDSERVICE_GOOGLEDRIVE", nil)};
    return mapDict[rmsRepoType];
}


+(NSString *) userSyncDateDefaultsKey
{
    NSString *syncDateKey = [NSString stringWithFormat:@"%@@%@", [NXLoginUser sharedInstance].profile.userId, [NXLoginUser sharedInstance].profile.defaultMembership.tenantId];

    [syncDateKey stringByAppendingString:NXSYNC_REPO_DATE_USERDEFAULTS_KEY];
    return syncDateKey;
}

+ (NSString *) ISO8601Format:(NSDate *)date {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"<\"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'\""];
    return [formatter stringFromDate:date];
}

// convert URI string to normal string.
+ (NSString *)decodedURLString:(NSString *)encodedString
{
    NSString *decodedString  = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)encodedString, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    return decodedString;
}

+ (NSNumber *)converttoNumber:(NSString *)string
{
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *number = [f numberFromString:string];
    return number;
}

+ (BOOL)ispdfFileContain3DModelFormat:(NSString *)pdfFilePath
{
    CFURLRef pdfURL = CFURLCreateWithFileSystemPath(NULL, (__bridge CFStringRef)pdfFilePath, kCFURLPOSIXPathStyle, NO);
    CGPDFDocumentRef document = CGPDFDocumentCreateWithURL(pdfURL);
    
    size_t pages = CGPDFDocumentGetNumberOfPages(document);
    //3D pdf file format: https://www.convertcadfiles.com/3d-pdf/
    for (int i = 0; i < pages; i++) {
        CGPDFPageRef page = CGPDFDocumentGetPage(document, i + 1);
        CGPDFDictionaryRef dic = CGPDFPageGetDictionary(page);
        
        CGPDFObjectRef object;
        if (CGPDFDictionaryGetObject(dic, [@"Annots" UTF8String],&object) && CGPDFObjectGetType(object) == kCGPDFObjectTypeArray) {
            CGPDFArrayRef array;
            CGPDFDictionaryGetArray(dic, [@"Annots" UTF8String], &array);
            for (int j = 0; j < CGPDFArrayGetCount(array); j++) {
                CGPDFObjectRef object;
                if (CGPDFArrayGetObject(array, j, &object) && CGPDFObjectGetType(object) == kCGPDFObjectTypeDictionary) {
                    const char *type;
                    CGPDFDictionaryRef anno;
                    if (CGPDFArrayGetDictionary(array, j, &anno) && CGPDFDictionaryGetName(anno, [@"Subtype" UTF8String], &type)) {
                        if ([[NSString stringWithUTF8String:type] isEqualToString:@"3D"]) {
                            CGPDFStreamRef stream;
                            if (CGPDFDictionaryGetStream(anno, [@"3DD" UTF8String], &stream)) {
                                CGPDFDictionaryRef streamDic = CGPDFStreamGetDictionary(stream);
                                const char *typeName;
                                CGPDFDictionaryGetName(streamDic, [@"Type" UTF8String], &typeName);
                                const char *subTypename;
                                CGPDFDictionaryGetName(streamDic, [@"Subtype" UTF8String], &subTypename);
                                if ([[NSString stringWithUTF8String:subTypename] compare:@"U3D" options:NSCaseInsensitiveSearch] == NSOrderedSame||
                                    [[NSString stringWithUTF8String:subTypename] compare:@"PRC" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
//                                    CGPDFPageRelease(page);
                                    CGPDFDocumentRelease(document);
                                    return YES;
                                }
                            }
                        }
                    }
                }
            }
        }
//http://lists.apple.com/archives/quartz-dev/2006/Jun/msg00087.html
//        CGPDFPageRelease(page);
    }
    CGPDFDocumentRelease(document);
    return NO;
}

+ (BOOL)isStewardUser:(NSString *)userId {
    __block BOOL isSteward = NO;
    NSArray *memberships = [NXLoginUser sharedInstance].profile.memberships;
    [memberships enumerateObjectsUsingBlock:^(NXMembership *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.ID isEqualToString:userId]) {
            isSteward = YES;
        }
    }];
    return isSteward;
}

@end
