//
//  LoadImageOperation.h
//  TimeSliceCam
//
//  Created by Bane on 13/01/14.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface LoadImageOperation : NSOperation {
    NSURL *photoURL;
    UIImage *resultImage;
    ALAssetsLibrary *library;
    int executeNumber;
    BOOL isFinished;
}

@property (nonatomic, retain) NSURL *photoURL;
@property (nonatomic, retain) UIImage *resultImage;
@property (nonatomic, retain) ALAssetsLibrary *library;
@property (nonatomic, assign) int executeNumber;

- (id)initWithPhotoURL:(NSURL *)url executeNumber:(int)executeNumber;

@end
