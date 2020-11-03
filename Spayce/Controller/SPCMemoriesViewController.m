//
//  SPCMemoriesViewController.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/28/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SPCMemoriesViewController.h"

// Framework
#import "Flurry.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "ProfileDetail.h"
#import "SPCAlertAction.h"
#import "User.h"
#import "UserProfile.h"

// View
#import "MemoryCell.h"
#import "PXAlertView.h"
#import "SPCTimelinePlaceholderCell.h"

// Controller
#import "MemoryCommentsViewController.h"
#import "SPCAlertViewController.h"
#import "SPCMainViewController.h"
#import "SPCProfileViewController.h"
#import "SPCStarsViewController.h"
#import "SPCTagFriendsViewController.h"
#import "SPCMapViewController.h"
#import "SPCHashTagContainerViewController.h"
#import "SignUpViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCReportViewController.h"
#import "SPCReportAlertView.h"
#import "SPCAdminSockPuppetChooserViewController.h"
#import "SPCVenueDetailViewController.h"

// Category
#import "UIAlertView+SPCAdditions.h"
#import "UIImageView+WebCache.h"
#import "UIViewController+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

// Coordinator
#import "SPCMemoryCoordinator.h"

// General
#import "AppDelegate.h"
#import "Constants.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "PNSManager.h"
#import "ProfileManager.h"
#import "SPCPullToRefreshManager.h"
#import "AdminManager.h"

// Transitions
#import "SPCAlertTransitionAnimator.h"

// Utility
#import "APIUtils.h"
#import "ImageUtils.h"
#import "SocialService.h"

 // Literals
#import "SPCLiterals.h"

const NSTimeInterval MEMORY_FEED_UPDATE_EVERY = 30;

static CGFloat FEED_HIDE_NEW_MEMORIES_BUTTON_DISTANCE = 10.f;     // 10 density-independent points

@interface SPCMemoriesViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIViewControllerTransitioningDelegate, SPCAdjustMemoryLocationViewControllerDelegate, SPCMapViewControllerDelegate, SPCPullToRefreshManagerDelegate, SPCTagFriendsViewControllerDelegate, SPCReportAlertViewDelegate, SPCReportViewControllerDelegate, SPCAdminSockPuppetChooserViewControllerDelegate> {
    BOOL refreshAdded;
    
    BOOL moreMemoriesExist;
    BOOL memoryQueryOngoing;
}

// Data
@property (nonatomic, strong) Memory *tempMemory;
@property (strong, nonatomic) NSArray *memories;
@property (assign, nonatomic) NSInteger lastMemoryId;
@property (strong, nonatomic) NSArray *locationMemories;
@property (strong, nonatomic) NSArray *nonLocationMemories;
@property (nonatomic) SPCReportType reportType;
@property (nonatomic, strong) NSArray *reportMemoryOptions;

// UI
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) SPCPullToRefreshManager *pullToRefreshManager;
@property (nonatomic, strong) PXAlertView *alertView;
@property (nonatomic, strong) SPCReportAlertView *reportAlertView;
@property (nonatomic, assign) BOOL viewIsVisible;
@property (nonatomic, strong) UIButton *newMemoriesButton;
@property (nonatomic, assign) CGFloat newMemoriesHidePosition;
@property (nonatomic, assign) CGFloat lastScrollOffset;

// Formatter
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

// Synchronization
@property (nonatomic, assign) NSInteger maxIndexViewed;

// Caching
@property (nonatomic, strong) NSArray *assetQueue;
@property (nonatomic, strong) NSMutableSet *prefetchedList;
@property (nonatomic, assign) NSInteger currentPrefetchIndex;
@property (nonatomic, strong) UIImageView *prefetchImageView;
@property (nonatomic, assign) BOOL prefetchPaused;

// Coordinator
@property (nonatomic, strong) SPCMemoryCoordinator *memoryCoordinator;

// Refresh
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, assign) NSTimeInterval lastFetch;
@property (nonatomic, assign) NSInteger newMemoryCount;

// Add Friends Callout
@property (nonatomic) BOOL addFriendsCalloutWasShown;
@property (nonatomic) BOOL presentedAddFriendsCalloutInstance;

@end

@implementation SPCMemoriesViewController {
    NSInteger alertViewTagTwitter;
    NSInteger alertViewTagFacebook;
    NSInteger alertViewTagReport;
}

#pragma mark - Object lifecyle

- (void)dealloc {
    // Dealloc alert banners
    [self spc_dealloc];
    
    _pullToRefreshManager = nil;
    
    // Remove notification observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Remove KVO observers
    @try {
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(memories))];
        [[PNSManager sharedInstance] removeObserver:self forKeyPath:@"unreadFeedCount"];
    }
    @catch (NSException *exception) {}
    
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (id)init {
    self = [super init];
    if (self) {
        moreMemoriesExist = YES;
    }
    return self;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorWithRed:231.0f/255.0f green:231.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
    
    [self.view addSubview:self.tableView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    
    [self.view addSubview:self.newMemoriesButton];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.newMemoriesButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:130]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.newMemoriesButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:28]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.newMemoriesButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.newMemoriesButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-65]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.newMemoriesButton];
    
    [self configureTableViewHeader];
    
    // Observe KVO changes
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(memories)) options:NSKeyValueObservingOptionNew context:NULL];
    
    [[PNSManager sharedInstance] addObserver:self forKeyPath:@"unreadFeedCount" options:NSKeyValueObservingOptionNew context:nil];
    
    // Observe notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_addMemoryLocally:) name:@"addMemoryLocally" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAssets) name:@"stopAllAssets" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanup) name:kAuthenticationDidLogoutNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshPrompt) name:@"newMemsAvailable" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRequestFollowNotification:) name:kFollowDidRequestWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFollowNotification:) name:kFollowDidFollowWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnfollowNotification:) name:kFollowDidUnfollowWithUserToken object:nil];
    
    // Update top inset
    CGFloat topInset = CGRectGetHeight(self.pullToRefreshFadingHeader.superview.frame) ;

    self.tableView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    self.tableView.contentOffset = CGPointMake(0, -topInset);
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self fetchPublicMemories:NO];
    
    alertViewTagFacebook = 0;
    alertViewTagTwitter = 1;
    alertViewTagReport = 2;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self configureRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = _pullToRefreshFadingHeader;
    }
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    
    self.prefetchPaused = NO;
    self.viewIsVisible = YES;
    if (!self.refreshTimer) {
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:MEMORY_FEED_UPDATE_EVERY+4 target:self selector:@selector(refreshContentInPlaceIfNewContentAvailable) userInfo:nil repeats:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.navigationController.navigationBarHidden = YES;
    
    if ([PNSManager sharedInstance].unreadFeedCount > 0) {
        [self reloadData];
    }
    
    
    self.tableView.tableHeaderView = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = nil;
    }
    
    self.prefetchPaused = YES;
    self.viewIsVisible = NO;
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - View Configuration

- (void)configureTableViewHeader {
    [self refreshPrompt];
}

- (void)configureRefreshControl {
    if (!refreshAdded) {
        refreshAdded = YES;
        self.pullToRefreshManager = [[SPCPullToRefreshManager alloc] initWithScrollView:self.tableView];
        self.pullToRefreshManager.fadingHeaderView = self.pullToRefreshFadingHeader;
        self.pullToRefreshManager.delegate = self;
    }
}

#pragma mark - Mutators

- (void)setPrefetchPaused:(BOOL)prefetchPaused {
    if (_prefetchPaused != prefetchPaused) {
        _prefetchPaused = prefetchPaused;
        
        if (!prefetchPaused) {
            // restart image downloads?
            if (self.assetQueue.count > 0) {
                [self prefetchNextImageInQueue];
            }
        }
    }
}


#pragma mark - Accessors

- (BOOL)hasContent {
    return self.memories != nil;
}

