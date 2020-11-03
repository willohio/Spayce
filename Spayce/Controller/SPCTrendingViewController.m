//
//  SPCTrendingViewController.m
//  Spayce
//
//  Created by Jake Rosin on 7/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTrendingViewController.h"

// View
#import "SPCTrendingVenueCell.h"
#import "SPCInSpaceView.h"
#import "UIImageView+WebCache.h"

// Controller
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"

// Category
#import "UIViewController+SPCAdditions.h"

// Manager
#import "LocationContentManager.h"
#import "LocationManager.h"
#import "VenueManager.h"

// Category
#import "UITabBarController+SPCAdditions.h"

// Model
#import "Asset.h"
#import "Memory.h"


static NSString * CellIdentifier = @"SPCTrendingVenueCell";

static NSTimeInterval VENUES_STALE_AFTER = 60;  // 1 minute
static NSTimeInterval CURRENT_LOCATION_STALE_AFTER = 600;   // 10 minutes
static NSTimeInterval CYCLE_IMAGE_EVERY = 3.0f;        // 3 seconds (w/ 6 venues, each lasts 18 seconds)
static NSTimeInterval FIRST_IMAGE_CYCLE_AFTER_AT_LEAST = 2.0f;

@interface SPCTrendingViewController() {
    NSTimeInterval _fetchStartedAt;
}


@property (nonatomic, strong) NSArray * localVenues;
@property (nonatomic, strong) NSArray * globalVenues;
@property (nonatomic, strong) Venue * currentVenue;    // used only for country.  Probably doesn't need to be refreshed often...
@property (nonatomic, assign) NSTimeInterval localVenuesUpdatedAt;
@property (nonatomic, assign) NSTimeInterval globalVenuesUpdatedAt;
@property (nonatomic, assign) NSTimeInterval currentVenueUpdatedAt;

@property (nonatomic, strong) UIView * scopeControls;
@property (nonatomic, strong) UIView *localEmptyView;
@property (nonatomic, strong) UIView *globalEmptyView;
@property (nonatomic, strong) SPCInSpaceView *locationOffView;

@property (nonatomic, assign) BOOL isLocalSelected;
@property (nonatomic, readonly) NSArray * venues;
@property (nonatomic, readonly) NSTimeInterval venuesUpdatedAt;

@property (nonatomic, assign) BOOL fetchOngoing;
@property (nonatomic, assign) BOOL hasFetched;
@property (nonatomic, assign) BOOL hasAppeared;
@property (nonatomic, assign) BOOL viewIsVisible;

// image cycling
@property (nonatomic, strong) NSTimer * cycleImageTimer;
@property (nonatomic, assign) NSInteger cycleImageLastCellCycled;
@property (nonatomic, strong) NSMutableArray * cycleCells;

// image prefetching
@property (nonatomic, strong) NSArray *prefetchAssetQueue;
@property (nonatomic, assign) BOOL prefetchOngoing;

// nothing trending...
@property (nonatomic, strong) UIImageView *arrowImgView;
@property (nonatomic, strong) UIButton * localButton;
@property (nonatomic, strong) UIButton * globalButton;

@property (nonatomic, strong) UIImageView *prefetchImageView;


@end

@implementation SPCTrendingViewController

-(void)dealloc {
    
    // Cancel any previous requests that were set to execute on a delay!!
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.scopeControls];
    [self.view addSubview:self.collectionView];
    
    [self.view addSubview:self.localEmptyView];
    [self.view addSubview:self.globalEmptyView];
    [self.view addSubview:self.locationOffView];
    
    self.localEmptyView.hidden = YES;
    self.globalEmptyView.hidden = YES;
    self.locationOffView.hidden = YES;
    
    self.arrowImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow-down-green"]];
    self.arrowImgView.hidden = YES;
    [self.view addSubview:self.arrowImgView];
    
    self.isLocalSelected = _isLocalSelected;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchStaleContent) name:kLocationServicesAuthorizationStatusWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchStaleContent) name:kLocationServicesAuthorizationStatusDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchStaleContent) name: UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    self.collectionView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), self.collectionView.superview.frame.size.height);
 
    //restart the animation if needed
    [self.locationOffView restartAnimation];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    BOOL hadAppeared = self.hasAppeared;
    self.hasAppeared = YES;
    
    if (!self.hasFetched) {
        [self fetchTrendingVenues];
    } else if (hadAppeared) {
        [self fetchStaleContent];
    } else if (!self.fetchOngoing) {
        [self reloadData];
        [self fetchStaleContent];
    }
    
    if (!self.viewIsVisible) {
        self.viewIsVisible = YES;
        self.cycleImageTimer = [NSTimer scheduledTimerWithTimeInterval:CYCLE_IMAGE_EVERY target:self selector:@selector(cycleImage) userInfo:nil repeats:YES];
    }
    
    [self.locationOffView restartAnimation];
    [self performSelector:@selector(revealTab) withObject:nil afterDelay:1];
    [self animateArrow];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.viewIsVisible = NO;
    [self.cycleImageTimer invalidate];
}


