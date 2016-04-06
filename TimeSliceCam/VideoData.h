//
//  VideoData.h
//  TimeSliceCam
//
//  Created by Bane on 12/11/10.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoData : NSObject

@property (nonatomic, retain) NSMutableData *completeVideo;
@property (nonatomic, retain) NSString *numberOfPackets;
@property (nonatomic, retain) NSMutableDictionary *videoDataDic;
@property (nonatomic, assign) BOOL didCompleteData;
@property (nonatomic, assign) NSInteger receivedCount;

- (void)sortVideoData;

@end
