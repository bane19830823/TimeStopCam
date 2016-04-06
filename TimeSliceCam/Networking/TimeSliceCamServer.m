//
//  TimeSliceCamServer.m
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "TimeSliceCamServer.h"
#import "AppDelegate.h"

typedef enum {
	ServerStateIdle,
	ServerStateAcceptingConnections,
	ServerStateIgnoringNewConnections,
} ServerState;

@implementation TimeSliceCamServer {
    ServerState _serverState;
    NSString *serverPeerID;
}

@synthesize maxClients = _maxClients;
@synthesize session = _session;
@synthesize delegate = _delegate;
@synthesize connectedClients = _connectedClients;

- (void)dealloc {
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"%@", self);
#endif
    self.connectedClients = nil;
    self.session = nil;
    _serverState = ServerStateIdle;
    serverPeerID = nil;
    
    [super dealloc];
}

#pragma mark - Initialize
- (id)init
{
	if ((self = [super init]))
	{
		_serverState = ServerStateIdle;
	}
	return self;
}

#pragma mark - TimeSliceCamServer CustomMethods
- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID {
    LOG_METHOD;
    if (_serverState == ServerStateIdle) {
        self.connectedClients = [[[NSMutableArray alloc] initWithCapacity:self.maxClients] autorelease];
        
        self.session = [[[GKSession alloc] initWithSessionID:sessionID displayName:nil sessionMode:GKSessionModeServer] autorelease];
        self.session.delegate = self;
        self.session.available = YES;
        
        //サーバーのpeerID
        serverPeerID = _session.peerID;
        
        //撮影モードが iPhone x iPhoneの場合、connectedClientの0番目にサーバーをセットする
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (app.globalShootingMode == ShootingMode_iPhone_iPhone) {
            [self.connectedClients addObject:serverPeerID];
        }
        
        _serverState = ServerStateAcceptingConnections;
    }
}


- (void)endSession
{
    LOG_METHOD;
	NSAssert(_serverState != ServerStateIdle, @"Wrong state");
    
	_serverState = ServerStateIdle;
    
	[_session disconnectFromAllPeers];
	_session.available = NO;
	_session.delegate = nil;
	_session = nil;
    
	_connectedClients = nil;
    
	[self.delegate timeSliceCamServerSessionDidEnd:self];
}

- (NSArray *)connectedClients {
    return _connectedClients;
}

- (void)stopAcceptingConnections
{
    LOG_METHOD;
	NSAssert(_serverState == ServerStateAcceptingConnections, @"Wrong state");
    
	_serverState = ServerStateIgnoringNewConnections;
	_session.available = NO;
}

#pragma mark - GKSessionDelagate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state {
#ifdef DEBUG
    LOG(@"TimeSliceCamServer: peer %@ changed state %d", peerID, state);
#endif
    
    switch (state)
	{
		case GKPeerStateAvailable:
			break;
            
		case GKPeerStateUnavailable:
			break;
            
            // A new client has connected to the server.
		case GKPeerStateConnected:
			if (_serverState == ServerStateAcceptingConnections)
			{
				if (![_connectedClients containsObject:peerID])
				{
					[_connectedClients addObject:peerID];
                    LOG_METHOD;
                    LOG(@"connectedClientsCount:%d", [_connectedClients count]);
					[self.delegate timeSliceCamServer:self clientDidConnect:peerID];
				}
			}
			break;
            
            // A client has disconnected from the server.
		case GKPeerStateDisconnected:
			if (_serverState != ServerStateIdle)
			{
				if ([_connectedClients containsObject:peerID])
				{
					[_connectedClients removeObject:peerID];
					[self.delegate timeSliceCamServer:self clientDidDisconnect:peerID];
                    LOG(@"disconnectedPeerID %@", peerID);
                }
			}
			break;
            
		case GKPeerStateConnecting:
			break;
	}
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID {
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"TimeSliceCamServer: connection request from peerID: %@", peerID);
#endif
    
    if (_serverState == ServerStateAcceptingConnections && [self connectedClientCount] < self.maxClients)
	{
		NSError *error = nil;
		if ([session acceptConnectionFromPeer:peerID error:&error])
			LOG(@"TimeSliceCamServer: Connection accepted from peer %@", peerID);
		else
			LOG(@"TimeSliceCamServer: Error accepting connection from peer %@, %@", peerID, error);
	}
	else  // not accepting connections or too many clients
	{
		[session denyConnectionFromPeer:peerID];
	}
}

- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"TimeSliceCamServer: connection with peer %@ failed %@", peerID, error);
#endif
}

- (void)session:(GKSession *)session didFailWithError:(NSError *)error
{
#ifdef DEBUG
    LOG_METHOD;
	LOG(@"MatchmakingServer: session failed %@", error);
#endif
    
	if ([[error domain] isEqualToString:GKSessionErrorDomain])
	{
		if ([error code] == GKSessionCannotEnableError)
		{
			[self.delegate timeSliceCamServerNoNetwork:self];
			[self endSession];
		}
	}
}

- (NSUInteger)connectedClientCount
{
	return [_connectedClients count];
}

- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index
{
	return [_connectedClients objectAtIndex:index];
}

- (NSString *)displayNameForPeerID:(NSString *)peerID
{
	return [_session displayNameForPeer:peerID];
}


@end
