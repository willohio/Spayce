//
//  SPCHereVenueMapViewController.m
//  Spayce
//
//  Created by Jake Rosin on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereVenueMapViewController.h"


// Model
#import "SPCMapDataSource.h"
#import "SPCVenueTypes.h"

// View
#import "SPCAnimationDelegate.h"
#import "SPCMapRadiusHighlightView.h"
#import "SPCStarsView.h"

// Controller
#import "MemoryCommentsViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCHereVenueViewController.h"
#import "SPCHereViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"

// Category
#import "MKMapView+SPCAdditions.h"

// Manager
#import "ContactAndProfileManager.h"
#import "LocationManager.h"
#import "SPCRegionMemoriesManager.h"

static const NSTimeInterval EXPLORE_LOAD_MEMORY_FOR = 8.0f;
static const NSTimeInterval EXPLORE_DISPLAY_MEMORY_FOR = 6.6f;
static const NSTimeInterval EXPLORE_TIME_BETWEEN_MEMORIES = 0.5f;
// static const NSTimeInterval EXPLORE_FADE_IN_DURATION = 1.2f;
static const NSTimeInterval EXPLORE_FADE_OUT_DURATION = 1.0f;
static const NSTimeInterval EXPLORE_GET_MEMORY_REMOTELY_TIMEOUT = 30.0f;
static const NSTimeInterval HIDE_MEMORY_AFTER_DISPLAY_DURATION = 10*60;  // 10 minutes
static const NSTimeInterval HIDE_MEMORY_AFTER_TAP_DURATION = 10 * 60;    // 10 minutes


static const NSTimeInterval USER_LOCATION_FADE_DURATION = 1.4f;


static const CGFloat MIN_ZOOM_EXPLORE_OFF = 15.5;

// in case of bugs....
static const CGFloat MINIMUM_VENUE_RADIUS = 180;
static const CGFloat MAXIMUM_VENUE_RADIUS = 420;



@interface SPCHereUpdate : NSObject

@property (nonatomic, strong) NSArray *allVenues;
@property (nonatomic, strong) Venue *currentVenue;
@property (nonatomic, strong) Venue *deviceVenue;

@property (nonatomic, assign) SpayceState spayceState;

-(instancetype) initWithVenues:(NSArray *)venues currentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue spayceState:(SpayceState)spayceState;

@end

@implementation SPCHereUpdate

-(instancetype) initWithVenues:(NSArray *)venues currentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue spayceState:(SpayceState)spayceState {
    self = [super init];
    if (self) {
        
        //DEDUPLICATE !!
        
        NSMutableArray *tempVenues = [[NSMutableArray alloc] init];
        for (int i = 0; i < venues.count; i++) {
            Venue *venue = venues[i];
            BOOL alreadyAdded = NO;
            
            for (int j = 0; j < tempVenues.count; j++) {
                Venue *prevVenue = tempVenues[j];
                if (venue.locationId == prevVenue.locationId) {
                    alreadyAdded = YES;
                    break;
                }
            }
            
            if (!alreadyAdded) {
                [tempVenues addObject:venue];
            }
        }
        
        venues = [NSArray arrayWithArray:tempVenues];
        
        // Ensure that our current venue is in the list.
        __block BOOL hasCurrent = NO;
        __block BOOL hasDevice = NO;
        [venues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Venue * venue = obj;
            if ([SPCMapDataSource venue:venue is:currentVenue]) {
                hasCurrent = YES;
            }
            if ([SPCMapDataSource venue:venue is:deviceVenue]) {
                hasDevice = YES;
            }
            if (hasCurrent && hasDevice) {
                *stop = YES;
            }
        }];
        
        NSArray * allVenues = [NSArray arrayWithArray:venues];
        if (!hasCurrent && currentVenue) {
            allVenues = [allVenues arrayByAddingObject:currentVenue];
        }
        if (!hasDevice && deviceVenue && ![SPCMapDataSource venue:deviceVenue is:currentVenue]) {
            allVenues = [allVenues arrayByAddingObject:deviceVenue];
        }
        
        self.allVenues = allVenues;
        self.currentVenue = currentVenue;
        self.deviceVenue = deviceVenue;
        self.spayceState = spayceState;
    }
    return self;
}

@end

@interface SPCHereVenueMapViewController () <SPCMapDataSourceDelegate, SPCGoogleMapInfoViewSupportDelegateDelegate>

// Map display / helper properties

@property (nonatomic, strong) SPCMapRadiusHighlightView * mapRadiusHighlightView;
@property (nonatomic, strong) SPCGoogleMapInfoViewSupportDelegate *mapViewSupportDelegate;
@property (nonatomic, strong) SPCMapDataSource *mapDataSource;
@property (nonatomic, strong) SPCStarsView *starsView;
@property (nonatomic, assign) CGFloat midY;

@property (nonatomic, assign) BOOL didViewAppear;

// Searching
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) NSCache *geocoderResultCache;
@property (nonatomic, strong) NSString *searchOperationActiveString;
@property (nonatomic, strong) NSString *searchOperationPendingString;
@property (nonatomic, strong) CLLocation *mapSearchResetLocation;
@property (nonatomic, strong) CLLocation *mapZoomResetLocation;


// Venue data
@property (nonatomic, strong) NSArray * allVenues;
@property (nonatomic, strong) Venue * currentVenue;
@property (nonatomic, assign) SpayceState spayceState;
// New data
@property (nonatomic, strong) SPCHereUpdate *updatePending;
@property (nonatomic, assign) BOOL isUpdateOngoing;

// Venue markers
@property (nonatomic, strong) NSArray * allMarkers;
@property (nonatomic, strong) NSArray * activeMarkers;
@property (nonatomic, strong) SPCMarker * locationMarker;
@property (strong, nonatomic) NSTimer *locationMarkerAdjustTimer;
@property (nonatomic, readonly) BOOL locationMarkerShouldDisplay;
@property (nonatomic, readonly) BOOL venueMarkersShouldDisplay;
@property (nonatomic, assign) BOOL manuallyLocationResetInProgress;
@property (nonatomic, assign) int maxZ;
@property (nonatomic, assign) CGFloat currZoom;
@property (nonatomic, assign) CGFloat popularZoom;

// Venue region
@property (nonatomic, assign) MKCoordinateRegion venueRegion;
@property (nonatomic, assign) BOOL venueRegionIsSet;

// Display
@property (nonatomic, readonly) BOOL limitToVenueRegion;
@property (nonatomic, readonly) BOOL displayVenueRegionLimitation;
@property (nonatomic, assign) BOOL userInterfaceHidden;
@property (nonatomic, readonly) BOOL displayStarsView;

// Explore properties
@property (nonatomic, assign) BOOL exploreConfigured;
@property (strong, nonatomic) NSTimer *exploreRefreshTimer;
@property (strong, nonatomic) NSTimer *exploreDisplayTimer;
@property (nonatomic, assign) NSTimeInterval exploreMemoryRemoteFetchBeganAt;
@property (nonatomic, assign) NSTimeInterval exploreMemoryLoadingAt;
@property (nonatomic, assign) NSTimeInterval exploreMemoryDisplayedAt;
@property (nonatomic, assign) NSTimeInterval exploreMemoryDismissedAt;
@property (nonatomic, assign) BOOL exploreMemoryIsFading;
@property (nonatomic, assign) BOOL exploreMemoryIsLoading;
@property (nonatomic, assign) BOOL exploreMemoryIsDisplayed;
@property (nonatomic, strong) Memory *exploreMemory;
@property (nonatomic, strong) SPCMarker *exploreMemoryMarker;


@property (nonatomic, strong) UIView *filterControlBar;
@property (nonatomic, assign) BOOL draggingMap;

@end

@implementation SPCHereVenueMapViewController {
    NSTimeInterval _updateStartedAt;
    BOOL _isUpdateOngoing;
}

@synthesize locationMarker=_locationMarker;

-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_mapRadiusHighlightView];
    [NSObject cancelPreviousPerformRequestsWithTarget:_mapView];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.locationMarkerAdjustTimer invalidate];
    self.locationMarkerAdjustTimer = nil;
    [self.exploreRefreshTimer invalidate];
    self.exploreRefreshTimer = nil;
    [self.exploreDisplayTimer invalidate];
    self.exploreDisplayTimer = nil;
}

-(instancetype) init {
    self = [super init];
    if (self) {
        _spayceState = SpayceStateLocationOff;
        self.userInterfaceHidden = YES;
    }
    return self;
}

-(void)loadView {
    [super loadView];
    [self.view addSubview:self.mapView];
    //[self.view addSubview:self.starsView];
    [self.view addSubview:self.filterControlBar];
    
    self.refreshLocationButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 47, 5, 45, 45)];
    [self.refreshLocationButton setBackgroundImage:[UIImage imageNamed:@"button-refresh-location"] forState:UIControlStateNormal];
    [self.refreshLocationButton addTarget:self action:@selector(refreshLocationButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}


-(void)viewDidLoad {
    [super viewDidLoad];
    [self configureMapView];
    self.popularZoom = 17.5;
    self.currZoom = 17.5;
    
    // Timers!
    self.exploreRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:61.23f target:self selector:@selector(exploreRefreshTimerDidTrigger) userInfo:nil repeats:YES];
    self.exploreDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:EXPLORE_DISPLAY_MEMORY_FOR target:self selector:@selector(exploreDisplayTimerDidTrigger) userInfo:nil repeats:YES];
    
    [self showNeutralRegion];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidUpdateProfile:) name:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fadeDownPinsForFeaturedMemory) name:@"fadeDownPinsForFeaturedMemory" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(displayVenueOnScroll:) name:@"displayVenueOnScroll" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToVenueFromMultiPin:) name:@"jumpToVenueFromMultiPin" object:nil];
    
}

-(void)viewDidAppear:(BOOL)animated {
    if (!self.didViewAppear) {
        [super viewDidAppear:animated];
        //NSLog(@"viewDidAppear");
        self.didViewAppear = YES;
        if (self.exploreMemoryIsDisplayed && !self.isExplorePaused) {
            // display the memory for a minimum of 1 second
            self.exploreMemoryMarker.opacity = 1.0f;
            self.exploreMemoryMarker.layer.opacity = 1.0f;
            self.exploreMemoryDisplayedAt = MAX(self.exploreMemoryDisplayedAt,
                                                [[NSDate date] timeIntervalSince1970] - EXPLORE_DISPLAY_MEMORY_FOR + 1.0);
            [self.exploreMemoryMarker.layer addAnimation:[self animationToFullOpacityQuickly:self.exploreMemoryMarker] forKey:@"fadeInReturn"];
        }
        
        // reload user marker?
        __weak typeof(self) weakSelf = self;
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                strongSelf.locationMarker.position = CLLocationCoordinate2DMake(gpsLat, gpsLong);
            } faultCallback:^(NSError *fault) {
                // meh?
            }];
        }
        if (self.displayStarsView) {
            [self.starsView startAnimation];
        }
    }
}

- (void)applicationDidBecomeActive:(id)sender {
    if (self.displayStarsView) {
        [self.starsView startAnimation];
    }
}

- (void)userDidUpdateProfile:(id)sender {
    if (_locationMarker) {
        [SPCMarkerVenueData configureMarker:_locationMarker withVenueData:_locationMarker.userData reposition:NO];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    if (self.didViewAppear) {
        [super viewWillDisappear:animated];
        
        //NSLog(@"viewDidDisappear");
        self.didViewAppear = NO;
    }
}


#pragma mark - properties


-(void)setAnimatingMemory:(BOOL)animatingMemory {
    _animatingMemory = animatingMemory;
}


-(GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:self.view.bounds];
        _mapView.delegate = self.mapViewSupportDelegate;
        _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _mapView.userInteractionEnabled = YES;
        _mapView.settings.rotateGestures = NO;
        _mapView.settings.tiltGestures = NO;
        _mapView.buildingsEnabled = NO;
        
        UIEdgeInsets mapInsets = UIEdgeInsetsMake(0.0, 0.0, 150.0, 0.0);
        _mapView.padding = mapInsets;
        
        [self setMapLimits];
    }
    return _mapView;
}

-(GMSMapView *)hiddenMapView {
    
    if (!_hiddenMapView) {
        _hiddenMapView = [[GMSMapView alloc] initWithFrame:self.view.bounds];
        UIEdgeInsets mapInsets = UIEdgeInsetsMake(0.0, 0.0, 50.0, 0.0);
        _hiddenMapView.padding = mapInsets;
        _hiddenMapView.hidden = YES;
        _hiddenMapView.buildingsEnabled = NO;
    }
    return _hiddenMapView;
    
}

- (void)configureMapView {
    // TODO: any necessary config?  This is a stub implementation.
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
            [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:gpsLat longitude:gpsLong zoom:18]];
            self.locationMarker.map = self.mapView;
        } faultCallback:^(NSError *fault) {
            // nothing
            self.locationMarker.opacity = 0.0f;
            self.locationMarker.layer.opacity = 0.0f;
            self.locationMarker.map = self.mapView;
        }];
    }
    else {
        // nothing
        self.locationMarker.opacity = 0.0f;
        self.locationMarker.layer.opacity = 0.0f;
        self.locationMarker.map = self.mapView;
    }
}

