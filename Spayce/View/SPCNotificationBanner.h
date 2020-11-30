//
//  SPCNotificationBanner.h
//  Spayce
//
//  Created by William Santiago on 6/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCNotificationBanner : UIView

- (instancetype)initWithParentView:(UIView *)parentView title:(NSString *)title error:(NSError *)error target:(id)target;
- (instancetype)initWithReferenceView:(UIView *)referenceView title:(NSString *)title error:(NSError *)error target:(id)target;
- (instancetype)initWithSegmentedControl:(UIView *)segmentedControl title:(NSString *)title error:(NSError *)error target:(id)target;
- (instancetype)initWithParentView:(UIView *)parentView title:(NSString *)title customText:(NSString *)customText target:(id)target;

- (void)show;
- (void)hide;
- (void)hideWithCompletionHandler:(void (^)())completionHandler;

@end
