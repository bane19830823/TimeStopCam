//
//  AVPlayerViewController.m
//  VideoPlayer
//
//  Created by Akabeko on 2012/09/30.
//  Copyright (c) 2012年 Akabeko. All rights reserved.
//

#import "AVPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GoogleManager.h"
#import "GData.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GDataEntryYouTubeUpload.h"
#import "YouTubeUploaderViewController.h"
#import "GTMOAuth2Authentication.h"

NSString* const kStatusKey = @"status";
static void* AVPlayerViewControllerStatusObservationContext = &AVPlayerViewControllerStatusObservationContext;

@interface AVPlayerViewController ()

@property (nonatomic, retain) NSURL*        videoUrl;         //! 動画の URL
@property (nonatomic, retain) AVPlayerItem* playerItem;       //! 再生対象となるアイテム情報
@property (nonatomic, retain) AVPlayer*     videoPlayer;      //! 動画プレイヤー
@property (nonatomic, assign) id            playTimeObserver; //! 再生位置の更新タイマー通知ハンドラ
@property (nonatomic, assign) BOOL          isPlaying;        //! 動画が再生中であることを示す値
@property (nonatomic, retain) UIBarButtonItem *doneButton;    //! 完了ボタン
@property (nonatomic, assign) BOOL isHidden;                  //! コントロール表示フラグ
@property (nonatomic, assign) BOOL isEndTime;                 //! 再生完了フラグ
@property (nonatomic, retain) NSData *videoData;              //Youtube投稿用データ
@property (nonatomic, retain) NSString *videoFilePath;        //Youtube投稿用ファイルパス
@property (nonatomic, retain) YouTubeUploaderViewController *youtubeUploder;

@end

@implementation AVPlayerViewController

@synthesize delegate = _delegate;
//@synthesize youtubeService = _youtubeService;

#pragma mark - Lifecycle

/**
 * コントローラのインスタンスを生成します。
 *
 * @param videoUrl 動画の URL。
 *
 * @return インスタンス。
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil videoURL:(NSURL *)videoURL {
    
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.videoUrl = videoURL;
        self.isHidden = NO;
        self.videoData = [NSData dataWithContentsOfURL:videoURL];
        self.videoFilePath = [videoURL path];
    }
    return self;
}

/**
 * インスタンスを破棄します。
 */
- (void)dealloc
{
    [self.videoPlayer pause];
    [self.playerItem removeObserver:self forKeyPath:kStatusKey context:AVPlayerViewControllerStatusObservationContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];

    self.videoPlayerView  = nil;
    self.videoPlayer      = nil;
    self.videoUrl         = nil;
    self.playerItem       = nil;
    self.currentTimeLabel = nil;
    self.seekBar          = nil;
    self.durationLabel    = nil;
    self.playButton       = nil;
    self.playerToolView   = nil;
    self.naviBar          = nil;
    self.youtubeUploder = nil;

    [super dealloc];
}

#pragma mark - View

