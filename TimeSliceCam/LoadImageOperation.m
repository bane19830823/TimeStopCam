//
//  LoadImageOperation.m
//  TimeSliceCam
//
//  Created by Bane on 13/01/14.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import "LoadImageOperation.h"
#import <AssetsLibrary/AssetsLibrary.h>


@implementation LoadImageOperation

@synthesize photoURL = _photoURL;
@synthesize resultImage = _resultImage;
@synthesize library = _library;
@synthesize executeNumber = _executeNumber;

- (id)initWithPhotoURL:(NSURL *)url executeNumber:(int)exeNumber {
    LOG_METHOD;
    self = [super init];
    if (self) {
        self.photoURL = url;
        self.executeNumber = exeNumber;
        LOG(@"photoURL:%@, executeNumber:%d", self.photoURL, self.executeNumber);
        self.library = [[ALAssetsLibrary alloc] init];
    }
    isFinished = NO;
    return self;
}

- (void)dealloc {
    LOG(@"dealloc:%@", self);
    self.photoURL = nil;
    self.resultImage = nil;
    self.library = nil;
    
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
    //ライブラリから写真を取得
    LOG(@"%@", self.photoURL);
    if(self.photoURL)
    {
        [self.library assetForURL:self.photoURL
                      resultBlock:^(ALAsset *myasset) {
                          ALAssetRepresentation *representation = [myasset defaultRepresentation];
                          UIImage *img = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                                             scale:[representation scale]
                                                       orientation:[representation orientation]];
                          
                          self.resultImage = img;
                          
                          LOG_METHOD;
                          LOG(@"finishedPickingImage");
                          [self willChangeValueForKey:@"isFinished"];
                          [self setValue:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                          [self didChangeValueForKey:@"isFinished"];
                          
                      }
                     failureBlock:^(NSError *myerror) {
                         LOG_METHOD;
                         LOG(@"Failed To Get Image From Library - %@",[myerror localizedDescription]);
                         LOG(@"Failed To Get Image From Library - %@",[myerror localizedFailureReason]);
                         [self willChangeValueForKey:@"isFinished"];
                         [self setValue:[NSNumber numberWithBool:YES] forKey:@"isFinished"];
                         [self didChangeValueForKey:@"isFinished"];
                     }];
    } else {
        LOG(@"photoURL is nil");
    }
    LOG(@"not finished yet here");
}


@end
