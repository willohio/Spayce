//
//  UIViewController+SPCAdditions.m
//  Spayce
//
//  Created by William Santiago on 6/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UIViewController+SPCAdditions.h"
#import "NSObject+AssociatedObjects.h"
#import "SPCNotificationBanner.h"

@implementation UIViewController (SPCAdditions)

- (BOOL)isRootViewController {
    return self.navigationController && self == self.navigationController.viewControllers[0];
}

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)spc_dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Accessors

- (NSMutableArray *)spc_queue {
    NSMutableArray *queue = [self associatedValueForKey:@selector(spc_queue)];
    if (!queue) {
        queue = [NSMutableArray array];
        
        [self associateValue:queue withKey:@selector(spc_queue)];
    }
    return queue;
}

#pragma mark - Private

- (void)_spc_queueNotificationBanner {
    if (self.spc_queue.count > 0) {
        // Get the next notification banner in the queue
        SPCNotificationBanner *currentNotificationBanner = self.spc_queue[0];
        
        // Remove current notification banner from the queue
        [self.spc_queue removeObjectAtIndex:0];
        
        [currentNotificationBanner hideWithCompletionHandler:^{
            if (self.spc_queue.count > 0) {
                // Show next notification banner in the queue
                SPCNotificationBanner *nextNotificationBanner = self.spc_queue[0];
                [nextNotificationBanner show];
                
                if (self.spc_queue.count > 1) {
                    [self spc_queueNotificationBanner];
                }
            }
        }];
    }
}

#pragma mark - Actions

- (void)spc_queueNotificationBanner {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self performSelector:@selector(_spc_queueNotificationBanner) withObject:nil afterDelay:5];
}

- (void)spc_showNotificationBannerInParentView:(UIView *)parentView title:(NSString *)title error:(NSError *)error {
    // Add to the queue
    SPCNotificationBanner *notificationBanner = [[SPCNotificationBanner alloc] initWithParentView:parentView title:title error:error target:self];
    [self.spc_queue addObject:notificationBanner];
    
    // Show notification banner immediately
    if (self.spc_queue.count == 1) {
        [notificationBanner show];
    }
    // Add notification banner to the queue and show after a delay
    else {
        [self spc_queueNotificationBanner];
    }
}

- (void)spc_showNotificationBannerInParentView:(UIView *)parentView title:(NSString *)title customText:(NSString *)customText {
    // Add to the queue
    SPCNotificationBanner *notificationBanner = [[SPCNotificationBanner alloc] initWithParentView:parentView title:title customText:customText target:self];
    [self.spc_queue addObject:notificationBanner];
    
    // Show notification banner immediately
    if (self.spc_queue.count == 1) {
        [notificationBanner show];
    }
    // Add notification banner to the queue and show after a delay
    else {
        [self spc_queueNotificationBanner];
    }
}


- (void)spc_showNotificationBannerInReferenceView:(UIView *)referenceView title:(NSString *)title error:(NSError *)error {
    // Add to the queue
    SPCNotificationBanner *notificationBanner = [[SPCNotificationBanner alloc] initWithReferenceView:referenceView title:title error:error target:self];
    [self.spc_queue addObject:notificationBanner];
    
    // Show notification banner immediately
    if (self.spc_queue.count == 1) {
        [notificationBanner show];
    }
    // Add notification banner to the queue and show after a delay
    else {
        [self spc_queueNotificationBanner];
    }
}

- (void)spc_showNotificationBannerInSegmentedControl:(UIView *)segmentedControl title:(NSString *)title error:(NSError *)error {
    // Add to the queue
    SPCNotificationBanner *notificationBanner = [[SPCNotificationBanner alloc] initWithSegmentedControl:segmentedControl title:title error:error target:self];
    [self.spc_queue addObject:notificationBanner];
    
    // Show notification banner immediately
    if (self.spc_queue.count == 1) {
        [notificationBanner show];
    }
    // Add notification banner to the queue and show after a delay
    else {
        [self spc_queueNotificationBanner];
    }
}

- (void)spc_hideNotificationBanner:(SPCNotificationBanner *)notificationBanner {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Remove current notification banner from the queue
    [self.spc_queue removeObjectAtIndex:0];
    
    [notificationBanner hideWithCompletionHandler:^{
        // Show next notification banner in the queue
        if (self.spc_queue.count > 0) {
            SPCNotificationBanner *nextNotificationBanner = self.spc_queue[0];
            [nextNotificationBanner show];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"deactivateContainerInteraction" object:nil];
        }
    }];
}

- (void)spc_hideNotificationBanner {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (self.spc_queue.count > 0) {
        // Get the next notification banner in the queue
        SPCNotificationBanner *notificationBanner = self.spc_queue[0];
        
        // Remove current notification banner from the queue
        [self.spc_queue removeObjectAtIndex:0];
        
        [notificationBanner hide];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"deactivateContainerInteraction" object:nil];
    }
}

@end
