//
//  SPCTrendingFeedViewController.m
//  Spayce
//
//  Created by Jake Rosin on 7/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTrendingFeedViewController.h"

// Model
#import "SPCTrendingDataSource.h"
#import "SPCVenueTypes.h"

// View
#import "MemoryCell.h"
#import "SPCTableView.h"

// Category
#import "UIViewController+SPCAdditions.h"

// Manager
#import "MeetManager.h"

@interface SPCTrendingFeedViewController () <SPCDataSourceDelegate>

@property (nonatomic, strong) UIView *statusBar;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIView *statBar;
@property (nonatomic, strong) UIView *headerSeparatorBar;

@property (nonatomic, strong) SPCTrendingDataSource *dataSource;
@property (nonatomic, strong) SPCTableView *tableView;
@property (nonatomic, assign) NSInteger maxIndexViewed;

@property (nonatomic, strong) Venue * venue;

@end

@implementation SPCTrendingFeedViewController

- (void)dealloc {
    [self unregisterFromNotifications];
}

- (id)initWithVenue:(Venue *)venue
{
    self = [super init];
    if (self) {
        // Custom initialization
        self.venue = venue;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Fake view (to prevent weird TableView top inset issues)
    UIView * tempView = [[UIView alloc] initWithFrame:CGRectMake(30.0, 30.0, 30.0, 30.0)];
    [self.view addSubview:tempView];
    
    // Do any additional setup after loading the view.
    [self.view addSubview:self.tableView];
    
    // Header (in reverse order, for z-ordering)
    [self.view addSubview:self.headerSeparatorBar];
    [self.view addSubview:self.statBar];
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.statusBar];
    
    [self registerForNotifications];
}

- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:SPCReloadForFilters object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(expandAccordion) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
}

- (void)unregisterFromNotifications {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = YES;
    
    // Hide tab bar
    [UIView animateWithDuration:0.35 animations:^{
        self.tabBarController.tabBar.alpha = 0.0;
    }];
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fetchMems];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    
    // Show tab bar
    [UIView animateWithDuration:0.35 animations:^{
        self.tabBarController.tabBar.alpha = 1.0;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Property Accessors

- (UIView *)statusBar {
    if (!_statusBar) {
        UIView *statusBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 20)];
        statusBar.backgroundColor = [UIColor colorWithRGBHex:0x2d3747];
        
        _statusBar = statusBar;
    }
    return _statusBar;
}

- (UIView *)navBar {
    if (!_navBar) {
        UIView *navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 20.0, CGRectGetWidth(self.view.frame), 44)];
        navBar.backgroundColor = [UIColor colorWithRGBHex:0x2d3747];
        
        UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(8, 7, 64, 29)];
        cancelButton.backgroundColor = [UIColor colorWithRed:151.0/255.0f green:164.0f/255.0f blue:172.0f/255.0f alpha:0.3f];
        cancelButton.titleLabel.font = [UIFont spc_mediumFont];
        cancelButton.layer.cornerRadius = 2;
        [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cancelButton setTitle:@"Back" forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentLeft;
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.text = NSLocalizedString(self.venue.venueName ? self.venue.venueName : self.venue.streetAddress, nil);
        [titleLabel sizeToFit];
        if (titleLabel.frame.size.width < CGRectGetWidth(self.view.frame) - 180) {
            // center in the frame
            titleLabel.center = CGPointMake(navBar.frame.size.width/2.0, navBar.frame.size.height/2.0);
            titleLabel.textAlignment = NSTextAlignmentCenter;
        } else {
            // left-align; resize to the width left for us
            CGFloat left = CGRectGetMaxX(cancelButton.frame) + 8;
            titleLabel.frame = CGRectMake(left, 0.0, CGRectGetWidth(self.view.frame) - left - 8, titleLabel.font.lineHeight);
            titleLabel.center = CGPointMake(titleLabel.center.x, navBar.frame.size.height/2.0);
        }
        
        [navBar addSubview:cancelButton];
        [navBar addSubview:titleLabel];
        
        _navBar = navBar;
    }
    return _navBar;
}

