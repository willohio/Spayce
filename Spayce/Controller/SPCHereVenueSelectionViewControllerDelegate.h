//
//  SPCHereVenueSelectionViewControllerDelegate.h
//  Spayce
//
//  Created by Jake Rosin on 6/18/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Venue.h"

@protocol SPCHereVenueSelectionViewControllerDelegate <NSObject>

@optional
- (void)venueSelectionViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue dismiss:(BOOL)dismiss;
- (void)venueSelectionViewController:(UIViewController *)viewController didSelectVenueFromFullScreen:(Venue *)venue dismiss:(BOOL)dismiss;
- (void)dismissVenueSelectionViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end
