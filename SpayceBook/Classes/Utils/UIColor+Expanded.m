//
//  UIColor-Expanded.m
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "UIColor+Expanded.h"

@implementation UIColor(Expanded)

+ (UIColor *)colorWithRGBHex:(UInt32)hex
{
    return [UIColor colorWithRGBHex:hex alpha:1.0];
}

+ (UIColor *)colorWithRGBHex:(UInt32)hex alpha:(CGFloat) alpha
{
    int r = (hex >> 16) & 0xFF;
    int g = (hex >> 8) & 0xFF;
    int b = (hex) & 0xFF;
    
    return [UIColor colorWithRed:r / 255.0f
                           green:g / 255.0f
                            blue:b / 255.0f
                           alpha:alpha];
}

@end
