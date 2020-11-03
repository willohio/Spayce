//
//  SPCMAMLocationViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 2/27/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMAMLocationViewController.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>

//Manager
#import "LocationManager.h"
#import "LocationContentManager.h"
#import "VenueManager.h"
#import "MeetManager.h"

// Model
#import "Venue.h"

// View
#import "SPCSearchTextField.h"

// Cell
#import "SPCPickLocationCell.h"

//Category
#import "UITableView+SPXRevealAdditions.h"

static NSString *CellIdentifier = @"SPCMAMLocationCell";


@interface SPCMAMLocationViewController ()

@property (nonatomic, strong) Venue *selectedVenue;
@property (nonatomic, strong) NSArray *nearbyVenues;
@property (nonatomic, strong) NSArray *filteredVenues;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat containerBaseY;

@property (nonatomic, strong) UIView *locationHeader;
@property (nonatomic, strong) SPCSearchTextField * searchBar;
@property (nonatomic, strong) UIImageView *searchIcon;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *clearSearchButton;

@property (nonatomic, strong) UIView *createLocationView;
@property (nonatomic, strong) UILabel *createLocationTitleLbl;
@property (nonatomic, strong) UIButton *createVenueBtn;
@property (nonatomic, strong) UIImageView *createLocPlusImgView;
@property (nonatomic, strong) UIActivityIndicatorView *createSpinner;

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) NSInteger selectedIndex;
@end


@implementation SPCMAMLocationViewController

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (id) initWithNearbyVenues:(NSArray *)nearbyVenues selectedVenue:(Venue *)selectedVenue {
    
    self = [super init];
    
    if (self) {
        self.nearbyVenues = nearbyVenues;
        self.filteredVenues = nearbyVenues;
        self.selectedVenue = selectedVenue;
    }
    return self;
}

-(void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 60)];
    titleLabel.text = @"OTHER LOCATIONS";
    titleLabel.font = [UIFont spc_boldSystemFontOfSize:15];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor colorWithWhite:49.0f/255.0f alpha:1.0f];
    [self.view addSubview:titleLabel];
    
    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 60)];
    [saveBtn setTitle:@"SAVE" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor colorWithRed:76.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    [saveBtn addTarget:self action:@selector(updateVenue) forControlEvents:UIControlEventTouchDown];
    [saveBtn.titleLabel setFont:[UIFont fontWithName:@"OpenSans"  size:10]];
    saveBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    [self.view addSubview:saveBtn];
    
    self.containerBaseY = CGRectGetMaxY(self.mapView.frame);
    
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.containerView];
    
    [self.containerView addSubview:self.locationHeader];
    [self.containerView addSubview:self.createLocationView];
    [self.containerView addSubview:self.tableView];
    
    [self.tableView registerClass:[SPCPickLocationCell class] forCellReuseIdentifier:CellIdentifier];
    [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:self.selectedVenue.location.coordinate.latitude longitude:self.selectedVenue.location.coordinate.longitude zoom:15]];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Accessors

- (GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(0, 60, self.view.bounds.size.width, 135)];
        _mapView.buildingsEnabled = NO;
        _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _mapView.userInteractionEnabled = NO;
        
       //UIEdgeInsets mapInsets = UIEdgeInsetsMake(0.0, 0.0, 50.0, 0.0);
        //_mapView.padding = mapInsets;
        
        [_mapView setMinZoom:14 maxZoom:30];
    }
    return _mapView;
}

-(UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.mapView.frame), self.view.bounds.size.width, self.view.bounds.size.height)];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.userInteractionEnabled = YES;
    }
    return _containerView;
}


-(UIView *)locationHeader {
    
    if (!_locationHeader) {
        _locationHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 50)];
        _locationHeader.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        _locationHeader.userInteractionEnabled = YES;
        
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 49.5, self.view.frame.size.width, .5)];
        sepLine.backgroundColor = [UIColor colorWithWhite:232.0f/255.0f alpha:1.0f];
        [_locationHeader addSubview:sepLine];
        
        [_locationHeader addSubview:self.searchBar];
        [_locationHeader addSubview:self.cancelBtn];
        [_locationHeader addSubview:self.clearSearchButton];
    }
    
    return _locationHeader;
}