-(SPCMapRadiusHighlightView *) mapRadiusHighlightView {
    if (!_mapRadiusHighlightView) {
        _mapRadiusHighlightView = [[SPCMapRadiusHighlightView alloc] initWithFrame:self.mapView.bounds];
        _mapRadiusHighlightView.highlight = YES;
        [_mapRadiusHighlightView updateWithMapView:self.mapView];
        [self setMapLimits];
    }
    return _mapRadiusHighlightView;
}

-(SPCMapDataSource *) mapDataSource {
    if (!_mapDataSource) {
        _mapDataSource = [[SPCMapDataSource alloc] init];
        _mapDataSource.delegate = self;
        _mapDataSource.stackedVenueType = StackedVenueTypeOmitDeviceLocation;
        _mapDataSource.zIndexVenue = 1;
        _mapDataSource.zIndexCurrent = 2;
        _mapDataSource.zIndexDevice = 0;
        _maxZ = 2;
    }
    return _mapDataSource;
}

- (SPCGoogleMapInfoViewSupportDelegate *)mapViewSupportDelegate {
    if (!_mapViewSupportDelegate) {
        _mapViewSupportDelegate = [[SPCGoogleMapInfoViewSupportDelegate alloc] init];
        _mapViewSupportDelegate.delegate = self;
    }
    return _mapViewSupportDelegate;
}

- (SPCStarsView *)starsView {
    if (!_starsView) {
        _starsView = [[SPCStarsView alloc] initWithFrame:self.mapView.frame];
        _starsView.hidden = !self.displayStarsView;
        _starsView.alpha = _starsView.hidden ? 0.0 : 1.0;
        if (!_starsView.hidden) {
            [_starsView startAnimation];
        }
    }
    return _starsView;
}

-(SPCMarker *)locationMarker {
    if (!_locationMarker) {
        CLLocation *location;
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            location = [LocationManager sharedInstance].currentLocation;
        }
        if (location) {
            _locationMarker = [SPCMarkerVenueData markerWithOriginalAndCurrentLocation:location venue:nil];
        } else {
            _locationMarker = [SPCMarkerVenueData markerWithOriginalAndCurrentLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0] venue:nil];
        }
    }
    return _locationMarker;
}

-(UIView *)filterControlBar  {
    if (!_filterControlBar) {
        _filterControlBar  = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height-45, self.view.bounds.size.width,45)];
        _filterControlBar.backgroundColor = [UIColor colorWithWhite:1 alpha:.5];
        
        NSArray *filterOptions = [[NSArray alloc] initWithObjects:@"All",@"Nearby",@"Popular",@"Night",@"Day", nil];
        float btnWidth = roundf(self.view.bounds.size.width / filterOptions.count);
        
        for (int i = 0; i < filterOptions.count; i ++) {
            
            float xOrigin = i * btnWidth;
            
            float mkOpticsXAdj = 0;
            if (i == 1) {
                mkOpticsXAdj = -7;
            }
            if (i == 2) {
                mkOpticsXAdj = 2;
            }
            if (i == 3) {
                mkOpticsXAdj = 4;
            }
            if (i == 4) {
                mkOpticsXAdj = -2;
            }
            UIButton *tempBtn = [[UIButton alloc] initWithFrame:CGRectMake(xOrigin+mkOpticsXAdj, 0, btnWidth, 45)];
            NSString *titleString = filterOptions[i];
            [tempBtn setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
            [tempBtn setTitle:titleString forState:UIControlStateNormal];
            [tempBtn setTitleColor:[UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f] forState:UIControlStateNormal]; ;
            [tempBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
            [tempBtn setBackgroundColor:[UIColor clearColor]];
            tempBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
            [tempBtn addTarget:self action:@selector(filterPins:) forControlEvents:UIControlEventTouchDown];
            tempBtn.tag = i;
            
            if (i == 0) {
                tempBtn.selected = YES;
            }
            [_filterControlBar addSubview:tempBtn];
        }
        _filterControlBar.hidden = YES;
    }
    return _filterControlBar;
}

-(void)setLocationMarker:(SPCMarker *)locationMarker {
    if (_locationMarker != locationMarker) {
        _locationMarker.map = nil;
        _locationMarker = locationMarker;
    }
}



- (CLGeocoder *)geocoder {
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

- (NSCache *)geocoderResultCache {
    if (!_geocoderResultCache) {
        _geocoderResultCache = [[NSCache alloc] init];
        [_geocoderResultCache setCountLimit:30];
    }
    return _geocoderResultCache;
}

- (BOOL)isUpdateOngoing {
    return _isUpdateOngoing && [[NSDate date] timeIntervalSince1970] - _updateStartedAt < 4;
}

- (void)setIsUpdateOngoing:(BOOL)isUpdateOngoing {
    _isUpdateOngoing = isUpdateOngoing;
    if (_isUpdateOngoing) {
        _updateStartedAt = [[NSDate date] timeIntervalSince1970];
    }
}

- (BOOL)locationMarkerShouldDisplay {
    return [self locationMarkerShouldDisplayWithSpayceState:self.spayceState];
}

- (BOOL)locationMarkerShouldDisplayWithSpayceState:(SpayceState)spayceState {
    switch(spayceState) {
        case SpayceStateLocationOff:
            return NO;
        case SpayceStateSeekingLocationFix:
            return NO;
        case SpayceStateUpdatingLocation:
            return NO;
        case SpayceStateRetrievingLocationData:
            return NO;
        case SpayceStateDisplayingLocationData:
            return NO;
    }
    return NO;
}

- (BOOL)venueMarkersShouldDisplay {
    return [self venueMarkersShouldDisplayWithSpayceState:self.spayceState];
}

-(BOOL)venueMarkersShouldDisplayWithSpayceState:(SpayceState)spayceState {
    switch(spayceState) {
        case SpayceStateLocationOff:
            return NO;
        case SpayceStateSeekingLocationFix:
            return NO;
        case SpayceStateUpdatingLocation:
            return NO;
        case SpayceStateRetrievingLocationData:
            return self.allVenues != nil && !self.manuallyLocationResetInProgress;
        case SpayceStateDisplayingLocationData:
            return YES;
    }
    return NO;
}

-(BOOL)venueRegionIsSet {
    return self.venueRegion.center.latitude != 0 || self.venueRegion.center.longitude != 0;
}


-(BOOL)limitToVenueRegion {
    return _mapView != nil && _mapRadiusHighlightView != nil && self.venueRegionIsSet && (!self.isExploreOn || self.isExplorePaused || self.userInterfaceHidden) && !self.isViewingFromHashtags;
}

-(BOOL)displayVenueRegionLimitation {
    return self.limitToVenueRegion && !self.userInterfaceHidden;
}

-(BOOL)displayStarsView {
    return (self.spayceState == SpayceStateSeekingLocationFix && self.userInterfaceHidden);
}

-(void)updateStarsViewAlpha:(BOOL)animated {
    if (self.displayStarsView && self.starsView.hidden) {
        NSTimeInterval duration = animated ? 0.3 : 0.0;
        self.starsView.alpha = 0;
        self.starsView.hidden = NO;
        [self.starsView startAnimation];
        [UIView animateWithDuration:duration animations:^{
            self.starsView.alpha = 1;
        }];
    } else if (!self.displayStarsView && !self.starsView.hidden) {
        NSTimeInterval duration = animated ? 0.3 : 0.0;
        [UIView animateWithDuration:duration animations:^{
            self.starsView.alpha = 0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.starsView.hidden = YES;
                [self.starsView stopAnimation];
            }
        }];
    }
}

-(void)setMapLimits {
    // set map capabilities
    if (!self.limitToVenueRegion) {
        [_mapRadiusHighlightView removeFromSuperview];
        [_mapView setMinZoom:0 maxZoom:1000000];
    } else {
        [self.mapRadiusHighlightView removeFromSuperview];
        if (self.limitToVenueRegion) {
            [self showLimitedRegionIfOutside];
        }
        CLLocation * location;
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            location = [LocationManager sharedInstance].currentLocation;
        }
        if (location && location.coordinate.latitude && location.coordinate.longitude) {
            [_mapView setMinZoom:MIN_ZOOM_EXPLORE_OFF maxZoom:1000000];
        }
        if (self.displayVenueRegionLimitation) {
            _mapRadiusHighlightView.alpha = 0;
            [_mapView insertSubview:_mapRadiusHighlightView atIndex:1];
        }
    }
}


#pragma mark - Public properties

-(BOOL) isAtDeviceLocation {
    // TODO: return whether this map view is centered to look at
    // the device location (where the user is physically positioned).
    return NO;
}

-(void) setIsExploreOn:(BOOL)isExploreOn {
    if (_isExploreOn == isExploreOn && _exploreConfigured) {
        // nothin
        return;
    }
    
    // cancel search editing
    [self.view endEditing:YES];
    
    _exploreConfigured = YES;
    
    if (isExploreOn) {
        _isExploreOn = YES;
        [self performSelector:@selector(refreshNearbyMemories) withObject:nil afterDelay:1.0f];
        // Our scheduling section will begin displaying these new memories
        // when they become available.
    } else {
        _isExploreOn = NO;
        [self dismissExploreMemoryWithFadeDuration:0.0f];
    }
    
    // set map capabilities
    if (!_isExploreOn && _currentVenue && _mapView) {
        CGRect visibleBounds = [self visibleRectInMapView];
        if (![self mapView:_mapView withVisibleRect:visibleBounds isDisplayingCoordinateRegion:self.venueRegion] || self.mapView.camera.zoom < MIN_ZOOM_EXPLORE_OFF) {
            [self showLatitude:[_currentVenue.latitude floatValue] longitude:[_currentVenue.longitude floatValue]];
        }
    }
    [self setMapLimits];
}

-(void)setIsExplorePaused:(BOOL)isExplorePaused {
    if (_isExplorePaused != isExplorePaused) {
        _isExplorePaused = isExplorePaused;
        if (self.exploreMemoryIsDisplayed) {
            if (!isExplorePaused) {
                // display the memory for a minimum of 1 second
                self.exploreMemoryMarker.opacity = 1.0f;
                self.exploreMemoryMarker.layer.opacity = 1.0f;
                self.exploreMemoryDisplayedAt = MAX(self.exploreMemoryDisplayedAt,
                                                    [[NSDate date] timeIntervalSince1970] - EXPLORE_DISPLAY_MEMORY_FOR + 1.0);
                [self.exploreMemoryMarker.layer addAnimation:[self animationToFullOpacityQuickly:self.exploreMemoryMarker] forKey:@"fadeInReturn"];
            } else {
                // hide this memory immediately
                self.exploreMemoryMarker.opacity = 0.0f;
                self.exploreMemoryMarker.layer.opacity = 0.0f;
                [self.exploreMemoryMarker.layer addAnimation:[self animationToZeroOpacityQuickly:self.exploreMemoryMarker] forKey:@"fadeOutReturn"];
            }
        }
    }
}

-(void)setSearchFilter:(NSString *)searchFilter {
    if (!searchFilter || [searchFilter length] == 0 || [searchFilter isEqualToString:self.searchFilter]) {
        return;
    }
    
    _searchFilter = searchFilter;
    
    if (self.searchOperationActiveString) {
        // wait for this operation to complete.
        self.searchOperationPendingString = searchFilter;
        return;
    }
    
    [self performSearchFor:searchFilter];
}

- (void)performSearchFor:(NSString *)searchFilter {
    // Check the cache...
    CLPlacemark * cachedPlacemark = [self.geocoderResultCache objectForKey:searchFilter];
    if (cachedPlacemark) {
        // use this cached value!
        self.searchOperationActiveString = nil;
        self.searchOperationPendingString = nil;
        
        if (self.isExploreOn && !self.isExplorePaused) {
            [self handleSearchResultWithPlacemark:cachedPlacemark];
        }
    } else {
        // Launch a search.
        self.searchOperationActiveString = searchFilter;
        self.searchOperationPendingString = nil;
        
        // Launch the search
        __weak typeof(self)weakSelf = self;
        
        [self.geocoder geocodeAddressString:searchFilter completionHandler:^(NSArray *placemarks, NSError *error) {
            // stuff
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            NSString * activeSearch = strongSelf.searchOperationActiveString;
            strongSelf.searchOperationActiveString = nil;
            
            if (placemarks && placemarks.count > 0) {
                [strongSelf.geocoderResultCache setObject:placemarks[0] forKey:searchFilter];
            }
            
            if ([activeSearch isEqualToString:searchFilter] && !strongSelf.searchOperationPendingString) {
                // This is our search term, and no additional term is pending.
                if (placemarks && placemarks.count > 0) {
                    //NSLog(@"found placemarks..");
                    [strongSelf handleSearchResultWithPlacemark:placemarks[0]];
                }
                else {
                    //NSLog(@"no placemarks found");
                    [strongSelf.delegate searchIsCompleteWithResults:NO];
                }
            }
            
            // launch the pending search?
            if (strongSelf.searchOperationPendingString) {
                //NSLog(@"results discarded, there was another pending search");
                [strongSelf performSearchFor:strongSelf.searchOperationPendingString];
            }
        }];
    }
}

