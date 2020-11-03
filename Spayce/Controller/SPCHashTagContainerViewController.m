//
//  SPCHashTagContainerViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHashTagContainerViewController.h"

#import "AppDelegate.h"

//controller
#import "SPCHereVenueMapViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCMainViewController.h"
#import "SPCVenueDetailGridTransitionViewController.h"

//view
#import "HMSegmentedControl.h"
#import "SPCGrid.h"
#import "SPCEarthquakeLoader.h"

//model
#import "Venue.h"
#import "Memory.h"

//data
#import "SPCBaseDataSource.h"

//category
#import "UIViewController+SPCAdditions.h"
#import "UIAlertView+SPCAdditions.h"
#import "UITableView+SPXRevealAdditions.h"

//manager
#import "SocialService.h"

@interface SPCHashTagContainerViewController () <SPCHereVenueMapViewControllerDelegate, SPCGridDelegate, SPCDataSourceDelegate,UIAlertViewDelegate>

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UILabel *hashTagTitleLbl;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIView *segControlContainer;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;

@property (nonatomic, strong) SPCGrid *gridView;
@property (nonatomic, strong) SPCEarthquakeLoader *gridLoader;

@property (nonatomic, strong) UIView *feedView;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *mapContainerView;
@property (nonatomic, strong) SPCHereVenueMapViewController *mapViewController;


@property (nonatomic, assign) float navBarOriginalCenterY;
@property (nonatomic, assign) float segControlOriginalCenterY;
@property (nonatomic, assign) float maxAdjustment;
@property (nonatomic, strong) Memory *fallbackMemory;

// Data
@property (nonatomic, strong) SPCBaseDataSource *dataSource;

@property (nonatomic, assign) BOOL isVisible;

@end

@implementation SPCHashTagContainerViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_tableView];
}

-(void)loadView {
    [super loadView];
 
    // Content views
    [self.view addSubview:self.gridView];
    [self.view addSubview:self.feedView];
    [self.view addSubview:self.mapContainerView];
 
    //nav
    [self.view addSubview:self.segControlContainer];
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.hashTagTitleLbl];


}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];

    self.view.backgroundColor = [UIColor colorWithWhite:254.0f/255.0f alpha:1.0f];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    self.tabBarController.tabBar.alpha = 0.0;
    self.isVisible = YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.tabBar.alpha = 0.0;
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.tabBarController.tabBar.alpha = 1.0;
    self.isVisible = NO;
}

-(void)configureWithHashTag:(NSString *)hashTag memory:(Memory *)mem {
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, self.view.bounds.size.width - 100, 45)];
    titleLbl.font = [UIFont spc_boldSystemFontOfSize:16];
    titleLbl.textColor = [UIColor colorWithRGBHex:0x292929];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = hashTag;
    titleLbl.numberOfLines = 1;
    
    self.hashTagTitleLbl = titleLbl;
    [_navBar addSubview:self.hashTagTitleLbl];
    self.fallbackMemory = mem;
    [self fetchVenuesForHashTag:hashTag];
}

#pragma mark - Accessors

-(UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 65)];
        _navBar.backgroundColor = [UIColor colorWithWhite:254.0f/255.0f alpha:1.0f];
        
        _backButton = [[UIButton alloc] initWithFrame:CGRectMake(-1.0, 18.0, 65.0, 50.0)];
        _backButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        _backButton.layer.cornerRadius = 2;
        _backButton.backgroundColor = [UIColor clearColor];
        [_backButton setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [_backButton setTitleColor:[UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:.7f] forState:UIControlStateHighlighted];
        [_backButton setTitle:@"Back" forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(closeButtonActivated:) forControlEvents:UIControlEventTouchUpInside];
        [_navBar addSubview:_backButton];
        
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 64, self.view.bounds.size.width, .5)];
        sepLine.backgroundColor = [UIColor colorWithWhite:244.0f/255.0f alpha:1.0f];
        [_navBar addSubview:sepLine];
    }
    return _navBar;
}

