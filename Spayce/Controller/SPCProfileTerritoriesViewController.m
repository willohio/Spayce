//
//  SPCProfileTerritoriesViewController.m
//  Spayce
//
//  Created by Jake Rosin on 11/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileTerritoriesViewController.h"

// Framework
#import "Flurry.h"

// View Controller
#import "MemoryCommentsViewController.h"
#import "SPCVenueDetailViewController.h"
#import "SPCCustomNavigationController.h"
#import "SPCVenueDetailGridTransitionViewController.h"

// Managers
#import "MeetManager.h"
#import "VenueManager.h"
#import "AuthenticationManager.h"

// Model
#import "UserProfile.h"
#import "ProfileDetail.h"
#import "SPCCity.h"
#import "SPCNeighborhood.h"
#import "Venue.h"

// Views
#import "SPCTerritoryCell.h"
#import "SPCTerritoryMemoryCell.h"
#import "SPCTerritoryFavoritedVenueCell.h"
#import "SPCTerritoriesEducationView.h"

// Utils
#import "UIColor+SPCAdditions.h"
#import "UIFont+SPCAdditions.h"
#import "UIImageEffects.h"

// Literals
#import "SPCLiterals.h"

// Constants
#import "Constants.h"


const int TERRITORY_EXPAND_VENUES_BUTTON_TAG_MASK = 0x1000;


typedef NS_ENUM(NSInteger, TerritoryRowType) {
    TerritoryRowTypeTerritory = 0,
    TerritoryRowTypeMemory = 1,
    TerritoryRowTypeVenuesHeader = 2,
    TerritoryRowTypeVenues = 3,
    TerritoryRowTypeVenuesExpansionButton = 4
};


@interface SPCProfileTerritoriesViewController () <UITableViewDataSource, UITableViewDelegate>

// UI
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UITableView *tableView;

// Profile
@property (nonatomic, strong) UserProfile *userProfile;

// Territory list information
@property (nonatomic, readonly) NSInteger cityCount;
@property (nonatomic, readonly) NSInteger neighborhoodCount;
@property (nonatomic, strong) NSArray *territories;
@property (nonatomic, strong) NSArray *popularMemoryInTerritory;
@property (nonatomic, strong) NSArray *favoritedVenuesInTerritory;

// UI state
@property (nonatomic, strong) NSMutableArray *territoryIsExpanded;
@property (nonatomic, strong) NSMutableArray *territoryIsShowingAllFavorites;
@property (nonatomic) BOOL fetchingPopularMemories;
@property (nonatomic) BOOL fetchingFavoritedVenues;

@property (nonatomic, assign) BOOL tabBarWasVisibleOnLoad;

//territories education screen
@property (nonatomic) BOOL educationScreenWasShown; // Persisted value
@property (nonatomic) BOOL presentedEducationScreenInstance; // This instance's value
@property (nonatomic, strong) UIImageView *viewBlurredScreen;
@property (nonatomic, strong) SPCTerritoriesEducationView *viewEducationScreen;
@property (nonatomic, assign) BOOL viewIsVisible;

@end

@implementation SPCProfileTerritoriesViewController

#pragma mark - Object lifespan


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype) initWithUserProfile:(UserProfile *)userProfile {
    self = [super init];
    if (self) {
        self.userProfile = userProfile;
    }
    return self;
}

#pragma mark - View configuration

