//
//  SPCHereViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereViewController.h"

// Model
#import "SPCHereDataSource.h"

// View
#import "IntroAnimation.h"
#import "SPCNavControllerLight.h"
#import "UIImageView+WebCache.h"
#import "HMSegmentedControl.h"

// Controller
#import "SPCCreateVenuePostViewController.h"
#import "SPCHandlePromptViewController.h"
#import "SPCHereVenueViewController.h"
#import "SPCHereVenueSelectionViewController.h"
#import "SPCTrendingViewController.h"

// Manager
#import "AuthenticationManager.h"
#import "LocationManager.h"
#import "LocationContentManager.h"
#import "MeetManager.h"
#import "ContactAndProfileManager.h"
#import "APIUtils.h"
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "Asset.h"

#define NEARBY_VENUES_STALE_AFTER 1200

#define MINIMUM_LOCATION_MANAGER_UPTIME 6

#define VERBOSE_STATE_CHANGES NO
#define VERBOSE_CONTENT_UPDATES NO

@interface SPCHereViewController () <SPCHereVenueViewControllerDelegate, SPCHereVenueSelectionViewControllerDelegate> {
    BOOL registeredForNotifications;
    
    BOOL ongoingUpdateIsStale;
    BOOL viewDidAppear;
    int approximateDepthOnViewControllerStack;    // if 1, currently visible.  If > 1, things are piled on top.
}

@property (nonatomic, strong) SPCHereVenueSelectionViewController *venueSelectionViewController;
@property (nonatomic, strong) SPCTrendingViewController *trendingViewController;

@property (nonatomic, strong) SPCHereDataSource *dataSource;
@property (nonatomic, assign) BOOL spc_viewDidAppear;
@property (nonatomic, assign, getter = isVenueSelectionTransitionAnimationInProgress) BOOL venueSelectionTransitionAnimationInProgress;
@property (nonatomic, assign, getter = isVenueSelectionDisplayed) BOOL venueSelectionDisplayed;

@property (nonatomic, assign) BOOL autoRefreshLocationIsOn;
@property (nonatomic, assign) BOOL performingRefresh;
@property (nonatomic, assign) BOOL hiSpeedModeActive;

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) Venue *deviceVenue;
@property (nonatomic, strong) NSArray *nearbyVenues;
@property (nonatomic, strong) NSArray *featuredContent;
@property (nonatomic, assign) BOOL memAnimationInProgress;
@property (nonatomic, assign) SpayceState spayceState;
@property (nonatomic, strong) Memory *localMem;
@property (nonatomic, assign) BOOL displayLightStatusBar;

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIView *statusBar;
@property (nonatomic, strong) UIButton *flyBtn;
@property (nonatomic, strong) UIView *segControlContainer;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;

@property (nonatomic, strong) UIView *gridContainer;

// status bar location
@property (nonatomic, assign) CGFloat statusBarBackgroundProportion;

// Waiting for uptime?
@property (nonatomic, assign) BOOL waitingForLocationManagerUptime;

// Time we went down (screen turned off).
@property (nonatomic, assign) NSTimeInterval screenOffTime;

@end

@implementation SPCHereViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_venueViewController];
    [self unregisterFromNotifications];
}

#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
    [self registerForNotifications];
    //NSLog(@"Spayce View Controller loaded");
    
    // Background color
    self.view.backgroundColor = [UIColor whiteColor];
    
    // Map view
    [self addChildViewController:self.venueViewController];
    [self.venueViewController didMoveToParentViewController:self];
    [self.view addSubview:self.venueViewController.view];
    
    
    // 'Nav' btns
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.segControlContainer];
    
    //grid
    [self.view addSubview:self.gridContainer];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    approximateDepthOnViewControllerStack = 1;
    viewDidAppear = YES;
    
        
    BOOL shouldChangeHandle = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldChangeHandle"];
    if (shouldChangeHandle) {
        [self forceHandleSelection];
    }
    else if (!self.spc_viewDidAppear){
        self.spc_viewDidAppear = YES;
    }
    
    BOOL locEnabled = [CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
    
    if (!locEnabled) {
        //NSLog(@"viewWillAppear: location is off");
        [_venueViewController locationResetManually];
        self.spayceState = SpayceStateLocationOff;
        [self updateForCurrentLocationFixWithRefreshOngoing:NO];
    } else if (self.spayceState == SpayceStateLocationOff) {
        //NSLog(@"Location is off: seeking fix, refreshing content");
        // user activated location then returned to the app
        self.spayceState = SpayceStateSeekingLocationFix;
        [self updateForCurrentLocationFixWithRefreshOngoing:YES];
        [self refreshContent:YES];
    }
    
    [self.view bringSubviewToFront:self.navBar];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    approximateDepthOnViewControllerStack--;
    viewDidAppear = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL locEnabled = [CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
    if (locEnabled) {
        self.spayceState = SpayceStateSeekingLocationFix;
    } else {
        self.spayceState = SpayceStateLocationOff;
    }
    
    [self refreshContent:NO];
}

#pragma mark - UIViewController - Configuring the View’s Layout Behavior

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}


