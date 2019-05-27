//
//  OCTest.h
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

#import <Foundation/Foundation.h>


//#pragma pack (2)
struct Message {
    uint8_t  type;
    uint32_t seq;
    double   timeTemp;
    char     content[16];
};

NS_ASSUME_NONNULL_BEGIN

@interface OCTest : NSObject

+ (void)test;

@end

NS_ASSUME_NONNULL_END
