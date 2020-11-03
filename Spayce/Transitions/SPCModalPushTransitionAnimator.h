//
//  SPCModalPushTransitionAnimator.h
//  Spayce
//
//  Created by Jake Rosin on 10/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCModalPushTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, getter=isPresenting) BOOL presenting;

@end
