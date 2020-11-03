//
//  SPCMapViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMapViewController.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>

// View
#import "SPCGoogleMapInfoView.h"
#import "SPCMapDataSource.h"
#import "SPCSearchTextField.h"
#import "SPCChangeLocationCell.h"
#import "SPCBaseDataSource.h"
#import "HMSegmentedControl.h"
#import "SPCEarthquakeLoader.h"

// Category
#import "UIScreen+Size.h"
#import "UITableView+SPXRevealAdditions.h"

// Manager
#import "LocationContentManager.h"
#import "LocationManager.h"
#import "MeetManager.h"
#import "VenueManager.h"
#import "ContactAndProfileManager.h"
#import "UserProfile.h"
#import "ProfileDetail.h"

// View Controller
#import "SPCAdjustMemoryLocationViewController.h"
#import "SPCCreateVenueViewController.h"
#import "SPCCreateVenuePostViewController.h"
#import "SPCCustomNavigationController.h"

// Model
#import "Memory.h"
#import "Venue.h"
#import "Location.h"

#define MINIMUM_LOCATION_MANAGER_UPTIME 6

#define VENUE_PLACEHOLDER_LOCATION_ID -11110

#define ADJUST_MEMORY_RADIUS 300

static NSString *CellIdentifier = @"SPCHereVenueListCell";


@interface SPCMapViewController () <UISearchBarDelegate, UITextFieldDelegate, SPCGoogleMapInfoViewSupportDelegateDelegate, SPCMapDataSourceDelegate, UIGestureRecognizerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) SPCGoogleMapInfoViewSupportDelegate *mapViewSupportDelegate;
@property (nonatomic, strong) SPCMapDataSource *mapDataSource;
@property (nonatomic, strong) SPCMarker *draggableMarker;
@property (nonatomic, strong) UIView *segControlContainer;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;
@property (nonatomic, strong) SPCSearchTextField * searchBar;
@property (nonatomic, strong) UIView *searchContainer;
@property (nonatomic, strong) UIImageView *searchIcon;
@property (nonatomic, strong) UIButton *resetSearchBtn;
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIButton *plusBottomOverlayButton;
@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, strong) NSArray *filteredVenues;
@property (nonatomic, strong) Venue *fuzzedVenue;


@property (nonatomic, assign) NSInteger memoryCountGold;
@property (nonatomic, assign) NSInteger memoryCountSilver;
@property (nonatomic, assign) NSInteger memoryCountBronze;

@property (nonatomic, strong) UIButton *hideLocationBtn;

@property (nonatomic, strong) GMSPolygon *poly;

// These properties are only used to restore the dragged pin position if the user suspends the view
// and returns to the same ViewController instance.  They are not used to determine
// the user's selected position when "select" is pressed.
@property (nonatomic, assign) CLLocationCoordinate2D draggedToCoordinate;
@property (nonatomic, strong) Venue *draggedToVenue;

@property (nonatomic, assign) BOOL performingRefresh;

@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) SPCEarthquakeLoader *locationLoader;

@end

@implementation SPCMapViewController


#pragma mark - NSObject - Creating, Copying, and Deallocating Objects
- (void)dealloc {
    // Remove observers!!!!
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Cancel any previous requests that were set to execute on a delay!!
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_mapView];
}


- (instancetype)initForNewMemoryWithSelectedVenue:(Venue *)selectedVenue {
    self = [super init];
    if (self) {
        self.selectedVenue = selectedVenue;
    }
    return self;
}

- (instancetype)initForExistingMemory:(Memory *)memory {
    self = [super init];
    if (self) {
        self.memory = memory;
        self.selectedVenue = memory.venue;
    }
    return self;
}


#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForNotifications];
    
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:self.segControlContainer];
    [self.view addSubview:self.searchContainer];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.hideLocationBtn];
    

    [self.view addSubview:self.navBar];
    [self.view addSubview:self.plusBottomOverlayButton];

    [self.view addSubview:self.locationLoader];
    
    [self configureTableView];
    
    [self fetchNearbyLocations:NO];
    
    if ([ContactAndProfileManager sharedInstance].profile.profileDetail.isCeleb) {
        self.hideLocationBtn.hidden = NO;
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tabBarController.tabBar setHidden:YES];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.tabBarController.tabBar setHidden:NO];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Accessors

- (GMSMapView *)mapView {
    if (!_mapView) {
        CGFloat yOrigin = CGRectGetMaxY(self.segControlContainer.frame);
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0.0, yOrigin, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - yOrigin)];
        _mapView.delegate = self.mapViewSupportDelegate;
        _mapView.buildingsEnabled = NO;
        _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _mapView.userInteractionEnabled = YES;
        _mapView.hidden = YES;
        _mapView.alpha = 0.0f;
        
        UIEdgeInsets mapInsets = UIEdgeInsetsMake(0.0, 0.0, 50.0, 0.0);
        _mapView.padding = mapInsets;
        
        [_mapView setMinZoom:14 maxZoom:30];
    }
    return _mapView;
}

