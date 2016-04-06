//
//  UIImage+resizeAspectFit.h
//  TimeSliceCam
//
//  Created by Bane on 13/01/23.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (ResizeAspectFit)
+ (UIImage *)getResizedImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height;
+ (UIImage *)getResizedImage:(UIImage *)image size:(CGSize)size;
@end
