//
//  HostVideoDataReceiveViewController.h
//  TimeSliceCam
//
//  Created by Bane on 12/11/08.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoDataTransferSession.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AVPlayerViewController.h"
#import "MSImageMovieEncoder.h"

@class HostVideoDataReceiveViewController;
@protocol HostVideoDataReceiveViewControllerDelegate <NSObject>

- (void)receiveViewController:(HostVideoDataReceiveViewController *)controller
 didFinishPickingMediaWithURL:(NSURL *)mediaUrl;

@end

@interface HostVideoDataReceiveViewController : UIViewController
<UITableViewDelegate, UITableViewDataSource, VideoDataTransferSessionDelegate,
UIImagePickerControllerDelegate, AVPlayerViewControllerDelagate, MSImageMovieEncoderFrameProvider> {
    IBOutlet UINavigationBar *naviBar;
    IBOutlet UINavigationItem *titleItem;
}

@property (nonatomic, retain) VideoDataTransferSession *transferSession;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIButton *btnOpenLibrary;
@property (nonatomic, retain) NSString *destinationPath;    //ホストで撮ったビデオの保存パス
@property (nonatomic, retain) NSURL *pictureSavePath;    //クライアントから受け取った写真の編集後保存パス
@property (nonatomic, retain) UIView *videoView;
@property (nonatomic, retain) ALAssetsLibrary *library;
@property (nonatomic, retain) NSOperationQueue *saveQueue;
@property (nonatomic, retain) NSOperationQueue *loadQueue;
@property (nonatomic, retain) NSURL *hostVideoURL;
@property (nonatomic, assign) id <HostVideoDataReceiveViewControllerDelegate> delegate;
//写真をビデオに変換するオブジェクトのインスタンス
@property (nonatomic, retain) MSImageMovieEncoder *movieEncoder;


- (IBAction)showImagePicker:(id)sender;
- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id )del sender:(UIBarButtonItem *)sender;

@end