- (UIView *)statBar {
    if (!_statBar) {
        UIView * statBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.navBar.frame), CGRectGetWidth(self.view.frame), 40)];
        statBar.backgroundColor = [UIColor colorWithRGBHex:0x374357];
        
        // separator bars
        CGFloat third = CGRectGetWidth(self.view.frame) / 3.0f;
        UIView * sep1 = [[UIView alloc] initWithFrame:CGRectMake(floorf(third), 12.0f, 0.5f, 16.0)];
        UIView * sep2 = [[UIView alloc] initWithFrame:CGRectMake(ceilf(third*2), 12.0f, 0.5f, 16.0)];
        sep1.backgroundColor = self.navBar.backgroundColor;
        sep2.backgroundColor = self.navBar.backgroundColor;
        [statBar addSubview:sep1];
        [statBar addSubview:sep2];
        
        // venue icon
        UIImageView * venueIconView = [[UIImageView alloc] initWithImage:[SPCVenueTypes imageForVenue:self.venue withIconType:VenueIconTypeIconSmallBlue]];
        venueIconView.center = CGPointMake(floorf(third/2.0f), CGRectGetMidY(statBar.bounds));
        // memories
        UIImageView * memoryIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-blue-memory"]];
        UILabel * memoryCountLabel = [[UILabel alloc] init];
        memoryCountLabel.textAlignment = NSTextAlignmentLeft;
        memoryCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
        memoryCountLabel.textColor = [UIColor colorWithRGBHex:0x7188ae];
        memoryCountLabel.text = [NSString stringWithFormat:@"%@", @(self.venue.totalMemories)];
        [memoryCountLabel sizeToFit];
        CGFloat width = memoryIconView.frame.size.width + 2.0 + memoryCountLabel.frame.size.width;
        CGFloat x = CGRectGetMidX(statBar.frame);
        // center first, then spread out
        memoryIconView.center = memoryCountLabel.center = CGPointMake(x, CGRectGetMidY(statBar.bounds));
        CGRect frame = memoryIconView.frame;
        frame.origin = CGPointMake(x - width/2.0f, frame.origin.y);
        memoryIconView.frame = frame;
        CGRect frame2 = memoryCountLabel.frame;
        frame2.origin = CGPointMake(CGRectGetMaxX(frame) + 2.0, frame.origin.y);
        memoryCountLabel.frame = frame2;
        
        // stars
        UIImageView * starIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-blue-star"]];
        UILabel * starCountLabel = [[UILabel alloc] init];
        starCountLabel.textAlignment = NSTextAlignmentLeft;
        starCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:13.0];
        starCountLabel.textColor = [UIColor colorWithRGBHex:0x7188ae];
        starCountLabel.text = [NSString stringWithFormat:@"%@", @(self.venue.totalStars)];
        [starCountLabel sizeToFit];
        width = starIconView.frame.size.width + 1.0 + starCountLabel.frame.size.width;
        x = ceilf(third * 2.5f);
        // center first, then spread out
        starIconView.center = starCountLabel.center = CGPointMake(x, CGRectGetMidY(statBar.bounds));
        frame = starIconView.frame;
        frame.origin = CGPointMake(x - width/2.0f, frame.origin.y);
        starIconView.frame = frame;
        frame2 = starCountLabel.frame;
        frame2.origin = CGPointMake(CGRectGetMaxX(frame) + 1.0, frame.origin.y);
        starCountLabel.frame = frame2;
        
        [statBar addSubview:venueIconView];
        [statBar addSubview:memoryCountLabel];
        [statBar addSubview:memoryIconView];
        [statBar addSubview:starCountLabel];
        [statBar addSubview:starIconView];
        
        _statBar = statBar;
    }
    return _statBar;
}

- (UIView *)headerSeparatorBar {
    if (!_headerSeparatorBar) {
        _headerSeparatorBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.statBar.frame), CGRectGetWidth(self.view.frame), 5)];
        _headerSeparatorBar.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
    }
    return _headerSeparatorBar;
}

