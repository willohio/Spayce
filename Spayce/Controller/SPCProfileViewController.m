//
//  ProfileViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 3/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileViewController.h"

// Model
#import "Friend.h"
#import "ProfileDetail.h"
#import "SPCAlertAction.h"
#import "SPCNeighborhood.h"
#import "SPCProfileFeedDataSource.h"
#import "UserProfile.h"
#import "User.h"
#import "Asset.h"
#import "SPCNotifications.h"

// View
// TODO: Remove unused
#import "LargeBlockingProgressView.h"
#import "MemoryCell.h"
#import "SPCInitialsImageView.h"
#import "SPCNewsLogCell.h"
#import "SPCProfileBioCell.h"
#import "SPCProfileConnectionsCell.h"
#import "SPCProfileMapsCell.h"
#import "SPCProfileMutualFriendsCell.h"
#import "SPCProfileFriendsCell.h"
#import "SPCProfileFriendActionCell.h"
#import "SPCProfileTerritoriesCell.h"
#import "SPCProfileHeaderView.h"
#import "SPCProfileTitleView.h"
#import "SPCProfileDescriptionView.h"
#import "SPCProfileRecentCell.h"
#import "SPCProfileSegmentedControlCell.h"
#import "SPCProfilePlaceholderCell.h"
#import "SPCEarthquakeLoader.h"
#import "SPCPeopleEducationView.h"
#import "SPCRelationshipDetailCell.h"
#import "SPCProfileDescriptionView.h"
#import "SPCMemoryGridCollectionView.h"

// Controller
#import "SPCAlertViewController.h"
#import "SPCEditBioViewController.h"
#import "SPCFriendsListPlaceholderViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCProfileFollowListPlaceholderViewController.h"
#import "SPCProfileFollowListViewController.h"
#import "SPCProfileStarPowerViewController.h"
#import "SPCLightboxViewController.h"

#import "SPCNotificationsViewController.h"
#import "SPCSettingsTableViewController.h"
#import "SPCProfileTerritoriesViewController.h"
#import "SPCTerritoriesListPlaceholderViewController.h"
#import "MemoryCommentsViewController.h"
#import "SPCMessagesViewController.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "ProfileManager.h"
#import "PNSManager.h"
#import "AdminManager.h"

// Transitions
#import "SPCAlertTransitionAnimator.h"

// Utility
#import "ImageUtils.h"
#import "ImageCache.h"
#import "APIUtils.h"

// Category
#import "NSString+SPCAdditions.h"
#import "UIAlertView+SPCAdditions.h"
#import "UIScrollView+SPCParallax.h"
#import "UIViewController+SPCAdditions.h"
#import "UIImageView+WebCache.h"
#import "UITabBarController+SPCAdditions.h"
#import "UIColor+Expanded.h"
#import "UIImageEffects.h"
#import "UITableView+SPXRevealAdditions.h"

// Constants
#import "Constants.h"

// Literals
#import "SPCLiterals.h"

//Frameworks
#import "Flurry.h"

static CGFloat kTableHeaderViewAspectRatio = 750.0f/390.0f; // Width:Height
static CGFloat kHeaderTitleViewMinOpacityOffsetY = 0;
static CGFloat kHeaderTitleViewMaxOpacityOffsetY = 60;
static CGFloat kNavigationBarMinOpacityOffsetY = 135;
static CGFloat kNavigationBarMaxOpacityOffsetY = 150;

static NSUInteger kMaxNumberRecentMemories = 200;

@interface SPCProfileViewController () <UIViewControllerTransitioningDelegate, GKImagePickerDelegate, SPCProfileDescriptionViewDelegate, SPCProfileSegmentedControllCellDelegate, UICollectionViewDelegate>

// Data
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) NSArray *dataSources;
@property (nonatomic, strong) SPCProfileFeedDataSource *dataSource;
@property (nonatomic, assign) NSInteger maxIndexViewed;
@property (nonatomic, strong) NSString *recentFeedNextPageKey;
@property (nonatomic, assign) NSUInteger feedCountBeforeLatestPagination;

// State
@property (nonatomic, assign, getter = isFetchingProfile) BOOL fetchingProfile;
@property (nonatomic, assign, getter = isFetchingBanner) BOOL fetchingBanner;
@property (nonatomic, assign, getter = isUpdatingBanner) BOOL updatingBanner;
@property (nonatomic, assign, getter = isFetchingNextRecentMemoriesPage) BOOL fetchingNextRecentMemoriesPage;

// UI
@property (nonatomic, strong) UIView *customNavigationBarContainerView;
@property (nonatomic, strong) UIView *customNavigationBar;
@property (nonatomic, strong) SPCProfileTitleView *titleView;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) SPCMemoryGridCollectionView *memoryGridCollectionView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *backButtonGray;

// UI - Header view
@property (nonatomic, strong) SPCProfileHeaderView *headerView;

// UI - Activity indicators
@property (nonatomic, strong) UIView *profileActivityIndicatorView;
@property (nonatomic, strong) LargeBlockingProgressView *bannerUpdateProgressView;
@property (nonatomic, strong) UIView *tableRecentMemFooterView;

// Updating images
@property (nonatomic) enum ProfileImageEditingState profileImageEditingState;
@property (nonatomic, strong) GKImagePicker *imagePicker;

// Updating display
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isStale;
@property (nonatomic, assign) BOOL isUpdated;
@property (nonatomic, assign) BOOL haveAddedNewsLog;

// UI - Loading popular/shared memories, Uploading profile/banner assets
@property (nonatomic, strong) SPCEarthquakeLoader *uploadLoader;
@property (nonatomic, strong) SPCEarthquakeLoader *memoriesLoader;

// Navigation - Moving to MCVC from grid cell tap
@property (nonatomic, strong) UINavigationController *navFromGrid;
@property (nonatomic, strong) UIView *clippingView;
@property (nonatomic, strong) UIImageView *expandingImageView;
@property (nonatomic) CGRect expandingImageRect;
@property (nonatomic) BOOL expandingDidHideTabBar;

// UI - tab bar
@property (nonatomic, assign) BOOL tabBarVisibleOnAppearance;

//people education screen
@property (nonatomic) BOOL educationScreenWasShown; // Persisted value
@property (nonatomic) BOOL presentedEducationScreenInstance; // This instance's value
@property (nonatomic, strong) UIImageView *viewBlurredScreen;
@property (nonatomic, strong) SPCPeopleEducationView *viewEducationScreen;

@end

@implementation SPCProfileViewController

#pragma mark - Object lifecycle

- (void)dealloc {
    // Stop observing all the notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Cancel any scheduled or delayed calls to self
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_tableView];
    
    // Remove all observers
    @try {
        [self removeObserver:self forKeyPath:@"updatingBanner"];
        [self removeObserver:self forKeyPath:@"fetchingProfile"];
        [self removeObserver:self forKeyPath:@"fetchingBanner"];
        
        [_dataSource removeObserver:self forKeyPath:@"draggingScrollView"];
    } @catch (NSException *exception) {}
    
    // Clean up
    if (_dataSource) {
        _dataSource.delegate = nil;
    }
    if (_imagePicker) {
        _imagePicker.delegate = nil;
    }
    if (_tableView) {
        [_tableView removeParallaxView];
        
        _tableView.delegate = nil;
        _tableView.dataSource = nil;
    }
    if (_memoryGridCollectionView) {
        _memoryGridCollectionView = nil;
    }
}

- (instancetype)initWithUserToken:(NSString *)userToken {
    self = [super init];
    if (self) {
        _userToken = userToken;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
    }
    return self;
}

#pragma mark - Managing the View

- (void)loadView {
    [super loadView];
    
    NSLog(@"profile load view");
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.profileActivityIndicatorView];
    [self.view addSubview:self.customNavigationBarContainerView];
    
    [self.customNavigationBarContainerView addSubview:self.customNavigationBar];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    
    [self.customNavigationBar addSubview:self.titleView];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBar attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:CGRectGetWidth(self.customNavigationBarContainerView.frame) - CGRectGetWidth(self.backButton.frame) * 2.0 - 20]];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.titleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBar attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)]];
    
    [self.customNavigationBarContainerView addSubview:self.actionButton];
    self.actionButton.hidden = YES;
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:7]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:58]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.actionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:58]];
    
    [self.customNavigationBarContainerView addSubview:self.settingsButton];
    self.settingsButton.hidden = YES;
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.settingsButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-4]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.settingsButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBarContainerView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-6]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.settingsButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:36]];
    [self.customNavigationBarContainerView addConstraint:[NSLayoutConstraint constraintWithItem:self.settingsButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:36]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Opt for bottom only extended layout
    self.edgesForExtendedLayout = UIRectEdgeBottom;
    
    // Configure UI
    [self configureNavigationBar];
    [self configureActions];
    [self configureTableView];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    // Add KVO observers for inner controller state
    [self addObserver:self forKeyPath:@"updatingBanner" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"fetchingProfile" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"fetchingBanner" options:NSKeyValueObservingOptionNew context:nil];
    
    [self.dataSource addObserver:self forKeyPath:@"draggingScrollView" options:NSKeyValueObservingOptionNew context:nil];
    
    // Subscribe for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProfile) name:ContactAndProfileManagerPersonalProfileDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProfile) name:SPCProfileReload object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryAdded:) name:@"addMemoryLocally" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNewsNotification:) name:SPCProfileDidSelectNewsNotification object:self.dataSource];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showBioUpdateNotification:) name:SPCProfileDidSelectBioUpdateNotification object:self.dataSource];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCityNotification:) name:SPCProfileDidSelectCityNotification object:self.dataSource];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNeighborhoodNotification:) name:SPCProfileDidSelectNeighborhoodNotification object:self.dataSource];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addNewProfileCellNotification:) name:SPCProfileDidAddNewCellNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectFollowUserNotification:) name:SPCProfileDidSelectFollowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectUnfollowUserNotification:) name:SPCProfileDidSelectUnfollowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAcceptFollowUserNotification:) name:SPCProfileDidSelectAcceptFollowNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStarMemory:) name:kDidStarMemory object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnstarMemory:) name:kDidUnstarMemory object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didStarComment:) name:kDidStarComment object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnstarComment:) name:kDidUnstarComment object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddFriendNotification:) name:kDidAddFriend object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAddBlockNotification:) name:kDidAddBlock object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveFriendNotification:) name:kDidRemoveFriend object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRemoveBlockNotification:) name:kDidRemoveBlock object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRequestFollowNotification:) name:kFollowDidRequestWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFollowNotification:) name:kFollowDidFollowWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnfollowNotification:) name:kFollowDidUnfollowWithUserToken object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didAcceptFollowRequestNotification:) name:kFollowRequestResponseDidAcceptWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRejectFollowRequestNotification:) name:kFollowRequestResponseDidRejectWithUserToken object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    
    // Tab Bar selected item changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarSelectedItemChanged:) name:kSPCTabBarSelectedItemDidChangeNotification object:nil];
    
    // Filtering the feed
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:SPCReloadProfileData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:SPCReloadProfileForFilters object:nil];
    
    // Fetch data
    [self fetchUserProfile];
}

