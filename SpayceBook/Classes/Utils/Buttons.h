//
//  Buttons.h
//  SpayceCard
//
//  Created by Dmitry Miller on 5/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Buttons : NSObject

// Navigation bar button item
+ (NSArray *)navBarItemsWithTitle:(NSString *)title titleColor:(UIColor *)titleColor backgroundColor:(UIColor *)backgroundColor target:(id)target action:(SEL)action;
// Navigation bar back button item
+ (NSArray *)backNavBarButtonsWithTarget:(id)target action:(SEL)action;
+ (NSArray *)backNavBarButtonsWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (NSArray *)backNavBarCancelButtonsWithTarget:(id)target action:(SEL)action;

@end
