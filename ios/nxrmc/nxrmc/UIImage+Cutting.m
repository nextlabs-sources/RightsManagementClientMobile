//
//  UIImage+Cutting.m
//  nxrmc
//
//  Created by nextlabs on 8/11/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "UIImage+Cutting.h"

@implementation UIImage (Cutting)

- (UIImage *)imageScaleToSize:(CGSize)size {
    
    UIGraphicsBeginImageContext(size);//thiswillcrop
    
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
