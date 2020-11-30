//
//  SPCHereFeedViewController.m
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereFeedViewController.h"

// Model
#import "ShadowedLabel.h"
#import "SPCFeaturedContent.h"
#import "SPCHereDataSource.h"
#import "SPCVenueTypes.h"
#import "Asset.h"

// View
#import "CoachMarks.h"
#import "MemoryCell.h"
#import "SPCFeaturedContentCell.h"
#import "SPCTableView.h"
#import "SPCView.h"
#import "SPCVenueDetailsCollectionViewCell.h"
#import "SPCInSpaceView.h"
#import "LLARingSpinnerView.h"

// Controller
#import "SPCCustomNavigationController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCHereViewController.h"

// Category
#import "NSString+SPCAdditions.h"
#import "UIScreen+Size.h"
#import "UIImageView+WebCache.h"

// Manager
#import "LocationManager.h"
#import "MeetManager.h"


static NSString *spcFeaturedContentCellIdentifier = @"SPCFeaturedContentCell";
static NSString *spcVenueDetailsCelldentifier = @"SPCVenueDetailsCell";

@interface SPCHereFeedViewController  () <UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate> {
    int currVenueIndex;
    int velocityMultiplier;
}

@property (nonatomic, strong) SPCTableView *tableView;
@property (nonatomic, strong) UICollectionView *featuredView;
@property (nonatomic, strong) UICollectionView *oylFeaturedView;
@property (nonatomic, strong) UICollectionView *oylVenueDetailCollectionView;

@property (nonatomic, strong) UIView *locationDeterminingView;
@property (nonatomic, strong) UIView *locationOffView;
@property (nonatomic, strong) UIView *locationLoadingMemoriesView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, assign) CGFloat tableHeaderOpaqueHeight;


@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) NSArray *featuredContent;
@property (nonatomic, strong) NSArray *oylContent;
@property (nonatomic, strong) NSArray *preppedContent;
@property (nonatomic, strong) NSArray *nearbyVenuesProvided;
@property (nonatomic, strong) NSArray *memoriesProvided;
@property (nonatomic, strong) NSArray *featuredContentProvided;
@property (nonatomic, strong) UICollectionView *venueDetailCollectionView;
@property (nonatomic, strong) UIView *venueInfoView;
@property (nonatomic, strong) UIView *venueInfoBackgroundView;
@property (nonatomic, strong) UIView *venueInfoBackgroundViewNoLocation;
@property (nonatomic, strong) CAGradientLayer *venueInfoBackgroundLayer;
@property (nonatomic, strong) CAGradientLayer *venueInfoBackgroundLayerNoLocation;
@property (nonatomic, strong) UIImageView *venueCompassArrowImageView;
@property (nonatomic, assign) BOOL venueCompassAnimating;
@property (nonatomic, assign) NSInteger maxMemoryIndexViewed;
@property (nonatomic, assign) NSInteger maxFeaturedIndexView;
@property (nonatomic, assign) CGFloat transparentPixelsAtTop;
@property (nonatomic, strong) UIButton *enterButton;
@property (nonatomic, strong) UIView *featuredOverlay;
@property (nonatomic, strong) UILabel *cityNameLabel;
@property (nonatomic, strong) UIView *featuredInfoContainer;
@property (nonatomic, assign) CGFloat resetOffset;
@property (nonatomic, assign) BOOL swipeInProgress;
@property (nonatomic, assign) BOOL snapInProgress;
@property (nonatomic, assign) BOOL animatingVenue;
@property (nonatomic, assign) BOOL extendedAnimationInProgress;
@property (nonatomic, assign) BOOL animationInProgress;

@property (nonatomic, strong) UIView *gestureContainer;

@property (nonatomic, strong) UIImageView *prefetchImageView;
@property (nonatomic, strong) NSArray *assetsQueue;
@property (nonatomic, assign) BOOL prefetchPaused;
@property (nonatomic, assign) BOOL draggingFeatured;

@property (nonatomic, strong) SPCInSpaceView *spaceView;
@property (nonatomic, strong) UIView *fullOverlay;

@property (nonatomic, assign) BOOL contentUpdated;
@property (nonatomic, assign) BOOL refreshInProgress;
@property (nonatomic, assign) BOOL displayingLocationContent;
@property (nonatomic, assign) BOOL readyToEndOYL;


@end

@implementation SPCHereFeedViewController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self unregisterFromNotifications];
}
#pragma mark - UIViewController - Managing the View

- (void)loadView {
    // gets the default frame
    
    [super loadView];
    // a custom view, allowing us to disregard touches in the top untouchableContentHeight pixels
    // of the table view.
    SPCView * mainView = [[SPCView alloc] initWithFrame:self.view.frame];
    mainView.pointInsideBlock = ^BOOL(CGPoint point, UIEvent * event) {
        if (self.spayceState != SpayceStateDisplayingLocationData) {
            return YES;
        }
        else {
            CGPoint pointInTableView = [_tableView convertPoint:point fromView:self.view];
            return [_tableView pointInside:pointInTableView withEvent:event];
        }
    };
    self.view = mainView;
    
    
    // the StatusBarBackground allows our table to span the full `een (including
    // status bar) without the header view (filter switch) sliding under the status
    // bar.  We set a content inset at the top of 20 (so the header pins just below
    // the status bar) and show / hide this status bar background as needed, based
    // on the position of the TableHeader.  We register for Notifications from
    // the SPCHere data source to detect the header moving on or off-screen.
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.prefetchImageView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentFetched = NO;
    self.contentUpdated = NO;
    self.displayingLocationContent = NO;
    [self fetchInitialFeaturedMems];
    
    self.featuredContentWidth = 280;
    self.featuredContentHeight = 210;
    self.featuredContentSpacing = 10;
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.featuredContentWidth = 320;
        self.featuredContentHeight = 250;
        self.featuredContentSpacing = 10;
    }
    
    //5"
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        self.featuredContentWidth = 320;
        self.featuredContentHeight = 250;
        self.featuredContentSpacing = 10;
    }
    
    velocityMultiplier = 1;
    
    self.snapInProgress = NO;
    
    [self configureTableView];
    [self configureTableDataSourceInsets];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        if (![[LocationManager sharedInstance] locServicesAvailable]) {
            [self setHeaderForCurrentVenue:nil withSpayceState:SpayceStateLocationOff];
            [self.tableView reloadData];
            [self reloadData];
        }
    }
    else {
        [self setHeaderForCurrentVenue:nil withSpayceState:SpayceStateLocationOff];
        [self.tableView reloadData];
        [self reloadData];
    }
    
    [self registerForNotifications];
}

#pragma mark - UIViewController - Responding to View Events

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self.dataSource resetToRestingIfNecessary:self.tableView animated:NO];
    
    //NSLog(@"self.dataSource.restingOffset %f",self.dataSource.restingOffset);
    //NSLog(@"triggeringOffset %f",self.dataSource.triggeringOffset);
    
    //NSLog(@"moving to self.resetOffset %f",self.resetOffset);
    //NSLog(@"displaying currVenueIndex %i",currVenueIndex);
    
    [self.featuredView setContentOffset:CGPointMake(self.resetOffset, 0)];
    [self.venueDetailCollectionView setContentOffset:CGPointMake(self.resetOffset, 0)];
    
    [self updateForContentWithIndex:currVenueIndex];
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    
    self.prefetchPaused = NO;
    [self.spaceView.spinnerView stopAnimating];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ((self.spayceState != SpayceStateLocationOff) && (self.spayceState != SpayceStateDisplayingLocationData)) {
        [self.spaceView promptForOptimizing];
        [self.spaceView spayceCentering];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.resetOffset = self.featuredView.contentOffset.x;
    //NSLog(@"last currVenueIndex %i",currVenueIndex);
    //NSLog(@"setting self.resetOffset %f",self.resetOffset);
    
    self.prefetchPaused = YES;
}


#pragma mark - SPCDataSourceDelegate
- (void)updateCellToPrivate:(NSIndexPath *)indexPath {
}

