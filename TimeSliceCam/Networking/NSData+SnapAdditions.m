//
//  NSData+SnapAdditions.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/08.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "NSData+SnapAdditions.h"

@implementation NSData (SnapAdditions)

- (int)rw_int32AtOffset:(size_t)offset
{
	const int *intBytes = (const int *)[self bytes];
	return ntohl(intBytes[offset / 4]);
}

- (short)rw_int16AtOffset:(size_t)offset
{
	const short *shortBytes = (const short *)[self bytes];
	return ntohs(shortBytes[offset / 2]);
}

- (char)rw_int8AtOffset:(size_t)offset
{
	const char *charBytes = (const char *)[self bytes];
	return charBytes[offset];
}

- (NSString *)rw_stringAtOffset:(size_t)offset bytesRead:(size_t *)amount
{
	const char *charBytes = (const char *)[self bytes];
	NSString *string = [NSString stringWithUTF8String:charBytes + offset];
	*amount = strlen(charBytes + offset) + 1;
	return string;
}

- (NSData *)rw_videoDataAtOffset:(size_t)offset;
{
    
    NSData *data = [self subdataWithRange:NSMakeRange(offset, [self length] - offset)];
    
    return data;
}

@end

@implementation NSMutableData (SnapAdditions)

- (void)rw_appendInt32:(int)value
{
	value = htonl(value);
	[self appendBytes:&value length:4];
}

- (void)rw_appendInt16:(short)value
{
	value = htons(value);
	[self appendBytes:&value length:2];
}

- (void)rw_appendInt8:(char)value
{
	[self appendBytes:&value length:1];
}

- (void)rw_appendString:(NSString *)string
{
	const char *cString = [string UTF8String];
	[self appendBytes:cString length:strlen(cString) + 1];
}

- (void)rw_appendData:(NSData *)data
{
    [self appendBytes:[data bytes] length:[data length]];
}
@end
