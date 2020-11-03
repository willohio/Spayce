//
//  SPCCreateVenueViewController.m
//  Spayce
//
//  Created by Jake Rosin on 6/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>

// Model
#import "SPCMapDataSource.h"

// Controller
#import "SPCCreateVenuePostViewController.h"
#import "SPCCreateVenueViewController.h"

// Manager
#import "LocationManager.h"
#import "VenueManager.h"

#define DEVICE_Z 0
#define VENUE_Z 1
#define MARKER_Z 2

#define GEOCODING_DELAY 1

const CGFloat CREATE_VENUE_MAM_DISTANCE = 121.92f;     // about 400 feet

@interface SPCCreateVenueViewController () <SPCGoogleMapInfoViewSupportDelegateDelegate, SPCCreateVenuePostViewControllerDelegate, SPCMapDataSourceDelegate>

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) SPCGoogleMapInfoViewSupportDelegate *mapViewSupportDelegate;
@property (nonatomic, strong) SPCMapDataSource *mapDataSource;
@property (nonatomic, strong) SPCMarker *marker;
@property (nonatomic, strong) Venue *markerAddressVenue;
@property (nonatomic, strong) SPCGoogleMapInfoView *markerInfoWindow;
@property (nonatomic, strong) UIView *markerInfoContentView;

@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, strong) UIView *mapNavBar;

@property (nonatomic, assign) BOOL popupDidAppear;

@end

@implementation SPCCreateVenueViewController


-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (id) initWithNearbyVenues:(NSArray *)venues {
    self = [super init];
    if (self) {
        NSMutableArray *unfuzzedVenues = [NSMutableArray arrayWithCapacity:venues.count];
        for (Venue *venue in venues) {
            if (venue.specificity == SPCVenueIsReal) {
                [unfuzzedVenues addObject:venue];
            }
        }
        [self.mapDataSource setAsVenueStacksWithVenues:unfuzzedVenues atCurrentVenue:nil deviceVenue:nil];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.mapNavBar];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self showCurrentLocationRegion];
    
    [self.mapView clear];
    
    // populate venues
    [self.mapDataSource.stackedVenueMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SPCMarker *marker = (SPCMarker *)obj;
        marker.zIndex = VENUE_Z;
        marker.map = self.mapView;
        
        SPCMarkerVenueData *vData = (SPCMarkerVenueData *)marker.userData;
        if (!vData.isOriginalUserLocation && !vData.isOwnedByUser) {
            CABasicAnimation *fadeDown = [CABasicAnimation animationWithKeyPath:@"opacity"];
            fadeDown.fromValue = @1.0;
            fadeDown.toValue = @0.5;
            fadeDown.duration = .1;
            fadeDown.fillMode = kCAFillModeForwards;
            fadeDown.removedOnCompletion = NO;
            [marker.layer addAnimation:fadeDown forKey:nil];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [self.tabBarController.tabBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
}

#pragma mark - Accessors

- (CLLocation *)currentLocation {
    if (!_currentLocation) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            LocationManager *locationManager = [LocationManager sharedInstance];
            _currentLocation = locationManager.currentLocation;
        }
        else {
            CLLocation *noLoc = [[CLLocation alloc] initWithLatitude:0 longitude:0 ];
            return noLoc;
        }
    }
    return _currentLocation;
}

- (GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        _mapView.delegate = self.mapViewSupportDelegate;
        _mapView.padding = UIEdgeInsetsMake(80, 0, 0, 0);
        _mapView.autoresizingMask = self.view.autoresizingMask;
        _mapView.userInteractionEnabled = YES;
        _mapView.buildingsEnabled = NO;
        
        [_mapView setMinZoom:14 maxZoom:30];
    }
    return _mapView;
}

- (SPCGoogleMapInfoViewSupportDelegate *)mapViewSupportDelegate {
    if (!_mapViewSupportDelegate) {
        _mapViewSupportDelegate = [[SPCGoogleMapInfoViewSupportDelegate alloc] init];
        _mapViewSupportDelegate.delegate = self;
    }
    return _mapViewSupportDelegate;
}

- (SPCMapDataSource *)mapDataSource {
    if (!_mapDataSource) {
        _mapDataSource = [[SPCMapDataSource alloc] init];
        _mapDataSource.infoWindowType = InfoWindowTypeVenueSelectionOwned;
        _mapDataSource.infoWindowSelectText = @"Edit";
        _mapDataSource.delegate = self;
        _mapDataSource.mapMarkerStyle = MapMarkerStyleEmphasizeOwned;
    }
    return _mapDataSource;
}

