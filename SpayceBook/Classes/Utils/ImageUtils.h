//
//  ImageUtils.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/24/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageUtils : NSObject

+ (UIImage *)imageFromLayer:(CALayer *) layer;
+ (UIImage *)rescaleImage:(UIImage *) image toSize:(CGSize) newSize;
+ (UIImage *)rescaleImageToScreenBounds:(UIImage *) originalImage;
+ (UIImage *)imageByCroppingRect:(CGRect) cropRect fromImage:(UIImage *) image;
+ (UIImage *)roundedRectImageWithColor:(UIColor *)color size:(CGSize)size;
+ (UIImage *)roundedRectImageWithColor:(UIColor *)color size:(CGSize)size corners:(CGFloat)corners;
+ (UIImage *)roundedRectImageWithColor:(UIColor *)color size:(CGSize)size corners:(CGFloat)corners shadow:(BOOL)shadow;

@end
