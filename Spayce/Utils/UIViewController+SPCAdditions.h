//
//  UIViewController+SPCAdditions.h
//  Spayce
//
//  Created by Pavel Dusatko on 6/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCAlert.h"

@interface UIViewController (SPCAdditions)

- (BOOL)isRootViewController;

// TODO: Refactor to UIViewController (SPCAlerts)

@property (nonatomic, strong, readonly) NSMutableArray *spc_queue;

- (void)spc_dealloc;
- (void)spc_showNotificationBannerInParentView:(UIView *)parentView title:(NSString *)title error:(NSError *)error;
- (void)spc_showNotificationBannerInParentView:(UIView *)parentView title:(NSString *)title customText:(NSString *)customText;
- (void)spc_showNotificationBannerInReferenceView:(UIView *)referenceView title:(NSString *)title error:(NSError *)error;
- (void)spc_showNotificationBannerInSegmentedControl:(UIView *)segmentedControl title:(NSString *)title error:(NSError *)error;
- (void)spc_hideNotificationBanner;

@end
