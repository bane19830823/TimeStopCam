//
//  PacketVideoDataSender.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/28.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "PacketVideoDataSender.h"
#import "NSData+SnapAdditions.h"

@implementation PacketVideoDataSender

@synthesize peerNumber = _peerNumber;

+ (id)packetWithPeerNumber:(NSString *)peerNumber numberOfPackets:(NSString *)packets videoData:(NSData *)data  {
    return [[[self class] alloc] initWithPeerNumber:peerNumber numberOfPackets:packets videoData:data ];
}

- (id)initWithPeerNumber:(NSString *)peerNumber numberOfPackets:(NSString *)packets videoData:(NSData *)data  {
    if ((self = [super initWithType:PacketTypeSendMovieData])) {
        self.packetNumber = 0;  // enable packet numbers for this packet
        self.peerNumber = peerNumber;
        self.numberOfPackets = packets;
        self.videoData = data;
    }
    return self;
}

- (void)addPayloadToData:(NSMutableData *)data
{
    [data rw_appendString:self.peerNumber];
    [data rw_appendString:self.numberOfPackets];
    [data rw_appendData:self.videoData];
}

+ (id)packetWithData:(NSData *)data {
    LOG_METHOD;
    size_t offset = PACKET_HEADER_SIZE;
    size_t count;
    
    NSString *peerNumber = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSString *numOfPackets = [data rw_stringAtOffset:offset bytesRead:&count];
    offset += count;
    
    NSData *videoData = [data rw_videoDataAtOffset:offset];
    
   return [[self class] packetWithPeerNumber:peerNumber numberOfPackets:numOfPackets videoData:videoData];
}

@end
