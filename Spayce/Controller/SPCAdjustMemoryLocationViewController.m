//
//  SPCAdjustMemoryLocationViewController.m
//  Spayce
//
//  Created by Jake Rosin on 6/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAdjustMemoryLocationViewController.h"

#import "SPCCustomNavigationController.h"
#import "SPCVenueDetailViewController.h"

// Model
#import "Location.h"
#import "Person.h"
#import "SPCBaseDataSource.h"
#import "User.h"

// View
#import "SPCMapRadiusHighlightView.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"
#import "VenueManager.h"

// Util
#import "SPCTerritory.h"

#define NAV_BAR_HEIGHT 64
#define NAV_TITLE_HORIZ_MARGIN 65
#define EDIT_BUTTON_HORIZ_MARGIN 60
#define EDIT_BUTTON_VERT_MARGIN 35
#define EDIT_BUTTON_HEIGHT 50

#define RADIUS 50

NSString * SPCMemoryMovedFromVenueToVenue = @"SPCMemoryMovedFromVenueToVenue";

@interface SPCAdjustMemoryLocationViewController ()

@property (nonatomic, strong) GMSMapView * mapView;
@property (nonatomic, strong) SPCMapRadiusHighlightView * mapRadiusHighlightView;
@property (nonatomic, strong) SPCGoogleMapInfoViewSupportDelegate * mapSupportDelegate;
@property (nonatomic, strong) SPCMapDataSource * mapDataSource;
@property (nonatomic, strong) SPCMarker * draggableMarker;
@property (nonatomic, strong) Venue * draggableVenue;

@property (nonatomic, strong) UIView *mapNavBar;
@property (nonatomic, strong) UIButton *editLocationButton;
@property (nonatomic, strong) UIButton *cancelEditButton;

@property (nonatomic, strong) UIView *postActionOverlay;

@property (nonatomic, strong) Memory * memory;

@property (nonatomic, strong) NSArray * venues;

@property (nonatomic, assign) BOOL editMode;

@property (nonatomic, strong) GMSPolygon *poly;

@property (nonatomic, strong) UIButton *enterVenueDetailBtn;
@property (nonatomic, strong) UILabel *venueNameLabel;

@end

@implementation SPCAdjustMemoryLocationViewController

-(void)dealloc{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_mapView];
}

-(SPCAdjustMemoryLocationViewController *)initWithMemory:(Memory*)memory {
    self = [super init];
    if (self) {
        _memory = memory;
        _editMode = NO;
        _venues = nil;
        _draggableVenue = _memory.venue;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Add subviews
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.mapNavBar];
    [self.view addSubview:self.editLocationButton];
    [self.view addSubview:self.cancelEditButton];
    
    [self.view addSubview:self.postActionOverlay];
    
    [self.mapView addSubview:self.mapRadiusHighlightView];
    [self.view addSubview:self.enterVenueDetailBtn];
    
    [self updateMapMarkers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_venues && [self userCanEdit]) {
        [MeetManager fetchNearbyAddressesWithLatitude:[self.memory.location.latitude floatValue] longitude:[self.memory.location.longitude floatValue] resultCallback:^(NSArray * venues) {
            [self.mapDataSource setAsVenueStacksWithVenues:venues atCurrentVenue:nil deviceVenue:nil];
            _venues = venues;
            if (self.editMode) {
                [self updateMapMarkers];
            }
        } faultCallback:^(NSError *error) {
            // Nothing for now...
            NSLog(@"Error fetching venues");
        }];
    }
    
    if (self.memory.venue.specificity > SPCVenueIsReal || self.memory.venue.isCustomVenue) {
        [self adjustMap];
    }
}

#pragma mark - property accessors

-(GMSMapView *) mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        GMSCameraPosition *camera;
        if (self.memory) {
            camera = [GMSCameraPosition cameraWithLatitude:[self.memory.location.latitude floatValue]
                                                 longitude:[self.memory.location.longitude floatValue] zoom:18
                                                   bearing:0 viewingAngle:15];
            _mapView.camera = camera;
        }
        _mapView.delegate = self.mapSupportDelegate;
        _mapView.settings.rotateGestures = NO;
        _mapView.buildingsEnabled = NO;
    }
    return _mapView;
}

