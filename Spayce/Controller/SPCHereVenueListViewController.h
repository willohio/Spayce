//
//  SPCHereVenueListViewController.h
//  Spayce
//
//  Created by Jake Rosin on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"
#import "SPCHereEnums.h"

@protocol SPCHereVenueListViewControllerDelegate <NSObject>

@optional
-(void)hereVenueListViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue;
-(void)hereVenueListViewControllerDismissKeyboard:(UIViewController *)viewController;

@end

@interface SPCHereVenueListViewController : UIViewController

@property (nonatomic, weak) NSObject <SPCHereVenueListViewControllerDelegate> *delegate;

@property (nonatomic, assign) BOOL isAtDeviceVenue;
@property (nonatomic, strong) NSString * searchFilter;

- (void)locationResetManually;

// Update the currently selected venue, the device location venue (which may or may
// not be the same), and whether the device venue should be given highlighted
// "you are here" treatment.  e.g. in current specs and discussion, centering the map
// view to point at your current location will cause a highlighted state for the button.
-(void)updateVenues:(NSArray *)venues withCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue atDeviceVenue:(BOOL)atDeviceVenue spayceState:(SpayceState)spayceState;

@end