- (UIRefreshControl *)refreshControl {
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(fetchMemories) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0);
        _tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [_tableView registerClass:[SPCTimelinePlaceholderCell class] forCellReuseIdentifier:SPCTimelinePlaceholderCellIdentifier];
    }
    return _tableView;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"MMM dd, yyyy - hh:mm a";
    }
    return _dateFormatter;
}

- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}

- (UIButton *)newMemoriesButton {
    if (!_newMemoriesButton) {
        _newMemoriesButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 130, 28)];
        _newMemoriesButton.backgroundColor = [UIColor whiteColor];
        _newMemoriesButton.layer.cornerRadius = 14;
        _newMemoriesButton.clipsToBounds = NO;
        [_newMemoriesButton setTitle:@"New Moments" forState:UIControlStateNormal];
        [_newMemoriesButton setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
        [_newMemoriesButton.titleLabel setFont:[UIFont spc_mediumSystemFontOfSize:13]];
        _newMemoriesButton.titleEdgeInsets = UIEdgeInsetsMake(2, 8, 0, 0);
        [_newMemoriesButton setImage:[UIImage imageNamed:@"arrow-new-memories"] forState:UIControlStateNormal];
        _newMemoriesButton.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 0);
    
        _newMemoriesButton.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, CGRectGetHeight(self.tableView.frame)/2);
        
        _newMemoriesButton.layer.shadowColor = [UIColor blackColor].CGColor;
        _newMemoriesButton.layer.shadowOffset = CGSizeMake(0, 1);
        _newMemoriesButton.layer.shadowRadius = 1;
        _newMemoriesButton.layer.shadowOpacity = 0.2f;
        
        _newMemoriesButton.translatesAutoresizingMaskIntoConstraints = NO;
        _newMemoriesButton.enabled = NO;
        _newMemoriesButton.hidden = YES;
        
        [_newMemoriesButton addTarget:self action:@selector(scrollToTop) forControlEvents:UIControlEventTouchUpInside];
    }
    return _newMemoriesButton;
}

- (NSMutableSet *)prefetchedList {
    if (!_prefetchedList) {
        _prefetchedList = [[NSMutableSet alloc] init];
    }
    return _prefetchedList;
}

- (void)setPullToRefreshFadingHeader:(UIView *)pullToRefreshFadingHeader {
    _pullToRefreshFadingHeader = pullToRefreshFadingHeader;
    if (_pullToRefreshManager) {
        _pullToRefreshManager.fadingHeaderView = _pullToRefreshFadingHeader;
    }
}

- (SPCMemoryCoordinator *)memoryCoordinator {
    if (!_memoryCoordinator) {
        _memoryCoordinator = [[SPCMemoryCoordinator alloc] init];
    }
    return _memoryCoordinator;
}

- (NSArray *)reportMemoryOptions {
    if (nil == _reportMemoryOptions) {
        _reportMemoryOptions = @[@"ABUSE", @"SPAM", @"PERTAINS TO ME"];
    }
    
    return _reportMemoryOptions;
}


#pragma mark - Setters

-(void)setNewMemoryCount:(NSInteger)newMemoryCount {
    _newMemoryCount = newMemoryCount;
    if (_newMemoryCount <= 0 && self.newMemoriesButton.isEnabled) {
        self.newMemoriesButton.enabled = NO;
        [UIView animateWithDuration:0.4 animations:^{
            self.newMemoriesButton.alpha = 0;
        } completion:^(BOOL finished) {
            self.newMemoriesButton.hidden = YES;
        }];
    }
}