#pragma mark - Responding to View Events

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Hide navigation controller
    self.navigationController.navigationBarHidden = YES;
    
    // Update status & navigation bar visibility
    [self updateTitleViewWithOffset:self.tableView.contentOffset];
    [self updateNavigationBarWithOffset:self.tableView.contentOffset];
    
    // Update tab bar visibility and content/scroll insets
    if (!self.tabBarController.tabBar.hidden) {
        self.tabBarVisibleOnAppearance = YES;
    }
    
    if (self.isRootViewController) {
        self.tabBarController.tabBar.alpha = 1;
    }
    
    self.tabBarController.tabBar.hidden = !self.isRootViewController;
    
    // Update memory cells (to keep their timestamps up to date).
    NSArray *visibleRows = [self.tableView indexPathsForVisibleRows];
    BOOL shouldReload = NO;
    for (NSIndexPath *indexPath in visibleRows) {
        if ([self.dataSource isMemoryAtIndexPath:indexPath]) {
            shouldReload = YES;
            break;
        }
    }
    if (shouldReload || self.isUpdated) {
        [self.tableView reloadData];
        self.isUpdated = NO;
    }
    
    if (self.isStale) {
        [self fetchUserProfile];
        self.isStale = NO;
    }
    
    self.isVisible = YES;
    
    self.dataSource.prefetchPaused = NO;
    
    [self.memoryGridCollectionView viewWillAppear];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateTableViewInsets];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Show bottom bar when popped
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        self.tabBarController.tabBar.hidden = !(self.navigationController.topViewController.isRootViewController || self.tabBarVisibleOnAppearance);
    }
    
    self.isVisible = NO;
    
    self.dataSource.prefetchPaused = YES;
    
    [self.memoryGridCollectionView viewWillDisappear];
}


-(void)applicationDidBecomeActive {
 
    if (self.userToken && self.isVisible && (!self.dataSource.hasLoadedProfile || !self.dataSource.hasLoaded)) {
        [self fetchUserProfile];
    }    
}


#pragma mark - Configuring the View’s Layout Behavior

- (UIStatusBarStyle)preferredStatusBarStyle {
    UIStatusBarStyle statusBarStyle = UIStatusBarStyleLightContent;
    
    if (self.navFromGrid) {
        statusBarStyle = [((UIViewController *)[self.navFromGrid.viewControllers firstObject]) preferredStatusBarStyle];
    } else if (0.5f <= self.customNavigationBar.alpha) {
        statusBarStyle = UIStatusBarStyleDefault;
    }
    // If our white navigation bar is at 50% or more alpha, then we want a default/dark status bar
    if (0.5f <= self.customNavigationBar.alpha) {
        statusBarStyle = UIStatusBarStyleDefault;
    }
    
    return statusBarStyle;
}

#pragma mark - Views

- (UIView *)customNavigationBarContainerView {
    if (!_customNavigationBarContainerView) {
        _customNavigationBarContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds) - 60, CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + CGRectGetHeight(self.navigationController.navigationBar.frame))];
        _customNavigationBarContainerView.backgroundColor = [UIColor clearColor];
        _customNavigationBarContainerView.layer.shadowColor = [UIColor colorWithRGBHex:0x011826].CGColor;
        _customNavigationBarContainerView.layer.shadowOpacity = 0.15f;
        _customNavigationBarContainerView.layer.shadowRadius = 2.0f / [UIScreen mainScreen].scale;
        _customNavigationBarContainerView.layer.shadowOffset = CGSizeMake(0, 1.0f / [UIScreen mainScreen].scale);
        _customNavigationBarContainerView.layer.shouldRasterize = YES;
        _customNavigationBarContainerView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return _customNavigationBarContainerView;
}

- (UIView *)customNavigationBar {
    if (!_customNavigationBar) {
        _customNavigationBar = [[UIView alloc] init];
        _customNavigationBar.backgroundColor = [UIColor clearColor];
        _customNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _customNavigationBar;
}

- (SPCProfileTitleView *)titleView {
    if (!_titleView) {
        _titleView = [[SPCProfileTitleView alloc] init];
        _titleView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _titleView;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        _actionButton = [[UIButton alloc] init];
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_actionButton setImage:[UIImage imageNamed:@"button-action-vertical-blue"] forState:UIControlStateNormal];
        _actionButton.contentEdgeInsets = UIEdgeInsetsMake(15, 0, 15, 0); // Give some tapping space
    }
    return _actionButton;
}

- (UIButton *)settingsButton {
    if (!_settingsButton) {
        _settingsButton = [[UIButton alloc] init];
        _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_settingsButton setImage:[UIImage imageNamed:@"button-settings-blue"] forState:UIControlStateNormal];
    }
    return _settingsButton;
}

- (UIButton *)backButton {
    if (!_backButton) {
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(-4, 19, 52, 46)];
        [_backButton setImage:[UIImage imageNamed:@"button-back-arrow-white"] forState:UIControlStateNormal];
        [_backButton setImageEdgeInsets:UIEdgeInsetsMake(11, 13, 11, 13)];
        [_backButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchDown];
    }
    return _backButton;
}

- (UIButton *)backButtonGray {
    if (!_backButtonGray) {
        _backButtonGray = [[UIButton alloc] initWithFrame:CGRectMake(-4, 19, 52, 46)];
        [_backButtonGray setImage:[UIImage imageNamed:@"button-back-arrow-blue"] forState:UIControlStateNormal];
        [_backButtonGray setImageEdgeInsets:UIEdgeInsetsMake(11, 13, 11, 13)];
        [_backButtonGray addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchDown];
    }
    return _backButtonGray;
}

- (SPCProfileHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[SPCProfileHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)/kTableHeaderViewAspectRatio)];
        _headerView.descriptionView.delegate = self;
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        _tableView.tag = kProfileTableViewTag;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor colorWithWhite:241.0/255.0 alpha:1.0];
    }
    return _tableView;
}

- (SPCMemoryGridCollectionView *)memoryGridCollectionView {
    if (nil == _memoryGridCollectionView) {
        SPCMemoryGridCollectionViewLayout *layout = [[SPCMemoryGridCollectionViewLayout alloc] init];
        _memoryGridCollectionView = [[SPCMemoryGridCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _memoryGridCollectionView.scrollEnabled = NO;
        _memoryGridCollectionView.backgroundColor = [UIColor clearColor];
        _memoryGridCollectionView.delegate = self;
        _memoryGridCollectionView.tableViewWidth = CGRectGetWidth(self.view.frame);
    }
    
    return _memoryGridCollectionView;
}

- (UIView *)profileActivityIndicatorView {
    if (!_profileActivityIndicatorView) {
        _profileActivityIndicatorView = [[UIView alloc] initWithFrame:self.view.bounds];
        _profileActivityIndicatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.color = [UIColor grayColor];
        indicatorView.center = _profileActivityIndicatorView.center;
        [indicatorView startAnimating];
        [_profileActivityIndicatorView addSubview:indicatorView];
    }
    return _profileActivityIndicatorView;
}

- (LargeBlockingProgressView *)bannerUpdateProgressView {
    if (!_bannerUpdateProgressView) {
        _bannerUpdateProgressView = [[LargeBlockingProgressView alloc] initWithFrame:self.navigationController.view.bounds];
        _bannerUpdateProgressView.label.text = NSLocalizedString(@"Saving ...", nil);
    }
    return _bannerUpdateProgressView;
}

- (SPCEarthquakeLoader *)uploadLoader {
    if (!_uploadLoader) {
        if (!self.tabBarController.tabBar.isHidden) { // We'll need to account for the tabbar
            _uploadLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.customNavigationBarContainerView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetHeight(self.customNavigationBarContainerView.frame) - CGRectGetHeight(self.tabBarController.tabBar.frame))];
        } else {
            _uploadLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.customNavigationBarContainerView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetHeight(self.customNavigationBarContainerView.frame))];
        }
        _uploadLoader.userInteractionEnabled = YES;
        _uploadLoader.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
        _uploadLoader.msgLabel.text = @"Uploading changes...";
    }
    return _uploadLoader;
}

- (SPCEarthquakeLoader *)memoriesLoader {
    if (!_memoriesLoader) {
        if (!self.tabBarController.tabBar.isHidden) { // We'll need to account for the tabbar
            _memoriesLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.customNavigationBarContainerView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetHeight(self.customNavigationBarContainerView.frame) - CGRectGetHeight(self.tabBarController.tabBar.frame))];
        } else {
            _memoriesLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.customNavigationBarContainerView.frame), self.view.frame.size.width, self.view.frame.size.height - CGRectGetHeight(self.customNavigationBarContainerView.frame))];
        }
        _memoriesLoader.userInteractionEnabled = YES;
        _memoriesLoader.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
        _memoriesLoader.msgLabel.text = @"Loading memories...";
    }
    return _memoriesLoader;
}

#pragma mark - Accessors

- (SPCProfileFeedDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [[SPCProfileFeedDataSource alloc] init];
        _dataSource.memoryGridCollectionView = self.memoryGridCollectionView;
        _dataSource.tableViewWidth = CGRectGetWidth(self.view.frame);
        _dataSource.delegate = self;
        _dataSource.isProfileData = YES;
    }
    return _dataSource;
}

- (UIView *)tableRecentMemFooterView {
    if (nil == _tableRecentMemFooterView && nil != self.recentFeedNextPageKey) {
        _tableRecentMemFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
        _tableRecentMemFooterView.backgroundColor = [UIColor clearColor];
        
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:_tableRecentMemFooterView.bounds];
        [spinner setColor:[UIColor darkGrayColor]];
        [_tableRecentMemFooterView addSubview:spinner];
        [spinner startAnimating];
    }
    
    return _tableRecentMemFooterView;
}

- (UIImageView *)expandingImageView {
    if (!_expandingImageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.hidden = YES;
        _expandingImageView = imageView;
    }
    return _expandingImageView;
}

- (UIView *)clippingView {
    if (!_clippingView) {
        _clippingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    }
    return _clippingView;
}

#pragma mark - Configuration

- (void)configureNavigationBar {
    if (!self.isRootViewController) {
        [self.view addSubview:self.backButton];
        [self.customNavigationBarContainerView addSubview:self.backButtonGray];
    }
}

