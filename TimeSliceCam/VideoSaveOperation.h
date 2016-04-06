//
//  VideoSaveOperation.h
//  TimeSliceCam
//
//  Created by Bane on 12/11/25.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface VideoSaveOperation : NSOperation {
    NSData *photoData;
    ALAssetsLibrary *library;
    NSURL *assetURL;
    int executeNumber;
    BOOL isFinished;
}

@property (nonatomic, retain) NSData *photoData;
@property (nonatomic, retain) ALAssetsLibrary *library;
@property (nonatomic, retain) NSURL *assetURL;
@property (nonatomic, assign) int executeNumber;

- (id)initWithPhotoData:(NSData *)data executeNumber:(int)executeNumber;

@end
