//
//  GoogleManager.m
//  TimeSliceCam
//
//  Created by Bane on 13/4/23.
//  Copyright 2013年 Bane. All rights reserved.
//

#import "GoogleManager.h"
#import "GData.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2SignIn.h"
#import "GTMOAuth2Authentication.h"

@implementation GoogleManager

@synthesize delegate = _delegate;
@synthesize oAuth = _oAuth;
@synthesize googleMailAddress = _googleMailAddress;

//Google認証ビューの初期化
- (GTMOAuth2ViewControllerTouch *)signInToGoogle {
    [self signOut];
    
    NSString *scope = @"http://gdata.youtube.com";
        
    GTMOAuth2ViewControllerTouch *googleLogin = nil;

    googleLogin = [[[GTMOAuth2ViewControllerTouch alloc] initWithScope:scope
                                                              clientID:GoogleClientID
                                                          clientSecret:GoogleClientSecret
                                                      keychainItemName:GoogleKeyChainName
                                                              delegate:self
                                                      finishedSelector:@selector(viewController:finishedWithAuth:error:)] autorelease];
//このプロパティーをYESにする事で、ユーザー情報の取得が可能になります。
    googleLogin.signIn.shouldFetchGoogleUserProfile = YES;

    
    return googleLogin;
}

//認証が成功した時、キャンセルされた時に実行される
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
    

    
    if (error != nil) {
        //エラー処理(認証失敗または、認証キャンセル)
        LOG(@"Google認証失敗:%@", error);
        NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
        if ([responseData length] > 0) {
            // show the body of the server's authentication failure response
            NSString *str = [[[NSString alloc] initWithData:responseData
                                                   encoding:NSUTF8StringEncoding] autorelease];
            LOG(@"%@", str);
            self.oAuth = nil;
        }
        if ([self.delegate respondsToSelector:@selector(googleManagerDidRequestCanceled)]) {
            [self.delegate googleManagerDidRequestCanceled];
        }
    } else {
        //認証成功
        LOG(@"Google認証成功");

        NSDictionary *result = viewController.signIn.userProfile;
        LOG(@"Google認証結果:%@", result);
        self.googleMailAddress = [result objectForKey:@"email"];
        
        self.oAuth = auth;
        if ([self.delegate respondsToSelector:@selector(googleManegerLadyForUploadVideoWithAuth:)]) {
            [self.delegate googleManegerLadyForUploadVideoWithAuth:self.oAuth];
        }
    }
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error {
    if (error != nil) {
        // Authorization failed
    } else {
        // Authorization succeeded
        // save the authentication object
    }
}

- (BOOL)isSignedIn {
    BOOL isSignedIn = self.oAuth.canAuthorize;
    return isSignedIn;
}

- (void)signOut {
    if ([self.oAuth.serviceProvider isEqual:kGTMOAuth2ServiceProviderGoogle]) {
        // remove the token from Google's servers
        [GTMOAuth2ViewControllerTouch revokeTokenForGoogleAuthentication:self.oAuth];
    }
    
    // remove the stored Google authentication from the keychain, if any
    [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:GoogleKeyChainName];
    
    // Discard our retained authentication object.
    self.oAuth = nil;
}

- (NSString *)getGoogleMailAddress {
    return self.googleMailAddress;
}

- (GTMOAuth2Authentication *)authWithKeyChain {
    //キーチェーンにトークンが保存されているか確認
    GTMOAuth2Authentication *auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:GoogleKeyChainName
                                                                       clientID:GoogleClientID
                                                                   clientSecret:GoogleClientSecret];
    if (auth.canAuthorize) {
        return auth;
    } else {
        return nil;
    }
}

- (void)dealloc {
    self.delegate = nil;
    self.oAuth = nil;
    self.googleMailAddress = nil;
    [super dealloc];
}
    
                                                 
                                        
                                                  
                                                  
@end