-(SPCMapDataSource *) mapDataSource {
    if (!_mapDataSource) {
        _mapDataSource = [[SPCMapDataSource alloc] init];
        _mapDataSource.delegate = self;
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


- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 70)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectZero];
        cancelButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        cancelButton.layer.cornerRadius = 2;
        cancelButton.backgroundColor = [UIColor clearColor];
        NSDictionary *cancelStringAttributes = @{ NSFontAttributeName : cancelButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *cancelString = [[NSAttributedString alloc] initWithString:@"Cancel" attributes:cancelStringAttributes];
        [cancelButton setAttributedTitle:cancelString forState:UIControlStateNormal];
        cancelButton.frame = CGRectMake(0, CGRectGetHeight(_navBar.frame) - 44.0f, 70, 44);
        [cancelButton addTarget:self action:@selector(closeButtonActivated:) forControlEvents:UIControlEventTouchUpInside];
        [cancelButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchDown];
        [cancelButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchDragEnter];
        [cancelButton addTarget:self action:@selector(closeButtonReleased:) forControlEvents:UIControlEventTouchUpOutside];
        [cancelButton addTarget:self action:@selector(closeButtonReleased:) forControlEvents:UIControlEventTouchDragExit];
        _cancelButton = cancelButton;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        NSDictionary *titleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:14],
                                                NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x292929],
                                                NSKernAttributeName : @(1.1) };
        NSString *titleText = NSLocalizedString(@"Change Location", nil);
        titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleText attributes:titleLabelAttributes];
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:titleLabelAttributes];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_navBar.frame), CGRectGetMidY(cancelButton.frame) - 1);
        
        UIImage *refreshImage = [UIImage imageNamed:@"button-refresh-location-inverse"];
        UIButton *refreshButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, refreshImage.size.width + 10, refreshImage.size.height + 10)]; // Add 10pt for enlarging the button's clickable area
        [refreshButton setImage:refreshImage forState:UIControlStateNormal];
        refreshButton.center = CGPointMake(CGRectGetWidth(self.view.frame) - CGRectGetWidth(_cancelButton.frame) / 2, CGRectGetMidY(titleLabel.frame));
        [refreshButton addTarget:self action:@selector(refreshLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _refreshButton = refreshButton;
        if (self.memory) {
            _refreshButton.alpha = 0;
            _refreshButton.enabled = NO;
        }
        else {
            _refreshButton.enabled = YES;
        }
        
        UIView *sepBottom = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_navBar.frame) - 0.5f, CGRectGetWidth(_navBar.frame), 0.5f)];
        [sepBottom setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
        
        [_navBar addSubview:_cancelButton];
        [_navBar addSubview:titleLabel];
        [_navBar addSubview:_refreshButton];
        [_navBar addSubview:sepBottom];
    }
    return _navBar;
}

- (SPCEarthquakeLoader *)locationLoader {
    if (!_locationLoader) {
        _locationLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame), self.view.frame.size.width, self.view.frame.size.height - self.segControlContainer.frame.size.height - 44)];
        _locationLoader.msgLabel.text = @"Updating location...";
        _locationLoader.alpha = 0;
    }
    return _locationLoader;
}

- (UIView *)segControlContainer {
    if (!_segControlContainer) {
        _segControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.view.frame.size.width, 40)];
        _segControlContainer.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        _segControlContainer.userInteractionEnabled = YES;
        
        [_segControlContainer addSubview:self.hmSegmentedControl];
        
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - .25, 11.5, 0.5, 17)];
        sepLine.backgroundColor = [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepLine];
    }
    return _segControlContainer;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"LIST", @"MAP"]];
        _hmSegmentedControl.font = [UIFont spc_boldSystemFontOfSize:12];
        _hmSegmentedControl.frame = CGRectMake(0, 0, _segControlContainer.frame.size.width, 40);
        [_hmSegmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
        _hmSegmentedControl.selectionIndicatorHeight = 0;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationNone;
        _hmSegmentedControl.shouldAnimateUserSelection = YES;
        _hmSegmentedControl.selectedSegmentIndex = 0;
    }
    return _hmSegmentedControl;
}

- (UIView *)searchContainer {
    
    if (!_searchContainer) {
        _searchContainer = [[UIView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.segControlContainer.frame) + 2, self.view.bounds.size.width-20, 30)];
        _searchContainer.backgroundColor = [UIColor whiteColor];
        _searchContainer.layer.borderColor = [UIColor colorWithRGBHex:0xe2e6e9].CGColor;
        _searchContainer.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _searchContainer.layer.cornerRadius = 15;
        _searchContainer.hidden = NO;
        _searchContainer.alpha = 1.0f;
        
        [_searchContainer addSubview:self.searchBar];
    }
    return _searchContainer;
}

- (UIImageView *)searchIcon {
    if (!_searchIcon) {
        _searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"magnifying-glass-off"]];
    }
    return _searchIcon;
}

- (SPCSearchTextField *)searchBar {
    if (!_searchBar) {
        _searchBar = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.searchContainer.frame) - 20, 30)];
        _searchBar.delegate = self;
        _searchBar.backgroundColor = [UIColor clearColor];
        _searchBar.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _searchBar.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _searchBar.font = [UIFont spc_mediumSystemFontOfSize:14];
        _searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
        _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        _searchBar.leftView.tintColor = [UIColor whiteColor];
        _searchBar.placeholder = @"Search nearby venues...";
        _searchBar.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
        
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
        [leftView addSubview:self.searchIcon];
        self.searchIcon.center = CGPointMake(CGRectGetWidth(leftView.bounds)/2.0 + 2, CGRectGetHeight(leftView.bounds)/2.0);
        _searchBar.leftView = leftView;
    }
    return _searchBar;
    
}

-(UIButton *)hideLocationBtn {
    if (!_hideLocationBtn) {
        _hideLocationBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.view.frame) - 160, CGRectGetMaxY(self.view.frame) - 47, 150, 37)];
        _hideLocationBtn.backgroundColor = [UIColor colorWithWhite:235.0f/255.0f alpha:1.0f];
        _hideLocationBtn.hidden = YES;
        _hideLocationBtn.layer.cornerRadius = 2;
        [_hideLocationBtn setTitle:@"Hide Location" forState:UIControlStateNormal];
        [_hideLocationBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _hideLocationBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
       
        // - TODO Update when desired behavior here has been defined
        //[_hideLocationBtn addTarget:self.delegate action:@selector(toggleLocationVisibility:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _hideLocationBtn;
}

