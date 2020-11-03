//
//  SPCExploreViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

//framework
#import "Flurry.h"

//manager
#import "MeetManager.h"
#import "LocationManager.h"
#import "LocationContentManager.h"
#import "SPCPullToRefreshManager.h"
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "SettingsManager.h"

//controller
#import "SPCExploreViewController.h"
#import "SPCFlyViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCHereVenueMapViewController.h"
#import "SPCCreateVenueViewController.h"
#import "SPCHereVenueSelectionViewController.h"
#import "SPCHandlePromptViewController.h"
#import "SPCNavControllerLight.h"
#import "SPCVenueDetailGridTransitionViewController.h"
#import "SignUpViewController.h"
#import "MemoryCommentsViewController.h"
#import "SPCProfileViewController.h"

//view
#import "HMSegmentedControl.h"
#import "SPCNearbyVenuesView.h"
#import "SPCGrid.h"
#import "SPCMapFilterCollectionViewCell.h"
#import "SPCEarthquakeLoader.h"
#import "SPCCallout.h"
#import "SPCAnonUnlockedView.h"
#import "SPCAnonWarningView.h"
#import "SPCAdminWarningView.h"
#import "SPCMontageView.h"
#import "MemoryCell.h"

//model
#import "SPCVenueTypes.h"
#import "ProfileDetail.h"
#import "UserProfile.h"
#import "Person.h"
#import "User.h"

//category
#import "UITabBarController+SPCAdditions.h"
#import "UIViewController+SPCAdditions.h"
#import "UIImageEffects.h"

//literals
#import "SPCLiterals.h"

//constants
#import "Constants.h"

static NSString * CellIdentifier = @"SPCFiltersCell";

const NSTimeInterval REFRESH_CONTENT_IF_INACTIVE_INTERVAL = 300.f;      // inactive for 5 minutes

const BOOL EXPLORE_NEARBY_VENUE_REFRESH = YES;
const NSTimeInterval EXPLORE_NEARBY_VENUE_REFRESH_INTERVAL = 60.f;
const CGFloat EXPLORE_NEARBY_VENUE_REFRESH_DISTANCE = 100;


@interface SPCExploreViewController () <SPCPullToRefreshManagerDelegate, SPCHereVenueSelectionViewControllerDelegate, SPCFlyViewControllerDelegate, SPCMontageViewDelegate>

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIView *statusBar;
@property (nonatomic, strong) UIButton *nearbyVenuesBtn;
@property (nonatomic, strong) UIButton *flyBtn;
@property (nonatomic, strong) UIView *segControlContainer;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) SPCGrid *localGridView;
@property (nonatomic, strong) SPCGrid *worldGridView;

@property (nonatomic, assign) ExploreState exploreState;

@property (nonatomic, strong) UIView *mapContainerView;
@property (nonatomic, strong) SPCNearbyVenuesView *nearbyVenuesView;
@property (nonatomic, strong) SPCHereVenueMapViewController *mapViewController;
@property (nonatomic, strong) SPCHereVenueSelectionViewController *venueSelectionViewController;
@property (nonatomic, strong) SPCFlyViewController *flyViewController;
@property (nonatomic, assign, getter = isVenueSelectionTransitionAnimationInProgress) BOOL venueSelectionTransitionAnimationInProgress;
@property (nonatomic, assign, getter = isVenueSelectionDisplayed) BOOL venueSelectionDisplayed;


@property (nonatomic, assign) BOOL performingRefresh;
@property (nonatomic, assign) BOOL displayingNearbyVenues;
@property (nonatomic, assign) BOOL waitingForLocationManagerUptime;

@property (nonatomic, strong) UIButton *filtersBtn;
@property (nonatomic, strong) UIView *filtersContainer;
@property (nonatomic, strong) UICollectionView *filtersCollectionView;
@property (nonatomic, strong) UIButton *dismissFiltersOverlayBtn;
@property (nonatomic, assign) BOOL displayingFilters;
@property (nonatomic, strong) NSArray *activeFilters;
@property (nonatomic, strong) NSArray *selectedFilters;
@property (nonatomic, assign) CGFloat filterItemWidth;
@property (nonatomic, assign) CGFloat filterItemHeight;
@property (nonatomic, assign) BOOL checkerboard;

@property (nonatomic, strong) UIButton *refreshLocationBtn;
@property (nonatomic, strong) UIButton *createLocationBtn;
@property (nonatomic, strong) UIButton *refreshAfterNearbyFaultBtn;
@property (nonatomic, strong) UIButton *refreshAfterWorldFaultBtn;
@property (nonatomic, strong) UIView *errorView;

@property (nonatomic, strong) NSArray *nearbyVenues;
@property (nonatomic, strong) Venue *currVenue;
@property (nonatomic, strong) Venue *deviceVenue;

@property (nonatomic, strong) SPCEarthquakeLoader *gridLoader;
@property (nonatomic, strong) SPCEarthquakeLoader *mapLoader;

@property (nonatomic, assign) float navBarOriginalCenterY;
@property (nonatomic, assign) float segControlOriginalCenterY;
@property (nonatomic, assign) float maxAdjustment;

@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) UIView *pullToRefreshFadingHeader;
@property (nonatomic, strong) SPCPullToRefreshManager *pullToRefreshManager;

@property (nonatomic, strong) UIRefreshControl *worldRefreshControl;
@property (nonatomic, strong) UIView *pullToRefreshWorldFadingHeader;
@property (nonatomic, strong) SPCPullToRefreshManager *worldPullToRefreshManager;

@property (nonatomic, assign) BOOL refreshAdded;
@property (nonatomic, assign) BOOL pullToRefreshStarted;
@property (nonatomic, assign) BOOL gridAlignmentFailSafeTriggered;


@property (nonatomic, assign) BOOL locationAvailable;
@property (nonatomic, assign) BOOL locationAvailableAtLastResign;
@property (nonatomic, strong) UIView *locationPromptView;
@property (nonatomic, strong) CLLocation *lastRefreshedLocation;

@property (nonatomic, strong) Memory *localMem;
@property (nonatomic, strong) UIImageView *animationImageView;
@property (nonatomic, strong) UIImage *gridScreenCapForTransition;

@property (nonatomic, strong) UIButton *scrollToTopBtn;

@property (nonatomic, strong) SPCHereVenueMapViewController *mamAnimationMapViewController;
@property (nonatomic, strong) UIView *mamAnimationView;

@property (nonatomic, strong) NSDate *didResignActiveDate;
@property (nonatomic, strong) NSTimer *nearbyVenueRefreshTimer;
@property (nonatomic, assign) NSInteger retryCount;

@property (nonatomic, assign) BOOL gridIsVisible; // Set when viewIsVisible and montage/MemComments is off-screen

@property (nonatomic, strong) UIImageView *viewBlurredScreen;
@property (nonatomic, assign) BOOL viewIsVisible;

//anon unlocked screen
@property (nonatomic) BOOL anonUnlockScreenWasShown;
@property (nonatomic) BOOL presentedAnonUnlockScreenInstance; // This instance's value
@property (nonatomic, strong) SPCAnonUnlockedView *anonUnlockScreen;

//anon warning screen
@property (nonatomic) BOOL anonWarningScreenWasShown;
@property (nonatomic) BOOL presentedAnonWarningScreenInstance; // This instance's value
@property (nonatomic, strong) SPCAnonWarningView *anonWarningScreen;

//admin warning screen
@property (nonatomic) BOOL presentedAdminWarningScreenInstance; // This instance's value
@property (nonatomic, strong) SPCAdminWarningView *adminWarningScreen;

//callouts
@property (nonatomic, strong) SPCCallout *calloutToPresent;
@property (nonatomic, strong) NSString *calloutNSUserDefaultsKey;
@property (nonatomic) CGRect rectCallout;
@property (nonatomic) BOOL calloutIsOnscreen;
@property (nonatomic) BOOL allCalloutsShown;

//montages
@property (strong, nonatomic) SPCMontageView *viewMontageLocal;
@property (strong, nonatomic) SPCMontageView *viewMontageWorld;
@property (weak, nonatomic) SPCMontageView *viewMontagePlaying;
@property (weak, nonatomic) UIView *originalMontageSuperview;
@property (strong, nonatomic) UIView *collectionViewOverlay;
@property (strong, nonatomic) UIView *commentViewHeader;
@property (nonatomic) CGRect originalMontageFrame;
@property (nonatomic) CGRect convertedMontageBounds;
@property (nonatomic) CGPoint convertedMontageCenter;
@property (nonatomic) CGPoint originalMontageCenterBeforeNav;
@property (nonatomic) BOOL isPreparingToPlayMontage; // Used for the period of time between the play button tap and sending the play signal to the montage
@property (strong, nonatomic) UINavigationController *navFromMontage;
@property (nonatomic) BOOL hasPerformedInitialMontageWorldFetch;
@property (nonatomic) BOOL hasPerformedInitialMontageNearbyFetch;
@property (nonatomic) BOOL montageCoachmarkWasShown;

//comment animation
@property (nonatomic, strong) UIImageView *expandingImageView;
@property (nonatomic, strong) UIImageView *expandingImageViewClipped;
@property (nonatomic, strong) UIView *clippingView;

@property (nonatomic, assign) CGRect expandingImageRect;
@property (nonatomic, assign) BOOL expandingDidHideTabBar;

@property (nonatomic, strong) UINavigationController *navFromGrid;

@property (nonatomic, readonly) BOOL isTabBarAllowed;
@property (nonatomic, readonly) BOOL isNavBarFullyVisible;

@end
#define NEARBY_VENUES_STALE_AFTER 1200

#define MINIMUM_LOCATION_MANAGER_UPTIME 6

#define VERBOSE_STATE_CHANGES NO
#define VERBOSE_CONTENT_UPDATES NO

@implementation SPCExploreViewController

- (void)dealloc {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    _pullToRefreshManager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_nearbyVenueRefreshTimer invalidate];
    _nearbyVenueRefreshTimer = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.navigationController.navigationBar.hidden = YES;
    
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        self.locationAvailable = YES;
    }
    
    // Background color
    self.view.backgroundColor  = [UIColor whiteColor];
    
    [self.view addSubview:self.containerView];
    //[self.view addSubview:self.nearbyVenuesView];
    //[self.nearbyVenuesView.mapContainerView addSubview:self.mapContainerView];
    
    
    // Content views
    [self.containerView addSubview:self.localGridView];
    [self.containerView addSubview:self.worldGridView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    //nav
    [self.containerView addSubview:self.statusBar];
    [self.containerView addSubview:self.navBar];
    [self.containerView addSubview:self.segControlContainer];
    [self.containerView addSubview:self.scrollToTopBtn];
    
    //Location & Fault handling
    [self.view addSubview:self.errorView];
    [self.localGridView addSubview:self.locationPromptView];
    
    [self.localGridView.collectionView addSubview:self.refreshAfterNearbyFaultBtn];
    [self.worldGridView.collectionView addSubview:self.refreshAfterWorldFaultBtn];
    
    self.refreshAfterNearbyFaultBtn.center = CGPointMake(self.localGridView.frame.size.width/2, self.localGridView.frame.size.height/2 - CGRectGetMaxY(self.segControlContainer.frame));
    self.refreshAfterWorldFaultBtn.center = CGPointMake(self.worldGridView.frame.size.width/2, self.worldGridView.frame.size.height/2 - CGRectGetMaxY(self.segControlContainer.frame));
    
    //mam animation
    [self.view addSubview:self.mamAnimationView];
    [self.mamAnimationView addSubview:self.mamAnimationMapViewController.view];
    
    
    self.gridLoader.alpha = 1;
    
    if (self.locationAvailable) {
        [self.localGridView fetchNearbyGridContent];
    } else {
        self.localGridView.collectionView.scrollEnabled = NO;
        self.locationPromptView.hidden = NO;
    }
    [self.worldGridView fetchGridContent];
    
    self.filterItemWidth = floor((self.view.bounds.size.width - 16)/4);
    self.filterItemHeight = self.filterItemWidth - 11;
    
    [self.filtersCollectionView registerClass:[SPCMapFilterCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    self.flyViewController.view.backgroundColor = [UIColor whiteColor];
    [self refreshContent:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusBarChange:) name:@"statusbarchange" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLocationSilently) name:@"reloadLocations" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name: UIApplicationWillResignActiveNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryPosted:) name:@"addMemoryLocally" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prepareToAnimateMemory) name:@"finishMemAnimation" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(skipToWorldGrid) name:@"restoreExploreDefaults" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarSelectedItemDidChange:) name:kSPCTabBarSelectedItemDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMAM:) name:@"handleMAM" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissMAM:) name:@"dismissMAM" object:nil];
    
    if (EXPLORE_NEARBY_VENUE_REFRESH && !self.nearbyVenueRefreshTimer) {
        //NSLog(@"making venue refresh timer...");
        _nearbyVenueRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:EXPLORE_NEARBY_VENUE_REFRESH_INTERVAL target:self selector:@selector(refreshVenuesIfUserMoved) userInfo:nil repeats:YES];
    }
    
    [self.clippingView addSubview:self.expandingImageViewClipped];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = _pullToRefreshFadingHeader;
    }
    
    //show tab bar as needed
    
    if (self.displayingNearbyVenues) {
        self.tabBarController.tabBar.alpha = 0.0;
    }
    
    if (!self.displayingNearbyVenues) {
        self.tabBarController.tabBar.alpha = 1.0;
    }
    
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    }
    
    if (self.hmSegmentedControl.selectedSegmentIndex == 1) {
        if (self.locationAvailable) {
            self.localGridView.collectionView.scrollEnabled = YES;
            [self.localGridView gridDidAppear];
        }
    }
    if (self.hmSegmentedControl.selectedSegmentIndex == 0) {
        [self.worldGridView gridDidAppear];
    }
    if (self.displayingNearbyVenues) {
        self.mapViewController.isExplorePaused = NO;
    }
    
    
    if (!self.locationAvailable) {
        if ([CLLocationManager locationServicesEnabled] &&
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            self.gridLoader.alpha = 1;
            [self.localGridView fetchNearbyGridContent];
            self.locationAvailable = YES;
            self.nearbyVenuesBtn.hidden = NO;
            [self refreshContent:NO];
        }
    }
    
    if (![CLLocationManager locationServicesEnabled] ||
        ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)) {
        self.locationAvailable = NO;
        self.locationPromptView.hidden = NO;
        self.nearbyVenuesBtn.hidden = YES;
    }
    
    if (self.gridLoader.alpha > 0) {
        [self.gridLoader stopAnimating];
        [self.gridLoader startAnimating];
    }
    
    BOOL shouldChangeHandle = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldChangeHandle"];
    if (shouldChangeHandle) {
        [self forceHandleSelection];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.localGridView gridDidDisappear];
    [self.worldGridView gridDidDisappear];
    self.mapViewController.isExplorePaused = YES;
    [self.mapViewController viewWillDisappear:NO];
    
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = nil;
    }
    self.viewIsVisible = NO;
    
    if (SPCMontageViewStatePlaying == self.viewMontagePlaying.state) {
        [self.viewMontagePlaying pause];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.displayingNearbyVenues) {
        self.tabBarController.tabBar.alpha = 0.0;
        self.mapViewController.isExplorePaused = NO;
    }
    
    [self.mapViewController viewDidAppear:NO];
    self.viewIsVisible = YES;
    
    // Present a callout if necessary and content has loaded
    if (0 < self.worldGridView.cellCount && self.gridIsVisible) {
        [self presentQueuedCallout];
    }
    
    // Display the Anon Unlock view if appropriate
    BOOL showingScreen = NO;
    
    if ([SettingsManager sharedInstance].anonWarningNeeded && !self.anonWarningScreenWasShown && self.anonUnlockScreenWasShown && !showingScreen && self.gridIsVisible) {
        [self presentAnonWarningScreenAfterDelay:@(2.0f)];
        showingScreen = YES;
    }
    
    //NSLog(@"admin warning needed %d, admin warning count %d", [SettingsManager sharedInstance].adminWarningNeeded, [SettingsManager sharedInstance].currAdminWarningCount);
    if ([SettingsManager sharedInstance].adminWarningNeeded && !showingScreen && self.gridIsVisible) {
        //NSLog(@"present admin warning screen after delay...");
        [self presentAdminWarningScreenAfterDelay:@(2.0f)];
        showingScreen = YES;
    }
    
    // Ensure the MemCommentsVC is not up as well (using self.navFromGrid)
    if (SPCMontageViewStatePaused == self.viewMontagePlaying.state && nil == self.navFromGrid) {
        [self.viewMontagePlaying play];
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

-(void)applicationDidBecomeActive {
    
    BOOL locAvailable = [CLLocationManager locationServicesEnabled] &&
    ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
    
    NSLog(@"applicationDidBecomeActive");
    if (!self.locationAvailable || (self.didResignActiveDate && [NSDate date].timeIntervalSince1970 - self.didResignActiveDate.timeIntervalSince1970 > REFRESH_CONTENT_IF_INACTIVE_INTERVAL)) {
        if (locAvailable) {
            NSLog(@"became active and content needs refreshing!");
            [self restoreGridHeadersAndFooters];
            self.locationAvailable = YES;
            self.locationPromptView.hidden = YES;
            self.localGridView.collectionView.scrollEnabled = YES;

            if (self.hmSegmentedControl.selectedSegmentIndex == 0) {
                self.gridLoader.alpha = 1;
                [self.gridLoader stopAnimating];
                [self.gridLoader startAnimating];
                [self.worldGridView fetchGridContent];
            }
            
            else if (self.hmSegmentedControl.selectedSegmentIndex == 1) {
                [self.localGridView fetchNearbyGridContent];
            }
        }
    }
    else {
        if (locAvailable) {
            self.localGridView.collectionView.scrollEnabled = YES;
            self.locationAvailable = YES;
            NSLog("became active and content doesn't need refresh!");
          
            if (self.hmSegmentedControl.selectedSegmentIndex == 0) {
                [self.worldGridView gridDidAppear];
                
                //we don't have any world venues; get some
                if (self.worldGridView.cellCount == 0) {
                    self.gridLoader.alpha = 1;
                    [self.gridLoader stopAnimating];
                    [self.gridLoader startAnimating];
                    [self.worldGridView fetchGridContent];
                }
                else {
                    self.gridLoader.alpha = 0;
                }
            }
            
            if (self.hmSegmentedControl.selectedSegmentIndex == 1) {
                [self.localGridView gridDidAppear];
                
                //we don't have any nearby venues; get some
                if (self.localGridView.cellCount == 0) {
                    self.locationPromptView.hidden = YES;
                     [self.localGridView fetchNearbyGridContent];
                }
                
            }
        }
    }
    
    if (!locAvailable) {
        [self restoreGridHeadersAndFooters];
        self.localGridView.collectionView.scrollEnabled = NO;
        self.locationAvailable = NO;
        self.locationPromptView.hidden = NO;
        self.nearbyVenuesBtn.hidden = YES;
        self.gridLoader.alpha = 0;
    }
    
    if (EXPLORE_NEARBY_VENUE_REFRESH && !self.nearbyVenueRefreshTimer) {
        _nearbyVenueRefreshTimer = [NSTimer scheduledTimerWithTimeInterval:EXPLORE_NEARBY_VENUE_REFRESH_INTERVAL target:self selector:@selector(refreshVenuesIfUserMoved) userInfo:nil repeats:YES];
    }
    
    if (self.displayingNearbyVenues) {
        self.mapViewController.isExplorePaused = NO;
    }
    
    if (SPCMontageViewStatePaused == self.viewMontagePlaying.state && self.viewIsVisible && nil == self.navFromMontage) {
        [self.viewMontagePlaying play];
    }
    
    [self determineCalloutToShowFromEvent:CalloutEventTypeApplicationDidBecomeActive];
}


- (void)applicationWillResignActive {
    NSLog(@"applicationWillResignActive");
    self.didResignActiveDate = [NSDate date];
    [self.nearbyVenueRefreshTimer invalidate];
    _nearbyVenueRefreshTimer = nil;
    _mapViewController.isExplorePaused = YES;
    if (SPCMontageViewStatePlaying == self.viewMontagePlaying.state) {
        [self.viewMontagePlaying pause];
    }
    [self determineCalloutToShowFromEvent:CalloutEventTypeApplicationWillResignActive];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self configureRefreshControl];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

- (void)configureRefreshControl {
    if (!self.refreshAdded) {
        self.refreshAdded = YES;
        self.pullToRefreshManager = [[SPCPullToRefreshManager alloc] initWithScrollView:self.localGridView.collectionView];
        self.pullToRefreshManager.fadingHeaderView = self.pullToRefreshFadingHeader;
        self.pullToRefreshManager.delegate = self;
        
        self.worldPullToRefreshManager = [[SPCPullToRefreshManager alloc] initWithScrollView:self.worldGridView.collectionView];
        self.worldPullToRefreshManager.fadingHeaderView = self.pullToRefreshWorldFadingHeader;
        self.worldPullToRefreshManager.delegate = self;
        
        //set our base insets right after we have configured our refresh control
        [self.localGridView.collectionView setContentInset:UIEdgeInsetsMake(-1 * self.localGridView.baseOffSetY, 0, 0, 0)];
        [self.worldGridView.collectionView setContentInset:UIEdgeInsetsMake(-1 * self.worldGridView.baseOffSetY, 0, 0, 0)];
    }
}

- (void)tabBarSelectedItemDidChange:(NSNotification *)notification {
    // This beauty of code checks for a proper notification object that gives us the new value of the tab bar's selected index
    // If it is equal to the home tab bar index, we will update our callout status
    NSDictionary *notificationObject = (NSDictionary *)notification.object;
    
    if (nil != notificationObject) {
        NSObject *objectTabBar = [notificationObject objectForKey:@"bar"];
        if (nil != objectTabBar && [objectTabBar isKindOfClass:[UITabBar class]]) {
            UITabBar *bar = (UITabBar *)objectTabBar;
            
            NSObject *objectChange = [notificationObject objectForKey:@"change"];
            if (nil != objectChange && [objectChange isKindOfClass:[NSDictionary class]]) {
                NSDictionary *change = (NSDictionary *)objectChange;
                
                NSObject *objectTabBarItem = [change objectForKey:NSKeyValueChangeNewKey];
                if (nil != objectTabBarItem && [objectTabBarItem isKindOfClass:[UITabBarItem class]]) {
                    UITabBarItem *isItem = (UITabBarItem *)objectTabBarItem;
                    
                    NSUInteger is = [bar.items indexOfObject:isItem];
                    
                    if (TAB_BAR_HOME_ITEM_INDEX == is) {
                        [self determineCalloutToShowFromEvent:CalloutEventTypeHomeTabTapped];
                    }
                }
            }
        }
    }
}

#pragma mark - Accessors


- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:self.view.frame];
    }
    return _containerView;
}