-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
    //[self.locationOffView endAnimation];
}

- (void)fetchStaleContent {
 
    if (self.isLocalSelected) {
        if ([CLLocationManager locationServicesEnabled] &&
            ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            [self.locationOffView promptForOptimizing];
            [self.locationOffView restartAnimation];
        }
    }
    
    if ([self localVenuesAreStale] && [self globalVenuesAreStale]) {
        [self fetchTrendingVenues];
    } else if ([self localVenuesAreStale]) {
        [self fetchLocalTrendingThenGlobal:NO];
    } else if ([self globalVenuesAreStale]) {
        [self fetchGlobalTrendingThenLocal:NO];
    }
}

- (void)animateArrow {
    if (_arrowImgView) {
        _arrowImgView.center = CGPointMake(CGRectGetWidth(self.view.frame)/2+2, CGRectGetHeight(self.view.frame)-67-12);
        [UIView animateWithDuration:1.6
                              delay:0.0
                            options: UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                         animations:^{
                             _arrowImgView.center = CGPointMake(_arrowImgView.center.x, _arrowImgView.center.y+16);
                         }
                         completion:NULL];
    }
}

- (void)revealTab {
    if (self.viewIsVisible){
        [self.tabBarController setTabBarHidden:NO];
   }
}



#pragma mark - Setters

- (void)setPrefetchPaused:(BOOL)prefetchPaused {
    if (_prefetchPaused != prefetchPaused) {
        _prefetchPaused = prefetchPaused;
        
        if (!prefetchPaused) {
            // restart image downloads?
            if (self.prefetchAssetQueue.count > 0) {
                [self prefetchNextAsset];
            }
        }
    }
}


#pragma mark - Accessors

-(BOOL)hasContent {
    return self.hasFetched;
}


-(BOOL)fetchOngoing {
    return [[NSDate date] timeIntervalSince1970] - _fetchStartedAt < 60;
}

-(void)setFetchOngoing:(BOOL)fetchOngoing {
    if (!fetchOngoing) {
        _fetchStartedAt = 0;
    } else {
        _fetchStartedAt = [[NSDate date] timeIntervalSince1970];
    }
}

-(NSMutableArray *)cycleCells {
    if (!_cycleCells) {
        _cycleCells = [[NSMutableArray alloc] init];
    }
    return _cycleCells;
}

-(UIView *) scopeControls {
    if (!_scopeControls) {
        
        UIColor *buttonTitleColorSelected = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        UIColor *buttonTitleColorNormal = [UIColor lightGrayColor];
        UIColor *buttonBackgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:0.95f];
        
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 35.0)];
        view.backgroundColor = [UIColor clearColor];
        
        UIButton * localButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame)/2.0, 35.0)];
        
        
        
        [localButton setTitleColor:buttonTitleColorNormal forState:UIControlStateNormal];
        [localButton setTitleColor:buttonTitleColorSelected forState:UIControlStateSelected];
        [localButton setTitle:@"LOCAL" forState:UIControlStateNormal];
        [localButton addTarget:self action:@selector(switchToLocal:) forControlEvents:UIControlEventTouchUpInside];
        [localButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:11]];
        localButton.backgroundColor = buttonBackgroundColor;
        
        UIButton * globalButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)/2.0, 0.0, CGRectGetWidth(self.view.frame)/2.0, 35.0)];
        [globalButton setTitleColor:buttonTitleColorNormal forState:UIControlStateNormal];
        [globalButton setTitleColor:buttonTitleColorSelected forState:UIControlStateSelected];
        [globalButton setTitle:@"WORLD" forState:UIControlStateNormal];
        [globalButton addTarget:self action:@selector(switchToGlobal:) forControlEvents:UIControlEventTouchUpInside];
        [globalButton.titleLabel setFont:[UIFont spc_regularSystemFontOfSize:11]];
        globalButton.backgroundColor = buttonBackgroundColor;
        
        [view addSubview:localButton];
        [view addSubview:globalButton];
        
        _scopeControls = view;
        _localButton = localButton;
        _globalButton = globalButton;
    }
    return _scopeControls;
}