#pragma mark - SPCHereVenueSelectionControllerDelegate

- (void)venueSelectionViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self hideVenueSelectionAnimated:YES];
    }
    
    //tell the scroller
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedOnVenue" object:venue];
    
    //tell the map
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:venue];
    
}

- (void)venueSelectionViewController:(UIViewController *)viewController didSelectVenueFromFullScreen:(Venue *)venue dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self hideVenueSelectionAnimated:YES];
    }
    //tell the scroller
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedOnVenue" object:venue];
    
    //tell the map
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:venue];
    
    //tell the map to jump to venue details
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToVenueFromMultiPin" object:venue];
    
}

- (void)dismissVenueSelectionViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController == self.venueSelectionViewController) {
        [self hideVenueSelectionAnimated:animated];
    }
}

#pragma mark - SPCHereVenueViewControllerDelegate

// Used to reveal the venue view controller
- (void)revealVenueViewController:(UIViewController *)controller animated:(BOOL)animated {
    if (!viewDidAppear) {
        return;
    }
    if (controller == self.venueViewController) {
        
    }
}

// Used to dismiss venue view controller
- (void)dismissVenueViewController:(UIViewController *)controller animated:(BOOL)animated {
    if (controller == self.venueViewController) {
        self.navBar.hidden = NO;
        self.segControlContainer.hidden = NO;
        
        // show/hide grid appropriately
        if (self.hmSegmentedControl.selectedSegmentIndex == 0) {
            //show grid view
            self.gridContainer.hidden = NO;
        }
        if (self.hmSegmentedControl.selectedSegmentIndex == 1) {
            //hide grid view
            self.gridContainer.hidden = YES;
        }
    }
}
- (void)hereVenueViewControllerDidRefreshLocation:(UIViewController *)controller {
    [self userRefreshedLocation];
}

// Used to pass back selected venue object
- (void)hereVenueViewController:(UIViewController *)controller didSelectVenue:(Venue *)venue dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self dismissVenueViewController:controller animated:YES];
    }
    [self userSelectedVenue:venue];
}

// Used to pass back a list of venue objects.  If not implemented, one of the venues will be sent to didSelectVenue.
- (void)hereVenueViewController:(UIViewController *)controller didSelectVenues:(NSArray *)venues dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self dismissVenueViewController:controller animated:YES];
    }
    
    self.venueSelectionViewController.venues = venues;
    [self showVenueSelectionAnimated:YES fullScreen:NO];
}
- (void)hereVenueViewController:(UIViewController *)controller didSelectVenuesFromFullScreen:(NSArray *)venues dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self dismissVenueViewController:controller animated:YES];
    }
    
    self.venueSelectionViewController.venues = venues;
    [self showVenueSelectionAnimated:YES fullScreen:YES];
}


