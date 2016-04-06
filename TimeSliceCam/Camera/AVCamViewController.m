/*
     File: AVCamViewController.m
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

#import "AVCamViewController.h"
#import "AVCamCaptureManager.h"
#import "AVCamRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "Packet.h"
#import "CameraSession.h"
#import "MainViewController.h"
#import "AppDelegate.h"
#import <CoreMotion/CoreMotion.h>

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface AVCamViewController () <UIGestureRecognizerDelegate>
- (void)stopRecording;
@end

@interface AVCamViewController (InternalMethods)
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;

@end

@interface AVCamViewController (AVCamCaptureManagerDelegate) <AVCamCaptureManagerDelegate>
@end

@implementation AVCamViewController

@synthesize captureManager;
@synthesize focusModeLabel;
@synthesize videoPreviewView;
@synthesize captureVideoPreviewLayer;
@synthesize session =  _session;
@synthesize peerName = _peerName;
@synthesize peerID = _peerID;
@synthesize delegate = _delegate;
@synthesize cameraSession = _cameraSession;
@synthesize positionLabel;
@synthesize startButton;
@synthesize stopButon;
@synthesize peerNumber = _peerNumber;
@synthesize readyForShootingStateClients = _readyForShootingStateClients;
@synthesize parentVC = _parentVC;
@synthesize controlPanel;
@synthesize toolBar;
@synthesize motionManager = _motionManager;
@synthesize xLabel;
@synthesize yLabel;
@synthesize zLabel;


#pragma mark - AutoRotation Support Methods

#pragma mark  iOS 6 or later
// iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        // iPhone がサポートする向き
        return //UIInterfaceOrientationMaskPortrait +
        UIInterfaceOrientationMaskLandscapeRight;
    }
    
    // iPad がサポートする向き
    return UIInterfaceOrientationMaskAll;
}
- (BOOL)shouldAutorotate
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        // iPhone
        return YES;
    }
    
    return YES;
}
#endif

#pragma mark  Before iOS 6
// iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ((interfaceOrientation == UIInterfaceOrientationPortrait)
        || (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    return NO;
}
#endif

#pragma mark - AVCamViewController Methods
//サーバーのビデオが撮影終了
- (void)stopRecording {
    [[self captureManager] stopRecording];
    
    //サーバー(iPhone/Touch)の場合、クライアントに撮影指令を送る
    [self.cameraSession sendClientToRecordingRequest:RECORDING_TYPE_SIMULTANEOUS];
}

- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = NSLocalizedString(@"locked", @"CameraFocusLocked");
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = NSLocalizedString(@"auto", @"CameraFocusAuto") ;
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = NSLocalizedString(@"continuous", @"CameraFocusContinuous");
			break;
	}
	
	return focusString;
}

- (void)dealloc
{
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"%@", self);
#endif
    
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode"];
	[captureManager release], captureManager = nil;
    [videoPreviewView release], videoPreviewView = nil;
	[captureVideoPreviewLayer release], captureVideoPreviewLayer = nil;
	[focusModeLabel release], focusModeLabel = nil;
    [positionLabel release], positionLabel = nil;
    [startButton release], startButton = nil;
    [stopButon release], stopButon = nil;
    self.readyForShootingStateClients = nil;
    self.parentVC = nil;
    self.controlPanel = nil;
    self.toolBar = nil;
    [self.motionManager stopAccelerometerUpdates];
    self.motionManager = nil;
    self.xLabel = nil;
    self.yLabel = nil;
    self.zLabel = nil;
	
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [SVProgressHUD dismiss];
    
    //加速度センサー
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.accelerometerUpdateInterval = 10.0 / 60.0; //CMMotionManagerが１秒に何回データを取得するか指定する
    
    NSOperationQueue *opQueue = [[[NSOperationQueue alloc] init] autorelease];
    [self.motionManager startAccelerometerUpdatesToQueue:opQueue
                                             withHandler:^(CMAccelerometerData *data, NSError *error) {
                                                 
                                                 //新しい加速度のデータを取得する度にこのブロックを実行する
                                                 
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     self.xLabel.text = [NSString stringWithFormat:@"%.02f", data.acceleration.x];
                                                     self.yLabel.text = [NSString stringWithFormat:@"%.02f", data.acceleration.y];
                                                     self.zLabel.text = [NSString stringWithFormat:@"%.02f", data.acceleration.z];
                                                 });
                                             }];

    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableArray *items = [NSMutableArray arrayWithArray:[self.toolBar items]];
    
    if (app.isServer) {
        if ([UIScreen is4inch]) {
            [items removeObjectAtIndex:0];
            [items removeObjectAtIndex:0];
            [items removeObjectAtIndex:0];
            
            [self.toolBar setItems:items];
            
            controlPanel.frame = CGRectMake(480, 0, 88, 300);
            [self.view addSubview:controlPanel];
        }
    } else {
        [items removeObjectAtIndex:0];
        [items removeObjectAtIndex:0];
        [items removeObjectAtIndex:0];
        
        [self.toolBar setItems:items];
        
        self.positionLabel.text = @"";
    }
    
	if ([self captureManager] == nil) {
		AVCamCaptureManager *manager = [[AVCamCaptureManager alloc] init];
		[self setCaptureManager:manager];
		[manager release];
		
		[[self captureManager] setDelegate:self];

		if ([[self captureManager] setupSession]) {
            // Create video preview layer and add it to the UI
			AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[[self captureManager] session]];
			UIView *view = [self videoPreviewView];
			CALayer *viewLayer = [view layer];
			[viewLayer setMasksToBounds:YES];
			
			CGRect bounds = [view bounds];
			[newCaptureVideoPreviewLayer setFrame:bounds];
            
            if ([newCaptureVideoPreviewLayer respondsToSelector:@selector(connection)])
            {
                if ([newCaptureVideoPreviewLayer.connection isVideoOrientationSupported])
                {
                    [newCaptureVideoPreviewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                }
            }
            else
            {
                // Deprecated in 6.0; here for backward compatibility
                if ([newCaptureVideoPreviewLayer isOrientationSupported])
                {
                    [newCaptureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationLandscapeRight];
                }                
            }

			
			[newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
			
			[viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
			
			[self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
            [newCaptureVideoPreviewLayer release];
			
            // Start the session. This is done asychronously since -startRunning doesn't return until the session is running.
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				[[[self captureManager] session] startRunning];
			});
			
//            [self updateButtonStates];
			
            // Create the focus mode UI overlay
			UILabel *newFocusModeLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, viewLayer.bounds.size.width - 20, 20)];
			[newFocusModeLabel setBackgroundColor:[UIColor clearColor]];
			[newFocusModeLabel setTextColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.50]];
			AVCaptureFocusMode initialFocusMode = [[[captureManager videoInput] device] focusMode];
			[newFocusModeLabel setText:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"focus:", @"CameraFocusString"),
                                        [self stringForFocusMode:initialFocusMode]]];
			[view addSubview:newFocusModeLabel];
			[self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
			[self setFocusModeLabel:newFocusModeLabel];
            [newFocusModeLabel release];
            
            // Add a single tap gesture to focus on the point tapped, then lock focus
			UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
			[singleTap setDelegate:self];
			[singleTap setNumberOfTapsRequired:1];
			[view addGestureRecognizer:singleTap];
			
            // Add a double tap gesture to reset the focus mode to continuous auto focus
			UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
			[doubleTap setDelegate:self];
			[doubleTap setNumberOfTapsRequired:2];
			[singleTap requireGestureRecognizerToFail:doubleTap];
			[view addGestureRecognizer:doubleTap];
			
			[doubleTap release];
			[singleTap release];
		}		
	}
		
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (app.isServer) {
            self.positionLabel.text = @"1";
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCamFocusModeObserverContext) {
        // Update the focus UI overlay string when the focus mode changes
		[focusModeLabel setText:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"focus:", @"CameraFocusString"), [self stringForFocusMode:(AVCaptureFocusMode)[[change objectForKey:NSKeyValueChangeNewKey] integerValue]]]];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -  Button Actions

- (IBAction)exitAction:(id)sender {
    [self.cameraSession quitCameraSessionWithReason:QuitReasonUserQuit];
}

//最初にサーバーで撮影を始めるメソッド
- (IBAction)startShootingOnServer:(id)sender {
    [self cameraSessionSatrtRecording:nil];
}

//サーバーの撮影を止めてクライアントの撮影を始めるメソッド
- (IBAction)stopServerShootingAndStartClientShooting:(id)sender {
    [self stopRecording];
}

//- (IBAction)toggleCamera:(id)sender
//{
//    // Toggle between cameras when there is more than one
//    [[self captureManager] toggleCamera];
//    
//    // Do an initial focus
//    [[self captureManager] continuousFocusAtPoint:CGPointMake(.5f, .5f)];
//}

//- (IBAction)toggleRecording:(id)sender
//{
//    // Start recording if there isn't a recording running. Stop recording if there is.
//    [[self recordButton] setEnabled:NO];
//    if (![[[self captureManager] recorder] isRecording])
//        [[self captureManager] startRecording];
//    else
//        [[self captureManager] stopRecording];
//}

//- (IBAction)connectWithGKSession:(id)sender {
//
//}
- (void)cameraSession:(CameraSession *)sesion didQuitReason:(QuitReason)reason {
    [self.delegate avCamViewController:self didQuitWithReason:reason];
}

#pragma mark - Capture Still Image
- (void)captureStillImage
{
    LOG_METHOD;
    // Capture a still image

    [[self captureManager] captureStillImage];
    
    // Flash the screen white and fade it out to give UI feedback that a still image was taken
//    UIView *flashView = [[UIView alloc] initWithFrame:[[self videoPreviewView] frame]];
    UIView *flashView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen getScreentWidth], [UIScreen getScreenHeight])];
    [flashView setBackgroundColor:[UIColor whiteColor]];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:flashView];
    
    [UIView animateWithDuration:.4f
                     animations:^{
                         [flashView setAlpha:0.f];
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                         [flashView release];
                     }
     ];
}

@end

@implementation AVCamViewController (InternalMethods)

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates 
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self videoPreviewView] frame].size;
    
//    if ([captureVideoPreviewLayer isMirrored]) {
//        viewCoordinates.x = frameSize.width - viewCoordinates.x;
//    }
    
    if ([captureVideoPreviewLayer respondsToSelector:@selector(connection)])
    {
        if ([captureVideoPreviewLayer.connection isVideoMirrored])
        {
            viewCoordinates.x = frameSize.width - viewCoordinates.x;
        }
    }
    else
    {
        // Deprecated in 6.0; here for backward compatibility
        if ([captureVideoPreviewLayer isMirrored])
        {
            viewCoordinates.x = frameSize.width - viewCoordinates.x;
        }
    }

    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;

                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:[self videoPreviewView]];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [captureManager autoFocusAtPoint:convertedFocusPoint];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    if ([[[captureManager videoInput] device] isFocusPointOfInterestSupported])
        [captureManager continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

// Update button states based on the number of available cameras and mics
//- (void)updateButtonStates
//{
//	NSUInteger cameraCount = [[self captureManager] cameraCount];
//	NSUInteger micCount = [[self captureManager] micCount];
//    
//    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
//        if (cameraCount < 2) {
//            [[self cameraToggleButton] setEnabled:NO]; 
//            
//            if (cameraCount < 1) {
////                [[self stillButton] setEnabled:NO];
//                
//                if (micCount < 1)
//                    [[self recordButton] setEnabled:NO];
//                else
//                    [[self recordButton] setEnabled:YES];
//            } else {
////                [[self stillButton] setEnabled:YES];
//                [[self recordButton] setEnabled:YES];
//            }
//        } else {
//            [[self cameraToggleButton] setEnabled:YES];
////            [[self stillButton] setEnabled:YES];
//            [[self recordButton] setEnabled:YES];
//        }
//    });
//}

@end

#pragma mark - AVCamCaptureManagerDelegate
@implementation AVCamViewController (AVCamCaptureManagerDelegate)

- (void)captureManager:(AVCamCaptureManager *)captureManager didFailWithError:(NSError *)error
{
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    });
}

- (void)captureManagerRecordingBegan:(AVCamCaptureManager *)captureManager
{
}

//録画終了
- (void)captureManagerRecordingFinished:(AVCamCaptureManager *)manager
{
    LOG_METHOD;
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        NSURL *url = manager.recorder.outputFileURL;
        
        if ([self.delegate respondsToSelector:@selector(avCamViewController:didFinishRecordingWithURL:session:serverPeerID:peerName:peerNumber:)]) {
            [self.delegate avCamViewController:self
                     didFinishRecordingWithURL:url
                                       session:_cameraSession.session
                                  serverPeerID:_cameraSession.serverPeerID
                                      peerName:_cameraSession.peerName
                                    peerNumber:self.peerNumber];
            
        }
        [self.cameraSession serverShootingDidFinish];
        [self.cameraSession checkShootingStatus];
    });
}

//クライアントで、写真撮影が終わった時にコールされるデリゲートメソッド
- (void)captureManagerStillImageCaptured:(AVCamCaptureManager *)captureManager withURL:(NSURL *)url
{
    LOG_METHOD;
    LOG(@"pictureURL:%@", url);

    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        
        if ([self.delegate respondsToSelector:@selector(avCamViewController:didFinishRecordingWithURL:session:serverPeerID:peerName:peerNumber:)]) {
            [self.delegate avCamViewController:self
                     didFinishRecordingWithURL:url
                                       session:_cameraSession.session
                                  serverPeerID:_cameraSession.serverPeerID
                                      peerName:_cameraSession.peerName
                                    peerNumber:self.peerNumber];
            
        }
        
        //クライアントの場合、撮影終了後にサーバーに通知する
        AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        if (app.isServer == NO) {
            [_cameraSession sendServerToRecordingFinishResponse];
        }

    });
}

- (void)captureManagerDeviceConfigurationChanged:(AVCamCaptureManager *)captureManager
{
//	[self updateButtonStates];
}

#pragma mark - CameraSession delegate

- (void)cameraSession:(CameraSession *)session didQuitWithReason:(QuitReason)reason {
    [self.delegate avCamViewController:self didQuitWithReason:reason];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)camSessionWaitingForServerReady:(CameraSession *)cameraSession {
    
}
#pragma clang diagnostic pop

//撮影開始
- (void)cameraSessionSatrtRecording:(CameraSession *)session {
    
    LOG(@"Start Shooing");
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //加速度取得停止
        [self.motionManager stopAccelerometerUpdates];
        if (app.isServer) {
            [[self captureManager] startRecording];
        } else {
            [self captureStillImage];
        }
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

#pragma mark - CameraSession delegate
//撮影順番を表示
- (void)cameraSession:(CameraSession *)session setShootingNumber:(NSString *)shootingNumber {
    LOG_METHOD;
    self.peerNumber = shootingNumber;
    
    int s = [shootingNumber intValue] + 1;
    self.positionLabel.text = [NSString stringWithFormat:@"%d", s];
}
#pragma clang diagnostic pop

- (void)cameraSessionDidAllClientFinishShooting:(CameraSession *)sesion
                                   withShooters:(NSMutableArray *)shooters
                                      gkSession:(GKSession *)gkSession
                                       peerName:(NSString *)peerName {
    
    if ([self.delegate respondsToSelector:@selector(avCamViewController:startVideoDataTransferWithSesion:shooters:peerName:)]) {
        [self.delegate avCamViewController:self
          startVideoDataTransferWithSesion:gkSession
                                  shooters:shooters
                                  peerName:peerName];
    }
}

- (void)cameraSession:(CameraSession *)session didReceiveReadyForShootingPacketFromClient:(NSString *)peerID {
    LOG_METHOD;
    [self.readyForShootingStateClients addObject:peerID];
}


@end