-(void)handleSearchResultWithPlacemark:(CLPlacemark *)placemark {
    
    if (!self.mapSearchResetLocation) {
        CGPoint centerViewAt = centerViewAt = CGPointMake(CGRectGetMidX(self.mapView.frame),self.midY);
        CLLocationCoordinate2D mapCenter = [self.mapView.projection coordinateForPoint:centerViewAt];
        self.mapSearchResetLocation = [[CLLocation alloc] initWithLatitude:mapCenter.latitude longitude:mapCenter.longitude];
        //NSLog(@"handleSearchResultWithPlacemark - map should flash, but overlay should still be up...");
    }
    [self testLatitude:placemark.location.coordinate.latitude longitude:placemark.location.coordinate.longitude zoom:12];
    
    // immediately display a realtime pin at this location -- or attempt to,
    // at least, if our displayed memory is not on screen.
    BOOL display = NO;
    BOOL searchFailed = YES;
    if (self.exploreMemoryIsDisplayed || self.exploreMemoryIsLoading) {
        //NSLog(@"After search, explore memory is either displayed or loading.");
        // offscreen?
        if (![[SPCRegionMemoriesManager sharedInstance] isMemory:self.exploreMemory inRegionWithProjection:self.hiddenMapView.projection mapViewBounds:[self visibleRectInMapView]]) {
            //NSLog(@"Memory was offscreen: dismissing.");
            // dismiss.
            [self dismissExploreMemoryWithFadeDuration:0.0f];
            display = YES;
        }
        else {
            //NSLog(@"explore memory is within region!");
            searchFailed = NO;
        }
    } else {
        //NSLog(@"After search, no explore memory is displayed.  Immediately put one on screen.");
        display = YES;
    }
    if (display) {
        //NSLog(@"displayExploreMemoryFromSearch!");
        [self displayExploreMemoryFromSearch];
        searchFailed = NO;
    }
    if (searchFailed) {
        //reset map if needed
        //NSLog(@"search failed");
        [self showLatitude:self.mapSearchResetLocation.coordinate.latitude longitude:self.mapSearchResetLocation.coordinate.longitude animated:NO];
        [self.delegate searchIsCompleteWithResults:NO];
    }
}


#pragma mark - Location analysis

- (BOOL) mapView:(GMSMapView *)mapView withVisibleRect:(CGRect)visibleRect isDisplayingCoordinateRegion:(MKCoordinateRegion)coordinateRegion {
    CGPoint center = CGPointMake(CGRectGetMidX(visibleRect), CGRectGetMidY(visibleRect));
    CLLocationCoordinate2D coordinate = [mapView.projection coordinateForPoint:center];
    return [self location:coordinate isInCoordinateRegion:coordinateRegion] || [self cornerIntersectionBetweenCoordinateRegion:coordinateRegion andMap:mapView withBounds:visibleRect];
}

- (BOOL)location:(CLLocationCoordinate2D)location isInCoordinateRegion:(MKCoordinateRegion)coordinateRegion {
    CLLocationCoordinate2D center = coordinateRegion.center;
    MKCoordinateSpan span = coordinateRegion.span;
    return center.latitude - span.latitudeDelta/2.0f <= location.latitude
    && location.latitude <= center.latitude + span.latitudeDelta/2.0f
    && center.longitude - span.longitudeDelta/2.0f <= location.longitude
    && location.longitude <= center.longitude + span.longitudeDelta/2.0f;
}

- (BOOL)location:(CLLocationCoordinate2D)location isOnMap:(GMSMapView *)mapView {
    CGPoint viewPoint = [mapView.projection pointForCoordinate:location];
    return viewPoint.x >= 0 && viewPoint.x <= mapView.frame.size.width
    && viewPoint.y >= 0 && viewPoint.y <= mapView.frame.size.height;
}

- (BOOL)cornerIntersectionBetweenCoordinateRegion:(MKCoordinateRegion)coordinateRegion andMap:(GMSMapView *)mapView withBounds:(CGRect)bounds {
    CLLocationCoordinate2D center = coordinateRegion.center;
    MKCoordinateSpan span = coordinateRegion.span;
    
    CLLocationCoordinate2D farLeft = [mapView.projection coordinateForPoint:CGPointMake(bounds.origin.x, bounds.origin.y)];
    CLLocationCoordinate2D farRight = [mapView.projection coordinateForPoint:CGPointMake(bounds.origin.x + bounds.size.width, bounds.origin.y)];
    CLLocationCoordinate2D nearLeft = [mapView.projection coordinateForPoint:CGPointMake(bounds.origin.x, bounds.origin.y + bounds.size.height)];
    CLLocationCoordinate2D nearRight = [mapView.projection coordinateForPoint:CGPointMake(bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height)];
    
    // Determine whether 1. any corner of the provided region is displayed on the map,
    // or 2. any corner of the map view is within the region.
    
    return
    [self location:CLLocationCoordinate2DMake(center.latitude - span.latitudeDelta/2.0f, center.longitude - span.longitudeDelta/2.0f) isOnMap:mapView]
    || [self location:CLLocationCoordinate2DMake(center.latitude + span.latitudeDelta/2.0f, center.longitude - span.longitudeDelta/2.0f) isOnMap:mapView]
    || [self location:CLLocationCoordinate2DMake(center.latitude - span.latitudeDelta/2.0f, center.longitude + span.longitudeDelta/2.0f) isOnMap:mapView]
    || [self location:CLLocationCoordinate2DMake(center.latitude + span.latitudeDelta/2.0f, center.longitude + span.longitudeDelta/2.0f) isOnMap:mapView]
    || [self location:farLeft isInCoordinateRegion:coordinateRegion]
    || [self location:farRight isInCoordinateRegion:coordinateRegion]
    || [self location:nearLeft isInCoordinateRegion:coordinateRegion]
    || [self location:nearRight isInCoordinateRegion:coordinateRegion];
}

- (CLLocationCoordinate2D)projectLocation:(CLLocationCoordinate2D)location intoCoordinateRegion:(MKCoordinateRegion)coordinateRegion {
    if ([self location:location isInCoordinateRegion:coordinateRegion]) {
        return location;
    }
    
    CGFloat latMin = coordinateRegion.center.latitude - coordinateRegion.span.latitudeDelta/2.0f;
    CGFloat latMax = coordinateRegion.center.latitude + coordinateRegion.span.latitudeDelta/2.0f;
    CGFloat lngMin = coordinateRegion.center.longitude - coordinateRegion.span.longitudeDelta/2.0f;
    CGFloat lngMax = coordinateRegion.center.longitude + coordinateRegion.span.longitudeDelta/2.0f;
    
    CGFloat a = 1.0f;
    // a: the proportion of the distance from center to 'projectedLocation'
    //      in order to reach the view boundary.
    if (location.latitude < latMin) {
        a = fminf(a, fabsf(latMin - coordinateRegion.center.latitude) / fabsf(location.latitude - coordinateRegion.center.latitude));
    }
    if (location.latitude > latMax) {
        a = fminf(a, fabsf(latMax - coordinateRegion.center.latitude) / fabsf(location.latitude - coordinateRegion.center.latitude));
    }
    if (location.longitude < lngMin) {
        a = fminf(a, fabsf(lngMin - coordinateRegion.center.longitude) / fabsf(location.longitude - coordinateRegion.center.longitude));
    }
    if (location.longitude > lngMax) {
        a = fminf(a, fabsf(lngMax - coordinateRegion.center.longitude) / fabsf(location.longitude - coordinateRegion.center.longitude));
    }
    // project!
    return CLLocationCoordinate2DMake(a*location.latitude + (1-a)*coordinateRegion.center.latitude, a*location.longitude + (1-a)*coordinateRegion.center.longitude);
}


#pragma mark - Map Data Source Delegate 

- (void)userDidSelectVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker {
    [self showLatitude:[venue.latitude floatValue] longitude:[venue.longitude floatValue]];
    if ([self.delegate respondsToSelector:@selector(hereVenueMapViewController:didSelectVenue:)]) {
        [self.delegate hereVenueMapViewController:self didSelectVenue:venue];
    }
}


#pragma mark - SPCGoogleMapInfoViewSupportDelegateDelegate


-(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker {
    return [self.mapDataSource getInfoWindowForMarker:marker mapView:mapView];
}

-(void) mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (gesture) {
        // cancel search editing
        [self.view endEditing:YES];
        self.draggingMap = YES;
    }
}

-(void) mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self.mapRadiusHighlightView updateWithMapView:mapView];
    if (self.limitToVenueRegion) {
        [self showLimitedRegionIfOutside];
    }
}

-(void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    //NSLog(@"mapView idle at camera position!");
    if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
        [self cycleDisplayedExploreMemory];
    }
    self.draggingMap = NO;
    [self.mapView setUserInteractionEnabled:YES];
}

-(BOOL) mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    // cancel search editing
    [self.view endEditing:YES];
    
    if ([self.delegate respondsToSelector:@selector(hereVenueMapViewController:revealAnimated:)]) {
        [self.delegate hereVenueMapViewController:self revealAnimated:YES];
    }
    return NO;
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker {
    [self.view endEditing:YES];
    
    NSLog(@"did tap marker");
    
    if (![marker.userData isKindOfClass:[SPCMarkerVenueData class]]) {
        return NO;
    }
    
    SPCMarkerVenueData *venueData = (SPCMarkerVenueData *)marker.userData;
    
    if (venueData.isRealtime) {
        // show this memory
        [self didTapExploreMemory:self];
        
        
        /*
         SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
         venueDetailViewController.venue = venueData.venue;
         
         SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
         navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
         */
        
        if (!self.isViewingFromHashtags) {
            [self displayVenueAndUpdatePins:venueData.venue];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(showVenueDetail:jumpToMemory:)]) {
            NSLog(@"show venue detail!");
            [self.delegate showVenueDetail:venueData.venue jumpToMemory:venueData.memory];
        }
        

        
        return YES;
    }
    
    // ignore taps
    if (venueData.isOriginalUserLocation) {
        return YES;
    }
    
    if (venueData.venueCount <= 1) {
        NSLog(@"tap on singe-venue pin?");
        if (!self.isViewingFromHashtags) {

            _maxZ = _maxZ + 1;
            marker.zIndex = _maxZ;
            [self resetIconsForOtherMarkers];
            marker.icon = marker.selectedIcon;
            self.currentVenue = venueData.venue;
        }
        
        /*
        SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
        venueDetailViewController.venue = venueData.venue;
        
        SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
        navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
         */
        
        if (!self.isViewingFromHashtags) {
            [self displayVenueAndUpdatePins:venueData.venue];
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(showVenueDetailFeed:)]) {
            NSLog(@"show venue detail!");
            [self.delegate showVenueDetailFeed:venueData.venue];
        }

    }
    else {

        if ([self.delegate respondsToSelector:@selector(hereVenueMapViewController:didSelectVenuesFromFullScreen:)]) {
            //NSLog(@"tap on multi-venue pin?");
            [self.delegate hereVenueMapViewController:self didSelectVenuesFromFullScreen:venueData.venues];
        }
    }
    
    return YES;
}

-(CGFloat)mapView:(GMSMapView *)mapView calloutHeightForMarker:(SPCMarker *)marker {
    return [self.mapDataSource infoWindowHeightForMarker:marker mapView:mapView];
}



#pragma mark - actions

- (void)locationResetManually {
    self.manuallyLocationResetInProgress = YES;
    CLLocationCoordinate2D coord;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        coord = [LocationManager sharedInstance].currentLocation.coordinate;
    }
    if (coord.latitude != 0 || coord.longitude != 0) {
        [self showLatitude:coord.latitude longitude:coord.longitude];
    }
}

- (void)displayVenueOnScroll:(NSNotification *)notification {
    
    if (!self.isViewingMemFromExplore) {
    
        Venue *venue = (Venue *)[notification object];
        
        [self displayVenueAndUpdatePins:venue];
    }
    else {
        self.isViewingMemFromExplore = NO;
    }
}