- (void)enableBackButtonsWithTarget:(id)target andSelector:(SEL)selector {
    [self.view addSubview:self.backButton];
    [self.customNavigationBarContainerView addSubview:self.backButtonGray];
    
    [self.backButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.backButtonGray addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureActions {
    [self.settingsButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionButton addTarget:self action:@selector(showActions:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.profileButton addTarget:self action:@selector(showProfileImageFullscreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.bannerButton addTarget:self action:@selector(showBannerImageFullscreen:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.actionButton addTarget:self action:@selector(showActions:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerView.settingsButton addTarget:self action:@selector(showSettings:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureTableView {
    // Register cells
    [self.tableView registerClass:[SPCNewsLogCell class] forCellReuseIdentifier:SPCProfileNewsCellIdentifier];
    [self.tableView registerClass:[SPCProfileMutualFriendsCell class] forCellReuseIdentifier:SPCProfileMutualFriendsCellIdentifier];
    [self.tableView registerClass:[SPCProfileFriendActionCell class] forCellReuseIdentifier:SPCProfileFriendActionCellIdentifier];
    [self.tableView registerClass:[SPCRelationshipDetailCell class] forCellReuseIdentifier:SPCRelationshipDetailCellIdentifier];
    [self.tableView registerClass:[SPCProfileConnectionsCell class] forCellReuseIdentifier:SPCProfileConnectionsCellIdentifier];
    [self.tableView registerClass:[SPCProfileBioCell class] forCellReuseIdentifier:SPCProfileBioCellIdentifier];
    [self.tableView registerClass:[SPCProfileMapsCell class] forCellReuseIdentifier:SPCProfileMapsCellIdentifier];
    [self.tableView registerClass:[SPCProfileSegmentedControlCell class] forCellReuseIdentifier:SPCProfileSegmentedControlCellIdentifier];
    [self.tableView registerClass:[SPCProfilePlaceholderCell class] forCellReuseIdentifier:SPCProfilePlaceholderCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCFeedCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCLoadMoreDataCellIdentifier];
    
    // Add table header and footer
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:self.headerView.bounds];
    self.tableView.tableHeaderView.userInteractionEnabled = NO;
    
    // Add parallax header
    [self.tableView addParallaxViewWithImage:nil contentView:self.headerView bottomView:self.headerView.headerBackgroundView];
    [self.tableView updateOverlay];
    
    // Link data source
    self.tableView.dataSource = self.dataSource;
    self.tableView.delegate = self.dataSource;
    [self.tableView reloadData];
}

- (void)updateTableViewInsets {
    // Here, we want the our content/scroll to move behind a hidden tabBar
    if (nil != self.tabBarController.tabBar && (self.tabBarController.tabBar.hidden || 0.01f > self.tabBarController.tabBar.alpha)) {
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    } else {
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0)];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0)];
    }
}

- (void)removeTableFooterView {
    // Remove any/all footers from their superview
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.tableRecentMemFooterView removeFromSuperview];
        
        strongSelf.tableView.tableFooterView = nil;
    });
}

#pragma mark Private - Profile

- (void)reloadProfile {
    NSLog(@"reload profile!");
    // Provide presenting view controller for data source
    self.dataSource.navigationController = self.navigationController;
    
    // Fetch profile and banner image
    [self fetchBannerImage];
    [self fetchProfileImage];
    
    // Update labels - Navigation bar
    [self.titleView configureWithName:self.dataSource.profile.profileDetail.displayName
                               handle:self.dataSource.profile.profileDetail.handle
                              isCeleb:self.dataSource.profile.profileDetail.isCeleb
                      useLightContent:NO];
    
    [self reloadHeader];
    
    // Reload the table
    [self.tableView reloadData];
}

- (void)reloadAfterNotificationsAreProcessed {
    if (!self.haveAddedNewsLog && self.dataSource.mostRecentNotification) {
        //reload table view to display newslog cell not that notifications are in
        //to handle case where profile has loaded before notifications have processed
        self.haveAddedNewsLog = YES; //only need to reload once!
        [self.dataSource reloadData];
        [self.tableView reloadData];
    }
}

- (void)reloadHeader {
    // Update labels - Header
    [self.headerView configureWithName:self.dataSource.profile.profileDetail.displayName
                                handle:self.dataSource.profile.profileDetail.handle
                               isCeleb:self.dataSource.profile.profileDetail.isCeleb
                             starCount:self.dataSource.profile.profileDetail.starCount
                         followerCount:self.dataSource.profile.profileDetail.followersCount
                        followingCount:self.dataSource.profile.profileDetail.followingCount
                              isLocked:(self.dataSource.profile.profileDetail.profileLocked && !self.dataSource.profile.isCurrentUser && self.dataSource.profile.profileDetail.followingStatus != FollowingStatusFollowing)];
    
    // Update buttons
    self.headerView.settingsButton.hidden = !self.dataSource.profile.isCurrentUser;
    self.headerView.actionButton.hidden = self.dataSource.profile.isCurrentUser;
    
    // Change the banner image button's target, if this profile is the current user's
    if (self.dataSource.profile.isCurrentUser) {
        // Banner image
        [self.headerView.bannerButton removeTarget:self action:@selector(showBannerImageFullscreen:) forControlEvents:UIControlEventAllEvents];
        [self.headerView.bannerButton addTarget:self action:@selector(showEditBanner) forControlEvents:UIControlEventTouchUpInside];
        
        // Profile image
        [self.headerView.profileButton removeTarget:self action:@selector(showProfileImageFullscreen:) forControlEvents:UIControlEventAllEvents];
        [self.headerView.profileButton addTarget:self action:@selector(showEditProfileImage) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.dataSource.profile.profileUserId < 0) {
        self.headerView.actionButton.hidden = YES;
        self.actionButton.hidden = YES;
        self.settingsButton.hidden = YES;
    }
}

#pragma mark Private - Memories

- (void)spc_localMemoryAdded:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    
    if (!memory.isAnonMem) {
    
        if ([self.dataSource respondsToSelector:@selector(addMemory:)]) {
            [self.dataSource addMemory:memory];
            
            [self.tableView reloadData];
        } else {
            // Grab our current recent feed. Must not be nil, so that we can add an object to it.
            NSMutableArray *currentFeed = nil == self.dataSource.feed ? [NSMutableArray array] : [NSMutableArray arrayWithArray:self.dataSource.feed];
            
            // throw it on top!
            [currentFeed insertObject:memory atIndex:0];
            NSArray *finalFeed = [NSArray arrayWithArray:currentFeed];
            self.dataSource.feed = finalFeed;
            
            [self.tableView reloadData];
        }
    }
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    
    // Here, we must update all copies of the memory we have across the various arrays (five arrays - fullFeed, feed, popularFeed, recentFeed, sharedFeed)
    
    __block Memory *memoryToUpdate = nil;
    
    [self.dataSource.fullFeed enumerateObjectsUsingBlock:^(Memory *obj, NSUInteger idx, BOOL *stop) {
        if (obj.recordID == memory.recordID) {
            memoryToUpdate = obj;
            *stop = YES;
        }
    }];
    if (nil != memoryToUpdate) {
        [memoryToUpdate updateWithMemory:memory];
    }
    self.dataSource.fullFeed = self.dataSource.fullFeed;
    memoryToUpdate = nil;
    
    [self.dataSource.feed enumerateObjectsUsingBlock:^(Memory *obj, NSUInteger idx, BOOL *stop) {
        if (obj.recordID == memory.recordID) {
            memoryToUpdate = obj;
            *stop = YES;
        }
    }];
    if (nil != memoryToUpdate) {
        [memoryToUpdate updateWithMemory:memory];
    }
    self.dataSource.feed = self.dataSource.feed;
    memoryToUpdate = nil;
    
    [self.tableView reloadData];
}

- (void)spc_localMemoryDeleted:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    
    [self removeMemoryFromSource:memory];
    
    [self.tableView reloadData];
}

- (void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    if (personUpdate) {
        [self.dataSource updateWithPersonUpdate:personUpdate];
    }
}

#pragma mark - Actions

- (void)pop {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; // stop all videos when leaving profile
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Actions - Fetching data

- (void)fetchProfileImage {
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:self.dataSource.profile.profileDetail.imageAsset.imageUrlDefault size:ImageCacheSizeThumbnailLarge]];
    [self.headerView.profileImageView configureWithText:self.dataSource.profile.profileDetail.firstname.firstLetter.capitalizedString url:url];
}

- (void)fetchBannerImage {
    NSLog(@"fetch banner!");
    NSURL *assetURL = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:self.dataSource.profile.profileDetail.bannerAsset.imageUrlDefault size:ImageCacheSizeDefault]];
    self.fetchingBanner = YES;
    NSLog(@"assetURL %@",assetURL);
    [self.tableView.parallaxView.imageView sd_setImageWithURL:assetURL
                                             placeholderImage:[UIImage imageNamed:@"placeholder-stars"]
                                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                        NSLog(@"banner fetched!");
                                                        self.fetchingBanner = NO;
                                                        [self.tableView updateParallaxViewWithImage:image];
                                                        
                                                    }];
}

- (void)fetchUserProfile {
    self.fetchingProfile = YES;
    NSLog(@"fetching profile for %@",self.userToken);
    
    if (self.userToken) {
    
        [ProfileManager fetchProfileWithUserToken:self.userToken resultCallback:^(UserProfile *profile) {
            // Store profile reference
            self.dataSource.profile = profile;
            
            // Observe user profile updates
            if (self.dataSource.profile.isCurrentUser) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadProfile) name:ContactAndProfileManagerUserProfileDidUpdateNotification object:nil];
                
                if (!self.dataSource.mostRecentNotification) {
                    //if we don't have notifications in yet, so we add an observer to reload the profile when they are in
                    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAfterNotificationsAreProcessed) name:PNSManagerDidSortNotifications object:nil];
                }
            }
            
            // Update state
            self.fetchingProfile = NO;
            self.dataSource.hasLoadedProfile = YES;
            NSLog(@"profile fetcheD!");
            
            // Reload UI
            [self reloadProfile];
            
            self.dataSource.profileIdToIgnoreForAuthorTaps = self.dataSource.profile.profileDetail.profileId;
            self.dataSource.userTokenToIgnoreForAuthorTaps = self.dataSource.profile.userToken;
            
            // Display the PeopleEducation view after 1s of the profile being fetched and if the user is on their own profile and on the profile tab
            if (YES == self.dataSource.profile.isCurrentUser && YES == self.isRootViewController && NO == self.presentedEducationScreenInstance && NO == self.educationScreenWasShown) {
                [self presentEducationScreenAfterDelay:@(1.0f)];
            }
            
            // This profile's mems are visible to the current user if it is the current user,
            // their profile is not locked, we are following them, or we are an admin.
            BOOL memsVisibleToUser = profile.isCurrentUser || !profile.profileDetail.profileLocked || FollowingStatusFollowing == profile.profileDetail.followingStatus || [AuthenticationManager sharedInstance].currentUser.isAdmin;
            
            // Reset feed count
            self.feedCountBeforeLatestPagination = 0;
            if (YES == memsVisibleToUser) {
                // Fetch recent memories
                self.dataSource.hasLoaded = NO;
                
                __weak typeof(self)weakSelf = self;
                NSLog(@"fetch profile mems!");
                [MeetManager fetchUserMemoriesWithUserToken:self.userToken memorySortType:MemorySortTypeRecency count:20 pageKey:nil completionHandler:^(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories, NSString *nextPageKey) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    if (!strongSelf) {
                        return ;
                    }
                    NSLog(@"mems fetched!");
                    strongSelf.dataSource.feed = memories;
                    strongSelf.recentFeedNextPageKey = nextPageKey;
                    if (nil == nextPageKey) {
                        strongSelf.tableView.tableFooterView = nil;
                    } else {
                        strongSelf.tableView.tableFooterView = strongSelf.tableRecentMemFooterView;
                    }
                    
                    strongSelf.dataSource.hasLoaded = YES;
                    
                    [strongSelf.tableView reloadData];
                } errorHandler:^(NSError *error) {
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    if (!strongSelf) {
                        return ;
                    }
                    NSLog(@"error fetching profile mems %@", error);
                    strongSelf.dataSource.hasLoaded = YES;
                    
                    [strongSelf.tableView reloadData];
                }];
                
            } else {
                self.dataSource.feed = [NSArray array];
                self.dataSource.hasLoaded = YES;
                
                [self.tableView reloadData];
            }
        } faultCallback:^(NSError *fault) {
            self.fetchingProfile = NO;
        }];
        
    }
}