- (UIView *)segControlContainer {
    if (!_segControlContainer) {
        _segControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.view.bounds.size.width, 37)];
        _segControlContainer.backgroundColor = [UIColor whiteColor];
        
        [_segControlContainer addSubview:self.hmSegmentedControl];
        
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width / 2 - .5, 11.5, 1, 17)];
        sepLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepLine];
        
        UIView *sepView2 = [[UIView alloc] initWithFrame:CGRectMake(0, _segControlContainer.frame.size.height - .5, self.view.bounds.size.width, .5)];
        sepView2.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepView2];
        
        self.segControlOriginalCenterY = _segControlContainer.center.y;
        self.maxAdjustment = 5 + CGRectGetHeight(_segControlContainer.frame);
    }
    
    return _segControlContainer;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"GRID", @"MAP"]];
        _hmSegmentedControl.frame = CGRectMake(0, 1, _segControlContainer.frame.size.width, 36);
        [_hmSegmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleTextWidthStripe;
        _hmSegmentedControl.selectionIndicatorHeight = 3.0f;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
        _hmSegmentedControl.shouldAnimateUserSelection = YES;
        _hmSegmentedControl.selectedSegmentIndex = 0;
        
    }
    
    return _hmSegmentedControl;
}


- (SPCGrid *)gridView {
    if (!_gridView) {
        _gridView = [[SPCGrid alloc] initWithFrame:CGRectMake(0, 65, self.view.bounds.size.width, self.view.bounds.size.height - 65)];
        _gridView.delegate = self;
        float initialOffset = -1 * (CGRectGetHeight(self.segControlContainer.frame));
        [_gridView setBaseContentOffset:initialOffset];
        [_gridView.collectionView setScrollIndicatorInsets:UIEdgeInsetsMake(CGRectGetHeight(self.segControlContainer.frame), 0, 0, 0)];
        [_gridView addSubview:self.gridLoader];
    }
    return _gridView;
}

- (UIView *)feedView {
    if (!_feedView) {
        _feedView = [[UIView alloc] initWithFrame:CGRectMake(0, 65, self.view.bounds.size.width, self.view.bounds.size.height - 65)];
        _feedView.backgroundColor = [UIColor yellowColor];
        _feedView.alpha = 0;
        _feedView.userInteractionEnabled = YES;
        [_feedView addSubview:self.tableView];
        [self.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(CGRectGetHeight(self.segControlContainer.frame), 0, 0, 0)];
    }
    
    return _feedView;
}


#pragma mark - Accessors

- (SPCBaseDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [[SPCBaseDataSource alloc] init];
        _dataSource.delegate = self;
        
    }
    return _dataSource;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.feedView.frame.size.height) style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0f];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self.dataSource;
        _tableView.delegate = self.dataSource;
        _tableView.userInteractionEnabled = YES;
        _tableView.tag = kHashTagTableViewTag;
    }
    return _tableView;
}


- (UIView *)mapContainerView {
    if (!_mapContainerView) {
        _mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width, CGRectGetMaxY(self.segControlContainer.frame),self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.segControlContainer.frame))];
        [_mapContainerView addSubview:self.mapViewController.view];
        _mapContainerView.clipsToBounds = YES;
    }
    
    return _mapContainerView;
}

- (SPCHereVenueMapViewController *)mapViewController {
    if (!_mapViewController) {
        _mapViewController = [[SPCHereVenueMapViewController alloc] init];
        _mapViewController.delegate = self;
        _mapViewController.isExplorePaused = YES;
        _mapViewController.isExploreOn = YES;
    }
    return _mapViewController;
}

- (SPCEarthquakeLoader *)gridLoader {
    if (!_gridLoader) {
        _gridLoader = [[SPCEarthquakeLoader alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.segControlContainer.frame), self.gridView.frame.size.width, self.gridView.frame.size.height - self.segControlContainer.frame.size.height)];
        _gridLoader.msgLabel.text = @"Finding memories...";
    }
    return _gridLoader;
}

#pragma mark - SPCGrid delegate methods

-(void)showVenueDetailFeed:(Venue *)v {

    SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
    venueDetailViewController.venue = v;
    [venueDetailViewController fetchMemories];
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
    [self presentViewController:navController animated:YES completion:nil];
}

-(void)showVenueDetail:(Venue *)v {
    [self showVenueDetail:v jumpToMemory:nil];
}

-(void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)m {
    if (m) {
        [self showVenueDetail:v jumpToMemory:m withImage:nil atRect:CGRectZero];
    }
    else {
        [self showVenueDetailFeed:v];
    }
}