- (UIView *)plusBottomOverlayButton {
    if (!_plusBottomOverlayButton) {
        UIButton *plusBottomOverlayButton = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 45, CGRectGetWidth(self.view.frame), 45)];
        plusBottomOverlayButton.backgroundColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:0.9f];
        
        UIView *verticalLineForPlus = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, 16)];
        [verticalLineForPlus setBackgroundColor:[UIColor whiteColor]];
        [verticalLineForPlus setCenter:CGPointMake(CGRectGetMidX(plusBottomOverlayButton.frame), CGRectGetHeight(plusBottomOverlayButton.frame)/2)];
        
        UIView *horizontalLineForPlus = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 2)];
        [horizontalLineForPlus setBackgroundColor:[UIColor whiteColor]];
        [horizontalLineForPlus setCenter:CGPointMake(CGRectGetMidX(plusBottomOverlayButton.frame), CGRectGetHeight(plusBottomOverlayButton.frame)/2)];
        
        [plusBottomOverlayButton addSubview:verticalLineForPlus];
        [plusBottomOverlayButton addSubview:horizontalLineForPlus];
        
        [plusBottomOverlayButton addTarget:self action:@selector(userDidTapCreateVenue:) forControlEvents:UIControlEventTouchUpInside];
        
        _plusBottomOverlayButton = plusBottomOverlayButton;
    }
    return _plusBottomOverlayButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        CGFloat yOrigin = CGRectGetMaxY(self.segControlContainer.frame) + 40;
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, yOrigin, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - yOrigin)];
        tableView.backgroundColor = [UIColor colorWithRGBHex:0xe6e7e7];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView = tableView;
        _tableView.hidden = NO;
        _tableView.alpha = 1.0f;
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.plusBottomOverlayButton.frame), 0);
    }
    return _tableView;
}

- (void) configureTableView {
    [self.tableView registerClass:[SPCChangeLocationCell class] forCellReuseIdentifier:CellIdentifier];
}

- (CLLocation *)currentLocation {
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        LocationManager *locationManager = [LocationManager sharedInstance];
        
        if (locationManager.userHasTempSelectedLocation) {
            return locationManager.tempMemLocation;
        }
        else {
            if (locationManager.userManuallySelectedLocation) {
                return locationManager.manualLocation;
            }
            else {
                return locationManager.currentLocation;
            }
        }
    }
    else {
        return [[CLLocation alloc] initWithLatitude:0 longitude:0];
    }
}


- (Venue *)makeDraggableVenueAt:(CLLocationCoordinate2D)location {
    Venue * venue = [[Venue alloc] init];
    venue.customName = @"Loading data, Please wait...";
    venue.latitude = [NSNumber numberWithFloat:location.latitude];
    venue.longitude = [NSNumber numberWithFloat:location.longitude];
    venue.totalMemories = -1;
    venue.totalStars = -1;
    venue.locationId = VENUE_PLACEHOLDER_LOCATION_ID;
    
    return venue;
}


- (void)updateMemoryVenue:(Venue *)venue {
    // move the memory here!
    if (venue.addressId == self.memory.venue.addressId) {
        // confirmed the same venue...
        [self dismissViewController:self];
    } else if (venue.addressId) {
        // has a location Id, but not the same as the original.
        self.view.userInteractionEnabled = NO;
        [MeetManager updateMemoryWithMemoryId:self.memory.recordID addressId:venue.addressId resultCallback:^(NSDictionary *results) {
            self.view.userInteractionEnabled = YES;
            
            BOOL success = 1 == [results[@"number"] intValue];
            if (success) {
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
                
                if ([self.delegate respondsToSelector:@selector(didAdjustLocationForMemory:)]) {
                    [self.delegate didAdjustLocationForMemory:self.memory];
                } else {
                    [self dismissViewController:self];
                }
            }
        } faultCallback:^(NSError *fault) {
            NSLog(@"Error updating venue... but why?");
            self.view.userInteractionEnabled = YES;
        }];
    } else {
        NSLog(@"Attempt to confirm venue with no addressId!");
    }
}


#pragma mark - Mutators


- (void)setSelectedVenue:(Venue *)selectedVenue {
    _selectedVenue = selectedVenue;
    [self highlightVenueAsCurrentlySelected:selectedVenue];
}


#pragma mark - SPCGoogleMapInfoViewSupportDelegateDelegate

-(CGFloat)mapView:(GMSMapView *)mapView calloutHeightForMarker:(SPCMarker *)marker {
    return [self.mapDataSource infoWindowHeightForMarker:marker mapView:mapView];
}

-(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker {
    return [self.mapDataSource getInfoWindowForMarker:marker mapView:mapView];
}

-(BOOL) mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker {
    
    SPCMarkerVenueData *venueData = (SPCMarkerVenueData *)marker.userData;
    Venue * venue = venueData.venue;
    
    if (!self.memory) {
        //reset other markers
        [self highlightMarkerAsCurrentlySelected:marker];
        
        // inform the delegate
        if ([self.delegate respondsToSelector:@selector(updateLocation:)]) {
           [self.delegate updateLocation:venue];
        }
        return YES;
    } else {
        [self updateMemoryVenue:venue];
    }
    return YES;
}

-(void) highlightVenueAsCurrentlySelected:(Venue *)venue {
    for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
        SPCMarkerVenueData *venueData = marker.userData;
        for (Venue *aVenue in venueData.venues) {
            if ([SPCMapDataSource venue:venue is:aVenue]) {
                [self highlightMarkerAsCurrentlySelected:marker];
                return;
            }
        }
    }
}

