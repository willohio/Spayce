//
//  SPCHereVenueListViewController.m
//  Spayce
//
//  Created by Jake Rosin on 8/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereVenueListViewController.h"
#import "SPCMapDataSource.h"
#import "SPCLocationCell.h"
#import "LocationManager.h"
#import "SPCNoSearchResultsCell.h"

static NSString *CellIdentifier = @"SPCHereVenueListCell";
static NSString *TextCellIdentifier = @"TextCellIdentifier";


@interface SPCHereVenueListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray * allVenues;
@property (nonatomic, strong) Venue * currentVenue;
@property (nonatomic, strong) Venue * deviceVenue;
@property (nonatomic, assign) SpayceState spayceState;

@property (nonatomic, assign) NSInteger memoryCountGold;
@property (nonatomic, assign) NSInteger memoryCountSilver;
@property (nonatomic, assign) NSInteger memoryCountBronze;

@property (nonatomic, strong) NSArray * listVenues;

@property (nonatomic, assign) BOOL manualLocationResetOngoing;

@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UITableView * tableView;

@end

@implementation SPCHereVenueListViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)loadView {
    [super loadView];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRGBHex:0xe6e7e7];
    [self.view addSubview:self.indicator];
    [self.view addSubview:self.label];
    [self.view addSubview:self.tableView];
    [self configureTableView];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
}

#pragma mark - properties

- (UIActivityIndicatorView *)indicator {
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicator.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2 - 120);
        _indicator.color = [UIColor grayColor];
    }
    return _indicator;
}

- (UILabel *)label {
    if (!_label) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20];
        _label.textColor = [UIColor colorWithWhite:201.0f/255.0f alpha:1.0f];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.lineBreakMode = NSLineBreakByWordWrapping;
        _label.numberOfLines = 0;
    }
    return _label;
}

- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        tableView.backgroundColor = [UIColor colorWithRGBHex:0xe6e7e7];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.hidden = YES;
        _tableView = tableView;
    }
    return _tableView;
}

- (void) configureTableView {
    [self.tableView registerClass:[SPCLocationCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[SPCNoSearchResultsCell class] forCellReuseIdentifier:TextCellIdentifier];
}

- (void)setIsAtDeviceVenue:(BOOL)isAtDeviceVenue {
    if (_isAtDeviceVenue != isAtDeviceVenue) {
        _isAtDeviceVenue = isAtDeviceVenue;
        [self reloadData];
    }
}

- (void)setSearchFilter:(NSString *)searchFilter {
    if (![_searchFilter isEqualToString:searchFilter]) {
        _searchFilter = searchFilter;
        [self reloadData];
    }
}


#pragma mark - public methods

-(void)locationResetManually {
    self.manualLocationResetOngoing = YES;
}

-(void)updateVenues:(NSArray *)venues withCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue atDeviceVenue:(BOOL)atDeviceVenue spayceState:(SpayceState)spayceState {
    _isAtDeviceVenue = atDeviceVenue;
    _currentVenue = currentVenue;
    _deviceVenue = deviceVenue;
    _spayceState = spayceState;
    
    // We don't take the venue list directly.  Instead, we apply
    // our own sorting to it, and include the current and device venues
    // if they are not already included.  Otherwise we sort by proxmixity.
    
    Venue *tempV;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized ||[CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        BOOL manualLocationSet = [[LocationManager sharedInstance] userHasManuallySelectedLocation];
        CLLocation *location;
        
        if (manualLocationSet) {
            location = [LocationManager sharedInstance].manualLocation;
        } else {
            location = [LocationManager sharedInstance].currentLocation;
        }
        
        for (tempV in venues) {
            [tempV updateDistance:[location distanceFromLocation:tempV.location]];
        }
    
    }
    
    //Deduplicate
    NSMutableArray *tempVenues = [[NSMutableArray alloc] init];
    for (int i = 0; i < venues.count; i++) {
        Venue *venue = venues[i];
        BOOL alreadyAdded = NO;
        
        for (int j = 0; j < tempVenues.count; j++) {
            Venue *prevVenue = tempVenues[j];
            if (venue.locationId == prevVenue.locationId) {
                alreadyAdded = YES;
                break;
            }
        }
        
        if (!alreadyAdded) {
            [tempVenues addObject:venue];
        }
    }
    
    venues = [NSArray arrayWithArray:tempVenues];
    
    NSArray * sortedVenues = [venues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"distanceAway" ascending:YES]]];
    
    self.allVenues = [NSArray arrayWithArray:sortedVenues];
    
    // We have our complete list of all venues, including current and device venues,
    // in their display order (although they may still be subject to filtering).  The
    // last step is to determine memory counts for gold, silver and bronze stars.
    NSMutableArray * memoryCounts = [NSMutableArray arrayWithCapacity:sortedVenues.count];
    for (Venue * venue in sortedVenues) {
        [memoryCounts addObject:@(venue.totalMemories)];
    }
    
    // sort the stacked memory counts: we use this to determine gold, silver
    // and bronze stars.
    NSArray * sortedMemoryCounts = [memoryCounts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"integerValue" ascending:NO]]];
    // Use selector, not indexing, in case we have a list of length 0.
    self.memoryCountGold = sortedMemoryCounts.count > 0 ? [sortedMemoryCounts[0] integerValue] : 0;
    self.memoryCountSilver = sortedMemoryCounts.count > 1 ? [sortedMemoryCounts[1] integerValue] : 0;
    self.memoryCountBronze = sortedMemoryCounts.count > 2 ? [sortedMemoryCounts[2] integerValue] : 0;
    
    // That's it!  Reload the data.
    [self reloadData];
}


