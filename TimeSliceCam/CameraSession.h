//
//  CameraSession.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/10.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

@class CameraSession;

@protocol CameraSessionDelegate <NSObject>

@optional
- (void)cameraSession:(CameraSession *)sesion didQuitReason:(QuitReason)reason;
- (void)camSessionWaitingForServerReady:(CameraSession *)cameraSession;
- (void)camSessionWaitingForClientsReady:(CameraSession *)cameraSession;
- (void)cameraSessionSatrtRecording:(CameraSession *)session;
- (void)cameraSessionDidAllClientFinishShooting:(CameraSession *)sesion
                                   withShooters:(NSMutableArray *)shooters
                                      gkSession:(GKSession *)gkSession
                                       peerName: (NSString *)peerName;


//撮影順番をdelegateに通知する
- (void)cameraSession:(CameraSession *)session setShootingNumber:(NSString *)shootingNumber;

- (void)cameraSession:(CameraSession *)session didReceiveReadyForShootingPacketFromClient:(NSString *)peerID;

//- (void)enableStartButton;
@end

#import <Foundation/Foundation.h>
#import "Peer.h"

@interface CameraSession : NSObject <GKSessionDelegate>

@property (nonatomic, assign) id <CameraSessionDelegate> delegate;
@property (nonatomic, retain) GKSession *session;
@property (nonatomic, retain) NSString *serverPeerID;
@property (nonatomic, retain) NSString *peerName;
@property (nonatomic, retain) NSMutableArray *shooters;
@property (nonatomic, assign) NSInteger shootingFinishedClientCount;


- (void)checkShootingStatus;
- (void)startClientShootingWithSession:(GKSession *)session peerName:(NSString *)name server:(NSString *)peerID;
- (void)startServerShootingWithSession:(GKSession *)session peerName:(NSString *)name clients:(NSArray *)clients;
- (void)quitCameraSessionWithReason:(QuitReason)reason;
- (void)sendClientToRecordingRequest:(RecordingType)recordingType;
- (void)sendServerToRecordingFinishResponse;
- (void)serverShootingDidFinish;

@end
