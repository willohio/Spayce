//
//  SPCHereViewController.h
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCBaseDataSource.h"
#import "SPCHiSpeedViewController.h"
#import "SPCHereVenueViewController.h"
@class SPCHereDataSource;


@interface SPCHereViewController : UIViewController
- (SPCHereDataSource *)dataSource;
@property (nonatomic, assign, getter = isFeedDisplayed) BOOL feedDisplayed;
@property (nonatomic, assign, getter = isFeedTransitionAnimationInProgress) BOOL feedTransitionAnimationInProgress;
@property (nonatomic, assign) BOOL mamCaptureActive;
@property (nonatomic, strong) SPCHereVenueViewController *venueViewController;
@property (nonatomic, strong) UIButton *nearbyVenuesBtn;

@end
