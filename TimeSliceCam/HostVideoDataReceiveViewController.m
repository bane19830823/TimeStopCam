//
//  HostVideoDataReceiveViewController.m
//  TimeSliceCam
//
//  Created by Bane on 12/11/08.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "HostVideoDataReceiveViewController.h"
#import "VideoData.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VideoSaveOperation.h"
#import "AVPlayerViewController.h"
#import "HostVideoDataReceiveCell.h"
#import "AppDelegate.h"
#import "LoadImageOperation.h"
#import "UIImage+ResizeAspectFit.h"

@interface HostVideoDataReceiveViewController () 
@property (nonatomic, retain) UIPopoverController *popOverController;
@property (nonatomic, retain) NSMutableDictionary *videoAssetsDic;
@property (nonatomic, retain) NSMutableArray *videoAssetsList;

//videoからstillImageを作るオブジェクト
@property (nonatomic, retain) AVAssetImageGenerator *imageGenerator;
//clientの画像を保持する配列
@property (nonatomic, retain) NSMutableArray *imageAssetArray;
//AVPlayer
@property (nonatomic, retain) AVPlayerViewController *avPlayerViewController;

//編集用のビデオURL
@property (nonatomic, retain) NSMutableArray *editAssetsArray;

@property (nonatomic, retain) NSMutableDictionary *photoImageDic;

- (void)photoEditProcess;
@end

@implementation HostVideoDataReceiveViewController {
    int videoSaveCount;
    int needToSaveVideoCount;
    int pictureCount;
    int photoLoadCount;
    int needToLoadPhotoCount;
}

@synthesize transferSession = _transferSession;
@synthesize tableView = _tableView;
@synthesize destinationPath = _destinationPath;
@synthesize videoView = _videoView;
@synthesize popOverController = _popOverController;
@synthesize library = _library;
@synthesize videoAssetsDic = _videoAssetsDic;
@synthesize videoAssetsList = _videoAssetsList;
@synthesize saveQueue = _saveQueue;
@synthesize loadQueue = _loadQueue;
@synthesize avPlayerViewController = _avPlayerViewController;
@synthesize hostVideoURL = _hostVideoURL;
@synthesize delegate = _delegate;
@synthesize imageGenerator = _imageGenerator;
@synthesize imageAssetArray = _imageAssetArray;
@synthesize movieEncoder = _movieEncoder;
@synthesize pictureSavePath = _pictureSavePath;
@synthesize editAssetsArray = _editAssetsArray;
@synthesize photoImageDic = _photoImageDic;
@synthesize btnOpenLibrary = _btnOpenLibrary;

