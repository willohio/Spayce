//
//  SPCFlyViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFlyViewController.h"

//manager
#import "MeetManager.h"
#import "VenueManager.h"
#import "AuthenticationManager.h"
#import "SPCRegionMemoriesManager.h"

//view
#import "SPCSearchTextField.h"
#import "SPCCitySearchResultCell.h"
#import "SPCSuggestionItemView.h"
#import "SPCEarthquakeLoader.h"
#import "SPCAnimationDelegate.h"

//controller
#import "SPCCustomNavigationController.h"
#import "SPCVenueDetailGridTransitionViewController.h"

//model
#import "SPCPeopleSearchResult.h"
#import "SPCMapDataSource.h"
#import "Memory.h"
#import "Location.h"

// Category
#import "UIViewController+SPCAdditions.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>
#import "Flurry.h"


static const NSInteger FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES = 8;

static const NSTimeInterval FLY_EXPLORE_DISPLAY_MEMORY_FOR = 5.0f;

static const NSTimeInterval FLY_EXPLORE_FADE_OUT_DURATION = 1.0f;
static const NSTimeInterval FLY_HIDE_MEMORY_AFTER_DISPLAY_DURATION = 60*10;  // 10 minutes
static const NSTimeInterval FLY_HIDE_MEMORY_AFTER_TAP_DURATION = 60*10;    // 10 minutes



@interface ExploreMemory : NSObject

@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) GMSMarker *marker;
@property (nonatomic, strong) SPCMarkerVenueData *venueData;

@property (nonatomic, strong) CLLocation *location;

@property (nonatomic, strong) NSDate *displayedAtDate;

@property (nonatomic, assign) BOOL hasDisplayed;
@property (nonatomic, assign) BOOL hasDismissed;


- (instancetype)initWithMemory:(Memory *)memory marker:(GMSMarker *)marker;
@end

@implementation ExploreMemory

- (instancetype)initWithMemory:(Memory *)memory marker:(GMSMarker *)marker {
    self = [super init];
    if (self) {
        self.memory = memory;
        self.marker = marker;
        self.venueData = (SPCMarkerVenueData *)marker.userData;
        
        self.location = [[CLLocation alloc] initWithLatitude:marker.position.latitude longitude:marker.position.longitude];
    }
    return self;
}

- (void)setHasDisplayed:(BOOL)hasDisplayed {
    if (hasDisplayed && !_hasDisplayed) {
        self.displayedAtDate = [NSDate date];
    }
    _hasDisplayed = hasDisplayed;
}

@end


@interface SPCFlyViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, SPCGoogleMapInfoViewSupportDelegateDelegate>

// Nav
@property (nonatomic, strong) UIView *statusBar;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *backButton;


// Search
@property (nonatomic, strong) UIView *searchContainer;
@property (nonatomic, strong) SPCSearchTextField *textField;
@property (nonatomic, strong) UIImageView *searchIcon;
@property (nonatomic, strong) UIButton *resetSearchBtn;


// Content: search container
@property (nonatomic, strong) UIView *searchContentContainer;
@property (nonatomic, strong) UILabel *searchStatus;
// Content: search results
@property (nonatomic, strong) UITableView *tableView;
// Content: explore suggestions
@property (nonatomic, strong) UIView *suggestionsView;
@property (nonatomic, strong) UILabel *suggestionsHeader;
// Content: explore map
@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) SPCGoogleMapInfoViewSupportDelegate *mapViewSupportDelegate;
@property (nonatomic, readonly) GMSCoordinateBounds *mapViewCoordinateBounds;
@property (nonatomic, readonly) GMSCoordinateBounds *mapViewExtendedCoordinateBounds;
@property (nonatomic, strong) GMSCoordinateBounds *mapViewCoordinateBoundsOnDragStart;
@property (nonatomic, strong) GMSCoordinateBounds *mapViewExtendedCoordinateBoundsOnDragStart;
// Content: loader
@property (nonatomic, strong) SPCEarthquakeLoader *earthquakeLoader;

// Global state
@property (nonatomic, assign) FlyState flyState;
@property (nonatomic, readonly) BOOL showExploreMemories;
@property (nonatomic, assign) BOOL viewDidAppear;

// Searching
@property (nonatomic, strong) NSOperationQueue *searchOperationQueue;
@property (nonatomic, assign) BOOL isLoadingCurrentData;
@property (nonatomic, strong) NSArray *searchResults;

// Suggestions
@property (nonatomic, strong) NSArray *suggestedVenues;
@property (nonatomic, assign) BOOL initialSuggestionsSet;
@property (nonatomic, assign) BOOL fetchingSuggestions;

// Explore
@property (nonatomic, strong) NSArray *exploreMemoriesDisplayed;
@property (nonatomic, strong) NSArray *exploreMemoriesLoaded;
@property (nonatomic, strong) NSDate *exploreMemoryLastDismissed;
@property (nonatomic, assign) BOOL exploreMemoryFetchInProgress;
@property (nonatomic, strong) NSTimer *exploreRefreshTimer;
@property (nonatomic, strong) NSTimer *exploreDisplayTimer;
// Explored territory
@property (nonatomic, strong) SPCCity *exploreTerritoryCity;
@property (nonatomic, strong) SPCNeighborhood *exploreTerritoryNeighborhood;
@property (nonatomic, strong) NSString *exploreTerritoryNextPageKey;
@property (nonatomic, assign) NSInteger exploreTerritoryPagesFetched;
@property (nonatomic, assign) BOOL exploreTerritoryIsFocused;
@property (nonatomic, assign) NSInteger exploreTerritoryFlyNumber;
// No realtime memories
@property (nonatomic, strong) UIView *exploreMemoriesNoneHereLabel;



// Nav bar hiding / showing
@property (nonatomic, assign) float navBarOriginalCenterY;
@property (nonatomic, assign) float searchContainerOriginalCenterY;
@property (nonatomic, assign) float maxAdjustment;
@property (nonatomic, strong) UIButton *scrollToTopBtn;


// Geocoder
@property (nonatomic, strong) CLGeocoder *geocoder;


@end


