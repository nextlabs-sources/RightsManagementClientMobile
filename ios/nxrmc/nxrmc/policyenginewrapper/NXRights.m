//
//  NXRights.m
//  nxrmc
//
//  Created by Kevin on 16/6/21.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import "NXRights.h"

@interface NXRights ()
{
    long    _rights;
    long    _obs;
    NSDictionary* _dictRights;
    NSDictionary* _dictObligations;
}
@end

@implementation NXRights

- (id)init
{
    if (self = [super init]) {
        _rights = 0;
        _obs = 0;
        _dictRights = @{
                        [NSNumber numberWithLong:RIGHTVIEW]: @"VIEW",
                        [NSNumber numberWithLong:RIGHTEDIT]: @"EDIT",
                        [NSNumber numberWithLong:RIGHTPRINT]: @"PRINT",
                        [NSNumber numberWithLong:RIGHTCLIPBOARD]: @"CLIPBOARD",
                        [NSNumber numberWithLong:RIGHTSAVEAS]: @"SAVEAS",
                        [NSNumber numberWithLong:RIGHTDECRYPT]: @"DECRYPT",
                        [NSNumber numberWithLong:RIGHTSCREENCAP]: @"SCREENCAP",
                        [NSNumber numberWithLong:RIGHTSEND]: @"SEND",
                        [NSNumber numberWithLong:RIGHTCLASSIFY]: @"CLASSIFY",
                        [NSNumber numberWithLong:RIGHTSHARING]: @"SHARE",
                        [NSNumber numberWithLong:RIGHTSDOWNLOAD]: @"DOWNLOAD",
                        };
        _dictObligations = @{
                             [NSNumber numberWithLong:OBLIGATIONWATERMARK]: @"WATERMARK",
                             };
    }
    
    return self;
}

- (id)initWithRightsObs:(NSArray *)rights obligations:(NSArray *)obs
{
    if (self = [self init]) {
        [_dictRights enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            NSString* value = (NSString*)obj;
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF == %@", value];
            NSArray* temp = [rights filteredArrayUsingPredicate:predicate];
            if (temp.count > 0 ) {
                _rights |= [key longValue];
            }
        }];
        
        
        [obs enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary* ob = (NSDictionary*)obj;
            NSString* obValue = [ob objectForKey:@"name"];
           
            [_dictObligations enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obValue isEqualToString:(NSString*)obj]) {
                    _obs |= [key longValue];
                    *stop = YES;
                }
            }];
        }];
    }
    
    return self;
}

- (BOOL)ViewRight
{
    return (_rights & RIGHTVIEW) != 0 ? YES : NO;
}

- (BOOL)ClassifyRight
{
    return (_rights & RIGHTCLASSIFY) != 0 ? YES : NO;
}

- (BOOL)EditRight
{
    return (_rights & RIGHTEDIT) != 0 ? YES : NO;
}

- (BOOL)PrintRight
{
    return (_rights & RIGHTPRINT) != 0 ? YES : NO;
}

- (BOOL)SharingRight
{
    return (_rights & RIGHTSHARING) != 0 ? YES : NO;
}

- (BOOL)DownloadRight
{
    return (_rights & RIGHTSDOWNLOAD) != 0 ? YES : NO;
}

- (BOOL)getRight:(RIGHT)right {
    return (_rights & right) != 0 ? YES : NO;
}

- (BOOL)getObligation:(OBLIGATION)ob
{
    return (_obs & ob) != 0 ? YES: NO;
}

- (void)setRight:(RIGHT)right value:(BOOL)hasRight
{
    if (hasRight) {
        _rights |= right;
    } else {
        _rights &= ~(right);
    }
}

- (void)setObligation:(OBLIGATION)ob value:(BOOL)hasOb
{
    if (hasOb) {
        _obs |= ob;
    }
    else
    {
        _obs &= ~(ob);
    }
}

- (void)setRights:(long)rights
{
    _rights = rights;
}

- (void)setAllRights
{
    _rights = 0xFFFFFFFF;
}

- (void)setNoRights {
    _rights = 0x00000000;
}

- (long) getRights
{
    return _rights;
}

- (NSArray*)getNamedRights
{
    NSMutableArray* namedRights = [NSMutableArray array];
    if (_rights & RIGHTVIEW) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTVIEW]]];
    }
    if (_rights & RIGHTEDIT) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTEDIT]]];
    }
    if (_rights & RIGHTPRINT) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTPRINT]]];
    }
    if (_rights & RIGHTCLIPBOARD) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTCLIPBOARD]]];
    }
    if (_rights & RIGHTSAVEAS) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTSAVEAS]]];
    }
    if (_rights & RIGHTDECRYPT) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTDECRYPT]]];
    }
    if (_rights & RIGHTSCREENCAP) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTSCREENCAP]]];
    }
    if (_rights & RIGHTSEND) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTSEND]]];
    }
    if (_rights & RIGHTCLASSIFY) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTCLASSIFY]]];
    }
    if (_rights & RIGHTSHARING) {
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTSHARING]]];
    }
    if (_rights & RIGHTSDOWNLOAD){
        [namedRights addObject:[_dictRights objectForKey:[NSNumber numberWithLong:RIGHTSDOWNLOAD]]];
    }
    return namedRights;
}

- (NSArray*) getNamedObligations
{
    NSMutableArray* namedObligations = [NSMutableArray array];
    if (_obs & OBLIGATIONWATERMARK) {
        NSDictionary* ob = @{@"name":[_dictObligations objectForKey:[NSNumber numberWithLong:OBLIGATIONWATERMARK]]};
        [namedObligations addObject:ob];
    }
    return namedObligations;
}


+ (NSArray *)getSupportedContentRights
{
    return @[  @{@"View":[NSNumber numberWithLong:RIGHTVIEW]},
               @{@"Edit":[NSNumber numberWithLong:RIGHTEDIT]},
               @{@"Print":[NSNumber numberWithLong:RIGHTPRINT]},
         /*      @{@"Clipboard":[NSNumber numberWithLong:RIGHTCLIPBOARD]},
               @{@"Save As": [NSNumber numberWithLong:RIGHTSAVEAS]},
               @{@"Decrypt": [NSNumber numberWithLong:RIGHTDECRYPT]},
               @{@"Screen Capture": [NSNumber numberWithLong:RIGHTSCREENCAP]},
               @{@"Send": [NSNumber numberWithLong:RIGHTSEND]},
               @{@"Classify": [NSNumber numberWithLong:RIGHTCLASSIFY]},*/
              
             ];
}

+ (NSArray *)getSupportedCollaborationRights
{
    return @[
              @{@"Share": [NSNumber numberWithLong:RIGHTSHARING]},
              @{@"Download": [NSNumber numberWithLong:RIGHTSDOWNLOAD]},
             ];
}

+ (NSArray*) getSupportedObs
{
    return @[@{@"Watermark/Overlay": [NSNumber numberWithLong:OBLIGATIONWATERMARK]}];
}

@end