- (void)updateCellToPublic:(NSIndexPath *)indexPath {
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView   {
    
    //NSLog(@"scrollViewWillBeginDragging ??");
    
    UICollectionView *fView = self.featuredView;
    
    if (!self.displayingLocationContent) {
        //NSLog(@"begin with OYL scroller!");
        fView = self.oylFeaturedView;
    }
    
    if (scrollView == fView) {
        self.draggingFeatured = YES;
    }
    else {
        self.draggingFeatured = NO;
    }
    if (self.contentFetched) {
        //NSLog(@"content fetched -- ready to end OYL!!");
        self.readyToEndOYL = YES;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    //NSLog(@"scrollViewDidScroll");
    
    UICollectionView *fView = self.featuredView;
    UICollectionView *dView = self.venueDetailCollectionView;
    NSInteger maxCount = self.featuredContent.count;
    
    if (!self.displayingLocationContent) {
        fView = self.oylFeaturedView;
        dView = self.oylVenueDetailCollectionView;
        maxCount = self.oylContent.count;
    }
    
    if (scrollView == fView) {
        float offX = fView.contentOffset.x;
        if (!self.snapInProgress && !self.animationInProgress) {
            [dView setContentOffset:CGPointMake(offX, 0)];
        }
        for (int i = 0; i < maxCount; i++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            SPCVenueDetailsCollectionViewCell *cell = (SPCVenueDetailsCollectionViewCell *)[dView cellForItemAtIndexPath:indexPath];
            
            float offAdj = 0;
            if (cell.tag < currVenueIndex) {
                offAdj = -30;
            }
            if (cell.tag > currVenueIndex) {
                offAdj = 30;
            }
            
            float centeredSnapOffset = currVenueIndex * (self.featuredContentWidth + 10);
            
            float delta = (dView.contentOffset.x - centeredSnapOffset) / self.featuredContentWidth;
            
            if (cell.tag == currVenueIndex) {
                if (!self.draggingFeatured) {
                    offAdj = 30 * delta * -1;
                }
                else {
                    offAdj = 30 * delta;
                }
            }
            
            [cell updateOffsetAdjustment:offAdj];
        }
    }
    
    if (scrollView == dView) {
        float offX = dView.contentOffset.x;
        if (!self.snapInProgress && !self.animationInProgress) {
            [fView setContentOffset:CGPointMake(offX, 0)];
        }
    }
}

- (void)updateMaxIndexViewed:(NSInteger)maxIndexViewed {
}


#pragma mark - Setters

- (void)setPrefetchPaused:(BOOL)prefetchPaused {
    if (_prefetchPaused != prefetchPaused) {
        _prefetchPaused = prefetchPaused;
        
        if (!prefetchPaused) {
            // restart image downloads?
            if (self.assetsQueue.count > 0) {
                [self getNextAssetToPreFetch];
            }
        }
    }
}

- (void) setDataSource:(SPCHereDataSource *)dataSource {
    _dataSource = dataSource;
    if (_tableView) {
        CGFloat headerContentTop = CGRectGetHeight(self.view.frame) - self.tableHeaderOpaqueHeight;
        _dataSource.restingOffset = 45;
        _dataSource.triggeringOffset = headerContentTop - 360 + (UIScreen.isLegacyScreen ? 88 : 0);
        _tableView.dataSource = _dataSource;
        _tableView.delegate = _dataSource;
    }
}

#pragma mark - Accessors

- (SPCTableView *)tableView {
    if (!_tableView) {
        _tableView = [[SPCTableView alloc] initWithFrame:self.view.bounds];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self.dataSource;
        self.dataSource.delegate = self;
        _tableView.delegate = self.dataSource;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.tag = kHereTableViewTag;
    }
    return _tableView;
}


- (UIView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIView alloc] init];
        _backgroundView.frame = CGRectMake(0.0, CGRectGetMidY(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) / 2.0);
        _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        _backgroundView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    }
    return _backgroundView;
}

- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.tableView.frame), self.featuredContentWidth, self.featuredContentHeight)];
        _prefetchImageView.hidden = YES;
    }
    return _prefetchImageView;
}

- (UICollectionView *)featuredView {
    
    if (!_featuredView) {
        
        UICollectionViewFlowLayout *collectionLayout = [[UICollectionViewFlowLayout alloc] init];
        
        float leftInset = 20;
        float padding = 20;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            leftInset = 27;
            padding = 22;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            leftInset = 46;
            padding = 22;
        }
        
        collectionLayout.sectionInset = UIEdgeInsetsMake(0, leftInset, 10, 10);
        collectionLayout.minimumLineSpacing = self.featuredContentSpacing;
        collectionLayout.itemSize = CGSizeMake(self.featuredContentWidth, self.featuredContentHeight);
        collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _featuredView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.venueDetailCollectionView.frame), CGRectGetWidth(self.view.frame), self.featuredContentHeight + padding) collectionViewLayout:collectionLayout];
        _featuredView.delegate = self;
        _featuredView.dataSource = self;
        _featuredView.pagingEnabled = NO;
        _featuredView.backgroundColor = [UIColor clearColor];//[UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        _featuredView.userInteractionEnabled = YES;
        _featuredView.scrollEnabled = YES;
        _featuredView.clipsToBounds = NO;
        _featuredView.showsHorizontalScrollIndicator = NO;
        _featuredView.alpha = 0;
        [_featuredView registerClass:[SPCFeaturedContentCell class] forCellWithReuseIdentifier:spcFeaturedContentCellIdentifier];
    }
    
    return _featuredView;
}

- (UICollectionView *)oylFeaturedView {
    
    if (!_oylFeaturedView) {
        
        UICollectionViewFlowLayout *collectionLayout = [[UICollectionViewFlowLayout alloc] init];
        
        float leftInset = 20;
        float padding = 20;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            leftInset = 27;
            padding = 22;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            leftInset = 46;
            padding = 22;
        }
        
        collectionLayout.sectionInset = UIEdgeInsetsMake(0, leftInset, 10, 10);
        collectionLayout.minimumLineSpacing = self.featuredContentSpacing;
        collectionLayout.itemSize = CGSizeMake(self.featuredContentWidth, self.featuredContentHeight);
        collectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _oylFeaturedView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.venueDetailCollectionView.frame), CGRectGetWidth(self.view.frame), self.featuredContentHeight + padding) collectionViewLayout:collectionLayout];
        _oylFeaturedView.delegate = self;
        _oylFeaturedView.dataSource = self;
        _oylFeaturedView.pagingEnabled = NO;
        _oylFeaturedView.backgroundColor = [UIColor clearColor];
        _oylFeaturedView.userInteractionEnabled = YES;
        _oylFeaturedView.scrollEnabled = YES;
        _oylFeaturedView.clipsToBounds = NO;
        _oylFeaturedView.showsHorizontalScrollIndicator = NO;
        [_oylFeaturedView registerClass:[SPCFeaturedContentCell class] forCellWithReuseIdentifier:spcFeaturedContentCellIdentifier];
    }
    
    return _oylFeaturedView;
}

- (UICollectionView *)venueDetailCollectionView {
    if (!_venueDetailCollectionView) {
        
        float bottomContentSize = 275;
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            bottomContentSize = 315;     //4.7"
        }
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            bottomContentSize = 315;    //5"
        }
        
        CGFloat venueInfoViewTop = CGRectGetHeight(self.view.frame) - bottomContentSize;
        
        //collection view layout for the venue details
        UICollectionViewFlowLayout *detailCollectionLayout = [[UICollectionViewFlowLayout alloc] init];
        
        float leftInset = 20;
        float padding = 20;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            leftInset = 27;
            padding = 22;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            leftInset = 46;
            padding = 22;
        }
        
        detailCollectionLayout.sectionInset = UIEdgeInsetsMake(0, leftInset, 0, 10);
        detailCollectionLayout.minimumLineSpacing = self.featuredContentSpacing;
        detailCollectionLayout.itemSize = CGSizeMake(self.featuredContentWidth, 50);
        detailCollectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _venueDetailCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0, venueInfoViewTop, CGRectGetWidth(self.view.frame), 50) collectionViewLayout:detailCollectionLayout];
        _venueDetailCollectionView.delegate = self;
        _venueDetailCollectionView.dataSource = self;
        _venueDetailCollectionView.pagingEnabled = NO;
        _venueDetailCollectionView.backgroundColor = [UIColor clearColor];
        _venueDetailCollectionView.userInteractionEnabled = YES;
        _venueDetailCollectionView.scrollEnabled = YES;
        _venueDetailCollectionView.clipsToBounds = NO;
        _venueDetailCollectionView.showsHorizontalScrollIndicator = NO;
        _venueDetailCollectionView.alpha = 0;
        
        [_venueDetailCollectionView registerClass:[SPCVenueDetailsCollectionViewCell class] forCellWithReuseIdentifier:spcVenueDetailsCelldentifier];
    }
    
    return _venueDetailCollectionView;
}

- (UICollectionView *)oylVenueDetailCollectionView {
    if (!_oylVenueDetailCollectionView) {
        
        float bottomContentSize = 275;
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            bottomContentSize = 315;     //4.7"
        }
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            bottomContentSize = 315;    //5"
        }
        
        CGFloat venueInfoViewTop = CGRectGetHeight(self.view.frame) - bottomContentSize;
        
        //collection view layout for the venue details
        UICollectionViewFlowLayout *detailCollectionLayout = [[UICollectionViewFlowLayout alloc] init];
        
        float leftInset = 20;
        float padding = 20;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            leftInset = 27;
            padding = 22;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            leftInset = 46;
            padding = 22;
        }
        
        detailCollectionLayout.sectionInset = UIEdgeInsetsMake(0, leftInset, 0, 10);
        detailCollectionLayout.minimumLineSpacing = self.featuredContentSpacing;
        detailCollectionLayout.itemSize = CGSizeMake(self.featuredContentWidth, 50);
        detailCollectionLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _oylVenueDetailCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0.0, venueInfoViewTop, CGRectGetWidth(self.view.frame), 50) collectionViewLayout:detailCollectionLayout];
        _oylVenueDetailCollectionView.delegate = self;
        _oylVenueDetailCollectionView.dataSource = self;
        _oylVenueDetailCollectionView.pagingEnabled = NO;
        _oylVenueDetailCollectionView.backgroundColor = [UIColor clearColor];
        _oylVenueDetailCollectionView.userInteractionEnabled = YES;
        _oylVenueDetailCollectionView.scrollEnabled = YES;
        _oylVenueDetailCollectionView.clipsToBounds = NO;
        _oylVenueDetailCollectionView.showsHorizontalScrollIndicator = NO;
        [_oylVenueDetailCollectionView registerClass:[SPCVenueDetailsCollectionViewCell class] forCellWithReuseIdentifier:spcVenueDetailsCelldentifier];
    }
    
    return _oylVenueDetailCollectionView;
}