@implementation SPCFlyViewController

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.exploreRefreshTimer invalidate];
    self.exploreRefreshTimer = nil;
    [self.exploreDisplayTimer invalidate];
    self.exploreDisplayTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.mapView];
    [self.view addSubview:self.searchContentContainer];
    [self.view addSubview:self.statusBar];
    [self.view addSubview:self.searchContainer];
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.earthquakeLoader];
    [self.view addSubview:self.scrollToTopBtn];
    
    [self.view addSubview:self.exploreMemoriesNoneHereLabel];
    [self refreshSuggestionsIfNeeded];
    
    self.flyState = FlyStateSearch;
    [self resetSearch];
    [self reloadSearchResults];
    [self showSuggestions];
    
    self.searchContentContainer.hidden = NO;
    self.searchContentContainer.frame = self.mapView.frame;
        
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    
    self.navBarOriginalCenterY = _navBar.center.y;
    self.searchContainerOriginalCenterY = _searchContainer.center.y;
    self.maxAdjustment = CGRectGetHeight(_navBar.frame) + CGRectGetHeight(_searchContainer.frame);
    
    // Timers!
    self.exploreRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:61.23f target:self selector:@selector(exploreRefreshTimerDidTrigger) userInfo:nil repeats:YES];
    self.exploreDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:FLY_EXPLORE_DISPLAY_MEMORY_FOR target:self selector:@selector(exploreDisplayTimerDidTrigger) userInfo:nil repeats:YES];
    
    // Geocoder!
    self.geocoder = [[CLGeocoder alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //hide tab bar
    self.tabBarController.tabBar.alpha = 0.0;
    
    // Refresh suggestions?
    [self refreshSuggestionsIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewDidAppear = YES;
    // update the display time of all displayed memories
    for (ExploreMemory *exploreMemory in self.exploreMemoriesLoaded) {
        if (exploreMemory.hasDisplayed) {
            exploreMemory.displayedAtDate = [NSDate date];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.viewDidAppear = NO;
}


#pragma mark - Accessors

- (UIView *)statusBar {
    if (!_statusBar) {
        _statusBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 20)];
        _statusBar.backgroundColor = [UIColor whiteColor];
    }
    return _statusBar;
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
        titleLabel.text = NSLocalizedString(@"Fly", nil);
        
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(-1.0, 18.0, 65.0, 50.0)];
        _backButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        _backButton.layer.cornerRadius = 2;
        _backButton.backgroundColor = [UIColor clearColor];
        [_backButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [_backButton setTitleColor:[UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:.7f] forState:UIControlStateHighlighted];
        [_backButton setTitle:@"Back" forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(closeButtonActivated:) forControlEvents:UIControlEventTouchUpInside];
        [_navBar addSubview:_backButton];
        
        [_navBar addSubview:titleLabel];
    }
    return _navBar;
    
}

- (UIView *)searchContainer {
    
    if (!_searchContainer) {
        _searchContainer = [[UIView alloc] initWithFrame:CGRectMake(-2, CGRectGetMaxY(self.navBar.frame), self.view.bounds.size.width+4, 45)];
        _searchContainer.backgroundColor = [UIColor whiteColor];
        _searchContainer.clipsToBounds = YES;
        
        [_searchContainer addSubview:self.textField];
        [_searchContainer addSubview:self.resetSearchBtn];
    }
    return _searchContainer;
}


- (UIImageView *)searchIcon {
    if (!_searchIcon) {
        _searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"magnifying-glass-off"]];
    }
    return _searchIcon;
}

- (SPCSearchTextField *)textField {
    if (!_textField) {
        // The x-coordinate of this field is 10pt to the right of the search Icon - iconOrigin.x + iconWidth + 10px spacing
        _textField = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(10, 5, CGRectGetWidth(self.searchContainer.frame) - 20, 30)];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _textField.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _textField.font = [UIFont spc_mediumSystemFontOfSize:14];
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        //_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.placeholder = @"Explore the world...";
        _textField.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
        _textField.layer.borderColor = [UIColor colorWithRGBHex:0xe2e6e9].CGColor;
        _textField.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _textField.layer.cornerRadius = 15;
        
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
        [leftView addSubview:self.searchIcon];
        self.searchIcon.center = CGPointMake(CGRectGetWidth(leftView.bounds)/2.0 + 2, CGRectGetHeight(leftView.bounds)/2.0);
        _textField.leftView = leftView;
    }
    return _textField;
}


- (UIButton *)resetSearchBtn {
    if (!_resetSearchBtn) {
        _resetSearchBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.textField.frame) - 44, -5, 50, 50)];
        [_resetSearchBtn setImage:[UIImage imageNamed:@"reset-search-btn"] forState:UIControlStateNormal];
        [_resetSearchBtn addTarget:self action:@selector(resetSearch) forControlEvents:UIControlEventTouchUpInside];
        _resetSearchBtn.hidden = YES;
    }
    return _resetSearchBtn;
}


- (UIView *)searchContentContainer {
    if (!_searchContentContainer) {
        _searchContentContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.searchContainer.frame))];
        _searchContentContainer.backgroundColor = [UIColor whiteColor];
        
        UIView *tableSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(self.tableView.frame), CGRectGetWidth(self.view.bounds), 1)];
        tableSeparator.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        
        [_searchContentContainer addSubview:self.tableView];
        [_searchContentContainer addSubview:tableSeparator];
        [_searchContentContainer addSubview:self.suggestionsView];
        [_searchContentContainer addSubview:self.searchStatus];
        
        
    }
    return _searchContentContainer;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 27, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.searchContentContainer.frame) - 27)];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor colorWithRGBHex:0xf0f1f1];
        _tableView.hidden = YES;
    }
    return _tableView;
}

- (UILabel *)searchStatus {
    if (!_searchStatus) {
        _searchStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, [UIFont spc_regularSystemFontOfSize:12].lineHeight)];
        _searchStatus.numberOfLines = 0;
        _searchStatus.textAlignment = NSTextAlignmentCenter;
        _searchStatus.font = [UIFont spc_regularSystemFontOfSize:12];
        _searchStatus.textColor = [UIColor colorWithRed:213.0f/255.0f green:218.0f/255.0f blue:223.0f/255.0f alpha:1.0f];
        _searchStatus.backgroundColor = [UIColor clearColor];
        _searchStatus.text = NSLocalizedString(@"Enter a city, neighborhood or school", nil);
    }
    return _searchStatus;
}



- (UIView *)suggestionsView {
    if (!_suggestionsView) {
        _suggestionsView = [[UIView alloc] initWithFrame:self.searchContentContainer.bounds];
        _suggestionsView.backgroundColor = [UIColor whiteColor];
        _suggestionsView.hidden = YES;
    
        [_suggestionsView addSubview:self.suggestionsHeader];
    }
    
    return _suggestionsView;
}

-(UILabel *)suggestionsHeader {
    if (!_suggestionsHeader) {
      
        float initialY = 60;
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            initialY = 90;
        }
        
        _suggestionsHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, initialY, _suggestionsView.frame.size.width, 20)];
        _suggestionsHeader.text = NSLocalizedString(@"Suggested Destinations", nil);
        _suggestionsHeader.font = [UIFont spc_boldSystemFontOfSize:14];
        _suggestionsHeader.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _suggestionsHeader.textAlignment = NSTextAlignmentCenter;
        _suggestionsHeader.hidden = YES;
    }
    return _suggestionsHeader;
}

-(GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.searchContainer.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.searchContainer.frame))];
        _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _mapView.userInteractionEnabled = YES;
        _mapView.settings.rotateGestures = NO;
        _mapView.settings.tiltGestures = NO;
        _mapView.buildingsEnabled = NO;
        
        _mapView.delegate = self.mapViewSupportDelegate;
        
        _mapView.hidden = YES;
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


- (GMSCoordinateBounds *)mapViewCoordinateBounds {
    // make a new one each time
    GMSProjection *projection = self.mapView.projection;
    CGPoint bottomLeft = CGPointMake(0, CGRectGetHeight(self.mapView.bounds));
    CGPoint topRight = CGPointMake(CGRectGetWidth(self.mapView.bounds), 0);
    return [[GMSCoordinateBounds alloc] initWithCoordinate:[projection coordinateForPoint:bottomLeft] coordinate:[projection coordinateForPoint:topRight]];
}

- (GMSCoordinateBounds *)mapViewExtendedCoordinateBounds {
    // make a new one each time
    GMSProjection *projection = self.mapView.projection;
    CGPoint bottomLeft = CGPointMake(-50, CGRectGetHeight(self.mapView.bounds)+50);
    CGPoint topRight = CGPointMake(CGRectGetWidth(self.mapView.bounds)+50, -50);
    return [[GMSCoordinateBounds alloc] initWithCoordinate:[projection coordinateForPoint:bottomLeft] coordinate:[projection coordinateForPoint:topRight]];
}


- (SPCEarthquakeLoader *)earthquakeLoader {
    if (!_earthquakeLoader) {
        _earthquakeLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.navBar.frame))];
        _earthquakeLoader.msgLabel.text = @"Flying...";
        _earthquakeLoader.hidden = YES;
        _earthquakeLoader.backgroundColor = [UIColor colorWithRGBHex:0xd0d1d1 alpha:0.8];
    }
    return _earthquakeLoader;
}

