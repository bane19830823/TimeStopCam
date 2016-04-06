//
//  SingletonManager.h
//  TimeSliceCame
//
//  Created by Bane on 13/4/23.
//  Copyright 2013年 Bane. All rights reserved.
//
///////////////////////////////////

#import <Foundation/Foundation.h>

@interface SingletonManager : NSObject {
    
}

+ (SingletonManager *)sharedManager;

/**
 * このクラスが管理する全てのマネジャークラスを解放する
 */
- (void)releaseAllManagers;

@end