#pragma mark - helper actions

- (void)reloadData {
    // First, determine the appropriate list of venues to display.  We already
    // have a sorted list of venues, so this amounts to applying the search filter
    // (if any) to reduce this list.
    self.listVenues = [self filterVenues:self.allVenues withSearchTerm:self.searchFilter];
    
    if (_label && _indicator) {
        BOOL showLabel = NO;
        BOOL showIndicator = NO;
        switch(self.spayceState) {
            case SpayceStateLocationOff:
                _label.text = NSLocalizedString(@"Spayce requires your location\nto load nearby venues.", nil);
                showLabel = YES;
                self.manualLocationResetOngoing = NO;
                break;
            case SpayceStateDisplayingLocationData:
                self.manualLocationResetOngoing = NO;
            default:
                showIndicator = YES;
                break;
        }
        
        self.label.hidden = !showLabel;
        self.indicator.hidden = !showIndicator;
        if (showLabel) {
            [self.label sizeToFit];
            self.label.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, CGRectGetHeight(self.view.frame)/2 - 80);
        } else {
            [self.indicator startAnimating];
        }
    }
    
    // The rest of the work is done by our table delegate methods.
    if (_tableView) {
        [self.tableView reloadData];
        
        if (self.spayceState >= SpayceStateRetrievingLocationData && self.allVenues.count > 0 && !self.manualLocationResetOngoing) {
            // make sure the table view is visible.
            if (self.tableView.hidden) {
                self.tableView.alpha = 0;
                self.tableView.hidden = NO;
                [UIView animateWithDuration:0.8 animations:^{
                    self.tableView.alpha = 1;
                }];
            }
        } else {
            // make sure the table view is hidden
            if (!self.tableView.hidden) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.tableView.alpha = 0;
                } completion:^(BOOL finished) {
                    self.tableView.hidden = YES;
                }];
            }
        }
    }
}

- (NSArray *)filterVenues:(NSArray *)venues withSearchTerm:(NSString *)searchTerm {
    if (searchTerm) {
        NSArray *wordsAndEmptyStrings = [searchTerm componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *words = [wordsAndEmptyStrings filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        for (NSString * word in words) {
            NSMutableArray * includedVenues = [NSMutableArray arrayWithCapacity:venues.count];
            for (Venue * venue in venues) {
                // match name!  A venue name is a match if venue name or
                // address name matches the string, i.e. it contains the string
                // in a case-insensitive format.
                NSString * venueName = venue.venueName;
                NSString * address = venue.streetAddress;
                NSString * title = venue.displayNameTitle;
                
                BOOL include = venueName && [venueName rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound;
                include = include || (address && [address rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound);
                include = include || (title && [title rangeOfString:word options:NSCaseInsensitiveSearch].location != NSNotFound);
                
                if (include) {
                    [includedVenues addObject:venue];
                }
            }
            
            // that's our new list
            venues = [NSArray arrayWithArray:includedVenues];
        }
    }
    
    return venues;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.allVenues.count > 0 && self.listVenues.count == 0) ? 1 : self.listVenues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.listVenues.count > 0) {
        return [self tableView:tableView venueCellForRowAtIndexPath:indexPath];
    } else {
        return [self tableView:tableView noSearchResultsCellAtIndexPath:indexPath];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView venueCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Venue *venue = self.listVenues[indexPath.row];
    
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
    if (venue.favorited) {
        badges |= spc_LOCATION_CELL_BADGE_FAVORITED;
    }
    
    [cell configureCellWithVenue:venue badges:badges];
    cell.hasSeparator = (indexPath.row != 0);
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView noSearchResultsCellAtIndexPath:(NSIndexPath *)indexPath {
    SPCNoSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:TextCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCNoSearchResultsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TextCellIdentifier];
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (self.allVenues.count > 0 && self.listVenues.count == 0) ? CGRectGetHeight(tableView.frame) : 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Venue * venue = self.listVenues[indexPath.row];
    
   // inform the delegate
    if ([self.delegate respondsToSelector:@selector(hereVenueListViewController:didSelectVenue:)]) {
        [self.delegate hereVenueListViewController:self didSelectVenue:venue];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(hereVenueListViewControllerDismissKeyboard:)]) {
        [self.delegate hereVenueListViewControllerDismissKeyboard:self];
    }
}

@end
