//
//  SPCExploreViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCNearbyVenuesView.h"
#import "Venue.h"
#import "Memory.h"
#import "SPCGrid.h"
#import "SPCHereVenueMapViewController.h"


typedef NS_ENUM(NSInteger, ExploreState) {
    ExploreStateLocal,
    ExploreStateWorld
};

@interface SPCExploreViewController : UIViewController <SPCNearbyVenuesViewDelegate, SPCGridDelegate, SPCHereVenueMapViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, assign) BOOL pullToRefreshInProgress;

- (void)showVenueDetail:(Venue *)v;
- (void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)memory;
- (void)hideNearbyVenues;
- (void)restoreGridHeadersAndFooters;
@end