- (SPCInSpaceView *)spaceView {
    if (!_spaceView) {
        _spaceView = [[SPCInSpaceView alloc] initWithFrame:CGRectMake(0, 45, self.view.bounds.size.width,self.view.bounds.size.height)];
        [_spaceView promptForOptimizing];
        _spaceView.alpha = 1;
        _spaceView.userInteractionEnabled = YES;
        [_spaceView spayceCentering];
    }
    return _spaceView;
}

#pragma mark - Private

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissViewController:) name:SPCHereTriggeringOffsetNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedComments) name:@"finishedComments" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tappedOnVenue:) name:@"tappedOnVenue" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(venueContentFetched:) name:@"venueContentFetched" object:nil];

    
}

- (void)unregisterFromNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)configureTableDataSourceInsets {
    CGFloat headerContentTop = CGRectGetHeight(self.tableView.frame) - self.tableHeaderOpaqueHeight;
    _dataSource.restingOffset = 45;
    _dataSource.triggeringOffset = headerContentTop - 360 + (UIScreen.isLegacyScreen ? 88 : 0);
}

- (void)configureTableView {
    // Configure cell reuse identifier
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCFeedCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCLoadMoreDataCellIdentifier];
    
    
    SPCView *tableHeaderView = [[SPCView alloc] init];
    tableHeaderView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(self.tableView.frame));
    tableHeaderView.backgroundColor = [UIColor clearColor];
    tableHeaderView.clipsToBounds = NO;
    [tableHeaderView setAutoresizingMask:UIViewAutoresizingNone];
    [tableHeaderView setPointInsideBlock:^BOOL(CGPoint point, UIEvent *event) {
        // allow taps to get thru to map only when we have location content loaded in
        if (self.spayceState != SpayceStateDisplayingLocationData) {
            return YES;
        }
        else {
            return CGRectContainsPoint(self.tableView.tableHeaderView.bounds, point);
        }
    }];
    
    CGFloat tableHeaderOpaqueHeight = 0;
    
    float bottomContentSize = 275;
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        bottomContentSize = 315;     //4.7"
    }
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        bottomContentSize = 315;    //5"
    }
    
    CGFloat venueInfoViewTop = CGRectGetHeight(self.view.frame) - bottomContentSize;

    
    UIView *gradientLayer = [[UIView alloc] initWithFrame:CGRectMake(0, venueInfoViewTop, self.view.bounds.size.width, bottomContentSize)];
    gradientLayer.backgroundColor = [UIColor clearColor];
    
    CAGradientLayer *l = [CAGradientLayer layer];
    l.frame = gradientLayer.bounds;
    l.name = @"Gradient";
    l.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:244.0f/255.0f alpha:0.0f] CGColor], (id)[[UIColor colorWithRed:247.0f/255.0f green:247.0f/255.0f blue:244.0f/255.0f alpha:1.0f] CGColor], nil];
    l.startPoint = CGPointMake(0.5, 0.0f);
    l.endPoint = CGPointMake(0.5f, 0.65f);
    [gradientLayer.layer addSublayer:l];
    
    [tableHeaderView addSubview:gradientLayer];
    
    UIView *featuredOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableHeaderView.frame), tableHeaderView.frame.size.height)];
    featuredOverlayView.backgroundColor = [UIColor clearColor];
    featuredOverlayView.hidden = YES;
    featuredOverlayView.userInteractionEnabled = YES;
    [tableHeaderView addSubview:featuredOverlayView];
    
    [tableHeaderView addSubview:self.spaceView];
    
    //add venue detail collection view
    [tableHeaderView addSubview:self.venueDetailCollectionView];
    tableHeaderOpaqueHeight += 50;
    // This is the collection of "featured content" cells.
    [tableHeaderView addSubview:self.featuredView];
    
    [tableHeaderView addSubview:self.oylVenueDetailCollectionView];
    [tableHeaderView addSubview:self.oylFeaturedView];
    

    self.gestureContainer = [[UIView alloc] initWithFrame:CGRectMake(0, venueInfoViewTop, self.view.bounds.size.width,bottomContentSize)];
    self.gestureContainer.backgroundColor = [UIColor clearColor];
    self.gestureContainer.userInteractionEnabled = NO;
    [tableHeaderView addSubview:self.gestureContainer];
    
    UISwipeGestureRecognizer *upRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeUp:)];
    [upRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [tableHeaderView addGestureRecognizer:upRecognizer];
    
    UISwipeGestureRecognizer *downRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeDown:)];
    [downRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [tableHeaderView addGestureRecognizer:downRecognizer];

    tableHeaderOpaqueHeight += self.featuredView.frame.size.height;
    
    self.tableHeaderOpaqueHeight = tableHeaderOpaqueHeight;
    
    // Our table is "untouchable" in the transparent areas of the
    // header, meaning that any hit in that area will be intepreted by the view
    // or ViewController behind it.  The header itself has a much taller center
    // portion; the blank areas to the left and right extend farther down and
    // so the untouchable region is extended there.
    CGRect untouchableRegion = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(self.tableView.frame) - tableHeaderOpaqueHeight - 30);
    
    [self.tableView addUntouchableContentRegion:untouchableRegion];
    
    self.tableView.tableHeaderView = tableHeaderView;
    self.featuredOverlay = featuredOverlayView;
    
    // hide views with no content yet
    self.featuredOverlay.hidden = YES;
    
    self.transparentPixelsAtTop = MAX(0, CGRectGetHeight(self.tableView.frame) - self.tableHeaderOpaqueHeight + 70);

    [self.tableView setContentOffset:CGPointMake(0, 45) animated:NO];
    self.tableView.scrollEnabled = NO;
    // set all content (if it's been provided)
    [self updateUserLocationToVenue:self.venue withMemories:self.memoriesProvided nearbyVenues:self.nearbyVenuesProvided featuredContent:self.featuredContentProvided spayceState:self.spayceState];
}

- (void)setHeaderForCurrentVenue:(Venue *)venue withSpayceState:(SpayceState)spayceState {
    BOOL showVenue;
    NSString *placeholderText;
    //NSLog(@"setHeaderForVenue with spayce state %li",spayceState);
    if (self.manualLocationResetInProgress) {
        spayceState = MIN(spayceState, SpayceStateUpdatingLocation);
        placeholderText = @"";
        showVenue = NO;
    }
    switch (spayceState) {
        case SpayceStateLocationOff:
            placeholderText = @"";
            showVenue = NO;
            break;
        case SpayceStateSeekingLocationFix:
            placeholderText = @"";
            showVenue = NO;
            break;
        case SpayceStateUpdatingLocation:
            placeholderText = @"";
            showVenue = NO;
            break;
        default:
            placeholderText = NSLocalizedString(@"", nil);
            showVenue = (venue != nil);
            break;
    }
    
    showVenue = venue && ([SPCMapDataSource venue:venue is:self.venue] && self.dataSource.hasLoaded);
    
    if (!showVenue) {
        // hide all venue-specific views
        self.venueInfoBackgroundView.hidden = YES;
        self.enterButton.hidden = YES;
        self.featuredOverlay.hidden = YES;
        
        // set placeholder text and venue stamp
        
        self.venueCompassAnimating = NO;
        
        // reveal visible views
    }
}

- (void)setCurrentMemories:(NSArray *)memories withNearbyVenues:(NSArray *)nearbyVenues featuredContent:(NSArray *)featuredContent {

    if (featuredContent && !self.contentFetched) {
        self.refreshInProgress = NO;
        self.featuredContent = [self filterFeaturedContent:featuredContent withNearbyVenues:nearbyVenues];
        [self.featuredView reloadData];
        [self.venueDetailCollectionView reloadData];
        //NSLog(@"data reloaded and currVenueIndex %i",currVenueIndex);
        [self performSelector:@selector(contentHasBeenFetched) withObject:nil afterDelay:1];
    }
}

-(void)contentHasBeenFetched {
    //NSLog(@"contentFetched");
    self.contentFetched = YES;
    self.spaceView.alpha = 1;
    [self.spaceView promptForSwipe];
}