// ----  nav / seg control

-(UIView *)statusBar {
    if (!_statusBar) {
        _statusBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 20)];
        _statusBar.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    }
    return _statusBar;
}

- (UIView *)navBar {
    
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 69)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIImageView *titleImage = [[UIImageView alloc] init];
        [titleImage setImage:[UIImage imageNamed:@"spayce-explore-logo"]];
        titleImage.frame = CGRectMake(CGRectGetMidX(_navBar.frame) - 75.0, CGRectGetMidY(_navBar.frame), 150.0, 18);
        titleImage.contentMode = UIViewContentModeScaleAspectFit;
        
        //[_navBar addSubview:self.flyBtn];
        
        [_navBar addSubview:titleImage];
        
        self.navBarOriginalCenterY = _navBar.center.y;
    }
    return _navBar;
    
}

- (UIButton *)flyBtn {
    if (!_flyBtn) {
        CGFloat statusBarHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
        CGFloat flyBtnDimension = CGRectGetHeight(self.navBar.frame) - statusBarHeight;
        _flyBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-55, statusBarHeight, flyBtnDimension, flyBtnDimension)];
        [_flyBtn setImage:[UIImage imageNamed:@"fly-btn"] forState:UIControlStateNormal];
        [_flyBtn addTarget:self action:@selector(flyPressed:) forControlEvents:UIControlEventTouchUpInside];
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
        [_nearbyVenuesBtn addTarget:self action:@selector(nearbyPressed:) forControlEvents:UIControlEventTouchUpInside];
        _nearbyVenuesBtn.alpha = 1;
        _nearbyVenuesBtn.userInteractionEnabled = YES;
    }
    return _nearbyVenuesBtn;
}

- (UIView *)segControlContainer {
    if (!_segControlContainer) {
        _segControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.view.bounds.size.width, 37)];
        _segControlContainer.backgroundColor = [UIColor whiteColor];
        
        [_segControlContainer addSubview:self.hmSegmentedControl];
        
        CGFloat fSepWidth = 1.0f / [UIScreen mainScreen].scale;
        CGFloat fSepHeight = 17.0f;
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - fSepWidth / 2.0f, CGRectGetHeight(_segControlContainer.frame) - 12.5f - fSepHeight, fSepWidth, fSepHeight)];
        sepLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepLine];
        
        self.segControlOriginalCenterY = _segControlContainer.center.y;
        self.maxAdjustment = CGRectGetMaxY(_segControlContainer.frame);
        
        _segControlContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        _segControlContainer.layer.shadowOffset = CGSizeMake(0, 1.0f/[UIScreen mainScreen].scale);
        _segControlContainer.layer.shadowOpacity = 0.12f;
        _segControlContainer.layer.shadowRadius = 1.0f/[UIScreen mainScreen].scale;
    }
    
    return _segControlContainer;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"WORLD", @"LOCAL"]];
        _hmSegmentedControl.frame = CGRectMake(0, 0, _segControlContainer.frame.size.width, 37);
        [_hmSegmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f + (self.view.bounds.size.width >= 375 ? 1.0f : 0.0f)];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
        _hmSegmentedControl.selectionIndicatorHeight = 3.0f;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        _hmSegmentedControl.shouldAnimateUserSelection = YES;
        _hmSegmentedControl.selectedSegmentIndex = 0;
        
        // Default explore state
        self.exploreState = ExploreStateWorld; // This should match the section title that corresponds to the selectedSegmentIndex
    }
    
    return _hmSegmentedControl;
}

- (UIView *)locationPromptView {
    
    if (!_locationPromptView) {
        _locationPromptView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame), self.view.bounds.size.width, self.gridLoader.frame.size.height)];
        _locationPromptView.backgroundColor = [UIColor whiteColor];
        _locationPromptView.hidden = YES;
        
        UILabel *promptLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.bounds.size.width, 40)];
        promptLbl.text = @"Spayce requires location to show you\nthe great memories around you.";
        promptLbl.textAlignment = NSTextAlignmentCenter;
        promptLbl.numberOfLines = 0;
        promptLbl.lineBreakMode = NSLineBreakByWordWrapping;
        promptLbl.font = [UIFont spc_regularSystemFontOfSize:14];
        promptLbl.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        [_locationPromptView addSubview:promptLbl];
        
        UIButton *locationBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - 210)/2, CGRectGetMaxY(promptLbl.frame) + 30, 210, 40)];
        [locationBtn setTitle:@"Turn On Location" forState:UIControlStateNormal];
        locationBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [locationBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [locationBtn setBackgroundColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f]];
        locationBtn.layer.cornerRadius = 20;
        [locationBtn addTarget:self action:@selector(showLocationPrompt:) forControlEvents:UIControlEventTouchUpInside];
        [_locationPromptView addSubview:locationBtn];
        
    }
    return _locationPromptView;
    
}

// ----  main content

- (SPCGrid *)localGridView {
    if (!_localGridView) {
        _localGridView = [[SPCGrid alloc] initWithFrame:CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _localGridView.delegate = self;
        float initialOffset = -1 * (CGRectGetHeight(self.segControlContainer.frame) + CGRectGetHeight(self.navBar.frame));
        [_localGridView setBaseContentOffset:initialOffset];
        [_localGridView.collectionView setScrollIndicatorInsets:UIEdgeInsetsMake(CGRectGetHeight(self.segControlContainer.frame) + CGRectGetHeight(self.navBar.frame), 0, 0, 0)];
        _localGridView.viewMontage = self.viewMontageLocal;
        _localGridView.montageLastViewedMemories = [self montageLastViewedMemoriesLocal];
    }
    return _localGridView;
}

- (SPCGrid *)worldGridView {
    if (!_worldGridView) {
        _worldGridView = [[SPCGrid alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _worldGridView.delegate = self;
        float initialOffset = -1 * (CGRectGetHeight(self.segControlContainer.frame) + CGRectGetHeight(self.navBar.frame));
        [_worldGridView setBaseContentOffset:initialOffset];
        [_worldGridView.collectionView setScrollIndicatorInsets:UIEdgeInsetsMake(CGRectGetHeight(self.segControlContainer.frame) + CGRectGetHeight(self.navBar.frame), 0, 0, 0)];
         [_worldGridView addSubview:self.gridLoader];
        _worldGridView.viewMontage = self.viewMontageWorld;
        _worldGridView.montageLastViewedMemories = [self montageLastViewedMemoriesWorld];
    }
    return _worldGridView;
}

-(UIView *)errorView {
    if (!_errorView) {
        _errorView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame), self.view.frame.size.width, 120)];
        _errorView.hidden = YES;
        _errorView.clipsToBounds = YES;
    }
    return _errorView;
}


- (UIView *)mapContainerView {
    if (!_mapContainerView) {
        _mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame),self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.segControlContainer.frame))];
        //[_mapContainerView addSubview:self.mapViewController.view];
        
        [_mapContainerView addSubview:self.refreshLocationBtn];
        [_mapContainerView addSubview:self.dismissFiltersOverlayBtn];
        [_mapContainerView addSubview:self.filtersBtn];
        [_mapContainerView addSubview:self.filtersContainer];
        
        [_mapContainerView addSubview:self.mapLoader];
        _mapContainerView.clipsToBounds = YES;
    }
    
    return _mapContainerView;
}

- (SPCNearbyVenuesView *)nearbyVenuesView {
    if (!_nearbyVenuesView) {
        _nearbyVenuesView = [[SPCNearbyVenuesView alloc] initWithFrame:CGRectMake(-self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _nearbyVenuesView.delegate = self;
        _nearbyVenuesView.clipsToBounds = YES;
    }
    return _nearbyVenuesView;
}

- (SPCHereVenueMapViewController *)mapViewController {
    if (!_mapViewController) {
        _mapViewController = [[SPCHereVenueMapViewController alloc] init];
        _mapViewController.delegate = self;
        _mapViewController.isExplorePaused = YES;
        _mapViewController.isExploreOn = NO;
        // TODO: turn explore mode back on if we re-enable mapViewController.
    }
    return _mapViewController;
}

- (SPCHereVenueSelectionViewController *)venueSelectionViewController {
    if (!_venueSelectionViewController) {
        _venueSelectionViewController = [[SPCHereVenueSelectionViewController alloc] init];
        _venueSelectionViewController.delegate = self;
        [_venueSelectionViewController sizeToFitPerPage:3];
    }
    return _venueSelectionViewController;
}

- (SPCFlyViewController *)flyViewController {
    if (!_flyViewController) {
        _flyViewController = [[SPCFlyViewController alloc] init];
        _flyViewController.delegate = self;
        
    }
    return _flyViewController;
}

- (UIButton *)filtersBtn {
    if (!_filtersBtn) {
        _filtersBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 17, 75, 30)];
        [_filtersBtn setTitle:@"Filters" forState:UIControlStateNormal];
        [_filtersBtn setBackgroundColor:[UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:.8]];
        [_filtersBtn addTarget:self action:@selector(toggleFilters) forControlEvents:UIControlEventTouchDown];
        _filtersBtn.layer.cornerRadius = 14;
        _filtersBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        [_filtersBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _filtersBtn.layer.shadowColor = [UIColor colorWithWhite:0 alpha:.2].CGColor;
        _filtersBtn.layer.shadowOffset = CGSizeMake(1, 1);
        _filtersBtn.layer.shadowRadius = 1;
    }
    return _filtersBtn;
}

- (UIView *)filtersContainer {
    if (!_filtersContainer) {
        _filtersContainer = [[UIView alloc] initWithFrame:CGRectMake(8, 57, 0, 0)];
        _filtersContainer.clipsToBounds = YES;
        _filtersContainer.layer.cornerRadius = 4;
        
        UIImageView *filterTri = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"filter-tri"]];
        filterTri.center = CGPointMake(40, 3);
        [_filtersContainer addSubview:filterTri];
        
        [_filtersContainer addSubview:self.filtersCollectionView];
    }
    return _filtersContainer;
}

- (UICollectionView *) filtersCollectionView {
    if (!_filtersCollectionView) {
        UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        layout.itemSize = CGSizeMake(self.filterItemWidth, self.filterItemHeight);
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _filtersCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 5, self.view.bounds.size.width, self.view.bounds.size.height) collectionViewLayout:layout];
        [_filtersCollectionView setDataSource:self];
        [_filtersCollectionView setDelegate:self];
        _filtersCollectionView.allowsMultipleSelection = YES;
        _filtersCollectionView.scrollEnabled = NO;
        
        _filtersCollectionView.alwaysBounceVertical = YES;
        _filtersCollectionView.backgroundColor = [UIColor whiteColor];
        _filtersCollectionView.layer.cornerRadius = 4;
        [_filtersCollectionView registerClass:[SPCMapFilterCollectionViewCell class] forCellWithReuseIdentifier:CellIdentifier];
    }
    return _filtersCollectionView;
}

-(UIButton *)dismissFiltersOverlayBtn {
    if (!_dismissFiltersOverlayBtn) {
        _dismissFiltersOverlayBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.mapContainerView.frame.size.width, self.mapContainerView.frame.size.height)];
        _dismissFiltersOverlayBtn.hidden = YES;
        [_dismissFiltersOverlayBtn addTarget:self action:@selector(dismissFilters) forControlEvents:UIControlEventTouchDown];
        _dismissFiltersOverlayBtn.backgroundColor = [UIColor colorWithWhite:0 alpha:.15];
    }
    return _dismissFiltersOverlayBtn;
}

- (UIButton *)refreshLocationBtn {
    if (!_refreshLocationBtn) {
        _refreshLocationBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 90, 14, 80, 35)];
        [_refreshLocationBtn setImage:[UIImage imageNamed:@"button-refresh-oval"] forState:UIControlStateNormal];
        [_refreshLocationBtn addTarget:self action:@selector(refreshLocation) forControlEvents:UIControlEventTouchUpInside];
    }
    return _refreshLocationBtn;
}

- (UIButton *)refreshAfterNearbyFaultBtn {
    if (!_refreshAfterNearbyFaultBtn) {
        _refreshAfterNearbyFaultBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        [_refreshAfterNearbyFaultBtn setBackgroundColor:[UIColor clearColor]];
        [_refreshAfterNearbyFaultBtn setImage:[UIImage imageNamed:@"faultRetryBtn"] forState:UIControlStateNormal];
        _refreshAfterNearbyFaultBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [_refreshAfterNearbyFaultBtn setTitleEdgeInsets:UIEdgeInsetsMake(10, -50, 0, 0)];
        _refreshAfterNearbyFaultBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_refreshAfterNearbyFaultBtn setImageEdgeInsets:UIEdgeInsetsMake(30, 70, 100, 0)];
        [_refreshAfterNearbyFaultBtn setTitle:@"Tap to retry" forState:UIControlStateNormal];
        [_refreshAfterNearbyFaultBtn setTitleColor:[UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [_refreshAfterNearbyFaultBtn addTarget:self action:@selector(refreshNearbyAfterFault) forControlEvents:UIControlEventTouchDown];
        _refreshAfterNearbyFaultBtn.hidden = YES;
    }
    return _refreshAfterNearbyFaultBtn;
}

- (UIButton *)refreshAfterWorldFaultBtn {
    if (!_refreshAfterWorldFaultBtn) {
        _refreshAfterWorldFaultBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
        [_refreshAfterWorldFaultBtn setBackgroundColor:[UIColor clearColor]];
        [_refreshAfterWorldFaultBtn setImage:[UIImage imageNamed:@"faultRetryBtn"] forState:UIControlStateNormal];
        _refreshAfterWorldFaultBtn.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        [_refreshAfterWorldFaultBtn setTitleEdgeInsets:UIEdgeInsetsMake(10, -50, 0, 0)];
        _refreshAfterWorldFaultBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_refreshAfterWorldFaultBtn setImageEdgeInsets:UIEdgeInsetsMake(30, 70, 100, 0)];
        [_refreshAfterWorldFaultBtn setTitle:@"Tap to retry" forState:UIControlStateNormal];
        [_refreshAfterWorldFaultBtn setTitleColor:[UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [_refreshAfterWorldFaultBtn addTarget:self action:@selector(refreshWorldAfterFault) forControlEvents:UIControlEventTouchUpInside];
        _refreshAfterWorldFaultBtn.hidden = YES;
    }
    return _refreshAfterWorldFaultBtn;
}


- (UIButton *)createLocationBtn {
    if (!_createLocationBtn) {
        _createLocationBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 91, 17, 31, 31)];
        [_createLocationBtn setImage:[UIImage imageNamed:@"create-loc-btn"] forState:UIControlStateNormal];
        [_createLocationBtn addTarget:self action:@selector(createLocation) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _createLocationBtn;
}

- (UIImageView *)animationImageView {
    if (!_animationImageView) {
        _animationImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
        _animationImageView.backgroundColor = [UIColor whiteColor];
        _animationImageView.clipsToBounds = YES;
    }
    return _animationImageView;
}

- (SPCEarthquakeLoader *)gridLoader {
    if (!_gridLoader) {
        _gridLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.segControlContainer.frame), self.localGridView.frame.size.width, self.localGridView.frame.size.height - self.segControlContainer.frame.size.height - 44)];
        _gridLoader.msgLabel.text = @"Getting Moments...";
    }
    return _gridLoader;
}


