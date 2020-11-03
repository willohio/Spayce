//
//  SPCNearbyVenuesViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNearbyVenuesView.h"
#import "HMSegmentedControl.h"

#import "SPCLocationCell.h"
#import "SPCNoSearchResultsCell.h"
#import "LocationManager.h"
#import "SPCSearchTextField.h"
#import "AuthenticationManager.h"

static NSString *CellIdentifier = @"SPCHereVenueListCell";
static NSString *TextCellIdentifier = @"TextCellIdentifier";

@interface SPCNearbyVenuesView ()

@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *plusButton;

@property (nonatomic, strong) UIView *segControlContainer;
@property (nonatomic, strong) HMSegmentedControl *hmSegmentedControl;

@property (nonatomic, strong) UIView *searchContainer;
@property (nonatomic, strong) UIImageView *searchIcon;

@property (nonatomic, strong) SPCSearchTextField *textField;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *allVenues;
@property (nonatomic, strong) NSArray * listVenues;

@property (nonatomic, strong) NSString * searchFilter;

@property (nonatomic, assign) NSInteger memoryCountGold;
@property (nonatomic, assign) NSInteger memoryCountSilver;
@property (nonatomic, assign) NSInteger memoryCountBronze;

@property (nonatomic, strong) UIView *listContainerView;


@end

@implementation SPCNearbyVenuesView

-(void)dealloc  {
    // Cancel any previous requests that were set to execute on a delay!!
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization codex
        [self addSubview:self.listContainerView];
        [self addSubview:self.mapContainerView];
        [self addSubview:self.navBar];

        [self addSubview:self.segControlContainer];

        
        self.backgroundColor = [UIColor whiteColor];
        [self.listContainerView addSubview:self.tableView];
        [self.listContainerView addSubview:self.searchContainer];
        
        [self addSubview:self.plusButton];
        [self configureTableView];
    }
    return self;
}


#pragma mark - Accessors

- (UIView *)navBar {
    
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.frame), 69)];
        _navBar.backgroundColor = [UIColor whiteColor];
        _navBar.hidden = NO;
        
        UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        closeButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        closeButton.layer.cornerRadius = 2;
        closeButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : closeButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Back" attributes:backStringAttributes];
        [closeButton setAttributedTitle:backString forState:UIControlStateNormal];
        closeButton.frame = CGRectMake(0, CGRectGetHeight(_navBar.frame) - 44.0f, 60, 44);
        [closeButton addTarget:self action:@selector(closeButtonActivated:) forControlEvents:UIControlEventTouchUpInside];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont spc_boldSystemFontOfSize:17];
        titleLabel.text = NSLocalizedString(@"Nearby", nil);
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : titleLabel.font }];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_navBar.frame), CGRectGetMidY(closeButton.frame) - 1);
        titleLabel.textColor = [UIColor colorWithRGBHex:0x292929];
        

        [_navBar addSubview:closeButton];
        [_navBar addSubview:titleLabel];

    }
    return _navBar;
    
}

- (UIView *)segControlContainer {
    if (!_segControlContainer) {
        _segControlContainer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), self.bounds.size.width, 37)];
        _segControlContainer.backgroundColor = [UIColor whiteColor];
        
        UIView *sepView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 1)];
        sepView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:243.0f/255.0f blue:245.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepView];
        
        [_segControlContainer addSubview:self.hmSegmentedControl];
        
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - .5, 11.5, 1, 17)];
        sepLine.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [_segControlContainer addSubview:sepLine];
    }
    
    return _segControlContainer;
}

- (HMSegmentedControl *)hmSegmentedControl {
    if (!_hmSegmentedControl) {
        _hmSegmentedControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"MAP", @"LIST"]];
        _hmSegmentedControl.frame = CGRectMake(0, 1, _segControlContainer.frame.size.width, 36);
        [_hmSegmentedControl addTarget:self action:@selector(segmentedControlChangedValue:) forControlEvents:UIControlEventValueChanged];
        
        _hmSegmentedControl.backgroundColor = [UIColor whiteColor];
        _hmSegmentedControl.textColor = [UIColor colorWithRed:139.0f/255.0f  green:153.0f/255.0f  blue:175.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectedTextColor = [UIColor colorWithRed:106.0f/255.0f  green:177.0f/255.0f  blue:251.0f/255.0f alpha:1.0f];
        _hmSegmentedControl.selectionIndicatorColor = [UIColor whiteColor];
        _hmSegmentedControl.selectionStyle = HMSegmentedControlSelectionStyleBox;
        _hmSegmentedControl.selectionIndicatorHeight = 0;
        _hmSegmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationNone;
        _hmSegmentedControl.shouldAnimateUserSelection = NO;
        _hmSegmentedControl .selectedSegmentIndex = 0;
        
    }
    
    return _hmSegmentedControl;
}

-(UIView *)listContainerView {
    if (!_listContainerView) {
        _listContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width, 0, self.bounds.size.width,self.bounds.size.height)];
    }
    return _listContainerView;
}


-(UIView *)mapContainerView {
    if (!_mapContainerView) {
        _mapContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width,self.bounds.size.height)];
        _mapContainerView.clipsToBounds = YES;
    }
    return _mapContainerView;
}