- (NSOperationQueue *)searchOperationQueue {
    if (!_searchOperationQueue) {
        _searchOperationQueue = [[NSOperationQueue alloc] init];
        _searchOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _searchOperationQueue;
}


- (NSArray *)exploreMemoriesDisplayed {
    if (!_exploreMemoriesDisplayed) {
        _exploreMemoriesDisplayed = [NSArray array];
    }
    return _exploreMemoriesDisplayed;
}


- (NSArray *)exploreMemoriesLoaded {
    if (!_exploreMemoriesLoaded) {
        _exploreMemoriesLoaded = [NSArray array];
    }
    return _exploreMemoriesLoaded;
}


- (UIView *)exploreMemoriesNoneHereLabel {
    if (!_exploreMemoriesNoneHereLabel) {
        _exploreMemoriesNoneHereLabel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 230, 50)];
        // Apply shadow
        _exploreMemoriesNoneHereLabel.layer.shadowColor = [UIColor blackColor].CGColor;
        _exploreMemoriesNoneHereLabel.layer.shadowOffset = CGSizeMake(0.0, 1);
        _exploreMemoriesNoneHereLabel.layer.shadowOpacity = 0.2f;
        _exploreMemoriesNoneHereLabel.layer.shadowRadius = 1.f;
        _exploreMemoriesNoneHereLabel.layer.shouldRasterize = YES;
        _exploreMemoriesNoneHereLabel.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        
        _exploreMemoriesNoneHereLabel.center = self.view.center;
        _exploreMemoriesNoneHereLabel.hidden = YES;
        _exploreMemoriesNoneHereLabel.alpha = 0.0;
        
        _exploreMemoriesNoneHereLabel.userInteractionEnabled = NO;
        
        // Drop shadow requires that we don't clip-to-bounds, but rounded
        // corners on a background requires that we do.  Use separate views.
        
        // Text
        UILabel *label = [[UILabel alloc] initWithFrame:_exploreMemoriesNoneHereLabel.bounds];
        label.backgroundColor = [UIColor whiteColor];
        label.layer.cornerRadius = 5;
        label.clipsToBounds = YES;
        label.font = [UIFont spc_regularSystemFontOfSize:14];
        label.textColor = [UIColor colorWithRed:139.0/255.0 green:153.0/255.0 blue:175.0/255.0 alpha:1.0];
        label.text = @"No real time memories here";
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = NO;
        [_exploreMemoriesNoneHereLabel addSubview:label];
    }
    return _exploreMemoriesNoneHereLabel;
}


- (BOOL)showExploreMemories {
    // TODO: currently, showing explore is equivalent to showing
    // the map.  That might change in the future with other types of searches;
    // e.g., if we are showing venues matching a hash tag, we might not want to show
    // explore memories at the same time
    return self.flyState == FlyStateExplore && self.viewDidAppear;
}


#pragma mark - Mutators

- (void)setFlyStateWithNumber:(NSNumber *)number {
    [self setFlyState:[number integerValue]];
}

- (void)setFlyState:(FlyState)flyState {
    if (_flyState != flyState) {
        // transitions...
        switch(_flyState) {
            case FlyStateSearch:
            case FlyStateSearchTeleport:
                if (flyState == FlyStateExplore) {
                    // transition from map to search
                    self.mapView.hidden = NO;
                    [UIView animateWithDuration:0.3 animations:^{
                        CGRect frame = CGRectMake(CGRectGetMinX(self.mapView.frame), CGRectGetMaxY(self.mapView.frame), CGRectGetWidth(self.mapView.frame), CGRectGetHeight(self.mapView.frame));
                        self.searchContentContainer.frame = frame;
                    } completion:^(BOOL finished) {
                        self.searchContentContainer.hidden = YES;
                    }];
                }
                break;
                
            case FlyStateExplore:
                if (flyState == FlyStateSearch || flyState == FlyStateSearchTeleport) {
                    // transition from map to search
                    self.searchContentContainer.hidden = NO;
                    [UIView animateWithDuration:0.3 animations:^{
                        self.searchContentContainer.frame = self.mapView.frame;
                    } completion:^(BOOL finished) {
                        self.mapView.hidden = YES;
                    }];
                }
                break;
        }
        
        _flyState = flyState;
        
        // states...
        switch(_flyState) {
            case FlyStateSearch:
                [self updateSuggestions];
                self.exploreMemoriesNoneHereLabel.hidden = YES;
                [self.mapView clear];
                break;
            case FlyStateSearchTeleport:
                self.earthquakeLoader.hidden = NO;
                [self.earthquakeLoader stopAnimating];
                [self.earthquakeLoader startAnimating];
                [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
                [self.textField resignFirstResponder];
                self.exploreMemoriesNoneHereLabel.hidden = YES;
                [self.mapView clear];
                break;
            case FlyStateExplore:
                [self.earthquakeLoader stopAnimating];
                self.earthquakeLoader.hidden = YES;
                [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
                [self.textField resignFirstResponder];
                // update the display time of all displayed memories
                for (ExploreMemory *exploreMemory in self.exploreMemoriesLoaded) {
                    if (exploreMemory.hasDisplayed) {
                        exploreMemory.displayedAtDate = [NSDate date];
                    }
                }
                break;
        }
        
        // no matter what....
        self.tabBarController.tabBar.alpha = 0.0;
        self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
        self.searchContainer.center = CGPointMake(self.searchContainer.center.x, self.searchContainerOriginalCenterY);
    }
}




#pragma mark - Actions 
-(void)closeButtonActivated:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(flyComplete)]) {
        [self.delegate flyComplete];
    }
}

-(void)resetSearch {
    self.textField.text = nil;
    self.resetSearchBtn.hidden = YES;
    self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    
    [self reloadSearchResults];
    [self.textField becomeFirstResponder];
    
    self.flyState = FlyStateSearch;
}


-(void)reloadSearchResults {
    if (self.textField.text.length > 0) {
        // search result is displayed.
        if (self.searchResults.count > 0) {
            // show search results
            [self.tableView reloadData];
            [self showSearchResults];
        } else {
            if (self.suggestionsView.hidden) {
                // show the suggestioned places,
                // with appropriate text.
                [self showSuggestions];
            }
        }
    } else {
        if (self.suggestionsView.hidden) {
            // show the suggestioned places,
            // TODO with appropriate text.
            [self showSuggestions];
        }
    }
}

-(void)showSearchResults {
    self.tableView.hidden = NO;
    
    self.suggestionsView.hidden = YES;
}

-(void)showSuggestions {
    self.suggestionsView.hidden = NO;
    
    self.tableView.hidden = YES;
}

-(void)goToRecommendedVenue:(id)sender {
    [Flurry logEvent:@"FLY_SUGGESTION_TAPPED"];
    SPCSuggestionItemView *sugVenueBtn = (SPCSuggestionItemView *)sender;
    Venue *destinationVenue = (Venue *)sugVenueBtn.venue;
    
    SPCCity *city = [[SPCCity alloc] init];
    city.neighborhoodName = destinationVenue.neighborhood;
    city.cityName = destinationVenue.city;
    city.county = destinationVenue.county;
    city.stateAbbr = destinationVenue.state;
    city.countryAbbr = destinationVenue.country;
    
    self.searchResults = [NSArray arrayWithObject:[[SPCPeopleSearchResult alloc] initWithCity:city]];
    
    [self exploreCity:city];
}