- (SPCTrendingDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [[SPCTrendingDataSource alloc] init];
        _dataSource.segmentItems = @[NSLocalizedString(@"Recent", nil), NSLocalizedString(@"Starred", nil), NSLocalizedString(@"Personal", nil)];
        _dataSource.navigationController = self.navigationController;
        _dataSource.delegate = self;
        
        [_dataSource configureAccordionViewsWithViewOrder:@[self.navBar, self.statBar, self.headerSeparatorBar] unfoldOrder:@[self.headerSeparatorBar, self.navBar, self.statBar] accordionTop:self.navBar.frame.origin.y];
        _dataSource.accordionStickyPixels = 150.0;
        _dataSource.accordionStickyPixelsRestick = 30.0;
    }
    return _dataSource;
}

- (SPCTableView *)tableView {
    if (!_tableView) {
        _tableView = [[SPCTableView alloc] initWithFrame:CGRectMake(0.0, 20.0, self.view.frame.size.width, self.view.frame.size.height - 20.0)];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        _tableView.tag = kTrendingTableViewTag;
        
        _tableView.dataSource = self.dataSource;
        _tableView.delegate = self.dataSource;
        _tableView.contentInset = UIEdgeInsetsMake(self.dataSource.accordionHeight+10, 0.0, 10.0, 0.0);
        
        // Configure cell reuse identifier
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCFeedCellIdentifier];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCLoadMoreDataCellIdentifier];
    }
    return _tableView;
}


#pragma mark - Controls

- (void)back:(id)sender {
    NSLog(@"back");
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)reloadData {
    [self.tableView reloadData];
}

- (void)expandAccordion {
    [self.dataSource setAccordionHeight:self.dataSource.accordionHeightMax forScrollView:self.tableView];
}

- (void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    if (personUpdate) {
        [self.dataSource updateWithPersonUpdate:personUpdate];
    }
}

- (void)fetchMems {
    __weak typeof(self) weakSelf = self;
    
    [MeetManager fetchLocationMemoriesFeedForVenue:self.venue
                            includeFeaturedContent:NO
                             withCompletionHandler:^(NSArray *memories, NSArray *featuredContent,NSArray *venueHashTags) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    
                                    strongSelf.dataSource.fullFeed = memories;
                                    strongSelf.dataSource.feed = memories;
                                    
                                    strongSelf.dataSource.hasLoaded = YES;
                                 
                                     if (strongSelf.dataSource.selectedSegmentIndex == 0) {
                                         [strongSelf.dataSource filterByRecency];
                                     } else if (strongSelf.dataSource.selectedSegmentIndex == 1) {
                                         [strongSelf.dataSource filterByStars];
                                     } else if (strongSelf.dataSource.selectedSegmentIndex == 2) {
                                         [strongSelf.dataSource filterByPersonal];
                                     }
                                    
                                    [strongSelf.tableView reloadData];
                                } errorHandler:^(NSError *error) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    
                                    // Show error notification
                                    [strongSelf spc_showNotificationBannerInSegmentedControl:strongSelf.dataSource.segmentedControl title:NSLocalizedString(@"Couldn't Load Memories", nil) error:error];
                                }];
}

#pragma mark - SPCDataSourceDelegate

- (void)updateCellToPrivate:(NSIndexPath *)indexPath {
    NSLog(@"trendingfeed updateCellToPrivate at row: %i",(int)indexPath.row);
    MemoryCell *cell = (MemoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateToPrivate];
}
- (void)updateCellToPublic:(NSIndexPath *)indexPath {
    NSLog(@"trendingfeed updateCellToPublic at row: %i",(int)indexPath.row);
    MemoryCell *cell = (MemoryCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateToPublic];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // Fades in bottom cell in table view as it enter the screen for first time
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if (visibleCells != nil  &&  [visibleCells count] != 0) {       // Don't do anything for empty table view
        
        /* Get bottom cell */
        UITableViewCell *bottomCell = [visibleCells lastObject];
        
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
        
        /* Make sure other cells stay opaque */
        // Avoids issues with skipped method calls during rapid scrolling
        for (UITableViewCell *cell in visibleCells) {
            cell.alpha = 1.0;
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
    }
    
}

- (void)updateMaxIndexViewed:(NSInteger)maxIndexViewed {
    if (maxIndexViewed > self.maxIndexViewed) {
        self.maxIndexViewed = maxIndexViewed;
    }
}

@end