-(UICollectionView *) collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        layout.minimumInteritemSpacing = 2;
        layout.minimumLineSpacing = 2;
        layout.itemSize = CGSizeMake(self.view.bounds.size.width/2.0f -1, self.view.bounds.size.width/2.0f - 1 );
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        _collectionView.allowsMultipleSelection = NO;
        
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = [UIColor colorWithRGBHex:0xf0f1f1];
        [_collectionView registerClass:[SPCTrendingVenueCell class] forCellWithReuseIdentifier:CellIdentifier];
    }
    return _collectionView;
}

-(UIView *) localEmptyView {
    if (!_localEmptyView) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(40, CGRectGetMaxY(self.scopeControls.frame), self.view.bounds.size.width - 80, self.view.bounds.size.height - CGRectGetHeight(self.scopeControls.frame) - 88.0f - 23.0 - 60.0)];
        label.text = @"It's quiet here.  Make a memory to get things started!";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        label.font = [UIFont spc_titleFont];
        label.numberOfLines = NSIntegerMax;
        
        _localEmptyView = label;
    }
    return _localEmptyView;
}

-(UIView *) globalEmptyView {
    if (!_globalEmptyView) {
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(40, CGRectGetMaxY(self.scopeControls.frame), self.view.bounds.size.width - 80, self.view.bounds.size.height - CGRectGetHeight(self.scopeControls.frame) - 88.0f - 23.0 - 60.0)];
        label.text = @"Nothing is trending.  Now's the perfect time to make a memory!";
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        label.font = [UIFont spc_titleFont];
        label.numberOfLines = NSIntegerMax;
        
        _globalEmptyView = label;
    }
    return _globalEmptyView;
}


-(SPCInSpaceView *) locationOffView {
    if (!_locationOffView) {
        _locationOffView = [[SPCInSpaceView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.scopeControls.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetHeight(self.scopeControls.frame) - CGRectGetHeight(self.tabBarController.tabBar.frame)-64)];
        _locationOffView.backgroundColor = [UIColor colorWithRed:64.0f/255.0f green:86.0f/255.0f blue:122.0f/255.0f alpha:1.0f];
        _locationOffView.clipsToBounds = YES;
    }
    return _locationOffView;
}


- (NSArray *)prefetchAssetQueue {
    if (!_prefetchAssetQueue) {
        _prefetchAssetQueue = [NSArray array];
    }
    return _prefetchAssetQueue;
}


-(NSArray *)venues {
    if (self.isLocalSelected) {
        return self.localVenues;
    } else {
        return self.globalVenues;
    }
}

-(NSTimeInterval)venuesUpdatedAt {
    return self.isLocalSelected ? self.localVenuesUpdatedAt : self.globalVenuesUpdatedAt;
}

-(BOOL)localVenuesAreStale {
    return self.localVenuesUpdatedAt + VENUES_STALE_AFTER < [[NSDate date] timeIntervalSince1970];
}

-(BOOL)globalVenuesAreStale {
    return self.globalVenuesUpdatedAt + VENUES_STALE_AFTER < [[NSDate date] timeIntervalSince1970];
}

-(BOOL)currentLocationStale {
    return self.currentVenueUpdatedAt + CURRENT_LOCATION_STALE_AFTER < [[NSDate date] timeIntervalSince1970];
}

- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}

#pragma mark - switching tabs

-(void)switchToLocal:(id)sender {
    self.isLocalSelected = YES;
}

-(void)switchToGlobal:(id)sender {
    self.isLocalSelected = NO;
}