- (SPCEarthquakeLoader *)mapLoader {
    if (!_mapLoader) {
        _mapLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, 0, self.mapContainerView.frame.size.width, self.mapContainerView.frame.size.height)];
        
        _mapLoader.msgLabel.text = @"Updating Location...";
    }
    return _mapLoader;
}


- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self.localGridView action:@selector(fetchNearbyGridContent) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (UIRefreshControl *)worldRefreshControl {
    if (!_worldRefreshControl) {
        _worldRefreshControl = [[UIRefreshControl alloc] init];
        [_worldRefreshControl addTarget:self.worldGridView action:@selector(fetchGridContent) forControlEvents:UIControlEventValueChanged];
    }
    return _worldRefreshControl;
}

- (UIButton *)scrollToTopBtn {
    if (!_scrollToTopBtn) {
        _scrollToTopBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        [_scrollToTopBtn addTarget:self action:@selector(scrollToTop) forControlEvents:UIControlEventTouchDown];
        _scrollToTopBtn.backgroundColor = [UIColor clearColor];
    }
    return _scrollToTopBtn;
}


-(UIView *)mamAnimationView {
    if (!_mamAnimationView) {
        _mamAnimationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        _mamAnimationView.hidden = YES;
    }
    return _mamAnimationView;
}

- (SPCHereVenueMapViewController *)mamAnimationMapViewController {
    if (!_mamAnimationMapViewController) {
        _mamAnimationMapViewController = [[SPCHereVenueMapViewController alloc] init];
        _mamAnimationMapViewController.delegate = self;
        _mamAnimationMapViewController.isExplorePaused = YES;
        _mamAnimationMapViewController.isExploreOn = NO;
        _mamAnimationMapViewController.isViewingFromHashtags = YES; //not really, but abusing this to turn off the map limits
        _mamAnimationMapViewController.mapView.padding = UIEdgeInsetsMake(44, 0, 50, 0);
    }
    return _mamAnimationMapViewController;
}

- (SPCMontageView *)viewMontageLocal {
    if (nil == _viewMontageLocal) {
        _viewMontageLocal = [[SPCMontageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)*3.0/4.0f)];
        _viewMontageLocal.delegate = self;
    }
    
    return _viewMontageLocal;
}

- (SPCMontageView *)viewMontageWorld {
    if (nil == _viewMontageWorld) {
        _viewMontageWorld = [[SPCMontageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)*3.0/4.0f)];
        _viewMontageWorld.delegate = self;
    }
    
    return _viewMontageWorld;
}


- (UIImageView *)expandingImageView {
    if (!_expandingImageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.hidden = YES;
        _expandingImageView = imageView;
    }
    return _expandingImageView;
}

- (UIImageView *)expandingImageViewClipped {
    if (!_expandingImageViewClipped) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.hidden = YES;
        _expandingImageViewClipped = imageView;
    }
    return _expandingImageViewClipped;
}

- (UIView *)clippingView {
    if (!_clippingView) {
        _clippingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    }
    return _clippingView;
}

- (BOOL)gridIsVisible {
    BOOL montageIsNotVisible = nil == self.viewMontagePlaying;
    BOOL memCommentsVCisNotVisible = nil == self.navFromGrid;
    
    return self.viewIsVisible && montageIsNotVisible && memCommentsVCisNotVisible;
}


#pragma mark - SPCGrid delegate methods

-(void)showVenueDetailFeed:(Venue *)v {
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = v;
    [venueDetailViewController fetchMemories];
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

-(void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)m {
    if (m) {
        [self showVenueDetail:v jumpToMemory:m withImage:nil atRect:CGRectZero];
    }
    else {
        [self showVenueDetailFeed:v];
    }
}

-(void)showVenueDetail:(Venue *)v {
    [self showVenueDetail:v jumpToMemory:nil];
}

-(void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)memory withImage:(UIImage *)image atRect:(CGRect)rect {
    if ([AuthenticationManager sharedInstance].currentUser) {
        //capture image of screen to use in MAM completion animation
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        UIGraphicsBeginImageContextWithOptions(rootViewController.view.bounds.size, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [rootViewController.view.layer renderInContext:context];
        UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        SPCVenueDetailGridTransitionViewController *vc = [[SPCVenueDetailGridTransitionViewController alloc] init];
        vc.venue = v;
        vc.memory = memory;
        vc.backgroundImage = currentScreenImg;
        vc.gridCellImage = image;
        vc.gridCellFrame = rect;
        
        // clip rect?
        CGFloat top = MAX(CGRectGetMaxY(self.segControlContainer.frame), CGRectGetMaxY(self.statusBar.frame));
        CGFloat bottom = CGRectGetMinY(self.navigationController.tabBarController.tabBar.frame);
        //NSLog(@"mask to the area from %f to %f", top, bottom);
        CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
        vc.gridClipFrame = maskRect;
        
        SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
        navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
        [self presentViewController:navController animated:NO completion:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
    }
}


- (void)showPerson:(Person *)person {
    SPCProfileViewController *pvc = [[SPCProfileViewController alloc] initWithUserToken:person.userToken];
    
    // Present it
    [self.navigationController pushViewController:pvc animated:YES];
}


-(void)showMemoryComments:(Memory *)m {
    [self showMemoryComments:m withImage:nil atRect:CGRectZero];
}

/*
-(void)showMemoryComments:(Memory *)m withImage:(UIImage *)image atRect:(CGRect)rect {
    if ([AuthenticationManager sharedInstance].currentUser) {
        //capture image of screen to use in MAM completion animation
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        UIGraphicsBeginImageContextWithOptions(rootViewController.view.bounds.size, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [rootViewController.view.layer renderInContext:context];
        UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // clip rect?
        CGFloat top = MAX(CGRectGetMaxY(self.segControlContainer.frame), CGRectGetMaxY(self.statusBar.frame));
        CGFloat bottom = CGRectGetMinY(self.navigationController.tabBarController.tabBar.frame);
        //NSLog(@"mask to the area from %f to %f", top, bottom);
        CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
        
        // show comments...
        MemoryCommentsViewController *vc = [[MemoryCommentsViewController alloc] initWithMemory:m];
        vc.viewingFromGrid = YES;
        vc.backgroundImage = currentScreenImg;
        vc.gridCellImage = image;
        vc.gridCellFrame = rect;
        vc.gridClipFrame = maskRect;
        
        SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
        navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
        [self presentViewController:navController animated:NO completion:nil];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
    }
}
 */


-(void)showMemoryComments:(Memory *)m withImage:(UIImage *)image atRect:(CGRect)rect {
    
    if ([AuthenticationManager sharedInstance].currentUser) {
        // clip rect?
        CGFloat top = MAX(CGRectGetMaxY(self.segControlContainer.frame), CGRectGetMaxY(self.statusBar.frame));
        //NSLog(@"mask to the area from %f to %f", top, bottom);
        CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-top);
        
        // Create a mask layer
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        
        // Create a path with our clip rect in it
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        
        // The path is not covered by ARC
        CGPathRelease(path);
        
        self.clippingView.layer.mask = maskLayer;
        
        BOOL hasImage = image != nil;
        
        self.expandingImageView.image = image;
        self.expandingImageViewClipped.image = image;
        self.expandingImageView.frame = rect;
        self.expandingImageViewClipped.frame = rect;
        
        self.expandingImageView.alpha = 0;
        self.expandingImageViewClipped.alpha = 1;
        
        self.expandingImageView.hidden = !hasImage;
        self.expandingImageViewClipped.hidden = !hasImage;
        
        self.expandingImageRect = rect;
        
        // Create the mcvc
        MemoryCommentsViewController *mcvc = [[MemoryCommentsViewController alloc] initWithMemory:m];
        mcvc.viewingFromGrid = YES;
        mcvc.gridCellImage = image;
        mcvc.animateTransition = NO;

        UIViewController *vc = [[UIViewController alloc] init];
        self.navFromGrid = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
        [self.navFromGrid pushViewController:mcvc animated:NO];
        
        // Get the memory's new center
        CGSize constraint = CGSizeMake([UIScreen mainScreen].bounds.size.width, CGFLOAT_MAX);
        CGFloat newTop = [MemoryCell measureMainContentOffsetWithMemory:m constrainedToSize:constraint] + mcvc.tableStart;
        CGRect newFrame = hasImage ? CGRectMake(0, newTop, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame)) : CGRectZero;
        
        // Animate in the MCVC (alpha 0 -> 1), while shifting the montage view to its new center (while above the MCVC)
        self.navFromGrid.view.alpha = 0.0f;
        [self addChildViewController:self.navFromGrid];
        [self.view addSubview:self.navFromGrid.view];
        [self.view addSubview:self.clippingView];
        [self.view addSubview:self.expandingImageView];
        
        NSTimeInterval timeToTravelDistance = 0;
        if (hasImage) {
            CGFloat xDist = CGRectGetMidX(rect) - CGRectGetMidX(newFrame);
            CGFloat yDist = CGRectGetMidY(rect) - CGRectGetMidY(newFrame);
            timeToTravelDistance = 0.0015f * sqrt(xDist * xDist + yDist * yDist);
        }
        NSTimeInterval minTime = 0.3;
        NSTimeInterval travelTime = MAX(minTime, timeToTravelDistance);
        [UIView animateWithDuration:travelTime animations:^{
            // Adjust the frame
            self.expandingImageView.frame = newFrame;
            self.expandingImageViewClipped.frame = newFrame;
        }];
        [UIView animateWithDuration:travelTime delay:0.12 options:0 animations:^{
            self.navFromGrid.view.alpha = 1.0f;
        } completion:^(BOOL finished) {
            if (finished) {
                // Our hack to make the back button usable on the MCVC
                [mcvc.backButton addTarget:self action:@selector(returnToGridFromNav) forControlEvents:UIControlEventTouchUpInside];
                
                // Send the images behind the MCVC
                [self.view insertSubview:self.clippingView belowSubview:self.navFromGrid.view];
                [self.view insertSubview:self.expandingImageView belowSubview:self.navFromGrid.view];
            }
        }];
        self.expandingDidHideTabBar = ![self.tabBarController didSlideTabBarHidden];
        if (self.expandingDidHideTabBar) {
            [self.tabBarController slideTabBarHidden:YES animated:YES];
        }
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
    }
}


- (void)returnToGridFromNav {
    [self setNeedsStatusBarAppearanceUpdate];
    UINavigationController *nav = self.navFromGrid;
    self.navFromGrid = nil;
    if (nil != nav.parentViewController) {
        BOOL hasImage = !self.expandingImageView.hidden;
        NSTimeInterval timeToTravelDistance = 0;
        if (hasImage) {
            CGFloat xDist = CGRectGetMidX(self.expandingImageView.frame) - CGRectGetMidX(self.expandingImageRect);
            CGFloat yDist = CGRectGetMidY(self.expandingImageView.frame) - CGRectGetMidY(self.expandingImageRect);
            timeToTravelDistance = 0.0015f * sqrt(xDist * xDist + yDist * yDist);
        }
        NSTimeInterval minTime = 0.3;
        NSTimeInterval travelTime = MAX(minTime, timeToTravelDistance);
        [UIView animateWithDuration:(travelTime) animations:^{
            nav.view.alpha = 0.0f;
            self.expandingImageView.frame = self.expandingImageRect;
            self.expandingImageViewClipped.frame = self.expandingImageRect;
        } completion:^(BOOL finished) {
            [nav.view removeFromSuperview];
            [nav removeFromParentViewController];
            for (UIViewController *viewController in nav.childViewControllers) {
                if ([viewController isKindOfClass:[MemoryCommentsViewController class]]) {
                    NSLog(@"clean up comments so it will dealloc??");
                    MemoryCommentsViewController *memCVC = (MemoryCommentsViewController *)viewController;
                    memCVC.gridCellImage = nil;
                    memCVC.backgroundImage = nil;
                    memCVC.exitBackgroundImage = nil;
                    [memCVC removeKeyControl];
                    [memCVC cleanUp];
                }
            }
            
            [self.expandingImageView removeFromSuperview];
            [self.clippingView removeFromSuperview];
            [self cleanUpNavAnimation];
        }];
        if ((self.expandingDidHideTabBar || self.isNavBarFullyVisible) && self.isTabBarAllowed) {
            [self.tabBarController slideTabBarHidden:NO animated:YES];
        }
    } else {
        [nav dismissViewControllerAnimated:YES completion:^{
            [self cleanUpNavAnimation];
        }];
        [self.expandingImageView removeFromSuperview];
        [self.clippingView removeFromSuperview];
    }
    
}

-(void)cleanUpNavAnimation {
    
    for (UIViewController *viewController in self.navFromGrid.childViewControllers) {
            [viewController removeFromParentViewController];
            [viewController.view removeFromSuperview];
    }
    
    self.navFromGrid = nil;
}

-(void)showVenueDetail:(Venue *)v jumpToRecentMemory:(Memory *)memory {
    if ([AuthenticationManager sharedInstance].currentUser) {
        //capture image of screen to use in MAM completion animation
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        UIGraphicsBeginImageContextWithOptions(rootViewController.view.bounds.size, YES, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [rootViewController.view.layer renderInContext:context];
        UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        SPCVenueDetailGridTransitionViewController *vc = [[SPCVenueDetailGridTransitionViewController alloc] init];
        vc.venue = memory.venue;
        vc.memory = memory;
        vc.backgroundImage = currentScreenImg;
        vc.exitBackgroundImage = self.gridScreenCapForTransition;
        vc.snapTransitionDismiss = YES;
        
        // clip rect?
        CGFloat top = MAX(CGRectGetMaxY(self.segControlContainer.frame), CGRectGetMaxY(self.statusBar.frame));
        CGFloat bottom = CGRectGetMinY(self.navigationController.tabBarController.tabBar.frame);
        //NSLog(@"mask to the area from %f to %f", top, bottom);
        CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
        vc.gridClipFrame = maskRect;
        
        SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
        navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
        [self presentViewController:navController animated:NO completion:^{
            self.mamAnimationView.hidden = YES;
        }];
    }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
    }
}

- (void)scrollingUpAdjustViewsWithDelta:(float)deltaAdj {
    
    //disable movement during pull to refresh
    if (!self.pullToRefreshStarted) {
        
        //adjust the views from their current position, based on movement of collection view
        if (self.navBar.center.y - deltaAdj > self.navBarOriginalCenterY - self.maxAdjustment) {
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBar.center.y  - deltaAdj);
            self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlContainer.center.y - deltaAdj);
            self.statusBar.alpha = 1.0f;
        }
        //cap the maximum movement
        else {
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY - self.maxAdjustment);
            self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY - self.maxAdjustment);
            [self.tabBarController slideTabBarHidden:YES animated:YES]; //only hide tab bar when our top nav is fully off screen
        }
        
    }
}

- (void)scrollingDownAdjustViewsWithDelta:(float)deltaAdj {
    
    //disable movement during pull to refresh
    if (!self.pullToRefreshStarted) {
        //adjust views from their current position, based on movement of collection view
        if (self.navBar.center.y + deltaAdj <= self.navBarOriginalCenterY) {
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBar.center.y + deltaAdj);
            self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlContainer.center.y + deltaAdj);
            if (self.isTabBarAllowed) {
                [self.tabBarController slideTabBarHidden:NO animated:YES]; //show tab bar immediately if user is looking for it
            }
            
        }
        //everything should be reset to its original position
        else {
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
            self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
        }
    }
}

- (void)nearbyContentComplete {
    if (self.pullToRefreshStarted) {
        self.pullToRefreshInProgress = NO; //only used to limit funky scrolling during PTR
        //NSLog(@"nearby content complete & pull to referesh is over. restore the view and reactivate the grid scrolling behavior");
        
        self.pullToRefreshManager.loadingView.clipsToBounds = YES;
        [self.pullToRefreshManager hideContentUntilStateChange];
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
            self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
            [self.localGridView.collectionView setContentOffset:CGPointMake(0, -1 * CGRectGetMaxY(self.segControlContainer.frame)) animated:NO];
            self.navBar.alpha = 1.0;
            self.segControlContainer.alpha = 1.0;
            
        }
                         completion:^(BOOL completion) {
                             
                             self.statusBar.alpha = 1.0;
                             self.pullToRefreshStarted = NO;
                             
                             [self.pullToRefreshManager refreshFinishedAnimated:NO];
                         }];
        
        if (self.isTabBarAllowed) {
            [self.tabBarController setTabBarHidden:NO];
            [self.tabBarController slideTabBarHidden:NO animated:YES];
        }
        
        // Refresh the montage as well
        if (self.hasPerformedInitialMontageNearbyFetch && 0 < self.localGridView.cellCount) {
            [self.localGridView refreshMontageContentIfNeeded];
        }
    }
    
    
    //handle fault
    if (self.localGridView.cellCount == 0) {
        if (self.errorView.hidden) {
            self.errorView.hidden = NO;
            [self spc_hideNotificationBanner];
            [self spc_showNotificationBannerInParentView:self.errorView title:NSLocalizedString(@"Couldn't Connect To Network", nil) customText:NSLocalizedString(@"Please check your connection.",nil)];
        }
        self.refreshAfterNearbyFaultBtn.hidden = NO;
    }
    else {
        self.refreshAfterNearbyFaultBtn.hidden = YES;
        self.errorView.hidden = YES;
    }
    
    [self determineCalloutToShowFromEvent:CalloutEventTypeLocalGridLoaded];
    
    // Refresh the montage if this is the first time the grid has been loaded
    if (NO == self.hasPerformedInitialMontageNearbyFetch && 0 < self.localGridView.cellCount) {
        self.hasPerformedInitialMontageNearbyFetch = YES;
        [self.localGridView refreshMontageContentIfNeeded];
    }
}

- (void)worldContentComplete {
    
    //NSLog(@"world content complete??");
    
    if (self.pullToRefreshStarted) {
        self.pullToRefreshInProgress = NO; //only used to limit funky scrolling during PTR
        //NSLog(@"nearby content complete & pull to referesh is over. restore the view and reactivate the grid scrolling behavior");
        
        self.worldPullToRefreshManager.loadingView.clipsToBounds = YES;
        [self.worldPullToRefreshManager hideContentUntilStateChange];
        
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
            self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
            [self.worldGridView.collectionView setContentOffset:CGPointMake(0, -1 * CGRectGetMaxY(self.segControlContainer.frame)) animated:NO];
            self.navBar.alpha = 1.0;
            self.segControlContainer.alpha = 1.0;
            
        }
                         completion:^(BOOL completion) {
                             
                             self.statusBar.alpha = 1.0;
                             self.pullToRefreshStarted = NO;
                             
                             [self.worldPullToRefreshManager refreshFinishedAnimated:NO];
                         }];
        
        if (self.isTabBarAllowed) {
            [self.tabBarController setTabBarHidden:NO];
            [self.tabBarController slideTabBarHidden:NO animated:YES];
        }
        
        // Refresh the montage's content as well
        if (self.hasPerformedInitialMontageWorldFetch && 0 < self.worldGridView.cellCount) {
            [self.worldGridView refreshMontageContentIfNeeded];
        }
    }
    
    self.gridLoader.alpha = 0;
    [self.gridLoader stopAnimating];
    
    
    //handle fault
    if (self.worldGridView.cellCount == 0) {
        if (self.errorView.hidden) {
            self.errorView.hidden = NO;
            [self spc_hideNotificationBanner];
            [self spc_showNotificationBannerInParentView:self.errorView title:NSLocalizedString(@"Couldn't Connect To Network", nil) customText:NSLocalizedString(@"Please check your connection.",nil)];
        }
        self.refreshAfterWorldFaultBtn.hidden = NO;
        
    } else {
        self.refreshAfterWorldFaultBtn.hidden = YES;
        self.errorView.hidden = YES;
    }
    
    if (NO == self.hasPerformedInitialMontageWorldFetch && 0 < self.worldGridView.cellCount) {
        self.hasPerformedInitialMontageWorldFetch = YES;
        [self.worldGridView refreshMontageContentIfNeeded];
    }
}


