//
//  NSData+Extension.m
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

#import "NSData+Extension.h"

@implementation NSData (Extension)

- (NSString *)hexString
{
    NSMutableString *mstr = [NSMutableString new];
    const Byte *bytes = [self bytes];
    for (int i = 0; i < self.length; i++) {
        [mstr appendFormat:@"0x%02x ",bytes[i]];
    }
    return mstr;
}

@end