-(SPCMapRadiusHighlightView *) mapRadiusHighlightView {
    if (!_mapRadiusHighlightView) {
        _mapRadiusHighlightView = [[SPCMapRadiusHighlightView alloc] initWithFrame:self.mapView.bounds];
        _mapRadiusHighlightView.location = self.memory.location.location;
        _mapRadiusHighlightView.radius = RADIUS;
        _mapRadiusHighlightView.highlight = NO;
        [_mapRadiusHighlightView updateWithMapView:self.mapView];
    }
    return _mapRadiusHighlightView;
}

-(SPCGoogleMapInfoViewSupportDelegate *)mapSupportDelegate {
    if (!_mapSupportDelegate) {
        _mapSupportDelegate = [[SPCGoogleMapInfoViewSupportDelegate alloc] init];
        _mapSupportDelegate.delegate = self;
    }
    return _mapSupportDelegate;
}

-(SPCMapDataSource *) mapDataSource {
    if (!_mapDataSource) {
        _mapDataSource = [[SPCMapDataSource alloc] init];
        _mapDataSource.delegate = self;
        // TODO: venues that have YES / NO buttons.  See Mark's design.
        _mapDataSource.infoWindowType = InfoWindowTypeVenueConfirmation;
        _mapDataSource.infoWindowConfirmationText = @"Change memory location here?";
    }
    return _mapDataSource;
}

- (UIView *)mapNavBar {
    if (!_mapNavBar) {
        UIView *navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), NAV_BAR_HEIGHT)];
        navBar.backgroundColor = [UIColor whiteColor];
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        closeButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        closeButton.layer.cornerRadius = 2;
        closeButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : closeButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Close" attributes:backStringAttributes];
        [closeButton setAttributedTitle:backString forState:UIControlStateNormal];
        CGSize sizeOfCloseButton = [closeButton.titleLabel.text sizeWithAttributes:backStringAttributes];
        closeButton.frame = CGRectMake(9, CGRectGetHeight(navBar.frame) - sizeOfCloseButton.height - 13.0f, sizeOfCloseButton.width, sizeOfCloseButton.height);
        [closeButton addTarget:self action:@selector(dismissViewController:) forControlEvents:UIControlEventTouchUpInside];
        
        NSString * venueName = self.memory.venue.venueName;
        NSString * addressLine;
        if (self.memory.venue.city && self.memory.venue.state) {
            addressLine = [NSString stringWithFormat:@"%@ %@", [SPCTerritory fixCityName:self.memory.venue.city stateCode:self.memory.venue.state countryCode:self.memory.venue.country], self.memory.venue.state];
        } else if (self.memory.venue.city && self.memory.venue.country) {
            addressLine = [NSString stringWithFormat:@"%@ %@", [SPCTerritory fixCityName:self.memory.venue.city stateCode:self.memory.venue.state countryCode:self.memory.venue.country], self.memory.venue.country];
        } else if (self.memory.venue.city) {
            addressLine = [SPCTerritory fixCityName:self.memory.venue.city stateCode:self.memory.venue.state countryCode:self.memory.venue.country];
        } else {
            addressLine = [SPCTerritory countryNameForCountryCode:self.memory.venue.country];
        }
        
        if (!venueName) {
            venueName = self.memory.venue.streetAddress;
        }
        
        if (self.memory.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
            venueName = self.memory.venue.neighborhood;
        }

        if (self.memory.venue.specificity == SPCVenueIsFuzzedToCity) {
            venueName = [SPCTerritory fixCityName:self.memory.venue.city stateCode:self.memory.venue.state countryCode:self.memory.venue.country];
            addressLine = [SPCTerritory countryNameForCountryCode:self.memory.venue.country];
        }
        
        // This is the widest width the title can occupy in order to avoid touching the closeButton
        CGFloat maxTitleWidth = CGRectGetWidth(navBar.frame) - 2 * CGRectGetMaxX(closeButton.frame) - 2.0f; // 2pt padding
        
        // Set the title label
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        NSDictionary *titleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16.0f],
                                                NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3f5578] };
        titleLabel.textAlignment = NSTextAlignmentLeft;
        
        if (venueName) {
            titleLabel.attributedText = [[NSAttributedString alloc] initWithString:[venueName uppercaseString] attributes:titleLabelAttributes];
            CGSize titleLabelSize = [[venueName uppercaseString] sizeWithAttributes:titleLabelAttributes];
            
            CGFloat titleLabelWidth = MIN(maxTitleWidth, titleLabelSize.width);
            titleLabel.frame = CGRectMake(CGRectGetWidth(navBar.frame) / 2 - titleLabelWidth / 2, CGRectGetMidY(closeButton.frame) - titleLabelSize.height + 2.0f, titleLabelWidth, titleLabelSize.height);
            
        }
        
        // Set the subtitle label
        UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        
        if (addressLine) {
            NSDictionary *subtitleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_regularSystemFontOfSize:13.0f],
                                                    NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x3f5578] };
            subtitleLabel.attributedText = [[NSAttributedString alloc] initWithString:addressLine attributes:subtitleLabelAttributes];
            subtitleLabel.textAlignment = NSTextAlignmentLeft;
            CGSize subtitleLabelSize = [addressLine sizeWithAttributes:subtitleLabelAttributes];
            CGFloat subtitleLabelWidth = MIN(maxTitleWidth, subtitleLabelSize.width);
            subtitleLabel.frame = CGRectMake(CGRectGetWidth(navBar.frame) / 2 - subtitleLabelWidth / 2, CGRectGetMidY(closeButton.frame) - 2.0f, subtitleLabelWidth, subtitleLabelSize.height);
        }
            
        [navBar addSubview:closeButton];
        [navBar addSubview:titleLabel];
        [navBar addSubview:subtitleLabel];
        
        _mapNavBar = navBar;
    }
    return _mapNavBar;
}


