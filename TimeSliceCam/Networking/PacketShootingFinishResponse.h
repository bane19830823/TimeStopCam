//
//  PacketShootingFinishResponse.h
//  TimeSliceCam
//
//  Created by Bane on 12/11/12.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Packet.h"

@interface PacketShootingFinishResponse : Packet

@property (nonatomic, copy) NSString *peerName;

+ (id)packetWithPeerName:(NSString *)peerName;

@end
