//
//  SingletonManager.m
//  TimeSliceCam
//
//  Created by Bane on 11/10/24.
//  Copyright 2013年 Bane. All rights reserved.
//

#import "SingletonManager.h"

@implementation SingletonManager

//このクラスを継承した各マネジャークラスを、ディクショナリーで管理します。
//アプリケーション終了時等に、'releaseAllManagers'メソッドをコールします。

static NSMutableDictionary *_instances = nil;

+ (SingletonManager *)sharedManager {
    @synchronized(self) {
        if ([_instances objectForKey:NSStringFromClass(self)] == nil) {
            [[self alloc] init];
        }
    }
    return [_instances objectForKey:NSStringFromClass(self)];
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if ([_instances objectForKey:NSStringFromClass(self)] == nil) {
            id instance = [super allocWithZone:zone];
            if ([_instances count] == 0) {
                _instances = [[NSMutableDictionary alloc] initWithCapacity:0];
            }
            [_instances setObject:instance forKey:NSStringFromClass(self)];
            return  instance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;
}

- (oneway void)release {
    
}

- (id)autorelease {
    return self;
}

- (void)releaseAllManagers {
    //このクラスが管理するデータ保持クラスを解放する。
    [_instances release], _instances = nil;
}

@end