-(void) highlightMarkerAsCurrentlySelected:(SPCMarker *)marker {
    for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
        marker.icon = marker.nonSelectedIcon;
        marker.zIndex = 1;
    }
    
    //highlight tapped marker
    marker.icon = marker.selectedIcon;
    marker.zIndex = 2;
    
    //update the camera
    CLLocationCoordinate2D newCenter = marker.position;
    GMSCameraPosition *camera;
    camera = [GMSCameraPosition cameraWithLatitude:newCenter.latitude
                                         longitude:newCenter.longitude zoom:18
                                           bearing:0 viewingAngle:15];
    
    self.mapView.camera = camera;
}

-(void) selectMarker:(id)marker {
    [self.mapViewSupportDelegate selectMarker:(SPCMarker *)marker withMapView:self.mapView];
}

-(void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    
}

-(BOOL) mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    // respond...?
    return NO;
}

-(void) mapView:(GMSMapView *)mapView didEndDraggingMarker:(SPCMarker *)marker {
    self.draggedToCoordinate = marker.position;
    self.draggedToVenue = [self makeDraggableVenueAt:self.draggedToCoordinate];
    [self.mapDataSource configureMarker:marker withStackAtDeviceAndCurrentVenue:self.draggedToVenue reposition:NO];
    
    // start a delayed load for this venue's true data
    CLLocation *location = [[CLLocation alloc] initWithLatitude:marker.position.latitude longitude:marker.position.longitude];
    [self performSelector:@selector(fetchAddressIfMarkerPosition:) withObject:location afterDelay:5.0f];
    
    // either way, show the marker label again
    self.mapView.selectedMarker = marker;
}

#pragma mark - Private

- (void)showCurrentLocationRegion {
    
    float zoom = 18;
    
    CLLocationCoordinate2D center = self.mapDataSource.currentVenue ? self.selectedVenue.location.coordinate : self.currentLocation.coordinate;
    
    if (self.memory && self.memory.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
        zoom  = 14;
        CLLocation *venLocation = [[CLLocation alloc] initWithLatitude:self.memory.location.latitude.floatValue
                                                         longitude:self.memory.location.longitude.floatValue];
        center = venLocation.coordinate;
    }
    if (self.memory && self.memory.venue.specificity == SPCVenueIsFuzzedToCity) {
        zoom  = 10;
        CLLocation *venLocation = [[CLLocation alloc] initWithLatitude:self.memory.location.latitude.floatValue
                                                             longitude:self.memory.location.longitude.floatValue];
        center = venLocation.coordinate;
        
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

- (void)updateMapMarkers {
    [self.mapView clear];    
    
    // Venue markers...
    __block BOOL hasCurrent = NO;
    [self.mapDataSource.stackedVenueMarkers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SPCMarker *marker = (SPCMarker *)obj;
        marker.zIndex = 1;
        marker.map = self.mapView;
        
        SPCMarkerVenueData *venueData = marker.userData;
        if (venueData.isCurrentUserLocation) {
            marker.zIndex = 2;
            hasCurrent = YES;
        }
    }];
    
    // and the "current position" marker
    if (!hasCurrent) {
        SPCMarker *marker = [SPCMarkerVenueData markerWithCurrentVenue:self.selectedVenue];
        marker.zIndex = 2;
        marker.map = self.mapView;
    }
    
    // Place our location marker...
    /*
    if (self.mapDataSource.deviceLocationMarker) {
        SPCMarker * marker = self.mapDataSource.deviceLocationMarker;
        marker.zIndex = 0;
        marker.map = self.mapView;
    }
    */
    
    // create the draggable marker
    // REMOVED by PC's request 8/18/14
    /*
    if (!self.draggedToVenue) {
        CLLocation * location;
        if (self.hasDraggedToCoordinate) {
            location = [[CLLocation alloc] initWithLatitude:self.draggedToCoordinate.latitude longitude:self.draggedToCoordinate.longitude];
        } else {
            if ([LocationManager sharedInstance].userHasTempSelectedLocation) {
                location = [LocationManager sharedInstance].tempMemLocation;
            } else {
                location = [LocationManager sharedInstance].currentLocation;
            }
        }
        self.draggedToVenue = [self makeDraggableVenueAt:location.coordinate];
        [self performSelector:@selector(fetchAddressIfMarkerPosition:) withObject:location afterDelay:4.0f];
    }
    self.draggableMarker = [self.mapDataSource markerWithStackAtDeviceAndCurrentVenue:self.draggedToVenue];
    self.draggableMarker.draggable = YES;
    self.draggableMarker.zIndex = 2;
    self.draggableMarker.map = self.mapView;
     */
    
    // A hack to allow the markers to become immediately tappable.  Without this line,
    // markers may only be tapped once the user scrolls the map.
    [self.mapView performSelector:@selector(setCamera:) withObject:self.mapView.camera afterDelay:0.2f];
}

- (void)showList {
    self.tableView.hidden = NO;
    self.searchContainer.hidden = NO;
    
    [UIView animateWithDuration:0.2f animations:^{
        
        self.tableView.alpha = 1.0f;
        self.searchContainer.alpha = 1.0f;
        self.mapView.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
        self.mapView.hidden = YES;
        
    }];
    
//    [UIView transitionWithView:self.view duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
//        
//        self.tableView.alpha = 1.0f;
//        self.searchContainer.alpha = 1.0f;
//        self.mapView.alpha = 0.0f;
//        
//    } completion:^(BOOL finished) {
//        
//        self.mapView.hidden = YES;
//        
//    }];
}

- (void)showMap {
    self.mapView.hidden = NO;
    
    [UIView animateWithDuration:0.2f animations:^{
        
        self.mapView.alpha = 1.0f;
        self.tableView.alpha = 0.0f;
        self.searchContainer.alpha = 0.0f;
        
    } completion:^(BOOL finished) {
        
        self.tableView.hidden = YES;
        self.searchContainer.hidden = YES;
        
    }];
    
//    [UIView transitionWithView:self.view duration:0.3f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
//        
//        self.mapView.alpha = 1.0f;
//        self.tableView.alpha = 0.0f;
//        self.searchContainer.alpha = 0.0f;
//        
//    } completion:^(BOOL finished) {
//        
//        self.tableView.hidden = YES;
//        self.searchContainer.hidden = YES;
//        
//    }];
}


#pragma mark - Actions

- (void)registerForNotifications {
    if (!self.memory) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchVenuesFromCache) name:SPCLocationContentNearbyVenuesUpdatedFromServer object:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchVenuesFromCache) name:@"reloadLocations" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdatedOrCreatedLocation:) name:kSPCDidPostVenue object:nil];
}


