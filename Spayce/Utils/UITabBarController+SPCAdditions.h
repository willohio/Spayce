//
//  UITabBarController+SPCAdditions.h
//  Spayce
//
//  Created by William Santiago on 10/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITabBarController (SPCAdditions)

@property (nonatomic, readonly) BOOL didSlideTabBarHidden;

- (void)setTabBarHidden:(BOOL)hidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)slideTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@end