-(void)setMemories:(NSArray *)memories {
    if ([memories count]) {
        _lastMemoryId = ((Memory *)memories.lastObject).recordID;
        NSArray *blockedIds = [MeetManager getBlockedIds];
        NSMutableArray *mems = [NSMutableArray arrayWithCapacity:memories.count];
        for (Memory *memory in memories) {
            if (![blockedIds containsObject:@(memory.author.recordID)]) {
                [mems addObject:memory];
            }
        }
        _memories = [NSArray arrayWithArray:mems];
    } else {
        _lastMemoryId = 0;
        _memories = nil;
    }
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.memories.count == 0 && !moreMemoriesExist){
        return 1;
    } else {
        return moreMemoriesExist ? self.memories.count + 1 : self.memories.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView textCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TextCell";
    __weak typeof(self) weakSelf = self;
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeText style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
        [cell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
        [cell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
        [cell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
        [cell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell setTaggedUserTappedBlock:^(NSString * userToken) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }];
        
        [cell setLocationTappedBlock:^(Memory * memory) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }];
        
        [cell setHashTagTappedBlock:^(NSString *hashTag, Memory *mem) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
            [hashTagContainerViewController configureWithHashTag:hashTag memory:mem];
            [self.navigationController pushViewController:hashTagContainerViewController animated:YES];
        }];
    }
    
    cell.tag = indexPath.row;
    
    [cell configureWithMemory:[self memoryAtIndexPath:indexPath] tag:indexPath.row dateFormatter:self.dateFormatter];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView imageCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    static NSString *CellIdentifier = @"ImageCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeImage style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
        [cell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
        [cell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
        [cell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
        [cell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell setTaggedUserTappedBlock:^(NSString * userToken) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }];
        
        [cell setLocationTappedBlock:^(Memory * memory) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }];
        [cell setHashTagTappedBlock:^(NSString *hashTag, Memory *mem) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
            [hashTagContainerViewController configureWithHashTag:hashTag memory:mem];
            [self.navigationController pushViewController:hashTagContainerViewController animated:YES];
        }];
    }
    
    cell.tag = indexPath.row;
    
    [cell configureWithMemory:[self memoryAtIndexPath:indexPath] tag:indexPath.row dateFormatter:self.dateFormatter];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView videoCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    static NSString *CellIdentifier = @"VideoCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeVideo style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
        [cell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
        [cell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
        [cell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
        [cell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell setTaggedUserTappedBlock:^(NSString * userToken) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }];
       
        [cell setLocationTappedBlock:^(Memory * memory) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }];
        
        [cell setHashTagTappedBlock:^(NSString *hashTag, Memory *mem) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCHashTagContainerViewController *hashTagContainerViewController = [[SPCHashTagContainerViewController alloc] init];
            [hashTagContainerViewController configureWithHashTag:hashTag memory:mem];
            [self.navigationController pushViewController:hashTagContainerViewController animated:YES];
        }];
    }
    
    cell.tag = indexPath.row;
    
    [cell configureWithMemory:[self memoryAtIndexPath:indexPath] tag:indexPath.row dateFormatter:self.dateFormatter];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView mapCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)weakSelf = self;
    static NSString *CellIdentifier = @"MapCell";
    
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeMap style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        [cell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
        [cell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
        [cell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
        [cell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
        [cell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell setTaggedUserTappedBlock:^(NSString * userToken) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }];
        
        [cell setLocationTappedBlock:^(Memory * memory) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }];
    }
    
    [cell configureWithMemory:[self memoryAtIndexPath:indexPath] tag:indexPath.row dateFormatter:self.dateFormatter];
     cell.tag = indexPath.row;
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView friendsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FriendCell";
    
    __weak typeof(self) weakSelf = self;
    MemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[MemoryCell alloc] initWithMemoryType:MemoryTypeFriends style:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell.commentsButton addTarget:self action:@selector(showMemoryRelatedComments:) forControlEvents:UIControlEventTouchUpInside];
        [cell.starsButton addTarget:self action:@selector(updateUserStar:) forControlEvents:UIControlEventTouchUpInside];
        [cell.usersToStarButton addTarget:self action:@selector(showUsersThatStarred:) forControlEvents:UIControlEventTouchUpInside];
        [cell.authorButton addTarget:self action:@selector(showAuthor:) forControlEvents:UIControlEventTouchUpInside];
        [cell.actionButton addTarget:self action:@selector(showMemoryActions:) forControlEvents:UIControlEventTouchUpInside];
        
        [cell setTaggedUserTappedBlock:^(NSString * userToken) {
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }];
        
        [cell setLocationTappedBlock:^(Memory * memory) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            //stop video playback if needed
            [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
            
            [Flurry logEvent:@"MEMORY_GEOTAG_TAPPED"];
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = memory.venue;
            [venueDetailViewController fetchMemories];
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            [strongSelf.navigationController presentViewController:navController animated:YES completion:nil];
        }];
    }
    
    cell.tag = indexPath.row;
    
    [cell configureWithMemory:[self memoryAtIndexPath:indexPath] tag:indexPath.row dateFormatter:self.dateFormatter];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LoadingMore";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.tag = 111;
        indicatorView.color = [UIColor grayColor];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:indicatorView];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        [indicatorView startAnimating];
    } else {
        UIActivityIndicatorView *animation = (UIActivityIndicatorView *)[cell viewWithTag:111];
        [animation startAnimating];
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeholderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCTimelinePlaceholderCell *cell = [self.tableView dequeueReusableCellWithIdentifier:SPCTimelinePlaceholderCellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"tableView: cellForRowAtIndexPath: %d", indexPath.row);
    if (self.memories.count == 0 && moreMemoriesExist) {
        return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
    }
    else {
        // First: check whether it's appropriate to launch a background query for more memories.
        if (moreMemoriesExist && !memoryQueryOngoing && self.memories.count - indexPath.row < 5) {
            // Within 5 of the bottom...
            [self fetchMorePublicMemories];
        }
        
        if (indexPath.row < self.memories.count) {
            if (indexPath.row < self.newMemoryCount) {
                self.newMemoryCount = indexPath.row;
            }
            
            Memory *memory = self.memories[indexPath.row];
            
            if (memory.type == MemoryTypeText) {
                return [self tableView:tableView textCellForRowAtIndexPath:indexPath];
            }
            if (memory.type == MemoryTypeImage) {
                    return [self tableView:tableView imageCellForRowAtIndexPath:indexPath];
            }
            if (memory.type == MemoryTypeVideo) {
                    return [self tableView:tableView videoCellForRowAtIndexPath:indexPath];
            }
            if (memory.type == MemoryTypeMap) {
                return [self tableView:tableView mapCellForRowAtIndexPath:indexPath];
            }
            if (memory.type == MemoryTypeFriends) {
                return [self tableView:tableView friendsCellForRowAtIndexPath:indexPath];
            }
        } else if (moreMemoriesExist) {
            return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
        } else {
            return [self tableView:tableView placeholderCellForRowAtIndexPath:indexPath];
        }
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.memories.count == 0){
        return CGRectGetHeight(self.tableView.frame) - CGRectGetHeight(self.tabBarController.tabBar.frame) - CGRectGetHeight(self.navigationController.navigationBar.frame);
    }
    else {
        Memory *memory = [self memoryAtIndexPath:indexPath];
        return [MemoryCell measureHeightWithMemory:memory constrainedToSize:CGSizeMake(290, 20000)];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.draggingScrollView = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL scrollingUp = self.lastScrollOffset > scrollView.contentOffset.y;
    
    // New memories button?
    if (self.newMemoryCount > 0) {
        if (scrollingUp || scrollView.contentOffset.y + FEED_HIDE_NEW_MEMORIES_BUTTON_DISTANCE < self.newMemoriesHidePosition) {
            self.newMemoriesHidePosition = scrollView.contentOffset.y + FEED_HIDE_NEW_MEMORIES_BUTTON_DISTANCE;
        }
        if (scrollingUp != self.newMemoriesButton.enabled) {
            if (scrollingUp) {
                // display button
                self.newMemoriesButton.alpha = 0;
                self.newMemoriesButton.hidden = NO;
                self.newMemoriesButton.enabled = YES;
                [UIView animateWithDuration:0.4 animations:^{
                    self.newMemoriesButton.alpha = 1;
                }];
            } else if (scrollView.contentOffset.y >= self.newMemoriesHidePosition) {
                // hide button
                self.newMemoriesButton.enabled = NO;
                [UIView animateWithDuration:0.4 animations:^{
                    self.newMemoriesButton.alpha = 0;
                } completion:^(BOOL finished) {
                    self.newMemoriesButton.hidden = YES;
                }];
            }
        }
    }
    
    // Fades in bottom cell in table view as it enter the screen for first time
    NSArray *visibleCells = [self.tableView visibleCells];
    
    // Don't do anything for empty table view, or one loading data
    if (visibleCells != nil && [visibleCells count] != 0 && !self.pullToRefreshManager.isLoading) {
        
        /* Get bottom cell */
        UITableViewCell *bottomCell = [visibleCells lastObject];
        
        int prefetchIndex = 1 + (int)bottomCell.tag;
        if (self.currentPrefetchIndex != prefetchIndex) {
            if (prefetchIndex < self.memories.count) {
                Memory *tempMem = self.memories[prefetchIndex];
                if (![self.prefetchedList containsObject:@(tempMem.recordID)]) {
                    self.currentPrefetchIndex = prefetchIndex;
                    [self updatePrefetchQueueWithMemAtIndex];
                }
            }
        }
        
        /* Make sure other cells stay opaque */
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.alpha = 1.0;
        }
        
        /* Set necessary constants */
        NSInteger tableViewBottomPosition = self.tableView.frame.origin.y + self.tableView.frame.size.height;
        NSIndexPath *bottomIndexPath = [NSIndexPath indexPathForRow:bottomCell.tag inSection:0];
        Memory *bottomCellMem = [self memoryAtIndexPath:bottomIndexPath];
        CGSize constraint = CGSizeMake(290, 20000);
        CGFloat height = MIN(scrollView.frame.size.height, [MemoryCell measureHeightWithMemory:bottomCellMem constrainedToSize:constraint]);
        NSInteger cellHeight = height;
        
        /* Get content offset to set opacity */
        CGRect bottomCellPositionInTableView = [self.tableView rectForRowAtIndexPath:[self.tableView indexPathForCell:bottomCell]];
        CGFloat bottomCellPosition = ([self.tableView convertRect:bottomCellPositionInTableView toView:[self.tableView superview]].origin.y + cellHeight);
        
        /* Set opacity based on amount of cell that is outside of view */
        CGFloat modifier = 1.1;     /* Increases the speed of fading (1.0 for fully transparent when the cell is entirely off the screen,
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
    }
    
    [self.pullToRefreshManager scrollViewDidScroll:scrollView];
    
    self.lastScrollOffset = scrollView.contentOffset.y;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.pullToRefreshManager scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    
    if (!decelerate) {
        self.draggingScrollView = NO;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.draggingScrollView = NO;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.maxIndexViewed) {
        self.maxIndexViewed = indexPath.row;
    }
    
    if ([cell.reuseIdentifier isEqualToString:@"VideoCell"])  {
        [cell prepareForReuse]; //force this call right away when cell is off screen to stop video playback
    }
}

#pragma mark - Private

- (Memory *)memoryAtIndexPath:(NSIndexPath *)indexPath {
    if (self.memories && indexPath.row < self.memories.count) {
        return self.memories[indexPath.row];
    }
    return nil;
}

- (void)reloadData {
    [self.tableView reloadData];
}

- (void)cleanup {
    self.memories = nil;
    self.locationMemories = nil;
    self.nonLocationMemories = nil;
    
    self.view.userInteractionEnabled = YES;
    
    [self reloadData];
}

- (void)dismissAlert:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"unreadFeedCount"]) {
        if (self.viewIsVisible) {
            [self refreshContentInPlace];
        } else {
            [self refreshContent];
        }
    }
}

#pragma mark - Actions


- (void)scrollToTop {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

- (void)showMemoryRelatedComments:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    NSInteger index = [sender tag];
    Memory *memory = [self memoryAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    [self stopAssets];
    
    MemoryCommentsViewController *memoryCommentsViewController = [[MemoryCommentsViewController alloc] initWithMemory:memory];
    memoryCommentsViewController.view.clipsToBounds=NO;
    [self.navigationController pushViewController:memoryCommentsViewController animated:YES];
    
    self.tabBarController.tabBar.alpha = 0.0;
}

- (void)showAuthor:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    NSInteger index = [sender tag];
    Memory *memory = [self memoryAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    if (memory.realAuthor && memory.realAuthor.userToken) {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:memory.realAuthor.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    } else if (memory.author.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    } else {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:memory.author.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}


- (void)updateUserStar:(id)sender {
    NSInteger index = [sender tag];
    Memory *memory;
    
    UIButton *button = (UIButton *)sender;
    button.userInteractionEnabled = NO;
    memory = [self memoryAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    [self updateUserStarForMemory:memory button:button];
}


- (void)updateUserStarForMemory:(Memory *)memory button:(UIButton *)button {
    if (memory.userHasStarred) {
        [self removeStarForMemory:memory button:button sockpuppet:nil];
    }
    else if (!memory.userHasStarred) {
        [self addStarForMemory:memory button:button sockpuppet:nil];
    }
}

- (void)addStarForMemory:(Memory *)memory button:(UIButton *)button sockpuppet:(Person *)sockpuppet {
    //update locally immediately
    Person * userAsStarred = memory.userToStarMostRecently;
    if (!sockpuppet) {
        memory.userHasStarred = YES;
        Person * thisUser = [[Person alloc] init];
        thisUser.userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        thisUser.firstname = [ContactAndProfileManager sharedInstance].profile.profileDetail.firstname;
        thisUser.imageAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        thisUser.recordID = [AuthenticationManager sharedInstance].currentUser.userId;
        memory.userToStarMostRecently = thisUser;
    } else {
        memory.userToStarMostRecently = sockpuppet;
    }
    memory.starsCount = memory.starsCount + 1;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    button.userInteractionEnabled = NO;
    
    [MeetManager addStarToMemory:memory
                    asSockPuppet:sockpuppet
                  resultCallback:^(NSDictionary *result) {
                      
                      int resultInt = [result[@"number"] intValue];
                      NSLog(@"add star result %i",resultInt);
                      button.userInteractionEnabled = YES;
                      
                      if (resultInt == 1) {
                          
                      }
                      //correct local update if call failed
                      else {
                          memory.userHasStarred = NO;
                          memory.starsCount = memory.starsCount - 1;
                          memory.userToStarMostRecently = userAsStarred;
                          
                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                          [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                          
                          [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                      }
                      
                  }
                   faultCallback:^(NSError *fault) {
                       if (!sockpuppet) {
                           memory.userHasStarred = NO;
                       }
                       memory.starsCount = memory.starsCount - 1;
                       memory.userToStarMostRecently = userAsStarred;
                       button.userInteractionEnabled = YES;
                       
                       //correct local update if call failed
                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                       
                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error adding star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                   }];
}

- (void)removeStarForMemory:(Memory *)memory button:(UIButton *)button sockpuppet:(Person *)sockpuppet {
    // we might need to refresh the memory cell from the server: if the user
    // was the most recent to star the memory, AND there are multiple stars,
    // we need to pull down data again to see who is the most recent afterwards.
    BOOL refreshMemoryFromServer = NO;
    Person * userAsStarred = memory.userToStarMostRecently;
    
    //update locally immediately
    if (!sockpuppet) {
        memory.userHasStarred = NO;
        if (memory.userToStarMostRecently.recordID == [AuthenticationManager sharedInstance].currentUser.userId) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
    } else {
        if (memory.userToStarMostRecently.recordID == sockpuppet.recordID) {
            userAsStarred = memory.userToStarMostRecently;
            if (memory.starsCount == 0) {
                memory.userToStarMostRecently = nil;
            } else {
                refreshMemoryFromServer = YES;
            }
        }
    }
    memory.starsCount = memory.starsCount - 1;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    button.userInteractionEnabled = NO;
    
    [MeetManager deleteStarFromMemory:memory
                         asSockPuppet:sockpuppet
                       resultCallback:^(NSDictionary *result){
                           int resultInt = [result[@"number"] intValue];
                           NSLog(@"delete star result %i",resultInt);
                           button.userInteractionEnabled = YES;
                           
                           if (resultInt == 1) {
                               if (refreshMemoryFromServer) {
                                   [MeetManager fetchMemoryWithMemoryId:memory.recordID resultCallback:^(NSDictionary *results) {
                                       [memory setWithAttributes:results];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                   } faultCallback:^(NSError *fault) {
                                       if (!sockpuppet) {
                                           memory.userHasStarred = YES;
                                       }
                                       memory.starsCount = memory.starsCount + 1;
                                       memory.userToStarMostRecently = userAsStarred;
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                                       [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                       
                                       [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                   }];
                               }
                           }
                           //correct local update if call failed
                           else {
                               if (!sockpuppet) {
                                   memory.userHasStarred = YES;
                               }
                               memory.starsCount = memory.starsCount + 1;
                               memory.userToStarMostRecently = userAsStarred;
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                               [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                               
                               [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                           }
                           
                       }
                        faultCallback:^(NSError *error){
                            
                            //correct local update if call failed
                            if (!sockpuppet) {
                                memory.userHasStarred = YES;
                            }
                            memory.starsCount = memory.starsCount + 1;
                            memory.userToStarMostRecently = userAsStarred;
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:memory];
                            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                            
                            button.userInteractionEnabled = YES;
                            [[[UIAlertView alloc] initWithTitle:nil message:@"Error removing star. Please try again later." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                        }];
}



- (void)showUsersThatStarred:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    NSInteger index = [sender tag];
    Memory *memory = [self memoryAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    SPCStarsViewController *starsViewController = [[SPCStarsViewController alloc] init];
    starsViewController.memory = memory;
    [self.navigationController pushViewController:starsViewController animated:YES];
}

- (void)showMemoryActions:(id)sender {
    //stop video playback if needed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil];
    
    // Selected memory index
    NSInteger idx = [sender tag];
    [Flurry logEvent:@"MEMORY_ACTION_BUTTON_TAPPED"];
    // Selected memory
    Memory *memory = self.memories[idx];
    
    BOOL isUsersMemory = memory.author.recordID == [AuthenticationManager sharedInstance].currentUser.userId;
    BOOL userIsWatching = memory.userIsWatching;
    
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    if ([AuthenticationManager sharedInstance].currentUser.isAdmin) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Promote Memory" subtitle:@"Add memory to Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Promote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Promote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] promoteMemory:memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Promoted Memory" message:@"This memory has been promoted.  It should now have prominent Local and World grid placement." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Demote Memory" subtitle:@"Remove from Local and World grids" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAlertViewController *subAlertViewController = [[SPCAlertViewController alloc] init];
            subAlertViewController.modalPresentationStyle = UIModalPresentationCustom;
            subAlertViewController.transitioningDelegate = self;
            subAlertViewController.alertTitle = NSLocalizedString(@"Demote Memory?", nil);
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Demote", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
                [[AdminManager sharedInstance] demoteMemory:memory completionHandler:^{
                    [[[UIAlertView alloc] initWithTitle:@"Demoted Memory" message:@"This memory has been demoted.  It should not appear on Local or World grids." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] show];
                } errorHandler:^(NSError *error) {
                    [UIAlertView showError:error];
                }];
            }]];
            
            [subAlertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
            
            [self.navigationController presentViewController:subAlertViewController animated:YES completion:nil];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Star as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionStar object:memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:@"Unstar as Puppet" style:SPCAlertActionStyleNormal handler:^(SPCAlertAction *action) {
            SPCAdminSockPuppetChooserViewController *vc = [[SPCAdminSockPuppetChooserViewController alloc] initWithSockPuppetAction:SPCAdminSockPuppetActionUnstar object:memory];
            vc.delegate = self;
            [self.navigationController pushViewController:vc animated:YES];
        }]];
    }
    
    // Alert view controller - alerts
    if (isUsersMemory) {
       
        alertViewController.alertTitle = NSLocalizedString(@"Edit or Share", nil);
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Change Location", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   [Flurry logEvent:@"MEM_UPDATED_LOCATION"];
                                                                   SPCMapViewController *mapVC = [[SPCMapViewController alloc] initForExistingMemory:memory];
                                                                   mapVC.delegate = self;
                                                                   [self.navigationController pushViewController:mapVC animated:YES];
                                                               }]];
        if (memory.type != MemoryTypeFriends) {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Tag Friends", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   SPCTagFriendsViewController *tagUsersViewController = [[SPCTagFriendsViewController alloc] initWithMemory:memory];
                                                                   tagUsersViewController.delegate = self;
                                                                   [self presentViewController:tagUsersViewController animated:YES completion:nil];
                                                               }]];
        }

            /* TODO: implement FB memory sharing on the client using a Facebook dialog.
             * This approach does not require FB review, although sharing through the server does.
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Share to Facebook", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self shareMemory:memory serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
                                                                   }]];
             */
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Share to Twitter", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [Flurry logEvent:@"MEM_SHARED_TO_TWITTER"];
                                                                       [self shareMemory:memory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
                                                                   }]];
        
        
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Delete Memory", nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showDeletePromptForMemory:memory];
                                                               }]];
    }
    else {
        alertViewController.alertTitle = NSLocalizedString(@"Watch or Report", nil);
        
        if (!userIsWatching) {
            
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Watch Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Get notifications of activity on this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self watchMemory:memory];
                                                                   }]];
        }
        else {
            [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Stop Watching Memory", nil)
                                                                  subtitle:NSLocalizedString(@"Stop receiving notifications about this memory", nil)
                                                                     style:SPCAlertActionStyleNormal
                                                                   handler:^(SPCAlertAction *action) {
                                                                       [self stopWatchingMemory:memory];
                                                                   }]];
        }
        
        
        NSString *reportString = [AuthenticationManager sharedInstance].currentUser.isAdmin ? @"Delete Memory" : @"Report Memory";
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(reportString, nil)
                                                                 style:SPCAlertActionStyleDestructive
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self showReportPromptForMemory:memory];
                                                               }]];
    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self presentViewController:alertViewController animated:YES completion:nil];
}

