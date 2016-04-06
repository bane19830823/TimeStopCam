//
//  GoogleManager.h
//  TimeSliceCam
//
//  Created by Bane on 13/4/23.
//  Copyright 2013年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SingletonManager.h"
#import "GData.h"
#import "GTMOAuth2Authentication.h"

@class GoogleManager;
@protocol GoogleManagerDelegate <NSObject>

//認証成功時にデリゲートに通知する
- (void)googleManegerLadyForUploadVideoWithAuth:(GTMOAuth2Authentication *)auth;

//認証がキャンセルされた時に実行するデリゲート
- (void)googleManagerDidRequestCanceled;

@end

@class GTMOAuth2ViewControllerTouch;

@interface GoogleManager : SingletonManager {
    id <GoogleManagerDelegate> delegate;
    GTMOAuth2Authentication *oAuth;
}

@property (nonatomic, assign) id <GoogleManagerDelegate> delegate;
@property (nonatomic, retain) GTMOAuth2Authentication *oAuth;
@property (nonatomic, retain) NSString *googleMailAddress;

//Google認証ビューの初期化
- (GTMOAuth2ViewControllerTouch *)signInToGoogle;

//ログイン認証のコールバック
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController 
      finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error;

//認証済みかどうか
- (BOOL)isSignedIn;

//Googleサービスからサインアウトする
- (void)signOut;

//Googleアカウントのメールアドレスを取得する
- (NSString *)getGoogleMailAddress;

//キーチェーンに保存されているトークンで認証出来るか確認する
- (GTMOAuth2Authentication *)authWithKeyChain;

@end
