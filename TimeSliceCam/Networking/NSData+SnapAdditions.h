//
//  NSData+SnapAdditions.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/08.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

@interface NSMutableData (SnapAdditions)

- (void)rw_appendInt32:(int)value;
- (void)rw_appendInt16:(short)value;
- (void)rw_appendInt8:(char)value;
- (void)rw_appendString:(NSString *)string;
- (void)rw_appendData:(NSData *)data;

@end

@interface NSData (SnapAdditions)

- (int)rw_int32AtOffset:(size_t)offset;
- (short)rw_int16AtOffset:(size_t)offset;
- (char)rw_int8AtOffset:(size_t)offset;
- (NSString *)rw_stringAtOffset:(size_t)offset bytesRead:(size_t *)amount;
- (NSData *)rw_videoDataAtOffset:(size_t)offset;


@end