- (void)reloadListDataWithSearch:(NSString *)search {
    if (search == self.searchBar.text || [self.searchBar.text isEqualToString:search]) {
        // First, determine the appropriate list of venues to display.  We already
        // have a sorted list of venues, so this amounts to applying the search filter
        // (if any) to reduce this list.
        self.filteredVenues = [self filterVenues:self.venues withSearchTerm:search];
    } else {
        self.filteredVenues = self.filteredVenues ?: self.venues;
    }
    
    self.filteredVenues = [self.filteredVenues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayNameTitle" ascending:YES]]];
    self.filteredVenues = [self.filteredVenues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"specificity" ascending:NO]]];
    
    // The rest of the work is done by our table delegate methods.
    if (_tableView) {
        [self.tableView reloadData];
    }
}

-(NSArray *)filterVenues:(NSArray *)venues withSearchTerm:(NSString *)searchTerm {
    if (!searchTerm || searchTerm.length == 0) {
        return venues;
    }
    
    NSMutableArray *mut = [[NSMutableArray alloc] initWithCapacity:venues.count];
    for (Venue *venue in venues) {
        if ([self venue:venue matchesSearchText:searchTerm]) {
            [mut addObject:venue];
        }
    }
    return [NSArray arrayWithArray:mut];
}

-(void)performFullSearchFor:(NSString *)searchText {
    if (searchText == self.searchBar.text || [self.searchBar.text isEqualToString:searchText]) {
        if (searchText && searchText.length > 0) {
            SPCMarker *bestMarker = nil;
            CGFloat bestVenueDist = -1;
            BOOL bestExactMatch = NO;

            CLLocation * location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
            if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
//                CLLocation *location = [LocationManager sharedInstance].currentLocation;
            }
            for (SPCMarker *marker in self.mapDataSource.stackedVenueMarkers) {
                SPCMarkerVenueData *venueData = marker.userData;
                for (Venue *venue in venueData.venues) {
                    BOOL match = [self venue:venue matchesSearchText:searchText];
                    BOOL exactMatch = match && [self venue:venue matchesSearchTextExactly:searchText];
                    if (match && (exactMatch || !bestExactMatch)) {
                        CGFloat dist = (location && venue.location) ? [location distanceFromLocation:venue.location] : INT_MAX;
                        if (!bestMarker || !location || dist < bestVenueDist) {
                            bestMarker = marker;
                            bestVenueDist = dist;
                            bestExactMatch = exactMatch;
                        }
                    }
                }
            }
            
            if (bestMarker && self.mapView.selectedMarker != bestMarker) {
                // focus and select?
                [self.mapViewSupportDelegate mapView:self.mapView didTapMarker:bestMarker];
                if (self.mapView.selectedMarker != bestMarker) {
                    [self.mapViewSupportDelegate selectMarker:bestMarker withMapView:self.mapView];
                    [self.mapView animateToLocation:bestMarker.position];
                }
            }
        } else {
            [self.mapViewSupportDelegate selectMarker:nil withMapView:self.mapView];
        }
    }
    
    [self reloadListDataWithSearch:searchText];
}