- (NSArray *)filterFeaturedContent:(NSArray *)featuredContent withNearbyVenues:(NSArray *)nearbyVenues {
    
    //Goal: Find content for all nearby venues, and supplement with featured content as necessary to get to min threshold of 20 pieces of content
    
    // Approach:
    
    //1. Trust the content from the server, and its order
    //2. Only alter the content to replace empty venues with placeholders
    
    
    
    NSMutableArray *newFeaturedContent = [NSMutableArray arrayWithCapacity:featuredContent.count];
    for (SPCFeaturedContent *content in featuredContent) {
        //NSLog(@"considering featured content item %@ with location id %d", content.venue.displayName, content.venue.locationId);
        SPCFeaturedContent *contentToAdd = content;
        if (content.contentType == FeaturedContentVenueNearby) {
            if (content.venue.popularMemories.count > 0) {
                contentToAdd = [[SPCFeaturedContent alloc] initWithPopularMemoryHere:content.venue.popularMemories[0]];
            } else if (content.venue.totalMemories > 0) {
                contentToAdd = [[SPCFeaturedContent alloc] initUnknownContentForVenue:content.venue];
            } else {
                contentToAdd = [[SPCFeaturedContent alloc] initPlaceholderForVenue:content.venue];
            }
        }
        
        [newFeaturedContent addObject:contentToAdd];
    }
    
    
    //Determine how many 'favorited/popular' venues we have, so we can handle zooming behavior appropriately
    
    for (int i = 0; i < newFeaturedContent.count; i++) {
        SPCFeaturedContent *content = (SPCFeaturedContent *)newFeaturedContent[i];
        BOOL isPopular = NO;
        
        if (content.venue.favorited) {
            isPopular = YES;
        }
        
        if (content.venue.totalMemories > 0) {
            if (i < 10) {
                isPopular = YES;
            }
        }
        
        if (!isPopular) {
            //set cutoff index
            //NSLog(@"adaptiveZoomCutOffIndex index = %i",i);
            SPCHereViewController *hereVC = (SPCHereViewController *)self.delegate;
            hereVC.venueViewController.mapViewController.adaptiveZoomCutOffIndex = i;
            break;
        }
    }
    
    //Modify our array to support a looping, infinite scrolling behavior
    NSMutableArray *paddedArray = [NSMutableArray arrayWithArray:newFeaturedContent];
    if (paddedArray.count > 0) {
        [paddedArray insertObject:[newFeaturedContent objectAtIndex:newFeaturedContent.count-1] atIndex:0];
        [paddedArray insertObject:[newFeaturedContent objectAtIndex:newFeaturedContent.count-2] atIndex:0];
        [paddedArray addObject:[newFeaturedContent objectAtIndex:0]];
        [paddedArray addObject:[newFeaturedContent objectAtIndex:1]];
    }
    
    //populate our prefetch queue.  Populate outward from center.  Prioritize rightward movement.
    [self makePrefetchQueueForArraySize:paddedArray.count centeredOnIndex:2 movingLeft:NO];
    
    return [NSArray arrayWithArray:paddedArray];
}

- (void)venueContentFetched:(NSNotification *)note {
    
    Venue *updatedVenue = (Venue *)[note object];

    for (int i = 0; i < self.featuredContent.count; i ++) {
   
        SPCFeaturedContent *fc = (SPCFeaturedContent *)[self.featuredContent objectAtIndex:i];
        Venue *venue = fc.venue;
        
        if (updatedVenue.locationId == venue.locationId) {
        
            //the fetatured content for this cell just updated with a mem, refresh
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            SPCFeaturedContentCell *cell = (SPCFeaturedContentCell *)[self.featuredView cellForItemAtIndexPath:indexPath];
            [cell configureWithFeaturedContent:fc];
            
            SPCVenueDetailsCollectionViewCell *detailsCell = (SPCVenueDetailsCollectionViewCell *)[self.venueDetailCollectionView cellForItemAtIndexPath:indexPath];
            [detailsCell configureWithFeaturedContent:fc];
        }
    }
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    
    NSMutableArray * mutMem = [NSMutableArray arrayWithArray:self.dataSource.fullFeed];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [((Memory *)obj) updateWithMemory:memory];
            *stop = YES;
        }
    }];
    self.dataSource.fullFeed = [NSArray arrayWithArray:mutMem];
  
    
    mutMem = [NSMutableArray arrayWithArray:self.dataSource.feed];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [((Memory *)obj) updateWithMemory:memory];
            *stop = YES;
        }
    }];
    self.dataSource.feed = [NSArray arrayWithArray:mutMem];
    
    [self reloadData];
}

- (void)spc_localMemoryDeleted:(NSNotification *)note {
    Memory *memory = (Memory *)[note object];
    
    NSMutableArray * mutMem = [NSMutableArray arrayWithArray:self.dataSource.fullFeed];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [mutMem removeObject:obj];
            *stop = YES;
        }
    }];
    self.dataSource.fullFeed = [NSArray arrayWithArray:mutMem];
    
    mutMem = [NSMutableArray arrayWithArray:self.dataSource.feed];
    [mutMem enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (((Memory *)obj).recordID == memory.recordID) {
            [mutMem removeObject:obj];
            *stop = YES;
        }
    }];
    self.dataSource.feed = [NSArray arrayWithArray:mutMem];
}

- (void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = (PersonUpdate *)[note object];
    [self.dataSource updateWithPersonUpdate:personUpdate];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
   
    if ((collectionView == self.featuredView) || (collectionView == self.venueDetailCollectionView)) {
        return self.featuredContent ? self.featuredContent.count : 0;
    }
    else if ((collectionView == self.oylFeaturedView) || (collectionView == self.oylVenueDetailCollectionView)) {
        return self.oylContent ? self.oylContent.count : 0;
    }
    else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == self.featuredView) {
    
        SPCFeaturedContentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:spcFeaturedContentCellIdentifier forIndexPath:indexPath];
        cell.tag = indexPath.item;
        
        SPCFeaturedContent *content = self.featuredContent[indexPath.item];
        [cell configureWithFeaturedContent:content];
        cell.delegate = self;
        [self performSelector:@selector(scrollViewDidScroll:) withObject:self.featuredView afterDelay:0.0];
        return cell;
    }
    
    if (collectionView == self.oylFeaturedView) {
        
        SPCFeaturedContentCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:spcFeaturedContentCellIdentifier forIndexPath:indexPath];
        cell.tag = indexPath.item;
        SPCFeaturedContent *content = self.oylContent[indexPath.item];
        [cell configureWithFeaturedContent:content];
        [cell forceFeature];
        cell.delegate = self;
        [self performSelector:@selector(scrollViewDidScroll:) withObject:self.oylFeaturedView afterDelay:0.0];
        return cell;
    }
    
    
    if (collectionView == self.venueDetailCollectionView) {
        
        SPCVenueDetailsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:spcVenueDetailsCelldentifier forIndexPath:indexPath];
        cell.tag = indexPath.item;
        
        SPCFeaturedContent *content = self.featuredContent[indexPath.item];
        [cell configureWithFeaturedContent:content];
        [cell.refreshLocationButton addTarget:self action:@selector(refreshLocationButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self performSelector:@selector(scrollViewDidScroll:) withObject:self.featuredView afterDelay:0.0];
        return cell;
    }
    
    if (collectionView == self.oylVenueDetailCollectionView) {
        
        SPCVenueDetailsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:spcVenueDetailsCelldentifier forIndexPath:indexPath];
        cell.tag = indexPath.item;
        
        SPCFeaturedContent *content = self.oylContent[indexPath.item];
        [cell configureWithFeaturedContent:content];
        cell.refreshLocationButton.hidden = YES;
        [self performSelector:@selector(scrollViewDidScroll:) withObject:self.featuredView afterDelay:0.0];
        return cell;
    }
    
    else {
        return nil;
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if ((collectionView == self.featuredView) || (collectionView == self.oylFeaturedView) ) {
        // Deselect cell
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        
        SPCFeaturedContent *content;
        if (self.displayingLocationContent) {
            content = self.featuredContent[currVenueIndex];
        }
        else {
            content = self.oylContent[currVenueIndex];
        }
        
        
        switch (content.contentType) {    
            case FeaturedContentPlaceholder:
                if ([[LocationManager sharedInstance] locServicesAvailable]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"handleMAM" object:nil];
                }
                break;
            default:
                if (content.venue) {
                 
                    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
                    Venue *selectedVenue = content.venue;
                    venueDetailViewController.venue = selectedVenue;
                    [venueDetailViewController jumpToPopular];
                    
                    
                    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
                    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
                    
                    [self.tabBarController presentViewController:navController animated:YES completion:nil];
                }
                break;
        }
    }
}


- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    if (!self.snapInProgress) {
        //NSLog(@"scrollViewWillBeginDecelerating currInedx %i",currVenueIndex);
        self.snapInProgress = YES;
        //NSLog(@"snapping..");
    
        UICollectionView *fView = self.featuredView;
        UICollectionView *dView = self.venueDetailCollectionView;
        int maxCount = (int)self.featuredContent.count - 2;
        
        if (!self.displayingLocationContent) {
            //NSLog(@"OYL content will begin decelerating..");
            fView = self.oylFeaturedView;
            dView = self.oylVenueDetailCollectionView;
            maxCount = (int)self.oylContent.count - 2;
        }
        
        
        
        float currOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
        //NSLog(@"currOffset %f",currOffset);
        //NSLog(@"prevVenue index %i",currVenueIndex);
        //NSLog(@"vel mult %i",velocityMultiplier);
        
        if (currOffset <= fView.contentOffset.x) {
            //NSLog(@"finish left swipe");
            currVenueIndex = currVenueIndex + (1 * velocityMultiplier);
            //NSLog(@"left - new ven index %i",currVenueIndex);
            
            if (currVenueIndex > maxCount) {
                //NSLog(@"over scroll??");
                currVenueIndex = maxCount;
            }
            
            //update our prefetching to stay ahead of user swipe
            [self reorderPrefetchQueueForArraySize:self.featuredContent.count centeredOnIndex:currVenueIndex movingLeft:NO];
            [self getNextAssetToPreFetch];
        }
        else if (currOffset > fView.contentOffset.x) {
            //NSLog(@"right - new ven index %i",currVenueIndex);
            currVenueIndex = currVenueIndex - (1 * velocityMultiplier);
            if (currVenueIndex < 1) {
                //NSLog(@"over scroll??");
                currVenueIndex = 1;
            }
            
            //update our prefetching to stay ahead of user swipe
            [self reorderPrefetchQueueForArraySize:self.featuredContent.count centeredOnIndex:currVenueIndex movingLeft:YES];
            [self getNextAssetToPreFetch];
        }
        float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
        //NSLog(@"snap offset %f",newOffset);
        
        //handle adjustments for infinite scroll wrapping
        float infiniteOffset = 0;
        
        if (currVenueIndex == 1) {
            currVenueIndex = maxCount - 1;
            infiniteOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
        }
        
        if (currVenueIndex == maxCount) {
            currVenueIndex = 2;
            infiniteOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
        }
        
        //update the map unless we are transitioning from oyl
        BOOL shouldUpdateMap = YES;
        if (self.contentFetched && !self.displayingLocationContent) {
            shouldUpdateMap = NO;
        }
        
        if (shouldUpdateMap) {
            [self updateForContentWithIndex:currVenueIndex];
        }
            
        if (infiniteOffset != 0) {
            //NSLog(@"infinite reset?");
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [fView scrollRectToVisible:CGRectMake(newOffset, 0, self.featuredView.bounds.size.width, self.featuredContentHeight) animated:NO];
                [dView scrollRectToVisible:CGRectMake(newOffset, 0, self.venueDetailCollectionView.bounds.size.width, self.venueDetailCollectionView.frame.size.height) animated:NO];
                
                
            } completion:^(BOOL finished) {
                [fView setContentOffset:CGPointMake(infiniteOffset, 0) animated:NO];
                [dView setContentOffset:CGPointMake(infiniteOffset, 0) animated:NO];
                self.snapInProgress = NO;
                //NSLog(@"infinite snap complete!");
                if (self.readyToEndOYL) {
                    [self performSelector:@selector(endOYL) withObject:nil afterDelay:.1];
                }
                
            }];
        }
        
        else {
            //NSLog(@"not inf ofset");
            //NSLog(@"new offest %f",newOffset);
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                [fView scrollRectToVisible:CGRectMake(newOffset, 0, self.featuredView.bounds.size.width, self.featuredContentHeight) animated:NO];
                [dView scrollRectToVisible:CGRectMake(newOffset, 0, self.venueDetailCollectionView.bounds.size.width, self.venueDetailCollectionView.frame.size.height) animated:NO];
            
            }  completion:^(BOOL finished) {
                self.snapInProgress = NO;
                //NSLog(@"snap all done %i",currVenueIndex);
                if (self.readyToEndOYL) {
                    [self performSelector:@selector(endOYL) withObject:nil afterDelay:.1];
                }
                
            }];
        }
    }
    
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset  {
    //NSLog(@"velocity %f",velocity.x);
    
    float velX = fabsf(velocity.x);
    
    if (velX < 2 ){
        velocityMultiplier = 1;
    }
    if (velX >= 2)  {
        velocityMultiplier = 2;
    }
    if (velX >= 3) {
        velocityMultiplier = 3;
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!self.snapInProgress && !decelerate) {
        //NSLog(@"scrollViewDidEndDragging");
        UICollectionView *fView = self.featuredView;
        UICollectionView *dView = self.venueDetailCollectionView;
        
        if (!self.displayingLocationContent) {
            //NSLog(@"OYL did end drag!");
            fView = self.oylFeaturedView;
            dView = self.oylVenueDetailCollectionView;
        }
        
        self.snapInProgress = YES;

        float currOffset = currVenueIndex * (self.featuredContentWidth + 10);
        //NSLog(@"currOffset %f",currOffset);
        //NSLog(@"prevVenue index %i",currVenueIndex);
        
        float distScrolled = fabsf(currOffset - fView.contentOffset.x);
        
        //snap back
        if (distScrolled < self.featuredContentWidth * .25) {
            //NSLog(@"snap back??");
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                [fView setContentOffset:CGPointMake(currOffset, 0) animated:NO];
                [dView setContentOffset:CGPointMake(currOffset,0) animated:NO];
                
            } completion:^(BOOL finished) {
                self.snapInProgress = NO;
            }];
        }
        else {
            //NSLog(@"snapping to next item..");
            
            float currOffset = currVenueIndex * (self.featuredContentWidth + 10);
            //NSLog(@"currOffset %f",currOffset);
            //NSLog(@"prevVenue index %i",currVenueIndex);
            
            if (currOffset <= fView.contentOffset.x) {
                //NSLog(@"finish left swipe");
                currVenueIndex = currVenueIndex + 1;
                
                //update our prefetching to stay ahead of user swipe
                NSInteger prefetchIndex = currVenueIndex + 2;
                if (prefetchIndex < self.featuredContent.count) {
                    [self prefetchImageForFeaturedContentAtIndex:prefetchIndex];
                }
            }
            else if (currOffset > fView.contentOffset.x) {
                //NSLog(@"finish right swipe");
                currVenueIndex = currVenueIndex - 1;
                
                //update our prefetching to stay ahead of user swipe
                NSInteger prefetchIndex = currVenueIndex - 2;
                if (prefetchIndex >= 0) {
                    [self prefetchImageForFeaturedContentAtIndex:prefetchIndex];
                }
                
            }
            float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            //NSLog(@"snap offset %f",newOffset);
            
            //handle adjustments for infinite scroll wrapping
            float infiniteOffset = 0;
            
            if (currVenueIndex == 1) {
                currVenueIndex = (int)self.featuredContent.count - 3;
                infiniteOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            }
            
            if (currVenueIndex == self.featuredContent.count - 2) {
                currVenueIndex = 2;
                infiniteOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
                //NSLog(@"infinite offset set on swipe left..");
            }
            
            //update the map unless we are transitioning from oyl
            BOOL shouldUpdateMap = YES;
            if (self.contentFetched && !self.displayingLocationContent) {
                shouldUpdateMap = NO;
            }
            
            if (shouldUpdateMap) {
                [self updateForContentWithIndex:currVenueIndex];
            }
            
            [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                //NSLog(@"finish snap");
                [fView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
                [dView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
                
            } completion:^(BOOL finished) {
                if (infiniteOffset != 0) {
                    [fView setContentOffset:CGPointMake(infiniteOffset, 0) animated:NO];
                    [dView setContentOffset:CGPointMake(infiniteOffset, 0) animated:NO];
                }
                //NSLog(@"snap complete %i",currVenueIndex);
                
                self.snapInProgress = NO;
                if (self.readyToEndOYL) {
                    //NSLog(@"ready to end oyl in .1");
                    [self performSelector:@selector(endOYL) withObject:nil afterDelay:.1];
                }
            }];
        }
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    
    //NSLog(@"scrollViewDidEndScrollingAnimation");
    
    UICollectionView *fView = self.featuredView;
    UICollectionView *dView = self.venueDetailCollectionView;
    
    if (!self.displayingLocationContent) {
        fView = self.oylFeaturedView;
        dView = self.oylVenueDetailCollectionView;
    }
    
    if (self.animationInProgress) {
        //NSLog(@"animation in progress???");
        self.animationInProgress = NO;
        fView.userInteractionEnabled = YES;
        dView.userInteractionEnabled = YES;
        [self cleanUpOffsets];
    }
}

#pragma mark - Actions