/**
 * 画面が読み込まれる時に発生します。
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    
    self.title = NSLocalizedString(@"Video Preview", @"VideoPreviewTitle");
    
    btnUpload = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Upload", @"UploadButtonTitle")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(upload:)] autorelease];
    
    self.navigationItem.leftBarButtonItem = btnUpload;
    
    done = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                           target:self
                                                                           action:@selector(dismissAVPlayer:)] autorelease];
    self.navigationItem.rightBarButtonItem = done;

    [self.playButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchDown];
    self.playButton.contentMode = UIViewContentModeCenter;
    
    // 再生の準備が整うまで、操作系は無効としておく
    self.playButton.enabled = NO;
    self.seekBar.enabled    = NO;
    
    self.playerItem = [[[AVPlayerItem alloc] initWithURL:self.videoUrl] autorelease];
    [self.playerItem addObserver:self
                      forKeyPath:kStatusKey
                         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                         context:AVPlayerViewControllerStatusObservationContext];

  	// 終了通知
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(playerDidPlayToEndTime:)
												 name:AVPlayerItemDidPlayToEndTimeNotification
											   object:self.playerItem];
  
    self.videoPlayer = [[[AVPlayer alloc] initWithPlayerItem:self.playerItem] autorelease];
    
    AVPlayerLayer* layer = ( AVPlayerLayer* )self.videoPlayerView.layer;
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    layer.player       = self.videoPlayer;
    
    // シングル タップ
	UITapGestureRecognizer* tapSingle = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSingle:)] autorelease];
	tapSingle.numberOfTapsRequired = 1;
	[self.videoPlayerView addGestureRecognizer:tapSingle];
//
//    // ダブル タップ
//	UITapGestureRecognizer* tapDouble = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDouble:)] autorelease];
//	tapDouble.numberOfTapsRequired = 2;
//	[self.videoPlayerView addGestureRecognizer:tapDouble];

}

/**
 * 画面が破棄される時に発生します。
 */
- (void)viewDidUnload
{
    [self.videoPlayer pause];
    [self.playerItem removeObserver:self forKeyPath:kStatusKey context:AVPlayerViewControllerStatusObservationContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
    self.videoPlayerView  = nil;
    self.videoPlayer      = nil;
    self.videoUrl         = nil;
    self.playerItem       = nil;
    self.currentTimeLabel = nil;
    self.seekBar          = nil;
    self.durationLabel    = nil;
    self.playButton       = nil;
    self.playerToolView   = nil;

    [super viewDidUnload];
}

/**
 * 画面が表示される時に発生します。
 *
 * @param animated 表示アニメーションを有効にする場合は YES。それ以外は NO。
 */
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.view setNeedsLayout];
}

/**
 * 他の画面へ切り替わる時に発生します。
 *
 * @param animated 表示アニメーションを有効にする場合は YES。それ以外は NO。
 */
- (void)viewWillDisappear:(BOOL)animated
{
    
    [super viewWillDisappear:animated];

}

/**
 * プロパティが更新された時に発生します。
 *
 * @param keyPath 変更されたプロパティ。
 * @param object  変更されたプロパティを持つオブジェクト。
 * @param change  変更内容。
 * @param context 任意のユーザー データ。
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    LOG_METHOD;
    if( context == AVPlayerViewControllerStatusObservationContext )
    {
        [self syncPlayButton];
        
        const AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch( status )
        {
        // 再生の準備が完了した
        case AVPlayerStatusReadyToPlay:
            [self setupSeekBar];
            self.playButton.enabled = YES;
            self.seekBar.enabled    = YES;
            break;

        // 不明
        case AVPlayerStatusUnknown:
            [self showError:nil];
            break;

  
        // 不正な状態
        case AVPlayerStatusFailed:
            {
                AVPlayerItem* playerItem = ( AVPlayerItem* )object;
                [self showError:playerItem.error];
            }
            break;
        }
    }
}

#pragma mark - Private

/**
 * 再生・一時停止ボタンが押された時に発生します。
 *
 * @param sender イベント送信元。
 */
- (void)play:(id)sender
{
    LOG_METHOD;
    if( self.isPlaying )
    {
        self.isPlaying = NO;
        [self toggleControlDisplay];
        [self.videoPlayer pause];
    }
    else
    {
        if (self.isEndTime) {
            [self.videoPlayer seekToTime:kCMTimeZero];
            self.isEndTime = NO;
        }
        self.isPlaying = YES;
        [self toggleControlDisplay];
        [self.videoPlayer play];
        
    }

    [self syncPlayButton];
}

/**
 * 動画再生が完了した時に発生します。
 *
 * @param notification 通知情報。
 */
- (void)playerDidPlayToEndTime:(NSNotification *)notification
{
    LOG_METHOD;
//	[self.videoPlayer seekToTime:kCMTimeZero];
    self.isEndTime = YES;
    self.isPlaying = NO;
//    [self toggleControlDisplay];
    [self syncPlayButton];

    // リピートする場合は再生を実行する
    //[self.videoPlayer play];
}