-(void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)memory withImage:(UIImage *)image atRect:(CGRect)rect {
    //capture image of screen to use in MAM completion animation
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    SPCVenueDetailGridTransitionViewController *vc = [[SPCVenueDetailGridTransitionViewController alloc] init];
    vc.venue = v;
    vc.memory = memory;
    vc.backgroundImage = currentScreenImg;
    vc.gridCellImage = image;
    vc.gridCellFrame = rect;
    
    // clip rect?
    CGFloat top = MAX(CGRectGetMaxY(self.segControlContainer.frame), CGRectGetMaxY(self.navBar.frame));
    CGFloat bottom = CGRectGetMaxY(self.view.frame);
    //NSLog(@"mask to the area from %f to %f", top, bottom);
    CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
    vc.gridClipFrame = maskRect;
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    [self presentViewController:navController animated:NO completion:nil];
}

-(void)showMemoryComments:(Memory *)m {
    [self showMemoryComments:m withImage:nil atRect:CGRectZero];
}

-(void)showMemoryComments:(Memory *)m withImage:(UIImage *)image atRect:(CGRect)rect {
    //capture image of screen to use in MAM completion animation
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.view.layer renderInContext:context];
    UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    SPCVenueDetailGridTransitionViewController *vc = [[SPCVenueDetailGridTransitionViewController alloc] init];
    vc.venue = m.venue;
    vc.memory = m;
    vc.backgroundImage = currentScreenImg;
    vc.gridCellImage = image;
    vc.gridCellFrame = rect;
    
    // clip rect?
    CGFloat top = MAX(CGRectGetMaxY(self.segControlContainer.frame), CGRectGetMaxY(self.navBar.frame));
    CGFloat bottom = CGRectGetMaxY(self.view.frame);
    //NSLog(@"mask to the area from %f to %f", top, bottom);
    CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
    vc.gridClipFrame = maskRect;
    
    SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
    navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
    [self presentViewController:navController animated:NO completion:nil];
}


- (void)scrollingUpAdjustViewsWithDelta:(float)deltaAdj {
    
    //adjust the views from their current position, based on movement of collection view
    if (self.segControlContainer.center.y - deltaAdj > self.segControlOriginalCenterY - self.maxAdjustment) {
        self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlContainer.center.y - deltaAdj);
    }
    //cap the maximum movement
    else {
        self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY - self.maxAdjustment);
    }
  
}

- (void)scrollingDownAdjustViewsWithDelta:(float)deltaAdj {
    
    //adjust views from their current position, based on movement of collection view
    if (self.segControlContainer.center.y + deltaAdj <= self.segControlOriginalCenterY) {
        self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlContainer.center.y + deltaAdj);
    }
}

- (void)contentComplete {
    self.gridLoader.alpha = 0;
    self.feedView.alpha = 0;
    self.gridView.alpha = 1;
    [self.gridLoader stopAnimating];
    [self.gridView gridDidAppear];
    
    //NSLog(@"content complete, update map w/venues %@",self.gridView.venues);
    if (self.gridView.venues.count > 0) {
        [self.mapViewController updateVenues:self.gridView.venues withCurrentVenue:nil deviceVenue:nil spayceState:SpayceStateDisplayingLocationData];
        self.mapViewController.isViewingFromHashtags = YES;
        [self.mapViewController showVenue:self.gridView.venues[0]];
        [self setMapViewProjectionToShowVenues:self.gridView.venues];
    }
}



- (void)gridScrolled:(UIScrollView *)scrollView {

}

- (void)showFeedForMemories:(NSArray *)memories {
    
    self.dataSource.navigationController = self.navigationController;
    self.gridLoader.alpha = 0;
    self.gridView.alpha = 0;
    self.feedView.alpha = 1;
    [self.gridLoader stopAnimating];
    
    self.dataSource.fullFeed = memories;
    self.dataSource.feed = memories;
    self.dataSource.hasLoaded = YES;
    
    [self.tableView reloadData];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(CGRectGetHeight(self.segControlContainer.frame), 0, 0, 0)];
    [self.tableView setContentOffset:CGPointMake(0, - 1 * CGRectGetHeight(self.segControlContainer.frame))];
}


#pragma mark - Actions