-(BOOL)venue:(Venue *)venue matchesSearchTextExactly:(NSString *)searchText {
    // match name!  A venue name is a match if venue name or
    // address name matches the string, i.e. it contains the string
    // in a case-insensitive format.
    NSString * venueName = venue.venueName;
    NSString * address = venue.streetAddress;
    NSString * title = venue.displayNameTitle;
    
    BOOL include = venueName && [venueName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
    include = include || (address && [address rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
    include = include || (title && [title rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
    
    return include;
}

-(BOOL)venue:(Venue *)venue matchesSearchText:(NSString *)searchText {
    BOOL match = YES;
    if (searchText) {
        NSArray *wordsAndEmptyStrings = [searchText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *words = [wordsAndEmptyStrings filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        for (NSString * word in words) {
            match = match && [self venue:venue matchesSearchTextExactly:word];
        }
    }

    return match;
}

- (void)refreshVenues {
    [self fetchNearbyLocations:NO];
}

- (void)fetchNearbyLocations:(BOOL)manualRefresh {
    if (self.performingRefresh) {
        return;
    }
    
    // Update map region
    [self showCurrentLocationRegion];
    
    // Hide the refresh button
    self.refreshButton.hidden = YES;
    self.performingRefresh = YES;
   
    if (!self.memory) {
        // load locations around the user's current location
        [[LocationManager sharedInstance] waitForUptime:MINIMUM_LOCATION_MANAGER_UPTIME withSuccessCallback:^(NSTimeInterval uptime) {
            [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue,SPCLocationContentFuzzedVenue, SPCLocationContentNearbyVenues] resultCallback:^(NSDictionary *results) {
                
                [self updateWithLocationContentResults:results manualRefresh:manualRefresh];
                self.refreshButton.hidden = NO;
                self.performingRefresh = NO;
                self.locationLoader.alpha = 0;
                [self.locationLoader stopAnimating];
            } faultCallback:^(NSError *fault) {
                // TODO: Show error table view cell
                // No nearby locations found
                NSLog(@"error fetching nearby locations: %@", fault);
                [self showCurrentLocationRegion];
                
                self.refreshButton.hidden = NO;
                self.performingRefresh = NO;
                self.locationLoader.alpha = 0;
                [self.locationLoader stopAnimating];

            }];
        } faultCallback:^(NSError *error) {
            // TODO: Show error table view cell
            // No nearby locations found
            NSLog(@"error waiting for uptime: %@", error);
            [self showCurrentLocationRegion];
            self.refreshButton.hidden = NO;
            self.performingRefresh = NO;
            self.locationLoader.alpha = 0;
            [self.locationLoader stopAnimating];

        }];
    } else {
        // load locations around the memory's latitude / longitude
        [[VenueManager sharedInstance] fetchVenueAndNearbyVenuesWithGoogleHintAtLatitude:self.memory.location.latitude.floatValue longitude:self.memory.location.longitude.floatValue rateLimited:YES resultCallback:^(Venue *venue, NSArray *venues,Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue) {
            
            Venue *fuzzedVenue;

            if (fuzzedCityVenue) {
                fuzzedVenue = fuzzedCityVenue;
            }
            if (fuzzedNeighborhoodVenue) {
                fuzzedVenue = fuzzedNeighborhoodVenue;
            }
            
            [self updateWithNearbyVenueResults:venues fuzzedVenue:fuzzedVenue];
            self.fuzzedVenue = fuzzedVenue;
            self.performingRefresh = NO;
            self.locationLoader.alpha = 0;
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            // TODO: Show error table view cell
            // No nearby locations found
            NSLog(@"error fetching venue list from server: %@", fault);
            [self showCurrentLocationRegion];
            self.performingRefresh = NO;
            self.locationLoader.alpha = 0;
            [self.locationLoader stopAnimating];
        }];
    }
}

- (void)fetchVenuesFromCache {
    if (self.performingRefresh || !_mapView) {
        return;
    }
    
    [[LocationContentManager sharedInstance] getContentFromCache:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue, SPCLocationContentFuzzedVenue, SPCLocationContentNearbyVenues] resultCallback:^(NSDictionary *results) {
        
        [self updateWithLocationContentResults:results manualRefresh:NO];
    } faultCallback:^(NSError *fault) {
        // TODO: Show error table view cell
        // No nearby locations found
        NSLog(@"error fetching nearby locations from cache!");
    }];
}

- (BOOL)updateWithLocationContentResults:(NSDictionary *)results manualRefresh:(BOOL)manualRefresh {
    Venue *deviceVenue = (Venue *)results[SPCLocationContentDeviceVenue];
    BOOL hasDevice = NO;
    BOOL hasSelected = NO;
    NSArray *nearbyVenues = results[SPCLocationContentNearbyVenues];
    for (Venue *venue in nearbyVenues) {
        if ([SPCMapDataSource venue:venue is:deviceVenue]) {
            hasDevice = YES;
        }
        if (self.selectedVenue && [SPCMapDataSource venue:venue is:self.selectedVenue]) {
            hasSelected = YES;
        }
    }
    
    if (!hasDevice) {
        nearbyVenues = [nearbyVenues arrayByAddingObject:deviceVenue];
    } else {
        nearbyVenues = [NSArray arrayWithArray:nearbyVenues];
    }
    [self.mapDataSource setAsVenueStacksWithVenues:nearbyVenues atCurrentVenue:(hasSelected ? self.selectedVenue : nil) deviceVenue:nil];
    [self showCurrentLocationRegion];
    [self updateMapMarkers];
    
    NSMutableArray *nearbyAndFuzzedVenues = [NSMutableArray arrayWithArray:nearbyVenues];
    
    if ((Venue *)results[SPCLocationContentFuzzedVenue]) {
        Venue *fuzzedVenue = (Venue *)results[SPCLocationContentFuzzedVenue];
        NSLog(@"got a fuzzed venue in city:%@",fuzzedVenue.city);
        [nearbyAndFuzzedVenues insertObject:fuzzedVenue atIndex:0];
    }
    
    self.venues = nearbyAndFuzzedVenues;
    
    //determine memory counts for gold, silver and bronze stars.
    NSMutableArray * memoryCounts = [NSMutableArray arrayWithCapacity:self.venues.count];
    for (Venue * venue in self.venues) {
        [memoryCounts addObject:@(venue.totalMemories)];
    }
    
    // sort the stacked memory counts: we use this to determine gold, silver
    // and bronze stars.
    NSArray * sortedMemoryCounts = [memoryCounts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"integerValue" ascending:NO]]];
    // Use selector, not indexing, in case we have a list of length 0.
    self.memoryCountGold = sortedMemoryCounts.count > 0 ? [sortedMemoryCounts[0] integerValue] : 0;
    self.memoryCountSilver = sortedMemoryCounts.count > 1 ? [sortedMemoryCounts[1] integerValue] : 0;
    self.memoryCountBronze = sortedMemoryCounts.count > 2 ? [sortedMemoryCounts[2] integerValue] : 0;
    
    self.filteredVenues = [NSArray arrayWithArray:nearbyVenues];
    [self reloadListDataWithSearch:self.searchBar.text];
    
    // Do NOT update the currently selected venue as a result of this
    // refresh.  Just refreshing things here doesn't make a difference in
    // terms of our "current" venue.
    
    return !hasSelected;
}


- (void)updateWithNearbyVenueResults:(NSArray *)venues fuzzedVenue:(Venue *)fuzzedVenue {
    BOOL hasSelected = NO;
    for (Venue *venue in venues) {
        if (self.selectedVenue && [SPCMapDataSource venue:venue is:self.selectedVenue]) {
            hasSelected = YES;
        }
    }
    
    if (!hasSelected) {
        venues = [venues arrayByAddingObject:self.selectedVenue];
    }
    
    // only allow movement of up to ADJUST_MEMORY_RADIUS
    NSMutableArray *nearbyVenues = [NSMutableArray arrayWithCapacity:venues.count];
    CLLocation *memoryLocation = [[CLLocation alloc] initWithLatitude:self.memory.location.latitude.doubleValue longitude:self.memory.location.longitude.doubleValue];
    for (Venue *venue in venues) {
        if ([venue.location distanceFromLocation:memoryLocation] < ADJUST_MEMORY_RADIUS) {
            [nearbyVenues addObject:venue];
        }
    }
    venues = [NSArray arrayWithArray:nearbyVenues];
    
    [self.mapDataSource setAsVenueStacksWithVenues:venues atCurrentVenue:self.selectedVenue deviceVenue:nil];
    [self showCurrentLocationRegion];
    [self updateMapMarkers];
    
    if (fuzzedVenue) {
        NSLog(@"got a fuzzed venue in city:%@",fuzzedVenue.city);
        [nearbyVenues insertObject:fuzzedVenue atIndex:0];
    }
    
    self.venues = [NSArray arrayWithArray:nearbyVenues];
    
    //determine memory counts for gold, silver and bronze stars.
    NSMutableArray * memoryCounts = [NSMutableArray arrayWithCapacity:self.venues.count];
    for (Venue * venue in self.venues) {
        [memoryCounts addObject:@(venue.totalMemories)];
    }
    
    // sort the stacked memory counts: we use this to determine gold, silver
    // and bronze stars.
    NSArray * sortedMemoryCounts = [memoryCounts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"integerValue" ascending:NO]]];
    // Use selector, not indexing, in case we have a list of length 0.
    self.memoryCountGold = sortedMemoryCounts.count > 0 ? [sortedMemoryCounts[0] integerValue] : 0;
    self.memoryCountSilver = sortedMemoryCounts.count > 1 ? [sortedMemoryCounts[1] integerValue] : 0;
    self.memoryCountBronze = sortedMemoryCounts.count > 2 ? [sortedMemoryCounts[2] integerValue] : 0;
    
    self.filteredVenues = [NSArray arrayWithArray:nearbyVenues];
    [self reloadListDataWithSearch:self.searchBar.text];
}

- (void)dismissViewController:(id)sender {
    
    if ([self.delegate respondsToSelector:@selector(cancelMap)]) {
        [self.delegate cancelMap];
    }
}

- (void)userDidSelectVenue:(Venue *)venue fromStack:(NSInteger)stack withMarker:(SPCMarker *)marker {
    if (!self.memory) {
        if ([self.delegate respondsToSelector:@selector(updateLocation:)]) {
            if (venue) {
                [self.delegate updateLocation:venue];
            } else {
                // Fetch location data for these coordinates.
                [[VenueManager sharedInstance] fetchVenueWithGoogleHintAtLatitude:marker.position.latitude longitude:marker.position.longitude rateLimited:YES resultCallback:^(Venue * venue) {
                    // include current latitude / longitude
                    venue.latitude = [NSNumber numberWithFloat:marker.position.latitude];
                    venue.longitude = [NSNumber numberWithFloat:marker.position.longitude];
                    
                    if ([self.delegate respondsToSelector:@selector(updateLocation:)]) {
                        [self.delegate updateLocation:venue];
                    } else {
                        [self dismissViewController:self];
                    }
                } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
                    [MeetManager fetchDefaultLocationNameWithLat:marker.position.latitude longitude:marker.position.longitude
                                                  resultCallback:^(NSDictionary *resultsDic) {
                                                      NSString *defaultAddress = resultsDic[@"name"];
                                                      if (resultsDic[@"addressName"]){
                                                          defaultAddress = resultsDic[@"addressName"];
                                                      }
                                                      if (resultsDic[@"locationName"]){
                                                          defaultAddress = resultsDic[@"locationName"];
                                                      }
                                                      NSString *addressIdStr = resultsDic[@"addressId"];
                                                      int addressId = [addressIdStr intValue];
                                                      
                                                      [MeetManager fetchCustomPlaceName:addressId
                                                                         resultCallback:^(NSDictionary *customLocation) {
                                                                             NSString *customName = customLocation[@"customLocationName"];
                                                                             
                                                                             Venue *v = [[Venue alloc] init];
                                                                             v.addressId = addressId;
                                                                             v.defaultName = defaultAddress;
                                                                             v.customName = customName;
                                                                             v.latitude = [NSNumber numberWithFloat:marker.position.latitude];
                                                                             v.longitude = [NSNumber numberWithFloat:marker.position.longitude];
                                                                             
                                                                             if ([self.delegate respondsToSelector:@selector(updateLocation:)]) {
                                                                                 [self.delegate updateLocation:v];
                                                                             } else {
                                                                                 [self dismissViewController:self];
                                                                             }
                                                                         }
                                                                          faultCallback:^(NSError *error) {
                                                                              NSLog(@"fetch custom name fault callback");
                                                                              [self dismissViewController:self];
                                                                          }];
                                                  }
                                                   faultCallback:^(NSError *error) {
                                                       [self dismissViewController:self];
                                                   }];

                }];
            }
        }
    } else {
        if (venue) {
            [self updateMemoryVenue:venue];
        }
    }
}