- (void)showBlockPromptForMemory:(Memory *)memory {
    NSString *msgText = [NSString stringWithFormat:@"You are about to block %@. This means that you will both be permanently invisible to each other.", memory.author.displayName];

    UIView *alertView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 235)];
    alertView.backgroundColor = [UIColor whiteColor];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 20, 270, 42);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.center=CGPointMake(alertView.bounds.size.width/2, imageView.center.y);
    [alertView addSubview:imageView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, 270, 30)];
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = [NSString stringWithFormat:@"Block %@?", memory.author.displayName];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [alertView addSubview:titleLabel];

    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 205, 100)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.center = CGPointMake(alertView.center.x, messageLabel.center.y);
    messageLabel.text = msgText;
    messageLabel.numberOfLines = 0;
    messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [alertView addSubview:messageLabel];

    UIColor *cancelBgColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    UIColor *cancelTextColor = [UIColor colorWithRed:145.0f/255.0f green:167.0f/255.0f blue:193.0f/255.0f alpha:1.0f];
    CGRect cancelBtnFrame = CGRectMake(25,180,100,40);

    UIColor *otherBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
    UIColor *otherTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
    CGRect otherBtnFrame = CGRectMake(145,180,100,40);

    NSString *targetUserName = memory.author.displayName;

    [PXAlertView showAlertWithView:alertView cancelTitle:@"Cancel" cancelBgColor:cancelBgColor cancelTextColor:cancelTextColor cancelFrame:cancelBtnFrame otherTitle:@"Block" otherBgColor:otherBgColor otherTextColor:otherTextColor otherFrame:otherBtnFrame completion:^(BOOL cancelled) {

        if (!cancelled) {
            [MeetManager blockUserWithId:memory.author.recordID
                          resultCallback:^(NSDictionary *result)  {

                              UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 165)];
                              contentView.backgroundColor = [UIColor whiteColor];

                              UILabel *contentTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 270, 30)];
                              contentTitleLabel.font = [UIFont boldSystemFontOfSize:20];
                              contentTitleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                              contentTitleLabel.backgroundColor = [UIColor clearColor];
                              contentTitleLabel.text = NSLocalizedString(@"Blocked!",nil);
                              contentTitleLabel.textAlignment = NSTextAlignmentCenter;
                              [contentView addSubview:contentTitleLabel];

                              UILabel *contentMessageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 250, 60)];
                              contentMessageLabel.font = [UIFont systemFontOfSize:16];
                              contentMessageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
                              contentMessageLabel.backgroundColor = [UIColor clearColor];
                              contentMessageLabel.center=CGPointMake(contentView.center.x, contentMessageLabel.center.y);
                              contentMessageLabel.text = [NSString stringWithFormat:@"You have blocked %@.",targetUserName];
                              contentMessageLabel.numberOfLines=0;
                              contentMessageLabel.lineBreakMode=NSLineBreakByWordWrapping;
                              contentMessageLabel.textAlignment = NSTextAlignmentCenter;
                              [contentView addSubview:contentMessageLabel];

                              UIColor *contentCancelBgColor = [UIColor colorWithRed:22.0f/255.0f green:26.0f/255.0f blue:30.0f/255.0f alpha:1.0f];
                              UIColor *contentCancelTextColor = [UIColor colorWithRed:103.0f/255.0f green:120.0f/255.0f blue:140.0f/255.0f alpha:1.0f];
                              CGRect contentCancelBtnFrame = CGRectMake(70,100,130,40);

                              [PXAlertView showAlertWithView:contentView cancelTitle:@"OK" cancelBgColor:contentCancelBgColor
                                             cancelTextColor:contentCancelTextColor
                                                 cancelFrame:contentCancelBtnFrame
                                                  completion:^(BOOL cancelled) {
                                                      [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
                                                      [ProfileManager fetchProfileWithUserToken:[AuthenticationManager sharedInstance].currentUser.userToken
                                                                                 resultCallback:nil
                                                                                  faultCallback:nil];
                                                  }];
                          }
                           faultCallback:nil];
        }
    }];
}

