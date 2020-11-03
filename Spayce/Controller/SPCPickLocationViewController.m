//
//  SPCPickLocationViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 1/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCPickLocationViewController.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>
#import "Flurry.h"

//Manager
#import "LocationManager.h"
#import "LocationContentManager.h"
#import "VenueManager.h"
#import "MeetManager.h"

//view
#import "SPCSearchTextField.h"

//cell
#import "SPCPickLocationCell.h"

//model
#import "SPCCity.h"

static NSString *CellIdentifier = @"SPCHereVenueListCell";

#define MINIMUM_LOCATION_MANAGER_UPTIME 6

@interface SPCPickLocationViewController ()

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *mapBtn;
@property (nonatomic, strong) UIImageView *imagePreview;
@property (nonatomic, strong) GMSMapView *mapView;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) CGFloat containerBaseY;

@property (nonatomic, strong) UILabel *chooseLocationPrompt;

@property (nonatomic, strong) UIView *locationHeader;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *clearSearchButton;

@property (nonatomic, strong) UIView *fuzzedHeader;
@property (nonatomic, strong) UILabel *fuzzedTitleLbl;
@property (nonatomic, strong) UILabel *fuzzedSubHeadLbl;
@property (nonatomic, strong) UIButton *fuzzedVenueBtn;
@property (nonatomic, strong) UIActivityIndicatorView *fuzzedSpinner;

@property (nonatomic, strong) UIView *createLocationView;
@property (nonatomic, strong) UILabel *createLocationTitleLbl;
@property (nonatomic, strong) UIButton *createVenueBtn;
@property (nonatomic, strong) UIImageView *createLocPlusImgView;
@property (nonatomic, strong) UIActivityIndicatorView *createSpinner;

@property (nonatomic, strong) UIActivityIndicatorView *geocodingSpinner;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UILabel *locationRequiredPrompt;
@property (nonatomic, strong) UIImageView *locationArrowPrompt;

@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, strong) NSArray *filteredVenues;
@property (nonatomic, strong) Venue *fuzzedVenue;
@property (nonatomic, strong) SPCSearchTextField * searchBar;
@property (nonatomic, strong) UIImageView *searchIcon;
@property (nonatomic, assign) BOOL performingRefresh;

@property (nonatomic, strong) NSArray *territories;
@property (nonatomic, assign) BOOL hasGPS;
@end



@implementation SPCPickLocationViewController


-(void)dealloc {

    
}

-(void)loadView {
    [super loadView];
    NSLog(@"SPCPickLocationViewController load view");
    
    self.view.backgroundColor = [UIColor colorWithRed:34.0f/255.0f green:40.0f/255.0f blue:46.0f/255.0f alpha:1.0f];
    [self.view addSubview:self.imagePreview];
    [self.view addSubview:self.mapView];
    [self.view addSubview:self.backBtn];
    
    self.containerBaseY = self.view.bounds.size.height - 385;
    
    if ([UIScreen mainScreen].bounds.size.width >= 414) {
        self.containerBaseY =  CGRectGetMaxY(self.imagePreview.frame) - 35;
    }    
    
    [self.view addSubview:self.containerView];
    [self.containerView addSubview:self.chooseLocationPrompt];
    [self.containerView addSubview:self.mapBtn];
    [self.containerView addSubview:self.locationHeader];
    [self.containerView addSubview:self.fuzzedHeader];
    [self.containerView addSubview:self.createLocationView];
    [self.containerView addSubview:self.tableView];
    [self.containerView addSubview:self.geocodingSpinner];
    [self.containerView addSubview:self.locationRequiredPrompt];
    [self.containerView addSubview:self.locationArrowPrompt];
    
    [self.tableView registerClass:[SPCPickLocationCell class] forCellReuseIdentifier:CellIdentifier];
    

}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"SPCPickLocationViewController viewDidLoad");
    
    [self fetchNearbyLocations:NO];
    self.navigationController.navigationBarHidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spc_hideStatusBar" object:nil];
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"spc_hideStatusBar" object:nil];
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

#pragma mark Accessors