-(void)exploreCity:(SPCCity *)city {
    if ([city isKindOfClass:[SPCNeighborhood class]]) {
        self.textField.text = ((SPCNeighborhood *)city).neighborhoodName;
        self.exploreTerritoryNeighborhood = (SPCNeighborhood *)city;
        self.exploreTerritoryCity = nil;
    } else {
        self.textField.text = city.cityName;
        self.exploreTerritoryNeighborhood = nil;
        self.exploreTerritoryCity = city;
    }
    self.exploreTerritoryNextPageKey = nil;
    self.exploreTerritoryFlyNumber++;
    self.exploreTerritoryPagesFetched = 0;
    
    self.resetSearchBtn.hidden = NO;
    self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-blue"];
    
    [self.textField resignFirstResponder];
    
    // fetch the city / neighborhood memories
    self.flyState = FlyStateSearchTeleport;
    [self fetchExploreTerritoryForFlyNumber:self.exploreTerritoryFlyNumber pageKey:nil];
}


#pragma mark - Explore Actions

- (void)fetchExploreTerritoryNextPageForFlyNumberObject:(NSNumber *)flyNumberObject {
    [self fetchExploreTerritoryNextPageForFlyNumber:flyNumberObject.integerValue];
}

- (void)fetchExploreTerritoryNextPageForFlyNumber:(NSInteger)flyNumber {
    if (self.exploreTerritoryNextPageKey) {
        [self fetchExploreTerritoryForFlyNumber:flyNumber pageKey:self.exploreTerritoryNextPageKey];
    }
}


- (void)fetchExploreTerritoryForFlyNumber:(NSInteger)flyNumber pageKey:(NSString *)pageKey {
    if (flyNumber != self.exploreTerritoryFlyNumber) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    if (self.exploreTerritoryCity) {
        [MeetManager fetchRegionMemoriesWithCity:self.exploreTerritoryCity pageKey:pageKey completionHandler:^(NSArray *memories, NSString *nextPageKey) {
            __strong typeof(self) strongSelf = weakSelf;
            NSLog(@"fetchExploreTerritoryForFlyNumber %li, pageKey %@, received next key %@", flyNumber, pageKey, nextPageKey);
            
            if (strongSelf.exploreTerritoryFlyNumber == flyNumber) {
                // process, place on map, teleport, and change state.
                strongSelf.exploreTerritoryNextPageKey = (pageKey != nil && [pageKey isEqualToString:nextPageKey]) ? nil : nextPageKey;
                strongSelf.exploreTerritoryPagesFetched++;
                [strongSelf processFlyTerritoryMemories:memories withFlyNumber:flyNumber];
            }
        } errorHandler:^(NSError *error) {
            NSLog(@"error %@", error);
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.exploreTerritoryFlyNumber == flyNumber) {
                if (strongSelf.flyState == FlyStateSearchTeleport) {
                    strongSelf.flyState = FlyStateSearch;
                } else {
                    strongSelf.exploreTerritoryIsFocused = NO;
                }
            }
        }];
    } else {
        [MeetManager fetchRegionMemoriesWithNeighborhood:self.exploreTerritoryNeighborhood pageKey:pageKey completionHandler:^(NSArray *memories, NSString *nextPageKey) {
            __strong typeof(self) strongSelf = weakSelf;
            NSLog(@"fetchExploreTerritoryForFlyNumber %li, pageKey %@, received next key %@", flyNumber, pageKey, nextPageKey);
            
            if (strongSelf.exploreTerritoryFlyNumber == flyNumber) {
                // process, place on map, teleport, and change state.
                strongSelf.exploreTerritoryNextPageKey = (pageKey != nil && [pageKey isEqualToString:nextPageKey]) ? nil : nextPageKey;
                strongSelf.exploreTerritoryPagesFetched++;
                [strongSelf processFlyTerritoryMemories:memories withFlyNumber:flyNumber];
            }
        } errorHandler:^(NSError *error) {
            NSLog(@"error %@", error);
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf.exploreTerritoryFlyNumber == flyNumber) {
                if (strongSelf.flyState == FlyStateSearchTeleport) {
                    strongSelf.flyState = FlyStateSearch;
                } else {
                    strongSelf.exploreTerritoryIsFocused = NO;
                }
            }
        }];
    }
}


- (void)processFlyTerritoryMemories:(NSArray *)memories withFlyNumber:(NSInteger)flyNumber {
    if (flyNumber != self.exploreTerritoryFlyNumber) {
        NSLog(@"provided fly number %li does not match current fly number %li", flyNumber, self.exploreTerritoryFlyNumber);
        // ignore
        return;
    }
    
    // to process the memories:
    // first, add them to our region memories manager as outside mems.
    // second, IF this is the first fetch, place markers for them on the map and then reveal it.
    // third, schedule the next fetch.  It should be immediately for the first set,
    //      and after a reasonable delay for any afterwards.
    //NSLog(@"About to process %d memories", memories.count);
    
    if (self.exploreTerritoryPagesFetched == 1) {
        //NSLog(@"1 pages fetched, state is %d", self.flyState);
        if (self.flyState == FlyStateSearchTeleport) {
            // first time
            //NSLog(@"providing to region memories manager");
            [[SPCRegionMemoriesManager sharedInstance] setOutsideMemories:memories];
            
            // populate the map with markers
            //NSLog(@"making map markers");
            NSMutableArray *venuesPlaced = [NSMutableArray array];
            NSMutableArray *exploreMemoriesPlaced = [NSMutableArray array];
            for (Memory *memory in memories) {
                // make sure we haven't placed this venue
                BOOL placed = NO;
                for (Venue *venue in venuesPlaced) {
                    if ([SPCMapDataSource venue:venue is:memory.venue]) {
                        placed = YES;
                    }
                }
                if (placed) {
                    continue;
                }
                
                [venuesPlaced addObject:memory.venue];
                
                GMSMarker *exploreMemoryMarker = [SPCMarkerVenueData markerWithRealtimeMemory:memory venue:memory.venue iconReadyHandler:^(SPCMarker *marker) {
                    // try to find the ExploreMemory object, so we can refresh its display time.
                    //NSLog(@"iconReadyHandler");
                    for (ExploreMemory *em in self.exploreMemoriesLoaded) {
                        if (em.marker == marker && !em.hasDismissed && !em.hasDisplayed) {
                            em.hasDisplayed = YES;
                            self.exploreMemoriesDisplayed = [self.exploreMemoriesDisplayed arrayByAddingObject:memory];
                            break;
                        }
                    }
                    marker.map = self.mapView;
                }];
                ExploreMemory *exploreMemory = [[ExploreMemory alloc] initWithMemory:memory marker:exploreMemoryMarker];
                self.exploreMemoriesLoaded = [self.exploreMemoriesLoaded arrayByAddingObject:exploreMemory];
                [exploreMemoriesPlaced addObject:exploreMemory];
                // possible race condition, see the iconReadyHandler block above...
                if (exploreMemory.marker.map && !exploreMemory.hasDismissed && !exploreMemory.hasDisplayed) {
                    exploreMemory.hasDisplayed = YES;
                    self.exploreMemoriesDisplayed = [self.exploreMemoriesDisplayed arrayByAddingObject:memory];
                }
                
                //NSLog(@"ExploreMemory %d placed for %@ in neighborhood %@", memory.recordID, memory.venue.displayNameTitle, memory.venue.neighborhood);
                if (exploreMemoriesPlaced.count >= FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES) {
                    // that's all we need
                    break;
                }
            }
            
            // teleport to a location that contains all these venues
            //NSLog(@"teleporting map to view markers");
            __weak typeof(self) weakSelf = self;
            SPCCity *city = self.exploreTerritoryCity;
            if (!city) {
                city = self.exploreTerritoryNeighborhood;
            }
            [self setMapViewProjectionToShowTerritory:city exploreMemories:exploreMemoriesPlaced completionHandler:^(BOOL success) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                // reveal!  ...in a bit.
                [strongSelf performSelector:@selector(setFlyStateWithNumber:) withObject:[NSNumber numberWithInteger:FlyStateExplore] afterDelay:1.0];
                
                // next fetch... almost immediately.
                if (strongSelf.exploreTerritoryNextPageKey) {
                    //NSLog(@"fetching the next page...");
                    [strongSelf performSelector:@selector(fetchExploreTerritoryNextPageForFlyNumberObject:) withObject:[NSNumber numberWithInteger:flyNumber] afterDelay:2.0f];
                }
            }];
        }
    } else {
        //NSLog(@"%d pages fetched, state is %d", self.exploreTerritoryPagesFetched, self.flyState);
        if (self.flyState == FlyStateExplore || self.flyState == FlyStateSearchTeleport) {
            // subsequent time
            [[SPCRegionMemoriesManager sharedInstance] addOutsideMemories:memories];
            
            // should we keep fetching?
            self.exploreTerritoryIsFocused = self.viewDidAppear && [self memoriesVisibleInMap:memories];
            
            // next fetch... in a bit.
            if (self.exploreTerritoryIsFocused && self.exploreTerritoryNextPageKey) {
                [self performSelector:@selector(fetchExploreTerritoryNextPageForFlyNumberObject:) withObject:[NSNumber numberWithInteger:flyNumber] afterDelay:FLY_EXPLORE_DISPLAY_MEMORY_FOR];
            }
        }
    }
}


