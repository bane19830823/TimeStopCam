//
//  AVPlayerView.m
//  TimeSliceCam
//
//  Created by Bane on 12/12/05.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "AVPlayerView.h"
#import <AVFoundation/AVFoundation.h>

@implementation AVPlayerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/**
 * レイヤーのクラス情報を取得します。
 *
 * @return レイヤー。
 */
+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
