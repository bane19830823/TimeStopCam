//
//  VideoDataSendSession.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/28.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "VideoDataTransferSession.h"
#import "Packet.h"
#import "PacketVideoDataSender.h"
#import "Peer.h"
#import "VideoData.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppDelegate.h"

@implementation VideoDataTransferSession {
    int _sendPacketNumber;
    int receivedVideoCount;

}

@synthesize session = _session;
@synthesize url = _url;
@synthesize serverPeerID = _serverPeerID;
@synthesize peerName = _peerName;
@synthesize peerNumber = _peerNumber;
@synthesize delegate = _delegate;
@synthesize needToReceiveVidoes = _needToReceiveVidoes;
@synthesize photoDataArray = _photoDataArray;

#pragma mark - ClientSide Initialize
- (void)startClientVideoTransferSessionWithGKSession:(GKSession *)session
                                 videoURL:(NSURL *)url
                                    server:(NSString *)serverPeerID
                                  peerName:(NSString *)peerName
                                peerNumber:(NSString *)peerNumber {
    
    LOG_METHOD;
    
    _session = session;
    _session.available = NO;
    _session.delegate = self;
    [_session setDataReceiveHandler:self withContext:nil];
    
    _url = url;
    
    _serverPeerID = serverPeerID;
    _peerName = peerName;
    _peerNumber = peerNumber;
    
    if ([self.delegate respondsToSelector:@selector(showVideoPreview:)]) {
        [self.delegate showVideoPreview:url];
    }
}

#pragma mark - ServerSide Initialize
- (void)startServerVideoTransferSessionWithGKSession:(GKSession *)session
                                        withShooters:(NSMutableArray *)shooters
                                              server:(NSString *)serverName {
    
    LOG_METHOD;
    self.photoDataArray = [[NSMutableArray alloc] initWithCapacity:0];

    //クライアントから受信したビデオデータ用のDic
    self.videoDataDic = [[NSMutableDictionary alloc] initWithCapacity:[shooters count]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.needToReceiveVidoes = [shooters count] - 1;
    } else {
        self.needToReceiveVidoes = [shooters count];
    }
    receivedVideoCount = 0;

    
    int start = 0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        start = 1;
    }
    for (int i = start; i < [shooters count]; i++) {
        VideoData *videoData = [[[VideoData alloc] init] autorelease];
        videoData.didCompleteData = NO;
        Peer *peer = [shooters objectAtIndex:i];
        LOG(@"peer:%@", [peer description]);
        [self.videoDataDic setObject:videoData forKey:[NSString stringWithFormat:@"%d", i]];
    }
    
    _session = session;
    _session.available = NO;
    _session.delegate = self;
    [_session setDataReceiveHandler:self withContext:nil];
    
    self.shooters = shooters;
    if ([self.delegate respondsToSelector:@selector(needRefleshTable)]) {
        [self.delegate needRefleshTable];
    }
    
    //サーバでデータ受信準備ができたので、クライアントの送信ボタンを操作出来るようにする。
    Packet *packet = [Packet packetWithType:PacketTypeReadyForReceiveData];
    [self sendPacketToAllClients:packet];
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"VideoSendDataSession: peer %@ changed state %d", peerID, state);
#endif
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"VideoSendDataSession: connection request from peer %@", peerID);
#endif
    
	[session denyConnectionFromPeer:peerID];
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"VideoSendDataSession: connection with peer %@ failed %@", peerID, error);
#endif
    
	// Not used.
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
    LOG_METHOD;
#ifdef DEBUG
	LOG(@"VideoSendDataSession: session failed %@", error);
#endif
}

#pragma mark - Networking
//NSDataを50kbずつに分割してサーバーに送信する
- (void)sendVideoDataToServer:(NSData *)data {
    
    [SVProgressHUD showWithStatus:kMessageSendPhotoDataToServer];
    LOG_METHOD;
    LOG(@"Photo Data Length:%d", [data length]);
    
    //1回に送信するデータ量(50kb)
    NSUInteger fiftyK = 51200;
    
    //1回に送信するデータ
    NSData *dataToSend = nil;
    NSRange range = NSMakeRange(0, 0);
    
    int numOfPackets = 0;
    int sendCount = 0;

    for (NSUInteger i = 0; i < data.length; i += fiftyK) {
        numOfPackets++;
        LOG(@"Client 送信するパケット数:%d", numOfPackets);
    }
    
    for (NSUInteger i = 0; i < data.length; i += fiftyK) {
        //余りデータ(50kb以下)
        if (i + fiftyK > data.length) {
            range = NSMakeRange(i, data.length - i);
        } else {
            range = NSMakeRange(i, fiftyK);
        }
        dataToSend = [data subdataWithRange:range];
        
        LOG_METHOD;
        LOG(@"Client: sendData Length:%d", [dataToSend length]);
        
        //send 'dataToSend'
        Packet *packet =
        [PacketVideoDataSender packetWithPeerNumber:self.peerNumber
                                    numberOfPackets:[NSString stringWithFormat:@"%d", numOfPackets]
                                          videoData:dataToSend];
        
        [self sendPacketToServer:packet];
        sendCount++;
        
        if (sendCount == numOfPackets) {
            [SVProgressHUD showSuccessWithStatus:kMessageSendPhotoDataToServerSucceed];
            
            if ([self.delegate respondsToSelector:@selector(dataTransferFinished)]) {
                [self.delegate dataTransferFinished];
            }
        }
    }
}

