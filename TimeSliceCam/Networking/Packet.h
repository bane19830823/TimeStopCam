//
//  Packet.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/08.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

const size_t PACKET_HEADER_SIZE;
typedef enum
{
	PacketTypeServerReadyForShooting = 0x64,         // server to client (撮影準備完了)
	PacketTypeClientReadyForShooting,                // client to server
    
	PacketTypeServerShootingStartRequest,            // server to client (録画スタート)    
	PacketTypeSendMovieData,                         // client to server (写真データ送信)
    PacketTypeShootingDidFinish,                     // client to server (撮影終了通知)
    PacketTypeReadyForReceiveData                    // server to client (データ受信準備完了通知)
} PacketType;

@interface Packet : NSObject

@property (nonatomic, assign) PacketType packetType;
@property (nonatomic, assign) int packetNumber;

+ (id)packetWithType:(PacketType)packetType;
- (id)initWithType:(PacketType)packetType;
+ (id)packetWithData:(NSData *)data;
- (NSData *)data;

@end
