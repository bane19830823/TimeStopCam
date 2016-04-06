//
//  UIImage+resizeAspectFit.m
//  TimeSliceCam
//
//  Created by Bane on 13/01/23.
//  Copyright (c) 2013年 Bane. All rights reserved.
//

#import "UIImage+resizeAspectFit.h"

#define radians( degrees ) ( degrees * M_PI / 180 )

@implementation UIImage (ResizeAspectFit)

+ (UIImage *)getResizedImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height
{
	if (UIGraphicsBeginImageContextWithOptions != NULL) {
		UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [[UIScreen mainScreen] scale]);
	} else {
		UIGraphicsBeginImageContext(CGSizeMake(width, height));
	}
    
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh); // 高品質リサイズ
    
	[image drawInRect:CGRectMake(0.0, 0.0, width, height)];
    
	UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
	UIGraphicsEndImageContext();
    
	return resizedImage;
}

+ (UIImage *)getResizedImage:(UIImage *)image size:(CGSize)size
{
	return [UIImage getResizedImage:image width:size.width height:size.height];
}

@end