- (void)displayVenueAndUpdatePins:(Venue *)venue {
    
    //look for a matching pin by locationId and get the lat/long
    float markerLat;
    float markerLong;
    
    
    //NOTE: it will be missing on the first pass if it's part of a multivenue pin
    
    BOOL foundMatch = NO;
    
    for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
        
        //reset all markers
        marker.icon = marker.nonSelectedIcon;
        
        //look for matches w/in all markers
        if (((SPCMarkerVenueData *)marker.userData).venue.locationId == venue.locationId) {
            
            // only update it here if it's a single venue marker
            if (((SPCMarkerVenueData *)marker.userData).venueCount == 1) {
                self.maxZ = self.maxZ + 1;
                marker.zIndex = self.maxZ;
                marker.icon = marker.selectedIcon;
                
                markerLat = marker.position.latitude;
                markerLong = marker.position.longitude;
                foundMatch = YES;
            }
        }
    }
    
    //the location is on a multivenue pin
    if (!foundMatch) {
        //NSLog(@"multivenue!");
        NSNumber *locIDToMatch = @(venue.locationId);
        
        //we must find our location's marker
        
        for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
            
            //only look for matches w/in multivenue pins
            if (((SPCMarkerVenueData *)marker.userData).venueCount > 1) {
                
                //for each multivenue pin: loop thru the compainion ids array of the active venue of the pin, and look for a match
                for (int i = 0; i < ((SPCMarkerVenueData *)marker.userData).venue.companionLocIds.count; i ++) {
                    
                    NSNumber *testID = ((SPCMarkerVenueData *)marker.userData).venue.companionLocIds[i];
                    
                    if (testID == locIDToMatch) {
                        //found the right marker to update!
                        self.maxZ = self.maxZ + 1;
                        marker.zIndex = self.maxZ;
                        
                        //customize the marker for the active venue w/in the multivenue pin
                        marker.icon = [marker.userData markerWithVenueForLocationId:venue];
                        
                        markerLat = marker.position.latitude;
                        markerLong = marker.position.longitude;
                        break;
                    }
                }
            }
        }
    }
    
    NSLog(@"venue %@",venue.displayNameTitle);
    NSLog(@"showMarker at lat: %f long: %f",markerLat,markerLong);
    
    self.currentVenue = venue;
    if (!self.animatingMemory) {
        [self updateZoomLevelForLatitude:markerLat longitude:markerLong];
        [self showLatitude:markerLat longitude:markerLong zoom:self.currZoom animated:YES];
        [self testLatitude:markerLat longitude:markerLong zoom:self.currZoom];
    }
    NSLog(@"update visible pins for lat!");
    [self updateVisiblePinsForLatitude:markerLat longitude:markerLong];
    NSLog(@"displayVenueAndUpdatePins done");
}

- (void)jumpToVenueFromMultiPin:(NSNotification *)notification {
    
    Venue *venue = (Venue *)[notification object];
    
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = venue;
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    
    [self.tabBarController presentViewController:navController animated:YES completion:nil];
}

- (void)showVenue:(Venue *)venue {
    if (venue) {
        [self showLatitude:venue.latitude.floatValue longitude:venue.longitude.floatValue];
    }
}

- (void)showVenue:(Venue *)venue withZoom:(float)zoom {
    if (venue) {
        [self showLatitude:venue.latitude.floatValue longitude:venue.longitude.floatValue zoom:zoom animated:YES];
        [self displayNextExploreMemoryIgnoringRateLimit:YES];
    }
}

- (void)showVenue:(Venue *)venue withZoom:(float)zoom animated:(BOOL)animated {
    if (venue) {
        [self showLatitude:venue.latitude.floatValue longitude:venue.longitude.floatValue zoom:zoom animated:animated];
        [self displayNextExploreMemoryIgnoringRateLimit:YES];
    }
}

- (void)resetIconsForOtherMarkers {
    for (SPCMarker *marker in self.allMarkers) {
        marker.icon = marker.nonSelectedIcon;
    }
}

// Update the currently selected venue, the device location venue (which may or may
// not be the same), and whether the device venue should be given highlighted
// "you are here" treatment.  e.g. in current specs and discussion, centering the map
// view to point at your current location will cause a highlighted state for the button.
-(void)updateVenues:(NSArray *)venues withCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue spayceState:(SpayceState)spayceState {
    
    SPCHereUpdate *update = [[SPCHereUpdate alloc] initWithVenues:venues currentVenue:currentVenue deviceVenue:deviceVenue spayceState:spayceState];
    
    if (self.isUpdateOngoing) {
        self.updatePending = update;
    } else {
        [self performUpdate:update];
    }
}

-(void)donePerformingUpdate {
    self.isUpdateOngoing = NO;
    if (self.updatePending) {
        SPCHereUpdate *update = self.updatePending;
        self.updatePending = nil;
        [self performUpdate:update];
    }
}

-(void)performUpdate:(SPCHereUpdate *)update {
    self.isUpdateOngoing = YES;

    // Steps:
    // 1. determine (before changing any properties) which markers are currently displayed
    BOOL prevLocationMarkerDisplayed = self.locationMarkerShouldDisplay || self.locationMarker.map;
    BOOL prevVenueMarkersDisplayed = self.venueMarkersShouldDisplay;
    
    // 2. provide this data to our map data source.  If it reports a change,
    //      assign the venue values to our properties.
    BOOL markersChanged =  [self.mapDataSource setAsVenueStacksWithVenues:update.allVenues atCurrentVenue:update.currentVenue deviceVenue:update.deviceVenue];
    BOOL currentVenueChanged = ![SPCMapDataSource venue:_currentVenue is:update.currentVenue];
    if (markersChanged) {
        _currentVenue = self.mapDataSource.currentVenue;
        _allVenues = update.allVenues;
        
        for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
            SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
            marker.markerIndex = i;
        }
    }
    
    // 3. here's the complex part.  We need to update the venues displayed on the
    //      map, but the method of update differs based on the previous and
    //      new spayce state.  Some states display a location marker, some
    //      the venue / nearby venue markers, and some neither.  We want to
    //      smoothly animate a change between these states.
    BOOL stateChanged = _spayceState != update.spayceState;
    if (stateChanged && update.spayceState == SpayceStateLocationOff) {
        [self showNeutralRegion];
    }
    //NSLog(@"Updating spacye state from %d to %d", _spayceState, spayceState);
    BOOL starsShown = self.displayStarsView;
    _spayceState = update.spayceState;
    BOOL newLocationMarkerDisplayed = self.locationMarkerShouldDisplay;
    BOOL newVenueMarkersDisplayed = self.venueMarkersShouldDisplay;
    
    if (newVenueMarkersDisplayed) {
        currentVenueChanged = currentVenueChanged || self.manuallyLocationResetInProgress || (!prevVenueMarkersDisplayed && (self.isExplorePaused || !self.isExploreOn));
        self.manuallyLocationResetInProgress = NO;
    } else {
        currentVenueChanged = NO;
    }
    
    if (newLocationMarkerDisplayed && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        self.locationMarker.position = [LocationManager sharedInstance].currentLocation.coordinate;
    }
    
    // Determine changes.  Some types of changes get animated, some get snapped.
    BOOL animateLocationMarker, animateVenueMarkers;
    CGFloat locationAlphaSrc, locationAlphaDst, venueAlphaSrc, venueAlphaDst;
    
    // update the venue region
    if (markersChanged || stateChanged || currentVenueChanged) {
        // setup venue region...
        [self resetVenueRegionForVenues:update.allVenues spayceState:update.spayceState];
        
        // reset its visibility
        [self.mapRadiusHighlightView removeFromSuperview];
        if (self.displayVenueRegionLimitation) {
            [self.mapView insertSubview:self.mapRadiusHighlightView atIndex:1];
        }
        
        // there are 2 types of map repositionings we might do.  We
        // could center the map on the current venue, or slide the venue region
        // into frame (or neither, keeping the map unchanged).  We want to
        // center the venue if the curent venue changed, UNLESS we are in
        // explore mode and the change happened automatically (not manually).
        // Err on the side of NOT repositioning the map; perform an automatic reposition
        // when the user selects a venue manually.
        BOOL followLocation = ((self.manuallyLocationResetInProgress || self.userInterfaceHidden) && newLocationMarkerDisplayed && !prevLocationMarkerDisplayed);
        BOOL reposition = !followLocation && currentVenueChanged && (!self.isExploreOn || self.isExplorePaused);
        //NSLog(@"followLocation: %d, reposition: %d, currentVenueChanged: %d, markersChanged: %d", followLocation, reposition, currentVenueChanged, markersChanged);
        if (followLocation) {
            [self showLatitude:self.locationMarker.position.latitude longitude:self.locationMarker.position.longitude];
        } 
        
        if (self.limitToVenueRegion) {
            if (!reposition || !_currentVenue) {
                [self showLimitedRegionIfOutside];
            }
            [self.mapView setMinZoom:MIN_ZOOM_EXPLORE_OFF maxZoom:1000000];
        } else {
            [self.mapView setMinZoom:0 maxZoom:1000000];
        }
    }
    
    if (starsShown != self.displayStarsView) {
        [self updateStarsViewAlpha:YES];
    }
    
    // Location marker fades OUT, but does not fade IN.
    animateLocationMarker = prevLocationMarkerDisplayed && !newLocationMarkerDisplayed;
    locationAlphaSrc = prevLocationMarkerDisplayed ? 1 : 0;
    locationAlphaDst = newLocationMarkerDisplayed ? 1 : 0;
    
    // Venue markers fade IN, but not OUT.
    animateVenueMarkers = !prevVenueMarkersDisplayed && newVenueMarkersDisplayed;
    venueAlphaSrc = prevVenueMarkersDisplayed ? 1 : 0;
    venueAlphaDst = newVenueMarkersDisplayed ? 1 : 0;
    
    // Perfom snap changes
    if (!animateLocationMarker) {
        if (locationAlphaDst > 0) {
            self.locationMarker.map = self.mapView;
            self.locationMarker.opacity = locationAlphaDst;
            self.locationMarker.layer.opacity = locationAlphaDst;
        } else {
            self.locationMarker = nil;
        }
    }
    
    if (!animateVenueMarkers) {
        if (markersChanged) {
            // snap transition
            [self.allMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                SPCMarker *marker = obj;
                marker.opacity = 0;
                marker.layer.opacity = 0;
                marker.map = nil;
            }];
            self.allMarkers = self.mapDataSource.stackedVenueMarkers;
            [self.allMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                SPCMarker *marker = obj;
                marker.opacity = venueAlphaDst;
                marker.layer.opacity = venueAlphaDst;
                marker.map = self.mapView;
            }];
        }
        else {
            if (venueAlphaDst > 0) {
                self.allMarkers = self.mapDataSource.stackedVenueMarkers;
                [self.allMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    SPCMarker *marker = obj;
                    marker.opacity = venueAlphaDst;
                    marker.layer.opacity = venueAlphaDst;
                    marker.map = self.mapView;
                }];
            }
            else {
                [self.allMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    SPCMarker *marker = obj;
                    marker.opacity = 0;
                    marker.layer.opacity = 0;
                    marker.map = nil;
                }];
                self.allMarkers = self.mapDataSource.stackedVenueMarkers;
            }
        }
    }
    
    if (!animateVenueMarkers && !animateLocationMarker) {
        // done with the update
        [self performSelector:@selector(donePerformingUpdate) withObject:nil];
    } else {
        __weak typeof(self) weakSelf = self;
        // animate location transition?
        if (animateLocationMarker) {
            GMSMarkerLayer *layer = self.locationMarker.layer;
            CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fade.fromValue = @(locationAlphaSrc);
            fade.toValue = @(locationAlphaDst);
            fade.duration = USER_LOCATION_FADE_DURATION;
            fade.fillMode = kCAFillModeForwards;
            //fade.removedOnCompletion = NO;
            fade.delegate = [[SPCAnimationDelegate alloc] initWithStartCallback:^(CAAnimation *anim) {
                __strong typeof (weakSelf) strongSelf = weakSelf;
                if (!strongSelf.locationMarker.map) {
                    strongSelf.locationMarker.map = strongSelf.mapView;
                }
                strongSelf.locationMarker.opacity = locationAlphaDst;
                strongSelf.locationMarker.layer.opacity = locationAlphaDst;
            } stopCallback:^(CAAnimation *anim, BOOL finished) {
                __strong typeof (weakSelf) strongSelf = weakSelf;
                if (!strongSelf.locationMarkerShouldDisplay) {
                    strongSelf.locationMarker = nil;
                }
            }];
            self.locationMarker.opacity = locationAlphaSrc;
            self.locationMarker.layer.opacity = locationAlphaSrc;
            [layer addAnimation:fade forKey:[NSString stringWithFormat:@"locationFade"]];
        }
        
        // animate venue transition?
        if (animateVenueMarkers) {
            if (prevVenueMarkersDisplayed) {
                [self.allMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    SPCMarker * marker = obj;
                    GMSMarkerLayer *layer = marker.layer;
                    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fade.fromValue = @(venueAlphaSrc);
                    fade.toValue = @0.0;
                    fade.duration = USER_LOCATION_FADE_DURATION;
                    fade.fillMode = kCAFillModeForwards;
                    fade.delegate = [[SPCAnimationDelegate alloc] initWithStartCallback:^(CAAnimation *anim) {
                        if (!marker.map) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            marker.map = strongSelf.mapView;
                        }
                    } stopCallback:^(CAAnimation *anim, BOOL finished) {
                        if (markersChanged) {
                            marker.map = nil;
                        }
                    }];
                    //fade.removedOnCompletion = NO;
                    if (!marker.map) {
                        marker.opacity = venueAlphaDst;
                    }
                    [layer addAnimation:fade forKey:[NSString stringWithFormat:@"fade_%@", @(idx)]];
                }];
            }
            
            if (markersChanged) {
                self.allMarkers = self.mapDataSource.stackedVenueMarkers;
            }
            
            if (newVenueMarkersDisplayed) {
                [self.allMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    SPCMarker * marker = obj;
                    GMSMarkerLayer *layer = marker.layer;
                    CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fade.fromValue = @0.0;
                    fade.toValue = @(venueAlphaDst);
                    fade.duration = USER_LOCATION_FADE_DURATION;
                    fade.fillMode = kCAFillModeForwards;
                    fade.delegate = [[SPCAnimationDelegate alloc] initWithStartCallback:^(CAAnimation *anim) {
                        if (!marker.map) {
                            __strong typeof(weakSelf) strongSelf = weakSelf;
                            marker.map = strongSelf.mapView;
                        }
                        marker.opacity = venueAlphaDst;
                        marker.layer.opacity = venueAlphaDst;
                    } stopCallback:^(CAAnimation *anim, BOOL finished) {
                        
                    }];
                    fade.removedOnCompletion = YES;
                    if (!marker.map) {
                        marker.opacity = venueAlphaDst;
                    }
                    [layer addAnimation:fade forKey:[NSString stringWithFormat:@"fade_%@", @(idx)]];
                }];
            }
        }
        
        [self performSelector:@selector(donePerformingUpdate) withObject:nil afterDelay:USER_LOCATION_FADE_DURATION];
    }
}


