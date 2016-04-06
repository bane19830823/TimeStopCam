//
//  HostMainViewController.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/14.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "HostMainViewController.h"
#import "HostViewController.h"
#import "CameraSession.h"
#import "VideoDataTransferSession.h"
#import "HostVideoDataReceiveViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AVPlayerViewController.h"
#import "AppDelegate.h"

@interface HostMainViewController ()
@property (nonatomic, retain) HostViewController *hostViewController;
@property (nonatomic, retain) CameraSession *camSession;
@property (nonatomic, retain) HostVideoDataReceiveViewController *videoReceiveVC;
@property (nonatomic, retain) UIPopoverController *popOverController;

//AVPlayer
@property (nonatomic, retain) AVPlayerViewController *avPlayerViewController;


@end

@implementation HostMainViewController

@synthesize startButton = _startButton;
@synthesize hostViewController = _hostViewController;
@synthesize camSession = _camSession;
@synthesize videoReceiveVC = _videoReceiveVC;
@synthesize popOverController = _popOverController;
@synthesize avPlayerViewController = _avPlayerViewController;

- (void)dealloc {
    [_popOverController release], _popOverController = nil;
    [_avPlayerViewController release], _avPlayerViewController = nil;

    [super dealloc];
}

#pragma mark - Button Action
- (IBAction)startAction:(id)sender
{
    self.hostViewController = [[HostViewController alloc] initWithNibName:@"HostViewController" bundle:nil];
    _hostViewController.delegate = self;

    // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self presentViewController:_hostViewController animated:NO completion:nil];
#endif
    // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
    [self presentModalViewController:_hostViewController animated:NO];
#endif
    
}

#pragma mark - Show ImagePicker
- (IBAction)showImagePicker:(UIButton *)sender {
    if ([self startMediaBrowserFromViewController:self usingDelegate:self sender:sender]) {
        // nothing
    } else {
        LOG(@"This Device Can't Open UIImagePicker.");
    }
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller
                              usingDelegate:(id)del
                                     sender:(UIButton *)sender {
    // 1 - Validations
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)
        || (del == nil)
        || (controller == nil)) {
        return NO;
    }
    // 2 - Get image picker
    UIImagePickerController *mediaUI = [[[UIImagePickerController alloc] init] autorelease];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = del;
    // 3 - Display image picker
    _popOverController = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
//    [_popOverController presentPopoverFromBarButtonItem:sender
//                               permittedArrowDirections:UIPopoverArrowDirectionAny
//                                               animated:YES];
    
    [_popOverController presentPopoverFromRect:sender.frame
                                        inView:self.view
                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                      animated:YES];
    
    return YES;
}

#pragma mark - ImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    LOG_METHOD;
    
    [_popOverController dismissPopoverAnimated:YES];
    
    // 1 - Get media type
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    // Handle a movie capture
    if (CFStringCompare ((CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        // 2 - Play the video
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        self.avPlayerViewController = [[[AVPlayerViewController alloc] initWithNibName:@"AVPlayerViewController"
                                                                                bundle:nil
                                                                              videoURL:url] autorelease];
        
        self.avPlayerViewController.delegate = self;
        // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self presentViewController:_avPlayerViewController animated:NO completion:nil];
#endif
        // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        [self presentModalViewController:_avPlayerViewController animated:NO];
#endif
    }
}

// For responding to the user tapping Cancel.
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    LOG_METHOD;
    [_popOverController dismissPopoverAnimated:YES];
}

#pragma mark - View Lifecycle
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
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Show Alert
- (void)showNoNetworkAlert
{
	UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"No Network", @"No network alert title")
                              message:NSLocalizedString(@"To use multiplayer, please enable Bluetooth or Wi-Fi in your device's Settings.", @"No network alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
	[alertView show];
    [alertView release];
}

#pragma mark - HostViewControllerDelegate

- (void)hostViewControllerDidCancel:(HostViewController *)controller {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)hostViewController:(HostViewController *)controller didEndSessionWithReason:(QuitReason)reason {
    if (reason == QuitReasonNoNetwork) {
        [self showNoNetworkAlert];
    }
}

- (void)hostViewController:(HostViewController *)controller
  startShootingWithSession:(GKSession *)session
                  peerName:(NSString *)name
                   clients:(NSArray *)clients {
    
    
    
    [self startShootingSessionWithBlock:^(CameraSession *camSession)
     {
         [camSession startServerShootingWithSession:session peerName:name clients:clients];
     }];
    
}

- (void)startShootingSessionWithBlock:(void (^)(CameraSession *))block {
    LOG_METHOD;
    
    self.camSession = [[CameraSession alloc] init];
    _hostViewController.cameraSession = _camSession;
    _camSession.delegate = _hostViewController;
    
    block(_camSession);
}

- (void)hostViewController:(HostViewController *)controller
startVideoDataTransferWithSesion:(GKSession *)gkSession
                  shooters:(NSMutableArray *)shooters
                  peerName:(NSString *)serverName {
    
    [self dismissViewControllerAnimated:NO completion:^
     {
         [self startVideoDataTransferSessionWithBlock:^(VideoDataTransferSession *sendSession)
          {
              [sendSession startServerVideoTransferSessionWithGKSession:gkSession
                                                           withShooters:shooters
                                                                 server:serverName];
              
          }];
         
     }];
    
    
}

- (void)startVideoDataTransferSessionWithBlock:(void (^)(VideoDataTransferSession *))block {
    
    HostVideoDataReceiveViewController *controller =
    [[HostVideoDataReceiveViewController alloc] initWithNibName:@"HostVideoDataReceiveViewController"
                                                         bundle:nil];
    
    [self presentViewController:controller animated:NO completion:^
     {
         
         VideoDataTransferSession *session = [[VideoDataTransferSession alloc] init];
         controller.transferSession = session;
         session.delegate = controller;
         
         block(session);
     }];
}

#pragma mark - AVPlayerViewController deleagte
- (void)dismissAVPlayerViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
