//
//  VideoDataSendSession.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/28.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VideoDataTransferSession;
@class Peer;
@class VideoData;

@protocol VideoDataTransferSessionDelegate <NSObject>

@optional
// Client - ビデオプレビューViewを表示
- (void)showVideoPreview:(NSURL *)url;

//データ送信完了
- (void)dataTransferFinished;

// Server
- (void)needRefleshTable;

- (void)videoDataTranserSession:(VideoDataTransferSession *)session
     didEndSessionWithPhotoDataArray:(NSArray *)photoDataArray;

- (void)readyForSendData;

@end

@interface VideoDataTransferSession : NSObject <GKSessionDelegate> {
}

@property (nonatomic, retain) GKSession *session;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *serverPeerID;
@property (nonatomic, retain) NSString *peerName;
@property (nonatomic, retain) NSString *peerNumber;
@property (nonatomic, retain) NSMutableArray *shooters;
@property (nonatomic, assign) id <VideoDataTransferSessionDelegate> delegate;
@property (nonatomic, retain) NSMutableDictionary *videoDataDic;
@property (nonatomic, assign) int needToReceiveVidoes;
@property (nonatomic, retain) NSMutableDictionary *videoURLDic;
@property (nonatomic, retain) NSMutableArray *photoDataArray;

- (void)startClientVideoTransferSessionWithGKSession:(GKSession *)session
                                 videoURL:(NSURL *)url
                                    server:(NSString *)serverPeerID
                                  peerName:(NSString *)peerName
                                peerNumber:(NSString *)peerNumber;

- (void)startServerVideoTransferSessionWithGKSession:(GKSession *)session
                                        withShooters:(NSMutableArray *)shooters
                                              server:(NSString *)serverName;


- (void)sendVideoDataToServer:(NSData *)data;
- (NSString *)peerIDForConnectedClientAtIndex:(NSUInteger)index;
- (NSString *)displayNameForPeerID:(NSString *)peerID;
- (NSString *)peerNumberForPeerID:(NSString *)peerID;

@end