- (void)loadView {
    [super loadView];
    
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.tableView];
    
    self.tabBarWasVisibleOnLoad = !self.tabBarController.tabBar.hidden;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self fetchPopularMemories];
    [self fetchFavoritedVenues];
    
    [self registerForNotifications];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update tab bar visibility
    self.tabBarController.tabBar.alpha = 0;
    self.tabBarController.tabBar.hidden = YES;
    
    // Hide navigation controller
    self.navigationController.navigationBarHidden = YES;
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewIsVisible = YES;
    
    // Present the education, since our territories are already loaded
    // Conditions: If the territories are for the current user and the user has not yet acknowledged the edu screen
    if (YES == self.userProfile.isCurrentUser && NO == self.presentedEducationScreenInstance && NO == self.educationScreenWasShown) {
        [self presentEducationScreenAfterDelay:@(1.0f)];
    }
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Show bottom bar when popped
    if (self.tabBarWasVisibleOnLoad) {
        self.tabBarController.tabBar.alpha = 1;
        self.tabBarController.tabBar.hidden = NO;
    }
    
    self.viewIsVisible = NO;
}


-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleDefault;
}


#pragma mark - Accessors


- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 70)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectZero];
        backButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        backButton.layer.cornerRadius = 2;
        backButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : backButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [backButton setAttributedTitle:backString forState:UIControlStateNormal];
        backButton.frame = CGRectMake(0, CGRectGetHeight(_navBar.frame) - 44.0f, 60, 44);
        [backButton addTarget:self action:@selector(dismissViewController:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        NSDictionary *titleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x292929],
                                                NSKernAttributeName : @(1.1) };
        NSString *titleText = NSLocalizedString(@"Territories", nil);
        titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleText attributes:titleLabelAttributes];
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:titleLabelAttributes];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_navBar.frame), CGRectGetMidY(backButton.frame) - 1);
        
        CGFloat sepBottomHeight = 1.0f / [UIScreen mainScreen].scale;
        UIView *sepBottom = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(_navBar.frame) - sepBottomHeight, CGRectGetWidth(_navBar.frame), sepBottomHeight)];
        [sepBottom setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
        
        [_navBar addSubview:backButton];
        [_navBar addSubview:titleLabel];
        [_navBar addSubview:sepBottom];
    }
    return _navBar;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.navigationController.view.frame) - CGRectGetMaxY(self.navBar.frame)) style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0f];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.dataSource = self;
        _tableView.delegate = self;
    }
    return _tableView;
}


- (NSInteger)cityCount {
    return self.userProfile.profileDetail.affiliatedCities.count;
}


- (NSInteger)neighborhoodCount {
    return self.userProfile.profileDetail.affiliatedNeighborhoods.count;
}


- (NSArray *)territories {
    if (!_territories) {
        NSMutableArray *mut = [NSMutableArray arrayWithCapacity:self.userProfile.profileDetail.affiliatedCities.count + self.userProfile.profileDetail.affiliatedNeighborhoods.count];
        [mut addObjectsFromArray:self.userProfile.profileDetail.affiliatedCities];
        [mut addObjectsFromArray:self.userProfile.profileDetail.affiliatedNeighborhoods];
        _territories = [NSArray arrayWithArray:mut];
    }
    return _territories;
}


- (NSArray *)popularMemoryInTerritory {
    if (!_popularMemoryInTerritory) {
        NSMutableArray *mut = [NSMutableArray arrayWithCapacity:self.territories.count];
        for (int i = 0; i < self.territories.count; i++) {
            [mut addObject:[NSNull null]];
        }
        _popularMemoryInTerritory = [NSArray arrayWithArray:mut];
    }
    return _popularMemoryInTerritory;
}


- (NSArray *)favoritedVenuesInTerritory {
    if (!_favoritedVenuesInTerritory) {
        NSMutableArray *mut = [NSMutableArray arrayWithCapacity:self.territories.count];
        for (int i = 0; i < self.territories.count; i++) {
            [mut addObject:[NSNull null]];
        }
        _favoritedVenuesInTerritory = [NSArray arrayWithArray:mut];
    }
    return _favoritedVenuesInTerritory;
}


- (NSMutableArray *)territoryIsExpanded {
    if (!_territoryIsExpanded) {
        _territoryIsExpanded = [NSMutableArray arrayWithCapacity:self.territories.count];
        for (int i  = 0; i < self.territories.count; i++) {
            [_territoryIsExpanded addObject:[NSNumber numberWithBool:NO]];
        }
    }
    return _territoryIsExpanded;
}


