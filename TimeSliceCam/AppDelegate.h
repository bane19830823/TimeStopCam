//
//  AppDelegate.h
//  TimeSliceCam
//
//  Created by Bane on 12/09/23.
//  Copyright (c) 2012年 Bane. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HostMainViewController;
@class MainViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;

@property (nonatomic, retain) HostMainViewController *hostMainViewController;
@property (nonatomic, retain) MainViewController *mainViewController;

//撮影モードを判定する変数...サーバー側のみで使用する
//ShootingMode_iPhone_iPhone,     //サーバー:iPhone/Touch クライアント:iPhone/Touch
//ShootingMode_iPad_iPhone        //サーバー:iPad         クライアント:iPhone/Touch
@property (nonatomic, assign) ShootingMode globalShootingMode;

//サーバーかクライアントかのフラグ
@property (nonatomic, assign) BOOL isServer;

@end