- (void)dealloc {
    [_transferSession release], _transferSession = nil;
    [_tableView release], _tableView = nil;
    [_destinationPath release], _destinationPath = nil;
    [_videoView release], _videoView = nil;
    [_library release], _library = nil;
    [_videoAssetsDic release], _videoAssetsDic = nil;
    [_videoAssetsList release], _videoAssetsList = nil;
    [_saveQueue release], _saveQueue = nil;
    [_loadQueue release], _loadQueue = nil;
    [_popOverController release], _popOverController = nil;
    [_avPlayerViewController release], _avPlayerViewController = nil;
    [_hostVideoURL release], _hostVideoURL = nil;
    [_imageGenerator release], _imageGenerator = nil;
    [_imageAssetArray release], _imageAssetArray = nil;
    [_movieEncoder release], _movieEncoder = nil;
    [_pictureSavePath release], _pictureSavePath = nil;
    [_editAssetsArray release], _editAssetsArray = nil;
    self.photoImageDic = nil;
    self.btnOpenLibrary = nil;
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.videoAssetsDic = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
        self.videoAssetsList = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
        self.photoImageDic = [[[NSMutableDictionary alloc] initWithCapacity:0] autorelease];
        self.editAssetsArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
        self.imageAssetArray = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
        
        videoSaveCount = 0;
        needToSaveVideoCount = 0;
        pictureCount = 0;
        photoLoadCount = 0;
        needToLoadPhotoCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.btnOpenLibrary.enabled = NO;
    //クライアントの写真保存パスを作成する
    [self makePictureSavePath];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_transferSession.shooters count];
    
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSString *CellIdentifier = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        CellIdentifier = @"smallCell";
    } else {
        CellIdentifier = @"largeCell";
    }
    
	HostVideoDataReceiveCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		NSArray *array = [[NSBundle mainBundle] loadNibNamed:@"HostVideoDataReceiveCell"
                                                       owner:self
                                                     options:nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell = [array objectAtIndex:0];
        } else {
            cell = [array objectAtIndex:1];
        }
    }
    
    
	NSString *peerID = [_transferSession peerIDForConnectedClientAtIndex:indexPath.row];
	cell.peerNameLabel.text = [_transferSession displayNameForPeerID:peerID];
    
    AppDelegate *app = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if (app.isServer) {
            if (indexPath.row == 0) {
                cell.signalView.image = [UIImage imageNamed:@"greenSignal"];
            } else {
                NSString *peerNumber = [_transferSession peerNumberForPeerID:peerID];
                VideoData *data = [_transferSession.videoDataDic objectForKey:peerNumber];
                cell.signalView.image = data.didCompleteData ? [UIImage imageNamed:@"greenSignal"] : [UIImage imageNamed:@"redSignal"];
            }
        }
        return cell;
    }
    
    NSString *peerNumber = [_transferSession peerNumberForPeerID:peerID];
    VideoData *data = [_transferSession.videoDataDic objectForKey:peerNumber];
    cell.signalView.image = data.didCompleteData ? [UIImage imageNamed:@"greenSignal"] : [UIImage imageNamed:@"redSignal"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

#pragma mark - VideoDataTransferSession Delegate

- (void)needRefleshTable {

    [self.tableView reloadData];
}

- (void)videoDataTranserSession:(VideoDataTransferSession *)session
didEndSessionWithPhotoDataArray:(NSArray *)photoDataArray {
    LOG_METHOD;
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:kMessageSavingPhotoDataToLibrary];
    self.library = [[ALAssetsLibrary alloc] init];
    needToSaveVideoCount = [photoDataArray count];
    LOG(@"保存すべきビデオ数:%d", needToSaveVideoCount);
    
    int start = 0;
    int end = [photoDataArray count];
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        start = 1;
//        end = [photoDataArray count] + 1;
//    }
    
    for (int i = start; i < end; i++) {
        
        self.saveQueue = [NSOperationQueue mainQueue];
        NSData *data = [photoDataArray objectAtIndex:i];
        LOG(@"photoDataLength:%d", [data length]);
        
        VideoSaveOperation *op = [[VideoSaveOperation alloc] initWithPhotoData:data
                                                                 executeNumber:i];
        
        [op addObserver:self
                    forKeyPath:@"isFinished"
                       options:NSKeyValueObservingOptionNew
                       context:nil];
        
        [self.saveQueue addOperation:op];
    }
}

- (void)countPlusOne {
    videoSaveCount++;
    LOG_METHOD;
    LOG(@"video saved To AssetsLibrary:count:%d", videoSaveCount);
    
    if (videoSaveCount == needToSaveVideoCount) {
        self.saveQueue = nil;
        [self sortVideoOrder];
    }
}

- (void)sortVideoOrder {
    LOG_METHOD;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        [self.videoAssetsDic setObject:self.hostVideoURL forKey:@"0"];
        [self.editAssetsArray addObject:self.hostVideoURL];
        LOG(@"editAssetsArray:%@", self.editAssetsArray);
    }
    
    for (int i = 0; i < [_videoAssetsDic count]; i++) {
        NSURL *url = [_videoAssetsDic objectForKey:[NSString stringWithFormat:@"%d", i]];
        [self.videoAssetsList addObject:url];
    }
    //クライアントから受け取った写真データの処理
    [self photoEditProcess];
}

- (void)photoEditProcess {
    LOG_METHOD;
    int start = 0;
    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        start = 0;
//    }
    [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:kMessageLoadingPhotoDataFromLibrary];
    
    needToLoadPhotoCount = [self.videoAssetsList count];
    if ([self.videoAssetsList count] != 0) {
        for (int i = start; i < [_videoAssetsList count]; i++) {
            
            self.loadQueue = [NSOperationQueue mainQueue];
            NSURL *url = [_videoAssetsList objectAtIndex:i];
            
            LoadImageOperation *op = [[LoadImageOperation alloc] initWithPhotoURL:url
                                                                    executeNumber:i];
            
            [op addObserver:self
                 forKeyPath:@"isFinished"
                    options:NSKeyValueObservingOptionNew context:nil];
            
            [self.loadQueue addOperation:op];
        }
    }
}

