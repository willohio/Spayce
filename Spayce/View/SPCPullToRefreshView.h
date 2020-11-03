//
//  SPCPullToRefreshView.h
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "MNMPullToRefreshView.h"

@interface SPCPullToRefreshView : MNMPullToRefreshView

@property (nonatomic, assign) float flyingRocketAdjustment;

- (void)hideContentUntilStateChange;

@end