-(UIButton *)cancelBtn {
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 80, 12.5, 65, 25)];
        _cancelBtn.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
        _cancelBtn.layer.borderWidth = .5;
        _cancelBtn.layer.cornerRadius = 2;
        [_cancelBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        [_cancelBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancelFiltering) forControlEvents:UIControlEventTouchDown];
        _cancelBtn.hidden = YES;
        
    }
    return _cancelBtn;
}

-(UIButton *)clearSearchButton {
    if (!_clearSearchButton) {
        _clearSearchButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 49, 3, 44, 44)];
        [_clearSearchButton setBackgroundImage:[UIImage imageNamed:@"pickLocCancelSearchIcon"] forState:UIControlStateNormal];
        [_clearSearchButton addTarget:self action:@selector(clearSearch) forControlEvents:UIControlEventTouchDown];
        _clearSearchButton.hidden = YES;
        
    }
    return _clearSearchButton;
}

- (SPCSearchTextField *)searchBar {
    if (!_searchBar) {
        _searchBar = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(0, 10, CGRectGetWidth(self.view.frame) - 20, 30)];
        _searchBar.delegate = self;
        _searchBar.backgroundColor = [UIColor clearColor];
        _searchBar.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _searchBar.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _searchBar.font = [UIFont spc_mediumSystemFontOfSize:14];
        _searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
        _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        _searchBar.leftView.tintColor = [UIColor whiteColor];
        _searchBar.placeholder = @"Search...";
        _searchBar.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
        
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 34, 30)];
        [leftView addSubview:self.searchIcon];
        self.searchIcon.center = CGPointMake(CGRectGetWidth(leftView.bounds)/2.0 + 2, CGRectGetHeight(leftView.bounds)/2.0);
        _searchBar.leftView = leftView;
    }
    return _searchBar;
    
}

- (UIImageView *)searchIcon {
    if (!_searchIcon) {
        _searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"magnifying-glass-off"]];
    }
    return _searchIcon;
}

- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.locationHeader.frame), CGRectGetWidth(self.view.frame), self.view.frame.size.height)];
        tableView.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        _tableView = tableView;
        
        float insetAdj = CGRectGetMaxY(self.mapView.frame) + CGRectGetMaxY(_locationHeader.frame);
        
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
        [_tableView setScrollIndicatorInsets:_tableView.contentInset];

    }
    return _tableView;
}

-(UIView *)createLocationView {
    if (!_createLocationView) {
        
        float expandedHeight = 60;
        
        _createLocationView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 0)];
        _createLocationView.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _createLocationView.clipsToBounds = YES;
        
        UIImageView *iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(15, (expandedHeight - 16)/2, 16, 16)];
        iconImgView.image = [UIImage imageNamed:@"lg-icon-pin-custom"];
        [_createLocationView addSubview:iconImgView];
        
        [_createLocationView addSubview:self.createLocPlusImgView];
        [_createLocationView addSubview:self.createSpinner];
        
        [_createLocationView addSubview:self.createLocationTitleLbl];
        
        UILabel *subHeadLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.createLocationTitleLbl.frame), CGRectGetMaxY(self.createLocationTitleLbl.frame), 300, 15)];
        subHeadLbl.text = NSLocalizedString(@"Create a custom location", nil);
        subHeadLbl.font = [UIFont spc_regularSystemFontOfSize:12];
        subHeadLbl.textColor = [UIColor colorWithRed:187.0f/255.0f green:220.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
        subHeadLbl.backgroundColor = [UIColor clearColor];
        subHeadLbl.textAlignment = NSTextAlignmentLeft;
        [_createLocationView addSubview:subHeadLbl];
        
        [_createLocationView addSubview:self.createVenueBtn];
    }
    
    return _createLocationView;
}

-(UIImageView *)createLocPlusImgView {
    float expandedHeight = 60;
    
    if (!_createLocPlusImgView) {
        _createLocPlusImgView = [[UIImageView alloc] initWithFrame:CGRectMake(_createLocationView.frame.size.width - 40, (expandedHeight - 25)/2, 25, 25)];
        _createLocPlusImgView.image = [UIImage imageNamed:@"pickLocPlusIcon"];
    }
    return _createLocPlusImgView;
}