- (void)resetVenueRegionForVenues:(NSArray *)venues spayceState:(SpayceState)spayceState {
    if (spayceState == SpayceStateLocationOff || spayceState == SpayceStateSeekingLocationFix) {
        self.venueRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake(0, 0), MKCoordinateSpanMake(0, 0));
    } else {
        CGFloat radius = MINIMUM_VENUE_RADIUS;
        CLLocation *center;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            center = _currentVenue ? _currentVenue.location : [LocationManager sharedInstance].currentLocation;
        }
        if (!venues || venues.count == 0) {
            // a bounding box around our device position; roughly 120 meters radius from the center,
            // or 240 to a side.
            _venueRegion = MKCoordinateRegionMakeWithDistance(center.coordinate, MINIMUM_VENUE_RADIUS*2, MINIMUM_VENUE_RADIUS*2);
        } else {
            // a bounding box around all existing venues, or ~120 meters radius from the center,
            // whichever is larger.
            MKCoordinateRegion baseRegion = MKCoordinateRegionMakeWithDistance(center.coordinate, MINIMUM_VENUE_RADIUS*2, MINIMUM_VENUE_RADIUS*2);
            for (int i = 0; i < venues.count; i++) {
                Venue * venue = venues[i];
                CGFloat distance = [center distanceFromLocation:venue.location];
                if (distance < MAXIMUM_VENUE_RADIUS) {
                    radius = MAX(radius, distance + 70);
                    MKCoordinateRegion venueRegion = MKCoordinateRegionMakeWithDistance(CLLocationCoordinate2DMake([venue.latitude floatValue], [venue.longitude floatValue]), 30, 30);
                    float latMin = fminf(baseRegion.center.latitude - baseRegion.span.latitudeDelta/2.0f, venueRegion.center.latitude - venueRegion.span.latitudeDelta/2.0f);
                    float latMax = fmaxf(baseRegion.center.latitude + baseRegion.span.latitudeDelta/2.0f, venueRegion.center.latitude + venueRegion.span.latitudeDelta/2.0f);
                    float lngMin = fminf(baseRegion.center.longitude - baseRegion.span.longitudeDelta/2.0f, venueRegion.center.longitude - venueRegion.span.longitudeDelta/2.0f);
                    float lngMax = fmaxf(baseRegion.center.longitude + baseRegion.span.longitudeDelta/2.0f, venueRegion.center.longitude + venueRegion.span.longitudeDelta/2.0f);
                    baseRegion = MKCoordinateRegionMake(CLLocationCoordinate2DMake((latMax + latMin)/2.0f, (lngMax + lngMin)/2.0f),
                                                        MKCoordinateSpanMake(latMax - latMin, lngMax - lngMin));
                    center = [[CLLocation alloc] initWithLatitude:baseRegion.center.latitude longitude:baseRegion.center.longitude];
                }
            }
            _venueRegion = baseRegion;
        }
        // adjust the highlighted area based on this region
        _mapRadiusHighlightView.location = center;
        _mapRadiusHighlightView.radius = radius;
        [_mapRadiusHighlightView updateWithMapView:_mapView];
    }
}

- (void)showUserInterfaceAnimated:(BOOL)animated {
    if (self.isExploreOn) {
        [self performSelector:@selector(refreshNearbyMemories) withObject:nil afterDelay:1.0f];
    }
    
    [_mapView setUserInteractionEnabled:YES];
    [self fadeUpAllFromFilters];
    
    self.userInterfaceHidden = NO;
    self.filterControlBar.hidden = NO;
    [self setMapLimits];
    [self updateStarsViewAlpha:animated];
    if (self.locationMarkerShouldDisplay) {
        self.locationMarker.map = self.mapView;
    } else {
        self.locationMarker = nil;
    }
    
    if (!self.mapZoomResetLocation) {
        CGPoint centerViewAt = centerViewAt = CGPointMake(CGRectGetMidX(self.mapView.frame),self.midY);
        CLLocationCoordinate2D mapCenter = [self.mapView.projection coordinateForPoint:centerViewAt];
        self.mapZoomResetLocation = [[CLLocation alloc] initWithLatitude:mapCenter.latitude longitude:mapCenter.longitude];
    }
}

- (void)hideUserInterfaceAnimated:(BOOL)animated {
    
    [self fadeUpAllFromFilters];
    self.filterControlBar.hidden = YES;
    // Dismiss showing callouts
    [_mapViewSupportDelegate selectMarker:nil withMapView:self.mapView];
    // Dismiss nearby memory callouts
    [self dismissExploreMemoryWithFadeDuration:0.0f];
    
    [_mapView setUserInteractionEnabled:YES];
    
    // center the currently selected venue...?
    if (_currentVenue) {
        
        //as needed:  snap to a reasonably close approximation of our destiation for a smoother finishing zoom, to minimize crazy color map tiles flashing, and to ensure we land on our target pin
        CGPoint centerViewAt = CGPointMake(CGRectGetMidX(self.mapView.frame),self.midY);
        CLLocationCoordinate2D currentMapCenter = [self.mapView.projection coordinateForPoint:centerViewAt];
        CLLocation *currLocation = [[CLLocation alloc] initWithLatitude:currentMapCenter.latitude longitude:currentMapCenter.longitude];
        CLLocation *destLocation = [[CLLocation alloc] initWithLatitude:self.mapZoomResetLocation.coordinate.latitude longitude:self.mapZoomResetLocation.coordinate.longitude];
        
        float distFromDestination = [destLocation distanceFromLocation:currLocation];
        if (self.mapView.camera.zoom < 14 || distFromDestination > 400) {
            NSLog(@"zoom: %f  ditance %f - reset!",self.mapView.camera.zoom,distFromDestination);
            NSLog(@"reset map to lat: %f long: %f",self.mapZoomResetLocation.coordinate.latitude,self.mapZoomResetLocation.coordinate.longitude);
            [self showLatitude:self.mapZoomResetLocation.coordinate.latitude longitude:self.mapZoomResetLocation.coordinate.longitude zoom:16 animated:NO];
            self.mapZoomResetLocation = nil;
            [self performSelector:@selector(zoomToVenue:) withObject:_currentVenue afterDelay:.1];
        }
        else {
            self.mapZoomResetLocation = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:_currentVenue];
        }
    }
    
    self.userInterfaceHidden = YES;
    [self setMapLimits];
    [self updateStarsViewAlpha:animated];
    if (self.locationMarkerShouldDisplay) {
        self.locationMarker.map = self.mapView;
    } else {
        self.locationMarker = nil;
    }
}

-(void)zoomToVenue:(Venue *)v {
    //NSLog(@"zoom to venue");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:v];
}

- (void)showNeutralRegion {
    [self.mapRadiusHighlightView removeFromSuperview];
    // Default camera to North America
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:30 longitude:-90 zoom:0 bearing:0 viewingAngle:0];
    [self.mapViewSupportDelegate repositionCalloutsForMapView:self.mapView];
    //NSLog(@"MAP CHANGE: show neutral region");
}

- (void)jumpToLatitude:(double)gpsLat longitude:(double)gpsLong {
    [self showLatitude:gpsLat longitude:gpsLong animated:NO];
}

-(void)showLatitude:(CGFloat)latitude longitude:(CGFloat)longitude {
    [self showLatitude:latitude longitude:longitude zoom:18.0 animated:NO];
}

-(void)showLatitude:(CGFloat)latitude longitude:(CGFloat)longitude animated:(BOOL)animated {
    [self showLatitude:latitude longitude:longitude zoom:18.0 animated:animated];
}


-(void)showLatitude:(CGFloat)latitude longitude:(CGFloat)longitude zoom:(CGFloat)zoom animated:(BOOL)animated {
    CGFloat angle = 0.0f; // self.inForeground ? 0.f : 15.f;

    //NSLog(@"showLat %f Long %f zoom: %f",latitude,longitude, zoom);
    
    GMSCameraPosition *camera;
    camera = [GMSCameraPosition cameraWithLatitude:latitude
                                                longitude:longitude
                                                     zoom:zoom
                                                  bearing:0
                                             viewingAngle:angle];

    if (!self.mapView.camera) {
        self.mapView.camera = camera;
    }
    
    // -- HACK --- using a hiddenMapView so that we can set the camera and get the projection point (for the view offset) before animating the map
    self.hiddenMapView.camera = camera;
    // -- END HACK
    
    self.midY = self.view.bounds.size.height/2;
    
    CGPoint centerViewAt = CGPointMake(CGRectGetMidX(self.mapView.frame),self.midY);
    CLLocationCoordinate2D mapCenter = [self.hiddenMapView.projection coordinateForPoint:centerViewAt];
  
    //NSLog(@"mapCenter Lat %f mapCenter Long %f",mapCenter.latitude,mapCenter.longitude);
    if (!animated) {
        [self.mapView moveCamera:[GMSCameraUpdate setTarget:mapCenter]];
    } else {
       [self.mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:mapCenter zoom:zoom]];
    }
    
    
    [self.mapRadiusHighlightView updateWithMapView:self.mapView];
    [self.mapRadiusHighlightView performSelector:@selector(updateWithMapView:) withObject:self.mapView afterDelay:0.1f];
    [self.mapViewSupportDelegate repositionCalloutsForMapView:self.mapView];
    
    [self.mapView performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:1.0f];
}

-(void)testLatitude:(CGFloat)latitude longitude:(CGFloat)longitude zoom:(CGFloat)zoom {
    CGFloat angle = 0.0f; // self.inForeground ? 0.f : 15.f;
    
    GMSCameraPosition *camera;
    camera = [GMSCameraPosition cameraWithLatitude:latitude
                                         longitude:longitude
                                              zoom:zoom
                                           bearing:0
                                      viewingAngle:angle];
    
    
    // -- HACK --- using hiddenMapView so we can test a map projection for explore mems w/o animating the visible map
    self.hiddenMapView.camera = camera;
    // -- END HACK
    
    self.midY = self.view.bounds.size.height/2;
    CGPoint centerViewAt = centerViewAt = CGPointMake(CGRectGetMidX(self.mapView.frame),self.midY);
    CLLocationCoordinate2D mapCenter = [self.hiddenMapView.projection coordinateForPoint:centerViewAt];
    [self.hiddenMapView moveCamera:[GMSCameraUpdate setTarget:mapCenter]];

}

-(void)showLimitedRegionIfOutside {
    // bounce back to the visible area: if necessary
    CGRect visibleBounds = [self visibleRectInMapView];
    CGPoint center = CGPointMake(CGRectGetMidX(visibleBounds), CGRectGetMidY(visibleBounds));
    CLLocationCoordinate2D coordinate = [self.mapView.projection coordinateForPoint:center];
    
    if (![self mapView:self.mapView withVisibleRect:visibleBounds isDisplayingCoordinateRegion:self.venueRegion]) {
        // the map will be re-enabled when it becomes idle
        [self.mapView setUserInteractionEnabled:NO];
        [self.mapView animateToLocation:[self projectLocation:coordinate intoCoordinateRegion:self.venueRegion]];
    }
}

#pragma mark - Explore Mode

- (void)refreshNearbyMemories {
    if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
        [[SPCRegionMemoriesManager sharedInstance] cacheMemoriesForRegionWithProjection:self.mapView.projection mapViewBounds:[self visibleRectInMapView] completionHandler:^(NSInteger memoriesCached) {
            [self cycleDisplayedExploreMemory];
        } errorHandler:^(NSError *error) {
            // meh, I'm sure we'll try again later.
            NSLog("Fault caching memories in this region %@", error);
        }];
    }
}

- (void)exploreRefreshTimerDidTrigger {
    // only refresh if we can put the data to use; otherwise it's
    // a waste of time and data.
    if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
        [self refreshNearbyMemories];
        //NSLog(@"Refreshing nearby memories!");
    } else {
        //NSLog(@"NOT refreshing nearby memories, with view did appear %d, in foreground %d, exploreOn %d", self.didViewAppear, self.inForeground, self.exploreOn);
    }
}

- (void)exploreDisplayTimerDidTrigger {
    if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
        [self cycleDisplayedExploreMemory];
        
        //NSLog(@"Updating explore displays!");
    } else {
        //NSLog(@"NOT Updating explore displays, with view did appear %d, in foreground %d, exploreOn %d", self.didViewAppear, self.inForeground, self.exploreOn);
    }
}