-(void)setIsLocalSelected:(BOOL)isLocalSelected {
    BOOL changed = _isLocalSelected != isLocalSelected;
    _isLocalSelected = isLocalSelected;
    if (isLocalSelected) {
        if (self.hasFetched && changed) {
            [self reloadData];
        }
        
        [self.localButton setSelected:YES];
        [self.globalButton setSelected:NO];
        
        if (self.hasFetched && [self localVenuesAreStale] && self.viewIsVisible) {
            [self fetchLocalTrendingThenGlobal:NO];
        }
    } else {
        if (self.hasFetched && changed) {
            [self reloadData];
        }
        
        [self.localButton setSelected:NO];
        [self.globalButton setSelected:YES];
        
        if (self.hasFetched && [self globalVenuesAreStale] && self.viewIsVisible) {
            [self fetchGlobalTrendingThenLocal:NO];
        }
    }
}


#pragma mark - Retrieve trending data

- (void)prefetchContent {
    if (!self.hasFetched) {
        [self fetchTrendingVenues];
    }
}

-(void)fetchTrendingVenues {
    self.hasFetched = YES;
    if (self.isLocalSelected) {
        // fetch locally first
        [self fetchLocalTrendingThenGlobal:YES];
    } else {
        // fetch globally first
        [self fetchGlobalTrendingThenLocal:YES];
    }
}

-(void)fetchLocalTrendingThenGlobal:(BOOL)fetchGlobalAfter {
    if (self.fetchOngoing) {
        return;
    }
    if (![self localVenuesAreStale]) {
        if (fetchGlobalAfter) {
            [self fetchGlobalTrendingThenLocal:NO];
        }
        return;
    }
    
    if (!self.currentVenue || [self currentLocationStale]) {
        if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            __weak typeof(self)weakSelf = self;
            self.fetchOngoing = YES;
            [[LocationContentManager sharedInstance] getUncachedContent:@[SPCLocationContentVenue] resultCallback:^(NSDictionary *results) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.currentVenue = results[SPCLocationContentVenue];
                strongSelf.currentVenueUpdatedAt = [[NSDate date] timeIntervalSince1970];
                strongSelf.fetchOngoing = NO;
                if (strongSelf.currentVenue) {
                    [strongSelf fetchLocalTrendingThenGlobal:fetchGlobalAfter];
                }
            } faultCallback:^(NSError *fault) {
                // whelp, not much else to do.
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.fetchOngoing = NO;
                if (fetchGlobalAfter) {
                    [strongSelf fetchGlobalTrendingThenLocal:NO];
                }
            }];
        }
        return;
    }
    
    if (self.isLocalSelected) {
        [self spc_hideNotificationBanner];
    }
    
    __weak typeof(self)weakSelf = self;
    self.fetchOngoing = YES;
    [[VenueManager sharedInstance] fetchTrendingVenuesNearbyWithCurrentVenue:self.currentVenue resultCallback:^(NSArray *venues) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        BOOL changed = ![strongSelf venueList:venues isEquivalentTo:strongSelf.localVenues];
        strongSelf.localVenues = venues;
        strongSelf.localVenuesUpdatedAt = [[NSDate date] timeIntervalSince1970];
        if (changed) {
            [self addVenuesForPrefetching:venues];
            [self prefetchNextAsset];
        }
        if (strongSelf.isLocalSelected && changed) {
            [strongSelf reloadData];
        }
        
        strongSelf.fetchOngoing = NO;
        
        if (fetchGlobalAfter) {
            [strongSelf fetchGlobalTrendingThenLocal:NO];
        }
    } faultCallback:^(NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        strongSelf.fetchOngoing = NO;
        
        // Show error notification
        if (self.isLocalSelected) {
            [strongSelf spc_showNotificationBannerInParentView:strongSelf.collectionView title:NSLocalizedString(@"Couldn't Refresh Trending", nil) error:error];
        }
    }];
    
}