-(UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 56, 31)];
        [_backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _backBtn.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.3];
        _backBtn.layer.borderColor = [UIColor colorWithWhite:1 alpha:1.0f].CGColor;
        _backBtn.layer.borderWidth = .5;
        _backBtn.layer.cornerRadius = 2;
        _backBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
        _backBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _backBtn.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _backBtn.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
        [_backBtn setTitle:@"Back" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

-(UIButton *)mapBtn {
    if (!_mapBtn) {
        _mapBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 47,CGRectGetMinY(self.chooseLocationPrompt.frame), 47, 35)];
        [_mapBtn setTitle:@"Map" forState:UIControlStateNormal];
        _mapBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:10];
        [_mapBtn setTitleColor:[UIColor colorWithWhite:117.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        
        [_mapBtn addTarget:self action:@selector(toggleMap) forControlEvents:UIControlEventTouchDown];
    }
    return _mapBtn;
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

-(UIImageView *)imagePreview {
    if (!_imagePreview) {
        _imagePreview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
        _imagePreview.backgroundColor = [UIColor clearColor];
        _imagePreview.contentMode = UIViewContentModeScaleAspectFill;
        _imagePreview.clipsToBounds = YES;
    }
    return _imagePreview;
}

- (GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:self.imagePreview.frame];
        _mapView.buildingsEnabled = NO;
        _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _mapView.userInteractionEnabled = YES;
        _mapView.hidden = YES;
        
        UIEdgeInsets mapInsets = UIEdgeInsetsMake(0.0, 0.0, 50.0, 0.0);
        _mapView.padding = mapInsets;
        
        [_mapView setMinZoom:14 maxZoom:30];
    }
    return _mapView;
}


-(UIView *)containerView {

    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.userInteractionEnabled = YES;
    }
    return _containerView;
}

-(UILabel *)chooseLocationPrompt {
    if (!_chooseLocationPrompt) {
        _chooseLocationPrompt = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,35)];
        _chooseLocationPrompt.font = [UIFont spc_boldSystemFontOfSize:17];
        _chooseLocationPrompt.text = NSLocalizedString(@"Where is this happening?", nil);
        _chooseLocationPrompt.textColor = [UIColor whiteColor];
        _chooseLocationPrompt.backgroundColor = [UIColor colorWithRed:34.0f/255.0f green:40.0f/255.0f blue:46.0f/255.0f alpha:0.5f];
        _chooseLocationPrompt.textAlignment = NSTextAlignmentCenter;

    }
    return _chooseLocationPrompt;
}

-(UIView *)locationHeader {
    
    if (!_locationHeader) {
        _locationHeader = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.chooseLocationPrompt.frame), self.view.frame.size.width, 50)];
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

-(UIView *)fuzzedHeader {
    if (!_fuzzedHeader) {
        _fuzzedHeader = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 62)];
        _fuzzedHeader.backgroundColor = [UIColor whiteColor];
        
        UIImageView *iconImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pickLocFuzzIcon"]];
        iconImgView.center = CGPointMake(31,_fuzzedHeader.frame.size.height/2);
        [_fuzzedHeader addSubview:iconImgView];
        
        [_fuzzedHeader addSubview:self.fuzzedTitleLbl];
        [_fuzzedHeader addSubview:self.fuzzedSubHeadLbl];
        [_fuzzedHeader addSubview:self.fuzzedSpinner];
        
        UIView *sepLine = [[UIView alloc] initWithFrame:CGRectMake(0, 61.5, self.view.frame.size.width, .5)];
        sepLine.backgroundColor = [UIColor colorWithWhite:232.0f/255.0f alpha:1.0f];
       [_fuzzedHeader addSubview:sepLine];
    
        [_fuzzedHeader addSubview:self.fuzzedVenueBtn];
        
    }
    return _fuzzedHeader;
}

-(UILabel *)fuzzedTitleLbl {
    if (!_fuzzedTitleLbl) {
        _fuzzedTitleLbl = [[UILabel alloc] initWithFrame:CGRectMake(59,17, 300, 16)];
        _fuzzedTitleLbl.font = [UIFont spc_boldSystemFontOfSize:14];
        _fuzzedTitleLbl.textColor = [UIColor colorWithRed:76.0f/255.0f green:154.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
        _fuzzedTitleLbl.textAlignment = NSTextAlignmentLeft;
    }
    return _fuzzedTitleLbl;
}

-(UILabel *)fuzzedSubHeadLbl {
    if (!_fuzzedSubHeadLbl) {
        _fuzzedSubHeadLbl = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.fuzzedTitleLbl.frame), CGRectGetMaxY(self.fuzzedTitleLbl.frame), 300, 14)];
        _fuzzedSubHeadLbl.font = [UIFont spc_regularSystemFontOfSize:12];
        _fuzzedSubHeadLbl.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
        _fuzzedSubHeadLbl.textAlignment = NSTextAlignmentLeft;
    }
    return _fuzzedSubHeadLbl;
}

