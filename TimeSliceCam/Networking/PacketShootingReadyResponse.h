//
//  PacketShootingReadyResponse.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/22.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"

@interface PacketShootingReadyResponse : Packet

@property (nonatomic, copy) NSString *peerName;

+ (id)packetWithPeerName:(NSString *)peerName;

@end