- (BOOL)memoriesVisibleInMap:(NSArray *)memories {
    for (Memory *memory in memories) {
        CLLocationCoordinate2D locationCoordinate = CLLocationCoordinate2DMake(memory.location.latitude.floatValue ,memory.location.longitude.floatValue);
        CGPoint pointOnMap = [self.mapView.projection pointForCoordinate:locationCoordinate];
        if (CGRectContainsPoint(self.mapView.bounds, pointOnMap)) {
            return YES;
        }
    }
    return NO;
}


- (BOOL)region:(GMSCoordinateBounds *)subRegion isContainedWithRegion:(GMSCoordinateBounds *)region {
    BOOL intersects = [region intersectsBounds:subRegion];
    BOOL contains = intersects && [region containsCoordinate:subRegion.southWest]
            && [region containsCoordinate:subRegion.northEast];
    return contains;
}


- (void)setMapViewProjectionToShowTerritory:(SPCCity *)city
                            exploreMemories:(NSArray *)exploreMemories
                          completionHandler:(void (^)(BOOL success))completionHandler {
    
    if (exploreMemories.count > 0) {
        GMSCoordinateBounds *bounds = nil;
        for (ExploreMemory *expMem in exploreMemories) {
            CLLocationCoordinate2D location = expMem.marker.position;
            if (!bounds) {
                bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:location coordinate:location];
            } else {
                bounds = [bounds includingCoordinate:location];
            }
        }
        
        // determine if it makes sense to set a fixed zoom level around the provided venue, or to
        CLLocation *ne = [[CLLocation alloc] initWithLatitude:bounds.northEast.latitude longitude:bounds.northEast.longitude];
        CLLocation *sw = [[CLLocation alloc] initWithLatitude:bounds.southWest.latitude longitude:bounds.southWest.longitude];
        
        if ([ne distanceFromLocation:sw] < 1000) {
            // less than a kilometer.... use a standard zoom level?
            NSLog(@"Area not large enough... using a standard zoom level");
            ExploreMemory *mem = exploreMemories[0];
            [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:mem.marker.position.latitude longitude:mem.marker.position.longitude zoom:15]];
        } else {
            NSLog(@"Fitting the camera to the fly area bounds");
            [self.mapView moveCamera:[GMSCameraUpdate fitBounds:bounds withPadding:50]];
        }
        
        if (completionHandler) {
            completionHandler(YES);
        }
    } else {
        NSString *searchString;
        if ([city isKindOfClass:[SPCNeighborhood class]]) {
            SPCNeighborhood *neighborhood = (SPCNeighborhood *)city;
            searchString = [NSString stringWithFormat:@"%@ %@", neighborhood.neighborhoodName, neighborhood.cityName];
        } else {
            searchString = city.cityName;
        }
        if (city.stateAbbr) {
            searchString = [NSString stringWithFormat:@"%@, %@", searchString, city.stateAbbr];
        }
        if (city.county) {
            searchString = [NSString stringWithFormat:@"%@, %@", searchString, city.county];
        }
        if (city.stateAbbr) {
            searchString = [NSString stringWithFormat:@"%@, %@", searchString, city.stateAbbr];
        }
        if (city.countryAbbr) {
            searchString = [NSString stringWithFormat:@"%@, %@", searchString, city.countryAbbr];
        }
        NSLog(@"No memories to define the bounds: use a geocoder for string '%@'", searchString);
        [self.geocoder geocodeAddressString:searchString completionHandler:^(NSArray *placemarks, NSError *error) {
            if (error || placemarks.count == 0) {
                if (completionHandler) {
                    completionHandler(NO);
                }
            } else {
                CLPlacemark *placemark = placemarks[0];
                CLLocationCoordinate2D coordinate = placemark.location.coordinate;
                [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:coordinate.latitude
                                                                    longitude:coordinate.longitude zoom:15]];
                
                if (completionHandler) {
                    completionHandler(YES);
                }
            }
        }];
    }
}




- (void)exploreRefreshTimerDidTrigger {
    // only refresh if we can put the data to use; otherwise it's
    // a waste of time and data.
    if (self.showExploreMemories) {
        [self refreshNearbyMemories];
        //NSLog(@"Refreshing nearby memories!");
    } else {
        //NSLog(@"NOT refreshing nearby memories, with view did appear %d, in foreground %d, exploreOn %d", self.didViewAppear, self.inForeground, self.exploreOn);
    }
}

- (void)exploreDisplayTimerDidTrigger {
    if (self.showExploreMemories) {
        [self cycleDisplayedExploreMemories];
        
        //NSLog(@"Updating explore displays!");
    } else {
        //NSLog(@"NOT Updating explore displays, with view did appear %d, in foreground %d, exploreOn %d", self.didViewAppear, self.inForeground, self.exploreOn);
    }
}


- (void)showExploreMemoryDetails:(SPCMarkerVenueData *)venueData {
    [self recordMemory:venueData.memory asExploredFor:(FLY_HIDE_MEMORY_AFTER_TAP_DURATION)]; // don't show for 48 hours
    
    
    //capture image of screen to use in MAM completion animation
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    SPCVenueDetailGridTransitionViewController *vc = [[SPCVenueDetailGridTransitionViewController alloc] init];
    vc.venue = venueData.venue;
    vc.memory = venueData.memory;
    vc.backgroundImage = currentScreenImg;
    vc.gridCellAsset = venueData.exploreAsset;
    // take a reasonable guess about where the image is currently displayed...
    CGPoint anchor = [self.mapView.projection pointForCoordinate:venueData.coordinate];
    CGSize iconSize = CGSizeMake(56, 77.5);
    CGPoint iconTopLeft = CGPointMake(anchor.x - iconSize.width * 0.5, anchor.y - iconSize.height * 0.97);
    CGPoint imageTopLeft = CGPointMake(iconTopLeft.x + 3, iconTopLeft.y + 3);
    vc.gridCellFrame = CGRectMake(imageTopLeft.x, imageTopLeft.y + CGRectGetMinY(self.mapView.frame), 50, 50);
    
    // clip rect?
    CGFloat top = CGRectGetMaxY(self.searchContainer.frame);
    CGFloat bottom = CGRectGetMaxY(self.view.frame);
    //NSLog(@"mask to the area from %f to %f", top, bottom);
    CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
    vc.gridClipFrame = maskRect;
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    [self presentViewController:navController animated:NO completion:nil];
}