- (void)userRefreshedLocation {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if ([[LocationManager sharedInstance] locServicesAvailable]){
            
            self.displayLightStatusBar = YES;
            [self setNeedsStatusBarAppearanceUpdate];
            
            if (self.spayceState == SpayceStateDisplayingLocationData || self.spayceState == SpayceStateRetrievingLocationData) {
                [_venueViewController locationResetManually];
                self.spayceState = SpayceStateSeekingLocationFix;
                if ([LocationManager sharedInstance].uptime > MINIMUM_LOCATION_MANAGER_UPTIME) {
                    [self updateForCurrentLocationFixWithRefreshOngoing:NO];
                    [[LocationContentManager sharedInstance] clearContentAndLocation];
                    [self refreshContent:YES];
                } else if (!self.waitingForLocationManagerUptime) {
                    self.waitingForLocationManagerUptime = YES;
                    [[LocationManager sharedInstance] waitForUptime:MINIMUM_LOCATION_MANAGER_UPTIME withSuccessCallback:^(NSTimeInterval uptime) {
                        self.waitingForLocationManagerUptime = NO;
                        [self updateForCurrentLocationFixWithRefreshOngoing:NO];
                        [[LocationContentManager sharedInstance] clearContentAndLocation];
                        [self refreshContent:YES];
                    } faultCallback:^(NSError *error) {
                        self.waitingForLocationManagerUptime = NO;
                        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse) {
                            [_venueViewController locationResetManually];
                            self.spayceState = SpayceStateLocationOff;
                        } else {
                            // nope.
                            [_venueViewController locationResetManually];
                            self.spayceState = SpayceStateLocationOff;
                        }
                    }];
                }
            }
        }
        else {
            // nope.
            [_venueViewController locationResetManually];
            self.spayceState = SpayceStateLocationOff;
        }
    }
    else {
        // nope.
        [_venueViewController locationResetManually];
        self.spayceState = SpayceStateLocationOff;
    }
}

- (void)userSelectedVenue:(Venue *)venue {
    // Inform the LocationManager of this update.  It will send a notification which we capture
    // to update our own content.
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (venue) {
            // Use the venue object if it has the required fields.
            if (venue.displayName && venue.addressId && venue.latitude && venue.longitude) {
                [LocationManager sharedInstance].manualVenue = venue;
            } else {
                [LocationManager sharedInstance].manualLocation = [[CLLocation alloc] initWithLatitude:[venue.latitude floatValue] longitude:[venue.longitude floatValue]];
            }
        } else {
            [LocationManager sharedInstance].manualLocation = nil;
        }
    }
}


#pragma mark - Accessors

- (BOOL)autoRefreshLocationIsOn {
    return NO;
}

- (SPCHereVenueSelectionViewController *)venueSelectionViewController {
    if (!_venueSelectionViewController) {
        _venueSelectionViewController = [[SPCHereVenueSelectionViewController alloc] init];
        _venueSelectionViewController.delegate = self;
        [_venueSelectionViewController sizeToFitPerPage:3];
    }
    return _venueSelectionViewController;
}

- (SPCHereVenueViewController *)venueViewController {
    if (!_venueViewController) {
        _venueViewController = [[SPCHereVenueViewController alloc] init];
        _venueViewController.delegate = self;
    }
    return _venueViewController;
}

- (SPCTrendingViewController *)trendingViewController {
    if (!_trendingViewController) {
        _trendingViewController = [[SPCTrendingViewController alloc] init];
    }
    return _trendingViewController;
}

- (UIView *)navBar {
    
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 64)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        titleLabel.frame = CGRectMake(CGRectGetMidX(_navBar.frame) - 75.0, CGRectGetMidY(_navBar.frame), 150.0, titleLabel.font.lineHeight);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        titleLabel.text = NSLocalizedString(@"SPAYCE", nil);
        
        [_navBar addSubview:self.nearbyVenuesBtn];
        [_navBar addSubview:self.flyBtn];
        
        [_navBar addSubview:titleLabel];
    }
    return _navBar;
    
}

- (UIButton *)flyBtn {
    if (!_flyBtn) {
        CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        _flyBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-55, statusBarHeight, 45, 45)];
        _flyBtn.backgroundColor = [UIColor clearColor];
        [_flyBtn setImage:[UIImage imageNamed:@"fly-btn"] forState:UIControlStateNormal];
        [_flyBtn setImage:[UIImage imageNamed:@"fly-btn"] forState:UIControlStateHighlighted];
        [_flyBtn addTarget:self action:@selector(mapButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_flyBtn];
    }
    return _flyBtn;
}