-(UIButton *)fuzzedVenueBtn {
    if (!_fuzzedVenueBtn) {
        _fuzzedVenueBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.fuzzedHeader.frame.size.width, self.fuzzedHeader.frame.size.height)];
        [_fuzzedVenueBtn addTarget:self action:@selector(selectFuzzedVenue) forControlEvents:UIControlEventTouchDown];
        _fuzzedVenueBtn.backgroundColor = [UIColor clearColor];
    }
    return _fuzzedVenueBtn;
}


-(UIActivityIndicatorView *)fuzzedSpinner {
    if (!_fuzzedSpinner) {
        _fuzzedSpinner = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(self.fuzzedHeader.frame.size.width - 40, (CGRectGetHeight(self.fuzzedHeader.frame) - 30)/2, 25, 25)];
        _fuzzedSpinner.color = [UIColor darkGrayColor];
        _fuzzedSpinner.hidden = YES;
        
    }
    return _fuzzedSpinner;
}

-(UIView *)createLocationView {
    if (!_createLocationView) {
        
        float expandedHeight = 60;
        
        _createLocationView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.fuzzedHeader.frame), self.view.frame.size.width, 0)];
        _createLocationView.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _createLocationView.clipsToBounds = YES;
        
        UIImageView *iconImgView = [[UIImageView alloc] initWithFrame:CGRectMake(15, (expandedHeight - 16)/2, 16, 16)];
        iconImgView.image = [UIImage imageNamed:@"lg-icon-pin-custom"];
        [_createLocationView addSubview:iconImgView];

        [_createLocationView addSubview:self.createLocPlusImgView];
        [_createLocationView addSubview:self.createSpinner];
        
        //pickLocPlusIcon
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

-(UILabel *)locationRequiredPrompt {
    if (!_locationRequiredPrompt) {
        
        _locationRequiredPrompt = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 30, 40)];
        _locationRequiredPrompt.text = NSLocalizedString(@"Memories from your camera roll can\nonly be left in territories", nil);
        _locationRequiredPrompt.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _locationRequiredPrompt.textAlignment = NSTextAlignmentCenter;
        _locationRequiredPrompt.lineBreakMode = NSLineBreakByWordWrapping;
        _locationRequiredPrompt.numberOfLines = 0;
        _locationRequiredPrompt.backgroundColor = [UIColor clearColor];
        _locationRequiredPrompt.textColor = [UIColor colorWithRed:193.0f/255.0f green:200.0f/255.0f blue:211.0f/255.0f alpha:1.0f];
        _locationRequiredPrompt.hidden = YES;
        
    }
    return _locationRequiredPrompt;
    
}

-(UIImageView *)locationArrowPrompt {
    if (!_locationArrowPrompt) {
        _locationArrowPrompt = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pickLocUpArrow"]];
        _locationArrowPrompt.hidden = YES;
    }
    return _locationArrowPrompt;
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

- (UIImageView *)searchIcon {
    if (!_searchIcon) {
        _searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"magnifying-glass-off"]];
    }
    return _searchIcon;
}

- (SPCSearchTextField *)searchBar {
    if (!_searchBar) {
        _searchBar = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(0, 12.5, CGRectGetWidth(self.locationHeader.frame) - 20, 30)];
        _searchBar.delegate = self;
        _searchBar.backgroundColor = [UIColor clearColor];
        _searchBar.textColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _searchBar.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _searchBar.font = [UIFont spc_mediumSystemFontOfSize:14];
        _searchBar.spellCheckingType = UITextSpellCheckingTypeNo;
        _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        _searchBar.leftView.tintColor = [UIColor whiteColor];
        _searchBar.placeholder = @"";
        _searchBar.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_mediumSystemFontOfSize:14] };
        
        UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 34, 30)];
        [leftView addSubview:self.searchIcon];
        self.searchIcon.center = CGPointMake(CGRectGetWidth(leftView.bounds)/2.0 + 2, CGRectGetHeight(leftView.bounds)/2.0);
        _searchBar.leftView = leftView;
    }
    return _searchBar;
    
}

