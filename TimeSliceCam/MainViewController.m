
#import "MainViewController.h"
#import "ClientViewController.h"
#import "AVCamViewController.h"
#import "CameraSession.h"
#import "VideoDataTransferSession.h"
#import "ClientVideoDataTransferViewController.h"
#import "HostMainViewController.h"
#import "AppDelegate.h"
#import "AVPlayerViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "NADView.h"

#import "GData.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"




@interface MainViewController ()

@property (nonatomic, retain) IBOutlet UIButton *startButton;
@property (nonatomic, retain) GKSession *session;
@property (nonatomic, retain) NSString *peerName;
@property (nonatomic, retain) NSString *peerID;

@property (nonatomic, retain) HostViewController *hostViewController;
@property (nonatomic, retain) ClientViewController *clientViewController;
@property (nonatomic, retain) CameraSession *camSession;
@property (nonatomic, retain) NSURL *hostVideoURL;
//AVPlayer
@property (nonatomic, retain) AVPlayerViewController *avPlayerViewController;
//Add
@property (nonatomic ,retain) NADView *nadView;

@property (nonatomic, retain) IBOutlet UIButton *googleButton;

@end

@implementation MainViewController

@synthesize startButton = _startButton;
@synthesize session = _session;
@synthesize peerName = _peerName;
@synthesize peerID = _peerID;
@synthesize hostViewController = _hostViewController;
@synthesize clientViewController = _clientViewController;
@synthesize hostVideoURL = _hostVideoURL;
@synthesize avPlayerViewController = _avPlayerViewController;
@synthesize nadView = _nadView;

- (void)dealloc {
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"%@", self);
#endif
    [_hostViewController release], _hostViewController = nil;
    [_clientViewController release], _clientViewController = nil;
    [_startButton release], _startButton = nil;
    [_hostVideoURL release], _hostVideoURL = nil;
    [_avPlayerViewController release], _avPlayerViewController = nil;
    self.nadView.delegate = nil;
    [_nadView release], _nadView = nil;
    [super dealloc];
}

#pragma mark - MainViewController StartPoint
- (void)viewDidLoad {
    [super viewDidLoad];

    self.nadView = [[[NADView alloc] initWithFrame:CGRectMake(0,
                                                              0,
                                                              NAD_ADVIEW_SIZE_320x50.width,
                                                              NAD_ADVIEW_SIZE_320x50.height)] autorelease];
    
    [self.nadView setIsOutputLog:NO];
    [self.nadView setNendID:NendID spotID:NendSpotID];
    [self.nadView setDelegate:self];
    [self.nadView load];
    [self.view addSubview:self.nadView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [self.nadView resume];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.nadView pause];
}

//クライアントのスタートポイント
- (IBAction)startClientSession:(id)sender
{
    LOG_METHOD;
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isServer = NO;
    self.clientViewController = [[ClientViewController alloc] initWithNibName:@"ClientViewController" bundle:nil];
    self.clientViewController.delegate = self;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self presentViewController:_clientViewController animated:NO completion:nil];
#endif
    // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
    [self presentModalViewController:_clientViewController animated:NO];
#endif
}

//ホストのスタートポイント
- (IBAction)startHostSession:(id)sender {
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    app.isServer = YES;
    //この時点で、iPhone x iPhone モードであることが確定する
    app.globalShootingMode = ShootingMode_iPhone_iPhone;
    
    self.hostViewController = [[HostViewController alloc] initWithNibName:@"HostViewController_iPhone"
                                                                   bundle:nil];
    self.hostViewController.delegate = self;
    
    // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self presentViewController:_hostViewController animated:NO completion:nil];
#endif
    // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
    [self presentModalViewController:_hostViewController animated:NO];
#endif
}

