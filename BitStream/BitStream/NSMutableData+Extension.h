//
//  NSMutableData+Extension.h
//  BitStream
//
//  Created by myself on 2019/5/25.
//  Copyright © 2019 chaocaiwei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableData (Extension)

- (void)appendInt:(int)value;
- (void)appendInt8:(int8_t)value;
- (void)appendInt16:(int16_t)value;
- (void)appendInt32:(int32_t)value;
- (void)appendInt64:(int64_t)value;

- (void)appendUInt:(uint)value;
- (void)appendUInt8:(uint8_t)value;
- (void)appendUInt16:(int16_t)value;
- (void)appendUInt32:(int32_t)value;
- (void)appendUInt64:(int64_t)value;

@end

NS_ASSUME_NONNULL_END