- (void)fetchNextRecentMemoriesPage {
    // This profile's mems are visible to the current user if it is the current user or this user is a follower
    BOOL memsVisibleToUser = self.dataSource.profile.isCurrentUser || !self.dataSource.profile.profileDetail.profileLocked || [AuthenticationManager sharedInstance].currentUser.isAdmin || self.dataSource.profile.profileDetail.followingStatus == FollowingStatusFollowing;
    
    if (YES == memsVisibleToUser && NO == self.isFetchingNextRecentMemoriesPage && nil != self.recentFeedNextPageKey && nil != self.dataSource.feed && kMaxNumberRecentMemories > [self.dataSource.feed count]) {
        self.fetchingNextRecentMemoriesPage = YES;
        
        __weak typeof(self)weakSelf = self;
        [MeetManager fetchUserMemoriesWithUserToken:self.userToken memorySortType:MemorySortTypeRecency count:20 pageKey:self.recentFeedNextPageKey completionHandler:^(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories, NSString *nextPageKey) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
            
            NSMutableArray *fullRecentMemories = [[NSMutableArray alloc] initWithArray:strongSelf.dataSource.feed];
            NSMutableSet *setMemoryRecordIDs = [[NSMutableSet alloc] init];
            for (Memory *memory in fullRecentMemories) {
                [setMemoryRecordIDs addObject:[NSNumber numberWithInteger:memory.recordID]];
            }
            
            // Let's add the new memories, but do not add duplicate memories
            NSUInteger numberOfAddedMemories = 0;
            for (Memory *memory in memories) {
                if (![setMemoryRecordIDs containsObject:[NSNumber numberWithInteger:memory.recordID]]) {
                    [setMemoryRecordIDs addObject:[NSNumber numberWithInteger:memory.recordID]];
                    ++numberOfAddedMemories;
                    [fullRecentMemories addObject:memory];
                }
            }
            
            NSMutableArray *newIndexPaths = [[NSMutableArray alloc] initWithCapacity:[memories count]];
            NSUInteger currentRecentFeedCount = [strongSelf.dataSource.feed count];
            
            for (NSUInteger u = currentRecentFeedCount; u < currentRecentFeedCount + numberOfAddedMemories; u++) {
                [newIndexPaths addObject:[NSIndexPath indexPathForRow:u inSection:1]];
            }
            
            strongSelf.dataSource.feed = fullRecentMemories;
            
            // This next conditional should be fixed server-side. Ensuring the nextPageKey is different than the current one before we set it
            if ([nextPageKey isEqualToString:strongSelf.recentFeedNextPageKey]) {
                strongSelf.recentFeedNextPageKey = nil;
            } else {
                strongSelf.recentFeedNextPageKey = nextPageKey;
            }
            
            if (nil == nextPageKey || kMaxNumberRecentMemories <= [fullRecentMemories count]) {
                strongSelf.tableRecentMemFooterView = nil;
                [strongSelf removeTableFooterView];
            }
            
            strongSelf.dataSource.hasLoaded = YES;
            
            NSArray *paths = [strongSelf.tableView indexPathsForVisibleRows];
            NSInteger currMaxVisibleRow = 0;
            
            for (int i =0; i < paths.count; i++) {
                NSIndexPath *indexPath = paths[i];
                if (indexPath.row > currMaxVisibleRow) {
                    currMaxVisibleRow = indexPath.row;
                }
            }
            
            //only attempt the insertion if the profile is being viewed
            if (!self.isVisible) {
                //DO NOTHING FOR NOW; no need to take a performance hit to update the ui until it is visible again
            }
            else {
                //if the profile is visible, only attempt the insertion if our last previous row is on screen already
                if (currentRecentFeedCount <= currMaxVisibleRow) {
                    [strongSelf.tableView beginUpdates];
                    [strongSelf.tableView insertRowsAtIndexPaths:newIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                    [strongSelf.tableView endUpdates];
                }
                else {
                    [strongSelf.tableView reloadData];
                }
            }
            
            strongSelf.fetchingNextRecentMemoriesPage = NO;
        } errorHandler:^(NSError *error) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return ;
            }
            strongSelf.dataSource.hasLoaded = YES;
            
            strongSelf.fetchingNextRecentMemoriesPage = NO;
        }];
    }
}

#pragma mark - Loader

- (void)showLoaderAnimationWithLoader:(SPCEarthquakeLoader *)loader {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __weak typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.view addSubview:loader];
        [loader startAnimating];
    });
}

- (void)hideLoaderAnimationWithLoader:(SPCEarthquakeLoader *)loader {
    dispatch_async(dispatch_get_main_queue(), ^{
        [loader removeFromSuperview];
        [loader stopAnimating];
    });
}

#pragma mark Actions - Navigation

- (void)showFriendNotification:(NSNotification *)note {
    Person *friend = (Person *)note.userInfo[@"selectedFriend"];
    if (friend) {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:friend.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}

- (void)handleProfileImageTap:(id)sender {
    int tag = (int)[sender tag];
    SpayceNotification * notification = [[PNSManager sharedInstance] getNotificationForId:tag];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:notification.user.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (void)showNewsNotification:(NSNotification *)note {
    // CT - Here you go
    SPCNotificationsViewController *notificationsViewController = [[SPCNotificationsViewController alloc] init];
    [self.navigationController pushViewController:notificationsViewController animated:YES];
}



- (void)showBioUpdateNotification:(NSNotification *)note {
    if ([self notificationIsRegardingDisplayedUser:note] && self.isVisible) {
        [self showEditBio];
    }
}

- (void)showCityNotification:(NSNotification *)note {
    [Flurry logEvent:@"PROFILE_TERRITORIES_TAPPED"];
    UIViewController *viewControllerToPush = nil;
    if (self.dataSource.profile.isCurrentUser || self.dataSource.profile.profileDetail.followingStatus == FollowingStatusFollowing) {
        viewControllerToPush = [[SPCProfileTerritoriesViewController alloc] initWithUserProfile:self.dataSource.profile];
    } else {
        viewControllerToPush = [[SPCTerritoriesListPlaceholderViewController alloc] initWithUserProfile:self.dataSource.profile];
    }
    [self.navigationController pushViewController:viewControllerToPush animated:YES];
}

- (void)showNeighborhoodNotification:(NSNotification *)note {
    [Flurry logEvent:@"PROFILE_TERRITORIES_TAPPED"];
    UIViewController *viewControllerToPush = nil;
    if (self.dataSource.profile.isCurrentUser || self.dataSource.profile.profileDetail.followingStatus == FollowingStatusFollowing) {
        viewControllerToPush = [[SPCProfileTerritoriesViewController alloc] initWithUserProfile:self.dataSource.profile];
    } else {
        viewControllerToPush = [[SPCTerritoriesListPlaceholderViewController alloc] initWithUserProfile:self.dataSource.profile];
    }
    [self.navigationController pushViewController:viewControllerToPush animated:YES];
}

- (void)addNewProfileCellNotification:(NSNotification *)note {
    [self.tableView reloadData];
}

- (void)didSelectFollowUserNotification:(NSNotification *)note {
    if ([self notificationIsRegardingDisplayedUser:note] && self.isVisible) {
        // Start following; don't bother with an alert warning the user.
        // Immediately change our local state to reflect the follow; we change if back if this fails.
        if (self.dataSource.profile.profileDetail.profileLocked) {
            self.dataSource.profile.profileDetail.followingStatus = FollowingStatusRequested;
        } else {
            self.dataSource.profile.profileDetail.followingStatus = FollowingStatusFollowing;
        }
        [self.tableView reloadData];
        
        __weak typeof(self) weakSelf = self;
        [MeetManager sendFollowRequestWithUserToken:self.dataSource.profile.userToken completionHandler:^(BOOL followingNow) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [Flurry logEvent:@"FOLLOW_REQ_IN_PROFILE"];
            if (followingNow && strongSelf.dataSource.profile.profileDetail.followingStatus != FollowingStatusFollowing) {
                strongSelf.dataSource.profile.profileDetail.followingStatus = FollowingStatusFollowing;
                [strongSelf.tableView reloadData];
            } else if (!followingNow && strongSelf.dataSource.profile.profileDetail.followingStatus != FollowingStatusRequested) {
                strongSelf.dataSource.profile.profileDetail.followingStatus = FollowingStatusRequested;
                [strongSelf.tableView reloadData];
            }
        } errorHandler:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [UIAlertView showError:error];
            strongSelf.dataSource.profile.profileDetail.followingStatus = FollowingStatusNotFollowing;
            [strongSelf.tableView reloadData];
        }];
    }
}

- (void)didSelectUnfollowUserNotification:(NSNotification *)note {
    if ([self notificationIsRegardingDisplayedUser:note] && self.isVisible) {
        SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
        alertViewController.modalPresentationStyle = UIModalPresentationCustom;
        alertViewController.transitioningDelegate = self;
        alertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ %@", nil), self.dataSource.profile.profileDetail.firstname, self.dataSource.profile.profileDetail.lastname];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Unfollow", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            
            // immediately set button status to NowFollowing; update it if needed on server response.
            self.dataSource.profile.profileDetail.followingStatus = FollowingStatusNotFollowing;
            [self.tableView reloadData];
            
            __weak typeof(self) weakSelf = self;
            [MeetManager unfollowWithUserToken:self.dataSource.profile.userToken completionHandler:^{
                [Flurry logEvent:@"UNFOLLOW_IN_PROFILE"];
                // nothing to do
            } errorHandler:^(NSError *error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                [UIAlertView showError:error];
                strongSelf.dataSource.profile.profileDetail.followingStatus = FollowingStatusFollowing;
                [strongSelf.tableView reloadData];
            }];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
        
        [self.navigationController presentViewController:alertViewController animated:YES completion:nil];
    }
}

- (void)didSelectAcceptFollowUserNotification:(NSNotification *)note {
    if ([self notificationIsRegardingDisplayedUser:note] && self.isVisible) {
        // Start following; don't bother with an alert warning the user.
        // Immediately change our local state to reflect the follow; we change if back if this fails.
        FollowingStatus followingStatusOriginal = self.dataSource.profile.profileDetail.followerStatus;
        self.dataSource.profile.profileDetail.followerStatus = FollowingStatusFollowing;
        [self.tableView reloadData];
        
        __weak typeof(self) weakSelf = self;
        [MeetManager acceptFollowRequestWithUserToken:self.dataSource.profile.userToken completionHandler:^{
            // Do nothing, the tableView is already loaded with this latest info
        } errorHandler:^(NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [UIAlertView showError:error];
            strongSelf.dataSource.profile.profileDetail.followingStatus = followingStatusOriginal;
            [strongSelf.tableView reloadData];
        }];
    }
}

- (void)didStarMemory:(NSNotification *)note {
    Memory *memory = note.object;
    if (self.dataSource.profile && [self.dataSource.profile.userToken isEqualToString:memory.author.userToken]) {
        self.dataSource.profile.profileDetail.starCount += 1;
        [self reloadHeader];
    }
}

- (void)didUnstarMemory:(NSNotification *)note {
    Memory *memory = note.object;
    if (self.dataSource.profile && [self.dataSource.profile.userToken isEqualToString:memory.author.userToken]) {
        self.dataSource.profile.profileDetail.starCount -= 1;
        [self reloadHeader];
    }
}

- (void)didStarComment:(NSNotification *)note {
    Comment *comment = note.object;
    if (self.dataSource.profile && [self.dataSource.profile.userToken isEqualToString:comment.userToken]) {
        self.dataSource.profile.profileDetail.starCount += 1;
        [self reloadHeader];
    }
}