- (void)fetchInitialFeaturedMems {
  
    //NSLog(@"fetch initial mems");
    self.spaceView.hidden = NO;
    
    [self.delegate updateStatusBarForOYL];
    
    float latitude = 0;
    float longitude = 0;
    
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        
        latitude = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
        longitude = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    }

    [[MeetManager sharedInstance] fetchFeaturedMemoriesWithLatitude:latitude
                                                          longitude:longitude
                                              withCompletionHandler:^(NSArray *fc){
                                                        //NSLog(@"featured content result %@",fc);
                                                  
                                                  for (int i = 0; i < fc.count; i++) {
                                                      //SPCFeaturedContent *feC = fc[i];
                                                      //NSLog(@"fc venue %@, mem id %li",feC.venue.displayNameTitle,feC.memory.recordID);
                                                  }
                                                  
                                                  //Modify our array to support a looping, infinite scrolling behavior
                                                  NSMutableArray *paddedArray = [NSMutableArray arrayWithArray:fc];
                                                  //NSLog(@"padded array has length %d", paddedArray.count);
                                                  if (paddedArray.count > 1) {
                                                      [paddedArray insertObject:[paddedArray objectAtIndex:fc.count-1] atIndex:0];
                                                      [paddedArray insertObject:[paddedArray objectAtIndex:fc.count-2] atIndex:0];
                                                      [paddedArray addObject:[fc objectAtIndex:0]];
                                                      [paddedArray addObject:[fc objectAtIndex:1]];
                                                      
                                                      //to support infinite scroll, we start at our adjusted 0 index of 2 after fetching new content
                                                      currVenueIndex = 2;
                                                  } else if (paddedArray.count == 1) {
                                                      [paddedArray insertObject:[paddedArray objectAtIndex:0] atIndex:0];
                                                      [paddedArray insertObject:[paddedArray objectAtIndex:0] atIndex:0];
                                                      [paddedArray addObject:[fc objectAtIndex:0]];
                                                      [paddedArray addObject:[fc objectAtIndex:0]];
                                                      
                                                      //to support infinite scroll, we start at our adjusted 0 index of 2 after fetching new content
                                                      currVenueIndex = 2;
                                                  } else {
                                                      currVenueIndex = 0;
                                                  }
                                                  
                                                  self.oylContent = paddedArray;
                                                  
                                                  [self.oylFeaturedView reloadData];
                                                  [self.oylVenueDetailCollectionView reloadData];
                                                  float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
                                                  [self.oylFeaturedView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
                                                  [self.oylVenueDetailCollectionView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
                                                  [self cleanUpOffsets];
                                                  
                                                  
                                                  
                                              }
                                                       errorHandler:^(NSError *error){
                                                           //NSLog(@"error %@",error);
                                                       }];
}



- (void)endOYL {
    if (self.contentFetched && !self.contentUpdated) {
        self.contentUpdated = YES;
        
        //NSLog(@"endOYL - begin cross fade!");
        if (self.featuredContent.count > 1) {
            currVenueIndex = 2;
        } else {
            currVenueIndex = (int)self.featuredContent.count;
        }
       
        self.featuredView.userInteractionEnabled = NO;
        self.venueDetailCollectionView.userInteractionEnabled = NO;
        self.oylVenueDetailCollectionView.userInteractionEnabled = NO;
        self.oylFeaturedView.userInteractionEnabled = NO;
        self.swipeInProgress = YES;
       
        float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
        [self.featuredView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
        [self.venueDetailCollectionView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
        [self updateForContentWithIndex:currVenueIndex];
        
        [self performSelector:@selector(prepLocOffset) withObject:nil afterDelay:.1];
        
        [UIView animateWithDuration:0.3 delay:0.1 options:0 animations:^{
            self.oylVenueDetailCollectionView.alpha = 0;
            self.oylFeaturedView.alpha = 0;
            self.venueDetailCollectionView.alpha = 1;
            self.featuredView.alpha = 1;
            self.spaceView.alpha = 0;
        }completion:^(BOOL finished) {
            // yay!  fade out!
            //NSLog(@"OYL complete!");
            [self performSelector:@selector(activateLocationContent) withObject:nil afterDelay:.1];
           
            SPCHereViewController *spcHereVC = (SPCHereViewController *)self.delegate;
            spcHereVC.nearbyVenuesBtn.alpha = 1;
            spcHereVC.nearbyVenuesBtn.userInteractionEnabled = YES;
            [self.delegate updateStatusBarAfterRefresh];
        }];
        
    }
}

-(void)activateLocationContent {
    //NSLog(@"activate location content!, should already be visible!");
    self.displayingLocationContent = YES;
    self.readyToEndOYL = NO;
    self.featuredView.userInteractionEnabled = YES;
    self.venueDetailCollectionView.userInteractionEnabled = YES;
    self.swipeInProgress = NO;
    self.animationInProgress = NO;
}

- (void)dismissViewController:(NSNotification *)note {
    if ([self.delegate respondsToSelector:@selector(dismissFeedViewController:animated:)]) {
        [self.delegate dismissFeedViewController:self animated:YES];
    }
}

- (void)reloadData {
    [self.featuredView reloadData];
    [self.venueDetailCollectionView reloadData];
    if (self.featuredContent.count > 2) {
        float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
        [self.featuredView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
        [self.venueDetailCollectionView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
        [self updateForContentWithIndex:currVenueIndex];
        self.swipeInProgress = NO;
    }
}

- (void)reloadTableData {
    [self.tableView reloadData];
}


-(void)refreshLocationButtonPressed {
    if (!self.refreshInProgress) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(userRefreshedLocation)]) {
    
            //reset bools
            self.refreshInProgress = YES;
            self.contentFetched = NO;
            self.contentUpdated = NO;
            self.displayingLocationContent = NO;
            
            //disable venue view nav btn
            SPCHereViewController *spcHereVC = (SPCHereViewController *)self.delegate;
            spcHereVC.nearbyVenuesBtn.alpha = .3;
            spcHereVC.nearbyVenuesBtn.userInteractionEnabled = NO;
            
            //show refresh overlay
            [self.spaceView promptForOptimizing];
            [self.spaceView spayceCentering];
            self.spaceView.hidden = NO;
            
            //display oyl content instead of location specific content
            //NSLog(@"display oyl content");

            //prepare to display oyl content
            if (self.oylContent.count > 1) {
                currVenueIndex = 2;
            } else {
                currVenueIndex = (int)self.oylContent.count;
            }
            
            self.swipeInProgress = YES;
            
            float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            [self.oylFeaturedView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
            [self.oylVenueDetailCollectionView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
            [self cleanUpOffsets];
            
            self.featuredView.userInteractionEnabled = NO;
            self.venueDetailCollectionView.userInteractionEnabled = NO;
            self.oylFeaturedView.userInteractionEnabled = NO;
            self.oylVenueDetailCollectionView.userInteractionEnabled = NO;
            
            [UIView animateWithDuration:0.3 delay:0.1 options:0 animations:^{
                NSLog(@"fade up oyl content");
                self.oylFeaturedView.alpha = 1;
                self.oylVenueDetailCollectionView.alpha = 1;
                self.venueDetailCollectionView.alpha = 0;
                self.featuredView.alpha = 0;
                self.spaceView.alpha = 1;
                
            }completion:^(BOOL finished) {
                // yay!  reenable user interaction!
                self.oylVenueDetailCollectionView.userInteractionEnabled = YES;
                self.oylFeaturedView.userInteractionEnabled = YES;
                self.featuredView.userInteractionEnabled = NO;
                self.venueDetailCollectionView.userInteractionEnabled = NO;
                self.swipeInProgress = NO;
                
                [self updateForContentWithIndex:currVenueIndex];
                
            }];

            [self.delegate userRefreshedLocation];
        }
    }
}

- (void)locationResetManually {
    self.manualLocationResetInProgress = YES;
}

- (void)updateUserLocationToVenue:(Venue *)venue withMemories:(NSArray *)memories nearbyVenues:(NSArray *)nearbyVenues featuredContent:(NSArray *)featuredContent spayceState:(SpayceState)spayceState {
    
    _venue = venue;
    _spayceState = spayceState;
    
    _memoriesProvided = memories;
    _nearbyVenuesProvided = nearbyVenues;
    _featuredContentProvided = featuredContent;
    
    switch (spayceState) {
        case SpayceStateLocationOff:
            [self promptForLocation];
            self.tableView.untouchableContentRegions = nil;
            break;
        case SpayceStateSeekingLocationFix:
            // fall-through...
        case SpayceStateUpdatingLocation:
            // Inform the data source
            self.dataSource.feed = nil;
            self.dataSource.fullFeed = nil;
            self.dataSource.feedUnavailable = YES;
            self.dataSource.hasLoaded = NO;
            [self.tableView reloadData];
            break;
        case SpayceStateDisplayingLocationData:
             self.tableView.untouchableContentRegions = nil;
            CGRect untouchableRegion = CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(self.tableView.frame) - self.tableHeaderOpaqueHeight - 30);
            [self.tableView addUntouchableContentRegion:untouchableRegion];
            self.manualLocationResetInProgress = NO;
            if (!self.contentFetched) {
                [self setCurrentMemories:memories withNearbyVenues:nearbyVenues featuredContent:featuredContent];
                [self setHeaderForCurrentVenue:venue withSpayceState:self.spayceState];
            }
            
        case SpayceStateRetrievingLocationData:
            
            break;
    }
}

-(void)finishedComments {
    self.dataSource.userIsViewingComments = NO;
}


-(void)promptForLocation {
    
    //NSLog(@"prompt for location?");
    
    //reset bools
    self.refreshInProgress = NO;
    self.contentFetched = NO;
    self.contentUpdated = NO;
    self.displayingLocationContent = NO;
    
    //disable venue view nav btn (!)
    SPCHereViewController *spcHereVC = (SPCHereViewController *)self.delegate;
    spcHereVC.nearbyVenuesBtn.alpha = .3;
    spcHereVC.nearbyVenuesBtn.userInteractionEnabled = NO;
    
    //show prompt location overlay
    [self.spaceView promptForLocationFromSpayce];
    self.spaceView.hidden = NO;
    
    //prepare to display oyl content
    if (self.oylContent.count > 1) {
        currVenueIndex = 2;
    } else {
        currVenueIndex = (int)self.oylContent.count;
    }
    
    self.swipeInProgress = YES;
    
    float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
    [self.oylFeaturedView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
    [self.oylVenueDetailCollectionView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
    [self cleanUpOffsets];
    
    self.featuredView.userInteractionEnabled = NO;
    self.venueDetailCollectionView.userInteractionEnabled = NO;
    self.oylFeaturedView.userInteractionEnabled = NO;
    self.oylVenueDetailCollectionView.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:0.3 delay:0.1 options:0 animations:^{
        self.oylFeaturedView.alpha = 1;
        self.oylVenueDetailCollectionView.alpha = 1;
        self.venueDetailCollectionView.alpha = 0;
        self.featuredView.alpha = 0;
        self.spaceView.alpha = 1;
        
    }completion:^(BOOL finished) {
        // yay!  reenable user interaction!
        self.oylVenueDetailCollectionView.userInteractionEnabled = YES;
        self.oylFeaturedView.userInteractionEnabled = YES;
        self.featuredView.userInteractionEnabled = NO;
        self.venueDetailCollectionView.userInteractionEnabled = NO;
        self.swipeInProgress = NO;
        
        [self updateForContentWithIndex:currVenueIndex];
        
    }];
    
}

- (void)promptEnableLocationServices:(id)sender {
    //NSLog(@"promptEnableLocationServices");
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


- (void)showVenueDetailFeed:(id)sender {
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    SPCFeaturedContent *fc;
    if (self.displayingLocationContent) {
        fc = (SPCFeaturedContent *)self.featuredContent[currVenueIndex];
    }
    else {
        fc = (SPCFeaturedContent *)self.oylContent[currVenueIndex];
        
    }
    Venue *selectedVenue = fc.venue;
    venueDetailViewController.venue = selectedVenue;
    [venueDetailViewController jumpToPopular];
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    
    [self.tabBarController presentViewController:navController animated:YES completion:nil];
}

- (void)showVenueDetailFeedForNewMemory:(Memory *)memory {
    Venue *selectedVenue = memory.venue;
    //NSLog(@"selected venue id %li",selectedVenue.locationId);
    //NSLog(@"fc.count %li",self.featuredContent.count);
    
    
    //scroll to venue if needed
    for (int i = 2; i < self.featuredContent.count; i++) {
        
        SPCFeaturedContent *fc = (SPCFeaturedContent *)self.featuredContent[i];
        if (fc.venue.locationId == selectedVenue.locationId) {
            [fc updateContentWithMemory:memory];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            SPCFeaturedContentCell *featCell = (SPCFeaturedContentCell *)[self.featuredView cellForItemAtIndexPath:indexPath];
            SPCVenueDetailsCollectionViewCell *detailsCell = (SPCVenueDetailsCollectionViewCell *)[self.venueDetailCollectionView cellForItemAtIndexPath:indexPath];
            
            [featCell configureWithFeaturedContent:fc];
            [detailsCell configureWithFeaturedContent:fc];
            
            //NSLog(@"fc type %li",fc.contentType);
            currVenueIndex = i;
            float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            [self.featuredView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
            [self updateForContentWithIndex:i];
            break;
        }
    }
    
    //show venue detail
    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = selectedVenue;
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    
    [self.tabBarController presentViewController:navController animated:YES completion:nil];
}


- (void)prepLocOffset {
    //NSLog(@"prep loc offset!");
    //NSLog(@"curr venue index %i",currVenueIndex);
    //NSLog(@"self.venueDetailCollectionView.contentOffset.x %f",self.venueDetailCollectionView.contentOffset.x);
    //NSLog(@"self.featContent count %i",(int)self.featuredContent.count);
    
    for (int i = 0; i < self.featuredContent.count; i++) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        SPCVenueDetailsCollectionViewCell *cell = (SPCVenueDetailsCollectionViewCell *)[self.venueDetailCollectionView cellForItemAtIndexPath:indexPath];
        
        float offAdj = 0;
        if (i < 2) {
            offAdj = -30;
        }
        if (i > 2) {
            offAdj = 30;
        }
        
        if (i == 2) {
            offAdj = 0;
            //NSLog(@"off adj?? %f",offAdj);
        }
        
        [cell updateOffsetAdjustment:offAdj];
    }
}

- (void)cleanUpOffsets {
    //NSLog(@"clean up offsets???");
    
    if (self.displayingLocationContent) {
    
        for (int i = 0; i < self.featuredContent.count; i++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            SPCVenueDetailsCollectionViewCell *cell = (SPCVenueDetailsCollectionViewCell *)[self.venueDetailCollectionView cellForItemAtIndexPath:indexPath];
            
            float offAdj = 0;
            if (cell.tag < currVenueIndex) {
                offAdj = -30;
            }
            if (cell.tag > currVenueIndex) {
                offAdj = 30;
            }
            
            float centeredSnapOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            
            float delta = (self.venueDetailCollectionView.contentOffset.x - centeredSnapOffset) / self.featuredContentWidth;
            
            if (cell.tag == currVenueIndex) {
                if (!self.draggingFeatured) {
                    offAdj = 30 * delta * -1;
                }
                else {
                    offAdj = 30 * delta;
                }
            }
            
            [cell updateOffsetAdjustment:offAdj];
            
        }

    }
    
    else {
    
        for (int i = 0; i < self.oylContent.count; i++) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
            SPCVenueDetailsCollectionViewCell *cell = (SPCVenueDetailsCollectionViewCell *)[self.oylVenueDetailCollectionView cellForItemAtIndexPath:indexPath];
            
            float offAdj = 0;
            if (cell.tag < currVenueIndex) {
                offAdj = -30;
            }
            if (cell.tag > currVenueIndex) {
                offAdj = 30;
            }
            
            float centeredSnapOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            
            float delta = (self.oylVenueDetailCollectionView.contentOffset.x - centeredSnapOffset) / self.featuredContentWidth;
            
            if (cell.tag == currVenueIndex) {
                if (!self.draggingFeatured) {
                    offAdj = 30 * delta * -1;
                }
                else {
                    offAdj = 30 * delta;
                }
            }
            
            [cell updateOffsetAdjustment:offAdj];
            
        }
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Easy enough -- there's only one button!  (besides cancel)
    if (buttonIndex == actionSheet.numberOfButtons - 1) { // Cancel
        return;
    }
}

#pragma mark - UISwipeGestureRecognizer methods

- (void)swipeUp:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.tableView.tableHeaderView];
    if (CGRectContainsPoint(self.gestureContainer.frame, p)) {
        if (self.featuredContent.count > currVenueIndex) {
            [self showVenueDetailFeed:nil];
        }
    } else {
    }
}
    
- (void)swipeDown:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.tableView.tableHeaderView];
    if (CGRectContainsPoint(self.gestureContainer.frame, p)) {
        if (self.featuredContent.count > currVenueIndex) {
            [self.delegate dismissFeedViewController:self animated:YES];
        }
    } else {
        
    }
}

-(void)doneWithAnimation {
    self.animatingVenue = NO;
}

-(void)updateForContentWithIndex:(int)currIndex {
    
    NSInteger maxCount = self.featuredContent.count;
    NSArray *activeArray = self.featuredContent;
    UICollectionView *featView = self.featuredView;
    
    if (!self.contentUpdated) {
        maxCount = self.oylContent.count;
        activeArray = self.oylContent;
        featView = self.oylFeaturedView;
    }
    
    if (currIndex < maxCount) {
    
        SPCFeaturedContent *activeFeature = (SPCFeaturedContent *)activeArray[currIndex];
        
        if (activeFeature.contentType == FeaturedContentFeaturedMemory) {
            if (self.contentFetched) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"fadeDownPinsForFeaturedMemory" object:nil];
            }
            self.featuredOverlay.hidden = NO;
        } else {
            self.featuredOverlay.hidden = YES;
            SPCHereViewController *hereVC = (SPCHereViewController *)self.delegate;
            hereVC.venueViewController.mapViewController.currPinIndex = currIndex;
            //NSLog(@"activeFeatured.venue %@",activeFeature.venue.displayNameTitle);
            if (self.contentFetched) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"displayVenueOnScroll" object:activeFeature.venue];
            }
        }
        
        //NSLog(@"index:%i offset: %f swipeTo:%@ locID:%li",currIndex,self.featuredView.contentOffset.x,activeFeature.venue.displayNameTitle,activeFeature.venue.locationId);

        //NSLog(@"distance label text set to %@, star count to %@", self.distanceLabel.text, self.starCountLabel.text);
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            if (activeFeature.venue.distanceAway > 400) {
                if (activeArray.count > 2) {
                    SPCFeaturedContent *baseFeature = (SPCFeaturedContent *)activeArray[2];
                    [[LocationManager sharedInstance] updateTempLocationWithVenue:baseFeature.venue];
                } else {
                    SPCFeaturedContent *baseFeature = (SPCFeaturedContent *)activeArray[0];
                    [[LocationManager sharedInstance] updateTempLocationWithVenue:baseFeature.venue];
                }
            }
            else {
                [[LocationManager sharedInstance] updateTempLocationWithVenue:activeFeature.venue];
            }
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currIndex inSection:0];
        SPCFeaturedContentCell *cell = (SPCFeaturedContentCell *)[featView cellForItemAtIndexPath:indexPath];
        [cell fallbackImageLoad];

    }
}

