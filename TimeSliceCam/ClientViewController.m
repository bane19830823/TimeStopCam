//
//  ClientViewController.m
//  TimeSliceCam
//
//  Created by Bane on 12/09/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "ClientViewController.h"
#import "AVCamViewController.h"

@interface ClientViewController ()
//Add
@property (nonatomic ,retain) NADView *nadView;
@end

@implementation ClientViewController {
    TimeSliceCamClient *_timeSliceCamClient;
    QuitReason _quitReason;
}

@synthesize nameLabel;
@synthesize nameTextField;
@synthesize statusLabel;
@synthesize tableView;
@synthesize waitView;
@synthesize waitLabel;
@synthesize delegate = _delegate;
@synthesize nadView = _nadView;

- (void)dealloc {
#ifdef DEBUG
    LOG_METHOD;
    LOG(@"%@", self);
#endif
    self.headingLabel = nil;
    self.nameLabel = nil;
    self.nameTextField = nil;
    self.statusLabel = nil;
    self.tableView = nil;
    self.delegate = nil;
    self.waitView = nil;
    self.waitLabel = nil;
    _timeSliceCamClient = nil;
    self.nadView.delegate = nil;
    self.nadView = nil;
    
    [super dealloc];
}

- (IBAction)exitAction:(id)sender
{
    _quitReason = QuitReasonUserQuit;
	[_timeSliceCamClient disconnectFromServer];
	[self.delegate clientViewControllerDidCancel:self];
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
    // Do any additional setup after loading the view from its nib.
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.nameTextField action:@selector(resignFirstResponder)];
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
        
    if (_timeSliceCamClient == nil) {
        _quitReason = QuitReasonConnectionDropped;
        _timeSliceCamClient = [[TimeSliceCamClient alloc] init];
        _timeSliceCamClient.delegate = self;
        [_timeSliceCamClient startSearchingForServersWithSessionID:kTimeSliceCamGKSessionID];
        
        self.nameTextField.placeholder = _timeSliceCamClient.session.displayName;
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    _timeSliceCamClient = nil;
    [self.nadView pause];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TimeSliceCamClientDelegate

- (void)timeSliceCamClient:(TimeSliceCamClient *)client serverBecameAvailable:(NSString *)peerID {
    LOG_METHOD;
    [self.tableView reloadData];
}

- (void)timeSliceCamClient:(TimeSliceCamClient *)client serverBecameUnavailable:(NSString *)peerID {
    LOG_METHOD;
    [self.tableView reloadData];
}

- (void)timeSliceCamClient:(TimeSliceCamClient *)client didDisconnectFromServer:(NSString *)peerID {
    LOG_METHOD;
    _timeSliceCamClient.delegate = nil;
    _timeSliceCamClient = nil;
    [self.tableView reloadData];
    [self.delegate clientViewController:self didDisconnectWithReason:_quitReason];
}

- (void)timeSliceCamClient:(TimeSliceCamClient *)client didConnectToServer:(NSString *)peerID
{
    LOG_METHOD;
    LOG(@"connected To Server And Start Camera.");
	NSString *name = [self.nameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ([name length] == 0)
		name = _timeSliceCamClient.session.displayName;
    
    if ([self.delegate respondsToSelector:@selector(clientViewController:startCapturingWithGKSession:peerName:server:)]) {
        [self.delegate clientViewController:self startCapturingWithGKSession:_timeSliceCamClient.session peerName:name server:peerID];
    }
    
}

- (void)timeSliceCamClientNoNetwork:(TimeSliceCamClient *)client {
    _quitReason = QuitReasonNoNetwork;
}

- (void)needRefreshTable {
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (_timeSliceCamClient != nil) {
        return [_timeSliceCamClient availableServerCount];
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
    
	NSString *peerID = [_timeSliceCamClient peerIDForAvailableServerAtIndex:indexPath.row];
	cell.textLabel.text = [_timeSliceCamClient displayNameForPeerID:peerID];
    
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[theTableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (_timeSliceCamClient != nil)
	{
        [SVProgressHUD showWithStatus:kMessageConnectingToServer];
		NSString *peerID = [_timeSliceCamClient peerIDForAvailableServerAtIndex:indexPath.row];
		[_timeSliceCamClient connectToServerWithPeerID:peerID];
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
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