- (void)gridScrolled:(UIScrollView *)scrollView {
    BOOL isDragging = NO;
    
    if (self.exploreState == ExploreStateLocal) {
        [self.pullToRefreshManager scrollViewDidScroll:scrollView];
        isDragging = self.localGridView.draggingScrollView;
    }
    if (self.exploreState == ExploreStateWorld) {
        [self.worldPullToRefreshManager scrollViewDidScroll:scrollView];
        isDragging = self.worldGridView.draggingScrollView;
    }
    
    if (!self.pullToRefreshStarted) {
        if (scrollView.contentOffset.y <= -scrollView.contentInset.top) {
            // Fade out navigation bar
            [UIView animateWithDuration:0.35 animations:^{
                self.navBar.alpha = isDragging ? 0.9 : 1.0;
                self.segControlContainer.alpha = isDragging ? 0.9 : 1.0;
                self.statusBar.alpha = 0;
            }];
            // Fade in/out tab bar
            if (isDragging || self.isTabBarAllowed) {
                [self.tabBarController setTabBarHidden:isDragging animated:YES];
            }
        } else if (self.navBar.alpha < 1 && isDragging) {
            // Fade in navigation bar
            [UIView animateWithDuration:0.35 animations:^{
                self.navBar.alpha = 1.0;
                self.segControlContainer.alpha = 1.0;
                self.statusBar.alpha = 1;
            }];
            // Fade in/out tab bar
            if (self.isTabBarAllowed) {
                [self.tabBarController setTabBarHidden:NO animated:YES];
            }
        }
    }
    
    
    //prevent funky overscroll during PTR
    if (self.pullToRefreshInProgress) {
        
        float refreshPoint = self.localGridView.baseOffSetY - ((self.navBar.frame.size.height + self.segControlContainer.frame.size.height));
        
        // refresh point for iOS 8
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
            
            if (scrollView.contentOffset.y > refreshPoint) {
                if (!self.gridAlignmentFailSafeTriggered) {
                    NSLog(@"reset grid for fail safe!");
                    self.gridAlignmentFailSafeTriggered = YES;
                    [scrollView setContentOffset:CGPointMake(0, refreshPoint) animated:YES];
                }
            }
        }
        // legcy iOS versions
        else {
            refreshPoint = self.localGridView.baseOffSetY;
            
            if (scrollView.contentOffset.y > refreshPoint) {
                if (!self.gridAlignmentFailSafeTriggered) {
                    self.gridAlignmentFailSafeTriggered = YES;
                    [scrollView setContentOffset:CGPointMake(0, refreshPoint) animated:YES];
                }
            }
        }
    }
}

- (void)gridDragEnded:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    if (self.exploreState == ExploreStateLocal) {
        [self.pullToRefreshManager scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
    if (self.exploreState == ExploreStateWorld) {
        [self.worldPullToRefreshManager scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)restoreGridHeadersAndFooters {
    
    // !!! begin by restoring our base offsets for both local and world grids to prevent the reactivation offset bug that occurs when the world grid updates offscreen upon reactivaton after app has gone deactive while on world grid after having paginated...whew..
    self.localGridView.collectionView.contentOffset = CGPointMake(0, self.localGridView.baseOffSetY);
    self.worldGridView.collectionView.contentOffset = CGPointMake(0, self.worldGridView.baseOffSetY);
    
    //make sure our seg control and nav bar are fully in place
    self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
    self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
    if (self.isTabBarAllowed) {
        [self.tabBarController slideTabBarHidden:NO animated:NO];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.activeFilters.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCMapFilterCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    [cell configureWithFilter:self.activeFilters[indexPath.item]];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.filterItemWidth, self.filterItemHeight);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCMapFilterCollectionViewCell *cell = (SPCMapFilterCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell toggleFilter];
    
    if ((indexPath.item == 0) && cell.filterSelected) {
        [self selectAllFilters];
    }
    
    if (!cell.filterSelected) {
        NSIndexPath *allIndex = [NSIndexPath indexPathForItem:0 inSection:0];
        SPCMapFilterCollectionViewCell *allCell = (SPCMapFilterCollectionViewCell *)[self.filtersCollectionView cellForItemAtIndexPath:allIndex];
        if (allCell.filterSelected) {
            [allCell toggleFilter];
        }
    }
}
-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCMapFilterCollectionViewCell *cell = (SPCMapFilterCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [cell toggleFilter];
    
    if ((indexPath.item == 0) && cell.filterSelected) {
        [self selectAllFilters];
    }
    
    if (!cell.filterSelected) {
        NSIndexPath *allIndex = [NSIndexPath indexPathForItem:0 inSection:0];
        SPCMapFilterCollectionViewCell *allCell = (SPCMapFilterCollectionViewCell *)[self.filtersCollectionView cellForItemAtIndexPath:allIndex];
        if (allCell.filterSelected) {
            [allCell toggleFilter];
        }
    }
}

#pragma mark - SPCPullToRefreshManagerDelegate

- (void)pullToRefreshTriggered:(SPCPullToRefreshManager *)manager {
    NSLog(@"pull to refresh triggered??");
    self.pullToRefreshInProgress = YES;
    self.gridAlignmentFailSafeTriggered = NO;
    self.errorView.hidden = YES;
    
    if (self.exploreState == ExploreStateLocal) {
        [Flurry logEvent:@"PTR_EXPLORE_LOCAL"];
        //NSLog(@"local refresh!");
        self.refreshAfterNearbyFaultBtn.hidden = YES;
        self.pullToRefreshManager.loadingView.flyingRocketAdjustment = 60;
        self.pullToRefreshManager.loadingView.clipsToBounds = NO;
        
        [UIView animateWithDuration:0.35 animations:^{
            self.navBar.alpha = 0;
            self.segControlContainer.alpha = 0;
            self.statusBar.alpha = 0;
        }];
        
        self.pullToRefreshStarted = YES;
        [self.refreshControl beginRefreshing];
        [self.localGridView fetchNearbyGridContent];
    }
    
    if (self.exploreState == ExploreStateWorld) {
        [Flurry logEvent:@"PTR_EXPLORE_WORLD"];
        //NSLog(@"world refresh!");
        self.refreshAfterWorldFaultBtn.hidden = YES;
        self.worldPullToRefreshManager.loadingView.flyingRocketAdjustment = 60;
        self.worldPullToRefreshManager.loadingView.clipsToBounds = NO;
        
        [UIView animateWithDuration:0.35 animations:^{
            self.navBar.alpha = 0;
            self.segControlContainer.alpha = 0;
            self.statusBar.alpha = 0;
        }];
        
        self.pullToRefreshStarted = YES;
        [self.worldRefreshControl beginRefreshing];
        [self.worldGridView fetchGridContent];
    }
}

#pragma mark = SPCFlyViewControllerDelegate

-(void)flyComplete {
    //reset position
    self.navBar.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 69);
    self.segControlContainer.frame = CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.view.bounds.size.width, 37);
}


#pragma mark - SPCHereVenueMapViewControllerDelegate

-(void)hereVenueMapViewController:(UIViewController *)viewController didSelectVenuesFromFullScreen:(NSArray *)venues {
    self.venueSelectionViewController.venues = venues;
    [self showVenueSelectionAnimated:YES fullScreen:YES];
}

#pragma mark - SPCHereVenueSelectionControllerDelegate

- (void)venueSelectionViewController:(UIViewController *)viewController didSelectVenue:(Venue *)venue dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self hideVenueSelectionAnimated:YES];
    }
    
    //tell the map
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:venue];
    
    //display venue detail feed
    [self showVenueDetail:venue];
    
}

- (void)venueSelectionViewController:(UIViewController *)viewController didSelectVenueFromFullScreen:(Venue *)venue dismiss:(BOOL)dismiss {
    if (dismiss) {
        [self hideVenueSelectionAnimated:YES];
    }
    //tell the map
    [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:venue];
    
    //display venue detail feed
    [self showVenueDetail:venue];
    
}

- (void)dismissVenueSelectionViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController == self.venueSelectionViewController) {
        [self hideVenueSelectionAnimated:animated];
    }
}

#pragma mark - SPCMontageViewDelegate & Montage

- (void)didLoadMemories:(NSArray *)memories OnSPCMontageView:(SPCMontageView *)montageView {
    if (self.viewMontageWorld == montageView) {
        [self.worldGridView.collectionView.collectionViewLayout invalidateLayout];
    } else if (self.viewMontageLocal == montageView) {
        [self.localGridView.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)didFailToLoadMemoriesOnSPCMontageView:(SPCMontageView *)montageView {
    // Poor connection -> Poor montage experience.
    // Montages should be auto-refreshed by the grid. Let's give them info that we just got a fail-to-load
    if (self.viewMontageWorld == montageView) {
        self.worldGridView.dateMontageLoadFailed = [NSDate date];
    } else if (self.viewMontageLocal == montageView) {
        self.localGridView.dateMontageLoadFailed = [NSDate date];
    }
}

- (void)tappedPlayButtonOnSPCMontageView:(SPCMontageView *)montageView {
    if (nil == self.viewMontagePlaying || SPCMontageViewStateStopped == self.viewMontagePlaying.state) {
        
        // Grab the appropriate collection view and its line spacing
        UICollectionView *collectionViewTapped;
        CGFloat lineSpacing = 2.0f; // Default
        if (self.viewMontageWorld == montageView) {
            [Flurry logEvent:@"MAM_WORLD_MONTAGE_TAPPED"];
            collectionViewTapped = self.worldGridView.collectionView;
            if ([self.worldGridView respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
                lineSpacing = [self.worldGridView collectionView:collectionViewTapped layout:collectionViewTapped.collectionViewLayout minimumLineSpacingForSectionAtIndex:0];
            }
        } else if (self.viewMontageLocal == montageView) {
            [Flurry logEvent:@"MAM_LOCAL_MONTAGE_TAPPED"];
            collectionViewTapped = self.localGridView.collectionView;
            if ([self.localGridView respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
                lineSpacing = [self.localGridView collectionView:collectionViewTapped layout:collectionViewTapped.collectionViewLayout minimumLineSpacingForSectionAtIndex:0];
            }
        }
        
        if (nil != collectionViewTapped) {
            // Set our properties with original values
            self.originalMontageFrame = montageView.frame;
            self.isPreparingToPlayMontage = YES;
            self.viewMontagePlaying = montageView;
            self.originalMontageSuperview = montageView.superview;
            
            // Scroll to the top of the collection view
            [collectionViewTapped scrollRectToVisible:CGRectMake(0, 0, CGRectGetWidth(collectionViewTapped.bounds), 1) animated:NO];
            
            // Get the Montage's frame. First, we get the header frame
            CGRect montageFrame = [collectionViewTapped layoutAttributesForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]].frame;
            // Then we convert it to the frame in the explore VC's view
            CGRect convertedMontageFrame = [self.view convertRect:montageFrame fromView:collectionViewTapped];
            // Account for the collection view's line spacing
            convertedMontageFrame.size.height -= lineSpacing;
            
            // Set the montage view's frame to its equivalent frame in the explore VC
            montageView.frame = convertedMontageFrame;
            self.convertedMontageBounds = montageView.bounds;
            self.convertedMontageCenter = montageView.center;
            
            // The new bounds, based on a 1:1 AR, with the screen width being the dimension size
            CGRect newMontageBounds = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds));
            
            // Create an overlay for the portion below the montage
            self.collectionViewOverlay = [[UIView alloc] initWithFrame:self.view.frame];
            self.collectionViewOverlay.backgroundColor = [UIColor blackColor];
            self.collectionViewOverlay.alpha = 0.0f;
            self.collectionViewOverlay.userInteractionEnabled = YES; // Absorbs touch events on cells it covers
            self.collectionViewOverlay.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedCollectionViewOverlayDuringMontage:)]];
            [self.view addSubview:self.collectionViewOverlay];
            
            // Add the montage view in front of the overlay
            [self.view insertSubview:montageView aboveSubview:self.collectionViewOverlay];
            
            // Animate in the montage to its larger, 1:1 size
            [UIView animateWithDuration:0.4f animations:^{
                montageView.bounds = newMontageBounds;
                montageView.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2.0f, CGRectGetHeight(montageView.bounds)/2.0f);
                
                // Assuming we're starting with a content offset equal to that which would be had if we were starting at the top of the collection view
                collectionViewTapped.contentOffset = CGPointMake(collectionViewTapped.contentOffset.x, collectionViewTapped.contentOffset.y + CGRectGetMaxY(convertedMontageFrame) - CGRectGetHeight(newMontageBounds));
                
                // Reset top nav items in case they were off screen
                self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
                self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x, self.segControlOriginalCenterY);
                
                // Animate in the overlay's opacity
                self.collectionViewOverlay.alpha = 0.8f;
                
                // Update status bar
                [self setNeedsStatusBarAppearanceUpdate];
            } completion:^(BOOL finished) {
                if (finished) {
                    // Start the montage
                    if (NO == self.montageCoachmarkWasShown) {
                        [montageView playWithCoachmark];
                    } else {
                        [montageView play];
                    }
                    self.isPreparingToPlayMontage = NO;
                }
            }];
        }
    }
}

- (void)tappedMemory:(Memory *)memory onSPCMontageView:(SPCMontageView *)montageView {
    // Pause the video and update the status bar
    [self.viewMontagePlaying pause];
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Get our current center for when we come back to the video
    self.originalMontageCenterBeforeNav = self.viewMontagePlaying.center;
    
    // Create the mcvc
    MemoryCommentsViewController *mcvc = [[MemoryCommentsViewController alloc] initWithMemory:memory];
    self.navFromMontage = [[SPCCustomNavigationController alloc] initWithRootViewController:mcvc];

    // Get the memory's new center
    CGSize constraint = CGSizeMake([UIScreen mainScreen].bounds.size.width, CGFLOAT_MAX);
    CGFloat montageViewNewCenterY = [MemoryCell measureMainContentOffsetWithMemory:memory constrainedToSize:constraint] + mcvc.tableStart + CGRectGetHeight(self.viewMontagePlaying.bounds)/2.0f;
    
    // Animate in the MCVC (alpha 0 -> 1), while shifting the montage view to its new center (while above the MCVC)
    self.navFromMontage.view.alpha = 0.0f;
    [self addChildViewController:self.navFromMontage];
    [self.view addSubview:self.navFromMontage.view];
    [self.navFromMontage didMoveToParentViewController:self];
    [self.view insertSubview:self.viewMontagePlaying aboveSubview:self.navFromMontage.view];
    
    // Create the header image & view
    UIImage *imageMcvc = [UIImageEffects takeSnapshotOfView:mcvc.view];
    // Hide the mcvc components pre-animation
    [mcvc setTableHeaderViewAlpha:0.0f];
    [mcvc setNavBarAlpha:0.0f];
    [mcvc setTableViewAlpha:0.0f];
    [mcvc setWhiteHeaderViewAlpha:0.0f];
    mcvc.view.backgroundColor = [UIColor clearColor];
    CGImageRef cgImageHeader = CGImageCreateWithImageInRect(imageMcvc.CGImage, CGRectMake(0, 0, imageMcvc.size.width, montageViewNewCenterY - CGRectGetHeight(self.viewMontagePlaying.bounds)/2.0f));
    UIImage *imageHeader = [UIImage imageWithCGImage:cgImageHeader];
    self.commentViewHeader = [[UIImageView alloc] initWithImage:imageHeader];
    self.commentViewHeader.frame = CGRectMake(0, -1*imageHeader.size.height, imageHeader.size.width, imageHeader.size.height);
    [self.view insertSubview:self.commentViewHeader aboveSubview:self.navFromMontage.view];
    // Create the footer image
    self.navFromMontage.view.center = CGPointMake(self.view.center.x, 1.5f * CGRectGetHeight(self.view.bounds));
    
    [UIView animateWithDuration:0.4f animations:^{
        // Adjust the center
        self.viewMontagePlaying.center = CGPointMake(self.viewMontagePlaying.center.x, montageViewNewCenterY);
        self.commentViewHeader.center = CGPointMake(self.viewMontagePlaying.center.x, imageHeader.size.height/2.0f);
        // Show the tableview and its comments
        [mcvc setTableViewAlpha:1.0f];
        
        self.navFromMontage.view.center = self.view.center;
        
        // Bring in the new VC
        self.navFromMontage.view.alpha = 1.0f;
        
        // Make the image disappear if it's a text mem
        if (MemoryTypeText == memory.type) {
            self.viewMontagePlaying.alpha = 0.0f;
        }
    } completion:^(BOOL finished) {
        if (finished) {
            // Fade out the montage image
            [UIView animateWithDuration:0.2f animations:^{
                self.viewMontagePlaying.alpha = 0.0f;
            } completion:^(BOOL finished) {
                // Send the montage behind the MCVC
                [self.view insertSubview:self.viewMontagePlaying belowSubview:self.navFromMontage.view];
                self.viewMontagePlaying.alpha = 1.0f;
            }];
            
            // 'Re-show' the actual mcvc
            [self.commentViewHeader removeFromSuperview];
            [mcvc setTableHeaderViewAlpha:1.0f];
            [mcvc setNavBarAlpha:1.0f];
            [mcvc setWhiteHeaderViewAlpha:1.0f];
            mcvc.view.backgroundColor = [UIColor whiteColor];
            
            // Our hack to make the back button usable on the MCVC
            [mcvc.backButton addTarget:self action:@selector(returnToMontageFromNav) forControlEvents:UIControlEventTouchUpInside];
        }
    }];
}

- (void)tappedAuthorForMemory:(Memory *)memory onSPCMontageView:(SPCMontageView *)montageView {
    // Pause the video and update the status bar
    [self.viewMontagePlaying pause];
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (memory.realAuthor && memory.realAuthor.userToken) {
        SPCProfileViewController *pvc = [[SPCProfileViewController alloc] initWithUserToken:memory.realAuthor.userToken];
        self.navFromMontage = [[SPCCustomNavigationController alloc] initWithRootViewController:pvc];
        
        // Present it
        [self presentViewController:self.navFromMontage animated:YES completion:^{
            // Our hack for having the back button call this ExploreVC when tapped
            [pvc enableBackButtonsWithTarget:self andSelector:@selector(returnToMontageFromNav)];
        }];
    } else if (memory.author.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    } else {
        SPCProfileViewController *pvc = [[SPCProfileViewController alloc] initWithUserToken:memory.author.userToken];
        self.navFromMontage = [[SPCCustomNavigationController alloc] initWithRootViewController:pvc];
        
        // Present it
        [self presentViewController:self.navFromMontage animated:YES completion:^{
            // Our hack for having the back button call this ExploreVC when tapped
            [pvc enableBackButtonsWithTarget:self andSelector:@selector(returnToMontageFromNav)];
        }];
    }
}

