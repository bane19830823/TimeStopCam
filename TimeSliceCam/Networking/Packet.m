//
//  Packet.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/08.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "Packet.h"
#import "NSData+SnapAdditions.h"
#import "PacketShootingOrderResponse.h"
#import "PacketShootingReadyResponse.h"
#import "PacketVideoDataSender.h"
#import "PacketShootingFinishResponse.h"

const size_t PACKET_HEADER_SIZE = 10;

@implementation Packet

@synthesize packetType = _packetType;
@synthesize packetNumber = _packetNumber;

+ (id)packetWithType:(PacketType)packetType
{
	return [[[self class] alloc] initWithType:packetType];
}

- (id)initWithType:(PacketType)packetType
{
	if ((self = [super init]))
	{
		self.packetType = packetType;
        self.packetNumber = -1;
	}
	return self;
}

- (NSData *)data
{
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:0];
    
	[data rw_appendInt32:'TIME'];                   // (header 4bytes)
	[data rw_appendInt32:self.packetNumber];        // packetNumber(4bytes)
	[data rw_appendInt16:self.packetType];          // packetType(2bytes)
    
    [self addPayloadToData:data];                   // Payload(otherData)
    
	return data;
}

- (void)addPayloadToData:(NSMutableData *)data
{
	// base class does nothing
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@, number=%d, type=%d", [super description], self.packetNumber, self.packetType];
}

+ (id)packetWithData:(NSData *)data
{
	if ([data length] < PACKET_HEADER_SIZE)
	{
		LOG(@"Error: Packet too small");
		return nil;
	}
    
	if ([data rw_int32AtOffset:0] != 'TIME')
	{
		LOG(@"Error: Packet has invalid header");
		return nil;
	}
    
	int packetNumber = [data rw_int32AtOffset:4];
	PacketType packetType = [data rw_int16AtOffset:8];
    
    Packet *packet = nil;
    
    switch (packetType) {
        case PacketTypeServerReadyForShooting:
            packet = [PacketShootingOrderResponse packetWithData:data];
            break;
        case PacketTypeClientReadyForShooting:
            packet = [PacketShootingReadyResponse packetWithData:data];
            break;
        case PacketTypeServerShootingStartRequest:
            packet = [Packet packetWithType:packetType];
            break;
        case PacketTypeSendMovieData:
            packet = [PacketVideoDataSender packetWithData:data];
            break;
        case PacketTypeShootingDidFinish:
            packet = [PacketShootingFinishResponse packetWithData:data];
            break;
        case PacketTypeReadyForReceiveData:
            packet = [Packet packetWithType:packetType];
            break;
        default:
            LOG(@"Error: Packet has invalid type");
            return nil;
            break;
    }
    
    packet.packetNumber = packetNumber;
	return packet;
}
@end