- (UIButton *)editLocationButton {
    if (!_editLocationButton) {
        UIButton * editButton = [[UIButton alloc] initWithFrame:CGRectMake(EDIT_BUTTON_HORIZ_MARGIN, CGRectGetHeight(self.view.frame) - EDIT_BUTTON_VERT_MARGIN - EDIT_BUTTON_HEIGHT, CGRectGetWidth(self.view.frame) - EDIT_BUTTON_HORIZ_MARGIN*2, EDIT_BUTTON_HEIGHT)];
        editButton.layer.cornerRadius = 2;
        [editButton setBackgroundColor:[UIColor colorWithRGBHex:0x6ab1fb]];
        [editButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        editButton.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:16];
        [editButton setTitle:@"Change Location\nof this memory" forState:UIControlStateNormal];
        editButton.enabled = !self.editMode && [self userCanEdit];
        editButton.hidden = !editButton.enabled;
        [editButton addTarget:self action:@selector(editModeOn:) forControlEvents:UIControlEventTouchUpInside];
        
        _editLocationButton = editButton;
    }
    return _editLocationButton;
}


- (UIButton *)cancelEditButton {
    if (!_cancelEditButton) {
        UIButton * button = [[UIButton alloc] initWithFrame:CGRectMake(EDIT_BUTTON_HORIZ_MARGIN, CGRectGetHeight(self.view.frame) - EDIT_BUTTON_VERT_MARGIN - EDIT_BUTTON_HEIGHT, CGRectGetWidth(self.view.frame) - EDIT_BUTTON_HORIZ_MARGIN*2, EDIT_BUTTON_HEIGHT)];
        button.layer.cornerRadius = 2;
        [button setBackgroundColor:[UIColor colorWithRGBHex:0xed7652]];
        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
        button.enabled = self.editMode;
        button.hidden = !button.enabled;
        [button addTarget:self action:@selector(editModeOff:) forControlEvents:UIControlEventTouchUpInside];
        
        _cancelEditButton = button;
    }
    return _cancelEditButton;
}

- (UIView *)postActionOverlay {
    if (!_postActionOverlay) {
        UIView * view = [[UIView alloc] initWithFrame:self.view.frame];
        view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
        view.userInteractionEnabled = NO;
        view.hidden = YES;
        
        _postActionOverlay = view;
    }
    return _postActionOverlay;
}

