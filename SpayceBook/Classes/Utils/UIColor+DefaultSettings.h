//
//  UIColor+DefaultSettings.h
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIColor (DefaultSettings)

// General
+ (UIColor *)shadowColor;
+ (UIColor *)primaryActionButtonColor;
+ (UIColor *)selectionColor;

// Memories
+ (UIColor *)memory_normalBackgroundColor;
+ (UIColor *)memory_normalTitleForegroundColor;
+ (UIColor *)memory_normalSubtitleForegroundColor;
+ (UIColor *)memory_normalCountdownForegroundColor;
+ (UIColor *)memory_vipBackgroundColor;
+ (UIColor *)memory_vipTitleForegroundColor;
+ (UIColor *)memory_vipSubtitleForegroundColor;
+ (UIColor *)memory_vipCountdownForegroundColor;

@end
