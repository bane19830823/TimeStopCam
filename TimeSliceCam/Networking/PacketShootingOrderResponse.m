//
//  PacketShootingOrderResponse.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/21.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "PacketShootingOrderResponse.h"
#import "NSData+SnapAdditions.h"

@implementation PacketShootingOrderResponse

@synthesize peerNumber = _peerNumber;


+ (id)packetWithPeerNumber:(NSString *)peerNumber {
    return [[[self class] alloc] initWithPeerNumber:peerNumber];
}

- (id)initWithPeerNumber:(NSString *)peerNumber
{
	if ((self = [super initWithType:PacketTypeServerReadyForShooting]))
	{
		self.peerNumber = peerNumber;
	}
	return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	[data rw_appendString:self.peerNumber];
}

+ (id)packetWithData:(NSData *)data {
    size_t count;
    NSString *peerNumber = [data rw_stringAtOffset:PACKET_HEADER_SIZE bytesRead:&count];
    return [[self class] packetWithPeerNumber:peerNumber];
}

@end
