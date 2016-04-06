//
//  ClientVideoDataTransferViewController.m
//  TimeSliceCam
//
//  Created by Bane on 12/10/29.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import "ClientVideoDataTransferViewController.h"
#import "VideoDataTransferSession.h"
#import "Packet.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface ClientVideoDataTransferViewController ()
@property (nonatomic, retain) NSData *photoData;
@property (nonatomic, retain) ALAssetsLibrary* assetslibrary;
@end

@implementation ClientVideoDataTransferViewController

@synthesize sendSession = _sendSession;
@synthesize previewView = _previewView;
@synthesize photoData = _photoData;
@synthesize assetslibrary = _assetslibrary;
@synthesize mainViewController = _mainViewController;

- (void)dealloc {
    self.sendSession = nil;
    self.previewView = nil;
    self.photoData = nil;
    self.assetslibrary = nil;
    self.mainViewController = nil;
    
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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - VideoDataSendSession delegate
- (void)showVideoPreview:(NSURL *)url {
    LOG_METHOD;
    //サーバーの準備ができるまで、送信ボタンを無効にしておく
    sendButton.enabled = NO;
    
    //写真取得に成功
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *representation = [myasset defaultRepresentation];
        UIImage *img = [UIImage imageWithCGImage:[representation fullResolutionImage]
                                           scale:[representation scale]
                                     orientation:[representation orientation]];
        
        self.photoData = [[[NSData alloc] initWithData:UIImageJPEGRepresentation(img, kResultImagecompressionQuality)] autorelease];
        
        self.previewView.image = img;
        
//        //サーバーに写真データを送信する
//        [self sendVideoDataToServer];
    };
    
    //写真取得に失敗
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        LOG(@"Failed To Get Image From Library - %@",[myerror localizedDescription]);
        LOG(@"Failed To Get Image From Library - %@",[myerror localizedFailureReason]);
    };
    
    //ライブラリから写真を取得
    if(url)
    {
        self.assetslibrary = [[[ALAssetsLibrary alloc] init] autorelease];
        [self.assetslibrary assetForURL:url
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }
    [self.view bringSubviewToFront:sendButton];
}

- (void)dataTransferFinished {
    [self.mainViewController dataTransferFinished];
}

- (void)readyForSendData {
    LOG_METHOD;
    sendButton.enabled = YES;
}

#pragma mark - Send Data To Server
//クライアントからサーバーに写真データを送信する
- (IBAction)sendVideoDataToServer:(id)sender {
    LOG_METHOD;
    LOG(@"PhotoData Bytes:%d", [self.photoData length]);
    sendButton.enabled = NO;

    [self.sendSession sendVideoDataToServer:self.photoData];
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
        return 
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
    if ((interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    return NO;
}
#endif

@end
