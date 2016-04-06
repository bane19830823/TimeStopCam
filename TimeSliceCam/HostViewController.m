//
//  HostViewController.m
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "HostViewController.h"
#import "Packet.h"
#import "Peer.h"
#import "CameraSession.h"

@interface HostViewController ()
@property (nonatomic ,retain) NADView *nadView;
@end

@implementation HostViewController {
    TimeSliceCamServer *_timeSliceCamServer;
    QuitReason _quitReason;
}

@synthesize headingLabel;
@synthesize nameLabel;
@synthesize nameTextField;
@synthesize statusLabel;
@synthesize tableView;
@synthesize sequencialButton;
@synthesize delegate = _delegate;
@synthesize cameraSession = _cameraSession;
@synthesize readyForShootingStateClients = _readyForShootingStateClients;
@synthesize nadView = _nadView;

- (void)dealloc {
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"%@", self);
#endif
    headingLabel = nil;
    nameLabel = nil;
    nameTextField = nil;
    statusLabel = nil;
    tableView = nil;
    sequencialButton = nil;
    self.delegate = nil;
    self.cameraSession = nil;
    self.readyForShootingStateClients = nil;
    self.nadView.delegate = nil;
    self.nadView = nil;
    
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
    [super viewDidLoad];
    
	UITapGestureRecognizer *gestureRecognizer =
    [[UITapGestureRecognizer alloc] initWithTarget:self.nameTextField action:@selector(resignFirstResponder)];
	gestureRecognizer.cancelsTouchesInView = NO;
	[self.view addGestureRecognizer:gestureRecognizer];
    
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
    [super viewWillAppear:animated];
    [self.nadView resume];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    LOG_METHOD;
    
//    self.startButton.enabled = NO;
    self.readyForShootingStateClients = [[NSMutableArray alloc] initWithCapacity:0];
    
    if (_timeSliceCamServer == nil) {
        _timeSliceCamServer = [[TimeSliceCamServer alloc] init];
        _timeSliceCamServer.delegate = self;
        _timeSliceCamServer.maxClients = kMaxCients;
        [_timeSliceCamServer startAcceptingConnectionsForSessionID:kTimeSliceCamGKSessionID];
        
        self.nameTextField.placeholder = _timeSliceCamServer.session.displayName;
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    _timeSliceCamServer = nil;
    [self.readyForShootingStateClients removeAllObjects];
    self.readyForShootingStateClients = nil;
    [self.nadView pause];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//撮影開始
- (void)startRecording:(RecordingType)recordingType {
    [_cameraSession sendClientToRecordingRequest:recordingType];
}

#pragma mark - TimeSliceCamServer delegate
- (void)timeSliceCamServer:(TimeSliceCamServer *)server clientDidConnect:(NSString *)peerID {
    [self.tableView reloadData];
}

- (void)timeSliceCamServer:(TimeSliceCamServer *)server clientDidDisconnect:(NSString *)peerID {
    [self.tableView reloadData];

}

- (void)timeSliceCamServerSessionDidEnd:(TimeSliceCamServer *)server {
    LOG_METHOD;
    _timeSliceCamServer.delegate = nil;
	_timeSliceCamServer = nil;
	[self.tableView reloadData];
	[self.delegate hostViewController:self didEndSessionWithReason:_quitReason];
}

- (void)timeSliceCamServerNoNetwork:(TimeSliceCamServer *)server {
    _quitReason = QuitReasonNoNetwork;
}

#pragma mark - Button Action
- (IBAction)startAction:(id)sender
{
    [self startRecording:RECORDING_TYPE_SIMULTANEOUS];
}

//撮影順序の送信
- (IBAction)sendShootingOrder:(id)sender {
    LOG_METHOD;
    if (_timeSliceCamServer != nil && [_timeSliceCamServer connectedClientCount] > 0)
	{
        NSString *name =
        [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ([name length] == 0)
			name = _timeSliceCamServer.session.displayName;
        
        //クライアントの接続受付を停止する
		[_timeSliceCamServer stopAcceptingConnections];
        
        if ([self.delegate respondsToSelector:@selector(hostViewController:startShootingWithSession:peerName:clients:)])
        {
            [self.delegate hostViewController:self
                     startShootingWithSession:_timeSliceCamServer.session
                                     peerName:name
                                      clients:_timeSliceCamServer.connectedClients];
        }
	}
}

- (IBAction)exitAction:(id)sender
{
    _quitReason = QuitReasonUserQuit;
    [_timeSliceCamServer endSession];
    [self.delegate hostViewControllerDidCancel:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_timeSliceCamServer != nil) {
        return [_timeSliceCamServer connectedClientCount];
    } else {
        return 0;
    }

}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
	UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
	NSString *peerID = [_timeSliceCamServer peerIDForConnectedClientAtIndex:indexPath.row];
	cell.textLabel.text = [_timeSliceCamServer displayNameForPeerID:peerID];
    
	return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - CameraSession delegate
- (void)cameraSession:(CameraSession *)session didReceiveReadyForShootingPacketFromClient:(NSString *)peerID {
    LOG_METHOD;
    [self.readyForShootingStateClients addObject:peerID];
    
    if ([self.readyForShootingStateClients count] == [_timeSliceCamServer.connectedClients count]) {
        self.sequencialButton.enabled = YES;
        self.simultaneousButton.enabled = YES;
    }
    
}

- (void)cameraSessionDidAllClientFinishShooting:(CameraSession *)sesion
                                   withShooters:(NSMutableArray *)shooters
                                      gkSession:(GKSession *)gkSession
                                       peerName:(NSString *)peerName {
    
    if ([self.delegate respondsToSelector:@selector(hostViewController:startVideoDataTransferWithSesion:shooters:peerName:)]) {
        [self.delegate hostViewController:self
         startVideoDataTransferWithSesion:gkSession
                                 shooters:shooters
                                 peerName:peerName];
    }
}

#pragma mark - AutoRotation Support Methods

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
        // iPhone
        return NO;
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

#pragma mark - NADViewDelegate
- (void)nadViewDidFinishLoad:(NADView *)adView {
    
}


@end