- (void)tappedCollectionViewOverlayDuringMontage:(id)sender {
    [self stopMontage:self.viewMontagePlaying];
}

- (void)tappedDismissButtonOnSPCMontageView:(SPCMontageView *)montageView {
    [self stopMontage:montageView];
}

- (void)didPlayToEndOnSPCMontageView:(SPCMontageView *)montageView {
    // Create a set of viewed memory keys
    NSMutableArray *arrayViewedMemories = [[NSMutableArray alloc] init];
    for (Memory *memory in montageView.memories) {
        [arrayViewedMemories addObject:memory.key];
    }
    
    // Set the associated NSUserDefaults variable
    if (self.viewMontageWorld == montageView) {
        [self setMontageLastViewedMemoriesWorld:arrayViewedMemories];
        self.worldGridView.montageLastViewedMemories = arrayViewedMemories;
    } else if (self.viewMontageLocal == montageView) {
        [self setMontageLastViewedMemoriesLocal:arrayViewedMemories];
        self.localGridView.montageLastViewedMemories = arrayViewedMemories;
    }
    
    // Finally, stop the montage (and remove it from the grid)
    [self stopMontage:montageView andRemoveFromGrid:YES];
}

- (void)memoriesWereClearedFromSPCMontageView:(SPCMontageView *)montageView {
    if (nil != self.viewMontagePlaying) {
        [self stopMontage:montageView andRemoveFromGrid:YES];
    }
}

- (void)stopMontage:(SPCMontageView *)montageView {
    [self stopMontage:montageView andRemoveFromGrid:NO];
}

- (void)stopMontage:(SPCMontageView *)montageView andRemoveFromGrid:(BOOL)removeFromGrid {
    // Stop the player
    [montageView stop];
    
    UICollectionView *collectionViewTapped;
    BOOL montageViewIsVisible = YES;
    if (self.viewMontageWorld == montageView) {
        collectionViewTapped = self.worldGridView.collectionView;
        if (ExploreStateWorld != self.exploreState) {
            montageViewIsVisible = NO;
        }
    } else if (self.viewMontageLocal == montageView) {
        collectionViewTapped = self.localGridView.collectionView;
        if (ExploreStateLocal != self.exploreState) {
            montageViewIsVisible = NO;
        }
    }
    
    // If we're still on the same screen (and the montage is visible), animate it out
    if (montageViewIsVisible) {
        // Scroll to the top of the collection view, exclusing the header, if we're removing the montage
        if (removeFromGrid) {
            [collectionViewTapped scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:YES];
        }
        
        [UIView animateWithDuration:0.4f animations:^{
            if (removeFromGrid) {
                montageView.bounds = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 1);
                montageView.center = CGPointMake(CGRectGetWidth(self.view.frame)/2.0f, 0);
                montageView.alpha = 0.0f;
            } else {
                // Set its original bounds and center
                montageView.bounds = self.convertedMontageBounds;
                montageView.center = self.convertedMontageCenter;
                
                // Scroll to the top of the collectionView
                [collectionViewTapped scrollRectToVisible:CGRectMake(0, 0, CGRectGetWidth(collectionViewTapped.bounds), 1) animated:NO];
            }
            
            // Un-dim the overlay
            self.collectionViewOverlay.alpha = 0.0f;
            
            // Animate in the status bar
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            if (finished) {
                // Remove the montage view from the ExploreVC view
                [montageView removeFromSuperview];
                
                // Set its original frame
                montageView.frame = self.originalMontageFrame;
                    
                // Add it back to its original superview
                [self.originalMontageSuperview addSubview:montageView];
                
                // Get rid of the collectionView overlay
                [self.collectionViewOverlay removeFromSuperview];
                self.collectionViewOverlay = nil;
                
                // Clear our the ExploreVC's property
                self.viewMontagePlaying = nil;
                
                if (removeFromGrid) {
                    // We need to clear montage's contents
                    if (NO == [AuthenticationManager sharedInstance].currentUser.isAdmin)
                    {
                        if (self.viewMontageWorld == montageView) {
                            [self.viewMontageWorld clear];
                        } else if (self.viewMontageLocal == montageView) {
                            [self.viewMontageLocal clear];
                        }
                    } else {
                        // reset its alpha and do NOT clear its contents
                        montageView.alpha = 1.0f;
                    }
                    
                    [collectionViewTapped.collectionViewLayout invalidateLayout];
                    [collectionViewTapped scrollRectToVisible:CGRectMake(0, 0, CGRectGetWidth(collectionViewTapped.bounds), 1) animated:NO];
                    self.navBar.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2.0f, self.navBarOriginalCenterY);
                    self.segControlContainer.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2.0f, self.segControlOriginalCenterY);
                }
            }
        }];
    } else {
        // No animation necessary
        // Remove the montage view from the ExploreVC view
        [montageView removeFromSuperview];
        
        // Set its original frame
        montageView.frame = self.originalMontageFrame;
        
        // Add it back to its original superview
        if (NO == removeFromGrid) {
            [self.originalMontageSuperview addSubview:montageView];
        }
        
        // Get rid of the collectionView overlay
        [self.collectionViewOverlay removeFromSuperview];
        self.collectionViewOverlay = nil;
        
        // Clear our the ExploreVC's property
        self.viewMontagePlaying = nil;
        
        if (removeFromGrid) {
            // We need to clear the object (we hold the strong pointer, grid holds weak pointer)
            // Also, the view has been removed from its superview
            if (self.viewMontageWorld == montageView) {
                self.viewMontageWorld = nil;
            } else if (self.viewMontageLocal == montageView) {
                self.viewMontageLocal = nil;
            }
            
            [collectionViewTapped.collectionViewLayout invalidateLayout];
        }
    }
}

- (void)returnToMontageFromNav {
    self.isPreparingToPlayMontage = YES;
    [self setNeedsStatusBarAppearanceUpdate];
    
    UINavigationController *nav = self.navFromMontage;
    self.navFromMontage = nil;
    
    // Determine if we're returning from the MemoryCommentsVC, from which we must apply custom animation
    if ([[nav.viewControllers firstObject] isKindOfClass:[MemoryCommentsViewController class]]) {
        MemoryCommentsViewController *mcvc = (MemoryCommentsViewController *)[nav.viewControllers firstObject];

        // 'Re-show' the montage
        self.viewMontagePlaying.alpha = 1.0f;
        
        // Place it and the comment header above the MCVC
        [self.view insertSubview:self.commentViewHeader aboveSubview:nav.view];
        [self.view insertSubview:self.viewMontagePlaying aboveSubview:nav.view];
        [mcvc setTableHeaderViewAlpha:0.0f];
        [mcvc setNavBarAlpha:0.0f];
        [mcvc setWhiteHeaderViewAlpha:0.0f];
        [UIView animateWithDuration:0.4f animations:^{
            // Place the montage back where it was originally
            self.viewMontagePlaying.center = self.originalMontageCenterBeforeNav;
            self.viewMontagePlaying.alpha = 1.0f;
            
            // Place the comment view header above the screen as well
            self.commentViewHeader.center = CGPointMake(self.viewMontagePlaying.center.x, -0.5 * CGRectGetHeight(self.commentViewHeader.frame));
            
            // Place the MCVC below the screen and fade it out
            nav.view.center = CGPointMake(self.view.center.x, 1.5 * CGRectGetHeight(nav.view.frame));
            [mcvc setTableViewAlpha:0.0f];
            mcvc.view.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            // Remove the nav from the view
            [nav willMoveToParentViewController:nil];
            [nav.view removeFromSuperview];
            [nav removeFromParentViewController];
            
            // Remove the comments header from our view
            [self.commentViewHeader removeFromSuperview];
            self.commentViewHeader = nil;
            
            // Start the montage
            [self.viewMontagePlaying play];
            self.isPreparingToPlayMontage = NO;
        }];
    } else {
        [nav dismissViewControllerAnimated:YES completion:^{
            // Start the montage
            [self.viewMontagePlaying play];
            self.isPreparingToPlayMontage = NO;
        }];
    }
}

- (void)didTapCoachmarkToCompletionOnSPCMontageView:(SPCMontageView *)montageView {
    self.montageCoachmarkWasShown = YES;
}

- (void)setMontageCoachmarkWasShown:(BOOL)montageCoachmarkWasShown {
    NSString *strMontageCoachmarkStringUserLiteralKey = [SPCLiterals literal:kSPCMontageCoachmarkWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setBool:montageCoachmarkWasShown forKey:strMontageCoachmarkStringUserLiteralKey];
}

- (BOOL)montageCoachmarkWasShown {
    BOOL wasShown = NO;
    
    NSString *strMontageCoachmarkStringUserLiteralKey = [SPCLiterals literal:kSPCMontageCoachmarkWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strMontageCoachmarkStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strMontageCoachmarkStringUserLiteralKey];
    }
    
    return wasShown;
}

- (void)setMontageLastViewedMemoriesWorld:(NSArray *)montageLastViewedMemoriesWorld {
    NSString *strMontageLastMemoriesViewedWorldKey = [SPCLiterals literal:kSPCMontageLastMemoriesViewedWorld forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setObject:montageLastViewedMemoriesWorld forKey:strMontageLastMemoriesViewedWorldKey];
}

- (NSArray *)montageLastViewedMemoriesWorld {
    NSArray *montageLastViewedMemoriesWorld = nil;
    
    NSString *strMontageLastMemoriesViewedWorldKey = [SPCLiterals literal:kSPCMontageLastMemoriesViewedWorld forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strMontageLastMemoriesViewedWorldKey]) {
        NSObject *montageLastViewedMemoriesWorldObj = [[NSUserDefaults standardUserDefaults] objectForKey:strMontageLastMemoriesViewedWorldKey];
        if ([montageLastViewedMemoriesWorldObj isKindOfClass:[NSArray class]]) {
            montageLastViewedMemoriesWorld = (NSArray *)montageLastViewedMemoriesWorldObj;
        }
    }
    
    return montageLastViewedMemoriesWorld;
}

- (void)setMontageLastViewedMemoriesLocal:(NSArray *)montageLastViewedMemoriesLocal {
    NSString *strMontageLastMemoriesViewedLocalKey = [SPCLiterals literal:kSPCMontageLastMemoriesViewedLocal forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setObject:montageLastViewedMemoriesLocal forKey:strMontageLastMemoriesViewedLocalKey];
}

- (NSArray *)montageLastViewedMemoriesLocal {
    NSArray *montageLastViewedMemoriesLocal = nil;
    
    NSString *strMontageLastMemoriesViewedLocalKey = [SPCLiterals literal:kSPCMontageLastMemoriesViewedLocal forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strMontageLastMemoriesViewedLocalKey]) {
        NSObject *montageLastViewedMemoriesLocalObj = [[NSUserDefaults standardUserDefaults] objectForKey:strMontageLastMemoriesViewedLocalKey];
        if ([montageLastViewedMemoriesLocalObj isKindOfClass:[NSArray class]]) {
            montageLastViewedMemoriesLocal = (NSArray *)montageLastViewedMemoriesLocalObj;
        }
    }
    
    return montageLastViewedMemoriesLocal;
}

- (BOOL)isTabBarAllowed {
    // the tab bar should not be shown if the user is in a subordinate view
    // controller.
    return !self.navFromGrid && !self.navFromMontage;
}


- (BOOL)isNavBarFullyVisible {
    return self.navBar.center.y == self.navBarOriginalCenterY;
}


#pragma mark - Status Bar

- (BOOL)prefersStatusBarHidden {
    return SPCMontageViewStatePlaying == self.viewMontagePlaying.state || self.isPreparingToPlayMontage;
}

#pragma mark - Actions

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    if (segmentedControl.selectedSegmentIndex == 0) {
        if (self.worldGridView.cellCount > 0) {
            self.errorView.hidden = YES;
        }
        
        [Flurry logEvent:@"WORLD_TAPPED_EXP"];
        
        // Update our callout statesegmentedControlChangedValue
        [self determineCalloutToShowFromEvent:CalloutEventTypeWorldTapped];
        
        // animate in and display world grid
        self.exploreState = ExploreStateWorld;
        [self.localGridView gridDidDisappear];
        [self.worldGridView gridDidAppear];
        if (self.isTabBarAllowed) {
            [self.tabBarController slideTabBarHidden:NO animated:YES]; //ensure tab bar is visible
        }
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             //make sure our seg control and nav bar are fully in place
                             self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
                             self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
                             
                             self.worldGridView.center = CGPointMake(self.view.bounds.size.width/2, self.worldGridView.center.y);
                             self.localGridView.center = CGPointMake(self.view.bounds.size.width/2 + self.view.bounds.size.width, self.localGridView.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
    }
    if (segmentedControl.selectedSegmentIndex == 1) {
        if (self.localGridView.cellCount > 0) {
            self.errorView.hidden = YES;
        }
        if (self.locationAvailable) {
            self.locationPromptView.hidden = YES;
        }
        
        
        [Flurry logEvent:@"LOCAL_TAPPED_EXP"];
        // animate in and display grid view (local)
        self.exploreState = ExploreStateLocal;
        [self.localGridView gridDidAppear];
        [self.worldGridView gridDidDisappear];
        if (self.isTabBarAllowed) {
            [self.tabBarController slideTabBarHidden:NO animated:YES]; //ensure tab bar is visible
        }
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             //make sure our seg control and nav bar are fully in place
                             self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
                             self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
                             
                             self.localGridView.center = CGPointMake(self.view.bounds.size.width/2, self.localGridView.center.y);
                             self.worldGridView.center = CGPointMake(self.view.bounds.size.width/2 - self.view.bounds.size.width, self.worldGridView.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
        
    }
    
}

-(void)skipToLocalGrid {
    
    // Take the montage off-screen if we're changing to a different state
    if (ExploreStateLocal != self.exploreState && nil != self.viewMontagePlaying) {
        [self performSelectorOnMainThread:@selector(stopMontage:) withObject:self.viewMontagePlaying waitUntilDone:NO];
    }
    
    self.hmSegmentedControl.selectedSegmentIndex = 1;
    self.exploreState = ExploreStateLocal;
    if (self.isTabBarAllowed) {
        [self.tabBarController slideTabBarHidden:NO animated:NO];
    }
    [self.localGridView gridDidAppear];
    [self.worldGridView gridDidDisappear];
    
    //make sure our seg control and nav bar are fully in place
    self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
    self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
    self.localGridView.collectionView.contentOffset = CGPointMake(0, self.localGridView.baseOffSetY);
    
    self.localGridView.center = CGPointMake(self.view.bounds.size.width/2, self.localGridView.center.y);
    self.worldGridView.center = CGPointMake(self.view.bounds.size.width/2 - self.view.bounds.size.width, self.worldGridView.center.y);
}

-(void)skipToWorldGrid {
    
    // Take the montage off-screen if we're changing to a different state
    if (ExploreStateWorld != self.exploreState && nil != self.viewMontagePlaying) {
        [self performSelectorOnMainThread:@selector(stopMontage:) withObject:self.viewMontagePlaying waitUntilDone:NO];
    }
    
    self.hmSegmentedControl.selectedSegmentIndex = 0;
    self.exploreState = ExploreStateWorld;
    
    if (self.isTabBarAllowed) {
        [self.tabBarController slideTabBarHidden:NO animated:NO];
    }
    [self.localGridView gridDidDisappear];
    [self.worldGridView gridDidAppear];
    
    //make sure our seg control and nav bar are fully in place
    self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
    self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
    
    self.worldGridView.center = CGPointMake(self.view.bounds.size.width/2, self.worldGridView.center.y);
    self.localGridView.center = CGPointMake(self.view.bounds.size.width/2 + self.view.bounds.size.width, self.localGridView.center.y);
}

-(void)flyPressed:(id)sender {
//    // animate in and display fly
    NSLog(@"show fly grid");
    [Flurry logEvent:@"FLY_TAPPED"];
    [self.navigationController pushViewController:self.flyViewController animated:YES];
    
    // Update our callout state
    [self determineCalloutToShowFromEvent:CalloutEventTypeFlyTapped];
}

-(void)nearbyPressed:(id)sender {
    //show nearby venues
    NSLog(@"show nearby venues");
    self.displayingNearbyVenues = YES;
    [self.nearbyVenuesView skipToMap];
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         self.containerView.center = CGPointMake(self.view.bounds.size.width/2 + self.view.bounds.size.width, self.containerView.center.y);
                         self.nearbyVenuesView.center = CGPointMake(self.view.bounds.size.width/2, self.nearbyVenuesView.center.y);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             
                             if (self.mapLoader.alpha == 1) {
                                 [self.mapLoader startAnimating];
                             }
                             self.mapViewController.isExplorePaused = NO;
                         }
                     }];
    
    //hide tab bar
    self.tabBarController.tabBar.alpha = 0.0;
    
}

-(void)showCreateVenueViewControllerWithVenues:(NSArray *)venues {
    SPCCreateVenueViewController *createVenueViewController = [[SPCCreateVenueViewController alloc] initWithNearbyVenues:venues];
    [self.navigationController pushViewController:createVenueViewController animated:YES];
}

-(void)hideNearbyVenues {
    self.displayingNearbyVenues = NO;
    
    //reset position
    
    self.navBar.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 69);
    self.segControlContainer.frame = CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.view.bounds.size.width, 37);
    self.localGridView.collectionView.contentOffset = CGPointMake(0, self.localGridView.baseOffSetY);
    
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         self.containerView.center = CGPointMake(self.view.bounds.size.width/2, self.containerView.center.y);
                         self.nearbyVenuesView.center = CGPointMake(self.view.bounds.size.width/2 - self.view.bounds.size.width, self.nearbyVenuesView.center.y);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             
                         }
                     }];
    
    //show tab bar
    [self.tabBarController.tabBar setHidden:NO];
    self.tabBarController.tabBar.alpha = 1.0;
    self.mapViewController.isExplorePaused = YES;
}

-(void)toggleFilters {
    if (self.displayingFilters) {
        [self dismissFilters];
    }
    else {
        [self showFilters];
    }
}

-(void)showFilters {
    
    if (self.activeFilters.count > 0) {
        
        self.displayingFilters = YES;
        self.dismissFiltersOverlayBtn.hidden = NO;
        
        
        float numRows = ceilf(self.activeFilters.count / 4.0);
        
        float height = 6 + numRows * self.filterItemHeight;
        float width  = 4 * self.filterItemWidth;
        
        float padding = (self.view.bounds.size.width - width)/2;
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.filtersContainer.frame = CGRectMake(padding, 57, width, height);
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
    }
}