- (NSMutableArray *)territoryIsShowingAllFavorites {
    if (!_territoryIsShowingAllFavorites) {
        _territoryIsShowingAllFavorites = [NSMutableArray arrayWithCapacity:self.territories.count];
        for (int i  = 0; i < self.territories.count; i++) {
            [_territoryIsShowingAllFavorites addObject:[NSNumber numberWithBool:NO]];
        }
    }
    return _territoryIsShowingAllFavorites;
}


- (BOOL)isTerritoryExpanded:(NSInteger)territory {
    NSNumber *number = self.territoryIsExpanded[territory];
    return number.boolValue;
}

- (void)setTerritory:(NSInteger)territory expanded:(BOOL)expanded {
    NSNumber *number = [NSNumber numberWithBool:expanded];
    self.territoryIsExpanded[territory] = number;
    if (!expanded) {
        [self setTerritory:territory showingAllFavorites:NO];
    }
}

- (BOOL)isTerritoryShowingAllFavorites:(NSInteger)territory {
    NSNumber *number = self.territoryIsShowingAllFavorites[territory];
    return number.boolValue;
}

- (void)setTerritory:(NSInteger)territory showingAllFavorites:(BOOL)showingAllFavorites {
    NSNumber *number = [NSNumber numberWithBool:showingAllFavorites];
    self.territoryIsShowingAllFavorites[territory] = number;
}


# pragma mark - Actions

- (void)dismissViewController:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)fetchPopularMemories {
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i < self.territories.count; i++) {
        NSObject *territoryObject = self.territories[i];
        if (i < self.cityCount) {
            [MeetManager fetchPopularMemoriesByUserWithToken:self.userProfile.userToken city:(SPCCity *)territoryObject count:1 completionHandler:^(NSArray *memories) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                if (memories.count > 0) {
                    Memory *memory = memories[0];
                    NSMutableArray *mut = [NSMutableArray arrayWithArray:strongSelf.popularMemoryInTerritory];
                    mut[i] = memory;
                    strongSelf.popularMemoryInTerritory = [NSArray arrayWithArray:mut];
                    [strongSelf.tableView reloadData];
                }
            } errorHandler:^(NSError *error) {
                NSLog(@"ERROR fetching popular memory in City %@:\n%@", ((SPCCity *)territoryObject).cityName, error);
            }];
        } else {
            [MeetManager fetchPopularMemoriesByUserWithToken:self.userProfile.userToken neighborhood:(SPCNeighborhood *)territoryObject count:1 completionHandler:^(NSArray *memories) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                if (memories.count > 0) {
                    Memory *memory = memories[0];
                    NSMutableArray *mut = [NSMutableArray arrayWithArray:strongSelf.popularMemoryInTerritory];
                    mut[i] = memory;
                    strongSelf.popularMemoryInTerritory = [NSArray arrayWithArray:mut];
                    [strongSelf.tableView reloadData];
                }
            } errorHandler:^(NSError *error) {
                NSLog(@"ERROR fetching popular memory in Neighborhood %@:\n%@", ((SPCNeighborhood *)territoryObject).neighborhood, error);
            }];
        }
    }
}