- (void)cycleDisplayedExploreMemory {
    if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
        //NSLog(@"cycleDisplayedExploreMemory");
        if (self.exploreMemoryIsDisplayed || self.exploreMemoryIsLoading) {
            //NSLog(@"displayed!");
            if ([self exploreMemoryLoadingFor] >= EXPLORE_LOAD_MEMORY_FOR) {
                //NSLog(@"dismissing (never fully loaded)");
                [self dismissExploreMemoryWithFadeDuration:0.0f];
            } else if ([self exploreMemoryDisplayedFor] >= EXPLORE_DISPLAY_MEMORY_FOR) {
                //NSLog(@"recording as displayed and dismissing");
                [self recordExploreMemoryAsExploredFor:(HIDE_MEMORY_AFTER_DISPLAY_DURATION)]; // don't show for an hour
                [self dismissExploreMemoryWithFadeDuration:EXPLORE_FADE_OUT_DURATION];
            }
        } else {
            //NSLog(@"not displayed!");
            if ([self exploreMemoryNotDisplayedFor] >= EXPLORE_TIME_BETWEEN_MEMORIES) {
                //NSLog(@"displaying the next memory...");
                [self displayNextExploreMemory];
            }
        }
    }
}

- (CGRect) visibleRectInMapView {
    return CGRectInset(CGRectMake(self.visibleRectInsets.left,
                                  self.visibleRectInsets.top,
                                  CGRectGetWidth(self.view.frame) - self.visibleRectInsets.left - self.visibleRectInsets.right,
                                  CGRectGetHeight(self.mapView.frame) - self.visibleRectInsets.top - self.visibleRectInsets.bottom),
                       10, 10);
}


- (Venue *)bestVenueForMemory:(Memory *)memory {
    NSInteger locationID = memory.venue.locationId;
    __block Venue * venue = nil;
    if (locationID != 0) {
        [self.allVenues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Venue * v = (Venue *)obj;
            if (v.locationId == locationID) {
                venue = v;
                *stop = YES;
            }
        }];
    }
    if (!venue) {
        venue = memory.venue;
    }
    return venue;
}

- (NSTimeInterval) exploreMemoryLoadingFor {
    if (self.exploreMemoryIsLoading) {
        return [[NSDate date] timeIntervalSince1970] - self.exploreMemoryLoadingAt;
    }
    return 0;
}

- (NSTimeInterval) exploreMemoryDisplayedFor {
    if (self.exploreMemoryIsDisplayed) {
        return [[NSDate date] timeIntervalSince1970] - self.exploreMemoryDisplayedAt;
    }
    return 0;
}

- (NSTimeInterval) exploreMemoryNotDisplayedFor {
    if (!self.exploreMemoryIsLoading && !self.exploreMemoryIsDisplayed) {
        return [[NSDate date] timeIntervalSince1970] - self.exploreMemoryDismissedAt;
    }
    return 0;
}

- (void) dismissExploreMemoryWithFadeDuration:(NSTimeInterval)fadeDuration {
    if (fadeDuration <= 0) {
        self.exploreMemoryMarker.map = nil;
        self.exploreMemoryMarker = nil;
        [self.mapViewSupportDelegate dismissFakeCalloutWindow];
        self.exploreMemoryDismissedAt = [[NSDate date] timeIntervalSince1970];
        self.exploreMemoryIsDisplayed = NO;
        self.exploreMemoryIsLoading = NO;
        if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
            [self performSelector:@selector(cycleDisplayedExploreMemory) withObject:nil afterDelay:EXPLORE_TIME_BETWEEN_MEMORIES+0.2f];
        }
    } else {
        SPCMarker * marker = self.exploreMemoryMarker;
        GMSMarkerLayer *layer = marker.layer;
        self.exploreMemoryIsFading = YES;
        CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOut.fromValue = @1.0;
        fadeOut.toValue = @0.0;
        fadeOut.duration = fadeDuration;
        fadeOut.fillMode = kCAFillModeForwards;
        fadeOut.removedOnCompletion = YES;
        fadeOut.delegate = [[SPCAnimationDelegate alloc] initWithStopCallback:^(CAAnimation *anim, BOOL finished) {
            if (marker == self.exploreMemoryMarker && !self.exploreMemoryIsFading && self.exploreMemoryIsDisplayed) {
                // restore?
                marker.opacity = 1.0f;
            } else {
                marker.map = nil;
                if (marker == self.exploreMemoryMarker) {
                    self.exploreMemoryMarker = nil;
                    [self.mapViewSupportDelegate dismissFakeCalloutWindow];
                    self.exploreMemoryDismissedAt = [[NSDate date] timeIntervalSince1970];
                    self.exploreMemoryIsDisplayed = NO;
                    self.exploreMemoryIsLoading = NO;
                    if (self.didViewAppear && !self.isExplorePaused && self.isExploreOn) {
                        [self performSelector:@selector(cycleDisplayedExploreMemory) withObject:nil afterDelay:EXPLORE_TIME_BETWEEN_MEMORIES+0.2f];
                    }
                }
            }
        }];
        [layer addAnimation:fadeOut forKey:@"fadeOut"];
    }
}

- (void) recordExploreMemoryAsExploredFor:(NSTimeInterval)duration {
    if (self.exploreMemory) {
        [[SPCRegionMemoriesManager sharedInstance] setHasExploredMemory:self.exploreMemory explored:YES withDuration:duration];
    }
}

- (void) displayNextExploreMemory {
    [self displayNextExploreMemoryIgnoringRateLimit:NO];
}

- (void) displayNextExploreMemoryIgnoringRateLimit:(BOOL)ignoreRateLimit {
    if (self.exploreMemoryRemoteFetchBeganAt + EXPLORE_GET_MEMORY_REMOTELY_TIMEOUT > [[NSDate date] timeIntervalSince1970]) {
        // nope, a remote fetch is ongoing.
        return;
    }
    
    if (!self.isExploreOn) {
        // nope, don't care
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [[SPCRegionMemoriesManager sharedInstance] fetchUnexploredMemoryForRegionWithProjection:self.mapView.projection mapViewBounds:[self visibleRectInMapView] ignoreRateLimit:ignoreRateLimit displayedWithMemories:nil withWillFetchRemotelyHandler:^(BOOL *cancel) {
        // store that there is a background fetch happening; don't allow another
        // fetch until we get a callback (or a timeout).
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.exploreMemoryRemoteFetchBeganAt = [[NSDate date] timeIntervalSince1970];
    } completionHandler:^(Memory *memory) {
        // note that we got a callback.
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.exploreMemoryRemoteFetchBeganAt = 0;
        if (memory && strongSelf.didViewAppear && !strongSelf.isExplorePaused && strongSelf.isExploreOn && !strongSelf.exploreMemoryIsDisplayed) {
            // display the memory.
            [strongSelf displayExploreMemory:memory withVenue:[strongSelf bestVenueForMemory:memory]];
        }
    } errorHandler:^(NSError *error) {
        // note that we got a callback.
        NSLog(@"Error in fetching unexplored memory for region %@", error);
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.exploreMemoryRemoteFetchBeganAt = 0;
    }];
}

- (void) displayAnyExploreMemoryFromSuggestedVenue:(Venue *)suggestedVenue {
    
    if (!self.mapSearchResetLocation) {
        CGPoint centerViewAt = centerViewAt = CGPointMake(CGRectGetMidX(self.mapView.frame),self.midY);
        CLLocationCoordinate2D mapCenter = [self.mapView.projection coordinateForPoint:centerViewAt];
        self.mapSearchResetLocation = [[CLLocation alloc] initWithLatitude:mapCenter.latitude longitude:mapCenter.longitude];
        //NSLog(@"mapSearchResetLocation - lat: %f long: %f",self.mapSearchResetLocation.coordinate.latitude, self.mapSearchResetLocation.coordinate.longitude);
    }
    
    //NSLog(@"show mem from suggested venue: %@ lat: %@ long: %@",suggestedVenue.displayNameTitle, suggestedVenue.latitude, suggestedVenue.longitude);
    
    //begin by showing a mem from the venue that was suggested
    Memory *memory;
    for (int i = 0; i < suggestedVenue.popularMemories.count; i++) {
        if ([suggestedVenue.popularMemories[i] isKindOfClass:[ImageMemory class]] && ((ImageMemory *)suggestedVenue.popularMemories[i]).images.count > 0) {
            memory = ((ImageMemory *)suggestedVenue.popularMemories[i]);
            //NSLog(@"got a mem from our venue!");
            break;
        }
    }
    
    if (memory && suggestedVenue) {
        //NSLog(@"trying to display a mem ASAPish");
        [self displayExploreMemory:memory withVenue:suggestedVenue];
    } else {
        //NSLog(@"wtf?!?!?");
    }
    
    //continue on and refresh our cache for this new region as needed
    
    if (self.exploreMemoryRemoteFetchBeganAt + EXPLORE_GET_MEMORY_REMOTELY_TIMEOUT > [[NSDate date] timeIntervalSince1970]) {
        // nope, a remote fetch is ongoing.
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [[SPCRegionMemoriesManager sharedInstance] fetchAnyMemoryForRegionWithProjection:self.mapView.projection mapViewBounds:[self visibleRectInMapView] ignoreRateLimit:YES displayedWithMemories:nil withWillFetchRemotelyHandler:^(BOOL *cancel) {
        // store that there is a background fetch happening; don't allow another
        // fetch until we get a callback (or a timeout).
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.exploreMemoryRemoteFetchBeganAt = [[NSDate date] timeIntervalSince1970];
    } completionHandler:^(Memory *memory) {
        // note that we got a callback.
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.exploreMemoryRemoteFetchBeganAt = 0;
        if (memory && strongSelf.didViewAppear && !strongSelf.isExplorePaused && strongSelf.isExploreOn && !strongSelf.exploreMemoryIsDisplayed) {
            // display the memory.
            [strongSelf displayExploreMemory:memory withVenue:[strongSelf bestVenueForMemory:memory]];
        }
    } errorHandler:^(NSError *error) {
        // note that we got a callback.
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.exploreMemoryRemoteFetchBeganAt = 0;
    }];
}

- (void) displayExploreMemoryFromSearch {
    //NSLog(@"hunt for a mem from search to display");
    self.isExplorePaused = NO;
    
    if (self.exploreMemoryRemoteFetchBeganAt + EXPLORE_GET_MEMORY_REMOTELY_TIMEOUT > [[NSDate date] timeIntervalSince1970]) {
        // nope, a remote fetch is ongoing.
        //NSLog(@"canceling explore mem search as a remote fetch is ongoing.");
        [self.delegate searchIsCompleteWithResults:NO];
        return;
    }
    __weak typeof(self) weakSelf = self;

    [[SPCRegionMemoriesManager sharedInstance] fetchAnyMemoryForRegionWithProjection:self.hiddenMapView.projection
                                                                       mapViewBounds:[self visibleRectInMapView] ignoreRateLimit:YES displayedWithMemories:nil
                                                        withWillFetchRemotelyHandler:^(BOOL *cancel) {
      
                                                            // store that there is a background fetch happening; don't allow another
                                                            // fetch until we get a callback (or a timeout).
                                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                                            strongSelf.exploreMemoryRemoteFetchBeganAt = [[NSDate date] timeIntervalSince1970];
                                                        }
     
                                                       completionHandler:^(Memory *memory) {
                                                            // note that we got a callback.
                                                            //NSLog(@"got a callback?");
                                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                                            strongSelf.exploreMemoryRemoteFetchBeganAt = 0;
                                                            if (memory && strongSelf.didViewAppear) {
                                                                // display the memory.
                                                                NSLog(@"got a mem!");
                                                                [strongSelf displayExploreMemory:memory withVenue:[strongSelf bestVenueForMemory:memory]];
                                                                Venue *anchorVenue = [strongSelf bestVenueForMemory:memory];
                                                                [strongSelf showLatitude:anchorVenue.latitude.floatValue longitude:anchorVenue.longitude.floatValue zoom:12 animated:NO];
                                                                
                                                                //end the search after a slight delay to allow the map to update first
                                                                [strongSelf performSelector:@selector(endSearchOnDelay) withObject:nil afterDelay:.5];
                                                            }
                                                            else {
                                                                NSLog(@"nope, no mem here, reset map");
                                                                [strongSelf.delegate searchIsCompleteWithResults:NO];
                                                                [strongSelf showLatitude:strongSelf.mapSearchResetLocation.coordinate.latitude longitude:strongSelf.mapSearchResetLocation.coordinate.longitude animated:NO];
                                                            }
                                                        }
     
                                                        errorHandler:^(NSError *error) {
                                                            // note that we got a callback.
                                                            //NSLog(@"Error in fetching unexplored memory for region %@", error);
                                                            __strong typeof(weakSelf) strongSelf = weakSelf;
                                                            [strongSelf showLatitude:strongSelf.mapSearchResetLocation.coordinate.latitude longitude:strongSelf.mapSearchResetLocation.coordinate.longitude animated:NO];
                                                            [strongSelf.delegate searchIsCompleteWithResults:NO];
                                                            strongSelf.exploreMemoryRemoteFetchBeganAt = 0;
                                                        }];
}


- (void) displayExploreMemory:(Memory *)memory withVenue:(Venue *)venue {
    if (self.exploreMemoryMarker) {
        self.exploreMemoryMarker.map = nil;
        self.exploreMemoryMarker = nil;
    }
    self.exploreMemoryIsLoading = YES;
    self.exploreMemoryLoadingAt = [[NSDate date] timeIntervalSince1970];
    self.exploreMemory = memory;
    self.exploreMemoryMarker = [SPCMarkerVenueData markerWithRealtimeMemory:memory venue:venue iconReadyHandler:^(SPCMarker *marker) {
        // display if appropriate...
        BOOL correctMarker = self.exploreMemory == memory && (!self.exploreMemoryMarker || self.exploreMemoryMarker == marker);
        BOOL display = self.didViewAppear && !self.isExplorePaused && self.isExploreOn;
        if (correctMarker && display) {
            // display!
      
            marker.zIndex = self.maxZ;
            self.maxZ = self.maxZ+1;
            self.exploreMemoryMarker = marker;
            [self performSelector:@selector(cycleDisplayedExploreMemory) withObject:nil afterDelay:EXPLORE_DISPLAY_MEMORY_FOR+0.2f];
            
            self.exploreMemoryMarker.map = self.mapView;
            [self.mapViewSupportDelegate showInvisibleCalloutCoveringMarker:self.exploreMemoryMarker inMapView:self.mapView];
            self.exploreMemoryDisplayedAt = [[NSDate date] timeIntervalSince1970];
            self.exploreMemoryIsDisplayed = YES;
            self.exploreMemoryIsLoading = NO;
        }
    }];
}

-(void) didTapExploreMemory:(id)sender {
    //NSLog(@"didTapExploreMemory");
    
    self.isViewingMemFromExplore = YES;
    
    // tapped!  Don't show again for a long time.
    [self recordExploreMemoryAsExploredFor:(HIDE_MEMORY_AFTER_TAP_DURATION)]; // don't show for 48 hours
    
    // make sure the marker will linger on the screen at least 1 second upon return
    [self.exploreMemoryMarker.layer removeAllAnimations];
    self.exploreMemoryMarker.opacity = 1.0f;
    self.exploreMemoryMarker.layer.opacity = 1.0f;
    self.exploreMemoryIsFading = NO;
    self.exploreMemoryDisplayedAt = MAX(self.exploreMemoryDisplayedAt,
                                        [[NSDate date] timeIntervalSince1970] - EXPLORE_DISPLAY_MEMORY_FOR + 1.0);
    // for some reason, just setting the opacity doesn't seem to work, but animating it does.
    // Animate a fade in.
    [self.exploreMemoryMarker.layer addAnimation:[self animationToFullOpacityQuickly:self.exploreMemoryMarker] forKey:@"fadeInExit"];
    
    // open venue detail screen
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = self.exploreMemory.venue;
    [venueDetailViewController jumpToMem:self.exploreMemory];
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;

    [self.tabBarController presentViewController:navController animated:YES completion:nil];

}

-(CABasicAnimation *) animationToFullOpacityQuickly:(SPCMarker *)marker {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(marker.opacity);
    animation.toValue = @1.0;
    animation.duration = 0.01;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = YES;
    return animation;
}

-(CABasicAnimation *) animationToZeroOpacityQuickly:(SPCMarker *)marker {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(marker.opacity);
    animation.toValue = @0.0;
    animation.duration = 0.01;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = YES;
    return animation;
}

-(void)endSearchOnDelay {
    [self.delegate searchIsCompleteWithResults:YES];
}

-(void)resetMapAfterTeleport {
    if (self.mapSearchResetLocation) {
        //NSLog(@"reset map after teleport");
        [self showLatitude:self.mapSearchResetLocation.coordinate.latitude longitude:self.mapSearchResetLocation.coordinate.longitude zoom:15 animated:YES];
        self.mapSearchResetLocation = nil;
    }
    else {
        self.isViewingMemFromExplore = NO;
    }
}

-(BOOL)isMapResetNeeded {
    BOOL needed = NO;
    if (self.mapSearchResetLocation)  {
        needed = YES;
    }
    return needed;
}


#pragma mark - Pin Filters

-(void)updateZoomLevelForLatitude:(double)latitude longitude:(double)longitude  {
    //NSLog(@"self.currPinIndex %i",self.currPinIndex);
    
    //get the lat/long for our current anchor pin
    CLLocation *baseLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    NSLog(@"--------  anchor venue %@",self.currentVenue.displayNameTitle);
    
    //update the distance from anchor pin for all other pins
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:marker.position.latitude longitude:marker.position.longitude];
        marker.distanceFromBasePin = [baseLocation distanceFromLocation:testLocation];
        
    }
    
    //sort by distance
    NSMutableArray *sortedArray = [NSMutableArray arrayWithArray:self.mapDataSource.stackedVenueMarkers];
    NSSortDescriptor *distanceSorter = [[NSSortDescriptor alloc] initWithKey:@"distanceFromBasePin" ascending:YES];
    [sortedArray sortUsingDescriptors:@[distanceSorter]];
    
    for (int i = 0; i < sortedArray.count; i++) {
        SPCMarker *marker = (SPCMarker *)sortedArray[i];
        
        if (i < 20) {
            
            //use the distanceFromBasePin for the furthest pin as a rough proxy for cluster density..
            if (i == 19) {
                
                if (marker.distanceFromBasePin < 40) {
                    self.currZoom = 19;
                }
                if (marker.distanceFromBasePin < 65) {
                    self.currZoom = 18.5;
                }
                else if (marker.distanceFromBasePin < 100) {
                    self.currZoom = 18;
                }
                else {
                    self.currZoom = 17.5;
                }
            }
            
        }
    }
    
    //NSLog(@"dynamic zoom of %f",self.currZoom);
    
    if (self.currPinIndex == 2) {
        self.popularZoom = self.currZoom;
        //NSLog(@"popular zoom set to %f",self.popularZoom);
    }
    

    if (self.currPinIndex < self.adaptiveZoomCutOffIndex) {
        if (self.popularZoom > 0) {
            self.currZoom = self.popularZoom;
        }
        //NSLog(@"hold on popular zoom of %f",self.currZoom);
    }
}

