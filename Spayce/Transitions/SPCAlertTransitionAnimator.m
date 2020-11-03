//
//  SPCAlertTransitionAnimator.m
//  Spayce
//
//  Created by Pavel Dusatko on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAlertTransitionAnimator.h"

@implementation SPCAlertTransitionAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.0;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (self.presenting) {
        UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext completeTransition:YES];
    }
    else {
        UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
        [fromViewController.view removeFromSuperview];
        [transitionContext completeTransition:YES];
    }
}

@end