- (void)showDeletePromptForMemory:(Memory *)memory {
    self.tempMemory = memory;
    
    [self stopAssets];
    
    UIView *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 270, 280)];
    demoView.backgroundColor = [UIColor whiteColor];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"oh-no"]];
    imageView.frame = CGRectMake(0, 10, 270, 40);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [demoView addSubview:imageView];
    
    NSString *title = @"Delete this memory?";
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 270, 20)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    titleLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:titleLabel];
    
    UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 230, 40)];
    messageLabel.font = [UIFont systemFontOfSize:14];
    messageLabel.textColor = [UIColor colorWithRGBHex:0x485868];
    messageLabel.backgroundColor = [UIColor clearColor];
    messageLabel.numberOfLines = 2;
    messageLabel.text = @"Once you delete this memory it will be gone forever!";
    messageLabel.textAlignment = NSTextAlignmentCenter;
    [demoView addSubview:messageLabel];
    
    UIButton *okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    okBtn.frame = CGRectMake(70, 145, 130, 40);
    
    [okBtn setTitle:NSLocalizedString(@"Delete", nil) forState:UIControlStateNormal];
    okBtn.backgroundColor = [UIColor colorWithRGBHex:0x4ACBEB];
    okBtn.layer.cornerRadius = 4.0;
    okBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    
    UIImage *selectedImage = [ImageUtils roundedRectImageWithColor:[UIColor colorWithRGBHex:0x4795AC] size:okBtn.frame.size corners:4.0f];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateHighlighted];
    [okBtn setBackgroundImage:selectedImage forState:UIControlStateSelected];
    
    [okBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okBtn addTarget:self action:@selector(deleteConfirmed:) forControlEvents:UIControlEventTouchUpInside];
    [demoView addSubview:okBtn];
    
    
    CGRect cancelFrame = CGRectMake(70, 205, 130, 40);
    
    self.alertView = [PXAlertView showAlertWithView:demoView cancelTitle:@"Cancel" cancelBgColor:[UIColor darkGrayColor] cancelTextColor:[UIColor whiteColor] cancelFrame:cancelFrame completion:^(BOOL cancelled) {
        self.alertView = nil;
    }];
}