-(void)updateVisiblePinsForLatitude:(double)latitude longitude:(double)longitude {
    
    //get the lat/long for our current anchor pin
    CLLocation *baseLocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    NSLog(@"--------  anchor venue %@",self.currentVenue.displayNameTitle);
    
    //update the distance from anchor pin for all other pins
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:marker.position.latitude longitude:marker.position.longitude];
        marker.distanceFromBasePin = [baseLocation distanceFromLocation:testLocation];
        
    }
    
    //Goal:
    // 1.  For favorited/popular venues, we show the other fav/pop venues and then the closest pins until 20 are displayed
    // 2.  For nearby venues, we show the 20 closest pins
    
    
    //get the fav/pop venues if neeed
    
    NSMutableArray *popularVenues = [[NSMutableArray alloc] init];
    NSMutableArray *remainingVenues = [NSMutableArray arrayWithArray:self.mapDataSource.stackedVenueMarkers];
    
   NSLog(@"self.adaptiveZoomCutOffIndex %i",self.adaptiveZoomCutOffIndex);
   
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        if (i < self.adaptiveZoomCutOffIndex) {
            SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
            [popularVenues addObject:marker];
            NSLog(@"popular venue marker: %@",((SPCMarkerVenueData *)marker.userData).venue.displayNameTitle);
  
            //handle de-duplication for when we sort remaining pins by distance
            for (int i = 0; i < remainingVenues.count; i++) {
                SPCMarker *remainingMarker = remainingVenues[i];
                if (remainingMarker.markerIndex == marker.markerIndex) {
                    [remainingVenues removeObjectAtIndex:i];
                    break;
                }
            }
        } else {
            break;
        }
    }
    
    NSLog(@"popularVenues count %li",popularVenues.count);
    
    //sort all remaining markers by distance from base pin
    NSSortDescriptor *distanceSorter = [[NSSortDescriptor alloc] initWithKey:@"distanceFromBasePin" ascending:YES];
    [remainingVenues sortUsingDescriptors:@[distanceSorter]];
   
    //create a combo array of markers for our popular venues and our remaining nearby venues
    NSMutableArray *comboArray = [[NSMutableArray alloc] initWithArray:popularVenues];
    for (int i = 0; i < remainingVenues.count; i++) {
        [comboArray addObject:remainingVenues[i]];
    }
  
    NSLog(@"marker comboArray count %li",comboArray.count);
    
    //fade appropriately
    for (int i = 0; i < comboArray.count; i++) {
        SPCMarker *marker = (SPCMarker *)comboArray[i];
        
        if (i < 20) {
            NSLog(@"marker name %@ distance %f",marker.title,marker.distanceFromBasePin);
            
            BOOL isWithinVisibleRange = YES;
            
            CGPoint markerCenter =  [self.hiddenMapView.projection pointForCoordinate:marker.position];  //use the hidden map view because the visible map view is still animating and it messes this up
            
            if (markerCenter.y > self.view.bounds.size.height * .9) {
                isWithinVisibleRange = NO;
            }
            
            if (isWithinVisibleRange) {
                
                //fade up as needed
                if (marker.isFadedForFeature){
                    //NSLog(@"fade up");
                    marker.isFadedForFeature = NO;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeIn.fromValue = @0.2;
                    fadeIn.toValue = @01.0;
                    fadeIn.duration = .01;
                    fadeIn.fillMode = kCAFillModeForwards;
                    fadeIn.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeIn forKey:nil];
                    marker.tappable = YES;
                }
                
                if (marker.isFadedForFilters){
                    //NSLog(@"fade up");
                    marker.isFadedForFilters = NO;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeIn.fromValue = @0.0;
                    fadeIn.toValue = @01.0;
                    fadeIn.duration = .01;
                    fadeIn.fillMode = kCAFillModeForwards;
                    fadeIn.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeIn forKey:nil];
                    marker.tappable = YES;
                }
            }
            else {
                NSLog(@"outside of visbible range exclude - marker name %@ distance %f",marker.title,marker.distanceFromBasePin);
                if (marker.isFadedForFeature) {
                    marker.isFadedForFeature = NO;
                    marker.isFadedForFilters = YES;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeOut.fromValue = @0.2;
                    fadeOut.toValue = @0.0;
                    fadeOut.duration = .1;
                    fadeOut.fillMode = kCAFillModeForwards;
                    fadeOut.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeOut forKey:nil];
                    marker.tappable = NO;
                }
                
                
                if (!marker.isFadedForFilters) {
                    //NSLog(@"fade down");
                    marker.isFadedForFilters = YES;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeOut.fromValue = @1.0;
                    fadeOut.toValue = @0.0;
                    fadeOut.duration = .1;
                    fadeOut.fillMode = kCAFillModeForwards;
                    fadeOut.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeOut forKey:nil];
                    marker.tappable = NO;
                }
            }
        }
        else {
            NSLog(@"exclude - marker name %@ distance %f",marker.title,marker.distanceFromBasePin);
            
            //fade down alpha pins
            if (marker.isFadedForFeature) {
                marker.isFadedForFeature = NO;
                marker.isFadedForFilters = YES;
                [marker.layer removeAllAnimations];
                CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                fadeOut.fromValue = @0.2;
                fadeOut.toValue = @0.0;
                fadeOut.duration = .1;
                fadeOut.fillMode = kCAFillModeForwards;
                fadeOut.removedOnCompletion = NO;
                [marker.layer addAnimation:fadeOut forKey:nil];
                marker.tappable = NO;
            }
            
            
            if (!marker.isFadedForFilters) {
                //NSLog(@"fade down");
                marker.isFadedForFilters = YES;
                [marker.layer removeAllAnimations];
                CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                fadeOut.fromValue = @1.0;
                fadeOut.toValue = @0.0;
                fadeOut.duration = .1;
                fadeOut.fillMode = kCAFillModeForwards;
                fadeOut.removedOnCompletion = NO;
                [marker.layer addAnimation:fadeOut forKey:nil];
                marker.tappable = NO;
            }
        }
        
        
    }
}

-(void)fadeDownPinsForFeaturedMemory {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        CGPoint markerCenter =  [self.mapView.projection pointForCoordinate:marker.position];
        
        if (markerCenter.y > self.view.bounds.size.height * .6) {
          //off screen pins
        }
        else {
            //fade down visible pins as needed
            if (!marker.isFadedForFilters) {
                if (!marker.isFadedForFeature) {
                    marker.isFadedForFeature = YES;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeDown = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeDown.fromValue = @1.0;
                    fadeDown.toValue = @0.2;
                    fadeDown.duration = .01;
                    fadeDown.fillMode = kCAFillModeForwards;
                    fadeDown.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeDown forKey:nil];
                    marker.tappable = YES;
                }
            }
        }
    }
}

-(void)hidePinsOutsideOfVisibleArea {

}

