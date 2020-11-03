//
//  SPCCreateVenueViewController.h
//  Spayce
//
//  Created by Jake Rosin on 6/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"


@interface SPCCreateVenueViewController : UIViewController

@property (nonatomic, assign) BOOL fromExplore;

-(id) initWithNearbyVenues:(NSArray *)venues;

@end