- (void)startImageEditing {
    LOG_METHOD;
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:kMessageEncodingMovie];
    
    CGSize frameSize = kImageFrameSize;
    self.movieEncoder = [[MSImageMovieEncoder alloc] initWithURL:self.pictureSavePath
                                                    andFrameSize:frameSize
                                                andFrameDuration:CMTimeMake(1, 24)]; // 24fps = 24枚で1秒
//                         CMTimeMake(kScalingPhotoToMovieValue, kScalingPhotoToMovieTimeScaling)];
    self.movieEncoder.frameDelegate = self;
    
    [self.movieEncoder startRequestingFrames];
    
}

- (void)countPlusOneForPhotoPicking {
    LOG_METHOD;
    photoLoadCount++;
    
    LOG(@"photoLoadCount:%d", photoLoadCount);
    LOG(@"needToLoadPhotoCount:%d", needToLoadPhotoCount);
    
    if (photoLoadCount == needToLoadPhotoCount) {
        self.loadQueue = nil;
        [self sortPhotosOrder];
    }
}

- (void)sortPhotosOrder {
    LOG_METHOD;
    
    for (int i = 0; i < [_photoImageDic count]; i++) {
        UIImage *image = [_photoImageDic objectForKey:[NSString stringWithFormat:@"%d", i]];
        [self.imageAssetArray addObject:image];
        LOG(@"imageAssetArray Count:%d", [_imageAssetArray count]);
    }
    //写真をビデオに変換するメソッド
    if ([self.imageAssetArray count] > 0) {
        [self startImageEditing];
    }
}

// NSOperationが終了した通知を受け取る
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
                        change:(NSDictionary*)change context:(void*)context {
    
    
    NSOperation *op = (NSOperation *)object;
    
    if ([op isMemberOfClass:[VideoSaveOperation class]]) {
        LOG_METHOD;
        LOG(@"VideoSaveOP finished");
        VideoSaveOperation *operation = (VideoSaveOperation *)op;
        
        if (operation.isFinished) {
            int order = operation.executeNumber;
            NSURL *url = operation.assetURL;
            LOG(@"order = %d, url = %@", order, url);
            
            [self.videoAssetsDic setObject:url forKey:[NSString stringWithFormat:@"%d", order]];
            // キー値監視を解除する
            [operation removeObserver:self forKeyPath:keyPath];
            [operation release], operation = nil;
            
            [self countPlusOne];
        }
    } else if ([op isMemberOfClass:[LoadImageOperation class]]) {
        LoadImageOperation *operation = (LoadImageOperation *)op;
        LOG_METHOD;
        LOG(@"LoadImaegOP finished");
        
        if (operation.isFinished) {
            int order = operation.executeNumber;
            UIImage *image = operation.resultImage;
            LOG(@"order = %d image = %@", order, image);
            
            [self.photoImageDic setObject:image forKey:[NSString stringWithFormat:@"%d", order]];
            // キー値監視を解除する
            [operation removeObserver:self forKeyPath:keyPath];
            [operation release], operation = nil;
            
            [self countPlusOneForPhotoPicking];
        }
    }
}

