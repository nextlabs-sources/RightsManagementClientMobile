//
//  NXRights.h
//  nxrmc
//
//  Created by Kevin on 16/6/21.
//  Copyright © 2016年 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(long, RIGHT) {
    RIGHTVIEW           = 0x00000001,
    RIGHTEDIT           = 0x00000002,
    RIGHTPRINT          = 0x00000004,
    RIGHTCLIPBOARD      = 0x00000008,
    RIGHTSAVEAS         = 0x00000010,
    RIGHTDECRYPT        = 0x00000020,
    RIGHTSCREENCAP      = 0x00000040,
    RIGHTSEND           = 0x00000080,
    RIGHTCLASSIFY       = 0x00000100,
    RIGHTSHARING        = 0x00000200,
    RIGHTSDOWNLOAD      = 0x00000400,
};

typedef NS_OPTIONS(long, OBLIGATION){
    OBLIGATIONWATERMARK = 0x00000001,
};

@interface NXRights : NSObject

- (id)initWithRightsObs: (NSArray*)rights obligations: (NSArray*)obs;

- (BOOL)ViewRight;
- (BOOL)ClassifyRight;
- (BOOL)EditRight;
- (BOOL)PrintRight;
- (BOOL)SharingRight;
- (BOOL)DownloadRight;

- (BOOL)getRight:(RIGHT)right;
- (void)setRight:(RIGHT)right value:(BOOL)hasRight;

- (void)setRights:(long)rights;
- (void)setAllRights;
- (void)setNoRights;
- (long)getRights;
- (NSArray*)getNamedRights;

- (void)setObligation:(OBLIGATION) ob value: (BOOL)hasOb;
- (BOOL)getObligation:(OBLIGATION) ob;
- (NSArray*)getNamedObligations;


+ (NSArray *)getSupportedContentRights;
+ (NSArray *)getSupportedCollaborationRights;
+ (NSArray *)getSupportedObs;

@end