-(void)tappedOnVenue:(NSNotification *)notification {
  Venue *tappedVenue = (Venue *)[notification object];
    NSInteger tappedVenueID = tappedVenue.locationId;
    //NSLog(@"tapped v locID %li",tappedVenueID);
    
    for (int i = 2; i < self.featuredContent.count - 2; i++) {
        
        SPCFeaturedContent *fc = (SPCFeaturedContent *)self.featuredContent[i];
        if (fc.venue.locationId == tappedVenueID) {
            
            //handle custom long scroll animation
            int delta = abs(currVenueIndex - i);
            BOOL customLongScrollNeeded = NO;
            BOOL customShortScrollNeeded = NO;
            if (delta >= 5) {
                customLongScrollNeeded = YES;
            }
            else if (delta > 1) {
                customShortScrollNeeded = YES;
            }
            BOOL scrollingToRight = YES;
            
            if (currVenueIndex > i) {
                scrollingToRight = NO;
            }
            
            currVenueIndex = i;
            //NSLog(@"currVenueIndex %i",currVenueIndex);
            float newOffset = currVenueIndex * (self.featuredContentWidth + self.featuredContentSpacing);
            self.resetOffset = newOffset;
            
            [self.featuredView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
            [self.venueDetailCollectionView setContentOffset:CGPointMake(newOffset, 0) animated:NO];
            
            [self updateForContentWithIndex:i];
            [self reorderPrefetchQueueForArraySize:self.featuredContent.count centeredOnIndex:i movingLeft:NO];
            break;
        }
    }
}

-(void)resetScrollerAndMap {
    [self updateForContentWithIndex:currVenueIndex];
}

#pragma mark - Prefetch methods

-(void)prefetchImageForFeaturedContentAtIndex:(NSInteger)prefetchIndex {
    if (self.assetsQueue.count > 0 && !self.prefetchPaused) {
        //NSLog(@"\n\n attempt to prefetch at index %li",prefetchIndex);
        if (prefetchIndex < self.featuredContent.count && prefetchIndex >= 0) {
            SPCFeaturedContent *content = (SPCFeaturedContent *)[self.featuredContent objectAtIndex:prefetchIndex];
            Asset *prefetchAsset = nil;
            
            if (content.contentType == FeaturedContentPopularMemoryHere) {
                prefetchAsset =  [self assetForMemory:content.memory];
                //NSLog(@"mem prefetchAsset %@",prefetchAsset);
            }
            
            if (content.contentType == FeaturedContentFeaturedMemory) {
                prefetchAsset =  [self assetForMemory:content.memory];
                //NSLog(@"mem prefetchAsset %@",prefetchAsset);
            }
            if (content.contentType == FeaturedContentVenueNearby) {
                prefetchAsset = [self assetForVenue:content.venue];
                //NSLog(@"ven prefetchAsset %@",prefetchAsset);
            }

            if (prefetchAsset) {
                //NSLog(@"found asset to prefetch at index %li",prefetchIndex);
                
                BOOL imageIsCached = NO;
                
                if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:[prefetchAsset imageUrlSquare]]]) {
                    imageIsCached = YES;
                    //NSLog(@"cached image!");
                }
                if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:[prefetchAsset imageUrlSquare]]]) {
                    imageIsCached = YES;
                    //NSLog(@"image cached to disk!");
                }
                
                if (!imageIsCached) {
                    //NSLog(@"image not yet cached for URL %@",[prefetchAsset imageUrlSquare]);
                    [self.prefetchImageView sd_cancelCurrentImageLoad];
                
                    [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:[prefetchAsset imageUrlSquare]]
                                      placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                 if (image) {
                                                     //NSLog(@"prefetch featured image %@",imageURL);
                                                     //we got the image
                                                     [self removeIndexFromPreFetchQueue:prefetchIndex];
                                                     self.prefetchImageView.image = image;
                                                     [self getNextAssetToPreFetch];
                                                 }
                                                 if (!image) {
                                                     if (error) {
                                                         //NSLog(@"error prefetching??");
                                                     }
                                                     //NSLog(@"try again at index %li",prefetchIndex);
                                                     [self prefetchImageForFeaturedContentAtIndex:prefetchIndex];
                                                 }
                                                 
                                         }];
                } else {
                    //image is already cached - clean up and keep going
                    //NSLog(@"image is already cached for index %li",prefetchIndex);
                    [self removeIndexFromPreFetchQueue:prefetchIndex];
                    [self getNextAssetToPreFetch];
                }
            }
            
            else {
                //there is no asset to cache - clean up and keep going
                //NSLog(@"no asset of type %li at index %li",content.contentType,prefetchIndex);
                [self removeIndexFromPreFetchQueue:prefetchIndex];
                [self getNextAssetToPreFetch];
            }
        }
    }
}