-(void)fetchGlobalTrendingThenLocal:(BOOL)fetchLocalAfter {
    if (self.fetchOngoing) {
        return;
    }
    if (![self globalVenuesAreStale]) {
        if (fetchLocalAfter) {
            [self fetchLocalTrendingThenGlobal:NO];
        }
        return;
    }
    
    if (!self.isLocalSelected) {
        [self spc_hideNotificationBanner];
    }
    
    __weak typeof(self)weakSelf = self;
    self.fetchOngoing = YES;
    [[VenueManager sharedInstance] fetchTrendingVenuesForWorldWithResultCallback:^(NSArray *venues) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        BOOL changed = ![strongSelf venueList:venues isEquivalentTo:strongSelf.globalVenues];
        strongSelf.globalVenues = venues;
        strongSelf.globalVenuesUpdatedAt = [[NSDate date] timeIntervalSince1970];
        if (changed) {
            [self addVenuesForPrefetching:venues];
            [self prefetchNextAsset];
        }
        if (!strongSelf.isLocalSelected && changed) {
            [strongSelf reloadData];
        }
        
        strongSelf.fetchOngoing = NO;
        
        if (fetchLocalAfter) {
            [strongSelf fetchLocalTrendingThenGlobal:NO];
        }
    } faultCallback:^(NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        
        strongSelf.fetchOngoing = NO;
        
        // Show error notification
        if (!self.isLocalSelected) {
            [strongSelf spc_showNotificationBannerInParentView:strongSelf.collectionView title:NSLocalizedString(@"Couldn't Refresh Trending", nil) error:error];
        }
    }];
}


-(BOOL) venueList:(NSArray *)venueList1 isEquivalentTo:(NSArray *)venueList2 {
    BOOL same = venueList1.count == venueList2.count;
    for (int i = 0; i < venueList1.count && same; i++) {
        same = same && [SPCTrendingVenueCell venue:venueList1[i] isEquivalentTo:venueList2[i]];
    }
    return same;
}


-(BOOL) memoryList:(NSArray *)memoryList1 isEquivalentTo:(NSArray *)memoryList2 {
    BOOL same = memoryList1.count == memoryList2.count;
    for (int i = 0; i < memoryList1.count && same; i++) {
        same = same && [SPCTrendingVenueCell memory:memoryList1[i] isEquivalentTo:memoryList2[i]];
    }
    return same;
}


