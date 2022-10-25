//
//  NSData+zip.h
//  nxrmc
//
//  Created by nextlabs on 6/29/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (zip)

- (NSData *)gzip;
- (NSData *)ungzip;

@end
