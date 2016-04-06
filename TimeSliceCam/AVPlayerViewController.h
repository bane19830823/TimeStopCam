//
//  AVPlayerViewController.h
//  VideoPlayer
//
//  Created by Akabeko on 2012/09/30.
//  Copyright (c) 2012年 Akabeko. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVPlayerView.h"
#import "GoogleManager.h"
#import "GData.h"
#import "GTMOAuth2Authentication.h"
#import "YouTubeUploaderViewController.h"
/**
 * AVPlayerによる動画再生クラス
 */

@protocol AVPlayerViewControllerDelagate <NSObject>
//AVplayerViewControllerをdismiss
- (void)dismissAVPlayerViewController;

@end

@interface AVPlayerViewController : UIViewController <UIActionSheetDelegate, GoogleManagerDelegate, YouTubeUploaderViewControllerDelegate> {
    UIBarButtonItem *btnUpload;
    UIBarButtonItem *done;
}

@property (nonatomic, retain) IBOutlet AVPlayerView* videoPlayerView;  //! 動画表示
@property (nonatomic, retain) IBOutlet UIView*       playerToolView;   //! プレイヤー操作部
@property (nonatomic, retain) IBOutlet UIButton*     playButton;       //! 再生・一時停止ボタン
@property (nonatomic, retain) IBOutlet UILabel*      currentTimeLabel; //! 現在の再生時間ラベル
@property (nonatomic, retain) IBOutlet UISlider*     seekBar;          //! 再生位置スライダー
@property (nonatomic, retain) IBOutlet UILabel*      durationLabel;    //! 演奏時間ラベル
@property (nonatomic, retain) IBOutlet UINavigationBar *naviBar;       //! ナビゲーションバー
@property (nonatomic, assign) id <AVPlayerViewControllerDelagate> delegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil videoURL:(NSURL *)videoURL;
- (void)dismissAVPlayer:(id)sender;
- (void)upload:(id)sender;

@end
