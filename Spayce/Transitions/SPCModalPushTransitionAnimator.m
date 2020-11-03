//
//  SPCModalPushTransitionAnimator.m
//  Spayce
//
//  Created by Jake Rosin on 10/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//
//  A VC transition animator meant to simulate the default "push" / "pop" animations
//  when displaying a modal view controller.  Feel free to tweak this if you can
//  get it closer to the default animation, especially if you have a reference implementation
//

#import "SPCModalPushTransitionAnimator.h"

@implementation SPCModalPushTransitionAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    // Grab the from and to view controllers from the context
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    CGRect screenFrame = [[UIScreen mainScreen] bounds];

    if (self.presenting) {
        fromViewController.view.userInteractionEnabled = NO;
        toViewController.view.userInteractionEnabled = NO;
        
        CGRect toStartFrame = screenFrame;
        toStartFrame.origin.x += [[UIScreen mainScreen] bounds].size.width;
        CGRect fromEndFrame = screenFrame;
        fromEndFrame.origin.x -= [[UIScreen mainScreen] bounds].size.width/3;
        
        [transitionContext.containerView addSubview:fromViewController.view];
        [transitionContext.containerView addSubview:toViewController.view];
        
        toViewController.view.frame = toStartFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
            fromViewController.view.frame = fromEndFrame;
            toViewController.view.frame = screenFrame;
        } completion:^(BOOL finished) {
            toViewController.view.userInteractionEnabled = YES;
            [transitionContext completeTransition:YES];
        }];
    }
    else {
        CGRect toStartFrame = screenFrame;
        toStartFrame.origin.x -= [[UIScreen mainScreen] bounds].size.width/3;
        CGRect fromEndFrame = screenFrame;
        fromEndFrame.origin.x += [[UIScreen mainScreen] bounds].size.width;
        
        [transitionContext.containerView addSubview:toViewController.view];
        [transitionContext.containerView addSubview:fromViewController.view];
        
        fromViewController.view.frame = screenFrame;
        toViewController.view.frame = toStartFrame;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            toViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
            fromViewController.view.frame = fromEndFrame;
            toViewController.view.frame = screenFrame;
        } completion:^(BOOL finished) {
            toViewController.view.userInteractionEnabled = YES;
            [fromViewController.view removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