- (void)refreshNearbyMemories {
    if (self.showExploreMemories) {
        [[SPCRegionMemoriesManager sharedInstance] cacheMemoriesForRegionWithProjection:self.mapView.projection mapViewBounds:self.mapView.bounds completionHandler:^(NSInteger memoriesCached) {
            [self cycleDisplayedExploreMemories];
        } errorHandler:^(NSError *error) {
            // meh, I'm sure we'll try again later.
            NSLog("Fault caching memories in this region %@", error);
        }];
    }
}

- (void)cycleDisplayedExploreMemories {
    if (self.showExploreMemories) {
        //NSLog(@"cycleDisplayedExploreMemories...");
        // cycle out any explore memories that need to go.
        
        // cycle any that are fully offscreen.  Use extra bounds, especially on
        // the bottom (a marker can be anchored at its bottom but still be mostly onscreen)
        CGRect bounds = self.mapView.bounds;
        CGRect boundsWithExtra = CGRectMake(bounds.origin.x - 100, bounds.origin.y - 100, bounds.size.width + 200, bounds.size.height + 200);
        GMSProjection *projection = self.mapView.projection;
        int memoriesRemoved = 0;
        for (ExploreMemory *candidate in self.exploreMemoriesLoaded) {
            if (!CGRectContainsPoint(boundsWithExtra, [projection pointForCoordinate:candidate.marker.position])) {
                // on the map, but outside the visible boundaries.
                [self dismissExploreMemory:candidate withFadeDuration:0];
                memoriesRemoved++;
            }
        }
        
        if (memoriesRemoved == 0 && (!self.exploreMemoryLastDismissed || [[NSDate date] timeIntervalSinceDate:self.exploreMemoryLastDismissed] >= FLY_EXPLORE_DISPLAY_MEMORY_FOR)) {
            // it's possible to dismiss one...
            ExploreMemory *memoryToDismiss = nil;
            for (ExploreMemory *candidate in self.exploreMemoriesLoaded) {
                if (candidate.hasDisplayed && [[NSDate date] timeIntervalSinceDate:candidate.displayedAtDate] >= FLY_EXPLORE_DISPLAY_MEMORY_FOR) {
                    memoryToDismiss = candidate;
                    break;
                }
            }
            
            if (memoryToDismiss) {
                //NSLog(@"dismissing memory %@", memoryToDismiss);
                [self recordExploreMemory:memoryToDismiss asExploredFor:FLY_HIDE_MEMORY_AFTER_DISPLAY_DURATION];
                [self dismissExploreMemory:memoryToDismiss withFadeDuration:FLY_EXPLORE_FADE_OUT_DURATION];
                memoriesRemoved++;
            }
        }
        
        if (self.exploreMemoriesLoaded.count < FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES) {
            //NSLog(@"attempting to display new memories!");
            // attempt to display new memories!
            [self displayNextExploreMemories];
        }
    }
}


- (void)displayNextExploreMemories {
    // Load and display up to FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES memories.
    //NSLog(@"fetch in progress %d, count %d", exploreMemoriesLoaded, self.exploreMemoryFetchInProgress);
    if (self.showExploreMemories && self.exploreMemoriesLoaded.count < FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES && !self.exploreMemoryFetchInProgress) {
        //NSLog(@"fetching a memory to display...");
        __weak typeof(self) weakSelf = self;
        NSMutableArray *mut = [NSMutableArray arrayWithCapacity:self.exploreMemoriesDisplayed.count];
        for (ExploreMemory *exploreMemory in self.exploreMemoriesLoaded) {
            [mut addObject:exploreMemory.memory];
        }
        GMSCoordinateBounds *boundsBeforeCall = self.mapViewCoordinateBounds;
        [[SPCRegionMemoriesManager sharedInstance] fetchAnyMemoryForRegionWithProjection:self.mapView.projection mapViewBounds:self.mapView.bounds   ignoreRateLimit:NO displayedWithMemories:[NSArray arrayWithArray:mut] withWillFetchRemotelyHandler:^(BOOL *cancel) {
            //NSLog(@"will fetch remotely");
            // store that there is a background fetch happening; don't allow another
            // fetch until we get a callback (or a timeout).
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.exploreMemoryFetchInProgress = YES;
        } completionHandler:^(Memory *memory) {
            //NSLog(@"completion!  get memory %@", memory);
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.exploreMemoryFetchInProgress = NO;
            GMSCoordinateBounds *boundsAfterCall = strongSelf.mapViewCoordinateBounds;
            // note that we got a callback.
            if (memory && [boundsAfterCall containsCoordinate:memory.location.location.coordinate]) {
                // add to displayed results and fade in.  We always want results to be consistent,
                // so try to do this "atomically".
                GMSMarker *exploreMemoryMarker = [SPCMarkerVenueData markerWithRealtimeMemory:memory venue:memory.venue iconReadyHandler:^(SPCMarker *marker) {
                    // try to find the ExploreMemory object, so we can refresh its display time.
                    //NSLog(@"iconReadyHandler");
                    for (ExploreMemory *em in strongSelf.exploreMemoriesLoaded) {
                        if (em.marker == marker && !em.hasDismissed && !em.hasDisplayed) {
                            em.hasDisplayed = YES;
                            strongSelf.exploreMemoriesDisplayed = [strongSelf.exploreMemoriesDisplayed arrayByAddingObject:memory];
                            break;
                        }
                    }
                    marker.map = strongSelf.mapView;
                }];
                ExploreMemory *exploreMemory = [[ExploreMemory alloc] initWithMemory:memory marker:exploreMemoryMarker];
                strongSelf.exploreMemoriesLoaded = [strongSelf.exploreMemoriesLoaded arrayByAddingObject:exploreMemory];
                // possible race condition, see the iconReadyHandler block above...
                if (exploreMemory.marker.map && !exploreMemory.hasDismissed && !exploreMemory.hasDisplayed) {
                    exploreMemory.hasDisplayed = YES;
                    strongSelf.exploreMemoriesDisplayed = [strongSelf.exploreMemoriesDisplayed arrayByAddingObject:memory];
                }
                
                //NSLog(@"ExploreMemory %d placed for %@ in neighborhood %@", memory.recordID, memory.venue.displayNameTitle, memory.venue.neighborhood);
                
                // fetch another?
                if (strongSelf.exploreMemoriesLoaded.count < FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES) {
                    //NSLog(@"attempting to display new memories!");
                    // attempt to display new memories!
                    [strongSelf displayNextExploreMemories];
                }
                
                if (!strongSelf.exploreMemoriesNoneHereLabel.hidden) {
                    [UIView animateWithDuration:0.5 animations:^{
                        strongSelf.exploreMemoriesNoneHereLabel.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        strongSelf.exploreMemoriesNoneHereLabel.hidden = YES;
                    }];
                }
            } else if (!memory) {
                // no memories in the BEFORE CALL bounds.  That only means there are no
                // memories in the AFTER CALL bounds if after call is fully contained within
                // before call.
                
                if ([self region:boundsAfterCall isContainedWithRegion:boundsBeforeCall] && strongSelf.exploreMemoriesLoaded.count == 0 && strongSelf.exploreMemoriesNoneHereLabel.hidden) {
                    strongSelf.exploreMemoriesNoneHereLabel.alpha = 0.0;
                    strongSelf.exploreMemoriesNoneHereLabel.hidden = NO;
                    [UIView animateWithDuration:0.5 animations:^{
                        strongSelf.exploreMemoriesNoneHereLabel.alpha = 1.0;
                    }];
                }
            }
        } errorHandler:^(NSError *error) {
            // note that we got a callback.
            NSLog(@"Error in fetching unexplored memory for region %@", error);
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.exploreMemoryFetchInProgress = NO;
            
            /*  Don't display on an error -- only display on a success that produces no results.
            if (strongSelf.exploreMemoriesLoaded.count == 0 && strongSelf.exploreMemoriesNoneHereLabel.hidden) {
                strongSelf.exploreMemoriesNoneHereLabel.alpha = 0.0;
                strongSelf.exploreMemoriesNoneHereLabel.hidden = NO;
                [UIView animateWithDuration:0.5 animations:^{
                    strongSelf.exploreMemoriesNoneHereLabel.alpha = 1.0;
                }];
            }
             */
        }];
    }
}