-(void)closeButtonActivated:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; // stop all videos when leaving hashtag
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
   
    if (segmentedControl.selectedSegmentIndex == 0) {
        
        // animate in and display grid view (local)
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             self.gridView.center = CGPointMake(self.view.bounds.size.width/2, self.gridView.center.y);
                             self.feedView.center = CGPointMake(self.view.bounds.size.width/2, self.feedView.center.y);
                             
                             self.mapContainerView.center = CGPointMake(self.view.bounds.size.width/2 + self.view.bounds.size.width, self.mapContainerView.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 [self.gridView gridDidAppear];
                             }
                         }];
        
    }
    if (segmentedControl.selectedSegmentIndex == 1) {
        // animate in and display map
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             //make sure our seg control and nav bar are fully in place
                             self.segControlContainer.center = CGPointMake(self.segControlContainer.center.x,self.segControlOriginalCenterY);
                             
                             self.mapContainerView.center = CGPointMake(self.view.bounds.size.width/2, self.mapContainerView.center.y);
                             self.gridView.center = CGPointMake(self.view.bounds.size.width/2 - self.view.bounds.size.width, self.gridView.center.y);
                             self.feedView.center = CGPointMake(self.view.bounds.size.width/2 - self.view.bounds.size.width, self.feedView.center.y);
                             
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 [self.gridView gridDidDisappear];
                             }
                         }];
        
    }
}


#pragma mark - Private 

-(void)fetchVenuesForHashTag:(NSString *)hashTag {
    //NSLog(@"fetchVenuesForHashTag %@",hashTag);
    [self.gridLoader startAnimating];
    [self.gridView fetchContentForHash:hashTag memory:self.fallbackMemory];
}

- (void)setMapViewProjectionToShowVenues:(NSArray *)venues {
    GMSCoordinateBounds *bounds = nil;
    for (Venue *venue in venues) {
        CLLocationCoordinate2D location = CLLocationCoordinate2DMake(venue.latitude.doubleValue, venue.longitude.doubleValue);
        //NSLog(@"location lat:%f long:%f:",location.latitude,location.longitude);
        if (!bounds) {
            bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:location coordinate:location];
        } else {
            bounds = [bounds includingCoordinate:location];
        }
    }
    
    // determine if it makes sense to set a fixed zoom level around the provided venue, or to zoom the bounds of all venues
    CLLocation *ne = [[CLLocation alloc] initWithLatitude:bounds.northEast.latitude longitude:bounds.northEast.longitude];
    CLLocation *sw = [[CLLocation alloc] initWithLatitude:bounds.southWest.latitude longitude:bounds.southWest.longitude];
    
    if ([ne distanceFromLocation:sw] < 1000) {
        // less than a kilometer.... use a standard zoom level?
        //NSLog(@"Area not large enough... using a standard zoom level");
        Venue *venue = venues[0];
        [self.mapViewController.mapView setCamera:[GMSCameraPosition cameraWithLatitude:venue.latitude.floatValue longitude:venue.longitude.floatValue zoom:15]];
    } else {
        //NSLog(@"Fitting the camera to the area bounds");
        [self.mapViewController.mapView setMinZoom:0 maxZoom:1000000];
        [self.mapViewController.mapView moveCamera:[GMSCameraUpdate fitBounds:bounds withPadding:50]];
    }
}


-(void)videoFailedToLoad {
    if (self.isVisible) {
        [self  spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.view title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
    }
}

#pragma mark - Memories CRUD

- (void)spc_localMemoryDeleted:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    if ([self.dataSource.fullFeed containsObject:memory]) {
        NSMutableArray *mutableMemories = [self.dataSource.fullFeed mutableCopy];
        [mutableMemories removeObject:memory];
        NSArray *memories = [mutableMemories copy];
        
        self.dataSource.fullFeed = memories;
        self.dataSource.feed = memories;
    }
    
    [self.tableView reloadData];
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    NSUInteger index = [self.dataSource.feed indexOfObject:memory];
    
    if (NSNotFound != index) {
        Memory *updatedMem = self.dataSource.feed[index];
        [updatedMem updateWithMemory:memory];
        
        self.dataSource.fullFeed = self.dataSource.fullFeed;
        self.dataSource.feed = self.dataSource.feed;
        
        [self.tableView reloadData];
    }
}




@end
