//
//  HostMainViewController.h
//  TimeSliceCam
//
//  Created by Bane on 12/10/14.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HostViewController.h"
#import "CameraSession.h"
#import "HostVideoDataReceiveViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVPlayerViewController.h"


@interface HostMainViewController : UIViewController
<HostViewControllerDelegate, AVPlayerViewControllerDelagate> {

}

@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) IBOutlet UIButton *pickerButton;

- (IBAction)startAction:(id)sender;
- (IBAction)showImagePicker:(UIButton *)sender;


@end