- (void)recordExploreMemory:(ExploreMemory *)exploreMemory asExploredFor:(NSTimeInterval)timeInterval {
    [self recordMemory:exploreMemory.memory asExploredFor:timeInterval];
}

- (void)recordMemory:(Memory *)memory asExploredFor:(NSTimeInterval)timeInterval {
    if (memory) {
        [[SPCRegionMemoriesManager sharedInstance] setHasExploredMemory:memory explored:YES withDuration:timeInterval];
    }
}

- (void)dismissExploreMemory:(ExploreMemory *)memoryToDismiss withFadeDuration:(NSTimeInterval)fadeDuration {
    // first step: remove this memory from our list of "displayed" memories.
    NSMutableArray *mut = [NSMutableArray arrayWithArray:self.exploreMemoriesDisplayed];
    [mut removeObject:memoryToDismiss.memory];
    self.exploreMemoriesDisplayed = [NSArray arrayWithArray:mut];
    
    // now fade out the marker.
    GMSMarker *marker = memoryToDismiss.marker;
    self.exploreMemoryLastDismissed = [NSDate date];
    memoryToDismiss.hasDismissed = YES;
    if (fadeDuration <= 0) {
        marker.map = nil;
        
        mut = [NSMutableArray arrayWithArray:self.exploreMemoriesLoaded];
        [mut removeObject:memoryToDismiss];
        self.exploreMemoriesLoaded = [NSArray arrayWithArray:mut];
        // fetch another?
        if (self.exploreMemoriesLoaded.count < FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES) {
            //NSLog(@"attempting to display new memories!");
            // attempt to display new memories!
            [self displayNextExploreMemories];
        }
    } else {
        __weak typeof(self) weakSelf = self;
        GMSMarkerLayer *layer = marker.layer;
        CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOut.fromValue = @1.0;
        fadeOut.toValue = @0.0;
        fadeOut.duration = fadeDuration;
        fadeOut.fillMode = kCAFillModeForwards;
        fadeOut.removedOnCompletion = YES;
        fadeOut.delegate = [[SPCAnimationDelegate alloc] initWithStopCallback:^(CAAnimation *anim, BOOL finished) {
            marker.map = nil;
            
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSMutableArray *mut = [NSMutableArray arrayWithArray:self.exploreMemoriesLoaded];
            [mut removeObject:memoryToDismiss];
            strongSelf.exploreMemoriesLoaded = [NSArray arrayWithArray:mut];
            // fetch another?
            if (self.exploreMemoriesLoaded.count < FLY_MAX_SIMULTANEOUS_EXPLORE_MEMORIES) {
                //NSLog(@"attempting to display new memories!");
                // attempt to display new memories!
                [self displayNextExploreMemories];
            }
        }];
        [layer addAnimation:fadeOut forKey:@"fadeOut"];
    }
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    self.resetSearchBtn.hidden = textField.text.length == 0;
    if (self.flyState != FlyStateSearch) {
        [self reloadSearchResults];
        self.flyState = FlyStateSearch;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.resetSearchBtn.hidden = textField.text.length == 0;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    //self.promptContainer.alpha = 0;
    //self.promptText.alpha = 0;
    
    if (text.length >= 100) {
        return NO;
    } else if (text.length == 0) {
        if (self.suggestionsView.hidden) {
            // show the suggestioned places,
            // TODO with appropriate text.
            [self showSuggestions];
        }
        self.resetSearchBtn.hidden = YES;
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    } else {
        //self.cancelSearchBtn.hidden = YES;
        self.resetSearchBtn.hidden = NO;
        
        // Cancel previous filter request
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-blue"];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        // Perform this search.  When results are available, display in the list.
        [self performSelector:@selector(filterContentForSearchText:) withObject:text afterDelay:0.1];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}



#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchResults.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cityCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cityResult";
    
    SPCCitySearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[SPCCitySearchResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    SPCCity *city;
    SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
    city = result.city;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell configureWithCity:city];
    cell.tag = (int)indexPath.row;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView neighborhoodCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"neighborhoodResult";
    
    SPCCitySearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[SPCCitySearchResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    SPCCity *city;
    SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
    city = result.neighborhood;
    
    [cell configureWithCity:city];
    [cell updateForNeighborhood:city];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.tag = (int)indexPath.row;
    return cell;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
    
    if (result.searchResultType == SearchResultCity) {
        return [self tableView:tableView cityCellForRowAtIndexPath:indexPath];
    } else if (result.searchResultType == SearchResultNeighborhood) {
        return [self tableView:tableView neighborhoodCellForRowAtIndexPath:indexPath];
    } else {
        NSLog(@"result type is %ld", result.searchResultType);
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    
    if ([cell.reuseIdentifier isEqualToString:@"cityResult"]) {
        
        //get the selected city
        SPCCity *city = ((SPCPeopleSearchResult *)self.searchResults[indexPath.row]).city;
        [self exploreCity:city];
    }
    if ([cell.reuseIdentifier isEqualToString:@"neighborhoodResult"]) {
        
        //get the selected neighborhood
        SPCNeighborhood *neighborhood = ((SPCPeopleSearchResult *)self.searchResults[indexPath.row]).neighborhood;
        [self exploreCity:neighborhood];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}


#pragma mark - Explore suggestions

-(void)refreshSuggestionsIfNeeded {
    if  (self.suggestedVenues.count < 5) {
        [self suggestionRefreshNeeded];
    }
}

- (void)suggestionRefreshNeeded {
    //FETCH BATCH OF SUGGESTED VENUES FROM SERVER
    //NSLog(@"fetch suggestions@");
    if (!self.fetchingSuggestions) {
        //NSLog(@"fetching suggestions");
        self.fetchingSuggestions = YES;
        [[VenueManager sharedInstance] fetchSuggestedVenuesResultCallback:^(NSArray *venues) {
            //NSLog(@"got suggestions!");
            self.fetchingSuggestions = NO;
            self.suggestedVenues = [NSArray arrayWithArray:venues];
            if (!self.initialSuggestionsSet){
                [self updateSuggestions];
            }
        } faultCallback:^(NSError *error) {
            self.fetchingSuggestions = NO;
        }];
    }
    
}

-(void)updateSuggestions {
    //NSLog(@"update suggestions");
    
    NSMutableArray *updatedArray = [[NSMutableArray alloc] init];
    if (self.suggestedVenues.count > 0) {
        self.initialSuggestionsSet = YES;
        updatedArray = [NSMutableArray arrayWithArray:self.suggestedVenues];
        
        //clean up the old view
        UIView *view;
        NSArray *subs = [self.suggestionsView subviews];
        
        for (view in subs) {
            if (view.tag < 0) {
                [view removeFromSuperview];
            }
        }
    }
    
    
    //ADD THE CURRENT FLIGHT OF SUGGESTIONS TO THE VIEW
    float itemWidth = 100;
    float adjY = 20;
    
    if (self.view.bounds.size.width > 320) {
        itemWidth = 105;
        adjY = 50;
    }
    float initialX = (self.suggestionsView.frame.size.width - (itemWidth * 3))/2;
    
    
    NSString *firstSuggestedCity;
    NSString *secondSuggestedCity;
    NSInteger suggestionsAdded = 0;
    
    for (int i = 0; i < self.suggestedVenues.count; i++) {
        
        self.suggestionsHeader.hidden = NO;
        
        //get a suggested venue, avoiding including 2 venues from the same city...
        Venue *tempV = (Venue *)self.suggestedVenues[i];
        //NSLog(@"tempV.city %@",tempV.city);
        
        BOOL cityAlreadyIncluded = NO;
        
        if ([tempV.city isEqualToString:firstSuggestedCity] || [tempV.city isEqualToString:secondSuggestedCity]) {
            cityAlreadyIncluded = YES;
            //NSLog(@"already included!");
        }
        
        else {
            //NSLog(@"new city..");
            if (firstSuggestedCity) {
                if (!secondSuggestedCity) {
                    secondSuggestedCity = tempV.city;
                    //NSLog(@"remeber as second city");
                }
            }
            else {
                firstSuggestedCity = tempV.city;
                //NSLog(@"remember as first city");
            }
        }
        
        if (!cityAlreadyIncluded) {
            
            if (updatedArray.count > i ) {
                [updatedArray removeObjectAtIndex:i];
            }
            float originX = initialX + itemWidth * suggestionsAdded;
            suggestionsAdded++;
            
            SPCSuggestionItemView *tempVenView = [[SPCSuggestionItemView alloc] initWithVenue:tempV andFrame:CGRectMake(originX, 80+adjY, itemWidth, itemWidth)];
            tempVenView.tag = -777;
            [tempVenView addTarget:self action:@selector(goToRecommendedVenue:) forControlEvents:UIControlEventTouchDown];
            [self.suggestionsView addSubview:tempVenView];
        }
        
        if (suggestionsAdded >= 3) {
            break;
        }
    }
    if (updatedArray.count > 4) {
        if (suggestionsAdded >= 3) {
            self.suggestedVenues = [NSArray arrayWithArray:updatedArray];
        }
        else {
            [self suggestionRefreshNeeded];
        }
    } else {
        self.suggestedVenues = nil;
        [self refreshSuggestionsIfNeeded];
    }
}


#pragma mark - Content filtering

- (void)filterContentForSearchText:(NSString *)searchText {
    // Cancel any previous search operations before performing a new one
    if (self.searchOperationQueue) {
        [self.searchOperationQueue cancelAllOperations];
    }
    
    if (searchText.length > 0) {
        
        NSBlockOperation *operation = [[NSBlockOperation alloc] init];
        
        __weak typeof(self)weakSelf = self;
        __weak typeof(operation)weakOperation = operation;
        
        [operation addExecutionBlock:^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            __strong typeof(weakOperation)strongOperation = weakOperation;
            
            if (strongOperation.isCancelled) {
                return;
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (strongOperation.isCancelled) {
                    return;
                }
                // Reload view right away and show loader
                strongSelf.isLoadingCurrentData = YES;
                [strongSelf fetchUnifiedResultsWithSearchString:searchText];
            }];
        }];
        [self.searchOperationQueue addOperation:operation];
    } else {
        if (self.suggestionsView.hidden) {
            // show the suggestioned places,
            // with appropriate text.
            [self showSuggestions];
        }
    }
}



- (void)fetchUnifiedResultsWithSearchString:(NSString *)searchStr {
    [self spc_hideNotificationBanner];
    
    //1. fetch results
    [MeetManager fetchExplorePlacesWithSearch:searchStr
                            completionHandler:^(NSArray *neighborhoods, NSArray *cities)
    {
        [self spc_hideNotificationBanner];
        
        // package up search results.
        NSMutableArray *mingledResults = [NSMutableArray arrayWithCapacity:(neighborhoods.count + cities.count)];
        for (int i = 0; i < MAX(neighborhoods.count, cities.count); i++) {
            if (i < neighborhoods.count) {
                [mingledResults addObject:[[SPCPeopleSearchResult alloc] initWithNeighborhood:neighborhoods[i]]];
            }
            if (i < cities.count) {
                [mingledResults addObject:[[SPCPeopleSearchResult alloc] initWithCity:cities[i]]];
            }
        }
        
        if (![searchStr isEqualToString:self.textField.text]){
            
            //NSLog(@"Search string has changed since search occurred!");
            //DO ANOTHER SEARCH!
            
            if (self.searchOperationQueue) {
                [self.searchOperationQueue cancelAllOperations];
            }
            
            
            if (self.textField.text.length > 0) {
                NSBlockOperation *operation = [[NSBlockOperation alloc] init];
                
                __weak typeof(self) weakSelf = self;
                __weak typeof(operation) weakOperation = operation;
                
                [operation addExecutionBlock:^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    __strong typeof(weakOperation) strongOperation = weakOperation;
                    
                    if (strongOperation.isCancelled) {
                        return;
                    }
                    
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (strongOperation.isCancelled) {
                            return;
                        }
                        [strongSelf fetchUnifiedResultsWithSearchString:strongSelf.textField.text];
                    }];
                }];
                [self.searchOperationQueue addOperation:operation];
            }
            else {
                [self resetSearch];
            }
        } else {
            // set and show these search results.
            self.searchResults = [NSArray arrayWithArray:mingledResults];
            [self reloadSearchResults];
        }

        
    } errorHandler:^(NSError *error) {
        NSLog(@"error searching for explore places: %@", error);
    }];
    
}


