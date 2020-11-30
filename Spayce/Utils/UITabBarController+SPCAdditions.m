//
//  UITabBarController+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 10/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UITabBarController+SPCAdditions.h"

@interface UITabBarController ()

@property (nonatomic, assign) BOOL isListeningForNotifications;

@end

@implementation UITabBarController (SPCAdditions)

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTabBarHidden:(BOOL)hidden {
    [self setTabBarHidden:hidden animated:YES];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    [UIView animateWithDuration:(animated ? 0.35 : 0) animations:^{
        // use the bounds of self.view, not the frame, to determine tab bar position.
        // We have a tendency to slide this view controller around and we don't want
        // to leave the tab bar behind.
        CGRect frame = self.tabBar.frame;
        frame.origin.y = CGRectGetMaxY(self.view.bounds) + (hidden ? 1 : -1) * CGRectGetHeight(frame);
        self.tabBar.frame = frame;
        self.tabBar.alpha = !hidden;
    }];
    [self registerForNotifications];
}


- (void)slideTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    if (!hidden) {
        self.tabBar.alpha = 1;
    }
    [UIView animateWithDuration:(animated ? 0.35 : 0) animations:^{
        // use the bounds of self.view, not the frame, to determine tab bar position.
        // We have a tendency to slide this view controller around and we don't want
        // to leave the tab bar behind.
        CGRect frame = self.tabBar.frame;
        frame.origin.y = CGRectGetMaxY(self.view.bounds) + (hidden ? 1 : -1) * CGRectGetHeight(frame);
        self.tabBar.frame = frame;
    }];
    [self registerForNotifications];
}

- (BOOL)didSlideTabBarHidden {
    CGRect frame = self.tabBar.frame;
    return frame.origin.y >= CGRectGetMaxY(self.view.bounds);
}

- (void)showTabBarAfterApplicationBecameActive {
    [self setTabBarHidden:NO animated:YES];
}

- (void)registerForNotifications {
    static BOOL isListeningForNotifications = NO;
    if (!isListeningForNotifications) {
        NSLog(@"registering for notifications");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showTabBarAfterApplicationBecameActive) name: UIApplicationDidBecomeActiveNotification object:nil];
        isListeningForNotifications = YES;
    }
}

@end
