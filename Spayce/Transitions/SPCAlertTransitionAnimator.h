//
//  SPCAlertTransitionAnimator.h
//  Spayce
//
//  Created by Pavel Dusatko on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCAlertTransitionAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, getter=isPresenting) BOOL presenting;

@end
