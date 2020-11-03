//
//  UIColor+SPCAdditions.m
//  Spayce
//
//  Created by Pavel Dusatko on 9/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UIColor+SPCAdditions.h"

@implementation UIColor (SPCAdditions)

+ (UIColor *)spc_navigationBarColor {
    return [[self class] spc_navigationBarColorWithAlpha:0.95];
}

+ (UIColor *)spc_navigationBarColorWithAlpha:(CGFloat)alpha {
    return [UIColor colorWithRed:63.0/255.0 green:85.0/255.0 blue:120.0/255.0 alpha:alpha];
}

+ (UIColor *)spc_navigationItemDoneColor {
    return [UIColor colorWithRed:106.0/255.0 green:177.0/255.0 blue:251.0/255.0 alpha:1.0];
}

+ (UIColor *)spc_tableViewBackgroundColor {
    return [UIColor colorWithRed:240.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0];
}

@end