- (void)mergeAndSaveVideo {
    LOG_METHOD;
    
    [SVProgressHUD dismiss];
    [SVProgressHUD showWithStatus:kMessageMergingMovie];
    
    if ([self.videoAssetsList count] != 0) {
        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        // 2 - Video track
        AVMutableCompositionTrack *mainTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        

        AVAsset *firstAsset = nil;
        int end = 1;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            end = 2;
        }
        
        for (int i = 0; i < end; i++) {
            NSURL *url = [self.editAssetsArray objectAtIndex:i];
            LOG(@"editAssetsURL:%@", url);
            NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber
                                                                        numberWithBool:YES]
                                                                forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
            
            AVURLAsset *currentAsset = [AVURLAsset URLAssetWithURL:url options:options];

            CMTimeRange videoTimeRange = CMTimeRangeMake(kCMTimeZero,currentAsset.duration);
            if (i == 0) {
                if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    firstAsset = currentAsset;
                }
                
                [mainTrack insertTimeRange:videoTimeRange
                                   ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:kCMTimeZero
                                     error:nil];
                
                LOG(@"sourceAssetDurationOfFirstVideo:%f", CMTimeGetSeconds(currentAsset.duration));

            } else {
                [mainTrack insertTimeRange:videoTimeRange
                                   ofTrack:[[currentAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:mixComposition.duration
                                     error:nil];
                
                LOG(@"sourceAssetDurationOfSecondVideo:%f", CMTimeGetSeconds(currentAsset.duration));

                //スローダウン処理
                CMTimeRange range = CMTimeRangeMake(firstAsset.duration, mixComposition.duration);
                double doubleDuration = CMTimeGetSeconds([currentAsset duration]) * 4.0;
                [mainTrack scaleTimeRange:range toDuration:CMTimeMakeWithSeconds(doubleDuration, 600.0)];
            }
        }
        
        LOG(@"totalVideoDuration:%f", CMTimeGetSeconds(mixComposition.duration));

//        //scale対象のtimeRange
//        CMTimeRange sourceTimeRange;
//        //サーバーがiPadの場合、全体をスケールさせる
//        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//            sourceTimeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration);
//        } else {
//        //サーバーがiPhoneの場合、クライアントの映像のみスケールさせる
//            sourceTimeRange = CMTimeRangeMake(firstAsset.duration, mixComposition.duration);
//        }
//        LOG(@"totalSourceDuration:%f", CMTimeGetSeconds(mixComposition.duration));
//        
//        //スケール対象のビデオの秒数
//        Float64 f;
//        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//            f = CMTimeGetSeconds(mixComposition.duration);
//        } else {
//            CMTime time = CMTimeSubtract(mixComposition.duration, firstAsset.duration);
//            f = CMTimeGetSeconds(time);
//        }
//        LOG(@"finalCutsDurationOfBeforeScaling:%f", f);
//
//        int64_t t = kScalingCMTimeValue * (kScalingRatio * f);
//        CMTime targetTime = CMTimeMake(t, kScalingCMTimeTimeScaling);
//        
//        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//            [mainTrack scaleTimeRange:sourceTimeRange toDuration:targetTime];
//        } else {
//
//        }
//        LOG(@"finalCutsDurationOfAfterScaling:%f", CMTimeGetSeconds(mixComposition.duration));
        

        // 3 - Audio track
//        if (audioAsset!=nil){
//            AVMutableCompositionTrack *AudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
//                                                                                preferredTrackID:kCMPersistentTrackID_Invalid];
//            [AudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration))
//                                ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
//        }
        
        // 4 - Get path
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        
        NSString *myPathDocs =
        [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"mergeVideo%@-%d.mov", [dateFormatter stringFromDate:[NSDate date]] , arc4random() % 1000]];
        
        NSURL *url = [NSURL fileURLWithPath:myPathDocs];
        // 5 - Create exporter
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetHighestQuality];
        exporter.outputURL = url;
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self exportDidFinish:exporter];
            });
        }];
    }
}

-(void)exportDidFinish:(AVAssetExportSession*)session {
    LOG_METHOD;
    
    [SVProgressHUD dismiss];
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        if ([self.library videoAtPathIsCompatibleWithSavedPhotosAlbum:outputURL]) {
            [self.library writeVideoAtPathToSavedPhotosAlbum:outputURL completionBlock:^(NSURL *assetURL, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Video export failed alert title") message:NSLocalizedString(@"Video Saving Failed", @"Video export failed alert message")
                                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"Button: OK")
                                                              otherButtonTitles:nil];
                        [alert show];
                        [alert release];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Video Saved", @"Video export success alert title")  message:NSLocalizedString(@"Saved To Photo Album Completed.Tap the Open Image Picker Button to Watch the FinalCut"
, @"Video export success alert message")                                                                        delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                        [alert release];
                        self.btnOpenLibrary.enabled = YES;
                    }
                });
            }];
        }
    }
}

- (void)saveFileToDocuments:(NSData *)videoData {
    LOG_METHOD;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	self.destinationPath =
    [documentsDirectory stringByAppendingFormat:@"/output%@.mov", [dateFormatter stringFromDate:[NSDate date]]];
	[dateFormatter release];
    
    BOOL success = [videoData writeToFile:_destinationPath atomically:YES];
    if (!success) {
        LOG(@"VideoSave Failed");
    }
}