-(void)makePrefetchQueueForArraySize:(NSUInteger)arraySize centeredOnIndex:(NSInteger)centeredOnIndex movingLeft:(BOOL)movingLeft {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:arraySize];
    for (int i = 0; i < arraySize; i++) {
        [tempArray addObject:@(i)];
    }
    self.assetsQueue = [NSArray arrayWithArray:tempArray];
    
    [self reorderPrefetchQueueForArraySize:arraySize centeredOnIndex:centeredOnIndex movingLeft:movingLeft];
}

-(void)reorderPrefetchQueueForArraySize:(NSUInteger)arraySize centeredOnIndex:(NSInteger)centeredOnIndex movingLeft:(BOOL)movingLeft {
    NSArray *prevArray = self.assetsQueue;
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:prevArray.count];
    // start 2 away from the current position, then expand outward.
    // include the centered index and the 2 on either side, but only at the end.
    int leftEdge = (int)centeredOnIndex - 2;
    int rightEdge = (int)centeredOnIndex + 2;
    
    for (int i = 0; i < arraySize; i += 3) {
        if (movingLeft) {
            [self addNewIndex:leftEdge-- withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
            [self addNewIndex:leftEdge-- withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
            [self addNewIndex:rightEdge++ withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
        } else {
            [self addNewIndex:rightEdge++ withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
            [self addNewIndex:rightEdge++ withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
            [self addNewIndex:leftEdge-- withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
        }
    }
    
    // add around the center...
    [self addNewIndex:centeredOnIndex-1 withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
    [self addNewIndex:centeredOnIndex withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
    [self addNewIndex:centeredOnIndex+1 withMax:arraySize toArray:tempArray ifPresentIn:prevArray];
    
    self.assetsQueue = [NSArray arrayWithArray:tempArray];
}


-(void)addNewIndex:(NSInteger)index withMax:(NSInteger)maxIndex toArray:(NSMutableArray *)array ifPresentIn:(NSArray *)previousArray {
    NSObject *obj = @([self safeIndex:index withCount:maxIndex]);
    if ([previousArray containsObject:obj] && ![array containsObject:obj]) {
        [array addObject:obj];
    }
}

-(NSInteger)safeIndex:(NSInteger)index withCount:(NSInteger)count {
    if (count <= 0) {
        return 0;
    }
    
    while (index < 0) {
        index += count;
    }
    while (index >= count) {
        index -= count;
    }
    
    return index;
}

-(void)removeIndexFromPreFetchQueue:(NSInteger)removeIndex {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.assetsQueue];
    for (int i = 0; i < tempArray.count; i++) {
        NSInteger testInteger = [[tempArray objectAtIndex:i] integerValue];
        if (testInteger == removeIndex) {
            [tempArray removeObjectAtIndex:i];
            break;
        }
    }
    self.assetsQueue = [NSArray arrayWithArray:tempArray];
}


-(void)getNextAssetToPreFetch {
    if (self.assetsQueue.count > 0 && !self.prefetchPaused) {
        
        //check to see if the current image needs to be loaded next!
        BOOL imageIsCached = NO;
        
        SPCFeaturedContent *content = (SPCFeaturedContent *)[self.featuredContent objectAtIndex:currVenueIndex];
        Asset *prefetchAsset;
        
        if (content.contentType == FeaturedContentPopularMemoryHere) {
            prefetchAsset =  [self assetForMemory:content.memory];
            //NSLog(@"mem prefetchAsset %@",prefetchAsset);
        }
        
        if (content.contentType == FeaturedContentFeaturedMemory) {
            prefetchAsset =  [self assetForMemory:content.memory];
            //NSLog(@"mem prefetchAsset %@",prefetchAsset);
        }
        if (content.contentType == FeaturedContentVenueNearby) {
            prefetchAsset = [self assetForVenue:content.venue];
            //NSLog(@"ven prefetchAsset %@",prefetchAsset);
        }
        
        if (prefetchAsset) {
            //NSLog(@"found asset to prefetch at index %li",prefetchIndex);
           if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:[NSURL URLWithString:[prefetchAsset imageUrlSquare]]]) {
                imageIsCached = YES;
                //NSLog(@"already cached image!");
            }
            if ([[SDWebImageManager sharedManager] diskImageExistsForURL:[NSURL URLWithString:[prefetchAsset imageUrlSquare]]]) {
                imageIsCached = YES;
                //NSLog(@"image already cached to disk!");
            }
        }
    
        if (imageIsCached) {
            //just keep going thru the queue..
            NSNumber *prefetchIndex = [self.assetsQueue objectAtIndex:0];
            NSInteger preIndex = [prefetchIndex integerValue];
            [self prefetchImageForFeaturedContentAtIndex:preIndex];
        }
        else {
            //get this one, we need it now..
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:currVenueIndex inSection:0];
            SPCFeaturedContentCell *cell = (SPCFeaturedContentCell *)[self.featuredView cellForItemAtIndexPath:indexPath];
            [cell fallbackImageLoad];
        }
    }
}

-(void)imageLoadComplete {
    //delegate callback method from the cell used when image is cached directly w/in the cell
    [self getNextAssetToPreFetch];
}

- (Asset *)assetForMemory:(Memory *)memory {
    //NSLog(@"asset for mem of type %li",memory.type);
    if (memory.type == MemoryTypeImage) {
        //NSLog(@"img mem?");
        ImageMemory *imageMemory = (ImageMemory *)memory;
        if (imageMemory.images.count > 0) {
             //NSLog(@"got imgs?");
            return imageMemory.images[0];
        }
    } else if (memory.type == MemoryTypeVideo) {
       //NSLog(@"VID mem?");
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

-(void)delayedPrefetch {
    [self prefetchImageForFeaturedContentAtIndex:2];
}

@end