- (UITableView *)tableView {
    if (!_tableView) {
        // allocate and set up
        UITableView * tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(self.fuzzedHeader.frame), CGRectGetWidth(self.view.frame), self.view.frame.size.height)];
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView = tableView;
        _tableView.hidden = NO;
        _tableView.alpha = 1.0f;
        
        float insetAdj  = self.containerBaseY + CGRectGetHeight(self.chooseLocationPrompt.frame) + CGRectGetHeight(self.fuzzedHeader.frame) + CGRectGetHeight(self.locationHeader.frame);
        
        _tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
        [_tableView setScrollIndicatorInsets:_tableView.contentInset];
    }
    return _tableView;
}

-(UIActivityIndicatorView *)geocodingSpinner {
    if (!_geocodingSpinner) {
        
        _geocodingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _geocodingSpinner.color = [UIColor grayColor];
        _geocodingSpinner.hidden = YES;
        
    }
    return _geocodingSpinner;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.fuzzedVenuesOnly && !self.hasGPS) {
        return self.territories.count;
    }
    else {
        return self.filteredVenues.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.fuzzedVenuesOnly && !self.hasGPS) {
        SPCPickLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        SPCCity *territory = self.territories[indexPath.row];
        [cell configureCellWithTerritory:territory];
        return cell;
    }
    else {
        SPCPickLocationCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        Venue *venue = self.filteredVenues[indexPath.row];
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            location = [LocationManager sharedInstance].currentLocation;
        }
        CGFloat distance = (location && venue.location) ? [location distanceFromLocation:venue.location] : -1;
        
        [cell configureCellWithVenue:venue distance:distance];

        return cell;
    }
}

#pragma UITableView Delegate Methods


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.fuzzedVenuesOnly && !self.hasGPS) {
        SPCCity *territory = self.territories[indexPath.row];
        
        SPCPickLocationCell *cell = (SPCPickLocationCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell activateSpinner];
        
        // inform the delegate
        [self.delegate spcPickLocationViewControllerDidFinish:self withSelectedTerritory:territory];
    }
    else {
    
        Venue * venue = self.filteredVenues[indexPath.row];
        
        SPCPickLocationCell *cell = (SPCPickLocationCell *)[tableView cellForRowAtIndexPath:indexPath];
        [cell activateSpinner];
        
        // inform the delegate
        [self.delegate spcPickLocationViewControllerDidFinish:self withSelectedVenue:venue];
    }
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // no change
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
    
    if (self.fuzzedVenuesOnly && !self.hasGPS) {
        //don't show the create location functionality when searching for territories
    }
    else {
        if (text.length == 3) {
            [self showCreateLocation];
        }
        if (text.length == 2) {
            [self hideCreateLocation];
        }
    }
    
    NSString *customVenName = [NSString stringWithFormat:@"Create \"%@\"",text];
    self.createLocationTitleLbl.text = customVenName;
    
    // Cancel previous filter request
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
     if (self.fuzzedVenuesOnly && !self.hasGPS) {
         [self performSelector:@selector(fetchTerritoriesWithSearchString:) withObject:text afterDelay:0.2];
     }
     else {
    
         // Schedule delayed filter request in order to allow textField to update it's internal state
         [self performSelector:@selector(reloadListDataWithSearch:) withObject:text afterDelay:0.2];
     }
    return YES;
}


#pragma mark Configuration

