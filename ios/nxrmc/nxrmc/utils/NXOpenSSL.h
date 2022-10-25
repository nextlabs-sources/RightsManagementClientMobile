//
//  NXOpenSSL.h
//  nxrmc
//
//  Created by EShi on 6/25/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DH_PUBLIC_KEY @"DH_PUBLIC_KEY"
#define DH_PRIVATE_KEY @"DH_PRIVATE_KEY"

@interface NXOpenSSL : NSObject
+(NSDictionary *) generateDHKeyPair;
+(void) DHAgreementPublicKey:(NSString *) certification binPublicKey: (NSData**)publicKey agreement: (NSString**) agreement;

+ (NSString*) DHAgreementFromBinary: (NSData*) data;
@end