- (UIButton *)nearbyVenuesBtn {
    if (!_nearbyVenuesBtn) {
        CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        _nearbyVenuesBtn = [[UIButton alloc] initWithFrame:CGRectMake(10.0, statusBarHeight, 45, 45)];
        _nearbyVenuesBtn.backgroundColor = [UIColor clearColor];
        [_nearbyVenuesBtn setImage:[UIImage imageNamed:@"nearby-venues-btn"] forState:UIControlStateNormal];
        [_nearbyVenuesBtn setImage:[UIImage imageNamed:@"nearby-venues-btn"] forState:UIControlStateHighlighted];
        [_nearbyVenuesBtn addTarget:self action:@selector(listButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _nearbyVenuesBtn.alpha = 1;
        _nearbyVenuesBtn.userInteractionEnabled = YES;
        [_statusBar addSubview:_nearbyVenuesBtn];
        [self.view addSubview:_nearbyVenuesBtn];
    }
    return _nearbyVenuesBtn;
}


- (UIView *)segControlContainer {
    if (!_segControlContainer) {
        _segControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.view.bounds.size.width, 37)];
        _segControlContainer.backgroundColor = [UIColor whiteColor];
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 1)];
        sepView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepView];
        
        [_segControlContainer addSubview:self.hmSegmentedControl];
        
    }
    
    return _segControlContainer;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"GRID", @"MAP"]];
        _hmSegmentedControl.frame = CGRectMake(0, 1, _segControlContainer.frame.size.width, 36);
        [_hmSegmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor whiteColor];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleBox;
        _hmSegmentedControl.selectionIndicatorHeight = 0;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationNone;
        _hmSegmentedControl.shouldAnimateUserSelection = NO;
        _hmSegmentedControl .selectedSegmentIndex = 0;
        
    }
    return _hmSegmentedControl;
}

- (UIView *)gridContainer {
    if (!_gridContainer) {
        _gridContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.segControlContainer.frame) - 44)];
        _gridContainer.backgroundColor = [UIColor lightGrayColor];
        
        [_gridContainer addSubview:self.trendingViewController.collectionView];
        [self.trendingViewController viewWillAppear:NO];
        [self.trendingViewController viewDidAppear:NO];
    }
    return _gridContainer;
}


-(void)setSpayceState:(SpayceState)spayceState {
    if (VERBOSE_STATE_CHANGES) {
        NSLog(@"spayceState %li",spayceState);
    }
    
    if (spayceState == SpayceStateLocationOff) {
        _spayceState = spayceState;
        self.nearbyVenuesBtn.hidden = YES;
        self.flyBtn.hidden = YES;
    }
    else {
        self.nearbyVenuesBtn.hidden = NO;
        self.flyBtn.hidden = NO;
    }
    
    if (spayceState != _spayceState) {
        _spayceState = spayceState;
    }
}


#pragma mark - Private

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    if (segmentedControl.selectedSegmentIndex == 0) {
        //show grid view
        [self.trendingViewController viewWillAppear:NO];
        [self.trendingViewController viewDidAppear:NO];
        self.gridContainer.hidden = NO;
    }
    if (segmentedControl.selectedSegmentIndex == 1) {
        //hide grid view
        self.gridContainer.hidden = YES;
    }
}



- (void)listButtonPressed:(id)sender {
 
    // Show user interface
    [self.venueViewController showListUserInterfaceAnimated:YES];
    
    self.navBar.hidden = YES;
    self.segControlContainer.hidden = YES;
    self.gridContainer.hidden = YES;
}

- (void)mapButtonPressed:(id)sender {
    
    self.navBar.hidden = YES;
    self.segControlContainer.hidden = YES;
    self.gridContainer.hidden = YES;
    
    [self.venueViewController showMapUserInterfaceAnimated:YES];
    _venueViewController.suggestionsView.hidden = NO;
    [_venueViewController updateSuggestions];
     [_venueViewController.searchBar becomeFirstResponder];
    
}

- (void)spc_viewDidAppearWithNotification:(NSNotification *)note {
    if (!self.spc_viewDidAppear) {
        self.spc_viewDidAppear = YES;
        
    }
}


- (void)spc_localMemoryPostingToVenue:(NSNotification *)note {
    Venue *venue = (Venue *)[note object];
    if (venue.addressId != self.venue.addressId) {
        //NSLog(@"update venue after change in MAM");
        //user changed locations w/in add memory.  Update the
        // manual location; this prompts a Notification, which we trigger
        // on to refresh the memory feed.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"tappedOnVenue" object:venue];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:venue];
    }
}


- (void)spc_localMemoryPosted:(NSNotification *)note {
    NSLog(@"spc_localMemoryPosted!");
    Memory *memory = (Memory *)[note object];
    Venue *venue = memory.venue;
    self.localMem = memory;
    if (memory.addressID != self.venue.addressId) {
        //NSLog(@"update venue after change in MAM");
        //user changed locations w/in add memory.  Update the
        // manual location; this prompts a Notification, which we trigger
        // on to refresh the memory feed.
        if (!venue) {
            venue = [LocationManager sharedInstance].tempMemVenue;
        }
        [[LocationManager sharedInstance] updateManualLocationWithVenue:venue];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"tappedOnVenue" object:venue];
        //[[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:venue];
        [self.venueViewController showVenue:venue];
    }
    
    //make sure the SPAYCE tab is displayed
    self.displayLightStatusBar = YES    ;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jumpToHere" object:nil];
}

