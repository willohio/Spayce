//
//  SPCCustomNavigationController.m
//  Spayce
//
//  Created by William Santiago on 6/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCustomNavigationController.h"

@implementation SPCCustomNavigationController

#pragma mark - Object lifecycle

-(void)dealloc {
    NSLog(@"custom nav dealloc");
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController {
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        _spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    }
    return self;
}

#pragma mark - Orientation

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)shouldAutorotate {
    if (UIInterfaceOrientationIsPortrait(self.spc_interfaceOrientation)) {
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        return NO;
    }
    else {
        return YES;
    }
}

@end