- (void)deleteConfirmed:(id)sender {
    // Dismiss alert
    [self dismissAlert:sender];
    [Flurry logEvent:@"MEM_DELETED"];
    // Delete memory
    [self.memoryCoordinator deleteMemory:self.tempMemory completionHandler:^(BOOL success) {
        if (success) {
            if ([self.memories containsObject:self.tempMemory]) {
                // Remove locally
                NSMutableArray *mutableMemories = [NSMutableArray arrayWithArray:self.memories];
                [mutableMemories removeObject:self.tempMemory];
                self.memories = [NSArray arrayWithArray:mutableMemories];
            }
            
            [self reloadData];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryDeleted object:self.tempMemory];
            [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil
                                        message:NSLocalizedString(@"Error deleting memory. Please try again later.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                              otherButtonTitles:nil] show];
        }
        self.tempMemory = nil;
    }];
}

- (void)showReportPromptForMemory:(Memory *)memory {
    self.tempMemory = memory;
    
    [self stopAssets];
    
    self.reportAlertView = [[SPCReportAlertView alloc] initWithTitle:@"Choose type of report" stringOptions:self.reportMemoryOptions dismissTitles:@[@"CANCEL"] andDelegate:self];
    
    [self.reportAlertView showAnimated:YES];
}

- (void)watchMemory:(Memory *)memory {
    
    memory.userIsWatching = YES;
    
    [MeetManager watchMemoryWithMemoryKey:memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"watching mem!");
                           }
                            faultCallback:nil];
    
}

- (void)stopWatchingMemory:(Memory *)memory {
    
    memory.userIsWatching = NO;
    
    [MeetManager unwatchMemoryWithMemoryKey:memory.key
                           resultCallback:^(NSDictionary *result) {
                               NSLog(@"unwatching mem!");
                           }
                            faultCallback:nil];
    
}


- (void)stopAssets {
    
}



- (void)refreshContent {
    if ([PNSManager sharedInstance].unreadFeedCount > 0) {
        self.memories = nil;
        
        moreMemoriesExist = YES;
        
        [self fetchPublicMemories:NO];
    }
}

- (void)refreshContentInPlace {
    if (!memoryQueryOngoing) {
        if ([PNSManager sharedInstance].unreadFeedCount > 20) {
            [self refreshContent];
        } else {
            [self fetchPublicMemories:YES];
        }
    }
}

- (void)refreshContentInPlaceIfNewContentAvailable {
    //NSLog(@"refreshContentInPlaceIfNewContentAvailable...");
    if (self.memories && self.memories.count > 0) {
        NSTimeInterval timeSinceFetch =  [[NSDate date] timeIntervalSince1970] - self.lastFetch;
        NSInteger millisSinceFetch = timeSinceFetch * 1000;
        //NSLog(@"timeSinceFetch %f", timeSinceFetch);
        if (timeSinceFetch >= MEMORY_FEED_UPDATE_EVERY) {
            __weak typeof(self) weakSelf = self;
            [MeetManager fetchNewFeedCountSince:millisSinceFetch completionHandler:^(NSInteger newCount) {
                //NSLog(@"fetched %d new count since %d", newCount, millisSinceFetch);
                __strong typeof(self) strongSelf = weakSelf;
                if (newCount > 0) {
                    //NSLog(@"%d new feed items: refreshing!", newCount);
                    [strongSelf fetchPublicMemories:YES];
                }
            } errorHandler:^(NSError *error) {
                // meh
            }];
        }
    }
}

- (void)refreshPrompt {
    if ([PNSManager sharedInstance].unreadFeedCount > 0) {
        float prevOffset = self.tableView.contentOffset.y;
        
        UILabel *tempAlert = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 100)];
        tempAlert.backgroundColor = [UIColor clearColor];
        tempAlert.text = [NSString stringWithFormat:@"%i new memories available.\nPull to refresh!",(int)[PNSManager sharedInstance].unreadFeedCount];
        
        if ((int)[PNSManager sharedInstance].unreadFeedCount==1){
            tempAlert.text = [NSString stringWithFormat:@"1 new memory available.\nPull to refresh!"];
        }
    
        tempAlert.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
        tempAlert.textColor = [UIColor colorWithWhite:30.0f/255.0f alpha:1.0f];
        tempAlert.textAlignment = NSTextAlignmentCenter;
        tempAlert.numberOfLines = 0;
        tempAlert.lineBreakMode = NSLineBreakByWordWrapping;
        self.tableView.tableHeaderView = tempAlert;
        
        [self reloadData];
        
        [self.tableView setContentOffset:CGPointMake(0, prevOffset+100) animated:NO];
    } else if ([PNSManager sharedInstance].unreadFeedCount == 0)   {
        self.tableView.tableHeaderView = nil;
        [self reloadData];
    }
}

#pragma mark - Memories - Fetching

- (void)fetchMemories {
    [self.refreshControl beginRefreshing];
    
    [self fetchPublicMemories:NO];
}

- (void)fetchPublicMemories:(BOOL)smoothUpdate {
    static NSInteger fetchCount = 20;
    
    memoryQueryOngoing = YES;
    
    self.lastFetch = [[NSDate date] timeIntervalSince1970];
    
    [self spc_hideNotificationBanner];
    
    __weak typeof(self) weakSelf = self;
    
    [MeetManager fetchMemoriesFeedWithCount:fetchCount
                          completionHandler:^(NSArray *memories, NSInteger totalRetrieved) {
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              if (!strongSelf) {
                                  return ;
                              }
                              
                              memoryQueryOngoing = NO;
                              moreMemoriesExist = memories.count > 0;
                              
                              BOOL didSmoothUpdate = YES;
                              if (!smoothUpdate) {
                                  didSmoothUpdate = NO;
                              } else if (!strongSelf.memories) {
                                  didSmoothUpdate = NO;
                              } else if (strongSelf.memories.count < 5) { // heuristic: fewer memories and we shouldn't bother trying a smooth refresh.
                                  didSmoothUpdate = NO;
                              } else if ([strongSelf.pullToRefreshManager isLoading]) {
                                  didSmoothUpdate = NO;
                              } else {
                                  // attempt a smooth update.  Do this if our 20 result
                                  // page does not entirely represent the future -- if we
                                  // can identify a point where the 1st page refresh transitions
                                  // into memories we already know about.  Only include
                                  // memories which are newer than those in our existing list.
                                  int newMemoryCount = 0;
                                  NSDate *mostRecent = ((Memory *)strongSelf.memories[0]).dateCreated;
                                  for (int i = 0; i < memories.count; i++) {
                                      if ([((Memory *)memories[i]).dateCreated compare:mostRecent] == NSOrderedDescending) {
                                          newMemoryCount++;
                                      } else {
                                          break;
                                      }
                                  }
                                  if (newMemoryCount == memories.count) {
                                      didSmoothUpdate = NO;
                                  } else {
                                      NSLog(@"performing a smooth update!");
                                      NSMutableArray *mutArray = [NSMutableArray arrayWithArray:[memories subarrayWithRange:NSMakeRange(0, newMemoryCount)]];
                                      [mutArray addObjectsFromArray:strongSelf.memories];
                                      
                                      // This is our new memories array.  The update procedure is:
                                      // 1. Set our memory array
                                      // 2. Calculate the height of our new memories
                                      // 3. Reload the table data
                                      // 4. Update our content offset by adding the new memory height
                                      // 5. Show some sort of indication that new memories are available up above.
                                      
                                      strongSelf.memories = [NSArray arrayWithArray:mutArray];
                                      CGFloat memHeight = 0;
                                      for (int i = 0; i < newMemoryCount; i++) {
                                          memHeight += [strongSelf tableView:strongSelf.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                                      }
                                      CGPoint previousOffset = strongSelf.tableView.contentOffset;
                                      CGPoint offset = CGPointMake(previousOffset.x, previousOffset.y + memHeight);
                                      [strongSelf reloadData];
                                      strongSelf.tableView.contentOffset = offset;
                                      
                                      // inform the user that new content is available above
                                      strongSelf.newMemoryCount += newMemoryCount;
                                  }
                              }
                              
                              if (!didSmoothUpdate) {
                                  NSLog(@"no smooth update attempted");
                                  strongSelf.memories = memories;
                                  [strongSelf reloadData];
                                  strongSelf.newMemoryCount = 0;
                              }
                              
                              //update tableview header
                              strongSelf.tableView.tableHeaderView = nil;
                              [strongSelf configureTableViewHeader];
                              [strongSelf.pullToRefreshManager refreshFinished];
                              strongSelf.pullToRefreshStarted = NO;
                              
                              if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(spcMemoriesViewControllerDidLoadFeed:)]) {
                                  [strongSelf.delegate spcMemoriesViewControllerDidLoadFeed:strongSelf];
                              }
                              
                              if (strongSelf.prefetchedList.count == 0) {
                                  [strongSelf updatePrefetchQueueWithMemAtIndex];
                              }
                          } errorHandler:^(NSError *error) {
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              if (!strongSelf) {
                                  return ;
                              }
                              memoryQueryOngoing = false;
                              [strongSelf reloadData];
                              [strongSelf.pullToRefreshManager refreshFinished];
                              strongSelf.pullToRefreshStarted = NO;
                              
                              // Show error notification
                              [strongSelf spc_showNotificationBannerInParentView:strongSelf.tableView title:NSLocalizedString(@"Couldn't Refresh Feed", nil) error:error];
                          }];
}

