//
//  UITabBar+SPCAdditions.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UITabBar+SPCAdditions.h"

static CGFloat tabBarHeight = 45.0;

@implementation UITabBar (SPCAdditions)

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize auxSize = size;
    auxSize.height = tabBarHeight;
    return auxSize;
}

@end