- (UIButton *) enterVenueDetailBtn   {
    if (!_enterVenueDetailBtn) {
        
        _enterVenueDetailBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 55, self.view.bounds.size.width, 55)];
        _enterVenueDetailBtn.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        [_enterVenueDetailBtn setTitle:NSLocalizedString(@"Enter:",nil) forState:UIControlStateNormal];
        [_enterVenueDetailBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 15, 0)];
        _enterVenueDetailBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        [_enterVenueDetailBtn addTarget:self action:@selector(goToVenueDetail:) forControlEvents:UIControlEventTouchDown];
        
        [_enterVenueDetailBtn addSubview:self.venueNameLabel];
        [self.venueNameLabel sizeToFit];
        self.venueNameLabel.center = CGPointMake(self.view.bounds.size.width/2, self.venueNameLabel.center.y);
        
        UIImageView *pinImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pin-white-small"]];
        pinImgView.frame = CGRectMake(CGRectGetMinX(_venueNameLabel.frame) - 3 - pinImgView.frame.size.width, CGRectGetMinY(_venueNameLabel.frame) + 4, pinImgView.frame.size.width, pinImgView.frame.size.height);
        [_enterVenueDetailBtn addSubview:pinImgView];
        
    }
    return _enterVenueDetailBtn;
}

-(UILabel *)venueNameLabel {
    
    
    if (!_venueNameLabel) {
        
        NSString * venueName = self.memory.venue.venueName;
        
        if (!venueName) {
            venueName = self.memory.venue.streetAddress;
        }
        
        if (self.memory.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
            venueName = self.memory.venue.neighborhood;
        }
        
        if (self.memory.venue.specificity == SPCVenueIsFuzzedToCity) {
            venueName = [SPCTerritory fixCityName:self.memory.venue.city stateCode:self.memory.venue.state countryCode:self.memory.venue.country];
        }
      
        _venueNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, self.view.bounds.size.width, 25)];
        _venueNameLabel.text = venueName;
        _venueNameLabel.font = [UIFont fontWithName:@"OpenSans-Bold" size:14.0f];
        _venueNameLabel.textAlignment = NSTextAlignmentCenter;
        _venueNameLabel.textColor = [UIColor whiteColor];
        _venueNameLabel.userInteractionEnabled = NO;
    }
    return _venueNameLabel;
}


#pragma mark - Action methods

- (BOOL)withinRadius:(CLLocationCoordinate2D)coordinate {
    CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLLocation * centerLocation = [[CLLocation alloc] initWithLatitude:[self.memory.location.latitude floatValue] longitude:[self.memory.location.longitude floatValue]];
    if (location && centerLocation) {
        return [location distanceFromLocation:centerLocation] < RADIUS;
    }
    return NO;
}

- (CLLocationCoordinate2D)toWithinRadius:(CLLocationCoordinate2D)coordinate {
    CLLocation * location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    CLLocation * centerLocation = [[CLLocation alloc] initWithLatitude:[self.memory.location.latitude floatValue] longitude:[self.memory.location.longitude floatValue]];
    if (location && centerLocation) {
        CGFloat distance = [location distanceFromLocation:centerLocation];
        if (distance < RADIUS) {
            return coordinate;
        }
        CGFloat portion = RADIUS / distance;
        return CLLocationCoordinate2DMake(portion * coordinate.latitude + (1-portion) * centerLocation.coordinate.latitude, portion * coordinate.longitude + (1-portion) * centerLocation.coordinate.longitude);
    }
    return coordinate;
}

- (BOOL)userCanEdit {
    return (self.memory.author.recordID == [AuthenticationManager sharedInstance].currentUser.userId && self.memory.venue.specificity == SPCVenueIsReal);
}

