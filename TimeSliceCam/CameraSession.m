//
//  CameraSession.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/10.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "CameraSession.h"
#import "Packet.h"
#import "Peer.h"
#import "PacketShootingOrderResponse.h"
#import "PacketShootingReadyResponse.h"
#import "PacketShootingFinishResponse.h"
#import "AppDelegate.h"

typedef enum {
    CamSessionStateWaitingForSignIn,
    CamSessionStateWaitingForReady,
    CamSessionStateShootingReady,
    CamSessionStateShooting,
    CamSessionStateShootIsOver,
    CamSessionStateQuitting
} CamSessionState;

@implementation CameraSession {
    CamSessionState _state;
    NSArray *_clients;

}

@synthesize delegate = _delegate;
@synthesize session = _session;
@synthesize serverPeerID = _serverPeerID;
@synthesize peerName = _peerName;
@synthesize shooters = _shooters;
@synthesize shootingFinishedClientCount = _shootingFinishedClientCount;

- (void)dealloc {
#ifdef DEBUG
    LOG(@"%@", self);
#endif
    [super dealloc];
}

//クライアントの撮影状況をチェックするメソッド
- (void)checkShootingStatus {
    if (self.shootingFinishedClientCount == [_shooters count]) {
        
        if ([self.delegate respondsToSelector:@selector(cameraSessionDidAllClientFinishShooting:withShooters:gkSession:peerName:)]) {
            [self.delegate cameraSessionDidAllClientFinishShooting:self
                                                      withShooters:_shooters
                                                         gkSession:_session
                                                          peerName:_peerName];
        }
    }
}

- (id)init
{
	if ((self = [super init]))
	{
        //最大接続可能数(16) - 1(サーバーを1台としてカウントする)
        self.shooters = [[NSMutableArray alloc] initWithCapacity:15];
        self.shootingFinishedClientCount = 0;
	}
	return self;
}

#pragma mark - CameraSession Starting Methods
//クライアント
- (void)startClientShootingWithSession:(GKSession *)session
                              peerName:(NSString *)name
                                server:(NSString *)peerID {
    
    LOG_METHOD;
    
    _session = session;
    _session.available = NO;
    _session.delegate = self;
    [_session setDataReceiveHandler:self withContext:nil];
    
    _serverPeerID = peerID;
    _peerName = name;
    
    _state = CamSessionStateWaitingForReady;
    
//    Packet *packet = [PacketCapturingResponse packetWithPeerName:_serverPeerID];
//    [self sendPacketToServer:packet];
    [self.delegate camSessionWaitingForServerReady:self];
}

//サーバー
- (void)startServerShootingWithSession:(GKSession *)session
                              peerName:(NSString *)name
                               clients:(NSArray *)clients {
    
    LOG_METHOD;
    
    _clients = clients;
	_session = session;
	_session.available = NO;
	_session.delegate = self;
	[_session setDataReceiveHandler:self withContext:nil];
    
	_state = CamSessionStateWaitingForReady;
    
//    [self.delegate camSessionWaitingForClientsReady:self];
    
    // iPhone x iPhone の場合0番目であるサーバーにはパケットを送信しないで
    // まずサーバーにshootingNumberをセットする

    int start;
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (app.globalShootingMode == ShootingMode_iPhone_iPhone) {
        start = 1;
        if ([self.delegate respondsToSelector:@selector(cameraSession:setShootingNumber:)]) {
            [self.delegate cameraSession:self setShootingNumber:@"0"];
        }
        
        NSString *peerID = [clients objectAtIndex:0];
		Peer *peer = [[[Peer alloc] init] autorelease];
		peer.peerID = peerID;
        peer.peerNumber = 0;

        LOG(@"Peer ID = %@ PeerNumber = %d and This will be the server", peer.peerID, peer.peerNumber);
        [_shooters addObject:peer];
    } else {
        start = 0;
    }
    
    // Add a Peer object for each client.
    for (int i = start; i < [clients count]; i++) {
        NSString *peerID = [clients objectAtIndex:i];
		Peer *peer = [[[Peer alloc] init] autorelease];
		peer.peerID = peerID;
        peer.peerNumber = i;
        
        LOG(@"Send Shooting Order: Peer ID = %@ PeerNumber = %d", peer.peerID, peer.peerNumber);
        [_shooters addObject:peer];
        
        Packet *packet = [PacketShootingOrderResponse packetWithPeerNumber:[NSString stringWithFormat:@"%d", peer.peerNumber]];
        [self sendPacketToClient:peerID packet:packet];
    }
}

- (void)quitCameraSessionWithReason:(QuitReason)reason {
    
    LOG_METHOD;
    _state = CamSessionStateQuitting;
    
    [_session disconnectFromAllPeers];
    _session.delegate = nil;
    _session = nil;
    
    [self.delegate cameraSession:self didQuitReason:reason];
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"CamSession: peer %@ changed state %d", peerID, state);
#endif
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"CamSession: connection request from peer %@", peerID);
#endif
    
	[session denyConnectionFromPeer:peerID];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"CamSession: connection with peer %@ failed %@", peerID, error);
#endif
    
	// Not used.
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"CamSession: session failed %@", error);
#endif
}

#pragma mark - GKSession Data Receive Handler

//データ受信
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"CameraSession: receive data from peer: %@, data: %@, length: %d", peerID, data, [data length]);
#endif
    
	Packet *packet = [Packet packetWithData:data];
	if (packet == nil)
	{
		LOG(@"Invalid packet: %@", data);
		return;
	}
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (app.isServer) {
        Peer *peer = [self peerWithPeerID:peerID];
        if (peer != nil) {
            [self serverReceivedPacket:packet fromPeer:peer];
        } else {
            LOG(@"peer is nil!!");
        }
    } else {
		[self clientReceivedPacket:packet];
    }
}