-(void)filterPins:(id)sender {
    
    UIButton *btn;
    NSArray *subs = [self.filterControlBar subviews];
    
    for (btn in subs) {
        btn.selected = NO;
    }
    
    UIButton *filterBtn = (UIButton *)sender;
    filterBtn.selected = YES;
    NSInteger selectedSegment = filterBtn.tag;

    NSMutableArray *activePins = [[NSMutableArray alloc] init];
    
    if (selectedSegment == SpayceMapAllPins) {
        [self fadeUpAllFromFilters];
        [self showLatitude:self.currentVenue.latitude.floatValue longitude:self.currentVenue.longitude.floatValue zoom:16 animated:YES];
    }
    if (selectedSegment == SpayceMapNearbyPins) {
        
       for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
           SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
           if (((SPCMarkerVenueData *)marker.userData).venue.distanceAway > 50) {
               if (!marker.isFadedForFilters) {
                   marker.isFadedForFilters = YES;
                   [marker.layer removeAllAnimations];
                   CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                   fadeOut.fromValue = @1.0;
                   fadeOut.toValue = @0.0;
                   fadeOut.duration = .1;
                   fadeOut.fillMode = kCAFillModeForwards;
                   fadeOut.removedOnCompletion = NO;
                   [marker.layer addAnimation:fadeOut forKey:nil];
               }
           }
           else  {
               [activePins addObject:marker];
               [marker.layer removeAllAnimations];
               CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
               fadeIn.fromValue = @0.0;
               fadeIn.toValue = @01.0;
               fadeIn.duration = .01;
               fadeIn.fillMode = kCAFillModeForwards;
               fadeIn.removedOnCompletion = NO;
               [marker.layer addAnimation:fadeIn forKey:nil];
               marker.isFadedForFilters = NO;
           }
        }
    }
    if (selectedSegment== SpayceMapPopularPins) {
        
        for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
            SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
            if (((SPCMarkerVenueData *)marker.userData).venue.totalMemories < 1) {
                if (!marker.isFadedForFilters) {
                    marker.isFadedForFilters = YES;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeOut.fromValue = @1.0;
                    fadeOut.toValue = @0.0;
                    fadeOut.duration = .1;
                    fadeOut.fillMode = kCAFillModeForwards;
                    fadeOut.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeOut forKey:nil];
                }
            }
            else  {
                [activePins addObject:marker];
                [marker.layer removeAllAnimations];
                CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
                fadeIn.fromValue = @0.0;
                fadeIn.toValue = @01.0;
                fadeIn.duration = .01;
                fadeIn.fillMode = kCAFillModeForwards;
                fadeIn.removedOnCompletion = NO;
                [marker.layer addAnimation:fadeIn forKey:nil];
                marker.isFadedForFilters = NO;
            }
        }
    }
    if (selectedSegment == SpayceMapNightPins) {
        
        for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
            SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
            
            BOOL isNightVenue = [SPCVenueTypes isNightVenue:[SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue]];
            
            if (!isNightVenue) {
                if (!marker.isFadedForFilters) {
                    marker.isFadedForFilters = YES;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeOut.fromValue = @1.0;
                    fadeOut.toValue = @0.0;
                    fadeOut.duration = .1;
                    fadeOut.fillMode = kCAFillModeForwards;
                    fadeOut.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeOut forKey:nil];
                }
            }
            else  {
                [activePins addObject:marker];
                [marker.layer removeAllAnimations];
                CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
                fadeIn.fromValue = @0.0;
                fadeIn.toValue = @01.0;
                fadeIn.duration = .01;
                fadeIn.fillMode = kCAFillModeForwards;
                fadeIn.removedOnCompletion = NO;
                [marker.layer addAnimation:fadeIn forKey:nil];
                marker.isFadedForFilters = NO;
            }
        }
    }
    if (selectedSegment == SpayceMapDayPins) {
        
        for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
            SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
            
            BOOL isDayVenue = [SPCVenueTypes isDayVenue:[SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue]];
            
            if (!isDayVenue) {
                if (!marker.isFadedForFilters) {
                    marker.isFadedForFilters = YES;
                    [marker.layer removeAllAnimations];
                    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
                    fadeOut.fromValue = @1.0;
                    fadeOut.toValue = @0.0;
                    fadeOut.duration = .1;
                    fadeOut.fillMode = kCAFillModeForwards;
                    fadeOut.removedOnCompletion = NO;
                    [marker.layer addAnimation:fadeOut forKey:nil];
                }
            }
            else  {
                [activePins addObject:marker];
                [marker.layer removeAllAnimations];
                CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
                fadeIn.fromValue = @0.0;
                fadeIn.toValue = @01.0;
                fadeIn.duration = .01;
                fadeIn.fillMode = kCAFillModeForwards;
                fadeIn.removedOnCompletion = NO;
                [marker.layer addAnimation:fadeIn forKey:nil];
                marker.isFadedForFilters = NO;
            }
        }
    }
    

    /* -- NOTE:
    
     As the user taps the filters, we need to zoom in on the best 'cluster' of pins.  To do that, we:
        
     1. Populate an activePins array for the given filter
     2. Loop through the activePins, and for each marker, loop through all the other activePins and do a distance check
     2a. Keep track of how many pins are in the clusterRange for each pin
     3. Zoom on the marker that had the most pins within the 'cluster range'
     
    
    */
    
    CGFloat clusterRange = 40;
    NSInteger indexOfBestPinForCluster = 0;
    NSInteger mostPinsWithinRange = 0;
    
    //look for the best marker to be our cluster anchor
    for (int i = 0; i < activePins.count; i++) {
        
        SPCMarker *baseMarker = (SPCMarker *)activePins[i];
        CLLocation *baseLocation = [[CLLocation alloc] initWithLatitude:baseMarker.position.latitude longitude:baseMarker.position.longitude];
        //NSLog(@"base marker %i, baseLocation:  %f, %f",i,baseLocation.coordinate.latitude,baseLocation.coordinate.longitude);
        
        NSInteger pinsWithinRage = 0;
        
        //test all active markers to see if they are in range of our candidate marker
        
        for (int t = 0; t < activePins.count; t++) {
            SPCMarker *testClusterMarker = (SPCMarker *)activePins[t];
            CLLocation *testLocation = [[CLLocation alloc] initWithLatitude:testClusterMarker.position.latitude longitude:testClusterMarker.position.longitude];
            //NSLog(@"distance check %f",[baseLocation distanceFromLocation:testLocation]);
            if ([baseLocation distanceFromLocation:testLocation] < clusterRange) {
                pinsWithinRage = pinsWithinRage + 1;
                //NSLog(@"got one!");
            }
        }
        
        //NSLog(@"pins within range after loop %li",pinsWithinRage);
        
        //note whether this marker is better than all previous markers
        if (pinsWithinRage > mostPinsWithinRange) {
            mostPinsWithinRange = pinsWithinRage;
            indexOfBestPinForCluster = i;
        }
    }
    
    
    //Zoom in on the best marker we found
    
    if (indexOfBestPinForCluster < activePins.count) {
        //NSLog(@"indexOfBestPinForCluster %li mostPinsWithinRange %li",indexOfBestPinForCluster,mostPinsWithinRange);
        SPCMarker *clusterAnchorMarker = (SPCMarker *)activePins[indexOfBestPinForCluster];
        [self showLatitude:clusterAnchorMarker.position.latitude longitude:clusterAnchorMarker.position.longitude zoom:16 animated:YES];
    }
}

-(void)fadeUpAllFromFilters {
    
    for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
        if (marker.isFadedForFilters) {
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @1.0;
            fadeIn.duration = .1;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
            marker.tappable = YES;
        }
    }
}

-(void)fadeDownAllForFilters {

    for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
    
        if (!marker.isFadedForFilters) {
            marker.isFadedForFilters = YES;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeOut.fromValue = @1.0;
            fadeOut.toValue = @0.0;
            fadeOut.duration = .1;
            fadeOut.fillMode = kCAFillModeForwards;
            fadeOut.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeOut forKey:nil];
        }
    }
}

-(void)fadeUpCafes {

    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeCafe) || (venType == VenueTypeBakery)) {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {

            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
}

-(void)fadeUpRestaurants {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeRestaurant) || (venType == VenueTypeFood)) {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
    
}

-(void)fadeUpSports {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeStadium) || (venType == VenueTypeGym) || (venType == VenueTypePark)) {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
}

-(void)fadeUpOffices {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeFinance) || (venType == VenueTypePolice) || (venType == VenueTypePost) || (venType == VenueTypePharmacy) || (venType == VenueTypePhysio) || (venType == VenueTypeLawyer)  || (venType == VenueTypeInsurance || (venType == VenueTypeHospital) || (venType == VenueTypeEmbassy) || (venType == VenueTypeFire) || (venType == VenueTypeDentist) || (venType == VenueTypeCourthouse) || (venType == VenueTypeDoctor) || (venType == VenueTypeCityHall) || (venType == VenueTypeFurniture) || (venType == VenueTypeGrocery))  ) {
            
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
    
}

-(void)fadeUpHomes {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if (venType == VenueTypeResidential)  {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
}

-(void)fadeUpTravel {
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeAirport) || (venType == VenueTypeTrain) || (venType == VenueTypeSubway) || (venType == VenueTypeTravel) || (venType == VenueTypeBus)) {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
}

-(void)fadeUpBars {
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeBar) || (venType == VenueTypeLiquor)) {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
    
}

-(void)fadeUpSchools {
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
       if ((venType == VenueTypeSchool) || (venType == VenueTypeLibrary)) {
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
            marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
}

-(void)fadeUpFun {
    
   for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
       SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
       
       BOOL isSelectedVenue = NO;
       
       NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
       
       if ((venType == VenueTypeAmusement) || (venType == VenueTypeAquarium) || (venType == VenueTypeArt) || (venType == VenueTypeMuseum) || (venType == VenueTypeHair) || (venType == VenueTypeCasino)  || (venType == VenueTypeBowling || (venType == VenueTypeMovieTheater) )  ) {
           isSelectedVenue = YES;
       }
       
       if (isSelectedVenue) {
           
           marker.isFadedForFilters = NO;
           [marker.layer removeAllAnimations];
           CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
           fadeIn.fromValue = @0.0;
           fadeIn.toValue = @01.0;
           fadeIn.duration = .01;
           fadeIn.fillMode = kCAFillModeForwards;
           fadeIn.removedOnCompletion = NO;
           [marker.layer addAnimation:fadeIn forKey:nil];
           marker.isFadedForFilters = NO;
       }
   }
}

-(void)fadeUpStore {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = NO;
        
        NSInteger venType = [SPCVenueTypes typeForVenue:((SPCMarkerVenueData *)marker.userData).venue];
        
        if ((venType == VenueTypeStore) || (venType == VenueTypeJewelry) || (venType == VenueTypeBicycle) || (venType == VenueTypeBookstore) || (venType == VenueTypeShopping) || (venType == VenueTypeShoe)  || (venType == VenueTypeMovieRental || (venType == VenueTypeHomegoods) || (venType == VenueTypeHardware) || (venType == VenueTypeClothing) || (venType == VenueTypeDepartment) || (venType == VenueTypeConvenience) || (venType == VenueTypeElectronics) || (venType == VenueTypeFlorist) || (venType == VenueTypeFurniture) || (venType == VenueTypeGrocery))  ) {
            
            isSelectedVenue = YES;
        }
        
        if (isSelectedVenue) {
            
             marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
    
}
-(void)fadeUpFavorites {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = ((SPCMarkerVenueData *)marker.userData).venue.favorited;
        
        if (isSelectedVenue) {
             marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
    
}
-(void)fadeUpPopular {
    
    for (int i = 0; i < self.mapDataSource.stackedVenueMarkers.count; i++) {
        SPCMarker *marker = (SPCMarker *)self.mapDataSource.stackedVenueMarkers[i];
        
        BOOL isSelectedVenue = ((SPCMarkerVenueData *)marker.userData).venue.popularMemories.count > 0;
        
        if (isSelectedVenue) {
             marker.isFadedForFilters = NO;
            [marker.layer removeAllAnimations];
            CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeIn.fromValue = @0.0;
            fadeIn.toValue = @01.0;
            fadeIn.duration = .01;
            fadeIn.fillMode = kCAFillModeForwards;
            fadeIn.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeIn forKey:nil];
            marker.isFadedForFilters = NO;
        }
    }
    
}
#pragma mark - Reset Location

-(void)adjustResetBtn {
    
    SPCHereVenueViewController *hvVC = (SPCHereVenueViewController *)self.delegate;
    SPCHereViewController *hVC = (SPCHereViewController *)hvVC.delegate;
    if (hVC.feedDisplayed || hVC.feedTransitionAnimationInProgress) {
        self.midY = self.view.bounds.size.height/2;
        if (hVC.feedDisplayed || hVC.feedTransitionAnimationInProgress) {
            self.midY = 300;
            if (self.view.bounds.size.height <= 568) {
                self.midY = 280;
            }
        }
        
        self.refreshLocationButton.center = CGPointMake(self.refreshLocationButton.center.x, self.midY - 80);
        self.refreshLocationButton.hidden = NO;
        
    } else {
        self.refreshLocationButton.hidden = YES;
    }
}

-(void)refreshLocationButtonPressed {
    if (self.delegate && [self.delegate respondsToSelector:@selector(refreshLocation)]) {
        [self.delegate refreshLocation];
    }
}

@end