- (void)updateMapMarkers {
    [self.mapView clear];
    if (self.editMode) {
        // Nearby places...
        NSArray * markers = self.mapDataSource.stackedVenueMarkers;
        if (markers) {
            [markers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                SPCMarker * marker = (SPCMarker *)obj;
                if ([self withinRadius:marker.position]) {
                    marker.zIndex = 0;
                    marker.map = self.mapView;
                }
            }];
        }
        
        // include a draggable pin, etc.
        self.draggableMarker = [self.mapDataSource markerWithStackAtDeviceAndCurrentVenue:self.draggableVenue];
        self.draggableMarker.zIndex = 1;
        self.draggableMarker.draggable = YES;
        self.draggableMarker.map = self.mapView;
    } else {
        // just the current venue, no profile pic - but only show pin for non-custom venues
        
         if (self.memory.venue.specificity == SPCVenueIsReal && !self.memory.venue.isCustomVenue) {
        
             SPCMarker * marker = [self.mapDataSource markerWithStackAtVenue:self.draggableVenue];
             marker.draggable = NO;
             marker.map = self.mapView;
             
             //center the map on the marker's position, becaue this varies slightly from the mem's lat/long in some cases
             CLLocationCoordinate2D center = marker.position;
             
             GMSCameraPosition *camera;
             camera = [GMSCameraPosition cameraWithLatitude:center.latitude
             longitude:center.longitude zoom:18
             bearing:0 viewingAngle:15];
             
             self.mapView.camera = camera;
         }
    }
    
    
    if (self.memory.venue.specificity == SPCVenueIsReal) {
        
        // set camera: allows immediate user interaction w/ markers, without having to drag map.
        [self.mapView performSelector:@selector(setCamera:) withObject:self.mapView.camera afterDelay:0.2f];
    }
}

- (void)adjustMap {

    float zoom = 18;
    
    CLLocation *venLocation = [[CLLocation alloc] initWithLatitude:self.memory.location.latitude.floatValue
                                                         longitude:self.memory.location.longitude.floatValue];
    
    
    CLLocationCoordinate2D center = venLocation.coordinate;
    
    if (self.memory && self.memory.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        zoom  = 14;
    }
    if (self.memory && self.memory.venue.specificity == SPCVenueIsFuzzedToCity) {
        zoom  = 10;
    }
    
    if (self.memory && self.memory.venue.isCustomVenue) {
        zoom  = 14;
    }
    
    if (center.latitude == 0 && center.longitude == 0) {
        // nope
        return;
    }
    
    GMSCameraPosition *camera;
    camera = [GMSCameraPosition cameraWithLatitude:center.latitude
                                         longitude:center.longitude zoom:zoom
                                           bearing:0 viewingAngle:15];
    
    self.mapView.camera = camera;
}

- (void)editModeOn:(id)sender {
    if (!self.editMode) {
        [self.mapSupportDelegate selectMarker:nil withMapView:self.mapView];
        
        _editMode = YES;
        
        self.mapRadiusHighlightView.highlight = YES;
        
        self.editLocationButton.hidden = YES;
        self.editLocationButton.enabled = NO;
        self.cancelEditButton.hidden = NO;
        self.cancelEditButton.enabled = YES;
        
        // TODO: retrieve / prepare Nearby Venues?
        
        [self updateMapMarkers];
    }
}

- (void)editModeOff:(id)sender {
    if (self.editMode) {
        [self.mapSupportDelegate selectMarker:nil withMapView:self.mapView];
        
        _editMode = NO;
        
        self.mapRadiusHighlightView.highlight = NO;
        
        self.editLocationButton.hidden = ![self userCanEdit];
        self.editLocationButton.enabled = !self.editLocationButton.hidden;
        self.cancelEditButton.hidden = YES;
        self.cancelEditButton.enabled = NO;
        
        _draggableVenue = _memory.venue;
        
        [self updateMapMarkers];
    }
}