- (SPCMarker *)marker {
    if (!_marker) {
        _marker = [SPCMarkerVenueData markerWithOriginalLocation:self.currentLocation venue:nil draggable:YES];
        _marker.zIndex = MARKER_Z;
        _marker.map = self.mapView;
    }
    return _marker;
}


-(SPCGoogleMapInfoView *) markerInfoWindow {
    if (!_markerInfoWindow) {
        _markerInfoWindow = [[SPCGoogleMapInfoView alloc] init];
        [_markerInfoWindow setContentView:self.markerInfoContentView];
    }
    return _markerInfoWindow;
}

-(UIView *) markerInfoContentView {
    if (!_markerInfoContentView) {
        UIView *contentView = [[UIView alloc] init];
        [contentView setBackgroundColor:[UIColor colorWithRed:106.0/255.0 green:177.0/255.0 blue:251.0/255.0 alpha:1.0]];
        
        // Create new location prompt text?
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 15.0, 180.0, 15)];
        label.numberOfLines = 1;
        label.text = @"Create new venue here?";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont spc_mediumSystemFontOfSize:14];
        
        // Buttons?
        UIButton *buttonConfirm = [[UIButton alloc] initWithFrame:CGRectIntegral(CGRectMake(38.0, 45.0, 60.0, 30.0))];
        [buttonConfirm setTitle:@"Yes" forState:UIControlStateNormal];
        [buttonConfirm setTitleColor:[UIColor colorWithRed:106.0/255.0 green:177.0/255.0 blue:251.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        buttonConfirm.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        buttonConfirm.backgroundColor = [UIColor whiteColor];
        buttonConfirm.layer.cornerRadius = 2;
        [buttonConfirm addTarget:self action:@selector(createLocationConfirmTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *buttonCancel = [[UIButton alloc] initWithFrame:CGRectIntegral(CGRectMake(CGRectGetMaxX(buttonConfirm.frame)+16.0, 45.0, 60.0, 30.0))];
        [buttonCancel setTitle:@"No" forState:UIControlStateNormal];
        [buttonCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        buttonCancel.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        buttonCancel.backgroundColor = [UIColor colorWithRed:106.0/255.0 green:177.0/255.0 blue:251.0/255.0 alpha:1.0];
        buttonCancel.layer.borderWidth = 1;
        buttonCancel.layer.borderColor = [UIColor whiteColor].CGColor;
        buttonCancel.layer.cornerRadius = 2;
        
        [buttonCancel addTarget:self action:@selector(createLocationCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Place subviews in content view
        [contentView addSubview:label];
        [contentView addSubview:buttonConfirm];
        [contentView addSubview:buttonCancel];
        contentView.frame = CGRectMake(0.0, 0.0, 210, 90);

        _markerInfoContentView = contentView;
    }
    return _markerInfoContentView;
}

- (UIView *)mapNavBar {
    if (!_mapNavBar) {
        _mapNavBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 65)];
        _mapNavBar.backgroundColor = [UIColor whiteColor];
        _mapNavBar.hidden = NO;
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        closeButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        closeButton.layer.cornerRadius = 2;
        closeButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : closeButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [closeButton setAttributedTitle:backString forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(0, CGRectGetHeight(_mapNavBar.frame) - 44.0f, 60, 44);
        [closeButton addTarget:self action:@selector(dismissViewController:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        titleLabel.text = NSLocalizedString(@"Create Location", nil);
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : titleLabel.font }];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_mapNavBar.frame), CGRectGetMidY(closeButton.frame) - 1);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        
        [_mapNavBar addSubview:titleLabel];
        [_mapNavBar addSubview:closeButton];
    }
    return _mapNavBar;
}


-(void)dismissViewController:(id)sender {
    if (!self.fromExplore) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}


#pragma mark - Map setup

- (BOOL) hasVenueAddress:(SPCMarker *)marker {
    // we have the address if 1. we have a venue, and 2.
    // it is within 3 meters.
    if (self.markerAddressVenue) {
        CLLocation * markerLocation = [[CLLocation alloc] initWithLatitude:marker.position.latitude longitude:marker.position.longitude];
        CLLocation * venuePosition = [[CLLocation alloc] initWithLatitude:[self.markerAddressVenue.latitude floatValue] longitude:[self.markerAddressVenue.longitude floatValue]];
        return [markerLocation distanceFromLocation:venuePosition] < 3;
    }
    return NO;
}


- (NSString *)venueAddressDisplayString {
    if (self.markerAddressVenue) {
        NSString * displayName = self.markerAddressVenue.displayName;
        NSRange commaRange = [displayName rangeOfString:@"," options:NSBackwardsSearch];
        if (commaRange.location == NSNotFound) {
            return displayName;
        } else {
            return [displayName substringToIndex:commaRange.location];
        }
    }
    return nil;
}


- (void)showCurrentLocationRegion {
    GMSCameraPosition *camera;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        if (![LocationManager sharedInstance].locServicesAvailable) {
            camera = [GMSCameraPosition cameraWithLatitude:10
                                                 longitude:-90
                                                      zoom:0
                                                   bearing:0
                                              viewingAngle:0];
        }
        
        else {
            CLLocationCoordinate2D center = self.currentLocation.coordinate;
            
            camera = [GMSCameraPosition cameraWithLatitude:center.latitude
                                                 longitude:center.longitude
                                                      zoom:18
                                                   bearing:0
                                              viewingAngle:0];
        }
        
    }
    else {
        CLLocationCoordinate2D center = self.currentLocation.coordinate;
        
        camera = [GMSCameraPosition cameraWithLatitude:center.latitude
                                             longitude:center.longitude
                                                  zoom:18
                                               bearing:0
                                          viewingAngle:0];
    }
    
    self.mapView.camera = camera;
}


- (void)createLocationConfirmTapped:(id)sender {
    if ([self hasVenueAddress:self.marker]) {
        SPCCreateVenuePostViewController *postVC = [[SPCCreateVenuePostViewController alloc] initWithVenue:self.markerAddressVenue];
        postVC.delegate = self;
        [self.navigationController pushViewController:postVC animated:YES];
    } else {
        SPCCreateVenuePostViewController *postVC = [[SPCCreateVenuePostViewController alloc] initWithLocation:self.marker.position];
        postVC.delegate = self;
        [self.navigationController pushViewController:postVC animated:YES];
    }
}


- (void)createLocationCancelTapped:(id)sender {
    // Hide the marker info window.
    [self.mapViewSupportDelegate selectMarker:nil withMapView:self.mapView];
}


#pragma mark - SPCGoogleMapInfoViewSupportDelegateDelegate

-(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker {
    if (marker == self.marker) {
        [self configureMarkerInfoWindow];
        return self.markerInfoWindow;
    } else if (marker.zIndex == DEVICE_Z) {
        return nil;
    } else {
        return [self.mapDataSource getInfoWindowForMarker:marker mapView:mapView];
    }
}


- (void)configureMarkerInfoWindow {
    if (![self hasVenueAddress:self.marker]) {
        // Fetch the address venue -- if the marker is still in the same place after a delay.
        // This delay ensures the user can't rapidly tap the map to cause a massive number
        // of reverse-geocoding queries.
        CLLocation * location = [[CLLocation alloc] initWithLatitude:self.marker.position.latitude longitude:self.marker.position.longitude];
        [self performSelector:@selector(fetchAddressIfMarkerPosition:) withObject:location afterDelay:GEOCODING_DELAY];
    }
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    if (!self.popupDidAppear) {
        // show the marker info
        [self.mapViewSupportDelegate selectMarker:self.marker withMapView:self.mapView showCallout:YES];
        self.popupDidAppear = YES;
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
        
    BOOL reposition = !self.mapView.selectedMarker || self.mapView.selectedMarker == self.marker;
    [self.mapViewSupportDelegate selectMarker:nil withMapView:self.mapView];
    
    if (reposition) {
        // check distance...
        CLLocation *newLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
        if ([newLocation distanceFromLocation:self.currentLocation] > CREATE_VENUE_MAM_DISTANCE) {
            // slide back into range.
            CLLocationCoordinate2D correctedLocation = [self mapView:mapView projectCoordinateIntoMAMRange:coordinate];
            self.marker.position = correctedLocation;
            [self.mapView animateToLocation:correctedLocation];
            
            // upon finishing the animation, select this marker again (to display popup)
            [self performSelector:@selector(selectMarker:) withObject:self.marker afterDelay:0.5];
            
            // We handled the map scroll -- do NOT allow the InfoDelegate to scroll for us.
            return YES;
            
        } else {
            // just place the coordinate
            self.marker.position = coordinate;
            
            // upon finishing the animation, select this marker again (to display popup)
            [self performSelector:@selector(selectMarker:) withObject:self.marker afterDelay:0.5];
        }
    }
    
    return NO;
}


-(BOOL) mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker {
    if (marker.zIndex == DEVICE_Z) {
        [self.mapViewSupportDelegate selectMarker:nil withMapView:self.mapView];
        self.marker.position = marker.position;
        // upon finishing the animation, select this marker again (to display popup)
        [self performSelector:@selector(selectMarker:) withObject:self.marker afterDelay:0.5];
        return YES;
    }
    return NO;
}

-(void) mapView:(GMSMapView *)mapView didEndDraggingMarker:(SPCMarker *)marker {
    [self.mapViewSupportDelegate selectMarker:nil withMapView:self.mapView];
    
    CLLocationCoordinate2D correctedLocation = [self mapView:mapView projectCoordinateIntoMAMRange:marker.position];
    marker.position = correctedLocation;
    // the info window will recenter.
    
    // upon finishing the animation, select this marker again (to display popup)
    [self performSelector:@selector(selectMarker:) withObject:self.marker afterDelay:0.5];
}

-(CGFloat)mapView:(GMSMapView *)mapView calloutHeightForMarker:(SPCMarker *)marker {
    return [self.mapDataSource infoWindowHeightForMarker:marker mapView:mapView];
}

-(void) selectMarker:(id)marker {
    [self.mapViewSupportDelegate selectMarker:(SPCMarker *)marker withMapView:self.mapView];
}

-(void) fetchAddressIfMarkerPosition:(id)clLocation {
    CLLocation * location = (CLLocation *)clLocation;
    CLLocation * markerLocation = [[CLLocation alloc] initWithLatitude:self.marker.position.latitude longitude:self.marker.position.longitude];
    
    // compare for an exact result
    if (location.coordinate.latitude == markerLocation.coordinate.latitude && location.coordinate.longitude == markerLocation.coordinate.longitude) {
        [[VenueManager sharedInstance] fetchGoogleAddressVenueAtLatitude:location.coordinate.latitude longitude:location.coordinate.longitude resultCallback:^(Venue *venue) {
            if (location.coordinate.latitude == markerLocation.coordinate.latitude && location.coordinate.longitude == markerLocation.coordinate.longitude) {
                // Got it!
                self.markerAddressVenue = venue;
            }
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            NSLog(@"TODO: update the info window (if displayed) to represent the error.");
        }];
    }
}


- (CLLocationCoordinate2D)mapView:(GMSMapView *)mapView projectCoordinateIntoMAMRange:(CLLocationCoordinate2D)coordinate {
    CGPoint centerPoint = [mapView.projection pointForCoordinate:self.currentLocation.coordinate];
    CGPoint newPoint = [mapView.projection pointForCoordinate:coordinate];
    CGVector vector = CGVectorMake(newPoint.x - centerPoint.x, newPoint.y - centerPoint.y);
    double magnitude = hypot(vector.dx, vector.dy);
    CGVector normalizedVector = CGVectorMake(vector.dx / magnitude, vector.dy / magnitude);
    // quick-and-dirty estimate: a change of 111,111 * cos(latitude) meters is 1 degree.
    double degreesPerMeter = 1.0 / (111111.0 * cos(M_PI * self.currentLocation.coordinate.latitude / 180.0));
    // another quick-and-dirty: how many pixels for the given radius?  Allow ourselves some room for error.
    CLLocationCoordinate2D maxDistanceCoordinate = CLLocationCoordinate2DMake(self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude + degreesPerMeter * CREATE_VENUE_MAM_DISTANCE);
    CGPoint maxDistancePoint = [mapView.projection pointForCoordinate:maxDistanceCoordinate];
    double pixelMagnitude = hypot(centerPoint.x - maxDistancePoint.x, centerPoint.y - maxDistancePoint.y);
    // scale the vector by distance magnitude to get the corrected point.  Remember to leave some margin for error!
    CGPoint correctedPoint = CGPointMake(centerPoint.x + normalizedVector.dx * pixelMagnitude * 0.9, centerPoint.y + normalizedVector.dy * pixelMagnitude * 0.9);
    return [mapView.projection coordinateForPoint:correctedPoint];
}


#pragma mark SPCMapDataSourceDelegate

- (void)userDidSelectVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker {
    // edit this!
    SPCCreateVenuePostViewController *postVC = [[SPCCreateVenuePostViewController alloc] initWithVenue:venue];
    postVC.delegate = self;
    [self.navigationController pushViewController:postVC animated:YES];
}


#pragma mark SPCCreateVenuePostViewControllerDelegate

-(void)spcCreateVenuePostViewControllerDidFinish:(UIViewController *)viewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadLocations" object:nil];
    
    // animating this first pop will cause a "nested-pop" crash on iOS 7.
    [viewController.navigationController popViewControllerAnimated:NO];
    
    // double pop
    if (!self.fromExplore) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}


@end