- (void)didUnstarComment:(NSNotification *)note {
    Comment *comment = note.object;
    if (self.dataSource.profile && [self.dataSource.profile.userToken isEqualToString:comment.userToken]) {
        self.dataSource.profile.profileDetail.starCount -= 1;
        [self reloadHeader];
    }
}

- (void)didAddFriendNotification:(NSNotification *)note {
    if (self.dataSource.profile.isCurrentUser) {
        self.dataSource.profile.profileDetail.friendsCount += 1;
        [self reloadProfile];
    } else if ([self notificationIsRegardingDisplayedUser:note]) {
        if (self.isVisible) {
            // this change originated from this screen
            self.dataSource.profile.profileDetail.friendsCount += 1;
            [self reloadProfile];
        } else {
            self.isStale = YES;
        }
    }
}

- (void)didRequestFollowNotification:(NSNotification *)note {
    
    NSString *userToken = (NSString *)[note object];
    
    for (int i = 0; i < self.memoryGridCollectionView.memories.count; i++) {
        Memory *memory = self.memoryGridCollectionView.memories[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusRequested;
        }
    }
    
    for (int i = 0; i < self.dataSource.feed.count; i++) {
        Memory *memory = self.dataSource.feed[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusRequested;
        }
    }
    
    if (self.dataSource.profile.isCurrentUser) {
        // no effect
    } else if ([self notificationIsRegardingDisplayedUser:note]) {
        self.dataSource.profile.profileDetail.followingStatus = FollowingStatusRequested;
        
        if (self.isVisible) {
            // change originated here
        } else {
            [self.tableView reloadData];
        }
        [self reloadHeader];
    }
}

- (void)didFollowNotification:(NSNotification *)note {
    
    
    NSString *userToken = (NSString *)[note object];
    
    for (int i = 0; i < self.memoryGridCollectionView.memories.count; i++) {
        Memory *memory = self.memoryGridCollectionView.memories[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusFollowing;
        }
    }
    
    for (int i = 0; i < self.dataSource.feed.count; i++) {
        Memory *memory = self.dataSource.feed[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusFollowing;
        }
    }
    
    if (self.dataSource.profile.isCurrentUser) {
        self.dataSource.profile.profileDetail.followingCount += 1;
        [self reloadHeader];
    } else if ([self notificationIsRegardingDisplayedUser:note]) {
        self.dataSource.profile.profileDetail.followersCount += 1;
        self.dataSource.profile.profileDetail.followingStatus = FollowingStatusFollowing;
        
        if (self.isVisible) {
            // change originated here
        } else {
            [self.tableView reloadData];
        }
        [self reloadHeader];
    }
}

- (void)didUnfollowNotification:(NSNotification *)note {
    
    NSString *userToken = (NSString *)[note object];
    
    for (int i = 0; i < self.memoryGridCollectionView.memories.count; i++) {
        Memory *memory = self.memoryGridCollectionView.memories[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusNotFollowing;
        }
    }
    
    for (int i = 0; i < self.dataSource.feed.count; i++) {
        Memory *memory = self.dataSource.feed[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusNotFollowing;
        }
    }
    
    
    if (self.dataSource.profile.isCurrentUser) {
        self.dataSource.profile.profileDetail.followingCount -= 1;
        [self reloadHeader];
    } else if ([self notificationIsRegardingDisplayedUser:note]) {
        self.dataSource.profile.profileDetail.followersCount -= 1;
        self.dataSource.profile.profileDetail.followingStatus = FollowingStatusNotFollowing;
        
        if (self.isVisible) {
            // change originated here
        } else {
            [self.tableView reloadData];
        }
        [self reloadHeader];
    }
}


- (void)didAcceptFollowRequestNotification:(NSNotification *)note {
    if ([self notificationIsRegardingDisplayedUser:note]) {
        self.dataSource.profile.profileDetail.followerStatus = FollowingStatusFollowing;
        self.dataSource.profile.profileDetail.followingCount += 1;
        [self.tableView reloadData];
        [self reloadHeader];
    }
}

- (void)didRejectFollowRequestNotification:(NSNotification *)note {
    if ([self notificationIsRegardingDisplayedUser:note]) {
        self.dataSource.profile.profileDetail.followerStatus = FollowingStatusNotFollowing;
        [self.tableView reloadData];
    }
}


- (void)didAddBlockNotification:(NSNotification *)note {
    if (self.dataSource.profile.isCurrentUser || [self notificationIsRegardingDisplayedUser:note]) {
        if (!self.isVisible) {
            self.isStale = YES;
        }
    }
}


- (void)didRemoveFriendNotification:(NSNotification *)note {
    if (self.dataSource.profile.isCurrentUser) {
        self.dataSource.profile.profileDetail.friendsCount -= 1;
        [self reloadProfile];
    } else if ([self notificationIsRegardingDisplayedUser:note]) {
        if (self.isVisible) {
            // this change originated from this screen
            self.dataSource.profile.profileDetail.friendsCount -= 1;
            [self reloadProfile];
        } else {
            self.isStale = YES;
        }
    }
}

- (void)didRemoveBlockNotification:(NSNotification *)note {
    if (self.dataSource.profile.isCurrentUser || [self notificationIsRegardingDisplayedUser:note]) {
        if (!self.isVisible) {
            self.isStale = YES;
        }
    }
}

- (BOOL)notificationIsRegardingDisplayedUser:(NSNotification *)note {
    NSObject *obj = note.object;
    if ([obj isKindOfClass:[NSNumber class]]) {
        return self.dataSource.profile.profileUserId == [(NSNumber *)obj integerValue];
    } else if ([obj isKindOfClass:[NSString class]]) {
        return [self.dataSource.profile.userToken isEqualToString:((NSString *)obj)];
    } else if ([obj isKindOfClass:[Memory class]]) {
        return [self.dataSource.profile.userToken isEqualToString:((Memory *)obj).author.userToken];
    } else if ([obj isKindOfClass:[Comment class]]) {
        return [self.dataSource.profile.userToken isEqualToString:((Comment *)obj).userToken];
    } else if ([obj isKindOfClass:[SPCProfileFeedDataSource class]]) {
        return self.dataSource == obj;
    }
    
    return NO;
}

-(void)videoFailedToLoad {
    if (self.isVisible) {
        [self  spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.view title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
    }
}

- (void)showProfileImageFullscreen:(id)sender {
    SPCLightboxViewController *lightboxViewController = [[SPCLightboxViewController alloc] initWithURL:[NSURL URLWithString:self.dataSource.profile.profileDetail.imageAsset.imageUrlSquare]];
    [self.navigationController pushViewController:lightboxViewController animated:YES];
}

- (void)showBannerImageFullscreen:(id)sender {
    SPCLightboxViewController *lightboxViewController = [[SPCLightboxViewController alloc] initWithURL:[NSURL URLWithString:self.dataSource.profile.profileDetail.bannerAsset.imageUrlDefault]];
    [self.navigationController pushViewController:lightboxViewController animated:YES];
}

- (void)showActions:(id)sender {
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    alertViewController.alertTitle = self.dataSource.profile.profileDetail.displayName;
    
    // TODO: Implement when it's supported by the API
    /*
     [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Report", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
     SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
     subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
     subAlertViewController.transitioningDelegate = self;
     subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Report %@?", nil), self.dataSource.profile.profileDetail.displayName];
     
     [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Report", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
     
     }]];
     
     [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
     
     [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
     }]];
     */
    
    
    if ([AuthenticationManager sharedInstance].currentUser.isAdmin) {
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Admin Controls" style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            [self showAdminActions];
            
            
            
        }]];
        
        
    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Block", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
        SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
        subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
        subAlertViewController.transitioningDelegate = self;
        subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Block %@?", nil), self.dataSource.profile.profileDetail.displayName];
        
        [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Block", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            [MeetManager blockUserWithId:self.dataSource.profile.profileDetail.profileId resultCallback:^(NSDictionary *result) {
                [self fetchUserProfile];
                
            } faultCallback:^(NSError *fault) {
                [UIAlertView showError:fault];
            }];
        }]];
        
        [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
        
        [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
    }]];
    
    if (self.dataSource.profile.profileDetail.followingStatus == FollowingStatusFollowing) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Un-Follow", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Un-Follow %@?", nil), self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Un-Follow", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [MeetManager unfollowWithUserToken:self.dataSource.profile.userToken completionHandler:^{
                    [Flurry logEvent:@"UNFOLLOW_IN_PROFILE"];
                    [self fetchUserProfile];
                } errorHandler:^(NSError *fault) {
                    [UIAlertView showError:fault];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    [self.navigationController presentViewController:alertViewController animated:YES completion:nil];
}