- (void)fetchFavoritedVenues {
    __weak typeof(self) weakSelf = self;
    for (int i = 0; i < self.territories.count; i++) {
        NSObject *territoryObject = self.territories[i];
        if (i < self.cityCount) {
            [[VenueManager sharedInstance] fetchFavoritedVenuesWithUserToken:self.userProfile.userToken city:(SPCCity *)territoryObject resultCallback:^(NSArray *venues) {
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(totalMemories)) ascending:NO];
                venues = [venues sortedArrayUsingDescriptors:@[sortDescriptor]];
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                NSMutableArray *mut = [NSMutableArray arrayWithArray:strongSelf.favoritedVenuesInTerritory];
                mut[i] = venues;
                strongSelf.favoritedVenuesInTerritory = [NSArray arrayWithArray:mut];
                if (venues.count > 0) {
                    [strongSelf.tableView reloadData];
                }
            } faultCallback:^(NSError *fault) {
                NSLog(@"ERROR fetching favorited venues in City %@:\n%@", ((SPCCity *)territoryObject).cityName, fault);
            }];
        } else {
            
            [[VenueManager sharedInstance] fetchFavoritedVenuesWithUserToken:self.userProfile.userToken neighborhood:(SPCNeighborhood *)territoryObject resultCallback:^(NSArray *venues) {
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(totalMemories)) ascending:NO];
                venues = [venues sortedArrayUsingDescriptors:@[sortDescriptor]];
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return ;
                }
                NSMutableArray *mut = [NSMutableArray arrayWithArray:strongSelf.favoritedVenuesInTerritory];
                mut[i] = venues;
                strongSelf.favoritedVenuesInTerritory = [NSArray arrayWithArray:mut];
                if (venues.count > 0) {
                    [strongSelf.tableView reloadData];
                }
            } faultCallback:^(NSError *fault) {
                NSLog(@"ERROR fetching favorited venues in Neighborhood %@:\n%@", ((SPCNeighborhood *)territoryObject).neighborhood, fault);
            }];
        }
    }
}


- (void)registerForNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTapFavoritedVenueNotification:) name:SPCTerritoryFavoritedVenueTappedNotification object:nil];
    
    // TODO: respond to Memory / Venue updates
}


- (void)expandFavoriteVenues:(id)sender {
    UIButton *button = sender;
    int section = (int)button.tag - TERRITORY_EXPAND_VENUES_BUTTON_TAG_MASK;
    
    [self setTerritory:section showingAllFavorites:YES];
    [self.tableView reloadData];
}


- (void)didTapFavoritedVenueNotification:(NSNotification *)notification {
    // Push venue feed
    SPCTerritoryFavoritedVenueCellVenueTapped *venueTapped = notification.object;
    
    if (venueTapped && venueTapped.venue) {
        if (venueTapped.memoryDisplayed) {
            //capture image of screen to use in MAM completion animation
            UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, YES, 0);
            CGContextRef context = UIGraphicsGetCurrentContext();
            [self.view.layer renderInContext:context];
            UIImage *currentScreenImg = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            SPCVenueDetailGridTransitionViewController *vc = [[SPCVenueDetailGridTransitionViewController alloc] init];
            vc.venue = venueTapped.venue;
            vc.memory = venueTapped.memoryDisplayed;
            vc.backgroundImage = currentScreenImg;
            vc.gridCellImage = venueTapped.imageDisplayed;
            vc.gridCellFrame = venueTapped.gridRect;
            
            // clip rect?
            CGFloat top = CGRectGetMaxY(self.navBar.frame);
            CGFloat bottom = CGRectGetMaxY(self.view.frame);
            //NSLog(@"mask to the area from %f to %f", top, bottom);
            CGRect maskRect = CGRectMake(0, top, CGRectGetWidth(self.view.frame), bottom-top);
            vc.gridClipFrame = maskRect;
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:vc];
            navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
            [self presentViewController:navController animated:NO completion:nil];
        } else {
            SPCVenueDetailViewController *venueDetailViewController = [[SPCVenueDetailViewController alloc] init];
            venueDetailViewController.venue = venueTapped.venue;
            
            
            SPCCustomNavigationController *navController = [[SPCCustomNavigationController alloc] initWithRootViewController:venueDetailViewController];
            navController.spc_interfaceOrientation = UIInterfaceOrientationPortrait;
            
            
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
}


# pragma mark - UITableViewDataSource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // one section for each territory
    return self.territories.count;
}