/**
 * 再生時間の更新ハンドラを削除します。
 */
- (void)removePlayerTimeObserver
{
    if( self.playTimeObserver == nil ) { return; }

    [self.videoPlayer removeTimeObserver:self.playTimeObserver];
    self.playTimeObserver = nil;
}

/**
 * 再生時間スライダーの操作によって値が更新された時に発生します。
 *
 * @param slider スライダー。
 */
- (void)seekBarValueChanged:(UISlider *)slider
{
	[self.videoPlayer seekToTime:CMTimeMakeWithSeconds( slider.value, NSEC_PER_SEC )];
}

/**
 * シークバーを初期化します。
 */
- (void)setupSeekBar
{
	self.seekBar.minimumValue = 0;
	self.seekBar.maximumValue = CMTimeGetSeconds( self.playerItem.duration );
	self.seekBar.value        = 0;
	[self.seekBar addTarget:self action:@selector(seekBarValueChanged:) forControlEvents:UIControlEventValueChanged];
    
	// 再生時間とシークバー位置を連動させるためのタイマー
	const double interval = ( 0.5f * self.seekBar.maximumValue ) / self.seekBar.bounds.size.width;
	const CMTime time     = CMTimeMakeWithSeconds( interval, NSEC_PER_SEC );
	self.playTimeObserver = [self.videoPlayer addPeriodicTimeObserverForInterval:time
                                                                           queue:NULL
                                                                      usingBlock:^( CMTime time ) { [self syncSeekBar]; }];

    self.durationLabel.text = [self timeToString:self.seekBar.maximumValue];
}

/**
 * エラー通知をおこないます。
 *
 * @param error エラー情報。
 */
- (void)showError:(NSError *)error
{
    [self removePlayerTimeObserver];
    [self syncSeekBar];
    self.playButton.enabled = NO;
    self.seekBar.enabled    = NO;
    
    if( error != nil )
    {
        UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                            message:[error localizedFailureReason]
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                                                  otherButtonTitles:nil] autorelease];
        [alertView show];
    }
}

/**
 * 再生位置スライダーを同期します。
 */
- (void)syncSeekBar
{
	const double duration = CMTimeGetSeconds( [self.videoPlayer.currentItem duration] );
	const double time     = CMTimeGetSeconds([self.videoPlayer currentTime]);
	const float  value    = ( self.seekBar.maximumValue - self.seekBar.minimumValue ) * time / duration + self.seekBar.minimumValue;
    
	[self.seekBar setValue:value];
    self.currentTimeLabel.text = [self timeToString:self.seekBar.value];
}

/**
 * 再生・一時停止ボタンの状態を同期します。
 */