//クライアントからサーバーへのパケット送信
- (void)sendPacketToServer:(Packet *)packet
{
    if (packet.packetNumber != -1) {
		packet.packetNumber = _sendPacketNumber++;
        GKSendDataMode dataMode = GKSendDataReliable;
        NSData *data = [packet data];
        NSError *error = nil;
        if (![_session sendData:data toPeers:[NSArray arrayWithObject:_serverPeerID] withDataMode:dataMode error:&error])
        {
            LOG(@"Error sending data to server: %@", error);
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:kMessageSendPhotoDataToServerFailed];
        }
    }
}

//サーバーからすべてのpeerへ一斉送信
- (void)sendPacketToAllClients:(Packet *)packet
{
    LOG_METHOD;
	GKSendDataMode dataMode = GKSendDataReliable;
	NSData *data = [packet data];
	NSError *error = nil;
	if (![_session sendDataToAllPeers:data withDataMode:dataMode error:&error])
	{
		LOG(@"Error sending data to clients: %@", error);
	}
}

#pragma mark - GKSession Data Receive Handler

//データ受信
- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context
{
#ifdef DEBUG
	LOG(@"VideoDataTransferSession: receive data from peer: %@, data: %@, length: %d", peerID, data, [data length]);
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
        }
    } else {
		[self clientReceivedPacket:packet];
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


//サーバーでパケット受信
- (void)serverReceivedPacket:(Packet *)packet fromPeer:(Peer *)peer
{
    LOG_METHOD;
	switch (packet.packetType)
	{
            
        case PacketTypeSendMovieData:
        {
            //写真データ受信開始
            //インジケータstart
            if (receivedVideoCount == 0) {
                [SVProgressHUD showWithStatus:kMessageReceivingPhotoData];
            }
            VideoData *videoData = [self.videoDataDic objectForKey:[NSString stringWithFormat:@"%d", peer.peerNumber]];
            [videoData.videoDataDic setObject:((PacketVideoDataSender *)packet).videoData
                                       forKey:[NSString stringWithFormat:@"%d",packet.packetNumber]];
            LOG(@"receivedVideo From PeerNumber:%d packetNumber%d", peer.peerNumber, packet.packetNumber);

            NSString *numberOfPackets = ((PacketVideoDataSender *)packet).numberOfPackets;
            LOG(@"Server:受信すべきパケット数:%@", numberOfPackets);
            videoData.receivedCount++;
            
            //あるクライアントが送信したパケットを全て受け取った
            LOG(@"videoData.receivedCount:%d", videoData.receivedCount);
            if ([numberOfPackets intValue] == videoData.receivedCount) {
                [videoData sortVideoData];
                
                receivedVideoCount++;
                videoData.didCompleteData = YES;
                
                //テーブルデータを更新する
                if ([self.delegate respondsToSelector:
                     @selector(needRefleshTable)]) {
                    [self.delegate needRefleshTable];
                }
                [self checkReceiveProgress];
            }
        }
            break;
		default:
			LOG(@"Server received unexpected packet: %@", packet);
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:@"Received Unexpected Data From Client."];
			break;
	}
}

//クライアントでパケット受信
- (void)clientReceivedPacket:(Packet *)packet
{
    LOG_METHOD;
	switch (packet.packetType) {
        case PacketTypeReadyForReceiveData:
            [self.delegate readyForSendData];
            break;
        default:
            break;
    }
}

- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index
{
    Peer *peer = [_shooters objectAtIndex:index];
	return peer.peerID;
}

- (NSString *)peerNumberForPeerID:(NSString *)peerID {
    Peer *targetPeer = nil;
    for (int i = 0; i < [_shooters count]; i++) {
        Peer *p = [_shooters objectAtIndex:i];
        if ([p.peerID isEqualToString:peerID]) {
            targetPeer = p;
        }
    }
    return [NSString stringWithFormat:@"%d", targetPeer.peerNumber];
}

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [_session displayNameForPeer:peerID];
}

- (void)checkReceiveProgress {
    LOG_METHOD;

    if (receivedVideoCount == _needToReceiveVidoes) {
        [self saveVideoToLibrary];

    }
}

- (void)saveVideoToLibrary {
    LOG_METHOD;

    int start = 0;
    int end = [_videoDataDic count];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        start = 1;
        end = [_videoDataDic count] + 1;
    }
    for (int i = start; i < end; i++) {
        LOG(@"videoの数:%d", end);
        VideoData *videoData = [_videoDataDic objectForKey:[NSString stringWithFormat:@"%d", i]];
        LOG(@"受け取ったビデオのlength:%d", [videoData.completeVideo length]);
        
//        [self saveFileToDocuments:videoData.completeVideo withNumber:i];
        [self.photoDataArray addObject:videoData.completeVideo];
    }
    if ([self.delegate respondsToSelector:@selector(videoDataTranserSession:didEndSessionWithPhotoDataArray:)]) {
        [self.delegate videoDataTranserSession:self didEndSessionWithPhotoDataArray:self.photoDataArray];
    }
}

- (void)saveFileToDocuments:(NSData *)videoData withNumber:(NSInteger)number {
    LOG_METHOD;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	NSString *destinationPath =
    [documentsDirectory stringByAppendingFormat:@"/output%@-%d.jpg", [dateFormatter stringFromDate:[NSDate date]], number];
    
    [self.videoURLDic setObject:destinationPath forKey:[NSString stringWithFormat:@"%d", number]];
    
    BOOL success = [videoData writeToFile:destinationPath atomically:YES];
    if (!success) {
        LOG_METHOD;
        LOG(@"VideoSave Failed");
    } else {
        LOG(@"ビデオsaveOK:documentsDir:%@", destinationPath);
    }
}

- (void)removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {
            
        }
    }
}

@end
