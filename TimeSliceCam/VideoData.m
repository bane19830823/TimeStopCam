//
//  VideoData.m
//  TimeSliceCam
//
//  Created by Bane on 12/11/10.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "VideoData.h"

@implementation VideoData

@synthesize completeVideo = _completeVideo;
@synthesize numberOfPackets = _numberOfPackets;
@synthesize videoDataDic = _videoDataDic;
@synthesize didCompleteData = _didCompleteData;
@synthesize receivedCount = _receivedCount;

- (id)init {
    if (self = [super init]) {
        self.completeVideo = [[NSMutableData alloc] init];
        self.numberOfPackets = 0;
        self.videoDataDic = [[NSMutableDictionary alloc] init];
        self.didCompleteData = NO;
        self.receivedCount = 0;
    }
    return self;
}

- (void)sortVideoData {
    LOG_METHOD;

    for (int i = 0; i < [_videoDataDic count]; i++) {
        NSData *data = [_videoDataDic objectForKey:[NSString stringWithFormat:@"%d", i]];
        LOG(@"videoData Length:%d", [data length]);
        [self.completeVideo appendData:data];
    }
}

- (void)dealloc {
    [_completeVideo release], _completeVideo = nil;
    [_numberOfPackets release], _numberOfPackets = nil;
    [_videoDataDic release], _videoDataDic = nil;
    
    [super dealloc];
}

@end