- (UIView *)searchContainer {
    
    if (!_searchContainer) {
        _searchContainer = [[UIView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(self.segControlContainer.frame) + 2, self.bounds.size.width-20, 30)];
        _searchContainer.backgroundColor = [UIColor whiteColor];
        _searchContainer.layer.borderColor = [UIColor colorWithRGBHex:0xe2e6e9].CGColor;
        _searchContainer.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _searchContainer.layer.cornerRadius = 16;
        
        [_searchContainer addSubview:self.textField];
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
        _textField = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(0, 0, self.searchContainer.frame.size.width - 20, self.searchContainer.frame.size.height)];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _textField.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _textField.font = [UIFont spc_mediumSystemFontOfSize:14];
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.leftView.tintColor = [UIColor whiteColor];
        _textField.placeholder = @"Search nearby venues...";
        _textField.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
        
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 34, 30)];
        [leftView addSubview:self.searchIcon];
        self.searchIcon.center = CGPointMake(CGRectGetWidth(leftView.bounds)/2.0 + 2, CGRectGetHeight(leftView.bounds)/2.0);
        _textField.leftView = leftView;
    }
    return _textField;
    
}


- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        float yOrigin = CGRectGetMaxY(self.segControlContainer.frame) + 40;
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, yOrigin, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame)-yOrigin)];
        tableView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        tableView.hidden = NO;
        tableView.contentInset = UIEdgeInsetsMake(0, 0, 45, 0);
        _tableView = tableView;
    }
    return _tableView;
}

- (UIButton *)plusButton {
    
    if (!_plusButton) {
        _plusButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.bounds.size.height - 45, self.bounds.size.width, 45)];
        [_plusButton setBackgroundColor:[UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:.9f]];
        [_plusButton setImage:[UIImage imageNamed:@"create-plus-white"] forState:UIControlStateNormal];
        [_plusButton addTarget:self action:@selector(plusButtonActivated:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _plusButton;
}


- (void) configureTableView {
    [self.tableView registerClass:[SPCLocationCell class] forCellReuseIdentifier:CellIdentifier];
    [self.tableView registerClass:[SPCNoSearchResultsCell class] forCellReuseIdentifier:TextCellIdentifier];
}

#pragma mark - Segmented Control
- (void)segmentedControlChangedValue:(HMSegmentedControl *)segmentedControl {
    NSLog(@"seg control selected segment %li",segmentedControl.selectedSegmentIndex);
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        
        if ([self.textField isFirstResponder]) {
            [self.textField resignFirstResponder];
        }
        
        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             self.listContainerView.center = CGPointMake(self.bounds.size.width/2 + self.bounds.size.width, self.listContainerView.center.y);
                             self.mapContainerView.center = CGPointMake(self.bounds.size.width/2, self.mapContainerView.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
    }

    if (segmentedControl.selectedSegmentIndex == 1) {

        [UIView animateWithDuration:0.2
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             
                             self.listContainerView.center = CGPointMake(self.bounds.size.width/2, self.listContainerView.center.y);
                             self.mapContainerView.center = CGPointMake(-1 * self.bounds.size.width/2, self.mapContainerView.center.y);
                             
                         } completion:^(BOOL finished) {
                             if (finished) {
                                 
                             }
                         }];
    }
}


#pragma mark - public methods

-(void)skipToMap {
    self.hmSegmentedControl.selectedSegmentIndex = 0;
    self.listContainerView.center = CGPointMake(self.bounds.size.width/2 + self.bounds.size.width, self.listContainerView.center.y);
    self.mapContainerView.center = CGPointMake(self.bounds.size.width/2, self.mapContainerView.center.y);
}

-(void)updateVenues:(NSArray *)venues {
    
    // We don't take the venue list directly.  Instead, we apply
    // our own sorting to it, and include the current and device venues
    // if they are not already included.  Otherwise we sort by proxmixity.
    
    Venue *tempV;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        BOOL manualLocationSet = [[LocationManager sharedInstance] userHasManuallySelectedLocation];
        CLLocation *location;
        
        if (manualLocationSet) {
            location = [LocationManager sharedInstance].manualLocation;
        } else {
            location = [LocationManager sharedInstance].currentLocation;
        }
        
        for (tempV in venues) {
            if (tempV.specificity == SPCVenueIsReal) {
                [tempV updateDistance:[location distanceFromLocation:tempV.location]];
            }
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
    sortedVenues = [sortedVenues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"specificity" ascending:NO]]];
    
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
    [self.tableView reloadData];
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

-(void)closeButtonActivated:(id)sender {
    
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
    
    [self.delegate hideNearbyVenues];
}

-(void)plusButtonActivated:(id)sender {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
    
    if ([AuthenticationManager sharedInstance].currentUser) {
        // Required method - no need to check if the delegate implements this
        [self.delegate showCreateVenueViewControllerWithVenues:self.allVenues]; }
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
    }
    

}

-(void)filterContentForSearchText:(NSString *)searchText {
    // perform the search...
    self.searchFilter = searchText;
}

- (void)setSearchFilter:(NSString *)searchFilter {
    if (![_searchFilter isEqualToString:searchFilter]) {
        _searchFilter = searchFilter;
        [self reloadData];
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDefault) {
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(filterContentForSearchText:) withObject:textField.text afterDelay:0.05];
        
        [textField resignFirstResponder];
        
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (text.length == 0) {
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
        
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        textField.text = nil;
        self.searchFilter = nil;
    } else {
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-blue"];
        
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(filterContentForSearchText:) withObject:text afterDelay:.5];
    }
    
    return YES;
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
        cell.userInteractionEnabled = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (self.allVenues.count > 0 && self.listVenues.count == 0) ? CGRectGetHeight(tableView.frame) : (SPCVenueIsReal < ((Venue *)self.listVenues[indexPath.row]).specificity) ? 90 : 70;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < self.listVenues.count) {
        Venue * venue = self.listVenues[indexPath.row];
        
        // inform the delegate
        if ([self.delegate respondsToSelector:@selector(showVenueDetail:)]) {
            [self.delegate showVenueDetail:venue];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.textField isFirstResponder]) {
        [self.textField resignFirstResponder];
    }
}

@end