- (void)refreshContentSelector:(NSNumber *)force {
    BOOL forceBool = [force boolValue];
    [self refreshContent:forceBool];
}

- (void)refreshContent:(BOOL)force {
    
    if (VERBOSE_STATE_CHANGES) {
        NSLog(@"refreshContent from \n%@\n%@", [NSThread callStackSymbols][1], [NSThread callStackSymbols][2]);
    }
    
    // Fetch memories only if location services are enabled and manually authorized by the user
    // There's no point in polling for location sensitive data if it's not enabled or authorized
    if (![CLLocationManager locationServicesEnabled] ||
        ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)) {
        [self setSpayceState:SpayceStateLocationOff];
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"Can't access location services");
        }
        return;
    }
    
    if (self.performingRefresh) {
        ongoingUpdateIsStale = ongoingUpdateIsStale || force;
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"Currently performing refresh");
        }
        return;
    }
    
    if (self.waitingForLocationManagerUptime) {
        ongoingUpdateIsStale = ongoingUpdateIsStale || force;
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"Currently waiting for location manager uptime....");
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    if ([LocationManager sharedInstance].uptime < MINIMUM_LOCATION_MANAGER_UPTIME) {
        if (VERBOSE_STATE_CHANGES || VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Waiting for uptime %d", MINIMUM_LOCATION_MANAGER_UPTIME);
        }
        self.waitingForLocationManagerUptime = YES;
        [[LocationManager sharedInstance] waitForUptime:MINIMUM_LOCATION_MANAGER_UPTIME withSuccessCallback:^(NSTimeInterval uptime) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.waitingForLocationManagerUptime = NO;
            strongSelf.spayceState = SpayceStateRetrievingLocationData;
            // our previous location data was poor: clear it now
            [[LocationContentManager sharedInstance] clearContentAndLocation];
            [strongSelf performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:0.1f];
        } faultCallback:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.waitingForLocationManagerUptime = NO;
            if ([LocationManager sharedInstance].locServicesAvailable) {
                // device is turning off.
                // strongSelf.spayceState = SpayceStateSeekingLocationFix;
            } else {
                // location services are disabled.
                strongSelf.spayceState = SpayceStateLocationOff;
            }
        }];
        return;
    }
    
    self.performingRefresh = YES;
    ongoingUpdateIsStale = NO;
    
    if (VERBOSE_STATE_CHANGES || VERBOSE_CONTENT_UPDATES) {
        NSLog(@"Getting content");
    }
    [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue, SPCLocationContentNearbyVenues] progressCallback:^(NSDictionary *partialResults, BOOL *cancel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Progress Callback");
        }
        if (ongoingUpdateIsStale) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"Ongoing update is stale, terminating...");
            }
            *cancel = YES;
            strongSelf.performingRefresh = NO;
            ongoingUpdateIsStale = NO;
            [strongSelf performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:0.1f];
            return;
        }
        
        if (self.waitingForLocationManagerUptime) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"Currently waiting for location manager uptime, terminating...");
            }
            *cancel = YES;
            strongSelf.performingRefresh = NO;
            return;
        }
        
        // Perform a partial update.
        // i.e.: tell the Spayce Feed Here controller to display a loading screen
        // tell the Spayce Map Here controller to reposition at the selected venue
        SpayceState state = SpayceStateRetrievingLocationData;
        if (partialResults[SPCLocationContentVenue]) {
            self.spayceState = state;
            NSArray *nearby = partialResults[SPCLocationContentNearbyVenues] ?: strongSelf.nearbyVenues;
    
            if (partialResults[SPCLocationContentDeviceVenue]) {
                [strongSelf.venueViewController updateVenues:nearby withCurrentVenue:partialResults[SPCLocationContentVenue] deviceVenue:partialResults[SPCLocationContentDeviceVenue] spayceState:state];
            } else {
                [strongSelf.venueViewController updateVenues:nearby withCurrentVenue:partialResults[SPCLocationContentVenue] deviceVenue:strongSelf.deviceVenue spayceState:state];
            }
        }
    } resultCallback:^(NSDictionary *results) {
        if (VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Result Callback");
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (ongoingUpdateIsStale) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"Ongoing update is stale, terminating...");
            }
            strongSelf.performingRefresh = NO;
            ongoingUpdateIsStale = NO;
            [strongSelf performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:0.1f];
            return;
        }
        
        if (self.waitingForLocationManagerUptime) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"Currently waiting for location manager uptime...");
            }
            strongSelf.performingRefresh = NO;
            return;
        }
        
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"location content result");
        }
        
        // update our content
        strongSelf.venue = results[SPCLocationContentVenue];
        strongSelf.deviceVenue = results[SPCLocationContentDeviceVenue];
        strongSelf.nearbyVenues = results[SPCLocationContentNearbyVenues];
        strongSelf.featuredContent = nil;
        
        // lock-in at this venue until the user changes.
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            if (![LocationManager sharedInstance].manualVenue) {
                [LocationManager sharedInstance].manualVenue = strongSelf.venue;
            }
        }
        
        [strongSelf updateForCurrentLocationFixWithRefreshOngoing:YES];
        [strongSelf performSelector:@selector(updateForCurrentLocationAfterSuccessfulRefresh) withObject:nil afterDelay:1.0];
        
    } faultCallback:^(NSError *fault) {
        if (VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Fault Callback: %@", fault);
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //NSLog(@"fault...%@",fault);
        
        if (ongoingUpdateIsStale) {
            strongSelf.performingRefresh = NO;
            ongoingUpdateIsStale = NO;
            [strongSelf performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:0.1f];
            return;
        }
        
        // If the problem is lacking location data, revert to an empy state.
        // Otherwise, revert to our most recent success.
        if ([CLLocationManager locationServicesEnabled]) {
            // something else went wrong.  Reschedule.
            [strongSelf performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:4.0];
        } else {
            strongSelf.venue = nil;
            strongSelf.deviceVenue = nil;
            strongSelf.nearbyVenues = nil;
            strongSelf.spayceState = SpayceStateLocationOff;
        }
        
        [self updateForCurrentLocationFixWithRefreshOngoing:NO];
        
        // allow another refresh
        self.performingRefresh = NO;
    }];
}