- (void)showAdminActions {
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    alertViewController.alertTitle = NSLocalizedString(@"Admin Controls", nil);
    
    // WARN
    [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Warn" subtitle:@"Show a 'we're watching you' pop-up on login" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
        subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
        subAlertViewController.transitioningDelegate = self;
        subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Warn %@?", nil), self.dataSource.profile.profileDetail.displayName];
        
        [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Warn", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            // perform WARN admin action
            [[AdminManager sharedInstance] warnUserWithUserKey:self.dataSource.profile.userToken completionHandler:^() {
                [[[UIAlertView alloc] initWithTitle:@"Warned User" message:@"This user will see a pop-up on login informing them that memories or comments they've created have been flagged as inappropriate or abusive by the Spayce Authorities.  (only if they have updated their client since launch)" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }]];
        
        [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
        
        [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
    }]];
    
    // add MUTE / UNMUTE, BAN / UNBAN, DELETE actions.
    if (![self.dataSource.profile.profileDetail.adminActions containsObject:@"MUTE"] && ![self.dataSource.profile.profileDetail.adminActions containsObject:@"SHADOWMUTE"]) {
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Mute" subtitle:@"No grid placement or comments to strangers" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Mute %@?", nil), self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Mute", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform MUTE admin action
                [[AdminManager sharedInstance] muteUserWithUserKey:self.dataSource.profile.userToken shadow:NO completionHandler:^(AdminActionResult result) {
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Muted User" message:@"Success.  The user will not be featured on the homescreen grid, and will not be able to comment on memories by non-friends." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"MUTE"];
                            break;
                            
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Muted User" message:@"This 'mute' action has been queued and will be performed soon.  The user will not be featured on the homescreen grid, and will not be able to comment on memories by non-friends." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"MUTE"];
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Muted" message:@"This 'mute' action was already queued, and should be executed soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"MUTE"];
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Mute Pending" message:@"'Mute' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  This user will not be featured on the homescreen grid, and will not be able to comment on memories by non-friends." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"MUTE"];
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Shadow Mute", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform SHADOWMUTE admin action
                [[AdminManager sharedInstance] muteUserWithUserKey:self.dataSource.profile.userToken shadow:YES completionHandler:^(AdminActionResult result) {
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Shadow Muted User" message:@"Success.  The user will not be featured on the homescreen grid, and will not be able to comment on memories by non-friends.  However, their user experience should be identical to if these actions were allowed." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"SHADOWMUTE"];
                            break;
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Shadow Muted User" message:@"This 'shadow mute' action has been queued and will be performed soon.  The user will not be featured on the homescreen grid, and will not be able to comment on memories by non-friends.  However, their user experience should be identical to if these actions were allowed." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"SHADOWMUTE"];
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Shadow Muted" message:@"This 'shadow mute' action was already queued, and should be executed soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"SHADOWMUTE"];
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Shadow Mute Pending" message:@"'Shadow mute' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  This user will not be featured on the homescreen grid, and will not be able to comment on memories by non-friends.    However, their user experience should be identical to if these actions were allowed." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"SHADOWMUTE"];
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];

            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
            
        }]];
    } else {
        BOOL shadow = ![self.dataSource.profile.profileDetail.adminActions containsObject:@"MUTE"];
        NSString *actionName = shadow ? NSLocalizedString(@"Remove Shadow Mute", nil) : NSLocalizedString(@"Unmute", nil);
        [alertViewController addAction:[SPCAlertAction actionWithTitle:actionName subtitle:@"Allow grid placement, comments to strangers" style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:@"%@ %@?", actionName, self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:actionName style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform UNMUTE admin action
                [[AdminManager sharedInstance] unmuteUserWithUserKey:self.dataSource.profile.userToken completionHandler:^(AdminActionResult result) {
                    NSMutableArray *mut = [NSMutableArray arrayWithArray:self.dataSource.profile.profileDetail.adminActions];
                    [mut removeObject:@"MUTE"];
                    [mut removeObject:@"SHADOWMUTE"];
                    self.dataSource.profile.profileDetail.adminActions = [NSArray arrayWithArray:mut];
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Unmuted User" message:@"This user has been unmuted.  The user will be able post content to the home grid, and comment on stranger's memories." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Unmuted User" message:@"This user has been unmuted, or will be soon.  The user will be able post content to the home grid, and comment on stranger's memories." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Unmuted" message:@"This user was already being unmuted." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Unmuted Pending" message:@"'Unmute' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  The user will be able post content to the home grid, and comment on stranger's memories." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    }
    
    if (![self.dataSource.profile.profileDetail.adminActions containsObject:@"BAN"]) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Ban" subtitle:@"Prevent logins but keep old content" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Ban %@?", nil), self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Ban", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform BAN admin action
                [[AdminManager sharedInstance] banUserWithUserKey:self.dataSource.profile.userToken completionHandler:^(AdminActionResult result) {
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Banned User" message:@"Success.  The user will not be able to log in or create content, but old content will remain visible." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            break;
                            
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Banned User" message:@"This 'ban' action has been queued and will be performed soon.  The user will not be able to log in or create content, but old content will remain visible." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Banned" message:@"This 'ban' action was already queued, and should be executed soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Ban Pending" message:@"'Ban' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  This user will not be able to log in or create content, but old content will remain visible." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    } else {
        BOOL unbanAndUnblock = [self.dataSource.profile.profileDetail.adminActions containsObject:@"BLOCK"];
        NSString *actionName = NSLocalizedString(unbanAndUnblock ? @"Unban and Unblock Device" : @"Unban", nil);
        NSString *actionDescription = NSLocalizedString(unbanAndUnblock ? @"Allow logins by this user" : @"Allow logins and account creation", nil);
        [alertViewController addAction:[SPCAlertAction actionWithTitle:actionName subtitle:actionDescription style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ %@?", nil), actionName, self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:actionName style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform UNBAN admin action
                [[AdminManager sharedInstance] unbanUserWithUserKey:self.dataSource.profile.userToken completionHandler:^(AdminActionResult result) {
                    NSMutableArray *mut = [NSMutableArray arrayWithArray:self.dataSource.profile.profileDetail.adminActions];
                    [mut removeObject:@"BAN"];
                    if (unbanAndUnblock) {
                        [mut removeObject:@"BLOCK"];
                    }
                    self.dataSource.profile.profileDetail.adminActions = [NSArray arrayWithArray:mut];
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Unbanned User" message:@"Success.  The user will be able to access their account and post content again.  New account creation is allowed on their device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Unbanned User" message:@"This user has been unbanned, or will be soon.  The user will be able to access their account and post content again.  New account creation is allowed on their device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Unbanned" message:@"This user was already being unbanned." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Unban Pending" message:@"'Unban' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  The user will be able to access their account and post content again." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    }
    
    
    if (![self.dataSource.profile.profileDetail.adminActions containsObject:@"BLOCK"]) {
        BOOL banAndBlock = ![self.dataSource.profile.profileDetail.adminActions containsObject:@"BAN"];
        NSString *actionName = NSLocalizedString(banAndBlock ? @"Ban & Block Device" : @"Block Device", nil);
        NSString *actionDesc = NSLocalizedString(banAndBlock ? @"Ban, and no new accounts on device" : @"Prevent account creation on device", nil);
        [alertViewController addAction:[SPCAlertAction actionWithTitle:actionName subtitle:actionDesc style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ %@?", nil), actionName, self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:actionName style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform BAN admin action
                [[AdminManager sharedInstance] blockUserDeviceWithUserKey:self.dataSource.profile.userToken completionHandler:^(AdminActionResult result) {
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Blocked User" message:@"Success.  The user will not be able to log in or create content, but old content will remain visible.  Additionally, new accounts may not be created on this user's device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BLOCK"];
                            if (banAndBlock) {
                                self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            }
                            break;
                            
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Blocked User" message:@"This 'block device' action has been queued and will be performed soon.  The user will not be able to log in or create content, but old content will remain visible.  Additionally, new accounts may not be created on this user's device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BLOCK"];
                            if (banAndBlock) {
                                self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            }
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Blocked" message:@"This 'block device' action was already queued, and should be executed soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BLOCK"];
                            if (banAndBlock) {
                                self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            }
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Block Pending" message:@"'Block Device' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  This user will not be able to log in or create content, but old content will remain visible.  Additionally, new accounts may not be created on this user's device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BLOCK"];
                            if (banAndBlock) {
                                self.dataSource.profile.profileDetail.adminActions = [self.dataSource.profile.profileDetail.adminActions arrayByAddingObject:@"BAN"];
                            }
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    } else {
        NSString *actionName = NSLocalizedString(@"Unblock Device", nil);
        NSString *actionDescription = NSLocalizedString(@"Allow account creation on device", nil);
        [alertViewController addAction:[SPCAlertAction actionWithTitle:actionName subtitle:actionDescription style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ %@?", nil), actionName, self.dataSource.profile.profileDetail.displayName];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:actionName style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                // perform UNBAN admin action
                [[AdminManager sharedInstance] unblockUserDeviceWithUserKey:self.dataSource.profile.userToken completionHandler:^(AdminActionResult result) {
                    NSMutableArray *mut = [NSMutableArray arrayWithArray:self.dataSource.profile.profileDetail.adminActions];
                    [mut removeObject:@"BLOCK"];
                    self.dataSource.profile.profileDetail.adminActions = [NSArray arrayWithArray:mut];
                    switch(result) {
                        case AdminActionResultSuccess:
                            [[[UIAlertView alloc] initWithTitle:@"Unblocked User" message:@"This user's device has been unblocked; new account creation is possible." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultQueued:
                            [[[UIAlertView alloc] initWithTitle:@"Unblocked User" message:@"This user's device has been unblocked; new account creation is possible." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultRedundant:
                            [[[UIAlertView alloc] initWithTitle:@"Already Unblocked" message:@"This user was already being unblocked." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                            
                        case AdminActionResultNotImplemented:
                            [[[UIAlertView alloc] initWithTitle:@"Unblock Pending" message:@"'Unblock' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  New account creation will be re-enabled on this user's device." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                            break;
                    }
                    
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
    }
    
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Delete" subtitle:@"Permanantly delete user and their content" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
        subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
        subAlertViewController.transitioningDelegate = self;
        subAlertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"Delete %@?", nil), self.dataSource.profile.profileDetail.displayName];
        
        [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
            // perform DELETE admin action
            [[AdminManager sharedInstance] deleteUserWithUserKey:self.dataSource.profile.userToken completionHandler:^(AdminActionResult result) {
                switch(result) {
                    case AdminActionResultSuccess:
                        [[[UIAlertView alloc] initWithTitle:@"Deleted User" message:@"Success.  The user's profile, along with all memories and comments, have been be removed, or will be shortly." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                        break;
                        
                    case AdminActionResultQueued:
                        [[[UIAlertView alloc] initWithTitle:@"Deleted User" message:@"This 'delete' action has been queued and will be performed soon.  The user's profile, along with all memories and comments, will be removed." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                        break;
                        
                    case AdminActionResultRedundant:
                        [[[UIAlertView alloc] initWithTitle:@"Already Deleted" message:@"This 'delete' action was already queued, and should be executed soon." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                        break;
                        
                    case AdminActionResultNotImplemented:
                        [[[UIAlertView alloc] initWithTitle:@"Delete Pending" message:@"'Delete' actions are not yet implemented on the server.  However, this action has been queued and will be executed once this function is enabled.  This user's profile, along with all memories and comments, will be removed." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                        break;
                }
                
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }]];
        
        [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
        
        [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
    }]];
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    [self.navigationController presentViewController:alertViewController animated:YES completion:nil];

}

- (void)showSettings:(id)sender {
    SPCSettingsTableViewController *settingsViewController = [[SPCSettingsTableViewController alloc] init];
    settingsViewController.profile = self.dataSource.profile;
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:settingsViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    [self.navigationController presentViewController:navController animated:YES completion:^{}];
}

- (void)tabBarSelectedItemChanged:(NSNotification *)notification {
    if (nil != notification.object) {
        UITabBar *bar = (UITabBar *)notification.object[@"bar"];
        NSDictionary *change = (NSDictionary *)notification.object[@"change"];
        UITabBarItem *wasItem = [change objectForKey:NSKeyValueChangeOldKey];
        UITabBarItem *isItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        NSUInteger wasIndex = [bar.items indexOfObject:wasItem];
        NSUInteger isIndex = [bar.items indexOfObject:isItem];
        
        // If the index has changed, and the user was previously on the profile tab
        if (wasIndex != isIndex && TAB_BAR_PROFILE_ITEM_INDEX == wasIndex) {
            // Check if the navigation controller is showing the notifications view controller, i.e. The News Log
            UIViewController *topViewController = [self.navigationController topViewController];
            if ([topViewController isKindOfClass:[SPCNotificationsViewController class]]) {
                // We are showing the news log, so pop the news log VC and scroll to the top of the table
                __weak typeof(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf)strongSelf = weakSelf;
                    [strongSelf.navigationController popToViewController:strongSelf animated:NO];
                    [strongSelf.tableView scrollRectToVisible:CGRectMake(0, 0, strongSelf.view.bounds.size.width, 1) animated:NO];
                });
                
                //we left news log by tapping on another tab - mark all notifications as read
                [[NSNotificationCenter defaultCenter] postNotificationName:@"markNewsLogReadOnDelay" object:nil];
            }
        }
    }
}

#pragma mark Actions - Editing

// Private enum used for profile/banner editing state
typedef enum ProfileImageEditingState
{
    ProfileImageEditingStateUnknown = 0,
    ProfileImageEditingStateBanner = 1,
    ProfileImageEditingStateProfileImage = 2,
} ProfileImageEditingState;

- (void)showEditBio {
    [Flurry logEvent:@"PROFILE_EDIT_BIO_TAPPED"];
    SPCEditBioViewController *bioEditViewController = [[SPCEditBioViewController alloc] init];
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:bioEditViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    [self.navigationController presentViewController:navController animated:YES completion:^{}];
}

- (void)showEditBanner {
    SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
    subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
    subAlertViewController.transitioningDelegate = self;
    subAlertViewController.alertTitle = NSLocalizedString(@"Update Banner", nil);
    
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"View Banner", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        [self showBannerImageFullscreen:self.headerView.bannerButton];
    }]];
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        self.imagePicker = [[GKImagePicker alloc] initWithType:1];
        CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension * 3.0/4.0);
        self.imagePicker.delegate = (id)self;
        self.imagePicker.showCircleMask = NO;
        self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.imagePickerController.view.tag = 0;
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            self.imagePicker.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
    }]];
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        self.imagePicker = [[GKImagePicker alloc] initWithType:0];
        CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension * 3.0/4.0);
        self.imagePicker.showCircleMask = NO;
        self.imagePicker.delegate = (id)self;
        self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePicker.imagePickerController.view.tag = 1;
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
    }]];
    
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    self.profileImageEditingState = ProfileImageEditingStateBanner;
    
    [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
}

- (void)showEditProfileImage {
    SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
    subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
    subAlertViewController.transitioningDelegate = self;
    subAlertViewController.alertTitle = NSLocalizedString(@"Update Profile Picture", nil);
    
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"View Profile Picture", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        [self showProfileImageFullscreen:self.headerView.profileButton];
    }]];
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        self.imagePicker = [[GKImagePicker alloc] initWithType:1];
        CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension);
        self.imagePicker.delegate = (id)self;
        self.imagePicker.showCircleMask = NO;
        self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.imagePickerController.view.tag = 0;
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
            self.imagePicker.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
    }]];
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing", nil) style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
        self.imagePicker = [[GKImagePicker alloc] initWithType:0];
        CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension);
        self.imagePicker.showCircleMask = NO;
        self.imagePicker.delegate = (id)self;
        self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePicker.imagePickerController.view.tag = 1;
        [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
    }]];
    
    [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    self.profileImageEditingState = ProfileImageEditingStateProfileImage;
    
    [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([collectionView isEqual:self.memoryGridCollectionView]&& indexPath.row < self.memoryGridCollectionView.memories.count) {
        Memory *m = [self.memoryGridCollectionView.memories objectAtIndex:indexPath.row];
        
        if (nil != m) {
            UIImage *image = nil;
            if (MemoryTypeImage == m.type || MemoryTypeVideo == m.type) {
                UICollectionViewCell *cellTapped = [collectionView cellForItemAtIndexPath:indexPath];
                UIGraphicsBeginImageContextWithOptions(cellTapped.contentView.bounds.size, cellTapped.contentView.opaque, 0.0f);
                [cellTapped.contentView.layer renderInContext:UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            
            // clip rect?
            CGRect maskRect = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
            
            // Create a mask layer
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            
            // Create a path with our clip rect in it
            CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
            maskLayer.path = path;
            
            // The path is not covered by ARC
            CGPathRelease(path);
            
            self.clippingView.layer.mask = maskLayer;
            
            BOOL hasImage = image != nil;
            
            UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
            CGRect cellRect = attributes.frame;
            CGRect cellFrameInTableView = [collectionView convertRect:cellRect toView:self.tableView];
            CGRect rect = [self.tableView convertRect:cellFrameInTableView toView:self.view];
            
            self.expandingImageView.image = image;
            self.expandingImageView.frame = rect;
            
            self.expandingImageView.hidden = !hasImage;
            
            self.expandingImageRect = rect;
            
            // Create the mcvc
            MemoryCommentsViewController *mcvc = [[MemoryCommentsViewController alloc] initWithMemory:m];
            mcvc.viewingFromGrid = YES;
            mcvc.gridCellImage = image;
            mcvc.animateTransition = NO;
            
            self.navFromGrid = [[SPCCustomNavigationController alloc] initWithRootViewController:mcvc];
            
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
            }];
            [UIView animateWithDuration:travelTime delay:0.12 options:0 animations:^{
                self.navFromGrid.view.alpha = 1.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    // Our hack to make the back button usable on the MCVC
                    [mcvc.backButton addTarget:self action:@selector(returnToGridFromNav) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self setNeedsStatusBarAppearanceUpdate];
                    
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
            if (self.expandingDidHideTabBar) {
                [self.tabBarController slideTabBarHidden:NO animated:YES];
            }
            
            [self setNeedsStatusBarAppearanceUpdate];
        }];
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

#pragma mark - SPCDataSourceDelegate

- (void)showChat {
    [Flurry logEvent:@"CHAT_TAPPED_IN_PROFILE"];
    Person *tempPerson  = [[Person alloc] init];
    tempPerson.userToken = self.dataSource.profile.userToken;
    tempPerson.firstname = self.dataSource.profile.profileDetail.firstname;
    tempPerson.lastname = self.dataSource.profile.profileDetail.lastname;
    tempPerson.handle = self.dataSource.profile.profileDetail.handle;
    tempPerson.recordID = self.dataSource.profile.profileUserId;
    tempPerson.imageAsset = self.dataSource.profile.profileDetail.imageAsset;
    
    SPCMessagesViewController *messagesVC = [[SPCMessagesViewController alloc] init];
    [messagesVC performSelector:@selector(configureWithPerson:) withObject:tempPerson afterDelay:.2];
    [self.navigationController pushViewController:messagesVC animated:YES];
}

#pragma mark - SPCProfileDescriptionViewDelegate

- (void)tappedDescriptionType:(SPCProfileDescriptionType)descriptionType onDescriptionView:(SPCProfileDescriptionView *)descriptionView {
    if (SPCProfileDescriptionTypeStars == descriptionType) {
        //SPCProfileStarPowerViewController *vc = [[SPCProfileStarPowerViewController alloc] initWithUserProfile:self.dataSource.profile];
        //[self.navigationController pushViewController:vc animated:YES];
    } else if (SPCProfileDescriptionTypeFollowing == descriptionType || SPCProfileDescriptionTypeFollowers == descriptionType) {
        BOOL isCurrentUser = self.dataSource.profile.isCurrentUser;
        BOOL isFollowingUser = self.dataSource.profile.profileDetail.followingStatus == FollowingStatusFollowing;
        BOOL isPrivate = self.dataSource.profile.profileDetail.profileLocked;
        
        SPCFollowListType followListType;
        if (SPCProfileDescriptionTypeFollowing == descriptionType) {
            [Flurry logEvent:@"PROFILE_FOLLOWING_BTN_TAPPED"];
            followListType = isCurrentUser ? SPCFollowListTypeMyFollows : SPCFollowListTypeUserFollows;
        } else {
            [Flurry logEvent:@"PROFILE_FOLLOWERS_BTN_TAPPED"];
            followListType = isCurrentUser ? SPCFollowListTypeMyFollowers : SPCFollowListTypeUserFollowers;
        }
        
        if (!isCurrentUser && isPrivate && !isFollowingUser) {
            SPCFollowListPlaceholderViewController *vc = [[SPCFollowListPlaceholderViewController alloc] initWithFollowListType:followListType userProfile:self.dataSource.profile];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            SPCProfileFollowListViewController *vc = [[SPCProfileFollowListViewController alloc] initWithFollowListType:followListType userToken:self.dataSource.profile.userToken];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

#pragma mark - GKImagePickerDelegate

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image{
    // Note the editing state we are currently in, in the off-chance the user makes another request before we finish this one
    ProfileImageEditingState operationEditingState = self.profileImageEditingState; // Editing state for this upload operation
    
    // Dismiss the picker
    [imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:^{
        // Display an 'uploading' loader
        [self showLoaderAnimationWithLoader:self.uploadLoader];
        
        // We want the smallest dimension of the image to be scaled to the server's square dimension
        // Now, scale the image - first get the image's smallest dimension, and the constant necessary to scale it to the server's square dimension
        CGFloat scalingConstant = ((CGFloat) ImageCacheSizeSquare) / MIN(image.size.height, image.size.width);
        CGSize newSize = CGSizeMake(floor(scalingConstant * image.size.width), floor(scalingConstant * image.size.height)); // Using floor ensures we don't see a white line on the right side of the image when displaying it in our parallax view (for banner images, that is. for profile images, our dimensions should be integral anyway).
        UIImage *rescaledImage = [ImageUtils rescaleImage:image toSize:newSize];
        
        __weak typeof(self) weakSelf = self;
        if (ProfileImageEditingStateBanner == operationEditingState) {
            [[ContactAndProfileManager sharedInstance] updateProfileBanner:weakSelf.dataSource.profile
                                                               bannerImage:rescaledImage
                                                            resultCallback:^(NSInteger bannerAssetId) {
                                                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                strongSelf.dataSource.profile.profileDetail.bannerAsset = [Asset assetWithId:bannerAssetId];
                                                                
                                                                [strongSelf reloadProfile];
                                                                
                                                                [strongSelf hideLoaderAnimationWithLoader:strongSelf.uploadLoader];
                                                            } faultCallback:^(NSError *fault) {
                                                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                
                                                                [strongSelf displayUploadErrorForEditState:operationEditingState];
                                                                
                                                                [strongSelf hideLoaderAnimationWithLoader:strongSelf.uploadLoader];
                                                            }];
        } else if (ProfileImageEditingStateProfileImage == operationEditingState) {
            [[ContactAndProfileManager sharedInstance] updateProfile:weakSelf.dataSource.profile profileImage:rescaledImage resultCallback:^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                [strongSelf reloadProfile];
                
                [strongSelf hideLoaderAnimationWithLoader:strongSelf.uploadLoader];
            } faultCallback:^(NSError *fault) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                [strongSelf displayUploadErrorForEditState:operationEditingState];
                
                [strongSelf hideLoaderAnimationWithLoader:strongSelf.uploadLoader];
            }];
        } else {
            [self hideLoaderAnimationWithLoader:self.uploadLoader];
        }
    }];
}

// Displaying errors when the banner/profile image upload fails
- (void)displayUploadErrorForEditState:(ProfileImageEditingState)profileImageEditingState {
    
    NSString *editingStateString = nil;
    if (ProfileImageEditingStateBanner == profileImageEditingState) {
        editingStateString = @"banner image";
    } else if (ProfileImageEditingStateProfileImage == profileImageEditingState) {
        editingStateString = @"profile image";
    }
    NSString *errorMessage = [NSString stringWithFormat:@"We were unable to update your %@. Please try again in a few minutes.", editingStateString];
    
    [[[UIAlertView alloc] initWithTitle:@"Upload Error" message:errorMessage delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
}

- (void)updateCellToPrivate:(NSIndexPath *)indexPath {
    MemoryCell *cell = (MemoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateToPrivate];
}

- (void)updateCellToPublic:(NSIndexPath *)indexPath {
    MemoryCell *cell = (MemoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateToPublic];
}

#pragma mark - SPCProfileSegmentedControlCellDelegate

- (void)tappedMemoryCellDisplayType:(MemoryCellDisplayType)type onProfileSegmentedControl:(SPCProfileSegmentedControlCell *)profileSegmentedControl {
    
    // Reload 1st section if it's available
    if (1 <= self.tableView.numberOfSections) {
        self.dataSource.memoryCellDisplayType = profileSegmentedControl.memoryCellDisplayType;
        
        [self showLoaderAnimationWithLoader:self.memoriesLoader];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self hideLoaderAnimationWithLoader:self.memoriesLoader];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Fades in bottom cell in table view as it enter the screen for first time
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells != nil  &&  [visibleCells count] != 0) {       // Don't do anything for empty table view
        
        /* Get bottom cell */
        UITableViewCell *bottomCell = [visibleCells lastObject];
        
        /* Make sure other cells stay opaque */
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.alpha = 1.0;
        }
        
        // Piggyback on bottomCell call and use for prefetching !
        int prefetchIndex = 1 + (int)bottomCell.tag;
        if (self.dataSource.currentPrefetchIndex != prefetchIndex) {
            if (prefetchIndex < self.dataSource.feed.count) {
                Memory *tempMem = self.dataSource.feed[prefetchIndex];
                if (![self.dataSource.prefetchedList containsObject:@(tempMem.recordID)]) {
                    self.dataSource.currentPrefetchIndex = prefetchIndex;
                    [self.dataSource updatePrefetchQueueWithMemAtIndex];
                }
            }
        }
        
        /* Set necessary constants */
        CGFloat height = 100;
        
        NSInteger tableViewBottomPosition = self.tableView.frame.origin.y + self.tableView.frame.size.height;
        NSIndexPath *bottomIndexPath = [NSIndexPath indexPathForRow:bottomCell.tag inSection:0];
        //Memory *bottomCellMem = [self memoryForRowAtIndexPath:bottomIndexPath];
        if (bottomIndexPath.row < self.dataSource.feed.count) {
            Memory *bottomCellMem = (Memory *)self.dataSource.feed[bottomIndexPath.row];
            CGSize constraint = CGSizeMake(290, 20000);
            height = MIN(scrollView.frame.size.height, [MemoryCell measureHeightWithMemory:bottomCellMem constrainedToSize:constraint]);
            
        }
        NSInteger cellHeight = height;
        
        /* Get content offset to set opacity */
        CGRect bottomCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:bottomCell]];
        CGFloat bottomCellPosition = ([self.tableView convertRect:bottomCellPositionInTableView toView:[self.tableView superview]].origin.y + cellHeight);
        
        /* Set opacity based on amount of cell that is outside of view */
        CGFloat modifier = 1.4;     /* Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen,
                                     2.0 for fully transparent when the cell is half off the screen, etc) */
        CGFloat bottomCellOpacity = (1.0f - ((bottomCellPosition - tableViewBottomPosition) / cellHeight) * modifier);
        
        /* Set cell opacity */
        if (bottomCell) {
            if (bottomCell.tag > self.maxIndexViewed) {
                bottomCell.alpha = bottomCellOpacity;
                if (bottomCellOpacity > .99) {
                    self.maxIndexViewed = bottomCell.tag;
                }
            }
        }
        
        // Paginate when scrolling down far enough
        const CGFloat bottomOffsetToStartPagination = (self.tableView.contentSize.height - 1.5 * self.view.frame.size.height - self.tableView.tableFooterView.bounds.size.height);
        
        if (bottomOffsetToStartPagination < self.tableView.contentOffset.y && self.feedCountBeforeLatestPagination < self.dataSource.feed.count) {
            self.feedCountBeforeLatestPagination = self.dataSource.feed.count;
            [self fetchNextRecentMemoriesPage];
        }
    }
    
    [self updateTitleViewWithOffset:scrollView.contentOffset];
    [self updateNavigationBarWithOffset:scrollView.contentOffset];
}

- (void)updateMaxIndexViewed:(NSInteger)maxIndexViewed {
    if (maxIndexViewed > self.maxIndexViewed) {
        self.maxIndexViewed = maxIndexViewed;
    }
}

- (void)updateTitleViewWithOffset:(CGPoint)offset {
    CGFloat ratio;
    CGFloat minOffsetY = kHeaderTitleViewMinOpacityOffsetY;
    CGFloat maxOffsetY = kHeaderTitleViewMaxOpacityOffsetY;
    
    if (offset.y < minOffsetY) {
        ratio = 0.0f;
    }
    else if (offset.y >= maxOffsetY) {
        ratio = 1.0f;
    }
    else {
        CGFloat diff = offset.y - minOffsetY;
        ratio = diff / (maxOffsetY - minOffsetY);
    }
    
    // Update UI appearance
    self.headerView.titleView.alpha = 1 - ratio;
    self.headerView.settingsButton.alpha = 1 - ratio;
}

- (void)updateNavigationBarWithOffset:(CGPoint)offset {
    CGFloat ratio;
    CGFloat minOffsetY = kNavigationBarMinOpacityOffsetY;
    CGFloat maxOffsetY = kNavigationBarMaxOpacityOffsetY;
    
    if (offset.y < minOffsetY) {
        ratio = 0.0f;
    }
    else if (offset.y >= maxOffsetY) {
        ratio = 1.0f;
    }
    else {
        CGFloat diff = offset.y - minOffsetY;
        ratio = diff / (maxOffsetY - minOffsetY);
    }
    
    // Update UI appearance
    CGRect frame = self.customNavigationBarContainerView.frame;
    frame.size.width = ratio > 0 ? CGRectGetWidth(self.view.bounds) : CGRectGetWidth(self.view.bounds) - 60;
    self.customNavigationBarContainerView.frame = frame;
    self.customNavigationBar.alpha = ratio;
    self.customNavigationBar.alpha = ratio;
    self.titleView.alpha = ratio;
    self.backButton.alpha = 1.0f - ratio;
    if (self.dataSource.profile.profileUserId >= 0) {
        if (self.dataSource.profile.isCurrentUser) {
            self.settingsButton.hidden = ratio < 0.3;
        } else {
            self.actionButton.hidden = ratio < 0.3;
        }
        if (!self.dataSource.profile.isCurrentUser) {
            self.headerView.actionButton.hidden = !self.actionButton.hidden;
        }
    }
    
    // Update status bar appearance
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self) {
        if ([keyPath isEqualToString:@"updatingBanner"]) {
            BOOL isUpdatingBanner = [[object valueForKeyPath:keyPath] boolValue];
            if (isUpdatingBanner) {
                [self.bannerUpdateProgressView.activityIndicator startAnimating];
                [self.navigationController.view addSubview:self.bannerUpdateProgressView];
            }
            else {
                [self.bannerUpdateProgressView.activityIndicator stopAnimating];
                [self.bannerUpdateProgressView removeFromSuperview];
            }
        }
        else if ([keyPath isEqualToString:@"fetchingProfile"]) {
            BOOL isFetchingProfile = [[object valueForKeyPath:keyPath] boolValue];
            BOOL isFetchingBanner = self.isFetchingBanner;
            if (!isFetchingProfile && !isFetchingBanner) {
                if (self.profileActivityIndicatorView.superview) {
                    NSLog(@"profile fetched, remove profile activity indicator view");
                    [self.profileActivityIndicatorView removeFromSuperview];
                }
            }
        }
        else if ([keyPath isEqualToString:@"fetchingBanner"]) {
            BOOL isFetchingProfile = self.isFetchingProfile;
            BOOL isFetchingBanner = [[object valueForKeyPath:keyPath] boolValue];
            if (!isFetchingProfile && !isFetchingBanner) {
                if (self.profileActivityIndicatorView.superview) {
                    NSLog(@"banner fetched, remove profile activity indicator view");
                    [self.profileActivityIndicatorView removeFromSuperview];
                }
            }
        }
    }
    else if (object == self.dataSource) {
        if ([keyPath isEqualToString:@"draggingScrollView"]) {
            BOOL isScrolling = [[object valueForKeyPath:keyPath] boolValue];
            
            // Fade in/out navigation bar
            [UIView animateWithDuration:0.35 animations:^{
                self.customNavigationBar.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:isScrolling ? 0.9 : 1.0];
            }];
        }
    }
}

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    return animator;
}

#pragma mark - Education Screen

- (void)presentEducationScreenAfterDelay:(NSNumber *)delayInSeconds {
    
    if (self.isVisible) {
        
        __weak typeof(self) weakSelf = self;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delayInSeconds floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf.isVisible && !strongSelf.presentedEducationScreenInstance) {
                
                strongSelf.presentedEducationScreenInstance = YES;
                
                UIImage *imageBlurred = [UIImageEffects takeSnapshotOfView:strongSelf.view];
                imageBlurred = [UIImageEffects imageByApplyingBlurToImage:imageBlurred withRadius:5.0 tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:2.0 maskImage:nil];
                strongSelf.viewBlurredScreen = [[UIImageView alloc] initWithImage:imageBlurred];
                
                
                CGRect frameToPresent = CGRectMake(10, 50, CGRectGetWidth(strongSelf.view.bounds) - 20, CGRectGetHeight(strongSelf.view.frame) - 100 - (self.tabBarController.tabBar.alpha * CGRectGetHeight(self.tabBarController.tabBar.frame))); // account for whether or not the tabBar is visible
                strongSelf.viewEducationScreen = [[SPCPeopleEducationView alloc] initWithFrame:frameToPresent];
                [strongSelf.viewEducationScreen.btnFinished addTarget:strongSelf action:@selector(dismissEducationScreen:) forControlEvents:UIControlEventTouchUpInside];
                
                [UIView transitionWithView:strongSelf.view
                                  duration:0.6f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^{
                                    [strongSelf.view addSubview:strongSelf.viewBlurredScreen];
                                    [strongSelf.view addSubview:strongSelf.viewEducationScreen];
                                }
                                completion:nil];
            }
        });
    }
}

- (void)dismissEducationScreen:(id)sender {
    NSLog(@"dimiss education???");
    [UIView transitionWithView:self.view
                      duration:0.2f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^ {
                        [self.viewEducationScreen removeFromSuperview];
                        [self.viewBlurredScreen removeFromSuperview];
                    }
                    completion:^(BOOL completed) {
                        self.viewEducationScreen = nil;
                        self.viewBlurredScreen = nil;
                    }];
    
    // Set shown on dismissal
    [self setEducationScreenWasShown:YES];
}

- (void)setEducationScreenWasShown:(BOOL)educationScreenWasShown {
    NSString *strEducationStringUserLiteralKey = [SPCLiterals literal:kSPCPeopleEducationScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setBool:educationScreenWasShown forKey:strEducationStringUserLiteralKey];
}

- (BOOL)educationScreenWasShown {
    BOOL wasShown = NO;
    
    NSString *strEducationStringUserLiteralKey = [SPCLiterals literal:kSPCPeopleEducationScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strEducationStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strEducationStringUserLiteralKey];
    }
    
    return wasShown;
}

#pragma mark - Helpers

- (void)removeMemoryFromSource:(Memory *)memory {
    // Remove memory from our dataSource's arrays
    // Must not set a currently-nil array to a non-nil value
    
    if ([self.dataSource respondsToSelector:@selector(removeMemory:)]) {
        [self.dataSource removeMemory:memory];
    } else {
        __block Memory *memoryToDelete = nil;
        
        if (nil != self.dataSource.feed) {
            NSMutableArray *currentFeed = [NSMutableArray arrayWithArray:self.dataSource.feed];
            [currentFeed enumerateObjectsUsingBlock:^(Memory *obj, NSUInteger idx, BOOL *stop) {
                if (obj.recordID == memory.recordID) {
                    memoryToDelete = obj;
                    *stop = YES;
                }
            }];
            [currentFeed removeObject:memoryToDelete];
            self.dataSource.feed = [NSArray arrayWithArray:currentFeed];
            memoryToDelete = nil;
        }
    }
}

@end