-(void) reloadData {
    if (!self.hasAppeared) {
        return;
    }
    BOOL collectionVisible = !self.collectionView.hidden;
    if (self.venues && self.venues.count > 0) {
        self.collectionView.hidden = NO;
        self.localEmptyView.hidden = YES;
        self.globalEmptyView.hidden = YES;
        self.arrowImgView.hidden = YES;
        self.locationOffView.hidden = YES;
        //[self.locationOffView endAnimation];
    } else if (self.venuesUpdatedAt > 0) {
        self.collectionView.hidden = YES;
        self.localEmptyView.hidden = !self.isLocalSelected;
        self.globalEmptyView.hidden = self.isLocalSelected;
        self.arrowImgView.hidden = NO;
        self.locationOffView.hidden = YES;
        //[self.locationOffView endAnimation];
        if (collectionVisible) {
            [self animateArrow];
        }
    } else if (self.isLocalSelected &&
               (![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied)) {
        self.collectionView.hidden = YES;
        self.localEmptyView.hidden = YES;
        self.globalEmptyView.hidden = YES;
        self.arrowImgView.hidden = YES;
        [self.locationOffView promptForTrending];
        [self.locationOffView restartAnimation];
        self.locationOffView.hidden = NO;
    } else {
        self.collectionView.hidden = NO;
        self.localEmptyView.hidden = YES;
        self.globalEmptyView.hidden = YES;
        self.arrowImgView.hidden = YES;
        self.locationOffView.hidden = YES;
        //[self.locationOffView endAnimation];
    }
    [self.collectionView reloadData];
}

-(void) cycleImage {
    if (!self.viewIsVisible) {
        return;
    }
    
    if (self.venuesUpdatedAt + FIRST_IMAGE_CYCLE_AFTER_AT_LEAST > [[NSDate date] timeIntervalSince1970]) {
        return;
    }
    
    // Find the next cell to cycle.
    SPCTrendingVenueCell * cell;
    self.cycleImageLastCellCycled++;
    while (self.cycleCells.count > 0) {
        cell = self.cycleCells[self.cycleImageLastCellCycled % self.cycleCells.count];
        if (cell.isConfigured) {
            [cell cycleImageAnimated:YES];
            return;
        } else {
            // an unconfigured cell?  remove.
            [self.cycleCells removeObject:cell];
        }
    }
}

- (void)promptEnableLocationServices:(id)sender {
    if ([CLLocationManager locationServicesEnabled] &&
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServicesAuthorizationStatusWillChangeNotification object:nil];
        [[LocationManager sharedInstance] enableLocationServicesWithCompletionHandler:^(NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServicesAuthorizationStatusDidChangeNotification object:nil];
        }];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"\"Spayce\" Would Like to Use Your Current Location", nil)
                                    message:NSLocalizedString(@"Please go to Settings > Privacy and enable Location Services for the \"Spayce\" app", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.venues && self.venues.count > 0) {
        return self.venues.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCTrendingVenueCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    // frame.
    CGFloat width = self.collectionView.frame.size.width/2.0f - 1.0f;
    CGRect frame = cell.frame;
    cell.frame = CGRectMake(frame.origin.x, frame.origin.y, width, width);
    
    Venue * venue = self.venues[indexPath.row];
    
    [cell configureWithVenue:venue isLocal:self.isLocalSelected];
    if (![self.cycleCells containsObject:cell]) {
        // insert at a random position (so our image cycling doesn't go in order)
        int r = arc4random() % (self.cycleCells.count + 1);
        [self.cycleCells insertObject:cell atIndex:r];
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // Deselect cell
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    // Push venue feed
    Venue * venue = self.venues[indexPath.row];
    
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = venue;

    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;

    
    [self presentViewController:navController animated:YES completion:nil];
}



#pragma mark - Prefetching images

- (void)addMemoriesForPrefetching:(NSArray *)memories {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
    for (Memory *memory in memories) {
        
        Asset *asset = [self assetForMemory:memory];
        if (asset) {
            [tempArray addObject:asset];
        }
    }
    self.prefetchAssetQueue = [NSArray arrayWithArray:tempArray];
}

- (void)addVenuesForPrefetching:(NSArray *)venues {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
    for (Venue *venue in venues) {
        Asset *asset = [self assetForVenue:venue];
        if (asset) {
            [tempArray addObject:asset];
        }
    }
    self.prefetchAssetQueue = [NSArray arrayWithArray:tempArray];
}

- (Asset *)assetForMemory:(Memory *)memory {
    // attempt a memory first...
    if ([memory isKindOfClass:[ImageMemory class]]) {
        ImageMemory *imageMemory = (ImageMemory *)memory;
        if (imageMemory.images.count > 0) {
            return imageMemory.images[0];
        }
    } else if ([memory isKindOfClass:[VideoMemory class]]) {
        //NSLog(@"VIDeo mem?");
        VideoMemory *videoMemory = (VideoMemory *)memory;
        if (videoMemory.previewImages.count > 0) {
            return videoMemory.previewImages[0];
        }
    }
    
    return memory.locationMainPhotoAsset;
}

- (Asset *)assetForVenue:(Venue *)venue {
    // attempt a memory first...
    if (venue.popularMemories.count > 0) {
        for (Memory *memory in venue.popularMemories) {
            if ([memory isKindOfClass:[ImageMemory class]]) {
                ImageMemory *imageMemory = (ImageMemory *)memory;
                if (imageMemory.images.count > 0) {
                    return imageMemory.images[0];
                }
            } else if ([memory isKindOfClass:[VideoMemory class]]) {
                //NSLog(@"VIDeo mem?");
                VideoMemory *videoMemory = (VideoMemory *)memory;
                if (videoMemory.previewImages.count > 0) {
                    return videoMemory.previewImages[0];
                }
            }
        }
    }
    
    return venue.imageAsset;
}


- (void)prefetchNextAsset {
    if (self.prefetchPaused || self.prefetchOngoing) {
        return;
    }
    
    NSMutableArray *assets = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
    if (assets.count > 0) {
        Asset *asset = assets[0];
        [assets removeObjectAtIndex:0];
        self.prefetchAssetQueue = [NSArray arrayWithArray:assets];
        
        BOOL imageIsCached = NO;
        
        NSString *imageUrlStr = asset.imageUrlHalfSquare;
        if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:imageUrlStr]]) {
            imageIsCached = YES;
        }
        
        if (!imageIsCached) {
            self.prefetchOngoing = YES;
            [self.prefetchImageView sd_cancelCurrentImageLoad];
            [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 if (image) {
                                                     self.prefetchOngoing = NO;
                                                     [self prefetchNextAsset];
                                                 } else {
                                                     self.prefetchOngoing = NO;
                                                     NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.prefetchAssetQueue];
                                                     [tempArray addObject:asset];
                                                     self.prefetchAssetQueue = [NSArray arrayWithArray:tempArray];
                                                     [self prefetchNextAsset];
                                                 }
                                             }];
        }
        else {
            [self prefetchNextAsset];
        }
    }
}


@end
