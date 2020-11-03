//
//  SPCColorManager.m
//  Spayce
//
//  Created by Howard Cantrell on 7/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCColorManager.h"
#import "Singleton.h"

@implementation SPCColorManager

SINGLETON_GCD(SPCColorManager);

- (UIColor *)nameNormalColor {
    return [UIColor colorWithRed:1.0f/255.0f green:24.0f/255.0f blue:38.0f/255.0f alpha:1.0f];
}

- (UIColor *)buttonDisabledColor {
    return [UIColor colorWithRGBHex:0x3f5578 alpha:1.0f];
}

- (UIColor *)buttonEnabledColor {
    return [UIColor colorWithRGBHex:0x6ab1fb alpha:1.0f];
}

- (UIColor *)buttonEnabledFadedColor {
    return [UIColor colorWithRGBHex:0x6ab1fb alpha:0.4f];
}



@end