-(UIActivityIndicatorView *)createSpinner {
    float expandedHeight = 60;
    
    if (!_createSpinner) {
        _createSpinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(self.createLocationView.frame.size.width - 40, (expandedHeight - 25)/2, 25, 25)];
        _createSpinner.color = [UIColor darkGrayColor];
        _createSpinner.hidden = YES;
        
    }
    return _createSpinner;
}

-(UILabel *)createLocationTitleLbl  {
    if (!_createLocationTitleLbl) {
        _createLocationTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(40, 16, 300, 15)];
        _createLocationTitleLbl.font = [UIFont spc_boldSystemFontOfSize:14];
        _createLocationTitleLbl.textColor = [UIColor whiteColor];
        _createLocationTitleLbl.backgroundColor = [UIColor clearColor];
        _createLocationTitleLbl.textAlignment = NSTextAlignmentLeft;
    }
    
    return _createLocationTitleLbl;
}

-(UIButton *)createVenueBtn {
    float expandedHeight = 60;
    
    if (!_createVenueBtn) {
        _createVenueBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.height, expandedHeight)];
        _createVenueBtn.backgroundColor = [UIColor clearColor];
        [_createVenueBtn addTarget:self action:@selector(createNewVenue) forControlEvents:UIControlEventTouchDown];
    }
    return _createVenueBtn;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredVenues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SPCPickLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Venue *venue = self.filteredVenues[indexPath.row];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        location = [LocationManager sharedInstance].currentLocation;
    }
    CGFloat distance = (location && venue.location) ? [location distanceFromLocation:venue.location] : -1;
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    

    
    if(venue.addressId == self.selectedVenue.addressId) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell configureCellWithVenue:venue distance:distance];
    
    return cell;
    
}

#pragma UITableView Delegate Methods


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Venue * venue = self.filteredVenues[indexPath.row];
    self.selectedVenue = venue;
    [tableView reloadData];
    
    if ([self.searchBar isFirstResponder]) {
        [self clearSearch];
        [self cancelFiltering];
    }
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
       [self updateViewForFiltering];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.returnKeyType == UIReturnKeyDefault) {
        // Cancel previous filter request
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        // Schedule delayed filter request in order to allow textField to update it's internal state
        [self performSelector:@selector(performFullSearchFor:) withObject:textField.text afterDelay:0.05];
        // resign
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    
    if (text.length > 0) {
        self.clearSearchButton.hidden = NO;
        self.cancelBtn.hidden = YES;
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-blue"];
    } else {
        self.clearSearchButton.hidden = YES;
        self.cancelBtn.hidden = NO;
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    }
    
    
    if (text.length == 3) {
        [self showCreateLocation];
    }
    if (text.length == 2) {
        [self hideCreateLocation];
    }
    
    
    NSString *customVenName = [NSString stringWithFormat:@"Create \"%@\"",text];
    self.createLocationTitleLbl.text = customVenName;
    
    // Cancel previous filter request
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    

    // Schedule delayed filter request in order to allow textField to update it's internal state
    [self performSelector:@selector(reloadListDataWithSearch:) withObject:text afterDelay:0.2];
    
     
    return YES;
}

#pragma mark Filtering Methods

-(void)updateViewForFiltering {
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.containerView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.locationHeader.frame) + 300, 0);
                         
                     } completion:^(BOOL finished) {
                         self.cancelBtn.hidden = NO;
                         [_tableView setScrollIndicatorInsets:_tableView.contentInset];
                     }];
    
}

-(void)clearSearch {
    
    self.cancelBtn.hidden = NO;
    self.clearSearchButton.hidden = YES;
    self.searchBar.text = @"";
    [self reloadListDataWithSearch:self.searchBar.text];
    
    [self hideCreateLocation];
}

-(void)cancelFiltering {
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.containerView.frame = CGRectMake(0, self.containerBaseY, self.view.bounds.size.width, self.view.bounds.size.height);
                         
                         float insetAdj = CGRectGetMaxY(self.mapView.frame) + CGRectGetMaxY(_locationHeader.frame);
                         _tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
                         
                     } completion:^(BOOL finished) {
                         [_tableView setScrollIndicatorInsets:_tableView.contentInset];
                         
                     }];
}