- (void)dismissViewController:(id)sender {
    if ([self.delegate respondsToSelector:@selector(dismissAdjustMemoryLocationViewController:)]) {
        [self.delegate dismissAdjustMemoryLocationViewController:self];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)goToVenueDetail:(id)sender {
 
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = self.memory.venue;
    [venueDetailViewController fetchMemories];
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    [self presentViewController:navController animated:YES completion:nil];
}


#pragma mark - SPCGoogleMapInfoViewSupportDelegate

-(CGFloat)mapView:(GMSMapView *)mapView calloutHeightForMarker:(SPCMarker *)marker {
    return [self.mapDataSource infoWindowHeightForMarker:marker mapView:mapView];
}

-(void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    [self.mapRadiusHighlightView updateWithMapView:mapView];
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker {
    return !self.editMode;
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker {
    if (self.editMode) {
        // TODO show the "select this venue" window
        return [self.mapDataSource getInfoWindowForMarker:marker mapView:mapView];
    } else {
        return nil;
    }
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(SPCMarker *)marker {
    if (marker == self.draggableMarker) {
        
        CLLocationCoordinate2D location = marker.position;
        if (![self withinRadius:marker.position]) {
            location = [self toWithinRadius:marker.position];
            marker.position = location;
            // setting this will automatically reposition the marker to within the available radius;
            // there is no need to reposition it below, when the marker is configured
            // by the map data source.
        }
        
        // make a new venue, configure marker, popup.
        self.draggableVenue = [[Venue alloc] init];
        self.draggableVenue.latitude = [NSNumber numberWithFloat:location.latitude];
        self.draggableVenue.longitude = [NSNumber numberWithFloat:location.longitude];
        self.draggableVenue.defaultName = @"Loading address...";
        
        [self.mapDataSource configureMarker:marker withStackAtDeviceAndCurrentVenue:self.draggableVenue reposition:NO];
        
        [self.mapSupportDelegate selectMarker:marker withMapView:self.mapView];
        
        // Start a delayed load of address data here.
        CLLocation * cllocation = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
        [self performSelector:@selector(fetchAddressIfMarkerPosition:) withObject:cllocation afterDelay:2.0];
    }
}


-(void) fetchAddressIfMarkerPosition:(id)clLocation {
    CLLocation * location = (CLLocation *)clLocation;
    CLLocation * markerLocation = [[CLLocation alloc] initWithLatitude:self.draggableMarker.position.latitude longitude:self.draggableMarker.position.longitude];
    
    // compare for an exact result
    if (location.coordinate.latitude == markerLocation.coordinate.latitude && location.coordinate.longitude == markerLocation.coordinate.longitude) {
        
        [[VenueManager sharedInstance] fetchVenueWithGoogleHintAtLatitude:self.draggableMarker.position.latitude longitude:self.draggableMarker.position.longitude rateLimited:YES resultCallback:^(Venue * venue) {
            if (location.coordinate.latitude == markerLocation.coordinate.latitude && location.coordinate.longitude == markerLocation.coordinate.longitude) {
                self.draggableVenue = venue;
                self.draggableVenue.latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
                self.draggableVenue.longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
                [self.mapDataSource configureMarker:self.draggableMarker withStackAtDeviceAndCurrentVenue:self.draggableVenue reposition:NO];
                [self.mapDataSource refreshInfoWindowForMarker:self.draggableMarker];
            }
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            // Do nothing
            NSLog(@"Error fetching venue: %@", fault);
        }];
    }
}


#pragma mark - SPCMapDataSourceDelegate

- (void)userDidConfirmVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker {
    // move the memory here!
    if (venue.addressId == self.memory.venue.addressId) {
        // confirmed the same venue...
        [self dismissViewController:self];
    } else if (venue.addressId) {
        // has a location Id, but not the same as the original.
        self.postActionOverlay.hidden = NO;
        self.postActionOverlay.userInteractionEnabled = YES;
        [MeetManager updateMemoryWithMemoryId:self.memory.recordID addressId:venue.addressId resultCallback:^(NSDictionary *results) {
            BOOL success = 1 == [results[@"number"] intValue];
            if (!success) {
                self.postActionOverlay.hidden = YES;
                self.postActionOverlay.userInteractionEnabled = NO;
            } else {
                BOOL venueUpdate = self.memory.venue.locationId != venue.locationId;
                
                Venue * originalVenue = self.memory.venue;
                
                self.memory.venue = venue;
                self.memory.locationName = venue.displayName;
                
                if (venueUpdate) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryMovedFromVenueToVenue object:@[self.memory, originalVenue, venue]];
                }
                
                // post a notification that this memory has been updated!
                [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:self.memory];
                // refresh!
                [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:self.memory];
                
                if ([self.delegate respondsToSelector:@selector(didAdjustLocationForMemory:withViewController:)]) {
                    [self.delegate didAdjustLocationForMemory:self.memory withViewController:self];
                } else {
                    [self dismissViewController:self];
                }
            }
        } faultCallback:^(NSError *fault) {
            NSLog(@"Error updating venue... but why?");
            self.postActionOverlay.hidden = YES;
            self.postActionOverlay.userInteractionEnabled = NO;
        }];
    } else {
        NSLog(@"Attempt to confirm venue with no addressId!");
    }
}

- (void)userDidCancelVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker {
    [self.mapSupportDelegate selectMarker:nil withMapView:self.mapView];
}


- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return [self.navigationController.topViewController supportedInterfaceOrientations];
}

@end