#pragma mark - Keyboard

- (void)keyboardDidShowNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect kbRect = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize kbSize = [self.view convertRect:kbRect toView:nil].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}



#pragma mark - SPCGoogleMapInfoViewSupportDelegateDelegate

-(void) mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    if (gesture) {
        // cancel search editing
        [self.view endEditing:YES];
    }
}

-(void) mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    // If the "no new memories" sign is visible and we have moved outside of the previously
    // queried range, hide the sign?  Maybe only if outside by far enough?
    if (self.mapViewCoordinateBoundsOnDragStart && !self.exploreMemoriesNoneHereLabel.hidden) {
        // We are showing "no real time memories here," but are moving.
        // Check whether we've moved far outside the boundaries previously examined.
        if (![self region:self.mapViewCoordinateBounds isContainedWithRegion:self.mapViewExtendedCoordinateBoundsOnDragStart]) {
            [UIView animateWithDuration:0.5 animations:^{
                self.exploreMemoriesNoneHereLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.exploreMemoriesNoneHereLabel.hidden = YES;
            }];
            self.mapViewCoordinateBoundsOnDragStart = nil;
            self.mapViewExtendedCoordinateBoundsOnDragStart = nil;
        }
    }
}

-(void) mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    NSLog(@"mapView idle at camera position!");
    
    if (self.flyState == FlyStateExplore) {
        [self cycleDisplayedExploreMemories];
    }
    [self.mapView setUserInteractionEnabled:YES];
    
    self.mapViewCoordinateBoundsOnDragStart = self.mapViewCoordinateBounds;
    self.mapViewExtendedCoordinateBoundsOnDragStart = self.mapViewExtendedCoordinateBounds;
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(SPCMarker *)marker {
    [self.view endEditing:YES];
    
    //NSLog(@"did tap marker");
    
    if (![marker.userData isKindOfClass:[SPCMarkerVenueData class]]) {
        return NO;
    }
    
    SPCMarkerVenueData *venueData = marker.userData;
    
    [self showExploreMemoryDetails:venueData];
    
    return YES;
}

-(UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(SPCMarker *)marker {
  return nil;
}
@end
