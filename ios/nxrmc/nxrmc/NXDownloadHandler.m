//
//  NXDownloadHandle.m
//  nxrmc
//
//  Created by nextlabs on 10/23/15.
//  Copyright © 2015 nextlabs. All rights reserved.
//

#import "NXDownloadHandler.h"

@implementation NXDownloadHandler

+(NXDownloadHandler *) downloadHandlewithFile:(NXFileBase *)file delegate:(id<NXDownloadManagerDelegate>) delegate {
    NXDownloadHandler *handler = [[NXDownloadHandler alloc] init];
    handler.file = file;
    handler.delegate = delegate;
    return handler;
}

- (void) dealloc {
    NSLog(@"NXDownloadHandler dealloc %@", self.file.fullPath);
}

@end