-(void)dismissFilters {
    self.displayingFilters = NO;
    self.dismissFiltersOverlayBtn.hidden = YES;
    [self updateSelectedFilters];
    [self updateMapPins];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         
                         self.filtersContainer.frame = CGRectMake(8, 57, 0, 0);
                         
                     } completion:^(BOOL finished) {
                         if (finished) {
                             
                         }
                     }];
}

-(void)refreshNearbyAfterFault {
    self.refreshAfterNearbyFaultBtn.hidden = YES;
    self.errorView.hidden = YES;
    self.gridLoader.alpha = 1;
    [self.gridLoader startAnimating];
    [self.localGridView fetchNearbyGridContent];
}

-(void)refreshWorldAfterFault {
    self.refreshAfterWorldFaultBtn.hidden = YES;
    self.errorView.hidden = YES;
    [self.worldGridView fetchGridContent];
    
}
-(void)refreshLocation {
    [self refreshContent:YES];
}

-(void)refreshLocationSilently {
    [self refreshContent:NO];
}


-(void)createLocation {
    
    SPCCreateVenueViewController *createVenueViewController = [[SPCCreateVenueViewController alloc] initWithNearbyVenues:self.nearbyVenues];
    createVenueViewController.fromExplore = YES;
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:createVenueViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    navController.navigationBar.hidden = YES;
    
    [self presentViewController:navController animated:YES completion:nil];
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
        [self.mapContainerView addSubview:self.venueSelectionViewController.view];
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
                         destinationFrame.origin.y = -20.0;
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

-(void)showLocationPrompt:(id)sender {
    
    BOOL hasShownSystemPrompt = [[NSUserDefaults standardUserDefaults] boolForKey:@"systemHasShownLocationPrompts"];
    
    if (!hasShownSystemPrompt && [CLLocationManager locationServicesEnabled]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"systemHasShownLocationPrompts"];
        [[LocationManager sharedInstance] requestSystemAuthorization];
    }
    else if (!hasShownSystemPrompt && ![CLLocationManager locationServicesEnabled]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
    
    else {
        NSLog(@"already displayed system prompt!");
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services for the \"Spayce\" app", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

-(void)scrollToTop {
    
    if (!self.pullToRefreshStarted) {
        if (self.isTabBarAllowed) {
            [self.tabBarController slideTabBarHidden:NO animated:YES];
        }
        [self.localGridView.collectionView setContentOffset:CGPointMake(0, self.localGridView.baseOffSetY) animated:YES];
        [self.worldGridView.collectionView setContentOffset:CGPointMake(0, self.worldGridView.baseOffSetY) animated:YES];
        
        [UIView animateWithDuration:.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.navBar.center = CGPointMake(self.navBar.center.x, self.navBarOriginalCenterY);
                             self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
        
    }
}

#pragma mark - Private

- (void)refreshContent:(BOOL)manual {
    
    if (VERBOSE_STATE_CHANGES) {
        NSLog(@"refreshContent from \n%@\n%@", [NSThread callStackSymbols][1], [NSThread callStackSymbols][2]);
    }
    
    if (self.performingRefresh) {
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"Currently performing refresh");
        }
        return;
    }
    
    if (self.waitingForLocationManagerUptime) {
        
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"Currently waiting for location manager uptime....");
        }
        return;
    }
    
    // Fetch memories only if location services are enabled and manually authorized by the user
    // There's no point in polling for location sensitive data if it's not enabled or authorized
    if (![CLLocationManager locationServicesEnabled] ||
        ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)) {
        
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"Can't access location services");
        }
        // tell the user why we can't do anything?
        [self endNearbyRefreshWithError:manual];
        return;
    }
    
    if (self.mapLoader.alpha == 0) {
        // throw it up there!
        [self resetAllFilters];
        self.mapLoader.alpha = 1;
        [self.mapLoader stopAnimating];
        [self.mapLoader startAnimating];
    }
    
    __weak typeof(self) weakSelf = self;
    
    if ([LocationManager sharedInstance].uptime < MINIMUM_LOCATION_MANAGER_UPTIME) {
        if (VERBOSE_STATE_CHANGES || VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Waiting for uptime %d", MINIMUM_LOCATION_MANAGER_UPTIME);
        }
        self.waitingForLocationManagerUptime = YES;
        [[LocationManager sharedInstance] waitForUptime:MINIMUM_LOCATION_MANAGER_UPTIME withSuccessCallback:^(NSTimeInterval uptime) {
            if (VERBOSE_STATE_CHANGES || VERBOSE_CONTENT_UPDATES) {
                NSLog(@"Done waiting for uptime with uptime %f, manager property uptime %f", uptime, [LocationManager sharedInstance].uptime);
            }
            __strong typeof(weakSelf) strongSelf = weakSelf;
            strongSelf.waitingForLocationManagerUptime = NO;
            
            if ([LocationManager sharedInstance].uptime >= MINIMUM_LOCATION_MANAGER_UPTIME) {
                [strongSelf performSelector:@selector(refreshContentSelector:) withObject:[NSNumber numberWithBool:manual] afterDelay:0.1f];
            } else {
                if (self.retryCount < 3) {
                    strongSelf.waitingForLocationManagerUptime = NO;
                    self.retryCount = self.retryCount + 1;
                    [self performSelector:@selector(refreshContentSelector:) withObject:[NSNumber numberWithBool:manual] afterDelay:1];
                }
                else {
                    [strongSelf endNearbyRefreshWithError:manual];
                }
            }
        } faultCallback:^(NSError *error) {
            if (VERBOSE_STATE_CHANGES || VERBOSE_CONTENT_UPDATES) {
                NSLog(@"FAULT waiting for uptime");
            }
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (self.retryCount < 3) {
                strongSelf.waitingForLocationManagerUptime = NO;
                self.retryCount = self.retryCount + 1;
                [self performSelector:@selector(refreshContentSelector:) withObject:[NSNumber numberWithBool:manual] afterDelay:1];
            }
            else {
                [strongSelf endNearbyRefreshWithError:manual];
            }
        }];
        return;
    }
    
    self.performingRefresh = YES;
    
    
    if (VERBOSE_STATE_CHANGES || VERBOSE_CONTENT_UPDATES) {
        NSLog(@"Getting content");
    }
    [[LocationContentManager sharedInstance] clearContentAndLocation];
    [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue, SPCLocationContentNearbyVenues, SPCLocationContentFuzzedVenue] progressCallback:^(NSDictionary *partialResults, BOOL *cancel) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Progress Callback");
        }
        
        if (self.waitingForLocationManagerUptime) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"Currently waiting for location manager uptime, terminating...");
            }
            *cancel = YES;
            strongSelf.performingRefresh = NO;
            return;
        }
    } resultCallback:^(NSDictionary *results) {
        if (VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Result Callback");
        }
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        if (self.waitingForLocationManagerUptime) {
            if (VERBOSE_STATE_CHANGES) {
                NSLog(@"Currently waiting for location manager uptime...");
            }
            strongSelf.performingRefresh = NO;
            return;
        }
        
        SpayceState state = SpayceStateDisplayingLocationData;
        NSArray *nearby = results[SPCLocationContentNearbyVenues];
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:nearby];
        if (results[SPCLocationContentFuzzedVenue]) {
            [tempArray addObject:results[SPCLocationContentFuzzedVenue]];
        }
        strongSelf.nearbyVenues = [NSArray arrayWithArray:tempArray];
        strongSelf.currVenue = results[SPCLocationContentVenue];
        strongSelf.deviceVenue = results[SPCLocationContentDeviceVenue];
        
        [[LocationManager sharedInstance] setManualVenue:results[SPCLocationContentDeviceVenue]];
        //[strongSelf.nearbyVenuesView updateVenues:strongSelf.nearbyVenues];
        //[strongSelf updateActiveFilters:nearby];
        
        Asset *profilePicAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        if (!profilePicAsset) {
            //NSLog(@"uh oh!, no profilePicAsset yet!");
            
            //are we in preview mode??
            if (![AuthenticationManager sharedInstance].currentUser) {
                
                //we are in preview mode: proceed w/o a profile pic
                
                [strongSelf.mapViewController updateVenues:nearby withCurrentVenue:results[SPCLocationContentVenue] deviceVenue:results[SPCLocationContentDeviceVenue] spayceState:state];
                [strongSelf.mapViewController showVenue:results[SPCLocationContentDeviceVenue] withZoom:15 animated:NO];
                [strongSelf.mapViewController showVenue:results[SPCLocationContentDeviceVenue] withZoom:17.5 animated:YES];
                strongSelf.mapLoader.alpha = 0;
                [strongSelf.mapLoader stopAnimating];
                strongSelf.performingRefresh = NO;
                strongSelf.lastRefreshedLocation = [LocationManager sharedInstance].currentLocation;
            }
            else {
                
                //not in preview mode, try loading map again in .3 after giving profile a chance to laod
                
                [strongSelf performSelector:@selector(delayForProfileThenUpdate) withObject:nil afterDelay:.3];
            }
            
        }
        else {
            strongSelf.mapLoader.alpha = 0;
            [strongSelf.mapLoader stopAnimating];
            strongSelf.performingRefresh = NO;
            strongSelf.lastRefreshedLocation = [LocationManager sharedInstance].currentLocation;
        }
        
        if (VERBOSE_STATE_CHANGES) {
            NSLog(@"location content result");
        }
        self.retryCount = 0;
        
    } faultCallback:^(NSError *fault) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (VERBOSE_CONTENT_UPDATES) {
            NSLog(@"Fault Callback: %@", fault);
        }
        strongSelf.performingRefresh = NO;
        
        if (self.retryCount < 3) {
            self.retryCount = self.retryCount + 1;
            [self performSelector:@selector(refreshContentSelector:) withObject:[NSNumber numberWithBool:manual] afterDelay:1];
        }
        else {
            self.retryCount = 0;
            [strongSelf endNearbyRefreshWithError:manual];
        }
    }];
}

- (void)endNearbyRefreshWithError:(BOOL)manual {
    self.mapLoader.alpha = 0;
    [self.mapLoader stopAnimating];
    // alert
    if (manual) {
        NSString *message = @"Error refreshing nearby venues.  Please try again later.";
        if (![CLLocationManager locationServicesEnabled] ||
            ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse)) {
            
            message = @"Location services are unavailable.";
        }
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
}

- (void)refreshContentSelector:(NSNumber *)manual {
    [self refreshContent:manual.boolValue];
}

- (void)refreshVenuesIfUserMoved {
    //NSLog(@"refreshVenuesIfUserMoved");
    // only refresh the map if not displayed and we can trust our location
    if (self.displayingNearbyVenues || self.waitingForLocationManagerUptime || self.performingRefresh) {
        return;
    }
    // refresh map venues if the user has moved since last time.
    if ([CLLocationManager locationServicesEnabled] &&
        ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        __weak typeof(self) weakSelf = self;
        [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
            __strong typeof(weakSelf) strongSelfOutside = weakSelf;
            CLLocation *location = [[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong];
            //NSLog(@"refreshing nearby venues: user has moved from %@ to %@.", strongSelfOutside.lastRefreshedLocation, location);
            if (strongSelfOutside.lastRefreshedLocation && [location distanceFromLocation:strongSelfOutside.lastRefreshedLocation] > EXPLORE_NEARBY_VENUE_REFRESH_DISTANCE) {
                //NSLog(@"User has moved far enough: refresh venues now!");
                
                [strongSelfOutside resetAllFilters];
                strongSelfOutside.mapLoader.alpha = 1;
                [strongSelfOutside.mapLoader stopAnimating];
                [strongSelfOutside.mapLoader startAnimating];
                [[LocationContentManager sharedInstance] clearContentAndLocation];
                strongSelfOutside.lastRefreshedLocation = location;
                
                [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue, SPCLocationContentNearbyVenues, SPCLocationContentFuzzedVenue] progressCallback:^(NSDictionary *partialResults, BOOL *cancel) {
                    if (VERBOSE_CONTENT_UPDATES) {
                        NSLog(@"Progress Callback");
                    }
                    
                    if (self.waitingForLocationManagerUptime) {
                        if (VERBOSE_STATE_CHANGES) {
                            NSLog(@"Currently waiting for location manager uptime, terminating...");
                        }
                        *cancel = YES;
                        return;
                    }
                } resultCallback:^(NSDictionary *results) {
                    if (VERBOSE_CONTENT_UPDATES) {
                        NSLog(@"Result Callback");
                    }
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    
                    if (self.waitingForLocationManagerUptime) {
                        if (VERBOSE_STATE_CHANGES) {
                            NSLog(@"Currently waiting for location manager uptime...");
                        }
                        return;
                    }
                    
                    SpayceState state = SpayceStateDisplayingLocationData;
                    NSArray *nearby = results[SPCLocationContentNearbyVenues];
                    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:nearby];
                    if (results[SPCLocationContentFuzzedVenue]) {
                        [tempArray addObject:results[SPCLocationContentFuzzedVenue]];
                    }
                    strongSelf.nearbyVenues = [NSArray arrayWithArray:tempArray];
                    strongSelf.currVenue = results[SPCLocationContentVenue];
                    strongSelf.deviceVenue = results[SPCLocationContentDeviceVenue];
                    
                    [[LocationManager sharedInstance] setManualVenue:results[SPCLocationContentDeviceVenue]];
                    //[strongSelf.nearbyVenuesView updateVenues:strongSelf.nearbyVenues];
                    //[strongSelf updateActiveFilters:nearby];
                    
                    Asset *profilePicAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
                    if (!profilePicAsset) {
                        //NSLog(@"uh oh!, no profilePicAsset yet!");
                        
                        //are we in preview mode??
                        if (![AuthenticationManager sharedInstance].currentUser) {
                            
                            //we are in preview mode: proceed w/o a profile pic
                            
                            [strongSelf.mapViewController updateVenues:nearby withCurrentVenue:results[SPCLocationContentVenue] deviceVenue:results[SPCLocationContentDeviceVenue] spayceState:state];
                            [strongSelf.mapViewController showVenue:results[SPCLocationContentDeviceVenue] withZoom:15 animated:NO];
                            [strongSelf.mapViewController showVenue:results[SPCLocationContentDeviceVenue] withZoom:17.5 animated:YES];
                            strongSelf.mapLoader.alpha = 0;
                            [strongSelf.mapLoader stopAnimating];
                            strongSelf.performingRefresh = NO;
                        }
                        else {
                            
                            //not in preview mode, try loading map again in .3 after giving profile a chance to laod
                            
                            [strongSelf performSelector:@selector(delayForProfileThenUpdate) withObject:nil afterDelay:.3];
                        }
                        
                    }
                    else {
                        [strongSelf.mapViewController updateVenues:nearby withCurrentVenue:results[SPCLocationContentVenue] deviceVenue:results[SPCLocationContentDeviceVenue] spayceState:state];
                        [strongSelf.mapViewController showVenue:results[SPCLocationContentDeviceVenue] withZoom:15 animated:NO];
                        [strongSelf.mapViewController showVenue:results[SPCLocationContentDeviceVenue] withZoom:17.5 animated:YES];
                        strongSelf.mapLoader.alpha = 0;
                        [strongSelf.mapLoader stopAnimating];
                        strongSelf.performingRefresh = NO;
                    }
                    
                    if (VERBOSE_STATE_CHANGES) {
                        NSLog(@"location content result");
                    }
                    
                    
                } faultCallback:^(NSError *fault) {
                    if (VERBOSE_CONTENT_UPDATES) {
                        NSLog(@"Fault Callback: %@", fault);
                    }
                }];
            }
        } faultCallback:^(NSError *fault) {
            // nothing
        }];
    }
}

- (void)restartQuake {
    [self.gridLoader startAnimating];
}


-(void)delayForProfileThenUpdate {
    
    //NSLog(@"delay for profile...");
    
    if (self.performingRefresh) {
        Asset *profilePicAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        if (!profilePicAsset) {
            //NSLog(@"uh oh!, no profilePicAsset yet, don't update map pins until we have one..");
            [self performSelector:@selector(delayForProfileThenUpdate) withObject:nil afterDelay:.3];
        }
        else {
            //NSLog(@"end delayed load of map!");
            [self.mapViewController updateVenues:self.nearbyVenues withCurrentVenue:self.currVenue deviceVenue:self.deviceVenue spayceState:SpayceStateDisplayingLocationData];
            [self.mapViewController showVenue:self.currVenue withZoom:15 animated:NO];
            [self.mapViewController showVenue:self.currVenue withZoom:17.5 animated:YES];
            self.mapLoader.alpha = 0;
            [self.mapLoader stopAnimating];
            self.performingRefresh = NO;
        }
    }
}


- (void)forceHandleSelection {
    
    SPCHandlePromptViewController *handleVC = [[SPCHandlePromptViewController alloc] init];
    SPCNavControllerLight *navigationController = [[SPCNavControllerLight alloc] initWithRootViewController:handleVC];
    [self presentViewController:navigationController animated:YES completion:NULL];
    
}


- (void)setPullToRefreshFadingHeader:(UIView *)pullToRefreshFadingHeader {
    _pullToRefreshFadingHeader = pullToRefreshFadingHeader;
    _pullToRefreshWorldFadingHeader = pullToRefreshFadingHeader;
    
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = _pullToRefreshFadingHeader;
    }
    if (_worldPullToRefreshManager) {
        _worldPullToRefreshManager.fadingHeaderView = _pullToRefreshWorldFadingHeader;
    }
}

- (void)forceTabVisible {
    [self.tabBarController slideTabBarHidden:NO animated:YES];
}

#pragma mark - Filters Helder Methods

//updates the filters that are displayed for a given set of venues
-(void)updateActiveFilters:(NSArray *)nearbyVenues {
    
    
    //Loop through all nearby venues to determine which filters are relevant and should be displayed
    
    
    //step 1 - get the filters based on type
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < nearbyVenues.count; i++) {
        
        Venue *v = (Venue *)nearbyVenues[i];
        NSString *filterType = [self getFilterTypeForVenue:v];
        
        //check to see if we have already added this filter??
        BOOL alreadyAdded = NO;
        
        for (int j = 0; j < tempArray.count; j++) {
            
            NSString *tempFilter = tempArray[j];
            if ([filterType isEqualToString:tempFilter]) {
                alreadyAdded = YES;
                break;
            }
        }
        if (!alreadyAdded) {
            if (filterType.length > 0) {
                [tempArray addObject:filterType];
            }
        }
    }
    
    //step 2 - add the favorites filter if we need it
    for (int i = 0; i < nearbyVenues.count; i++) {
        Venue *v = (Venue *)nearbyVenues[i];
        if (v.favorited) {
            [tempArray insertObject:@"Favorites" atIndex:0];
            break;
        }
    }
    
    //step 3 - add popuplar filter if we need it
    for (int i = 0; i < nearbyVenues.count; i++) {
        Venue *v = (Venue *)nearbyVenues[i];
        if (v.popularMemories.count > 0) {
            [tempArray insertObject:@"Popular" atIndex:0];
            break;
        }
    }
    
    //step 4 - show all option
    [tempArray insertObject:@"All" atIndex:0];
    
    
    //set our array of active filters and update our collection view appropriately
    self.activeFilters = [NSArray arrayWithArray:tempArray];
    
    float numRows = ceilf(self.activeFilters.count / 4.0);
    
    float height = numRows * self.filterItemHeight;
    float width  = 4 * self.filterItemWidth;
    
    self.filtersCollectionView.frame = CGRectMake(0, 5, width, height);
    self.filtersCollectionView.contentSize = CGSizeMake(self.filtersCollectionView.frame.size.width, self.filtersCollectionView.frame.size.height);
    [self.filtersCollectionView reloadData];
}

