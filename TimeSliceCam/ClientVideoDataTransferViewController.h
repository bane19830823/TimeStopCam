//
//  ClientVideoDataTransferViewController.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VideoDataTransferSession.h"
#import "MainViewController.h"

@interface ClientVideoDataTransferViewController : UIViewController <VideoDataTransferSessionDelegate> {
    IBOutlet UIButton *sendButton;
}

@property (nonatomic, retain) VideoDataTransferSession *sendSession;
@property (nonatomic, retain) IBOutlet UIImageView *previewView;
@property (nonatomic, retain) MainViewController *mainViewController;


@end
