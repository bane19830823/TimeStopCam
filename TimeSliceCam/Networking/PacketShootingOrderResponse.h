//
//  PacketShootingOrderResponse.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/21.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"

@interface PacketShootingOrderResponse : Packet

@property (nonatomic, copy) NSString *peerNumber;

+ (id)packetWithPeerNumber:(NSString *)peerNumber;

@end
