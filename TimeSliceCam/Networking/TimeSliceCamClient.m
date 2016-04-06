//
//  TimeSliceCamClient.m
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "TimeSliceCamClient.h"

typedef enum {
	ClientStateIdle,
	ClientStateSearchingForServers,
	ClientStateConnecting,
	ClientStateConnected,
} ClientState;

@implementation TimeSliceCamClient {
    NSMutableArray  *_availableServers;
    ClientState     _clientState;
    NSString        *_serverPeerID;
}

@synthesize session = _session;
@synthesize delegate = _delegate;
@synthesize availableServers = _availableServers;

- (void)dealloc {
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"%@", self);
#endif
    
    self.availableServers = nil;
    self.session = nil;
    self.session.delegate = nil;
    _clientState = ClientStateIdle;
    _serverPeerID = nil;
    
    [super dealloc];
}

#pragma mark - Initialize
- (id)init {
	if ((self = [super init])) {
		_clientState = ClientStateIdle;
	}
	return self;
}

#pragma mark - TimeSliceCamClient CustomMethods
- (void)startSearchingForServersWithSessionID:(NSString *)sessionID {
    LOG_METHOD;
    if (_clientState == ClientStateIdle) {
        self.availableServers = [NSMutableArray arrayWithCapacity:10];
        
        self.session = [[GKSession alloc] initWithSessionID:kTimeSliceCamGKSessionID displayName:nil sessionMode:GKSessionModeClient];
        _session.delegate = self;
        _session.available = YES;
        
        _clientState = ClientStateSearchingForServers;
        [self. delegate needRefreshTable];
    }
}

- (void)connectToServerWithPeerID:(NSString *)peerID
{
    LOG_METHOD;
	NSAssert(_clientState == ClientStateSearchingForServers, @"Wrong state");
    
	_clientState = ClientStateConnecting;
	_serverPeerID = peerID;
	[_session connectToPeer:peerID withTimeout:_session.disconnectTimeout];
}

- (void)disconnectFromServer
{
    LOG_METHOD;
//	NSAssert(_clientState != ClientStateIdle, @"Wrong state");
    
	_clientState = ClientStateIdle;
    
	[_session disconnectFromAllPeers];
	_session.available = NO;
	_session.delegate = nil;
	_session = nil;
    
    [_availableServers removeAllObjects];
	_availableServers = nil;
    
    if ([self.delegate respondsToSelector:@selector(timeSliceCamClient:didDisconnectFromServer:)]) {
        [self.delegate timeSliceCamClient:self didDisconnectFromServer:_serverPeerID];

    }
	_serverPeerID = nil;
}

- (NSArray *)availableServers {
    return _availableServers;
}

#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"TimeSliceCamClient: peer %@ changed state %d", peerID, state);
#endif
    switch (state)
	{
            // The client has discovered a new server.
		case GKPeerStateAvailable:
            LOG(@"Client:didFoundServer");
            if (_clientState == ClientStateSearchingForServers) {
                if (![self.availableServers containsObject:peerID]) {
                    [self.availableServers addObject:peerID];
                    LOG(@"%@", self.availableServers);

                    [self.delegate timeSliceCamClient:self serverBecameAvailable:peerID];
                }
            }
			break;
            
            // The client sees that a server goes away.
		case GKPeerStateUnavailable:
            LOG(@"Client:didLostServer");
            if (_clientState == ClientStateSearchingForServers) {
                if ([_availableServers containsObject:peerID])
                {
                    [_availableServers removeObject:peerID];
                    [self.delegate timeSliceCamClient:self serverBecameUnavailable:peerID];
                }
                
                // Is this the server we're currently trying to connect with?
                if (_clientState == ClientStateConnecting && [peerID isEqualToString:_serverPeerID])
                {
                    [SVProgressHUD dismiss];
                    [self disconnectFromServer];
                }
            }
			break;
            
            // You're now connected to the server.
		case GKPeerStateConnected:
            LOG(@"Client:didConnectToServer");
            if (_clientState == ClientStateConnecting) {
                _clientState = ClientStateConnected;
                [self.delegate timeSliceCamClient:self didConnectToServer:peerID];
            }
			break;
            
		case GKPeerStateDisconnected:
            LOG(@"Client:didDisConnectFromServer");
            if (_clientState == ClientStateConnected && [peerID isEqualToString:_serverPeerID]) {
                [SVProgressHUD dismiss];
                [self disconnectFromServer];
            }
			break;
            
		case GKPeerStateConnecting:
			break;
	}
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"TimeSliceCamClient: connection request from peer %@", peerID);
#endif
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"TimeSliceCamClient: connection with peer %@ failed error %@ localizedDiscription %@ failureReason %@", peerID, error, [error localizedDescription], [error localizedFailureReason]);
#endif
    //複数クライアントが同時にサーバーに接続を試みると失敗する事が有るので、接続できなかったら再接続を試みる
    if ([[error domain] isEqualToString:GKSessionErrorDomain]) {
        if ([error code] == GKSessionConnectionFailedError) {
            LOG_METHOD;
            LOG(@"再接続");
            [self connectToServerWithPeerID:_serverPeerID];
        }
    } else {
        [SVProgressHUD dismiss];
        [self disconnectFromServer];
    }
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"TimeSliceCamClient: session failed %@ %@ %@", error, [error localizedDescription], [error localizedFailureReason]);
#endif
    
    [SVProgressHUD dismiss];
	if ([[error domain] isEqualToString:GKSessionErrorDomain])
	{
		if ([error code] == GKSessionCannotEnableError)
		{
			[self.delegate timeSliceCamClientNoNetwork:self];
			[self disconnectFromServer];
		}
	}
}

- (NSUInteger)availableServerCount {
    return [_availableServers count];
}

- (NSString *)peerIDForAvailableServerAtIndex:(NSUInteger)index {
    return [_availableServers objectAtIndex:index];
}

- (NSString *)displayNameForPeerID:(NSString *)peerID {
    return [_session displayNameForPeer:peerID];
}

@end
