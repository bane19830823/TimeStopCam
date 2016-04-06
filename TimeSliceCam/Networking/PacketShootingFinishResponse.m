//
//  PacketShootingFinishResponse.m
//  TimeSliceCam
//
//  Created by Bane on 12/11/12.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "PacketShootingFinishResponse.h"
#import "NSData+SnapAdditions.h"

@implementation PacketShootingFinishResponse

@synthesize peerName = _peerName;

+ (id)packetWithPeerName:(NSString *)peerName {
	return [[[self class] alloc] initWithPeerName:peerName];
}

- (id)initWithPeerName:(NSString *)peerName
{
	if ((self = [super initWithType:PacketTypeShootingDidFinish]))
	{
		self.peerName = peerName;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.peerName];
}

+ (id)packetWithData:(NSData *)data {
    size_t count;
    NSString *peerName = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
    return [[self class] packetWithPeerName:peerName];
}

@end
