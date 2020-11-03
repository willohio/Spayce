//
//  UIScreen+Size.m
//  RewardsPay
//
//  Created by Pavel Dušátko on 3/22/13.
//  Copyright (c) 2013 RewardsPay. All rights reserved.
//

#import "UIScreen+Size.h"

@implementation UIScreen (Size)

+ (BOOL)isLegacyScreen
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    return screenSize.height == 480;
}

@end