//サーバーでパケット受信
- (void)serverReceivedPacket:(Packet *)packet fromPeer:(Peer *)peer
{
    LOG_METHOD;
	switch (packet.packetType)
	{
    
        case PacketTypeClientReadyForShooting:
//            if (_state == CamSessionStateWaitingForReady) {
//                _state = CamSessionStateShootingReady;
            
                LOG(@"PacketTypeClientReadyForShooting:serverReceivedPacketFromPeer:%@", peer.peerID);
                [self.delegate cameraSession:self didReceiveReadyForShootingPacketFromClient:peer.peerID];
                
//            }
            break;
        //クライアントから撮影終了通知を受け取る
        case PacketTypeShootingDidFinish:
            self.shootingFinishedClientCount++;
            [self checkShootingStatus];
        
            break;
		default:
			LOG(@"Server received unexpected packet: %@", packet);
			break;
	}
}

//クライアントでパケット受信
- (void)clientReceivedPacket:(Packet *)packet
{
    LOG_METHOD;
	switch (packet.packetType)
	{
        //撮影順番を表示する
        case PacketTypeServerReadyForShooting: 
            if (_state == CamSessionStateWaitingForReady) {
                _state = CamSessionStateShootingReady;
                
                NSString *peerNumber = ((PacketShootingOrderResponse *)packet).peerNumber;
                [self.delegate cameraSession:self setShootingNumber:peerNumber];
                
                Packet *packet =
                [PacketShootingReadyResponse packetWithPeerName:_peerName];
                
                [self sendPacketToServer:packet];
            }
            
            break;
        //撮影開始!!
        case PacketTypeServerShootingStartRequest:
            if (_state == CamSessionStateShootingReady) {
                _state = CamSessionStateShooting;
                
                [self.delegate cameraSessionSatrtRecording:self];
            }
            break;
		default:
			LOG(@"Client received unexpected packet: %@", packet);
			break;
	}
}

- (Peer *)peerWithPeerID:(NSString *)peerID
{
    for (int i = 0; i < [_shooters count]; i++) {
        Peer *peer = [_shooters objectAtIndex:i];
        if ([peer.peerID isEqual:peerID]) {
            return [_shooters objectAtIndex:i];
        }
    }
    return nil;
}

#pragma mark - Networking

//サーバーからすべてのpeerへ一斉送信
- (void)sendPacketToAllClients:(Packet *)packet
{
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error = nil;
	if (![_session sendDataToAllPeers:data withDataMode:dataMode error:&error])
	{
		LOG(@"Error sending data to clients: %@", error);
	}
}

//サーバーから特定のpeerへパケット送信
- (void)sendPacketToClient:(NSString *)peerID packet:(Packet *)packet
{
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error = nil;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:peerID] withDataMode:dataMode error:&error])
	{
		LOG(@"Error sending data to clients: %@", error);
	}
}

//サーバーから特定のpeerへパケット送信 With performSelector 
- (void)sendPacketToClient:(id)object
{
    LOG_METHOD;
    NSMutableDictionary *dic = (NSMutableDictionary *)object;
    Packet *packet = [dic objectForKey:@"packet"];
    NSData *data = [packet data];
    
    NSString *peerID = [dic objectForKey:@"peerID"];
    LOG(@"送信対象peerID:%@", peerID);
    
	GKSendDataMode dataMode = GKSendDataReliable;
	NSError *error = nil;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:peerID] withDataMode:dataMode error:&error])
	{
		LOG(@"Error sending data to clients: %@", error);
	}
}

//サーバーからクライアントに録画開始パケットを送信
- (void)sendClientToRecordingRequest:(RecordingType)recordingType {
    
    Peer *targetPeer = nil;
    float interval = 0;
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    int startingPos;
    if (app.globalShootingMode == ShootingMode_iPad_iPhone) {
        startingPos = 0;
    } else {
        startingPos = 1;
    }
    
    int i = startingPos;
    
    for (int start = i; start < [_shooters count]; start++) {
        LOG_METHOD;
        LOG(@"撮影デバイスの数:%d", [_shooters count]);
        targetPeer = [_shooters objectAtIndex:start];
        
        Packet *packet = [Packet packetWithType:PacketTypeServerShootingStartRequest];
        NSMutableDictionary *dic = [[[NSMutableDictionary alloc] init] autorelease];
        [dic setObject:packet forKey:@"packet"];
        [dic setObject:targetPeer.peerID forKey:@"peerID"];
        
        if (recordingType == RECORDING_TYPE_SEQUENCIAL) {
            if (start == startingPos) {
                interval = 0;
            } else {
                interval = kRecordingInterval;
            }
        } else {
            interval = 0;
        }

        [self performSelector:@selector(sendPacketToClient:) withObject:dic afterDelay:interval];
        
    }
}

- (void)sendServerToRecordingFinishResponse {
    Packet *packet = [PacketShootingFinishResponse packetWithPeerName:_peerName];
    
    [self sendPacketToServer:packet];
}

//クライアントからサーバーへのパケット送信
- (void)sendPacketToServer:(Packet *)packet
{
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error = nil;
	if (![_session sendData:data toPeers:[NSArray arrayWithObject:_serverPeerID] withDataMode:dataMode error:&error])
	{
		LOG(@"Error sending data to server: %@", error);
	}
}

#pragma mark - Server Shooting Finshed
//iPhone x iPhone モードでサーバーの撮影が終了した
- (void)serverShootingDidFinish {
    self.shootingFinishedClientCount++;
}

@end
