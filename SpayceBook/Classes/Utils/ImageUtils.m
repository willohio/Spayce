//
//  ImageUtils.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/24/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "ImageUtils.h"

@implementation ImageUtils

+ (UIImage *)imageFromLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContext(layer.bounds.size);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return res;
}

+ (UIImage *)rescaleImage:(UIImage *)image toSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return res;
}

+ (UIImage *)rescaleImageToScreenBounds:(UIImage *)originalImage
{
    BOOL isPortrait = originalImage.size.height > originalImage.size.width;
    CGFloat newWidth = 0;
    CGFloat newHeight = 0;
    CGFloat aspectRatio = originalImage.size.width / originalImage.size.height;
    
    if (isPortrait)
    {
        
        newWidth = [UIScreen mainScreen].bounds.size.width;
        newHeight = newWidth / aspectRatio;
    }
    else
    {
        newHeight = [UIScreen mainScreen].bounds.size.height;
        newWidth  = newHeight * aspectRatio;
    }

    return [ImageUtils rescaleImage:originalImage toSize:CGSizeMake(newWidth, newHeight)];
}

+ (UIImage *)imageByCroppingRect:(CGRect)cropRect fromImage:(UIImage *)image
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return img;
}

+ (UIImage *)roundedRectImageWithColor:(UIColor *)color size:(CGSize)size
{
    return [ImageUtils roundedRectImageWithColor:color size:size corners:(size.height / 2.0f)];
}

+ (UIImage *)roundedRectImageWithColor:(UIColor *)color size:(CGSize)size corners:(CGFloat)corners
{
    return [ImageUtils roundedRectImageWithColor:color size:size corners:corners shadow:NO];
}

+ (UIImage *)roundedRectImageWithColor:(UIColor *)color size:(CGSize)size corners:(CGFloat)corners shadow:(BOOL)shadow;
{
    CGRect contentRect;

    if (shadow)
    {
        CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        contentRect = CGRectInset(rect, corners, corners);
    }
    else
    {
        contentRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIBezierPath *roundedPath = [UIBezierPath bezierPathWithRoundedRect:contentRect cornerRadius:corners];

    CGContextSetFillColorWithColor(context, [color CGColor]);

    if (shadow)
    {
        CGContextSetShadowWithColor(context, CGSizeMake(0.0, 0.0), corners, [[UIColor blackColor] CGColor]);
    }

    [roundedPath fill];
    [roundedPath addClip];

    if (shadow)
    {
        CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:1.0 alpha:0.6].CGColor);
        CGContextSetBlendMode(context, kCGBlendModeOverlay);

        CGContextMoveToPoint(context, CGRectGetMinX(contentRect), CGRectGetMinY(contentRect)+0.5);
        CGContextAddLineToPoint(context, CGRectGetMaxX(contentRect), CGRectGetMinY(contentRect)+0.5);
        CGContextStrokePath(context);
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