-(void) fetchAddressIfMarkerPosition:(id)clLocation {
    CLLocation * location = (CLLocation *)clLocation;
    CLLocation * markerLocation = [[CLLocation alloc] initWithLatitude:self.draggableMarker.position.latitude longitude:self.draggableMarker.position.longitude];
    
    BOOL latitudeMatch = abs(location.coordinate.latitude - markerLocation.coordinate.latitude) < 0.000001;
    BOOL longitudeMatch = abs(location.coordinate.longitude - markerLocation.coordinate.longitude) < 0.000001;

    // compare for an exact result
    if (latitudeMatch && longitudeMatch && self.draggedToVenue.locationId == VENUE_PLACEHOLDER_LOCATION_ID) {
        [[VenueManager sharedInstance] fetchGoogleAddressVenueAtLatitude:location.coordinate.latitude longitude:location.coordinate.longitude resultCallback:^(Venue *venue) {
            CLLocation * markerLocationNow = [[CLLocation alloc] initWithLatitude:self.draggableMarker.position.latitude longitude:self.draggableMarker.position.longitude];
            BOOL latitudeMatchNow = abs(location.coordinate.latitude - markerLocationNow.coordinate.latitude) < 0.000001;
            BOOL longitudeMatchNow = abs(location.coordinate.longitude - markerLocationNow.coordinate.longitude) < 0.000001;
            if (latitudeMatchNow && longitudeMatchNow && self.draggedToVenue.locationId == VENUE_PLACEHOLDER_LOCATION_ID) {
                // Got it!  Configure bizatch!
                self.draggedToVenue = venue;
                [self.mapDataSource configureMarker:self.draggableMarker withStackAtDeviceAndCurrentVenue:self.draggedToVenue reposition:NO];
                [self.mapDataSource refreshInfoWindowForMarker:self.draggableMarker];
            }
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            NSLog(@"TODO: update the info window (if displayed) to represent the error.");
        }];
    }
}