-(void)configureWithLatitude:(double)latitude longitude:(double)longitude image:(SPCImageToCrop *)imageToPreview {
    
    //handle map
    [self.mapView setCamera:[GMSCameraPosition cameraWithLatitude:latitude longitude:longitude zoom:15]];
    [self.tableView reloadData];
    
    //handle image
    if (imageToPreview) {
        self.imagePreview.image = [imageToPreview cropPreviewImage];
        self.imagePreview.hidden = NO;
        self.mapBtn.hidden = NO;
        self.mapView.hidden = YES;
    }
    else {
        self.imagePreview.hidden = YES;
        self.mapBtn.hidden = YES;
        self.mapView.hidden = NO;
    }
    
    //use lat/long to set-up table view
    NSLog(@"lat %f long %f",latitude,longitude);
    
    self.hasGPS = NO;
    
    if ((latitude != 0 || longitude != 0) && (latitude != -180 || longitude != -180) &&  (latitude != 180 || longitude != 180)) {
        self.hasGPS = YES;
    }

    self.tableView.hidden = NO;
    self.locationHeader.hidden = NO;
    self.locationRequiredPrompt.hidden = YES;
    self.locationArrowPrompt.hidden = YES;
    
    if (self.fuzzedVenuesOnly && self.hasGPS) {
        self.tableView.hidden = YES;
        self.locationHeader.hidden = YES;
    }
    
    //get our fuzzed veune for a cam roll selection with lat/long
    
    if (self.fuzzedVenuesOnly && self.hasGPS) {
        self.chooseLocationPrompt.text = NSLocalizedString(@"Where did this happen?", nil);
        [self updateViewForCamRollPic];
        self.geocodingSpinner.hidden = NO;
        [self.geocodingSpinner startAnimating];
        
        self.fuzzedTitleLbl.text = @"Searching..";
        self.fuzzedSubHeadLbl.text = @"";
        self.fuzzedVenueBtn.userInteractionEnabled = NO;
        
        NSLog(@"fetch fuzzed venue, it's a cam roll pic!");
  
        __weak typeof(self)weakSelf = self;
        [[VenueManager sharedInstance] fetchVenueAndNearbyVenuesWithoutGoogleHintAtLatitude:latitude longitude:longitude
                                                                             resultCallback:^(Venue *venue, NSArray *venues, Venue *fuzzedCityVenue, Venue *fuzzedNeighborhoodVenue) {
                                                                                 __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                                 if (!strongSelf) {
                                                                                     return ;
                                                                                 }
                                                                                 
                                                                                 Venue *fuzzedVenue;
                                                                                 
                                                                                 if (fuzzedCityVenue) {
                                                                                     fuzzedVenue = fuzzedCityVenue;
                                                                                 }
                                                                                 if (fuzzedNeighborhoodVenue) {
                                                                                     fuzzedVenue = fuzzedNeighborhoodVenue;
                                                                                 }
                                                                    
                                                                                 strongSelf.fuzzedVenue = fuzzedVenue;
                                                                                 if (fuzzedCityVenue) {
                                                                                     strongSelf.fuzzedTitleLbl.text = fuzzedVenue.neighborhood;
                                                                                     strongSelf.fuzzedSubHeadLbl.text = NSLocalizedString(@"(Neighborhood Level for private locations)", nil);
                                                                                 }
                                                                                 if (fuzzedNeighborhoodVenue) {
                                                                                     strongSelf.fuzzedTitleLbl.text = fuzzedVenue.city;
                                                                                     strongSelf.fuzzedSubHeadLbl.text = NSLocalizedString(@"(City Level for private locations)", nil);
                                                                                 }
                                                                                 [strongSelf.geocodingSpinner stopAnimating];
                                                                                 strongSelf.geocodingSpinner.hidden = YES;
                                                                                 strongSelf.fuzzedVenueBtn.userInteractionEnabled = YES;
                                                                             }
                                                                              faultCallback:^(GoogleApiResult apiResult, NSError *error) {
                                                                                  
                                                                                  NSLog(@"error fetching fuzzed venue! %@",error);
                                                                                  __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                                  if (!strongSelf) {
                                                                                      return ;
                                                                                  }
                                                                                  
                                                                                  [strongSelf cancel];
                                                                              }];
        
        

        
    }
    //handle cam roll pic w/o gps
    else if (self.fuzzedVenuesOnly && !self.hasGPS) {
        self.chooseLocationPrompt.text = NSLocalizedString(@"Where did this happen?", nil);
        self.searchBar.placeholder = @"Search territories (city, neighborhood, school)";
        self.mapBtn.hidden = YES;
        
        [self.delegate updateSelectedVenue:nil];
        
        float heightOfVisibleAreaBelowFuzzedHeader = self.view.bounds.size.height - (self.containerBaseY + CGRectGetMaxY(self.locationHeader.frame));
        float yCenter = CGRectGetMaxY(self.locationHeader.frame) + heightOfVisibleAreaBelowFuzzedHeader/2;
        self.locationRequiredPrompt.center = CGPointMake(self.view.bounds.size.width/2, yCenter);
        self.locationArrowPrompt.center = CGPointMake(self.view.bounds.size.width/2, CGRectGetMinY(self.locationRequiredPrompt.frame) - 20);
        if (self.territories.count == 0) {
            self.locationRequiredPrompt.hidden = NO;
            self.locationArrowPrompt.hidden = NO;
        }
        //prompt to search for a city!
        self.locationHeader.hidden = NO;
        self.fuzzedHeader.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 0);
        self.fuzzedVenueBtn.userInteractionEnabled = NO;
        
        self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, self.view.frame.size.height);
        float insetAdj  = self.containerBaseY + CGRectGetHeight(self.chooseLocationPrompt.frame) + CGRectGetHeight(self.locationHeader.frame);
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
    }
    
    else {
        self.chooseLocationPrompt.text = NSLocalizedString(@"Where is this happening?", nil);
        self.searchBar.placeholder = @"Search...";
        self.locationHeader.hidden = NO;
        self.fuzzedHeader.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 62);
        self.fuzzedVenueBtn.userInteractionEnabled = YES;
        [self refreshVenues];
    }
    
}