- (void)clientViewControllerDidCancel:(ClientViewController *)controller
{
	[self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - ClientViewController delegate
- (void)clientViewController:(ClientViewController *)controller didDisconnectWithReason:(QuitReason)reason {
	
	if (reason == QuitReasonNoNetwork)
	{
		[self showNoNetworkAlert];
	}
	else if (reason == QuitReasonConnectionDropped)
	{
		[self dismissViewControllerAnimated:NO completion:^
         {
             [self showDisconnectedAlert];
         }];
	}
}

- (void)clientViewController:(ClientViewController *)controller
 startCapturingWithGKSession:(GKSession *)session
                    peerName:(NSString *)name
                      server:(NSString *)peerID {
    LOG_METHOD;
    
    [self dismissViewControllerAnimated:NO completion:^
     {
         [self startShootingSessionWithBlock:^(CameraSession *cameraSession)
          {
              [cameraSession startClientShootingWithSession:session peerName:name server:peerID];
          }];
     }];
    
}

- (void)showDisconnectedAlert
{
	UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:NSLocalizedString(@"Disconnected", @"Client disconnected alert title")
                              message:NSLocalizedString(@"You were disconnected from the server.", @"Client disconnected alert message")
                              delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                              otherButtonTitles:nil];
    
	[alertView show];
    [alertView release];
}

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

#pragma mark - AVCamViewController delegate
- (void)avCamViewController:(AVCamViewController *)camController didQuitWithReason:(QuitReason)reason {
    [self dismissViewControllerAnimated:NO completion:^
     {
         if (reason == QuitReasonConnectionDropped)
         {
             [self showDisconnectedAlert];
         }
     }];
}

//録画または写真撮影終了時コールされる
- (void)avCamViewController:(AVCamViewController *)camController
 didFinishRecordingWithURL:(NSURL *)url
                    session:(GKSession *)session
               serverPeerID:(NSString *)peerID
                   peerName:(NSString *)peerName
                 peerNumber:(NSString *)peerNumber {
    
    //クライアントの場合、ここで写真プレビューと送信の画面に遷移する
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!app.isServer) {
        [self dismissViewControllerAnimated:NO completion:^
         {
             [self startVideoSendSessionWithBlock:^(VideoDataTransferSession *sendSession)
              {
                  [sendSession startClientVideoTransferSessionWithGKSession:session
                                                                   videoURL:url
                                                                     server:peerID
                                                                   peerName:peerName
                                                                 peerNumber:peerNumber];
              }];
             
         }];
    } else {
        self.hostVideoURL = url;
    }
}

- (void)startVideoSendSessionWithBlock:(void (^)(VideoDataTransferSession *))block {
    ClientVideoDataTransferViewController *controller =
    [[ClientVideoDataTransferViewController alloc] initWithNibName:@"ClientVideoDataTransferViewController"
                                                            bundle:nil];
    controller.mainViewController = self;
    
    [self presentViewController:controller animated:NO completion:^
     {
         VideoDataTransferSession *session = [[VideoDataTransferSession alloc] init];
         controller.sendSession = session;
         session.delegate = controller;
         block(session);
     }];
    
}

- (void)avCamViewController:(AVCamViewController *)camController
startVideoDataTransferWithSesion:(GKSession *)gkSession
                   shooters:(NSMutableArray *)shooters
                   peerName:(NSString *)serverName {
    LOG_METHOD;
    
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
    [[HostVideoDataReceiveViewController alloc] initWithNibName:@"HostVideoDataReceiveViewContoller_iPhone"
                                                         bundle:nil];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        controller.hostVideoURL = self.hostVideoURL;
    }
    
    [self presentViewController:controller animated:NO completion:^
     {
         
         VideoDataTransferSession *session = [[VideoDataTransferSession alloc] init];
         controller.transferSession = session;
         session.delegate = controller;
         controller.delegate = self;
         
         block(session);
     }];
}

#pragma mark  AutoRotation Support Methods

