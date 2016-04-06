//
//  Peer.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/16.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Peer : NSObject

@property (nonatomic, assign) NSInteger peerNumber;   //撮影順番
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *peerID;

@end
