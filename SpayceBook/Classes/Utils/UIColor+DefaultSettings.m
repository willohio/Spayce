//
//  UIColor+DefaultSettings.m
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "UIColor+DefaultSettings.h"

@implementation UIColor (DefaultSettings)

#pragma mark - General

+ (UIColor *)shadowColor {
    return [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];;
}

+ (UIColor *)primaryActionButtonColor {
    return [UIColor colorWithRGBHex:0x005581];
}

+ (UIColor *)selectionColor {
    return [UIColor colorWithRGBHex:0xc7ac65 alpha:0.3];
}

#pragma mark - Memories

+ (UIColor *)memory_normalBackgroundColor {
    return [UIColor colorWithRed:238.0/255.0 green:233.0/255.0 blue:230.0/255.0 alpha:1.0];
}

+ (UIColor *)memory_normalTitleForegroundColor {
    return [UIColor colorWithWhite:108.0/255.0 alpha:1.0];
}

+ (UIColor *)memory_normalSubtitleForegroundColor {
    return [UIColor colorWithWhite:164.0/255.0 alpha:1.0];
}

+ (UIColor *)memory_normalCountdownForegroundColor {
    return [UIColor colorWithRed:254.0/255.0 green:129.0/255.0 blue:27.0/255.0 alpha:1.0];
}

+ (UIColor *)memory_vipBackgroundColor {
    return [UIColor colorWithRed:248.0/255.0 green:200.0/255.0 blue:122.0/255.0 alpha:1.0];
}

+ (UIColor *)memory_vipTitleForegroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)memory_vipSubtitleForegroundColor {
    return [UIColor colorWithRed:134.0/255.0 green:106.0/255.0 blue:66.0/255.0 alpha:1.0];
}

+ (UIColor *)memory_vipCountdownForegroundColor {
    return [UIColor colorWithRed:134.0/255.0 green:106.0/255.0 blue:66.0/255.0 alpha:1.0];
}

@end