- (void)syncPlayButton
{
    if( self.isPlaying )
    {
        [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
    else
    {
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }
}

- (void)toggleControlDisplay {
    self.isHidden = !self.isHidden;
    
    if (self.isEndTime) {
        self.isHidden = NO;
    }
	[[UIApplication sharedApplication] setStatusBarHidden:self.isHidden withAnimation:NO];
	self.navigationController.navigationBar.hidden = self.isHidden;
    [self.playerToolView setHidden:self.isHidden];
    
    if (self.isHidden) {
        [self setWantsFullScreenLayout:YES];
    } else {
        [self setWantsFullScreenLayout:NO];
    }
}

/**
 * View がシングル タップされた時に発生します。
 *
 * @param sender イベント送信元。
 */
- (void)tapSingle:(UITapGestureRecognizer *)sender
{
    [self toggleControlDisplay];
}

/**
 * View がダブル タップされた時に発生します。
 *
 * @param sender イベント送信元。
 */
- (void)tapDouble:(UITapGestureRecognizer *)sender
{
    AVPlayerLayer* layer = ( AVPlayerLayer* )self.videoPlayerView.layer;
    layer.videoGravity = ( layer.videoGravity == AVLayerVideoGravityResizeAspect ? AVLayerVideoGravityResizeAspectFill : AVLayerVideoGravityResizeAspect );
}

/**
 * 時間を文字列化します。
 *
 * @param value 時間。
 *
 * @return 文字列。
 */
- (NSString* )timeToString:(float)value
{
    const NSInteger time = value;
    return [NSString stringWithFormat:@"%d:%02d", ( int )( time / 60 ), ( int )( time % 60 )];
}

#pragma mark - Action
- (void)dismissAVPlayer:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dismissAVPlayerViewController)]) {
        [self.delegate dismissAVPlayerViewController];
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
    if ((interfaceOrientation == UIInterfaceOrientationPortrait)
        || (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    return NO;
}
#endif

#pragma mark - Video Upload
- (void)upload:(id)sender {
    UIActionSheet *as = [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Upload To", @"VideoUploadSheetTitle")
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"Cancel", @"VideoUploadSheetCancelButton")
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:NSLocalizedString(@"YouTube", @"YouTube"), nil] autorelease];
    [as showInView:self.view];
}

- (void)actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        GoogleManager *googleLogin = (GoogleManager *)[GoogleManager sharedManager];
        googleLogin.delegate = self;
        
        //キーチェーンにトークンが保存されているか確認
        GTMOAuth2Authentication *auth = [googleLogin authWithKeyChain];
        if (auth == nil) {
            btnUpload.enabled = done.enabled = NO;
            self.playButton.enabled = NO;
            self.seekBar.enabled    = NO;
            GTMOAuth2ViewControllerTouch *touch = [googleLogin signInToGoogle];
            [self.navigationController pushViewController:(UIViewController *)touch animated:YES];
        } else {
            btnUpload.enabled = done.enabled = NO;
            self.playButton.enabled = NO;
            self.seekBar.enabled    = NO;
            self.youtubeUploder = [[[YouTubeUploaderViewController alloc] initWithNibName:@"YouTubeUploaderViewController"
                                                                                   bundle:nil
                                                                               authObject:auth
                                                                            videoFilePath:self.videoFilePath
                                                                                videoData:self.videoData] autorelease];
            self.youtubeUploder.delegate = self;

            
            self.youtubeUploder.googleMailAddress = [auth.parameters objectForKey:@"email"];
            // iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
            [self presentViewController:self.youtubeUploder animated:YES completion:nil];
#else
            [self presentModalViewController:self.youtubeUploder animated:YES];
#endif
        }
    }
}

#pragma mark - GoogleManager Delegate
//認証成功時にデリゲートに通知する
- (void)googleManegerLadyForUploadVideoWithAuth:(GTMOAuth2Authentication *)auth {
        
    self.youtubeUploder = [[[YouTubeUploaderViewController alloc] initWithNibName:@"YouTubeUploaderViewController"
                                                                           bundle:nil
                                                                       authObject:auth
                                                                    videoFilePath:self.videoFilePath
                                                                        videoData:self.videoData] autorelease];
    self.youtubeUploder.delegate = self;
    self.youtubeUploder.googleMailAddress = [auth.parameters objectForKey:@"email"];
    
// iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self presentViewController:self.youtubeUploder animated:YES completion:nil];
#else
    [self presentModalViewController:self.youtubeUploder animated:YES];
#endif
}

//認証がキャンセルされた時に実行するデリゲート
- (void)googleManagerDidRequestCanceled {
    btnUpload.enabled = done.enabled = YES;
    self.playButton.enabled = YES;
    self.seekBar.enabled    = YES;
}

#pragma mark - YouTubeUploaderViewController Delegate
- (void)YouTubeUploaderDidFinish {
    btnUpload.enabled = done.enabled = YES;
    self.playButton.enabled = YES;
    self.seekBar.enabled    = YES;

}


@end
