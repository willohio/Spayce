//
//  UIColor-Expanded.h
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor(Expanded)

+ (UIColor *)colorWithRGBHex:(UInt32)hex;
+ (UIColor *)colorWithRGBHex:(UInt32)hex alpha:(CGFloat) alpha;

@end
