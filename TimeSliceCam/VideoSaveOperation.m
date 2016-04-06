//
//  VideoSaveOperation.m
//  TimeSliceCam
//
//  Created by Bane on 12/11/25.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "VideoSaveOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation VideoSaveOperation

@synthesize photoData = _photoData;
@synthesize assetURL = _assetURL;
@synthesize library = _library;
@synthesize executeNumber = _executeNumber;

- (id)initWithPhotoData:(NSData *)data executeNumber:(int)exeNumber {
    LOG_METHOD;
    self = [super init];
    if (self) {
        self.photoData = data;
        self.executeNumber = exeNumber;
        self.library = [[ALAssetsLibrary alloc] init];
    }
    isFinished = NO;
    return self;
}

- (void)dealloc {
    LOG(@"dealloc:%@", self);
    [_photoData release], _photoData = nil;
    [_library release], _library = nil;
    [_assetURL release], _assetURL = nil;
    [super dealloc];
}

// YES を返さないとメインスレッド以外で動かなくなる
- (BOOL)isConcurrent {
    LOG_METHOD;
    return NO;
}

- (BOOL)isFinished {
    return isFinished;
}

- (void)main {
    LOG_METHOD;
    
    [_library writeImageDataToSavedPhotosAlbum:self.photoData
                                      metadata:nil
                               completionBlock:^(NSURL *savedAssetURL, NSError *error) {
                                   if (error) {
                                       LOG(@"%@", error);
                                       LOG(@"AssetLibrary保存エラー localizedDescription:%@", [error localizedDescription]);
                                       LOG(@"AssetLibrary保存エラー localizedFailureReason:%@", [error localizedFailureReason]);
                                       LOG(@"AssetLibrary保存エラーコード:%d", [error code]);
                                       
                                       LOG(@"failToSaveVideo");
                                       [self willChangeValueForKey:@"isFinished"];
                                       [self setValue:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                                       [self didChangeValueForKey:@"isFinished"];

                                   } else {
                                       LOG(@"AssetLibrary保存完了");
                                       self.assetURL = savedAssetURL;
                                       LOG(@"savedAssetURL:%@", self.assetURL);
                                       
                                       [self willChangeValueForKey:@"isFinished"];
                                       [self setValue:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                                       [self didChangeValueForKey:@"isFinished"];
                                   }
                               }];
    
    LOG_METHOD;
    LOG(@"Not finished yet here!!");
}

@end
