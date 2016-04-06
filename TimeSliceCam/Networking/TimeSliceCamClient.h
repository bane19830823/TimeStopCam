//
//  TimeSliceCamClient.h
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TimeSliceCamClient;

@protocol TimeSliceCamClientDelegate <NSObject>

- (void)timeSliceCamClient:(TimeSliceCamClient *)client serverBecameAvailable:(NSString *)peerID;
- (void)timeSliceCamClient:(TimeSliceCamClient *)client serverBecameUnavailable:(NSString *)peerID;
- (void)timeSliceCamClient:(TimeSliceCamClient *)client didDisconnectFromServer:(NSString *)peerID;
- (void)timeSliceCamClient:(TimeSliceCamClient *)client didConnectToServer:(NSString *)peerID;
- (void)timeSliceCamClientNoNetwork:(TimeSliceCamClient *)client;
- (void)needRefreshTable;

@end

@interface TimeSliceCamClient : NSObject <GKSessionDelegate>

@property (nonatomic, retain) NSMutableArray *availableServers;
@property (nonatomic, retain) GKSession *session;
@property (nonatomic, assign) id <TimeSliceCamClientDelegate> delegate;

- (void)startSearchingForServersWithSessionID:(NSString *)sessionID;
- (void)connectToServerWithPeerID:(NSString *)peerID;
- (NSUInteger)availableServerCount;
- (NSString *)peerIDForAvailableServerAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;
- (void)disconnectFromServer;


@end