-(void)reset {
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    //reset search
    self.clearSearchButton.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.searchBar.text = @"";
    [self reloadListDataWithSearch:self.searchBar.text];
    
    //reset location picking items frames and inset
    self.containerView.frame = CGRectMake(0, self.containerBaseY, self.view.bounds.size.width, self.view.bounds.size.height);
    
    
    self.tableView.frame = CGRectMake(0, CGRectGetHeight(self.locationHeader.frame), self.view.frame.size.width, self.view.frame.size.height);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.locationHeader.frame), 0);
}

- (void)reloadListDataWithSearch:(NSString *)search {
    if (search == self.searchBar.text || [self.searchBar.text isEqualToString:search]) {
        // First, determine the appropriate list of venues to display.  We already
        // have a sorted list of venues, so this amounts to applying the search filter
        // (if any) to reduce this list.
        self.filteredVenues = [self filterVenues:self.nearbyVenues withSearchTerm:search];
    } else {
        self.filteredVenues = self.filteredVenues ?: self.nearbyVenues;
    }
    
    self.filteredVenues = [self.filteredVenues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"distanceAway" ascending:YES]]];
    
    // The rest of the work is done by our table delegate methods.
    if (_tableView) {
        [self.tableView reloadData];
    }
}

-(NSArray *)filterVenues:(NSArray *)venues withSearchTerm:(NSString *)searchTerm {
    if (!searchTerm || searchTerm.length == 0) {
        return venues;
    }
    
    NSMutableArray *mut = [[NSMutableArray alloc] initWithCapacity:venues.count];
    for (Venue *venue in venues) {
        if ([self venue:venue matchesSearchText:searchTerm]) {
            [mut addObject:venue];
        }
    }
    return [NSArray arrayWithArray:mut];
}

-(void)performFullSearchFor:(NSString *)searchText {
    [self reloadListDataWithSearch:searchText];
}

-(BOOL)venue:(Venue *)venue matchesSearchTextExactly:(NSString *)searchText {
    // match name!  A venue name is a match if venue name or
    // address name matches the string, i.e. it contains the string
    // in a case-insensitive format.
    NSString * venueName = venue.venueName;
    NSString * address = venue.streetAddress;
    NSString * title = venue.displayNameTitle;
    
    BOOL include = venueName && [venueName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound;
    include = include || (address && [address rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
    include = include || (title && [title rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound);
    
    return include;
}

-(BOOL)venue:(Venue *)venue matchesSearchText:(NSString *)searchText {
    BOOL match = YES;
    if (searchText) {
        NSArray *wordsAndEmptyStrings = [searchText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *words = [wordsAndEmptyStrings filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
        
        for (NSString * word in words) {
            match = match && [self venue:venue matchesSearchTextExactly:word];
        }
    }
    
    return match;
}


#pragma mark Create Location Methods

-(void)showCreateLocation {
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.createLocationView.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 60);
                         self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.createLocationView.frame), self.view.frame.size.width, self.view.frame.size.height - 60);
                         
                         
                     } completion:^(BOOL finished) {
                         
                     }];
}

-(void)hideCreateLocation {
    float insetAdj = CGRectGetMaxY(self.mapView.frame) + CGRectGetMaxY(_locationHeader.frame);
    
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.createLocationView.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 0);
                         self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, self.view.frame.size.height);
                         _tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
                         
                         
                     } completion:^(BOOL finished) {
                         
                     }];
    
}

-(void)createNewVenue {
    
    //activate spinner and hide keyboard
    self.createVenueBtn.userInteractionEnabled = NO;
    self.createLocPlusImgView.hidden = YES;
    self.createSpinner.hidden = NO;
    [self.createSpinner startAnimating];
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    NSString *newVenueName = self.searchBar.text;
    
    float deviceLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
    float deviceLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    
    
    [MeetManager postVenueWithLat:deviceLat longitude:deviceLong name:newVenueName locationMainPhotoId:0 resultCallback:^(Venue * venue) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kSPCDidPostVenue" object:venue];
        [self.delegate spcPickLocationViewControllerDidFinish:self withSelectedVenue:venue];
        
    } faultCallback:^(NSError *fault) {
        NSLog(@"TODO: handle failure");
    }];
    
    
}

#pragma mark Navigation Methods

-(void)updateVenue {
    [self.delegate spcPickLocationViewControllerDidFinish:self withSelectedVenue:self.selectedVenue];
}

@end
