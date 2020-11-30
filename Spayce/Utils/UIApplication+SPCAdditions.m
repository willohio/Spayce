//
//  UIApplication+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 5/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UIApplication+SPCAdditions.h"

@implementation UIApplication (SPCAdditions)

- (void)addSubviewToWindow:(UIView *)view {
    NSInteger count = self.windows.count;
    UIWindow *window = self.windows[count - 1];
    [window addSubview:view];
}

@end
