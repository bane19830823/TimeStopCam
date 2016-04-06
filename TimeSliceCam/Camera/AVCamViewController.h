/*
     File: AVCamViewController.h
 Abstract: A view controller that coordinates the transfer of information between the user interface and the capture manager.
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <UIKit/UIKit.h>
#import "CameraSession.h"
#import <CoreMotion/CoreMotion.h>

@class AVCamCaptureManager, AVCamPreviewView, AVCaptureVideoPreviewLayer, AVCamViewController, MainViewController;

@protocol AVCamViewControllerDelegate <NSObject>

- (void)avCamViewController:(AVCamViewController *)camController didQuitWithReason:(QuitReason)reason;
- (void)avCamViewController:(AVCamViewController *)camController
         didFinishRecordingWithURL:(NSURL *)url
                    session:(GKSession *)session
               serverPeerID:(NSString *)peerID
                   peerName:(NSString *)peerName
                 peerNumber:(NSString *)peerNumber;

- (void)avCamViewController:(AVCamViewController *)camController
startVideoDataTransferWithSesion:(GKSession *)gkSession
                   shooters:(NSMutableArray *)shooters
                   peerName:(NSString *)serverName;

@end

@interface AVCamViewController : UIViewController <UIAlertViewDelegate, CameraSessionDelegate,
UIImagePickerControllerDelegate,UINavigationControllerDelegate, GKSessionDelegate> {
}

@property (nonatomic,assign) id <AVCamViewControllerDelegate> delegate;
@property (nonatomic,retain) CameraSession *cameraSession;
@property (nonatomic,retain) AVCamCaptureManager *captureManager;
@property (nonatomic,retain) IBOutlet UIView *videoPreviewView;
@property (nonatomic,retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (nonatomic,retain) IBOutlet UILabel *focusModeLabel;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *startButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *stopButon;
@property (nonatomic,retain) IBOutlet UILabel *positionLabel;
@property (nonatomic,retain) GKSession *session;
@property (nonatomic,retain) NSString *peerName;
@property (nonatomic,retain) NSString *peerID;
@property (nonatomic,retain) NSString *peerNumber;
@property (nonatomic, retain) NSMutableArray *readyForShootingStateClients;
@property (nonatomic, retain) MainViewController *parentVC;
@property (nonatomic, retain) IBOutlet UIView *controlPanel;
@property (nonatomic, retain) IBOutlet UIToolbar *toolBar;
//加速度センサー関連
@property (nonatomic, retain) CMMotionManager *motionManager;
@property (nonatomic, retain) IBOutlet UILabel *xLabel;
@property (nonatomic, retain) IBOutlet UILabel *yLabel;
@property (nonatomic, retain) IBOutlet UILabel *zLabel;

@end