//updates the filters that are selected by user

-(void)updateSelectedFilters {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.activeFilters.count; i++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        SPCMapFilterCollectionViewCell *cell = (SPCMapFilterCollectionViewCell *)[self.filtersCollectionView cellForItemAtIndexPath:indexPath];
        
        if (cell.filterSelected) {
            [tempArray addObject:cell.filterName];
        }
    }
    
    self.selectedFilters = [NSArray arrayWithArray:tempArray];
}

- (NSString *)getFilterTypeForVenue:(Venue *)v {
    
    NSInteger venType = [SPCVenueTypes typeForVenue:v];
    NSString *filterType = @"";
    
    if ((venType == VenueTypeCafe) || (venType == VenueTypeBakery)) {
        filterType = @"Cafes";
    }
    if ((venType == VenueTypeRestaurant) || (venType == VenueTypeFood)) {
        filterType = @"Restaurants";
    }
    if (venType == VenueTypeResidential)  {
        filterType = @"Homes";
    }
    if ((venType == VenueTypeAirport) || (venType == VenueTypeTrain) || (venType == VenueTypeSubway) || (venType == VenueTypeTravel) || (venType == VenueTypeBus)) {
        filterType = @"Travel";
    }
    if ((venType == VenueTypeStadium) || (venType == VenueTypeGym) || (venType == VenueTypePark)) {
        filterType = @"Sports";
    }
    if ((venType == VenueTypeBar) || (venType == VenueTypeLiquor)) {
        filterType = @"Bars";
    }
    if ((venType == VenueTypeSchool) || (venType == VenueTypeLibrary)) {
        filterType = @"Schools";
    }
    if ((venType == VenueTypeAmusement) || (venType == VenueTypeAquarium) || (venType == VenueTypeArt) || (venType == VenueTypeMuseum) || (venType == VenueTypeHair) || (venType == VenueTypeCasino)  || (venType == VenueTypeBowling || (venType == VenueTypeMovieTheater) )  ) {
        filterType = @"Fun";
    }
    
    if ((venType == VenueTypeStore) || (venType == VenueTypeJewelry) || (venType == VenueTypeBicycle) || (venType == VenueTypeBookstore) || (venType == VenueTypeShopping) || (venType == VenueTypeShoe)  || (venType == VenueTypeMovieRental || (venType == VenueTypeHomegoods) || (venType == VenueTypeHardware) || (venType == VenueTypeClothing) || (venType == VenueTypeDepartment) || (venType == VenueTypeConvenience) || (venType == VenueTypeElectronics) || (venType == VenueTypeFlorist) || (venType == VenueTypeFurniture) || (venType == VenueTypeGrocery))  ) {
        filterType = @"Stores";
    }
    
    if ((venType == VenueTypeFinance) || (venType == VenueTypePolice) || (venType == VenueTypePost) || (venType == VenueTypePharmacy) || (venType == VenueTypePhysio) || (venType == VenueTypeLawyer)  || (venType == VenueTypeInsurance || (venType == VenueTypeHospital) || (venType == VenueTypeEmbassy) || (venType == VenueTypeFire) || (venType == VenueTypeDentist) || (venType == VenueTypeCourthouse) || (venType == VenueTypeDoctor) || (venType == VenueTypeCityHall) || (venType == VenueTypeFurniture) || (venType == VenueTypeGrocery))  ) {
        filterType = @"Offices";
    }
    
    return filterType;
}

-(void)selectAllFilters {
    
    for (int i = 0; i < self.activeFilters.count; i++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        SPCMapFilterCollectionViewCell *cell = (SPCMapFilterCollectionViewCell *)[self.filtersCollectionView cellForItemAtIndexPath:indexPath];
        
        if (!cell.filterSelected) {
            [cell toggleFilter];
        }
    }
}

-(void)resetAllFilters {
    
    for (int i = 0; i < self.activeFilters.count; i++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        SPCMapFilterCollectionViewCell *cell = (SPCMapFilterCollectionViewCell *)[self.filtersCollectionView cellForItemAtIndexPath:indexPath];
        
        if (cell.filterSelected) {
            [cell toggleFilter];
        }
    }
}

-(void)updateMapPins {
    
    if (self.selectedFilters.count > 0) {
        [self.mapViewController fadeDownAllForFilters];
    }
    
    for (int i = 0; i < self.selectedFilters.count; i++) {
        
        NSString *currFilter = self.selectedFilters[i];
        
        if ([currFilter isEqualToString:@"All"]) {
            [self.mapViewController fadeUpAllFromFilters];
            break;
        }
        if ([currFilter isEqualToString:@"Cafes"]) {
            [self.mapViewController fadeUpCafes];
        }
        if ([currFilter isEqualToString:@"Restaurants"]) {
            [self.mapViewController fadeUpRestaurants];
        }
        if ([currFilter isEqualToString:@"Homes"]) {
            [self.mapViewController fadeUpHomes];
        }
        if ([currFilter isEqualToString:@"Travel"]) {
            [self.mapViewController fadeUpTravel];
        }
        if ([currFilter isEqualToString:@"Sports"]) {
            [self.mapViewController fadeUpSports];
        }
        if ([currFilter isEqualToString:@"Bars"]) {
            [self.mapViewController fadeUpBars];
        }
        if ([currFilter isEqualToString:@"Schools"]) {
            [self.mapViewController fadeUpSchools];
        }
        if ([currFilter isEqualToString:@"Fun"]) {
            [self.mapViewController fadeUpFun];
        }
        if ([currFilter isEqualToString:@"Stores"]) {
            [self.mapViewController fadeUpStore];
        }
        if ([currFilter isEqualToString:@"Offices"]) {
            [self.mapViewController fadeUpOffices];
        }
        if ([currFilter isEqualToString:@"Popular"]) {
            [self.mapViewController fadeUpPopular];
        }
        if ([currFilter isEqualToString:@"Favorites"]) {
            [self.mapViewController fadeUpFavorites];
        }
    }
}


#pragma mark - MAM Animation methods

- (void)spc_localMemoryPosted:(NSNotification *)note {
    NSLog(@"spc_localMemoryPosted!");
    Memory *memory = (Memory *)[note object];
    self.localMem = memory;
    
    NSArray *tempVenues = [NSArray arrayWithObjects:self.localMem.venue, nil];
    
    if (self.localMem.venue.specificity == SPCVenueIsReal) {
        [self.mamAnimationMapViewController updateVenues:tempVenues withCurrentVenue:self.localMem.venue deviceVenue:self.localMem.venue spayceState:SpayceStateDisplayingLocationData];
        [self.mamAnimationMapViewController showVenue:self.localMem.venue];
    }
    else {
        //modify animation for fuzzed veneus
        float venLat = [self.localMem.venue.latitude floatValue];
        float venLong = [self.localMem.venue.longitude floatValue];
        [self.mamAnimationMapViewController updateVenues:nil withCurrentVenue:nil deviceVenue:nil spayceState:SpayceStateDisplayingLocationData];
        [self.mamAnimationMapViewController showLatitude:venLat longitude:venLong zoom:8 animated:NO]; //jump to our new location
        [self.mamAnimationMapViewController showLatitude:venLat longitude:venLong zoom:8 animated:YES]; //handle the zoom since it's ignored on the above call
    }
    
    // refresh local grid...
    [self.localGridView fetchNearbyGridContent];
}

- (void)prepareToAnimateMemory {
    //NSLog(@"prepare to animate mem!");
    
    //take screenshot of grid?
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    UIGraphicsBeginImageContextWithOptions(rootViewController.view.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [rootViewController.view.layer renderInContext:context];
    self.gridScreenCapForTransition = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
   
    self.mamAnimationView.hidden = NO;
    [self hideCalloutDuringMAMAnimation];
    
    [self.view addSubview:self.animationImageView];
    
    //retrieve screenshot image saved when posting a mem
    NSString *documentsDirectoryPrev = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *currPreviewPath = [NSString stringWithFormat:@"mamAnimationImg.png"];
    NSString *previewPngPath = [documentsDirectoryPrev stringByAppendingPathComponent:currPreviewPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL previewSuccess = [fileManager fileExistsAtPath:previewPngPath];
    
    if (previewSuccess) {
        UIImage* screenImage = [[UIImage alloc] initWithContentsOfFile:previewPngPath];
        self.animationImageView.image = screenImage;
        self.animationImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.animationImageView.frame = CGRectMake(0,
                                                   0,
                                                   self.view.frame.size.width,
                                                   self.view.frame.size.height);
    } else {
        self.animationImageView.image = nil;
        self.animationImageView.frame = CGRectMake(0,
                                                   0,
                                                   self.view.frame.size.width,
                                                   self.view.frame.size.height);
    }
    
    self.mapViewController.animatingMemory = YES;
    [self performSelector:@selector(animateMemory) withObject:nil afterDelay:0.1];
}

- (void)animateMemory {
    if (!_animationImageView) {
        [self prepareToAnimateMemory];
    }
    
    CGPoint center = CGPointMake(self.animationImageView.frame.size.width/2, self.animationImageView.frame.size.height/2);
    self.animationImageView.layer.position = center;
    
    // time scalar.  Change this to alter the overall duration of
    // the animation without affecting relative timing.
    CGFloat ts = 4.6;
    
    // Animation has 3 stages (although they bleed into each other a little).
    // First: shrink down significantly to a point around the SW of the pin
    // Second: make a full rotation around the center (oval or circle), shrinking for
    //      the first 40-45% of the orbit.
    // Third: drop down into the center (the map pin) and fade out completely.
    
    // First section: shrink to starting position
    
    // set up scaling.  We quickly scale to 0.2, then finish the scaling
    // slowly from there.
    CABasicAnimation *resizeAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    CGFloat scale = 0.1;
    [resizeAnimation setToValue:[NSValue valueWithCGSize:CGSizeMake(self.animationImageView.frame.size.width * scale, self.animationImageView.frame.size.height * scale)]];
    resizeAnimation.fillMode = kCAFillModeForwards;
    resizeAnimation.removedOnCompletion = NO;
    resizeAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.1 :.65 :.4 :.8];
    resizeAnimation.duration = 0.23 * ts;
    
    CABasicAnimation *resizeAnimation2 = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    scale = 0.08;
    [resizeAnimation2 setToValue:[NSValue valueWithCGSize:CGSizeMake(self.animationImageView.frame.size.width * scale, self.animationImageView.frame.size.height * scale)]];
    resizeAnimation2.fillMode = kCAFillModeForwards;
    resizeAnimation2.removedOnCompletion = NO;
    resizeAnimation2.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.0 :.15 :.6 :1];
    resizeAnimation2.beginTime = resizeAnimation.duration;
    resizeAnimation2.duration = 0.10 * ts;
    
    // set up movement.  We move up during the initial, sharp scale-down, then swing around
    // a circle with EaseIn, EaseOut, before turning and descending into the center.
    
    // move left
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.calculationMode = kCAAnimationPaced;
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.1 :.5 :.2 :.6];
    pathAnimation.duration = 0.03 * ts;
    
    CGPoint endPoint = CGPointMake(self.view.bounds.size.width/2 - CGRectGetHeight(self.view.bounds)*0.2*0.8*0.9, self.view.bounds.size.height/2 + 30);
    CGMutablePathRef curvedPath = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath, NULL, center.x, center.y);
    CGPathAddCurveToPoint(curvedPath, NULL,
                          [self intrp:center.x to:endPoint.x with:0.5], center.y,
                          [self intrp:center.x to:endPoint.x with:0.9], [self intrp:center.y to:endPoint.y with:0.2],
                          endPoint.x, endPoint.y);
    pathAnimation.path = curvedPath;
    CGPathRelease(curvedPath);
    
    // ~circle
    CAKeyframeAnimation *pathAnimation2 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation2.calculationMode = kCAAnimationPaced;
    pathAnimation2.fillMode = kCAFillModeForwards;
    pathAnimation2.removedOnCompletion = NO;
    pathAnimation2.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.5 :.25 :.5 :.65];
    pathAnimation2.duration = .16 * ts;
    pathAnimation2.beginTime = pathAnimation.duration;
    
    // See http://spencermortensen.com/articles/bezier-circle/ for a description
    // of this circle approximation.  For an oval approximation, alter the two values of
    // xC / yC to be nonequal.
    CGFloat yR = CGRectGetHeight(self.view.bounds)*0.2;
    CGFloat xR = yR * 0.8;
    CGFloat yBend = 0;// 0.05 * yR;
    CGFloat xC = 0.551915024494 * xR;
    CGFloat yC = 0.551915024494 * yR;
    CGMutablePathRef curvedPath2 = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath2, NULL, endPoint.x, endPoint.y);
    
    // counter-clockwise from top to left...
    //CGPathAddCurveToPoint(curvedPath2, NULL,
    //                      endPoint.x-xC, center.y-yR - yBend,
    //                      center.x-xR, center.y-yC,
    //                      center.x-xR, center.y);
    
    
    endPoint = CGPointMake(self.view.bounds.size.width/2 - 30, self.view.bounds.size.height*0.3);
    
    // left to bottom...
    CGPathAddCurveToPoint(curvedPath2, NULL,
                          center.x-xR, center.y+yC,
                          center.x-xC, center.y+yR,
                          center.x,    center.y+yR);
    // bottom to right...
    CGPathAddCurveToPoint(curvedPath2, NULL,
                          center.x+xC, center.y+yR,
                          center.x+xR, center.y+yC,
                          center.x+xR, center.y);
    
    // right to top...
    CGPathAddCurveToPoint(curvedPath2, NULL,
                          center.x+xR, center.y-yC,
                          center.x*2 - endPoint.x+xC, center.y-yR,
                          center.x*2 - endPoint.x,    center.y-yR - yBend);
    pathAnimation2.path = curvedPath2;
    CGPathRelease(curvedPath2);
    
    // move down
    CAKeyframeAnimation *pathAnimation3 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation3.calculationMode = kCAAnimationPaced;
    pathAnimation3.fillMode = kCAFillModeForwards;
    pathAnimation3.removedOnCompletion = NO;
    pathAnimation3.timingFunction = [CAMediaTimingFunction functionWithControlPoints:.8 :.5 :.9 :.6];
    pathAnimation3.duration = 0.05*ts;
    pathAnimation3.beginTime = pathAnimation2.beginTime + pathAnimation2.duration;
    
    endPoint = CGPointMake(self.view.bounds.size.width/2 + 30, self.view.bounds.size.height*0.3);
    CGMutablePathRef curvedPath3 = CGPathCreateMutable();
    CGPathMoveToPoint(curvedPath3, NULL, endPoint.x, endPoint.y);
    CGPathAddCurveToPoint(curvedPath3, NULL,
                          [self intrp:center.x to:endPoint.x with:0.2], [self intrp:center.y to:endPoint.y with:1.03],
                          center.x, [self intrp:center.y to:endPoint.y with:0.5],
                          center.x, center.y);
    pathAnimation3.path = curvedPath3;
    CGPathRelease(curvedPath3);
    
    
    // Set up fade out effect (alpha and size)
    CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeOutAnimation setToValue:@0.0];
    fadeOutAnimation.fillMode = kCAFillModeForwards;
    fadeOutAnimation.removedOnCompletion = NO;
    fadeOutAnimation.beginTime = pathAnimation3.beginTime;
    fadeOutAnimation.duration = pathAnimation3.duration;
    fadeOutAnimation.timingFunction = pathAnimation3.timingFunction;
    
    CABasicAnimation *resizeAnimation3 = [CABasicAnimation animationWithKeyPath:@"bounds.size"];
    scale = 0.03;
    [resizeAnimation3 setToValue:[NSValue valueWithCGSize:CGSizeMake(self.animationImageView.frame.size.width * scale, self.animationImageView.frame.size.height * scale)]];
    resizeAnimation3.fillMode = kCAFillModeForwards;
    resizeAnimation3.removedOnCompletion = NO;
    resizeAnimation3.timingFunction = pathAnimation3.timingFunction;
    resizeAnimation3.duration = pathAnimation3.duration;
    resizeAnimation3.beginTime = pathAnimation3.beginTime;
    
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.fillMode = kCAFillModeForwards;
    group.removedOnCompletion = NO;
    [group setAnimations:@[pathAnimation, pathAnimation2, pathAnimation3, resizeAnimation, resizeAnimation2, resizeAnimation3, fadeOutAnimation]];
    group.duration = MAX(resizeAnimation2.duration + resizeAnimation2.beginTime, pathAnimation3.duration + pathAnimation3.beginTime);
    group.delegate = self;
    [group setValue:self.animationImageView forKey:@"imageViewBeingAnimated"];
    
    
    
    // Add the animation
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [self cleanUpAnimation];
    }];
    [self.animationImageView.layer addAnimation:group forKey:@"savingAnimation"];
    [CATransaction commit];
}

-(CGFloat)intrp:(CGFloat)a to:(CGFloat)b with:(CGFloat)prop {
    return b * prop + a * (1 - prop);
}

-(void)cleanUpAnimation {
    UIView *view;
    NSArray *subs = [self.animationImageView subviews];
    
    for (view in subs) {
        [view removeFromSuperview];
    }
    [self.animationImageView removeFromSuperview];
    self.animationImageView = nil;
    self.view.userInteractionEnabled = YES;
    
    self.mapViewController.animatingMemory = NO;
    
    [self performSelector:@selector(restoreCalloutAfterMAMAnimation) withObject:nil afterDelay:1.0f];
    
    self.localMem.venue.totalMemories = self.localMem.venue.totalMemories + 1;
    
    // show the memory / venue detail...
    // show the local tab, and refresh it...
    [self skipToLocalGrid];
    [UIView animateWithDuration:0.3 animations:^{
        self.mamAnimationView.alpha = 0;
    } completion:^(BOOL finished) {
        self.mamAnimationView.hidden = YES;
        self.mamAnimationView.alpha = 1;
    }];
    
    //[self showVenueDetail:self.localMem.venue jumpToRecentMemory:self.localMem];
}

- (void)handleMAM:(NSNotification *)notification {
    if (SPCMontageViewStatePlaying == self.viewMontagePlaying.state) {
        [self.viewMontagePlaying pause];
    }
}

- (void)dismissMAM:(NSNotification *)notification {
    if (self.viewIsVisible && nil == self.navFromMontage && SPCMontageViewStatePaused == self.viewMontagePlaying.state) {
        [self.viewMontagePlaying play];
    }
}

#pragma mark = Anon Education Screen

