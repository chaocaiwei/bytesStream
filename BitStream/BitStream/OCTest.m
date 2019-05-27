//
//  OCTest.m
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

#import "OCTest.h"
#import "NSData+Extension.h"



@implementation OCTest

+ (NSData *)testBuildData
{
    int16_t i = CFSwapInt16BigToHost(0x0025);
    UInt8   j = 3;
    double  k = 3.14;
    NSString *l   = @"a string";
    const char *m = "1234";
    
    NSMutableData *data0 = [[NSMutableData alloc] initWithBytes:&i length:sizeof(i)];
    [data0 appendBytes:&j length:sizeof(j)];
    [data0 appendBytes:&k length:sizeof(k)];
    [data0 appendData:[l dataUsingEncoding:NSUTF8StringEncoding]];
    [data0 appendBytes:m length:4];
    
    NSLog(@"%@",[data0 hexString]);
    return data0;
}

+ (void)testParseData:(NSData *)data
{
    int16_t tci;
    UInt8   cj;
    double  ck;
    char cm[10];
    [data getBytes:&tci range:NSMakeRange(0,2)];
    int16_t ci = CFSwapInt16BigToHost(tci);
    [data getBytes:&cj range:NSMakeRange(2,1)];
    [data getBytes:&ck range:NSMakeRange(3,8)];
    NSData *clData = [data subdataWithRange:NSMakeRange(11,9)];
    NSString *cl = [[NSString alloc] initWithData:clData encoding:NSUTF8StringEncoding];
    [data getBytes:cm range:NSMakeRange(19,4)];
    
    NSLog(@"ci=%d cj=%d ck=%lf cl=%@ cm=%s ",ci,cj,ck,cl,cm);
    
}

+ (void)testParseDataWithBytes:(NSData *)data
{
    const void *bytes = [data bytes];
    int16_t ci = *(int16_t*)(bytes);
    uint8_t cj = *(uint8_t*)(bytes+2);
    double  ck = *(double*)(bytes+3);
    char *cl = (char *)(bytes+11);
    char *cm = (char *)(bytes+19);
    NSString *nl = [NSString stringWithCString:cl encoding:NSUTF8StringEncoding];
    NSString *nm = [NSString stringWithCString:cm encoding:NSUTF8StringEncoding];
    
    NSLog(@"ci=%d cj=%d ck=%lf cl=%s cm=%s nl=%@ nm=%@",ci,cj,ck,cl,cm,nl,nm);
}

+ (void)testStruct
{
    struct Message msg = {};
    msg.type = 'a';
    msg.seq  = 0x0102;
    msg.timeTemp = CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970;
    memcpy(msg.content,"123456789012345",16);
    
    // 生成要发送的数据包
    void *sent = &msg;
    int length = sizeof(struct Message);
    
    int i = 0;
    Byte bytes[length];
    while (i < length) {
        bytes[i] = *(Byte *)(sent+i);
        i++;
    }
    
    NSMutableData *cdata = [[NSMutableData alloc] init];
    [cdata appendBytes:sent length:length];
    NSLog(@"%@",[cdata hexString]);
    // 接收到数据包后解析
    Byte *rec = (Byte *)[cdata bytes];
    struct Message nmsg = *(struct Message *)rec;
   
    NSLog(@"type=%d seq=%d temetamp=%lf msg=%s",nmsg.type,nmsg.seq,nmsg.timeTemp,nmsg.content);
}

+ (void)testIntToBytes:(int)value bytes:(Byte *)bytes size:(int*)size
{
    bytes[0] = (Byte)((value & 0xFF000000)>>24);
    bytes[1] = (Byte)((value & 0x00FF0000)>>16);
    bytes[2] = (Byte)((value & 0x0000FF00)>>8);
    bytes[3] = (Byte)((value & 0x000000FF));
    *size = 4;
}

+ (int)bytesToInt:(Byte *)bytes
{
    int res = 0;
    res |= (bytes[0] << 24);
    res |= (bytes[1] << 16);
    res |= (bytes[2] << 8);
    res |= bytes[3];
    return res;
}

+ (void)testCString
{
    NSString *string = @"一个字符串";
    Byte *cbytes = (Byte *)[string cStringUsingEncoding:NSUTF8StringEncoding];
    int i = 0;
    while (*(cbytes+i) != '\0') {
        i++;
    }
    NSLog(@"string.length=%lu cstring.lenth=%d",(unsigned long)string.length,i);
    // 输出：string.length=5 cstring.lenth=15
}

+ (void)test {

    NSData *data = [self testBuildData];
    [self testParseDataWithBytes:data];
    [self testParseData:data];
    
    
    Byte byte[4] = {0};
    printf(byte);
    int size;
    [self testIntToBytes:314 bytes:byte size:&size];
    int value = [self bytesToInt:byte];
    NSLog(@"%d",value);
   
    [self testStruct];
}

@end