- (TerritoryRowType)territoryRowTypeForIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case 0:
            return TerritoryRowTypeTerritory;
            
        case 1:
            if ([self.popularMemoryInTerritory[indexPath.section] isKindOfClass:[NSNull class]]) {
                return TerritoryRowTypeVenuesHeader;
            } else {
                return TerritoryRowTypeMemory;
            }
            
        case 2:
            if ([self.popularMemoryInTerritory[indexPath.section] isKindOfClass:[NSNull class]]) {
                return TerritoryRowTypeVenues;
            } else {
                return TerritoryRowTypeVenuesHeader;
            }
            
        case 3:
            if ([self.popularMemoryInTerritory[indexPath.section] isKindOfClass:[NSNull class]] && ![self isTerritoryShowingAllFavorites:indexPath.section]) {
                return TerritoryRowTypeVenuesExpansionButton;
            } else {
                return TerritoryRowTypeVenues;
            }
            
        case 4:
            if (![self.popularMemoryInTerritory[indexPath.section] isKindOfClass:[NSNull class]] && ![self isTerritoryShowingAllFavorites:indexPath.section]) {
                return TerritoryRowTypeVenuesExpansionButton;
            } else {
                return TerritoryRowTypeVenues;
            }
            
        default:
            return TerritoryRowTypeVenues;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // if the territory is not expanded, we have exactly 1 row.
    // Otherwise sum up the following:
    // 1 (territory)
    // 1 (if we have a popular memory)
    // 2 (if we have between 1 and 3 favorited venues - label and favorited row)
    // 3 (if we have > 3 favorited venues and venues are not expanded - label, favorited row, expand button)
    // 2 + (#venues-1 / 3) (if we have > 3 favorited venues and venues are expanded)
    
    if (![self isTerritoryExpanded:section]) {
        return 1;
    } else {
        NSInteger cells = 1;    // territory
        if (![self.popularMemoryInTerritory[section] isKindOfClass:[NSNull class]]) {
            cells++;
        }
        if (![self.favoritedVenuesInTerritory[section] isKindOfClass:[NSNull class]]) {
            // an array of arrays
            NSArray *venues = self.favoritedVenuesInTerritory[section];
            if (venues.count >= 1 && venues.count < 4) {
                cells += 2;
            } else if (venues.count >= 4) {
                cells += [self isTerritoryShowingAllFavorites:section] ? 1 + ((venues.count + 2) / 3) : 3;
            }
        }
        
        //NSLog(@"%d cells in section %d", cells, section);
        return cells;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TerritoryRowType rowType = [self territoryRowTypeForIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    UIViewController *vc;
    
    switch(rowType) {
        case TerritoryRowTypeTerritory:
            [Flurry logEvent:@"TERRITORIES_TERRITORY_TAPPED"];
            [self setTerritory:indexPath.section expanded:![self isTerritoryExpanded:indexPath.section]];
            [self.tableView reloadData];
            break;
            
        case TerritoryRowTypeMemory:
            // push a comments VC for this memory
            vc = [[MemoryCommentsViewController alloc] initWithMemory:self.popularMemoryInTerritory[indexPath.section]];
            [self.navigationController pushViewController:vc animated:YES];
            break;
            
        case TerritoryRowTypeVenuesHeader:
            // no effect
            break;
            
        case TerritoryRowTypeVenues:
            // not selectable.  ignore.  It is inside this cell that
            // venues are individually selectable.
            break;
            
        case TerritoryRowTypeVenuesExpansionButton:
            [self setTerritory:indexPath.section showingAllFavorites:![self isTerritoryShowingAllFavorites:indexPath.section]];
            [self.tableView reloadData];
            break;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    TerritoryRowType rowType = [self territoryRowTypeForIndexPath:indexPath];
    
    CGFloat width;
    CGFloat height;
    
    switch(rowType) {
        case TerritoryRowTypeTerritory:
            return 140;
            
        case TerritoryRowTypeMemory:
            return 125;
            
        case TerritoryRowTypeVenuesHeader:
            return 35;
            
        case TerritoryRowTypeVenues:
            // venue row:
            // squares of about 1/3 the screen width, plus some padding in between.
            // padding is:
            //                  4       4.7         5.5
            // sides (total)    20      20          ?
            // inner (total)    16      22          ?
            // total            36      42          ?
            //
            // height is the square width, plus 48, plus 14.
            width = CGRectGetWidth([UIScreen mainScreen].bounds);
            
            //4.7"
            if ([UIScreen mainScreen].bounds.size.width == 375) { // 4.7"
                width -= 42;
            } else if ([UIScreen mainScreen].bounds.size.width > 375) { // 5.5"
                width -= 42;
            } else {                                 // 4"
                width -= 36;
            }
            width /= 3;
            height = floor(width + 48 + 8);
            return height;
            
        case TerritoryRowTypeVenuesExpansionButton:
            return 68;
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TerritoryRowType rowType = [self territoryRowTypeForIndexPath:indexPath];
    
    switch(rowType) {
        case TerritoryRowTypeTerritory:
            // the territory cell
            return [self tableView:tableView territoryCellForRowAtIndexPath:(NSIndexPath *)indexPath];
            
        case TerritoryRowTypeMemory:
            // popular memory cell
            return [self tableView:tableView memoryCellForRowAtIndexPath:(NSIndexPath *)indexPath];
            
        case TerritoryRowTypeVenuesHeader:
            // a simple header w/o any customized content
            return [self tableView:tableView venueHeaderCellForRowAtIndexPath:(NSIndexPath *)indexPath];
            
        case TerritoryRowTypeVenues:
            // a row of
            return [self tableView:tableView venueCellForRowAtIndexPath:(NSIndexPath *)indexPath];
            
        case TerritoryRowTypeVenuesExpansionButton:
            // a simple header w/o any customized content
            return [self tableView:tableView venueExpansionButtonCellForRowAtIndexPath:(NSIndexPath *)indexPath];
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView territoryCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TerritoryCell";
    SPCTerritoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[SPCTerritoryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section < self.userProfile.profileDetail.affiliatedCities.count) {
        // city
        SPCCity *city = self.territories[indexPath.section];
        [cell configureWithCity:city cityNumber:indexPath.section expanded:[self isTerritoryExpanded:indexPath.section]];
    } else {
        // neighborhood
        SPCNeighborhood *neighborhood = self.territories[indexPath.section];
        [cell configureWithNeighborhood:neighborhood neighborhoodNumber:(indexPath.section - self.userProfile.profileDetail.affiliatedCities.count) expanded:[self isTerritoryExpanded:indexPath.section]];
    }
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView memoryCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"MemoryCell";
    SPCTerritoryMemoryCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[SPCTerritoryMemoryCell alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 125) reuseIdentifier:CellIdentifier];
    }
    
    [cell configureWithMemory:self.popularMemoryInTerritory[indexPath.section]];
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView venueHeaderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"VenueHeaderCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.imageView.image = [UIImage imageNamed:@"territory-favorite-heart"];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.75;
        cell.textLabel.font = [UIFont spc_mediumSystemFontOfSize:12];
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor colorWithRGBHex:0x9aa2b0];
        cell.textLabel.text = @"Favorited Venues";
        
        UIView *graySep = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetHeight(tableView.frame), 1.0 / [UIScreen mainScreen].scale)];
        graySep.backgroundColor = [UIColor colorWithRGBHex:0xe6e7e7];
        [cell.contentView addSubview:graySep];
    }
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView venueCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"VenueCell";
    SPCTerritoryFavoritedVenueCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[SPCTerritoryFavoritedVenueCell alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 147) reuseIdentifier:CellIdentifier];
    }
    
    // We want up to 3 venues.  Determine from the row # what our offset is.
    int venueRow = (int)indexPath.row - 2;
    if (![self.popularMemoryInTerritory[indexPath.section] isKindOfClass:[NSNull class]]) {
        venueRow--;
    }
    
    NSArray *allVenues = self.favoritedVenuesInTerritory[indexPath.section];
    int start = venueRow * 3;
    int end = MIN((int)allVenues.count, (int)(start + 3));
    
    NSArray *venues = [allVenues subarrayWithRange:NSMakeRange(start, end - start)];
    [cell configureWithVenues:venues];
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView venueExpansionButtonCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"VenueExpansionButtonCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIButton *expandButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 30)];
        expandButton.center = CGPointMake(CGRectGetWidth(tableView.frame)/2, 29);
        [expandButton setTitleColor:[UIColor colorWithRGBHex:0x6ab1fb] forState:UIControlStateNormal];
        expandButton.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:12];
        [expandButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 0, 0, 0)];
        expandButton.backgroundColor = [UIColor whiteColor];
        expandButton.layer.borderColor = [UIColor colorWithRGBHex:0x6ab1fb].CGColor;
        expandButton.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        expandButton.layer.cornerRadius = 15;
        [expandButton addTarget:self action:@selector(expandFavoriteVenues:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:expandButton];
        
        cell.tag = 0;
        expandButton.tag = TERRITORY_EXPAND_VENUES_BUTTON_TAG_MASK;
    }
    
    int prevTag = (int)cell.tag + TERRITORY_EXPAND_VENUES_BUTTON_TAG_MASK;
    UIButton *button = (UIButton *)[cell.contentView viewWithTag:prevTag];
    [button setTitle:[NSString stringWithFormat:@"View All %i Favorites", (int)[self.favoritedVenuesInTerritory[indexPath.section] count]] forState:UIControlStateNormal];
    
    cell.tag = indexPath.section;
    button.tag = TERRITORY_EXPAND_VENUES_BUTTON_TAG_MASK + indexPath.section;
    
    return cell;
}

