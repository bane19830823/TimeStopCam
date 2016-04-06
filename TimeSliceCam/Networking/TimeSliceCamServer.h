//
//  TimeSliceCamServer.h
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TimeSliceCamServer;

@protocol TimeSliceCamServerDelegate <NSObject>

- (void)timeSliceCamServer:(TimeSliceCamServer *)server clientDidConnect:(NSString *)peerID;
- (void)timeSliceCamServer:(TimeSliceCamServer *)server clientDidDisconnect:(NSString *)peerID;
- (void)timeSliceCamServerSessionDidEnd:(TimeSliceCamServer *)server;
- (void)timeSliceCamServerNoNetwork:(TimeSliceCamServer *)server;

@end

@interface TimeSliceCamServer : NSObject <GKSessionDelegate>

@property (nonatomic, assign) int maxClients;
@property (nonatomic, retain) NSMutableArray *connectedClients;
@property (nonatomic, retain) GKSession *session;
@property (nonatomic, assign) id <TimeSliceCamServerDelegate> delegate;

- (void)startAcceptingConnectionsForSessionID:(NSString *)sessionID;
- (NSUInteger)connectedClientCount;
- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;
- (void)stopAcceptingConnections;
- (void)endSession;

@end
