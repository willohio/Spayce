//
//  SPCHereVenueViewController.h
//  Spayce
//
//  Created by Jake Rosin on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//
//  A container VC displays both SPCHereVenueListVC and SPCHereVenueMapVC.
//  Contains all the nav-bar controls for both, sending the appropriate signals
//  and switching between the two.  Also relays user actions from the nav bar
//  and the sub VCs to its own delegate.

#import <UIKit/UIKit.h>

#import "SPCHereVenueListViewController.h"
#import "SPCHereVenueMapViewController.h"
#import "SPCHereEnums.h"
#import "SPCSearchTextField.h"

@protocol SPCHereVenueViewControllerDelegate <NSObject>

@optional
// Used to reveal the venue view controller
- (void)revealVenueViewController:(UIViewController *)controller animated:(BOOL)animated;
// Used to dismiss venue view controller
- (void)dismissVenueViewController:(UIViewController *)controller animated:(BOOL)animated;
// Used to pass back selected venue object
- (void)hereVenueViewController:(UIViewController *)controller didSelectVenue:(Venue *)venue dismiss:(BOOL)dismiss;
// Used to pass back a list of venue objects.  If not implemented, one of the venues will be sent to didSelectVenue.
- (void)hereVenueViewController:(UIViewController *)controller didSelectVenues:(NSArray *)venues dismiss:(BOOL)dismiss;
// Used to pass back a list of venue objects from the full screenmap.
- (void)hereVenueViewController:(UIViewController *)controller didSelectVenuesFromFullScreen:(NSArray *)venues dismiss:(BOOL)dismiss;
// Used when the user presses the "refresh location" button
- (void)hereVenueViewControllerDidRefreshLocation:(UIViewController *)controller;

@end

@interface SPCHereVenueViewController : UIViewController<SPCHereVenueListViewControllerDelegate, SPCHereVenueMapViewControllerDelegate>
@property (nonatomic, strong) SPCHereVenueMapViewController * mapViewController;
@property (nonatomic, weak) NSObject <SPCHereVenueViewControllerDelegate> *delegate;
@property (nonatomic, strong) SPCSearchTextField *searchBar;
@property (nonatomic, strong) UIView *suggestionsView;
@property (nonatomic, assign) CGFloat verticalOffset;

- (void)setVerticalOffset:(CGFloat)verticalOffset withDuration:(CGFloat)duration;

- (void)showMapUserInterfaceAnimated:(BOOL)animated;
- (void)showListUserInterfaceAnimated:(BOOL)animated;
- (void)hideUserInterfaceAnimated:(BOOL)animated;

- (void)showVenue:(Venue *)venue;

- (void)prepareToAnimateMemory;
- (void)animateMemory;

-(void)refreshLocation;
- (void)locationResetManually;

-(void)updateSuggestions;

// Update the currently selected venue, the device location venue (which may or may
// not be the same), and the list of all venues nearby.
-(void)updateVenues:(NSArray *)venues withCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue spayceState:(SpayceState)spayceState;

-(void)searchIsCompleteWithResults:(BOOL)hasResults;

@end