- (void)presentAnonUnlockScreenAfterDelay:(NSNumber *)delayInSeconds {
    __weak typeof(self) weakSelf = self;
    
    if (self.viewIsVisible) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delayInSeconds floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf.viewIsVisible && !strongSelf.presentedAnonUnlockScreenInstance && strongSelf.gridIsVisible) {
                
                [strongSelf hideCalloutDuringMAMAnimation];
                
                strongSelf.presentedAnonUnlockScreenInstance = YES;
                UIImage *imageBlurred = [UIImageEffects takeSnapshotOfView:strongSelf.view];
                imageBlurred = [UIImageEffects imageByApplyingBlurToImage:imageBlurred withRadius:5.0 tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:2.0 maskImage:nil];
                strongSelf.viewBlurredScreen = [[UIImageView alloc] initWithImage:imageBlurred];
                
                CGRect frameToPresent = CGRectMake(10, 50, CGRectGetWidth(strongSelf.view.bounds) - 20, CGRectGetHeight(strongSelf.view.frame) - 100 - 45); // 45pt for toolbar height
                strongSelf.anonUnlockScreen = [[SPCAnonUnlockedView alloc] initWithFrame:frameToPresent];
                [strongSelf.anonUnlockScreen.btnFinished addTarget:strongSelf action:@selector(dismissAnonUnlockScreen:) forControlEvents:UIControlEventTouchUpInside];
                
                [UIView transitionWithView:strongSelf.view
                                  duration:0.6f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [strongSelf.view addSubview:strongSelf.viewBlurredScreen];
                                    [strongSelf.view addSubview:strongSelf.anonUnlockScreen];
                                }
                                completion:nil];
            }
        });
    }
}

- (void)dismissAnonUnlockScreen:(id)sender {
    [UIView transitionWithView:self.view
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        [self.anonUnlockScreen removeFromSuperview];
                        [self.viewBlurredScreen removeFromSuperview];
                    }
                    completion:^(BOOL completed) {
                        self.anonUnlockScreen = nil;
                        self.viewBlurredScreen = nil;
                        [self restoreCalloutAfterMAMAnimation];
                    }];
    
    // Set shown on dismissal
    [self setAnonUnlockScreenWasShown:YES];
}

- (void)setAnonUnlockScreenWasShown:(BOOL)anonUnlockScreenWasShown {
    NSString *strAnonUnlockStringUserLiteralKey = [SPCLiterals literal:kSPCAnonUnlockScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    [[NSUserDefaults standardUserDefaults] setBool:anonUnlockScreenWasShown forKey:strAnonUnlockStringUserLiteralKey];
}

- (BOOL)anonUnlockScreenWasShown {
    BOOL wasShown = NO;
    
    NSString *strAnonUnlockStringUserLiteralKey = [SPCLiterals literal:kSPCAnonUnlockScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:strAnonUnlockStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strAnonUnlockStringUserLiteralKey];
    }
    
    return wasShown;
}


#pragma mark = Anon Warning Screen

- (void)presentAnonWarningScreenAfterDelay:(NSNumber *)delayInSeconds {
    __weak typeof(self) weakSelf = self;
    
    if (self.viewIsVisible) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delayInSeconds floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf.viewIsVisible && !strongSelf.presentedAnonWarningScreenInstance && strongSelf.gridIsVisible) {
                
                strongSelf.presentedAnonWarningScreenInstance = YES;
                UIImage *imageBlurred = [UIImageEffects takeSnapshotOfView:strongSelf.view];
                imageBlurred = [UIImageEffects imageByApplyingBlurToImage:imageBlurred withRadius:5.0 tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:2.0 maskImage:nil];
                strongSelf.viewBlurredScreen = [[UIImageView alloc] initWithImage:imageBlurred];
                
                CGRect frameToPresent = CGRectMake(10, 50, CGRectGetWidth(strongSelf.view.bounds) - 20, CGRectGetHeight(strongSelf.view.frame) - 100 - 45); // 45pt for toolbar height
                strongSelf.anonWarningScreen = [[SPCAnonWarningView alloc] initWithFrame:frameToPresent];
                [strongSelf.anonWarningScreen.btnFinished addTarget:strongSelf action:@selector(dismissAnonWarningScreen:) forControlEvents:UIControlEventTouchUpInside];
                
                [UIView transitionWithView:strongSelf.view
                                  duration:0.6f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [strongSelf.view addSubview:strongSelf.viewBlurredScreen];
                                    [strongSelf.view addSubview:strongSelf.anonWarningScreen];
                                }
                                completion:nil];
            }
        });
    }
}

- (void)dismissAnonWarningScreen:(id)sender {
    [UIView transitionWithView:self.view
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        [self.anonWarningScreen removeFromSuperview];
                        [self.viewBlurredScreen removeFromSuperview];
                    }
                    completion:^(BOOL completed) {
                        self.anonWarningScreen = nil;
                        self.viewBlurredScreen = nil;
                    }];
    
    // Set shown on dismissal
    [self setAnonWarningScreenWasShown:YES];
    
    NSString *lastWarningCountLiteralKey = [SPCLiterals literal:kSPCAnonWarningScreenLastWarningCountWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    [[NSUserDefaults standardUserDefaults] setInteger:[SettingsManager sharedInstance].currAnonWarningCount forKey:lastWarningCountLiteralKey];
    [SettingsManager sharedInstance].anonWarningNeeded = NO;
}

- (void)setAnonWarningScreenWasShown:(BOOL)anonUnlockScreenWasShown {
    NSString *strAnonUnlockStringUserLiteralKey = [SPCLiterals literal:kSPCAnonWarningScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    [[NSUserDefaults standardUserDefaults] setBool:anonUnlockScreenWasShown forKey:strAnonUnlockStringUserLiteralKey];
}

- (BOOL)anonWarningScreenWasShown {
    BOOL wasShown = NO;
    
    NSString *strAnonUnlockStringUserLiteralKey = [SPCLiterals literal:kSPCAnonWarningScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:strAnonUnlockStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strAnonUnlockStringUserLiteralKey];
    }
    
    return wasShown;
}



#pragma mark - Admin Warning screen

- (void)presentAdminWarningScreenAfterDelay:(NSNumber *)delayInSeconds {
    __weak typeof(self) weakSelf = self;
    
    if (self.viewIsVisible) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delayInSeconds floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf.viewIsVisible && !strongSelf.presentedAdminWarningScreenInstance && strongSelf.gridIsVisible) {
                
                strongSelf.presentedAdminWarningScreenInstance = YES;
                UIImage *imageBlurred = [UIImageEffects takeSnapshotOfView:strongSelf.view];
                imageBlurred = [UIImageEffects imageByApplyingBlurToImage:imageBlurred withRadius:5.0 tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:2.0 maskImage:nil];
                strongSelf.viewBlurredScreen = [[UIImageView alloc] initWithImage:imageBlurred];
                
                CGRect frameToPresent = CGRectMake(10, 50, CGRectGetWidth(strongSelf.view.bounds) - 20, CGRectGetHeight(strongSelf.view.frame) - 100 - 45); // 45pt for toolbar height
                strongSelf.adminWarningScreen = [[SPCAdminWarningView alloc] initWithFrame:frameToPresent];
                [strongSelf.adminWarningScreen.btnFinished addTarget:strongSelf action:@selector(dismissAdminWarningScreen:) forControlEvents:UIControlEventTouchUpInside];
                
                [UIView transitionWithView:strongSelf.view
                                  duration:0.6f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [strongSelf.view addSubview:strongSelf.viewBlurredScreen];
                                    [strongSelf.view addSubview:strongSelf.adminWarningScreen];
                                }
                                completion:nil];
            }
        });
    }
}

- (void)dismissAdminWarningScreen:(id)sender {
    [UIView transitionWithView:self.view
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        [self.adminWarningScreen removeFromSuperview];
                        [self.viewBlurredScreen removeFromSuperview];
                    }
                    completion:^(BOOL completed) {
                        self.AdminWarningScreen = nil;
                        self.viewBlurredScreen = nil;
                    }];
    
    NSString *lastWarningCountLiteralKey = [SPCLiterals literal:kSPCAdminWarningScreenLastWarningCountWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    [[NSUserDefaults standardUserDefaults] setInteger:[SettingsManager sharedInstance].currAdminWarningCount forKey:lastWarningCountLiteralKey];
    [SettingsManager sharedInstance].adminWarningNeeded = NO;
}



#pragma mark - Callouts

typedef enum CalloutEventType {
    CalloutEventTypeUnknown = 0,
    CalloutEventTypeHomeTabTapped = 1,
    CalloutEventTypeFlyTapped = 2,
    CalloutEventTypeWorldTapped = 3,
    CalloutEventTypeApplicationDidBecomeActive = 4,
    CalloutEventTypeApplicationWillResignActive = 5,
    CalloutEventTypeLocalGridLoaded = 6,
} CalloutEventType;

- (void)determineCalloutToShowFromEvent:(CalloutEventType)eventType {
    // We need to determine whether we need to set a new callout to display or not.
    // First, continue only if our calloutToPresent is nil, i.e. we do not have a callout already queued to present
    if (nil == self.calloutToPresent && NO == self.calloutIsOnscreen && NO == self.allCalloutsShown) {
        NSString *strCalloutKeyToPresent = nil;
        if (CalloutEventTypeHomeTabTapped == eventType) {
            if (NO == [self hasShownCallout:kSPCCalloutWorldWasShown]) {
                strCalloutKeyToPresent = kSPCCalloutWorldWasShown;
            } /*else if (NO == [self hasShownCallout:kSPCCalloutFlyWasShown]) {
                strCalloutKeyToPresent = kSPCCalloutFlyWasShown;
            } */else if (NO == [self hasShownCallout:kSPCCalloutMAMWasShown]) {
                strCalloutKeyToPresent = kSPCCalloutMAMWasShown;
            } else if (NO == [self hasShownCallout:kSPCCalloutLocalWasShown]) {
                if (self.locationAvailable) {
                    strCalloutKeyToPresent = kSPCCalloutLocalWasShown;
                }
            } else {
                // The case in which all callouts have been shown
                self.allCalloutsShown = YES;
            }
        } else if (CalloutEventTypeFlyTapped == eventType) {
            if (NO == [self hasShownCallout:kSPCCalloutFlyWasShown]) {
                strCalloutKeyToPresent = kSPCCalloutFlyWasShown;
            }
        } else if (CalloutEventTypeWorldTapped == eventType) {
            if (NO == [self hasShownCallout:kSPCCalloutWorldWasShown]) {
                strCalloutKeyToPresent = kSPCCalloutWorldWasShown;
            }
        } else if (CalloutEventTypeApplicationDidBecomeActive == eventType) {
            if (NO == [self hasShownCallout:kSPCCalloutLocalWasShown] && NO == self.locationAvailableAtLastResign && self.locationAvailable && 0 < self.localGridView.cellCount) {
                strCalloutKeyToPresent = kSPCCalloutLocalWasShown;
            }
        } else if (CalloutEventTypeApplicationWillResignActive == eventType) {
            self.locationAvailableAtLastResign = self.locationAvailable;
        } else if (CalloutEventTypeLocalGridLoaded == eventType) {
            if (NO == [self hasShownCallout:kSPCCalloutLocalWasShown] && 0 < self.localGridView.cellCount)
                strCalloutKeyToPresent = kSPCCalloutLocalWasShown;
        }
        
        // If we have a callout to present, go ahead and set it up
        if (nil != strCalloutKeyToPresent) {
            self.calloutNSUserDefaultsKey = strCalloutKeyToPresent;
            self.calloutToPresent = [[SPCCallout alloc] init];
            [self.calloutToPresent.btnDismiss addTarget:self action:@selector(dismissCallout:) forControlEvents:UIControlEventTouchUpInside];
            
            NSDictionary *dicStringAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:15.0f] };
            NSMutableAttributedString *strCalloutText = nil;
            CGRect rectCallout = CGRectZero;
            CGFloat arrowOffset = 0.0f;
            CGFloat labelHorizontalOffset = 0.0f;
            CalloutArrowLocation arrowLocation = CalloutArrowLocationUnknown;
            if ([kSPCCalloutWorldWasShown isEqualToString:strCalloutKeyToPresent]) { // World Callout
                strCalloutText = [[NSMutableAttributedString alloc] initWithString:@"See what's happening around\nthe world in real-time" attributes:dicStringAttributes];
                
                // Calculate our frame
                CGFloat width = 250.0f;
                CGFloat rightPadding = (CGRectGetWidth(self.view.bounds) - width) / 2;
                CGFloat height = 70.0f;
                rectCallout = CGRectMake(CGRectGetWidth(self.view.bounds) - rightPadding - width, CGRectGetHeight(self.hmSegmentedControl.frame) + CGRectGetHeight(self.navBar.frame) + 6.0f, width, height);
                arrowOffset = rectCallout.size.width - ((CGRectGetWidth(self.view.bounds) - ((CGRectGetWidth(self.hmSegmentedControl.frame) * 0.50f) - (CGRectGetWidth(self.hmSegmentedControl.frame) * 0.50f *[HMSegmentedControl firstLastSegmentOffsetPercent]) - ([[self.hmSegmentedControl.sectionTitles firstObject] sizeWithAttributes:@{NSFontAttributeName : self.hmSegmentedControl.font}].width / 2))) - rightPadding);
                arrowLocation = CalloutArrowLocationTop;
                labelHorizontalOffset = 2.0f;
                
            } else if ([kSPCCalloutLocalWasShown isEqualToString:strCalloutKeyToPresent]) { // Local Callout
                strCalloutText = [[NSMutableAttributedString alloc] initWithString:@"See what's happening\nin your local area" attributes:dicStringAttributes];
                [strCalloutText addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"OpenSans-Bold" size:15.0f] range:NSMakeRange([strCalloutText length] - 10, 5)];
                
                // Calculate our frame
                CGFloat width = 260.0f;
                CGFloat rightPadding = (CGRectGetWidth(self.view.bounds) - width) / 2;
                CGFloat height = 70.0f;
                rectCallout = CGRectMake(CGRectGetWidth(self.view.bounds) - rightPadding - width, CGRectGetHeight(self.hmSegmentedControl.frame) + CGRectGetHeight(self.navBar.frame) + 6.0f, width, height);
                arrowOffset = rectCallout.size.width - ((CGRectGetWidth(self.view.bounds) - ((CGRectGetWidth(self.hmSegmentedControl.frame) * 0.50f) + (CGRectGetWidth(self.hmSegmentedControl.frame) * 0.50f *[HMSegmentedControl firstLastSegmentOffsetPercent]) + ([[self.hmSegmentedControl.sectionTitles lastObject] sizeWithAttributes:@{NSFontAttributeName : self.hmSegmentedControl.font}].width / 2))) - rightPadding);
                arrowLocation = CalloutArrowLocationTop;
                labelHorizontalOffset = -15.0f;
                
            } else if ([kSPCCalloutFlyWasShown isEqualToString:strCalloutKeyToPresent]) { // Fly Callout
                strCalloutText = [[NSMutableAttributedString alloc] initWithString:@"Fly around the world to\ndifferent places" attributes:dicStringAttributes];
                
                // Calculate our frame
                CGFloat rightPadding = 10.0f;
                CGFloat height = 70.0f;
                CGFloat width = 250.0f;
                rectCallout = CGRectMake(CGRectGetWidth(self.view.bounds) - rightPadding - width, CGRectGetMaxY(self.flyBtn.frame) + 3.0f, width, height);
                arrowOffset = rectCallout.size.width - (CGRectGetWidth(self.view.bounds) - CGRectGetMidX(self.flyBtn.frame) - rightPadding);
                arrowLocation = CalloutArrowLocationTop;
                labelHorizontalOffset = -10.0f;
                
            } else if ([kSPCCalloutMAMWasShown isEqualToString:strCalloutKeyToPresent]) { // MAM Callout
                strCalloutText = [[NSMutableAttributedString alloc] initWithString:@"Make your first memory now!" attributes:dicStringAttributes];
                
                // Calculate our frame
                CGFloat width = 270.0f;
                CGFloat rightPadding = (CGRectGetWidth(self.view.bounds) - width) / 2.0f;
                CGFloat height = 62.5f;
                rectCallout = CGRectMake(CGRectGetWidth(self.view.bounds) - rightPadding - width, CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.tabBarController.tabBar.frame) - 6.0f - height, width, height);
                arrowOffset = width/2.0f;
                arrowLocation = CalloutArrowLocationBottom;
            }
            
            self.rectCallout = rectCallout;
            [self.calloutToPresent configureWithString:strCalloutText arrowLocation:arrowLocation andArrowOffset:arrowOffset];
            self.calloutToPresent.labelHorizontalOffset = labelHorizontalOffset;
        }
    }
}

- (void)setCallout:(NSString *)calloutKey wasShown:(BOOL)wasShown {
    NSString *strCalloutUserKey = [SPCLiterals literal:calloutKey forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setBool:wasShown forKey:strCalloutUserKey];
}

- (BOOL)hasShownCallout:(NSString *)calloutKey {
    BOOL wasShown = NO;
    
    NSString *strCalloutUserKey = [SPCLiterals literal:calloutKey forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strCalloutUserKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strCalloutUserKey];
    }
    
    return wasShown;
}

- (void)dismissCallout:(id)sender {
    [self.calloutToPresent removeFromSuperview];
    [self setCallout:self.calloutNSUserDefaultsKey wasShown:YES];
    self.calloutIsOnscreen = NO;
    self.calloutToPresent = nil;
    self.calloutNSUserDefaultsKey = nil;
}

- (void)presentQueuedCallout {
    if (NO == self.calloutIsOnscreen && nil != self.calloutToPresent && CGRectGetMidY(self.navBar.frame) == self.navBarOriginalCenterY) {
        self.calloutIsOnscreen = YES;
        self.calloutToPresent.alpha = 0.0f;
        
        CGFloat initialYOffset = 80.0f;
        if (CGRectGetHeight(self.view.bounds)/2.0f > CGRectGetMaxY(self.rectCallout)) {
            initialYOffset = -1 * initialYOffset;
        }
        self.calloutToPresent.frame = CGRectOffset(self.rectCallout, 0.0f, initialYOffset);
        
        [self.view addSubview:self.calloutToPresent];
        
        [UIView animateWithDuration:0.7f delay:0.2f usingSpringWithDamping:0.68f initialSpringVelocity:8.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.calloutToPresent.alpha = 1.0f;
            self.calloutToPresent.frame = self.rectCallout;
        } completion:nil];
    }
}

- (void)hideCalloutDuringMAMAnimation {
    if (self.calloutIsOnscreen) {
        self.calloutToPresent.alpha = 0.0f;
    }
}

- (void)restoreCalloutAfterMAMAnimation {
    if (self.calloutIsOnscreen) {
        self.calloutToPresent.alpha = 1.0f;
    }
}

#pragma mark - Resizing for Status Bar

- (void)handleStatusBarChange:(NSNotification*)notification {
    self.localGridView.collectionView.frame = self.view.frame;
    self.worldGridView.collectionView.frame = self.view.frame;
}

@end