//クライアントから受け取った写真をビデオにするパスの作成
- (void)makePictureSavePath {
    LOG_METHOD;
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	self.pictureSavePath =
    [NSURL fileURLWithPath:[documentsDirectory stringByAppendingFormat:@"/output-clients-movie%@.mov", [dateFormatter stringFromDate:[NSDate date]]]];
	[dateFormatter release];
}

- (void)removeFile:(NSURL *)fileURL
{
    NSString *filePath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:filePath error:&error] == NO) {

        }
    }
}

- (IBAction)showImagePicker:(UIBarButtonItem *)sender {
    if ([self startMediaBrowserFromViewController:self usingDelegate:self sender:sender]) {
        // nothing
    } else {
        
    }
}

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller
                              usingDelegate:(id)del
                                     sender:(UIBarButtonItem *)sender {
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
    } else {
        _popOverController = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
        [_popOverController presentPopoverFromBarButtonItem:sender
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];
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
    } else {
        [_popOverController dismissPopoverAnimated:YES];
    }

    // 1 - Get media type
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];

    // Handle a movie capture
    if (CFStringCompare ((CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        // 2 - Play the video
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
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
            
        } else {
            if ([self.delegate respondsToSelector:@selector(receiveViewController:didFinishPickingMediaWithURL:)]) {
                [self.delegate receiveViewController:self didFinishPickingMediaWithURL:url];
            }
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
        [self dismissModalViewControllerAnimated:YES];
#endif
    } else {
        [_popOverController dismissPopoverAnimated:YES];
    }
}

#pragma mark - AVPlayerViewController deleagte
- (void)dismissAVPlayerViewController {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    [self dismissViewControllerAnimated:NO completion:nil];
#endif
    // iOS 6 以前で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 60000
    [self dismissModalViewControllerAnimated:YES];
#endif
}

#pragma mark - AutoRotation Support Methods

#pragma mark  iOS 6 or later
// iOS 6 SDK 以降で有効
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (NSUInteger)supportedInterfaceOrientations
{

    return UIInterfaceOrientationMaskPortrait;
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
    if ((interfaceOrientation == UIInterfaceOrientationPortrait))
        return YES;
    return NO;
}
#endif

#pragma mark - MSImageMovieEncoderFrameProvider
-(void)movieEncoderDidFailWithReason:(NSString*)reason {
    //it's failed.  It's in an unpredictable state, the movie may exist but it's probably garbage if it does.
    [SVProgressHUD dismiss];
    [SVProgressHUD showErrorWithStatus:kMessageEncodingMovieFailed];
    LOG_METHOD;
    LOG(@"%@", reason);
}

-(void)movieEncoderDidFinishAddingFrames {
    LOG_METHOD;
    //all that's left is the remaining compression (very quick)
}

-(void)movieEncoderDidFinishEncoding {
    LOG_METHOD;
    //it's actually finished now, you can release it,
    //if you like you can ask for the fileURL first so you know where the movie went
    [self.editAssetsArray addObject:self.pictureSavePath];
    LOG(@"editAssetsArray:%@", self.editAssetsArray);
    [self mergeAndSaveVideo];

}

-(BOOL)nextFrameInCVPixelBuffer:(CVPixelBufferRef*)pixelBuf {
    LOG_METHOD;
    if (pictureCount == [self.imageAssetArray count]) {
        return NO;
    }
    
    UIImage *image = [self.imageAssetArray objectAtIndex:pictureCount];
    LOG(@"imageNo.%d: beforeResize: width:%f height:%f", pictureCount, image.size.width, image.size.height);
    
    image = [UIImage getResizedImage:image size:kImageFrameSize];
    CGImageRef imageRef = [image CGImage];
    *pixelBuf = [self pixelBufferFromCGImage:imageRef];
    pictureCount++;
    
    return YES;
}

//CGImageRefからCVPixelBufferRefに変換するメソッド
- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    LOG_METHOD;
    LOG(@"%@", image);
    
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:NO], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width,
                                          frameSize.height,  kCVPixelFormatType_32ARGB, (CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, frameSize.width,
                                                 frameSize.height, 8, 4*frameSize.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
