//
//  NSString+Codec.m
//  nxrmc
//
//  Created by EShi on 7/1/16.
//  Copyright © 2016 nextlabs. All rights reserved.
//

#import "NSString+Codec.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Codec)
-(NSString *) hexString
{
    const char *utf8 = self.UTF8String;
    NSMutableString *hex = [NSMutableString string];
    while ( *utf8 ) [hex appendFormat:@"%02X" , *utf8++ & 0x00FF];
    
    
    NSMutableString * newString = [[NSMutableString alloc] init];
    int i = 0;
    while (i < [hex length])
    {
        NSString * hexChar = [hex substringWithRange: NSMakeRange(i, 2)];
        int value = 0;
        sscanf([hexChar cStringUsingEncoding:NSASCIIStringEncoding], "%x", &value);
        [newString appendFormat:@"%c", (char)value];
        i+=2;
    }
    return hex;
}

- (NSString*)MD5
{
    // Create pointer to the string as UTF8
    const char *ptr = [self UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}
@end