-(void)showLocationOptions {
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.containerView.frame = CGRectMake(0, self.containerBaseY, self.view.bounds.size.width, self.view.bounds.size.height);
                         
                     } completion:^(BOOL finished) {
                     }];
}

#pragma mark Actions

-(void)selectFuzzedVenue {
    [Flurry logEvent:@"MAM_FUZZED_VENUE_TAPPPED"];
    self.fuzzedVenueBtn.userInteractionEnabled = NO;
    self.fuzzedSpinner.hidden = NO;
    [self.fuzzedSpinner startAnimating];
    [self.delegate spcPickLocationViewControllerDidFinish:self withSelectedVenue:self.fuzzedVenue];
    if (self.fuzzedVenuesOnly) {
        [self.delegate prepForVenueReset];
    }
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
        
        NSMutableArray *updatedVenues = [NSMutableArray arrayWithArray:self.venues];
        [updatedVenues addObject:venue];
        self.venues = [NSArray arrayWithArray:updatedVenues];
        
    } faultCallback:^(NSError *fault) {
        NSLog(@"TODO: handle failure");
    }];
    
    
}

-(void)clearSearch {
    
    self.cancelBtn.hidden = NO;
    self.clearSearchButton.hidden = YES;
    self.searchBar.text = @"";
    [self reloadListDataWithSearch:self.searchBar.text];
    
    [self hideCreateLocation];
}

-(void)toggleMap {
    if (self.mapView.hidden) {
        self.mapView.hidden = NO;
    }
    else {
        self.mapView.hidden = YES;
    }
}


#pragma mark Private

-(void)updateViewForCamRollPic {
    self.fuzzedHeader.frame = CGRectMake(0, CGRectGetMinY(self.locationHeader.frame), self.view.frame.size.width, 62);
    self.locationHeader.hidden = YES;
    
    float heightOfVisibleAreaBelowFuzzedHeader = self.view.bounds.size.height - (self.containerBaseY + CGRectGetMaxY(self.fuzzedHeader.frame));
    float yCenter = CGRectGetMaxY(self.fuzzedHeader.frame) + heightOfVisibleAreaBelowFuzzedHeader/2;
    self.geocodingSpinner.center = CGPointMake(self.view.bounds.size.width/2, yCenter);
    
}

-(void)updateViewForFiltering {
    
    self.locationRequiredPrompt.hidden = YES;
    self.locationArrowPrompt.hidden = YES;
    if (self.fuzzedVenuesOnly && !self.hasGPS) {
        self.searchBar.placeholder = @"Search territories..";
    }
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.containerView.frame = CGRectMake(0, -35, self.view.bounds.size.width, self.view.bounds.size.height + 35);
                         self.tableView.contentInset = UIEdgeInsetsMake(0, 0, CGRectGetHeight(self.fuzzedHeader.frame) + 300, 0);
                         
                     } completion:^(BOOL finished) {
                         self.cancelBtn.hidden = NO;
                        [_tableView setScrollIndicatorInsets:_tableView.contentInset];
                     }];
    
}

-(void)cancelFiltering {

    self.cancelBtn.hidden = YES;
    
    if (self.fuzzedVenuesOnly && !self.hasGPS && self.territories.count == 0) {
        self.locationRequiredPrompt.hidden = NO;
        self.locationArrowPrompt.hidden = NO;
    }

    if (self.fuzzedVenuesOnly && !self.hasGPS) {
        self.searchBar.placeholder = @"Search territories (city, neighborhood, school)";
    }
    
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    float insetAdj  = self.containerBaseY + CGRectGetHeight(self.chooseLocationPrompt.frame) + CGRectGetHeight(self.fuzzedHeader.frame) + CGRectGetHeight(self.locationHeader.frame);

    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.containerView.frame = CGRectMake(0, self.containerBaseY, self.view.bounds.size.width, self.view.bounds.size.height);
                         _tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
                         
                     } completion:^(BOOL finished) {
                        [_tableView setScrollIndicatorInsets:_tableView.contentInset];

                     }];
}

