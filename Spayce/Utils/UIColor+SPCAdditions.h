//
//  UIColor+SPCAdditions.h
//  Spayce
//
//  Created by William Santiago on 9/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SPCAdditions)

+ (UIColor *)spc_navigationBarColor;
+ (UIColor *)spc_navigationBarColorWithAlpha:(CGFloat)alpha;
+ (UIColor *)spc_navigationItemDoneColor;

+ (UIColor *)spc_tableViewBackgroundColor;

@end
