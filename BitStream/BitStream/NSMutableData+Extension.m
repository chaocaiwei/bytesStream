//
//  NSMutableData+Extension.m
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

#import "NSMutableData+Extension.h"

@implementation NSMutableData (Extension)

// TODO 自动生成代码完成剩下的函数
- (void)appendInt:(int)value
{
    int bigValue;
    bigValue = CFSwapInt32HostToBig(value);
    [self appendBytes:&bigValue length:sizeof(value)];
}

@end