-(void)reset {
    
    NSLog(@"reset after picking location!");
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    //reset search
    self.clearSearchButton.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.searchBar.text = @"";
    [self reloadListDataWithSearch:self.searchBar.text];
    
    //reset spinners and arrows
    self.fuzzedVenueBtn.userInteractionEnabled = YES;
    self.fuzzedSpinner.hidden =YES;
    [self.fuzzedSpinner stopAnimating];
    
    self.createVenueBtn.userInteractionEnabled = YES;
    self.createLocPlusImgView.hidden = NO;
    self.createSpinner.hidden = YES;
    [self.createSpinner stopAnimating];
    
    
    //reset location picking items frames and inset
    self.containerView.frame = CGRectMake(0, self.containerBaseY, self.view.bounds.size.width, self.view.bounds.size.height);
    self.createLocationView.frame = CGRectMake(0, CGRectGetMaxY(self.fuzzedHeader.frame), self.view.frame.size.width, 0);

    self.fuzzedHeader.frame = CGRectMake(0, CGRectGetMaxY(self.locationHeader.frame), self.view.frame.size.width, 62);

    
    self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.fuzzedHeader.frame), self.view.frame.size.width, self.view.frame.size.height);
    float insetAdj  = self.containerBaseY + CGRectGetHeight(self.chooseLocationPrompt.frame) + CGRectGetHeight(self.fuzzedHeader.frame) + CGRectGetHeight(self.locationHeader.frame);
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
}

-(void)showCreateLocation {
    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.createLocationView.frame = CGRectMake(0, CGRectGetMaxY(self.fuzzedHeader.frame), self.view.frame.size.width, 60);
                         self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.createLocationView.frame), self.view.frame.size.width, self.view.frame.size.height - 60);
                         
                         
                     } completion:^(BOOL finished) {
    
                     }];
}


-(void)hideCreateLocation {
    float insetAdj  = self.containerBaseY + CGRectGetHeight(self.chooseLocationPrompt.frame) + CGRectGetHeight(self.fuzzedHeader.frame) + CGRectGetHeight(self.locationHeader.frame);

    
    [UIView animateWithDuration:0.1
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.createLocationView.frame = CGRectMake(0, CGRectGetMaxY(self.fuzzedHeader.frame), self.view.frame.size.width, 0);
                         self.tableView.frame = CGRectMake(0, CGRectGetMaxY(self.fuzzedHeader.frame), self.view.frame.size.width, self.view.frame.size.height);
                         _tableView.contentInset = UIEdgeInsetsMake(0, 0, insetAdj, 0);
                         
                         
                     } completion:^(BOOL finished) {
                         
                     }];
     
}

- (void)reloadListDataWithSearch:(NSString *)search {
    if (search == self.searchBar.text || [self.searchBar.text isEqualToString:search]) {
        // First, determine the appropriate list of venues to display.  We already
        // have a sorted list of venues, so this amounts to applying the search filter
        // (if any) to reduce this list.
        self.filteredVenues = [self filterVenues:self.venues withSearchTerm:search];
    } else {
        self.filteredVenues = self.filteredVenues ?: self.venues;
    }
    
    self.filteredVenues = [self.filteredVenues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"distanceAway" ascending:YES]]];
    
    // The rest of the work is done by our table delegate methods.
    if (_tableView) {
        NSLog(@"we have %li filtered venues",self.filteredVenues.count);
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

- (void)refreshVenues {
    [self fetchNearbyLocations:NO];
}

- (void)fetchNearbyLocations:(BOOL)manualRefresh {
    if (self.performingRefresh) {
        return;
    }
    
    self.performingRefresh = YES;
    
    if (!self.fuzzedVenuesOnly) {
        // load locations around the user's current location
        [[LocationManager sharedInstance] waitForUptime:MINIMUM_LOCATION_MANAGER_UPTIME withSuccessCallback:^(NSTimeInterval uptime) {
            [[LocationContentManager sharedInstance] getContent:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue,SPCLocationContentFuzzedVenue, SPCLocationContentNearbyVenues] resultCallback:^(NSDictionary *results) {
                
                [self updateWithLocationContentResults:results manualRefresh:manualRefresh];
                self.performingRefresh = NO;
            } faultCallback:^(NSError *fault) {
                // TODO: Show error table view cell
                // No nearby locations found
                NSLog(@"error fetching nearby locations: %@", fault);
                self.performingRefresh = NO;
                
            }];
        } faultCallback:^(NSError *error) {
            // TODO: Show error table view cell
            // No nearby locations found
            NSLog(@"error waiting for uptime: %@", error);
            self.performingRefresh = NO;
            
        }];
    } else {
        // load the fuzzed venue around a cam roll image's latitude / longitude
        
    
    }
}