- (void)updateForCurrentLocationAfterSuccessfulRefresh {
    //NSLog(@"updateForCurrentLocationAfterSuccessfulRefresh");
    // update our state
    self.spayceState = SpayceStateDisplayingLocationData;
    
    [self performSelector:@selector(updateForCurrentLocationAfterRefresh) withObject:nil afterDelay:0.1f];
}

- (void)updateForCurrentLocationAfterRefresh {
    //NSLog(@"updateForCurrentLocationAfterRefresh");
    [self updateForCurrentLocationFixWithRefreshOngoing:NO];
    
    self.performingRefresh = NO;
}

- (void)spc_localVenuePosted:(NSNotification *)note {
    // delay to give the content time to arrive in the LocationContentManager.
    [self performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:0.5f];
}

- (void)spc_localVenueUpdated:(NSNotification *)note {
    [self refreshContent:NO];
}

- (void)spc_localVenueDeleted:(NSNotification *)note {
    // delay to give the content time to arrive in the LocationContentManager.
    [self performSelector:@selector(refreshContentSelector:) withObject:@NO afterDelay:0.5f];
}


- (void)showVenueSelectionAnimated:(BOOL)animated fullScreen:(BOOL)fullScreen {
    if (self.isVenueSelectionTransitionAnimationInProgress || self.isVenueSelectionDisplayed) {
        return;
    }
    
    // Flag animation being in progress
    self.venueSelectionTransitionAnimationInProgress = YES;
    
    // Add to view controller hierarchy as well as view hierarchy
    if (!self.venueSelectionViewController.view.superview) {
        [self addChildViewController:self.venueSelectionViewController];
        [self.venueSelectionViewController didMoveToParentViewController:self];
        [self.view addSubview:self.venueSelectionViewController.view];
    }
    
    CGRect originalFrame = self.venueSelectionViewController.view.frame;
    originalFrame.origin.y = -CGRectGetHeight(self.view.frame);
    self.venueSelectionViewController.view.frame = originalFrame;
    self.venueSelectionViewController.selectingFromFullScreenMap = fullScreen;
    
    [UIView animateWithDuration:(animated ? 0.3 : 0.0)
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         // Offset vertical position
                         CGRect destinationFrame = self.venueSelectionViewController.view.frame;
                         destinationFrame.origin.y = 0.0;
                         self.venueSelectionViewController.view.frame = destinationFrame;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             // Enable user interaction
                             self.venueSelectionViewController.view.userInteractionEnabled = YES;
                             
                             // Flag animation not in progress
                             self.venueSelectionTransitionAnimationInProgress = NO;
                             
                             // Displayed
                             self.venueSelectionDisplayed = YES;
                             
                             [self setNeedsStatusBarAppearanceUpdate];
                         }
                     }];
}