- (void)fetchMorePublicMemories {
    static NSInteger fetchCount = 20;
    //NSLog(@"fetch more public memories!");
    // Fetch a list of publicly available memories
    memoryQueryOngoing = YES;

    __weak typeof(self) weakSelf = self;
    [MeetManager fetchMemoriesFeedWithCount:fetchCount
                                  idsBefore:self.lastMemoryId
                          completionHandler:^(NSArray *memories, NSInteger totalRetrieved) {
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              if (!strongSelf) {
                                  return ;
                              }
                              memoryQueryOngoing = NO;
                              moreMemoriesExist = memories.count > 0;
                              NSMutableArray * array = [[NSMutableArray alloc] initWithArray:strongSelf.memories];
                              for (int i = 0; i < memories.count; i++) {
                                  [array addObject:memories[i]];
                              }
                              strongSelf.memories = [[NSArray alloc] initWithArray:array];
                              
                              //update tableview header
                              strongSelf.tableView.tableHeaderView = nil;
                              [strongSelf configureTableViewHeader];
                              
                              [strongSelf reloadData];
                              [strongSelf.pullToRefreshManager refreshFinished];
                          } errorHandler:^(NSError *error) {
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              if (!strongSelf) {
                                  return ;
                              }
                              memoryQueryOngoing = false;
                              [strongSelf reloadData];
                              [strongSelf.pullToRefreshManager refreshFinished];
                          }];
}

#pragma mark - Memories - Sharing

- (void)shareMemory:(Memory *)memory serviceName:(NSString *)serviceName serviceType:(SocialServiceType)serviceType {
    BOOL isServiceAvailable = [[SocialService sharedInstance] availabilityForServiceType:serviceType];
    if (isServiceAvailable) {
        [self.memoryCoordinator shareMemory:memory serviceName:serviceName completionHandler:^{
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Shared to %@", nil), [serviceName capitalizedString]]
                                        message:NSLocalizedString(@"Your memory has been successfully shared.", nil)
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
        }];
    }
    else {
        self.tempMemory = memory;
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Request %@ Access", nil), [serviceName capitalizedString]]
                                                            message:[NSString stringWithFormat:NSLocalizedString(@"You have to authorize with %@ in order to invite your friends", nil), [serviceName capitalizedString]]
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                  otherButtonTitles:NSLocalizedString(@"Authorize", nil), nil];
        alertView.tag = serviceType;
        [alertView show];
    }
}

#pragma mark - Memories - Local Changes

- (void)spc_localMemoryDeleted:(NSNotification *)note {
    Memory * memory = [note object];
    NSInteger memoryId = memory.recordID;
    
    NSMutableArray * mutMem = [NSMutableArray arrayWithArray:self.memories];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memoryId) {
            [mutMem removeObject:obj];
            *stop = YES;
        }
    }];
    self.memories = [NSArray arrayWithArray:mutMem];
    
    mutMem = [NSMutableArray arrayWithArray:self.locationMemories];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memoryId) {
            [mutMem removeObject:obj];
            *stop = YES;
        }
    }];
    self.locationMemories = [NSArray arrayWithArray:mutMem];
    
    mutMem = [NSMutableArray arrayWithArray:self.nonLocationMemories];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memoryId) {
            [mutMem removeObject:obj];
            *stop = YES;
        }
    }];
    self.nonLocationMemories = [NSArray arrayWithArray:mutMem];
    
    [self reloadData];
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    
    NSMutableArray * mutMem = [NSMutableArray arrayWithArray:self.memories];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [((Memory *)obj) updateWithMemory:memory];
            *stop = YES;
        }
    }];
    self.memories = [NSArray arrayWithArray:mutMem];
    
    mutMem = [NSMutableArray arrayWithArray:self.locationMemories];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [((Memory *)obj) updateWithMemory:memory];
            *stop = YES;
        }
    }];
    self.locationMemories = [NSArray arrayWithArray:mutMem];
    
    mutMem = [NSMutableArray arrayWithArray:self.nonLocationMemories];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [((Memory *)obj) updateWithMemory:memory];
            *stop = YES;
        }
    }];
    self.nonLocationMemories = [NSArray arrayWithArray:mutMem];
    
    [self reloadData];
}

- (void)spc_addMemoryLocally:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    if (self.memories && !memory.isAnonMem) {
        NSMutableArray * array = [NSMutableArray arrayWithArray:self.memories];
        [array insertObject:memory atIndex:0];
        self.memories = [NSArray arrayWithArray:array];
    }
    [self reloadData];
}

- (void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    if (personUpdate) {
        BOOL changed = [personUpdate applyToArray:self.memories];
        changed = [personUpdate applyToArray:self.locationMemories] || changed;
        changed = [personUpdate applyToArray:self.nonLocationMemories] || changed;
        if (changed && _tableView) {
            [self.tableView reloadData];
        }
    }
}


- (void)didRequestFollowNotification:(NSNotification *)note {
    NSString *userToken = (NSString *)[note object];
    for (int i = 0; i < self.memories.count; i++) {
        Memory *memory = self.memories[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusRequested;
        }
    }
}

- (void)didFollowNotification:(NSNotification *)note {
    NSString *userToken = (NSString *)[note object];
    for (int i = 0; i < self.memories.count; i++) {
        Memory *memory = self.memories[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusFollowing;
        }
    }
}

- (void)didUnfollowNotification:(NSNotification *)note {
    NSString *userToken = (NSString *)[note object];
    for (int i = 0; i < self.memories.count; i++) {
        Memory *memory = self.memories[i];
        if ([memory.author.userToken isEqualToString:userToken]) {
            memory.author.followingStatus = FollowingStatusNotFollowing;
        }
    }
}



#pragma mark - Image caching