- (void)fetchVenuesFromCache {
    if (self.performingRefresh) {
        return;
    }
    
    [[LocationContentManager sharedInstance] getContentFromCache:@[SPCLocationContentVenue, SPCLocationContentDeviceVenue, SPCLocationContentFuzzedVenue, SPCLocationContentNearbyVenues] resultCallback:^(NSDictionary *results) {
        
        [self updateWithLocationContentResults:results manualRefresh:NO];
    } faultCallback:^(NSError *fault) {
        // TODO: Show error table view cell
        // No nearby locations found
        NSLog(@"error fetching nearby locations from cache!");
    }];
}

- (BOOL)updateWithLocationContentResults:(NSDictionary *)results manualRefresh:(BOOL)manualRefresh {
    NSArray *nearbyVenues = results[SPCLocationContentNearbyVenues];
    NSMutableArray *nearbyAndFuzzedVenues = [NSMutableArray arrayWithArray:nearbyVenues];
    
    if ((Venue *)results[SPCLocationContentFuzzedVenue]) {
        Venue *fuzzedVenue = (Venue *)results[SPCLocationContentFuzzedVenue];
        NSLog(@"got a fuzzed venue in city:%@",fuzzedVenue.city);
        self.fuzzedVenue = fuzzedVenue;
        
        if (fuzzedVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
            self.fuzzedTitleLbl.text = fuzzedVenue.neighborhood;
            self.fuzzedSubHeadLbl.text = NSLocalizedString(@"Neighborhood Level for private locations", nil);
        }
        if (fuzzedVenue.specificity == SPCVenueIsFuzzedToCity) {
            self.fuzzedTitleLbl.text = fuzzedVenue.city;
            self.fuzzedSubHeadLbl.text = NSLocalizedString(@"City Level for private locations", nil);
        }
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        location = [LocationManager sharedInstance].currentLocation;
    }
    for (Venue *venue in nearbyAndFuzzedVenues) {
        CGFloat distance = (location && venue.location) ? [location distanceFromLocation:venue.location] : -1;
        venue.distanceAway = distance;
    }
    
    
    self.venues = nearbyAndFuzzedVenues;
    self.filteredVenues = [NSArray arrayWithArray:nearbyVenues];
    [self reloadListDataWithSearch:self.searchBar.text];
    
    // Do NOT update the currently selected venue as a result of this
    // refresh.  Just refreshing things here doesn't make a difference in
    // terms of our "current" venue.
    
    return NO;
}


- (void)updateWithNearbyVenueResults:(NSArray *)venues fuzzedVenue:(Venue *)fuzzedVenue {
    
    self.venues = [NSArray arrayWithArray:venues];

    self.filteredVenues = [NSArray arrayWithArray:venues];
    [self reloadListDataWithSearch:self.searchBar.text];
}

- (void)fetchTerritoriesWithSearchString:(NSString *)searchStr {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    //1. fetch cities
    [MeetManager fetchCitiesWithSearch:searchStr
                     completionHandler:^(NSArray *cities) {
                         
                         //limit city results to a max of 10
                         for (int i = 0; i < (int)cities.count; i++) {
                             [tempArray addObject:cities[i]];
                         }
                         
                         //2. fetch neighborhoods
                         
                         [MeetManager fetchNeighborhoodsWithSearch:searchStr
                                                 completionHandler:^(NSArray *neighborhoods) {
                                                     
                                                     for (int i = 0; i < (int)neighborhoods.count; i++) {
                                                         [tempArray addObject:neighborhoods[i]];
                                                     }

                                                     self.territories = [NSArray arrayWithArray:tempArray];
                                                     [self.tableView reloadData];
                                                     
                                                     [NSObject cancelPreviousPerformRequestsWithTarget:self];
                                                     
                                                 } errorHandler:^(NSError *error) {
                                                 }];
                         
                     } errorHandler:^(NSError *error) {
                     }];
}


#pragma mark Navigation Methods

-(void)cancel {
    NSLog(@"cancel");
    if ([self.searchBar isFirstResponder]) {
        [self.searchBar resignFirstResponder];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(spcPickLocationViewControllerDidCancel:)]){
        [self.delegate spcPickLocationViewControllerDidCancel:self];
    }
}

-(void)finishPost {
    
}


@end
