//
//  PacketVideoDataSender.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/28.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"

@interface PacketVideoDataSender : Packet

@property (nonatomic, retain) NSString *peerNumber;
@property (nonatomic, retain) NSData *videoData;
@property (nonatomic, retain) NSString *numberOfPackets;

+ (id)packetWithPeerNumber:(NSString *)peerNumber numberOfPackets:(NSString *)packets videoData:(NSData *)data;

@end