- (void)updatePrefetchQueueWithMemAtIndex {
    if (self.currentPrefetchIndex < self.memories.count) {
        //get the next visible memory
        Memory *tempMem = self.memories[self.currentPrefetchIndex];
        
        if (![self.prefetchedList containsObject:@(tempMem.recordID)]) {
            [self.prefetchedList addObject:@(tempMem.recordID)];
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
            
            //get (up to 2) assets for each memory
            if (tempMem.type == MemoryTypeImage) {
                ImageMemory *tempImgMem = (ImageMemory *)tempMem;
                
                int maxStart = (int)tempImgMem.images.count - 1;
                if (maxStart > 1) {
                    maxStart = 1;
                }
                
                //insert assets into queue so the visible image loads first for multi-asset mems
                for (int i = maxStart; i >= 0; i--) {
                    [tempArray insertObject:tempImgMem.images[i] atIndex:0];
                }
                self.assetQueue = [NSArray arrayWithArray:tempArray];
                [self prefetchNextImageInQueue];
            }
            else if (tempMem.type == MemoryTypeVideo) {
                
                VideoMemory *tempImgMem = (VideoMemory *)tempMem;
                
                int maxStart = (int)tempImgMem.previewImages.count - 1;
                if (maxStart > 1) {
                    maxStart = 1;
                }
                
                for (int i = maxStart; i >= 0; i--) {
                    [tempArray insertObject:tempImgMem.previewImages[i] atIndex:0];
                }
                self.assetQueue = [NSArray arrayWithArray:tempArray];
                [self prefetchNextImageInQueue];
            }
            else {
                //NSLog(@"skip forward past non image/vid mem");
                //go further ahead in the list if it's not a mem that needs prefetching
                self.currentPrefetchIndex = self.currentPrefetchIndex + 1;
                [self updatePrefetchQueueWithMemAtIndex];
            }
        }
        //go further ahead in the list if it's a mem that's already been prefetched
        else {
            if (self.currentPrefetchIndex < self.memories.count) {
                //NSLog(@"skip forward past previously fetched assets");
                self.currentPrefetchIndex = self.currentPrefetchIndex + 1;
                [self updatePrefetchQueueWithMemAtIndex];
            }
        }
    }
}

- (void)prefetchNextImageInQueue {
    if (self.prefetchPaused) {
        return;
    }
    
    if (self.assetQueue.count > 0) {
        
        NSString *imageUrlStr;
        NSString *imageName;
        
        id imageAsset = self.assetQueue[0];
        if ([imageAsset isKindOfClass:[Asset class]]) {
            Asset * asset = (Asset *)imageAsset;
            imageUrlStr = [asset imageUrlSquare];
        } else {
            imageName = [NSString stringWithFormat:@"%@", self.assetQueue[0]];
            int photoID = [imageName intValue];
            imageUrlStr = [APIUtils imageUrlStringForAssetId:photoID size:ImageCacheSizeSquare];
        }
        
        BOOL imageIsCached = NO;
        
        if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        
        if (!imageIsCached) {
            [self.prefetchImageView sd_cancelCurrentImageLoad];
            [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
                                                 [tempArray removeObject:imageAsset];
                                                 self.assetQueue = [NSArray arrayWithArray:tempArray];
                                                 [self prefetchNextImageInQueue];
                                             }];
        }
        else {
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetQueue];
            [tempArray removeObject:imageAsset];
            self.assetQueue = [NSArray arrayWithArray:tempArray];
            [self prefetchNextImageInQueue];
        }
    }
    else {
        if (self.currentPrefetchIndex < self.memories.count) {
            self.currentPrefetchIndex = self.currentPrefetchIndex + 1;
            [self updatePrefetchQueueWithMemAtIndex];
        }
    }
}

#pragma mark - SPCPullToRefreshManagerDelegate

- (void)pullToRefreshTriggered:(SPCPullToRefreshManager *)manager {
    [Flurry logEvent:@"PTR_FEED"];
    self.pullToRefreshStarted = YES;
    [self fetchMemories];
}

#pragma mark SPCMapViewController

- (void)cancelMap {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didAdjustLocationForMemory:(Memory *)memory {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark SPCAdjustMemoryLocationViewControllerDelegate

-(void)didAdjustLocationForMemory:(Memory *)memory withViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismissAdjustMemoryLocationViewController:(UIViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark SPCTagFriendsViewControllerDelegate

- (void)tagFriendsViewController:(SPCTagFriendsViewController *)viewController finishedPickingFriends:(NSArray *)selectedFriends {
    [self.memoryCoordinator updateMemory:viewController.memory taggedUsers:viewController.memory.taggedUsersIDs completionHandler:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCMemoryUpdated object:viewController.memory];
    }];
    [self reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tagFriendsViewControllerDidCancel:(SPCTagFriendsViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SPCReportAlertViewDelegate

- (void)tappedOption:(NSString *)option onSPCReportAlertView:(SPCReportAlertView *)reportView {
    if ([reportView isEqual:self.reportAlertView]) {
        self.reportType = [self.reportMemoryOptions indexOfObject:option] + 1;
        
        [reportView hideAnimated:YES];
        
        // Now, we need to show an alert view asking the user if they want to "Add Detail" or "Send"
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send Report Immediately?" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add Detail", @"Send", nil];
        alertView.tag = alertViewTagReport;
        [alertView show];
        
        self.reportAlertView = nil;
    }
}

- (void)tappedDismissTitle:(NSString *)dismissTitle onSPCReportAlertView:(SPCReportAlertView *)reportView {
    // We only have one dismiss option, so go ahead and remove the view
    [self.reportAlertView hideAnimated:YES];
    
    self.reportAlertView = nil;
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == alertViewTagTwitter) {
            AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeTwitter viewController:appDelegate.mainViewController.customTabBarController completionHandler:^{
                [self shareMemory:self.tempMemory serviceName:@"TWITTER" serviceType:SocialServiceTypeTwitter];
                self.tempMemory = nil;
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        }
        else if (alertView.tag == alertViewTagFacebook) {
            [[SocialService sharedInstance] authSocialServiceType:SocialServiceTypeFacebook viewController:nil completionHandler:^{
                [self shareMemory:self.tempMemory serviceName:@"FACEBOOK" serviceType:SocialServiceTypeFacebook];
                self.tempMemory = nil;
            } errorHandler:^(NSError *error) {
                [UIAlertView showError:error];
            }];
        } else if (alertView.tag == alertViewTagReport) {
            // These buttons were configured so that buttonIndex 1 = 'Send', buttonIndex 0 = 'Add Detail'
            if (1 == buttonIndex) {
                [Flurry logEvent:@"MEM_REPORTED"];
                [self.memoryCoordinator reportMemory:self.tempMemory withType:self.reportType text:nil completionHandler:^(BOOL success) {
                    if (success) {
                        [self showMemoryReportWithSuccess:YES];
                    } else {
                        [self showMemoryReportWithSuccess:NO];
                    }
                    self.tempMemory = nil;
                }];
            } else if (0 == buttonIndex) {
                SPCReportViewController *rvc = [[SPCReportViewController alloc] initWithReportObject:self.tempMemory reportType:self.reportType andDelegate:self];
                [self.navigationController pushViewController:rvc animated:YES];
            }
        }
    }
}

#pragma mark - SPCReportViewControllerDelegate

- (void)invalidReportObjectOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:NO];
}

- (void)canceledReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
}

- (void)sendFailedOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:NO];
}

- (void)sentReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showMemoryReportWithSuccess:YES];
}

#pragma mark - Report/Flagging Results

- (void)showMemoryReportWithSuccess:(BOOL)succeeded {
    if (succeeded) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"This memory has been reported. Thank you.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"Error reporting issue. Please try again later.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    }
}

#pragma mark SPCAdminSockPuppetChooserViewControllerDelegate

- (void)adminSockPuppetChooserViewController:(UIViewController *)vc didChoosePuppet:(Person *)puppet forAction:(SPCAdminSockPuppetAction)action object:(NSObject *)object {
    
    [self.navigationController popViewControllerAnimated:YES];
    
    switch(action) {
        case SPCAdminSockPuppetActionStar:
            NSLog(@"Star action as %@", puppet.firstname);
            [self addStarForMemory:(Memory *)object button:nil sockpuppet:puppet];
            break;
            
        case SPCAdminSockPuppetActionUnstar:
            NSLog(@"Unstar action as %@", puppet.firstname);
            [self removeStarForMemory:(Memory *)object button:nil sockpuppet:puppet];
            break;
            
        default:
            NSLog(@"WOULD HAVE perfomed action %d with sock puppet %@", action, puppet.firstname);
            break;
    }
}

- (void)adminSockPuppetChooserViewControllerDidCancel:(UIViewController *)vc {
    [self.navigationController popViewControllerAnimated:YES];
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

@end