- (void)userDidTapCreateVenue:(id)sender {
    NSLog(@"userDidTapCreateVenue");
    SPCCreateVenueViewController *createVenueViewController = [[SPCCreateVenueViewController alloc] initWithNearbyVenues:self.venues];
    createVenueViewController.fromExplore = YES;
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:createVenueViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    navController.navigationBar.hidden = YES;
    
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    if (segmentedControl.selectedSegmentIndex == 0) {
        [self showList];
    }
    if (segmentedControl.selectedSegmentIndex == 1) {
        [self showMap];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // no change
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
  
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDefault) {
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(performFullSearchFor:) withObject:textField.text afterDelay:0.05];
        // resign
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (text.length > 0) {
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-blue"];
    } else {
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    }
    
    // Cancel previous filter request
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    // Schedule delayed filter request in order to allow textField to update it's internal state
    [self performSelector:@selector(reloadListDataWithSearch:) withObject:text afterDelay:0.2];
    
    return YES;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredVenues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCChangeLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Venue *venue = self.filteredVenues[indexPath.row];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        location = [LocationManager sharedInstance].currentLocation;
    }
    CGFloat distance = (location && venue.location) ? [location distanceFromLocation:venue.location] : -1;
    
    [cell configureCellWithVenue:venue distance:distance];
  
    NSInteger badges = 0;
    
    if (venue.totalMemories > 0) {
        if (venue.totalMemories == self.memoryCountGold) {
            badges |= spc_LOCATION_CELL_BADGE_GOLD_STAR;
        } else if (venue.totalMemories == self.memoryCountSilver) {
            badges |= spc_LOCATION_CELL_BADGE_SILVER_STAR;
        } else if (venue.totalMemories == self.memoryCountBronze) {
            badges |= spc_LOCATION_CELL_BADGE_BRONZE_STAR;
        }
    }
    
    cell.hasSeparator = (indexPath.row != 0);
    [cell setBadges:badges];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightRet = 70.0f;
    if ([self.filteredVenues count] > indexPath.row) {
        Venue *venue = self.filteredVenues[indexPath.row];
        if (SPCVenueIsFuzzedToCity == venue.specificity || SPCVenueIsFuzzedToNeighhborhood == venue.specificity) {
            heightRet = 90.0f;
        }
    }
    return heightRet;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Venue * venue = self.filteredVenues[indexPath.row];
    
    // inform the delegate
    if (!self.memory) {
        if ([self.delegate respondsToSelector:@selector(updateLocation:)]) {
            [self.delegate updateLocation:venue];
        }
    } else {
        [self updateMemoryVenue:venue];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
}

#pragma mark - User Posted Venue Notification

- (void)userUpdatedOrCreatedLocation:(NSNotification *)notification {
    Venue *venue = (Venue *)[notification object];
    if (nil != venue && !self.memory) {
        if ([self.delegate respondsToSelector:@selector(updateLocation:)]) {
            [self.delegate updateLocation:venue];
        }
    } else {
        [self updateMemoryVenue:venue];
    }
}


#pragma mark - close button

-(void)closeButtonActivated:(id)sender {
    // first: the user has released the button; change its color
    [self closeButtonReleased:sender];
    
    if ([self.delegate respondsToSelector:@selector(cancelMap)]) {
        [self.delegate cancelMap];
    } else if (nil != self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissViewController:self];
    }
}

-(void)closeButtonPressed:(id)sender {

}

-(void)closeButtonReleased:(id)sender {

}

-(void)refreshLocationButtonPressed:(id)sender {
    if (!self.performingRefresh) {
        self.locationLoader.alpha = 1;
        [self.locationLoader startAnimating];
        [[LocationContentManager sharedInstance] clearContentAndLocation];
        [self fetchNearbyLocations:YES];
    }
}


#pragma  mark - Orientation Methods

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

@end
