//
//  SPCHereVenueMapViewController.h
//  Spayce
//
//  Created by Jake Rosin on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Venue.h"
#import "Memory.h"
#import "SPCHereEnums.h"
// Framework
#import <GoogleMaps/GoogleMaps.h>

@protocol SPCHereVenueMapViewControllerDelegate <NSObject>

@optional
-(void)hereVenueMapViewController:(UIViewController *)viewController revealAnimated:(BOOL)animated;
-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue;
-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenues:(NSArray *)venues;
-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenuesFromFullScreen:(NSArray *)venues;

-(void)searchIsCompleteWithResults:(BOOL)hasResults;
-(void)refreshLocation;
-(void)showVenueDetail:(Venue *)v;
-(void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)m;
-(void)showVenueDetailFeed:(Venue *)v;
@end

@interface SPCHereVenueMapViewController : UIViewController

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) GMSMapView *hiddenMapView;

@property (nonatomic, weak) NSObject <SPCHereVenueMapViewControllerDelegate> *delegate;
@property (nonatomic, readonly) BOOL isAtDeviceLocation;
@property (nonatomic, assign) BOOL isExploreOn;
@property (nonatomic, assign) BOOL isExplorePaused;
@property (nonatomic, assign) UIEdgeInsets visibleRectInsets;
@property (nonatomic, strong) NSString * searchFilter;
@property (nonatomic, assign) BOOL jumpToVenueDetails;
@property (nonatomic, strong) UIButton *refreshLocationButton;
@property (nonatomic, assign) BOOL isViewingMemFromExplore;
@property (nonatomic, assign) BOOL isViewingFromHashtags;
@property (nonatomic, assign) int adaptiveZoomCutOffIndex;
@property (nonatomic, assign) int currPinIndex;

@property (nonatomic, assign) BOOL animatingMemory;

-(void)locationResetManually;

- (void)showVenue:(Venue *)venue;
- (void)showVenue:(Venue *)venue withZoom:(float)zoom;
- (void)showVenue:(Venue *)venue withZoom:(float)zoom animated:(BOOL)animated;
- (void)jumpToLatitude:(double)gpsLat longitude:(double)gpsLong;
- (void)showLatitude:(CGFloat)latitude longitude:(CGFloat)longitude zoom:(CGFloat)zoom animated:(BOOL)animated;

// Update the currently selected venue, the device location venue (which may or may
// not be the same), and whether the device venue should be given highlighted
// "you are here" treatment.  e.g. in current specs and discussion, centering the map
// view to point at your current location will cause a highlighted state for the button.
-(void)updateVenues:(NSArray *)venues withCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue spayceState:(SpayceState)spayceState;

-(void)showUserInterfaceAnimated:(BOOL)animated;
-(void)hideUserInterfaceAnimated:(BOOL)animated;
- (void) displayNextExploreMemoryIgnoringRateLimit:(BOOL)ignoreRateLimit;
- (void) displayAnyExploreMemoryFromSuggestedVenue:(Venue *)suggestedVenue;
- (void) resetMapAfterTeleport;
- (BOOL) isMapResetNeeded;
-(void)adjustResetBtn;

-(void)fadeDownAllForFilters;
-(void)fadeUpAllFromFilters;
-(void)fadeUpCafes;
-(void)fadeUpRestaurants;
-(void)fadeUpSports;
-(void)fadeUpOffices;
-(void)fadeUpHomes;
-(void)fadeUpTravel;
-(void)fadeUpBars;
-(void)fadeUpSchools;
-(void)fadeUpFun;
-(void)fadeUpStore;
-(void)fadeUpFavorites;
-(void)fadeUpPopular;

@end