- (void)hideVenueSelectionAnimated:(BOOL)animated {
    if (self.isVenueSelectionTransitionAnimationInProgress || !self.isVenueSelectionDisplayed) {
        return;
    }
    
    // Flag animation being in progress
    self.venueSelectionTransitionAnimationInProgress = YES;
    
    // Disable user interactions
    self.venueSelectionViewController.view.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:(animated ? 0.3 : 0.0)
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         // Offset vertical position
                         CGRect destinationFrame = self.venueSelectionViewController.view.frame;
                         destinationFrame.origin.y = -CGRectGetHeight(self.view.frame);
                         self.venueSelectionViewController.view.frame = destinationFrame;
                     } completion:^(BOOL finished) {
                         if (finished) {
                             // Remove from view controller hierarchy as well as view hierarchy
                             [self.venueSelectionViewController removeFromParentViewController];
                             [self.venueSelectionViewController.view removeFromSuperview];
                             
                             // Flag animation not in progress
                             self.venueSelectionTransitionAnimationInProgress = NO;
                             
                             // Displayed
                             self.venueSelectionDisplayed = NO;
                         }
                     }];
}


- (void)registerForNotifications {
    if (!registeredForNotifications) {
        registeredForNotifications = YES;
        // Updates to display or refresh content
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_viewDidAppearWithNotification:) name:kIntroAnimationDidEndNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_manualLocationChanged:) name:SPCLocationManagerDidUpdateManualLocation object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_locationContentNearbyVenuesServerUpdate:) name:SPCLocationContentNearbyVenuesUpdatedFromServer object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryPostingToVenue:) name:@"postingMemoryToVenue" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryPosted:) name:@"addMemoryLocally" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localVenuePosted:) name:kSPCDidPostVenue object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localVenueUpdated:) name:kSPCDidUpdateVenue object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localVenueDeleted:) name:kSPCDidDeleteVenue object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMakeMemAnimation:) name:@"handleMakeMemAnimation" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishMemAnimation:) name:@"finishMemAnimation" object:nil];
        
        // Activity updates (user entered / left the app, etc.)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidChangeStatusBarFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeInactive:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeInactive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeInactive:) name:UIApplicationWillTerminateNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataSourceDidPushViewController:) name:SPCHerePushingViewController object:nil];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogout:) name:kAuthenticationDidLogoutNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationServicesAuthorizationStatusWillChange:) name:kLocationServicesAuthorizationStatusWillChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationServicesAuthorizationStatusDidChange:) name:kLocationServicesAuthorizationStatusDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationManagerFailed:) name:kLocationManagerDidFailNotification object:nil];
        
        //Handle Prompt
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayFeedAfterHandleSelection) name:@"displayFeedAfterHandleSelection" object:nil];
    }
}

- (void)unregisterFromNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    registeredForNotifications = NO;
}

- (void)handleMakeMemAnimation:(NSNotification *)notification {
    NSLog(@"handle make mem animation???");
    //moved code here to the beginining of finishMemAnimation because the calls were happening out of sequence!
}

- (void)finishMemAnimation:(NSNotification *)notification {
    NSLog(@"finish mem animation??");

    self.displayLightStatusBar = YES;
    self.memAnimationInProgress = YES;
    [self.venueViewController prepareToAnimateMemory];

    if (self.isFeedDisplayed) {

    }
    else {
        //complete mem animation if necessary
        self.memAnimationInProgress = NO;
        [self.venueViewController performSelector:@selector(animateMemory) withObject:nil afterDelay:0.1];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"mamEndedFromFullScreenStart" object:nil];
    }
}


- (void)forceHandleSelection {

    SPCHandlePromptViewController *handleVC = [[SPCHandlePromptViewController alloc] init];
    SPCNavControllerLight *navigationController = [[SPCNavControllerLight alloc] initWithRootViewController:handleVC];
    [self presentViewController:navigationController animated:YES completion:NULL];
    self.spc_viewDidAppear = NO;
}