#pragma mark  iOS 6 or later
// iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        // iPhone がサポートする向き
        return UIInterfaceOrientationMaskPortrait;
    }
    
    // iPad がサポートする向き
    return UIInterfaceOrientationMaskAll;
}
- (BOOL)shouldAutorotate
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        return YES;
    }
    
    return YES;
}
#endif

#pragma mark  Before iOS 6
// iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return NO;
}
#endif

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
    
    [self dismissViewControllerAnimated:NO completion:^{
        [self startShootingSessionWithBlock:^(CameraSession *camSession)
         {
             [camSession startServerShootingWithSession:session peerName:name clients:clients];
         }];
    }];
}

- (void)startShootingSessionWithBlock:(void (^)(CameraSession *))block {
    LOG_METHOD;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        
        self.camSession = [[[CameraSession alloc] init] autorelease];
        _hostViewController.cameraSession = _camSession;
        _camSession.delegate = _hostViewController;
        
        block(_camSession);
    } else {
        AVCamViewController *camController =
        [[[AVCamViewController alloc] initWithNibName:@"AVCamViewController"
                                               bundle:nil]
         autorelease];
        camController.delegate = self;
        camController.parentVC = self;
        
        [self presentViewController:camController animated:NO completion:^
         {
             CameraSession *session = [[CameraSession alloc] init];
             camController.cameraSession = session;
             session.delegate = camController;
             block(session);
             
         }];
    }
}

#pragma mark - HostVideoDataReceiveViewControllerDelegate
- (void)receiveViewController:(HostVideoDataReceiveViewController *)controller
 didFinishPickingMediaWithURL:(NSURL *)mediaUrl {
    
    [self dismissViewControllerAnimated:NO completion:^{
        self.avPlayerViewController = [[[AVPlayerViewController alloc] initWithNibName:@"AVPlayerViewController"
                                                                                bundle:nil
                                                                              videoURL:mediaUrl] autorelease];
        
        UINavigationController *navi = [[[UINavigationController alloc] initWithRootViewController:self.avPlayerViewController] autorelease];
        self.avPlayerViewController.delegate = self;
        
        // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self presentViewController:navi animated:NO completion:nil];
#endif
        // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        [self presentModalViewController:navi animated:NO];
#endif
    }];
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self presentViewController:mediaUI animated:NO completion:nil];
#endif
        // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        [self presentModalViewController:mediaUI animated:YES];
#endif
    }
    
    return YES;
}

#pragma mark - UIImagePickerController delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    LOG_METHOD;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self dismissViewControllerAnimated:NO completion:nil];
#endif
        // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        [self dismissModalViewControllerAnimated:YES];
#endif
    }
    
    // 1 - Get media type
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    // Handle a movie capture
    if (CFStringCompare ((CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        // 2 - Play the video
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            self.avPlayerViewController = [[[AVPlayerViewController alloc] initWithNibName:@"AVPlayerViewController"
                                                                                    bundle:nil
                                                                                  videoURL:url] autorelease];
            
            UINavigationController *navi = [[[UINavigationController alloc] initWithRootViewController:self.avPlayerViewController] autorelease];
            
            self.avPlayerViewController.delegate = self;
            // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
            [self presentViewController:navi animated:NO completion:nil];
#endif
            // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
            [self presentModalViewController:navi animated:NO];
#endif
            
        }
    }
}

// For responding to the user tapping Cancel.
-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    LOG_METHOD;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        [self dismissViewControllerAnimated:NO completion:nil];
#endif
        
        // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
        [self dismissModalViewControllerAnimated:NO];
#endif
    }
}

#pragma mark - AVPlayerViewController deleagte
- (void)dismissAVPlayerViewController {
    // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self dismissViewControllerAnimated:NO completion:nil];
#endif
    
    // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
    [self dismissModalViewControllerAnimated:NO];
#endif
}

- (void)dataTransferFinished {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - NADViewDelegate
- (void)nadViewDidFinishLoad:(NADView *)adView {
    
}

@end