#pragma mark - Education

- (void)presentEducationScreenAfterDelay:(NSNumber *)delayInSeconds {
    
    if (self.viewIsVisible) {
        
        __weak typeof(self) weakSelf = self;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([delayInSeconds floatValue] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            if (strongSelf.viewIsVisible && !strongSelf.presentedEducationScreenInstance) {
                
                strongSelf.presentedEducationScreenInstance = YES;
                
                UIImage *imageBlurred = [UIImageEffects takeSnapshotOfView:strongSelf.view];
                imageBlurred = [UIImageEffects imageByApplyingBlurToImage:imageBlurred withRadius:5.0 tintColor:[UIColor colorWithWhite:0 alpha:0.4] saturationDeltaFactor:2.0 maskImage:nil];
                strongSelf.viewBlurredScreen = [[UIImageView alloc] initWithImage:imageBlurred];
                
                
                CGRect frameToPresent = CGRectMake(10, (CGRectGetHeight(strongSelf.view.bounds) - 700.0f/1136.0f * CGRectGetHeight(self.view.bounds)) / 2, CGRectGetWidth(strongSelf.view.bounds) - 20, 700.0f/1136.0f * CGRectGetHeight(self.view.bounds));
                strongSelf.viewEducationScreen = [[SPCTerritoriesEducationView alloc] initWithFrame:frameToPresent];
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
    NSString *strEducationStringUserLiteralKey = [SPCLiterals literal:kSPCTerritoriesEducationScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setBool:educationScreenWasShown forKey:strEducationStringUserLiteralKey];
}

- (BOOL)educationScreenWasShown {
    BOOL wasShown = NO;
    
    NSString *strEducationStringUserLiteralKey = [SPCLiterals literal:kSPCTerritoriesEducationScreenWasShown forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:strEducationStringUserLiteralKey]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:strEducationStringUserLiteralKey];
    }
    
    return wasShown;
}

@end