- (void)displayFeedAfterHandleSelection {

}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
  
}


#pragma mark - Automatic refresh

-(void)applicationDidBecomeActive:(id)sender {
    BOOL locEnabled = [CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
    
    if (!locEnabled) {
        NSLog(@"applicationDidBecomeActive: location is off");
        self.displayLightStatusBar = YES;
        [self setNeedsStatusBarAppearanceUpdate];
        self.flyBtn.hidden = YES;
        self.nearbyVenuesBtn.hidden = YES;
    
        [_venueViewController locationResetManually];
        self.spayceState = SpayceStateLocationOff;
        [self updateForCurrentLocationFixWithRefreshOngoing:NO];
    } else if (self.spayceState == SpayceStateLocationOff) {
        NSLog(@"ApplicationDidBecomeActive: location was off: seeking fix, refreshing content");
        
        // user activated location then returned to the app
        self.spayceState = SpayceStateSeekingLocationFix;
        [self updateForCurrentLocationFixWithRefreshOngoing:YES];
        [self refreshContent:YES];
    } else if (self.screenOffTime > 0 && [[NSDate date] timeIntervalSince1970] - self.screenOffTime > NEARBY_VENUES_STALE_AFTER) {
        // force a complete content refresh
        NSLog(@"ApplicationDidBecomeActive: forcing a refresh; screen has been off for a while.");
        [[LocationContentManager sharedInstance] clearContentAndLocation];
        self.spayceState = SpayceStateSeekingLocationFix;
        [self refreshContent:YES];
    } else if (self.spayceState != SpayceStateDisplayingLocationData) {
        NSLog(@"ApplicationDidBecomeActive: was previously updating data.  Trying again");
        [self refreshContent:NO];
    } else {
        NSLog(@"ApplicationDidBecomeActive: no action");
    }
    
    // screen turned on!
    self.screenOffTime = 0;
}

-(void)applicationWillBecomeInactive:(id)sender {
    self.screenOffTime = [[NSDate date] timeIntervalSince1970];
}

-(void)dataSourceDidPushViewController:(id)sender {
    approximateDepthOnViewControllerStack++;
}

- (void)userDidLogout:(NSNotification *)notification {
    self.spc_viewDidAppear = NO;
}


#pragma mark -

- (void)updateStatusBarColorNotification:(NSNotification *)note {

}

#pragma mark - Location Fix

- (void)locationServicesAuthorizationStatusWillChange:(NSNotification *)note {
    // Stop observing application state changes while user has a chance to accept/decline location privacy prompt
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)locationServicesAuthorizationStatusDidChange:(NSNotification *)note {
    // Refresh feed
    if (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) && [[LocationManager sharedInstance] locServicesAvailable]) {
        self.spayceState = SpayceStateSeekingLocationFix;
    } else {
        self.spayceState = SpayceStateLocationOff;
    }
    [self refreshContent:YES];
    
    // Start observing application state changes again
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)locationManagerFailed:(NSNotification *)note {
    if (self.spayceState != SpayceStateLocationOff) {
        self.spayceState = SpayceStateLocationOff;
        [self refreshContent:YES];
    }
}


- (void)spc_manualLocationChanged:(NSNotification *)note {
    
    if (_venueViewController) {
        if (![SPCMapDataSource venue:self.venue is:[LocationManager sharedInstance].manualVenue]) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"manual location changed: updating");
            }
            [[LocationContentManager sharedInstance] clearContent:@[SPCLocationContentVenue]];
            [self refreshContent:NO];
        }
    }
}


- (void)spc_locationContentNearbyVenuesServerUpdate:(NSNotification *)note {
    if (_venueViewController && !_performingRefresh) {
        NSLog(@"performing a refresh: new nearby venues added to LocationContentManager");
        [self refreshContent:NO];
    } else {
        NSLog(@"not performing refresh: new venues added to LCM, but we are already refreshing.");
    }
}


- (void)updateForCurrentLocationFixWithRefreshOngoing:(BOOL)refreshOngoing {
    SpayceState state = self.spayceState;
    
    //update map pins and nearby venue list
    [_venueViewController updateVenues:_nearbyVenues withCurrentVenue:_venue deviceVenue:_deviceVenue spayceState:state];
}




@end
