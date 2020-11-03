//
//  SPCPeopleViewController.m
//  Spayce
//
//  Created by Christopher Taylor on 11/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCPeopleViewController.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>
#import <CoreText/CTStringAttributes.h>
#import "Flurry.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "PersonUpdate.h"
#import "ProfileDetail.h"
#import "SPCNeighborhood.h"
#import "User.h"
#import "UserProfile.h"
#import "Venue.h"
#import "SPCPeopleSearchResult.h"
#import "SPCNotifications.h"

// View
#import "SPCSearchTextField.h"
#import "SPCRankedUserTableViewCell.h"
#import "SPCCitySearchResultCell.h"
#import "HMSegmentedControl.h"
#import "SPCGetStartedTableViewCell.h"
#import "AddFriendsCollectionViewCell.h"

// Controller
#import "SPCProfileViewController.h"
#import "SPCCustomNavigationController.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "LocationManager.h"
#import "PNSManager.h"
#import "LocationContentManager.h"

// Category
#import "UIViewController+SPCAdditions.h"
#import "UIImageView+WebCache.h"
#import "UITabBarController+SPCAdditions.h"
#import "UIFont+SPCAdditions.h"

// Constants
#import "Constants.h"

// Literals
#import "SPCLiterals.h"

static NSString *RankedUserCellIdentifier = @"RankedUserCellIdentifier";
static NSString *UnrankedUserCellIdentifier = @"UnrankedUserCellIdentifier";
static NSString *placeholderCellIdentifier = @"placeholderCellIdentifier";
static NSString *getStartedCellIdentifier = @"getStartedCellIdentifier";

static NSString *CollectionViewCellIdentifier = @"FriendCell";

@interface SPCPeopleViewController ()

@property (nonatomic, assign) NSInteger currPeopleState;

@property (nonatomic, strong) UIView *textFieldBackgroundView;
@property (nonatomic, strong) SPCSearchTextField *textField;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIImageView *mapPreviewImg;
@property (nonatomic, strong) UILabel *headerTitleLabel;
@property (nonatomic, strong) UILabel *headerSubtitleLabel;
@property (nonatomic, strong) UIView *headerUnderline;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSArray *rankedUsers;
@property (nonatomic, strong) NSArray *unrankedUsers;
@property (nonatomic, strong) NSArray *cityResults;
@property (nonatomic, strong) NSArray *neighborhoodResults;

@property (nonatomic, strong) NSArray *searchResults;

@property (nonatomic, strong) NSArray *allUserAssets;
@property (nonatomic, strong) NSSet *prefetchedAssetIds;
@property (nonatomic, assign) BOOL prefetchInProgress;
@property (nonatomic, assign) BOOL prefetchPaused;
@property (nonatomic, strong) UIImageView *prefetchImageView;

@property (nonatomic, strong) NSArray *recentUnrankedUsers;
@property (nonatomic, strong) NSArray *recentCityResults;
@property (nonatomic, strong) NSArray *recentNeighborhoodResults;

@property (nonatomic, strong) NSArray *recentSearchResults;

@property (nonatomic, strong) NSArray *cachedGlobalResults;

@property (nonatomic, strong) NSArray *cachedLocalResults;
@property (nonatomic, strong) SPCCity *cachedLocal;  //our cached request
@property (nonatomic, strong) SPCCity *currLocalResult; //our cached result
@property (nonatomic, strong) NSString *cachedPop;

@property (nonatomic, strong) NSArray *cachedRankedFriends;

@property (nonatomic, strong) NSOperationQueue *searchOperationQueue;

@property (nonatomic, strong) Friend *currentUser;

@property (nonatomic, assign) BOOL hasAppeared;
@property (nonatomic, assign) BOOL isLoadingCurrentData;

@property (nonatomic, assign, getter = isScrolling) BOOL scrolling;

@property (nonatomic, strong) UILabel *promptText;
@property (nonatomic, strong) UIView  *promptContainer;
@property (nonatomic, strong) UIImageView *searchIcon;

@property (nonatomic, strong) GMSMapView *mapView;
@property (nonatomic, strong) NSString *activePlacename;

@property (nonatomic, assign) CGFloat headerHeight;

@property (nonatomic, strong) NSArray *allFriends;
@property (nonatomic, strong) NSArray *allCachedFriends;

//custom segmented control
@property (nonatomic, assign) CGFloat previousOffset;
@property (nonatomic, assign) BOOL snapInProgress;

@property (nonatomic, strong) UIView *recentSearchesHeaderView;
@property (nonatomic, strong) UIButton *cancelSearchBtn;
@property (nonatomic, strong) UIButton *resetSearchBtn;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, assign) BOOL draggingScrollView;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) float collectionHeaderHeight;

@end

@implementation SPCPeopleViewController

#pragma mark - Object lifecycle

- (void)dealloc {
    [self spc_dealloc];
    // Remove observers!!!!
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if (self.searchOperationQueue) {
        [self.searchOperationQueue cancelAllOperations];
    }
}

#pragma mark - View

- (void)loadView {
    [super loadView];
    
    self.headerHeight = 100;
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.headerHeight = 115;
    }
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        self.headerHeight = 124;
    }
    
    [self.view addSubview:self.mapView];
    
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.textFieldBackgroundView];
    [self.view addSubview:self.textField];
    [self.view addSubview:self.promptContainer];
    [self.promptContainer addSubview:self.promptText];
    
    [self.view addSubview:self.spinner];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
    
    //restore recent searches as needed
    [self.collectionView registerClass:[AddFriendsCollectionViewCell class] forCellWithReuseIdentifier:CollectionViewCellIdentifier];
    [self.tableView registerClass:[SPCRankedUserTableViewCell class] forCellReuseIdentifier:RankedUserCellIdentifier];
    [self.tableView registerClass:[SPCRankedUserTableViewCell class] forCellReuseIdentifier:UnrankedUserCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:placeholderCellIdentifier];
    [self.tableView registerClass:[SPCGetStartedTableViewCell class] forCellReuseIdentifier:getStartedCellIdentifier];
    
    self.currPeopleState = PeopleStateEmpty;
    [self fetchFollowedUsers];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleStatusBarChange:) name:@"statusbarchange" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetToDefault) name:@"resetPeopleToDefault" object:nil];
    
    // Activity updates (user entered / left the app, etc.)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidChangeStatusBarFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.currPeopleState >= PeopleStateEmpty) {
        self.tableView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame),0,0,0);
    } else {
        self.textField.text = nil;
        self.promptText.text = NSLocalizedString(@"Find people...", nil);
        self.promptText.alpha = 1;
        self.promptContainer.alpha = 1;
        self.tableView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame)+40,0,0,0);
    }
    
    self.prefetchPaused = NO;
    if (self.allUserAssets.count > 0) {
        [self prefetchNextAsset];
    }
    
    [self.tabBarController slideTabBarHidden:NO animated:NO];
    [self.navigationController setNavigationBarHidden:YES animated:NO]; // Needed for when returning from MemoryCommentsViewController
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.hasAppeared) {
        self.hasAppeared = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.textField resignFirstResponder];
    self.prefetchPaused = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.hasAppeared) {
        
        self.hasAppeared = NO;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}
#pragma mark - Accessors


- (NSArray *)allUserAssets {
    if (!_allUserAssets) {
        _allUserAssets = [NSArray array];
    }
    return _allUserAssets;
}

- (NSSet *)prefetchedAssetIds {
    if (!_prefetchedAssetIds) {
        _prefetchedAssetIds = [NSSet set];
    }
    return _prefetchedAssetIds;
}

- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}

- (UIView *)textFieldBackgroundView {
    if (!_textFieldBackgroundView) {
        _textFieldBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 85)];
        _textFieldBackgroundView.backgroundColor = [UIColor whiteColor];
        
        [_textFieldBackgroundView addSubview:self.searchIcon];
        
        [_textFieldBackgroundView addSubview:self.cancelSearchBtn];
        [_textFieldBackgroundView addSubview:self.resetSearchBtn];
        
        // sepViewBottom is the separator between the textfield and the friends/city/world filters
        CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
        UIView *sepViewBottom = [[UIView alloc] initWithFrame:CGRectMake(0, _textFieldBackgroundView.frame.size.height - separatorHeight, self.view.bounds.size.width, separatorHeight)];
        sepViewBottom.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [_textFieldBackgroundView addSubview:sepViewBottom];
    }
    return _textFieldBackgroundView;
}

- (UIImageView *)searchIcon {
    if (!_searchIcon) {
        _searchIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"magnifying-glass-off"]];
        _searchIcon.center = CGPointMake(_searchIcon.center.x+15, 10 + self.textFieldBackgroundView.frame.size.height/ 2 - 0.5f);
    }
    return _searchIcon;
}

- (SPCSearchTextField *)textField {
    if (!_textField) {
        // The x-coordinate of this field is 10pt to the right of the search Icon - iconOrigin.x + iconWidth + 10px spacing
        CGFloat xCoordinate = self.searchIcon.frame.origin.x + self.searchIcon.image.size.width + 10;
        _textField = [[SPCSearchTextField alloc] initWithFrame:CGRectMake(xCoordinate, 21, self.textFieldBackgroundView.frame.size.width - 125, self.textFieldBackgroundView.frame.size.height - 20)];
        _textField.delegate = self;
        _textField.backgroundColor = [UIColor clearColor];
        _textField.textColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.000];
        _textField.tintColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:1.000];
        _textField.font = [UIFont spc_regularSystemFontOfSize:14];
        _textField.spellCheckingType = UITextSpellCheckingTypeNo;
        //_textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _textField.autocorrectionType = UITextAutocorrectionTypeNo;
        _textField.leftView.tintColor = [UIColor whiteColor];
        _textField.placeholder = @"";
        _textField.placeholderAttributes = @{ NSForegroundColorAttributeName: [UIColor colorWithRed:118.0f/255.0f green:158.0f/255.0f blue:222.0f/255.0f alpha:1.0f], NSFontAttributeName: [UIFont spc_regularSystemFontOfSize:18] };
        _textField.leftView = nil;
    }
    return _textField;
    
}

- (UILabel *)promptText {
    if (!_promptText) {
        _promptText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.promptContainer.frame.size.width, self.textField.frame.size.height)];
        _promptText.userInteractionEnabled = NO;
        _promptText.backgroundColor = [UIColor clearColor];
        _promptText.textColor = [UIColor colorWithRed:124.0f/255.0f green:133.0f/255.0f blue:141.0f/255.0f alpha:1.000f];
        _promptText.font = [UIFont spc_mediumSystemFontOfSize:14];
        _promptText.text = NSLocalizedString(@"Find people...", nil);
    }
    return _promptText;
}

- (UIView *)promptContainer {
    if (!_promptContainer) {
        // The x-coordinate of this field is 10pt to the right of the search Icon - iconOrigin.x + iconWidth + 10px spacing
        CGFloat xCoordinate = self.searchIcon.frame.origin.x + self.searchIcon.image.size.width + 10;
        _promptContainer = [[UIView alloc] initWithFrame:CGRectMake(xCoordinate, 20, self.textFieldBackgroundView.frame.size.width - 50, self.textFieldBackgroundView.frame.size.height - 20)];
        _promptContainer.backgroundColor = [UIColor clearColor];
        _promptContainer.userInteractionEnabled = NO;
    }
    return _promptContainer;
}

- (UIView *)headerView {
    if (!_headerView) {
        
        _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, self.headerHeight)];
        _headerView.backgroundColor = [UIColor clearColor];
        
        [_headerView addSubview:self.mapPreviewImg];
        
        self.overlayView = [[UIView alloc] initWithFrame:_headerView.frame];
        self.overlayView.backgroundColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:0.7f];
        [_headerView addSubview:self.overlayView];
        
        [_headerView addSubview:self.headerTitleLabel];
        [_headerView addSubview:self.headerSubtitleLabel];
        
        self.headerUnderline = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _headerView.frame.size.width/2, .5)];
        self.headerUnderline.backgroundColor = [UIColor whiteColor];
        self.headerUnderline.center = CGPointMake(_headerView.frame.size.width/2, _headerView.frame.size.height / 2);
        [_headerView addSubview:self.headerUnderline];
        
        _headerView.clipsToBounds = YES;
    }
    return _headerView;
}

- (UIView *)recentSearchesHeaderView {
    if (!_recentSearchesHeaderView) {
        _recentSearchesHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        _recentSearchesHeaderView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
    }
    return _recentSearchesHeaderView;
}


- (UIButton *)cancelSearchBtn {
    if (!_cancelSearchBtn) {
        NSString *cancelString = @"Cancel";
        CGSize sizeOfTextWithPadding = [cancelString sizeWithAttributes:@{                                                             NSFontAttributeName : [UIFont spc_regularSystemFontOfSize:12] }];
        // The width should be a minimum of 60pt, with 8pt of padding on each side
        sizeOfTextWithPadding.width = MAX(60.0f, sizeOfTextWithPadding.width + 16.0f);
        
        _cancelSearchBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.textFieldBackgroundView.frame.size.width - sizeOfTextWithPadding.width - 10, 37.5, sizeOfTextWithPadding.width, 30)];
        [_cancelSearchBtn setTitle:@"Cancel" forState:UIControlStateNormal];
        _cancelSearchBtn.titleLabel.font = [UIFont spc_regularSystemFontOfSize:12];
        [_cancelSearchBtn  setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        _cancelSearchBtn.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
        _cancelSearchBtn.layer.borderWidth = 1;
        _cancelSearchBtn.layer.cornerRadius = 2;
        [_cancelSearchBtn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [_cancelSearchBtn addTarget:self action:@selector(cancelSearch) forControlEvents:UIControlEventTouchUpInside];
        _cancelSearchBtn.hidden = YES;
    }
    return _cancelSearchBtn;
}

- (UIButton *)resetSearchBtn {
    if (!_resetSearchBtn) {
        _resetSearchBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.textFieldBackgroundView.frame.size.width - 50, 28, 50, 50)];
        [_resetSearchBtn setBackgroundImage:[UIImage imageNamed:@"reset-search-btn"] forState:UIControlStateNormal];
        [_resetSearchBtn addTarget:self action:@selector(resetSearch) forControlEvents:UIControlEventTouchUpInside];
        _resetSearchBtn.hidden = YES;
    }
    return _resetSearchBtn;
}

- (UIImageView *)mapPreviewImg {
    if (!_mapPreviewImg) {
        _mapPreviewImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), self.headerHeight)];
    }
    return _mapPreviewImg;
}

- (UILabel *)headerTitleLabel {
    if (!_headerTitleLabel) {
        _headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, (_headerView.frame.size.height / 2) - 30, self.view.bounds.size.width-20, 20)];
        _headerTitleLabel.text = @"";
        _headerTitleLabel.font = [UIFont spc_mediumSystemFontOfSize:16];
        _headerTitleLabel.backgroundColor = [UIColor clearColor];
        _headerTitleLabel.textAlignment = NSTextAlignmentCenter;
        _headerTitleLabel.textColor = [UIColor whiteColor];
        _headerTitleLabel.center = CGPointMake(_headerView.frame.size.width/2, _headerTitleLabel.center.y);
    }
    return _headerTitleLabel;
}

- (UILabel *)headerSubtitleLabel {
    if (!_headerSubtitleLabel) {
        _headerSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, (_headerView.frame.size.height / 2) + 10, self.view.bounds.size.width-20, 20)];
        _headerSubtitleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _headerSubtitleLabel.backgroundColor = [UIColor clearColor];
        _headerSubtitleLabel.textAlignment = NSTextAlignmentCenter;
        _headerSubtitleLabel.textColor = [UIColor whiteColor];
    }
    return _headerSubtitleLabel;
}


-(UICollectionView *)collectionView {
    if (!_collectionView){
        
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;
        CGRect collectionFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetHeight(self.tabBarController.tabBar.frame));
        
        _collectionView=[[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:layout];
        [_collectionView setDataSource:self];
        [_collectionView setDelegate:self];
        _collectionView.allowsMultipleSelection = NO;
        _collectionView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame),0,0,0);
        _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame), 0, 0, 0);
        _collectionView.alwaysBounceVertical = YES; // Allows the user to scroll (vertically) when there is less than one page of content in the collection view
 
        [_collectionView registerClass:[UICollectionReusableView class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"sectionHeader"];
        
        [_collectionView setBackgroundColor:[UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f]];
    }
    return _collectionView;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 45)];
        //_tableView.contentOffset = CGPointMake(0, CGRectGetMaxY(self.textField.frame));
        _tableView.contentInset = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame),0,0,0);
        _tableView.scrollIndicatorInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame), 0, 0, 0);

        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
    }
    return _tableView;
}

- (NSOperationQueue *)searchOperationQueue {
    if (!_searchOperationQueue) {
        _searchOperationQueue = [[NSOperationQueue alloc] init];
        _searchOperationQueue.maxConcurrentOperationCount = 1;
    }
    return _searchOperationQueue;
}

- (Friend *)currentUser {
    if (!_currentUser){
        
        NSInteger userId = [AuthenticationManager sharedInstance].currentUser.userId;
        NSString *userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        NSString *firstName = [ContactAndProfileManager sharedInstance].profile.profileDetail.firstname;
        NSString *lastName = [ContactAndProfileManager sharedInstance].profile.profileDetail.lastname;
        NSString *handle = [ContactAndProfileManager sharedInstance].profile.profileDetail.handle;
        
        int starCount = (int)[ContactAndProfileManager sharedInstance].profile.profileDetail.starCount;
        Asset *asset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
        
        if (firstName.length == 0) {
            firstName = @" ";
        }
        if (lastName.length == 0) {
            lastName = @" ";
        }
        if (handle.length == 0) {
            handle = @" ";
        }
        
         if (firstName && lastName && asset.attributes && handle) {
        
            NSDictionary *currUserAttributes = @{ @"firstname": firstName,
                                                  @"lastname": lastName,
                                                  @"starCount": @(starCount),
                                                  @"profilePhotoAssetInfo": asset.attributes,
                                                  @"userToken": userToken,
                                                  @"id" : @(userId),
                                                  @"handle" : handle
                                             };

            _currentUser = [[Friend alloc] initWithAttributes:currUserAttributes];
        }
        else if (firstName && lastName && handle) {
            
            NSDictionary *currUserAttributes = @{ @"firstname": firstName,
                                                  @"lastname": lastName,
                                                  @"starCount": @(starCount),
                                                  @"userToken": userToken,
                                                  @"id" : @(userId),
                                                  @"handle" : handle
                                                  };
            
            _currentUser = [[Friend alloc] initWithAttributes:currUserAttributes];
            
        }

    }
    return _currentUser;
}

- (GMSMapView *)mapView {
    if (!_mapView) {
        _mapView = [[GMSMapView alloc] initWithFrame:CGRectMake(200, -200, 45, 90)];
        _mapView.userInteractionEnabled = NO;
    }
    
    return _mapView;
}

-(UIActivityIndicatorView *)spinner {
    if (!_spinner) {
        _spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _spinner.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
        _spinner.color = [UIColor darkGrayColor];
        _spinner.alpha = 0;
        
    }
    return _spinner;
}


#pragma mark - Mutators 

- (void)setPrefetchPaused:(BOOL)prefetchPaused {
    _prefetchPaused = prefetchPaused;
    if (!_prefetchPaused && !self.prefetchInProgress && self.allUserAssets.count > 0) {
        [self prefetchNextAsset];
    }
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [self.allFriends count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView customCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AddFriendsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    
    Friend *tempFriend = self.allFriends[indexPath.item];
    [cell configureWithFriend:tempFriend];
    
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self collectionView:collectionView customCellForItemAtIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // 3.5" & 4" screens
    float itemWidth = 100;
    float itemHeight = 120;
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        itemWidth = 118;
        itemHeight = 140;
    }
    
    //5"
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        itemWidth = 131;
        itemHeight = 157;
    }
   return CGSizeMake(itemWidth, itemHeight);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.view.frame.size.width, self.collectionHeaderHeight);
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = nil;
    
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                          withReuseIdentifier:@"sectionHeader"
                                                                 forIndexPath:indexPath];
        
        for (UIView *subview in reusableView.subviews) {
            [subview removeFromSuperview];
        }
    }
    
    return reusableView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.isLoadingCurrentData) {
        return 1;
    }
    else {
        if (self.currPeopleState == PeopleStateSearchResults) {
            if (self.searchResults.count == 0) {
                return 1;
            }
            else {
                return self.searchResults.count;
            }
        }
        else if (self.currPeopleState == PeopleStateEmpty) {
            return 1;
        }
        else {
            int numUsers = (int)self.rankedUsers.count;
            
            return numUsers;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView rankedUserCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCRankedUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:RankedUserCellIdentifier forIndexPath:indexPath];
    
    if (indexPath.row < self.rankedUsers.count) {
        NSInteger rank = indexPath.row + 1;
        
        NSString *rankSuffix = [cell findSuperscript:rank];
        
        NSString *rankText = [NSString stringWithFormat:@"%@%@", @(rank),rankSuffix];
        NSMutableAttributedString *styledRankText = [[NSMutableAttributedString alloc] initWithString:rankText];
        [styledRankText addAttributes:@{(id < NSCopying >)kCTSuperscriptAttributeName:[NSNumber numberWithInt:1], NSFontAttributeName:[UIFont spc_regularSystemFontOfSize:12]} range:NSMakeRange(rankText.length-2,2)];

        cell.rankLabel.attributedText = styledRankText;
        cell.rank = rank;

        Friend *tempFriend = self.rankedUsers[indexPath.row];
        BOOL viewingFromSearch = NO;
        if (self.currPeopleState == PeopleStateSearchResults) {
            viewingFromSearch = YES;
        }
        
        [cell configureWithPerson:tempFriend peopleState:self.currPeopleState];
        
        [cell.imageButton setTag:indexPath.row];
        [cell.imageButton addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
        
        NSString *userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
        cell.backgroundColor = [UIColor whiteColor];
        if ([userToken isEqualToString:tempFriend.userToken]) {
            cell.youBadge.hidden = NO;
        }
        
        // Display top neighborhood for each user when viewing city ranks
        if (self.currPeopleState == PeopleStateCitySearchResults) {
            if (tempFriend.topNeighborhood.length > 0) {
                cell.territoryNameLabel.text = tempFriend.topNeighborhood;
            }
        }
        
        // Display neighborhood when viewing neighborhood ranks
        if (self.currPeopleState == PeopleStateNeighborhoodSearchResults) {
            cell.territoryNameLabel.text = self.headerTitleLabel.text;
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView unrankedUserCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SPCRankedUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:UnrankedUserCellIdentifier forIndexPath:indexPath];
    
    Person *tempPerson;
     BOOL viewingFromSearch = NO;
    
    if (self.currPeopleState == PeopleStateSearchResults) {
        viewingFromSearch = YES;
        SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
        tempPerson  = result.person;
    }
    
    [cell configureWithPerson:tempPerson peopleState:self.currPeopleState];
    [cell.imageButton setTag:indexPath.row];
    [cell.imageButton addTarget:self action:@selector(handleProfileImageTap:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *userToken = [AuthenticationManager sharedInstance].currentUser.userToken;
    cell.backgroundColor = [UIColor whiteColor];
    if ([userToken isEqualToString:tempPerson.userToken]) {
        cell.youBadge.hidden = NO;
    }
    cell.territoryNameLabel.text = @"Spayce";
    if (tempPerson.topCity.length > 0) {
        cell.territoryNameLabel.text = tempPerson.topCity;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cityCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cityResult";
    
    SPCCitySearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[SPCCitySearchResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    SPCCity *city;
    
    if (self.currPeopleState == PeopleStateSearchResults){
        SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
        city = result.city;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell configureWithCity:city];
    cell.tag = (int)indexPath.row;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView neighborhoodCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"neighborhoodResult";
    
    SPCCitySearchResultCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[SPCCitySearchResultCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    SPCCity *city;
    
    if (self.currPeopleState == PeopleStateSearchResults){
        SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
        city = (SPCCity *)result.neighborhood;
    }
    [cell configureWithCity:city];
    [cell updateForNeighborhood:city];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.tag = (int)indexPath.row;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView noResultsCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *placeholderCell = [tableView dequeueReusableCellWithIdentifier:placeholderCellIdentifier];
    if (!placeholderCell) {
        placeholderCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:placeholderCellIdentifier];
    }
    placeholderCell.textLabel.text = @"No results for your search!";
    placeholderCell.textLabel.textAlignment = NSTextAlignmentCenter;
    placeholderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    placeholderCell.backgroundColor = [UIColor clearColor];
    placeholderCell.contentView.backgroundColor = [UIColor clearColor];
    placeholderCell.textLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    placeholderCell.textLabel.textColor = [UIColor colorWithWhite:155.0f/255.0f alpha:1.0f];
    
    if (self.currPeopleState == PeopleStateEmpty) {
        placeholderCell.textLabel.text = @"Enter text to search for people";
    }
    return placeholderCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    self.spinner.alpha = 1;
    [self.spinner startAnimating];
    
    UITableViewCell *placeholderCell = [tableView dequeueReusableCellWithIdentifier:placeholderCellIdentifier];
    if (!placeholderCell) {
        placeholderCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:placeholderCellIdentifier];
    }
    placeholderCell.textLabel.text = @"";
    placeholderCell.textLabel.textAlignment = NSTextAlignmentCenter;
    placeholderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    placeholderCell.backgroundColor = [UIColor clearColor];
    placeholderCell.contentView.backgroundColor = [UIColor clearColor];
    placeholderCell.textLabel.font = [UIFont spc_regularSystemFontOfSize:14];
    placeholderCell.textLabel.textColor = [UIColor colorWithWhite:155.0f/255.0f alpha:1.0f];
    
    return placeholderCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView getStartedCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SPCGetStartedTableViewCell *placeholderCell = [tableView dequeueReusableCellWithIdentifier:getStartedCellIdentifier];
    if (!placeholderCell) {
        placeholderCell = [[SPCGetStartedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:getStartedCellIdentifier];
    }
    placeholderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    placeholderCell.backgroundColor = [UIColor clearColor];
    placeholderCell.contentView.backgroundColor = [UIColor clearColor];
    placeholderCell.accessoryType = UITableViewCellAccessoryNone;
    
    // Add a target to the cell's button
    [placeholderCell.addFriendsButton addTarget:self action:@selector(inviteFriends:) forControlEvents:UIControlEventTouchUpInside];
    
    return placeholderCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if (self.isLoadingCurrentData) {
        return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
    } else if (self.currPeopleState == PeopleStateEmpty) {
        return [self tableView:tableView noResultsCellForRowAtIndexPath:indexPath];
    } else if (self.currPeopleState == PeopleStateSearchResults) {
        
        if (self.searchResults.count == 0) {
            return [self tableView:tableView noResultsCellForRowAtIndexPath:indexPath];
        }
        else {
            SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
            
            if (result.searchResultType == SearchResultFriend) {
                return [self tableView:tableView unrankedUserCellForRowAtIndexPath:indexPath];
            }
            if (result.searchResultType == SearchResultCeleb) {
                return [self tableView:tableView unrankedUserCellForRowAtIndexPath:indexPath];
            }
            if (result.searchResultType == SearchResultCity) {
                return [self tableView:tableView cityCellForRowAtIndexPath:indexPath];
            }
            if (result.searchResultType == SearchResultNeighborhood) {
                return [self tableView:tableView neighborhoodCellForRowAtIndexPath:indexPath];
            }
            if (result.searchResultType == SearchResultStranger) {
                return [self tableView:tableView unrankedUserCellForRowAtIndexPath:indexPath];
            }
        }
    }
    else if (self.currPeopleState == PeopleStateCitySearchResults) {
        if (self.rankedUsers.count > 0) {
            return [self tableView:tableView rankedUserCellForRowAtIndexPath:indexPath];
        }
        else {
            return  [self tableView:tableView noResultsCellForRowAtIndexPath:indexPath];
        }
    }
    else if (self.currPeopleState == PeopleStateNeighborhoodSearchResults) {
        if (self.rankedUsers.count > 0) {
            return [self tableView:tableView rankedUserCellForRowAtIndexPath:indexPath];
        }
        else {
            return  [self tableView:tableView noResultsCellForRowAtIndexPath:indexPath];
        }
    }
   
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
   
    if ([cell.reuseIdentifier isEqualToString:RankedUserCellIdentifier]) {
        
        //get user details
        Friend *friend;
        if (indexPath.row < self.rankedUsers.count) {
            friend = self.rankedUsers[indexPath.row];
        }
            
        //add to recent searches if necessary
        if (self.currPeopleState == PeopleStateSearchResults) {
            [self addSearchToRecentSearch:self.recentSearchResults[indexPath.row]];
        }
        
        if (self.currPeopleState >= PeopleStateCitySearchResults) {
            SPCPeopleSearchResult *selectedResult = [[SPCPeopleSearchResult alloc] initWithPerson:friend];
            [self addSearchToRecentSearch:selectedResult];
        }
        
        //display profile
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:friend.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
    if ([cell.reuseIdentifier isEqualToString:UnrankedUserCellIdentifier]) {

        //get user details
        Person *person;
        if (self.currPeopleState == PeopleStateSearchResults) {
            SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
            person = result.person;
            
            if (person.recordID != -2) {
            
                //add to recent searches
                [self addSearchToRecentSearch:result];
            }
        }
        
        if (person.recordID == -2) {
            [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
        }
        else {
            //display profile
            SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:person.userToken];
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
        
    }
    if ([cell.reuseIdentifier isEqualToString:@"cityResult"]) {
        
        //get the selected city
        SPCCity *city;

        if (self.currPeopleState == PeopleStateSearchResults) {
            SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
            city = result.city;
         
            //add to recent searches
            [self addSearchToRecentSearch:result];
        }
        
        //fetch ranked users for city
        self.currPeopleState = PeopleStateCitySearchResults;
        
        // Reload view right away and show loader while fetching
        self.isLoadingCurrentData = YES;
        [self reloadData];
        [self fetchRankedUsersForCity:city cacheResults:NO];

    }
    if ([cell.reuseIdentifier isEqualToString:@"neighborhoodResult"]) {
        
        //get the selected neighborhood
        SPCNeighborhood *neighborhood;
        
        if (self.currPeopleState == PeopleStateSearchResults) {
    
            SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
            neighborhood = result.neighborhood;
        
            //add to recent searches
            [self addSearchToRecentSearch:result];
        
        }
        
        //fetch ranked users for neighborhood
        self.currPeopleState = PeopleStateNeighborhoodSearchResults;
        
        // Reload view right away and show loader
        self.isLoadingCurrentData = YES;
        [self reloadData];
        
        [self fetchRankedUsersForNeighborhood:neighborhood cacheResults:NO];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.isLoadingCurrentData) {
        return self.tableView.frame.size.height - 216;
    }
    
    
    //placeholder?
    if (self.currPeopleState >= PeopleStateEmpty) {
        int combinedCount = 0;
        
        if (self.currPeopleState == PeopleStateSearchResults) {
            combinedCount = (int)self.searchResults.count;
        }
        if (self.currPeopleState == PeopleStateEmpty) {
            combinedCount = (int)self.recentSearchResults.count;
        }
        if (self.currPeopleState >= PeopleStateCitySearchResults) {
            combinedCount = (int)self.rankedUsers.count;
        }
        
        if (combinedCount == 0) {
            return self.tableView.frame.size.height - 216;
        }
    }
    
    //dynamic height based on content type when displaying search/recent searches
    
    if (self.currPeopleState == PeopleStateSearchResults) {
       
        SPCPeopleSearchResult *result = self.searchResults[indexPath.row];
        if ((result.searchResultType == SearchResultCity) || (result.searchResultType == SearchResultNeighborhood)) {
            return 60;
        }
        else {
             return 75;
        }
    }
    if (self.currPeopleState == PeopleStateEmpty) {
        SPCPeopleSearchResult *result = self.recentSearchResults[indexPath.row];
        if ((result.searchResultType == SearchResultCity) || (result.searchResultType == SearchResultNeighborhood)) {
            return 60;
        }
        else {
            return 75;
        }
    }
    else {
        if (indexPath.row < self.rankedUsers.count) {
            return 75;
        }
        else {
            return self.tableView.frame.size.height - 216;
        }
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
    if (textField.text.length == 0) {
        [Flurry logEvent:@"PEOPLE_SEARCH_TAPPED"];
        [self clearSearch];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField.text.length == 0) {
        
        if ((self.currPeopleState == PeopleStateCitySearchResults) || (self.currPeopleState == PeopleStateNeighborhoodSearchResults) ) {
            self.textField.text = self.activePlacename;
        }
        else {
            self.promptContainer.alpha = 1;
            self.promptText.alpha = 0;
            [self fadeUpPrompt];
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    self.promptContainer.alpha = 0;
    self.promptText.alpha = 0;
    
    if (text.length >= 100) {
        return NO;
    }
    else if (text.length == 0) {
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
        self.headerTitleLabel.text = @"";
        [self clearSearch];
        textField.text = nil;
    }
    else {
        self.cancelSearchBtn.hidden = YES;
        self.resetSearchBtn.hidden = NO;
        
        // Cancel previous filter request
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-on"];
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
        [self performSelector:@selector(filterContentForSearchText:) withObject:text afterDelay:0.1];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Friend *tempFriend = self.allFriends[indexPath.item];
    SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:tempFriend.userToken];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.scrolling = YES;
    self.draggingScrollView = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.scrolling = NO;
 
    self.draggingScrollView = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // We do not allow scrolling while searching by design.
    // This is due to a bug that can be caused while data model
    // changes during the scrolling that leads to a crash.
    //NSLog(@"scrollView.contentOffset y %f",scrollView.contentOffset.y);
    
    if (self.isScrolling) {
        [self.textField resignFirstResponder];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.draggingScrollView = NO;
}


#pragma mark - Content filtering

- (void)filterContentForSearchText:(NSString *)searchText {
    // Cancel any previous search operations before performing a new one
    if (self.searchOperationQueue) {
        [self.searchOperationQueue cancelAllOperations];
    }
    
    if (searchText.length > 0) {
    
        NSBlockOperation *operation = [[NSBlockOperation alloc] init];
        
        __weak typeof(self)weakSelf = self;
        __weak typeof(operation)weakOperation = operation;
        
        [operation addExecutionBlock:^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            __strong typeof(weakOperation)strongOperation = weakOperation;
            
            if (strongOperation.isCancelled) {
                return;
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (strongOperation.isCancelled) {
                    return;
                }
                // Reload view right away and show loader
                strongSelf.isLoadingCurrentData = YES;
                [strongSelf reloadData];
                [strongSelf fetchUnifiedResultsWithSearchString:searchText];
            }];
        }];
        [self.searchOperationQueue addOperation:operation];
    }
    else {
        self.headerTitleLabel.text = @"";
        
        [self fadeUpPrompt];
        
        self.textField.text = nil;
        [self.textField resignFirstResponder];
    }
}

- (void)processSearchResults {
    
    /* Goal: combine search results of various types and display based on the following logic:
    
     1. Up to 2 friends
     2. Up to 2 celebs
     3. Up to 2 cities
     4. Up to 2 neighborhoods
     5. Up to 2 strangers
    
     5. Repeat
    */
    
    // Approach - create an array for each group, and then combine them into a unified, sorted array of SPCSearchResult model objects
    
    //a. sort the people in the search results into friends/celebs/strangers groups
    NSMutableArray *friendsInResults = [[NSMutableArray alloc] init];
    NSMutableArray *celebsInResults = [[NSMutableArray alloc] init];
    NSMutableArray *strangersInResults = [[NSMutableArray alloc] init];
    NSMutableArray *citiesInResults = [NSMutableArray arrayWithArray:self.cityResults];
    NSMutableArray *neighborhoodsInResults = [NSMutableArray arrayWithArray:self.neighborhoodResults];
    
    for (int i = 0; i < self.unrankedUsers.count; i++) {
        
        Person *person = (Person *)self.unrankedUsers[i];
        if (person.followingStatus == FollowingStatusFollowing) {
            [friendsInResults addObject:person];
        }
        else if (person.isCeleb) {
            [celebsInResults addObject:person];
        }
        else {
            [strangersInResults addObject:person];
        }
    }
    
    //NSLog(@"friends %i, celebs %i, strangers %i, cities %i, neighborhoods %i",(int)friendsInResults.count,(int)celebsInResults.count,(int)strangersInResults.count,(int)citiesInResults.count,(int)neighborhoodsInResults.count);
    
    int totalResults = (int)friendsInResults.count + (int)celebsInResults.count + (int)strangersInResults.count + (int)citiesInResults.count + (int)neighborhoodsInResults.count;
    // NSLog(@"total results %i",totalResults);
    
    //sort and combine all result types
    NSMutableArray *comboArray = [[NSMutableArray alloc] init];

    int lastContentType = -1;
    int currentContentType = 0;
    
    for (int i = 0; i < totalResults; i++) {
        
        // get a friend
        if (currentContentType == SearchResultFriend) {
            
            //do we have a friend?
            if (friendsInResults.count > 0) {
                SPCPeopleSearchResult *result = [[SPCPeopleSearchResult alloc] initWithPerson:friendsInResults[0]];
                result.searchResultType = SearchResultFriend;
                [comboArray addObject:result];
                [friendsInResults removeObjectAtIndex:0];
                
                if (lastContentType == SearchResultFriend) {
                    //we have included 2 friends in a row, continue our progression...
                    currentContentType = SearchResultCeleb;
                } else {
                    lastContentType = SearchResultFriend;
                }
            }
            // we don't have any remaining friends to display
            else {
                currentContentType = SearchResultCeleb;
            }
            
        }
        
        // get a celeb
        if (currentContentType == SearchResultCeleb) {
            
            //do we have a celeb?
            if (celebsInResults.count > 0) {
                SPCPeopleSearchResult *result = [[SPCPeopleSearchResult alloc] initWithPerson:celebsInResults[0]];
                result.searchResultType = SearchResultCeleb;
                [comboArray addObject:result];
                [celebsInResults removeObjectAtIndex:0];
                
                if (lastContentType == SearchResultCeleb) {
                    //we have included 2 celebs in a row, continue our progression...
                    currentContentType = SearchResultCity;
                } else {
                    lastContentType = SearchResultCeleb;
                }
            }
            // we don't have any remaining celbs to display
            else {
                currentContentType = SearchResultCity;
            }
        }
        
        // get a city
        if (currentContentType == SearchResultCity) {
            
            //do we have a city?
            if (citiesInResults.count > 0) {
                SPCPeopleSearchResult *result = [[SPCPeopleSearchResult alloc] initWithCity:citiesInResults[0]];
                result.searchResultType = SearchResultCity;
                [comboArray addObject:result];
                [citiesInResults removeObjectAtIndex:0];
                
                if (lastContentType == SearchResultCity) {
                    //we have included 2 cities in a row, continue our progression...
                    currentContentType = SearchResultNeighborhood;
                } else {
                    lastContentType = SearchResultCity;
                }
            }
            // we don't have any remaining cities to display
            else {
                currentContentType = SearchResultNeighborhood;
            }
        }
        
        // get a neighborhood
        if (currentContentType == SearchResultNeighborhood) {
            
            //do we have a neighborhood?
            if (neighborhoodsInResults.count > 0) {
                SPCPeopleSearchResult *result = [[SPCPeopleSearchResult alloc] initWithNeighborhood:neighborhoodsInResults[0]];
                result.searchResultType = SearchResultNeighborhood;
                [comboArray addObject:result];
                [neighborhoodsInResults removeObjectAtIndex:0];
                
                if (lastContentType == SearchResultNeighborhood) {
                    //we have included 2 neighborhoods in a row, continue our progression...
                    currentContentType = SearchResultStranger;
                } else {
                    lastContentType = SearchResultNeighborhood;
                }
            }
            // we don't have any remaining neighborhoods to display
            else {
                currentContentType = SearchResultStranger;
            }
            
        }
        
        // get a stranger
        if (currentContentType == SearchResultStranger) {
            //do we have a stranger?
            if (strangersInResults.count > 0) {
                SPCPeopleSearchResult *result = [[SPCPeopleSearchResult alloc] initWithPerson:strangersInResults[0]];
                result.searchResultType = SearchResultStranger;
                [comboArray addObject:result];
                [strangersInResults removeObjectAtIndex:0];
                
                if (lastContentType == SearchResultStranger) {
                    //we have included 2 strangers in a row, restart our progression...
                    currentContentType = SearchResultFriend;
                } else {
                    lastContentType = SearchResultStranger;
                }
            }
            // we don't have any remaining strangers to display
            else {
                currentContentType = SearchResultFriend;
            }
        }
    }
    
    //Did it work??
    /*
    for (int i = 0; i < comboArray.count; i++) {
        SPCPeopleSearchResult *result = comboArray[i];
        NSLog(@"result type %li",result.searchResultType);
    }
    NSLog(@"combo array count %li",comboArray.count);
     */
    self.searchResults = [NSArray arrayWithArray:comboArray];
    
}

- (void)addSearchToRecentSearch:(SPCPeopleSearchResult *)result {
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.recentSearchResults];
    
    BOOL isDuplicate = NO;
    
    for (int i = 0; i < tempArray.count; i++) {
        
        SPCPeopleSearchResult *tempResult = tempArray[i];
        
        if (result.searchResultType == tempResult.searchResultType) {
           
            if (result.searchResultType == SearchResultCity) {
                if ([result.city.cityName isEqualToString:tempResult.city.cityName]) {
                    isDuplicate = YES;
                    break;
                }
            }
            if (result.searchResultType == SearchResultNeighborhood) {
                if ([result.city.neighborhoodName isEqualToString:tempResult.city.neighborhoodName]) {
                    isDuplicate = YES;
                    break;
                }
            }
            if (result.searchResultType == SearchResultFriend) {
                if ([result.person.userToken isEqualToString:tempResult.person.userToken]) {
                    isDuplicate = YES;
                    break;
                }
            }
          if (result.searchResultType == SearchResultStranger) {
                if ([result.person.userToken isEqualToString:tempResult.person.userToken]) {
                    isDuplicate = YES;
                    break;
                }
            }
            if (result.searchResultType == SearchResultCeleb) {
                if ([result.person.userToken isEqualToString:tempResult.person.userToken]) {
                    isDuplicate = YES;
                    break;
                }
            }
        }
    }
    
    
    if (!isDuplicate) {
    
        NSLog(@"not a duplicate??");
        
        [tempArray insertObject:result atIndex:0];
        
        for (int i = 10; i < tempArray.count; i++) {
            [tempArray removeObjectAtIndex:i];
        }
        self.recentSearchResults = [NSArray arrayWithArray:tempArray];
        
        [self translateAndPersistRecentSearches];
    }
}

-(void)translateAndPersistRecentSearches {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < self.recentSearchResults.count; i ++) {
        
        SPCPeopleSearchResult *result = self.recentSearchResults[i];
        
        if (result.searchResultType == SearchResultCity) {
 
            //translate info using plist friendly data types
            NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
            [self addNotNilToDictionary:resultDict key:@"type" value:[NSString stringWithFormat:@"%i", (int)SearchResultCity]];
            [self addNotNilToDictionary:resultDict key:@"city" value:result.city.cityName];
            [self addNotNilToDictionary:resultDict key:@"stateAbbr" value:result.city.stateAbbr];
            [self addNotNilToDictionary:resultDict key:@"countryAbbr" value:result.city.countryAbbr];
            [self addNotNilToDictionary:resultDict key:@"county" value:result.city.county];
            
            [tempArray addObject:[NSDictionary dictionaryWithDictionary:resultDict]];
        }
        if (result.searchResultType == SearchResultNeighborhood) {
            //translate info using plist friendly data types
            NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
            [self addNotNilToDictionary:resultDict key:@"type" value:[NSString stringWithFormat:@"%i", (int)SearchResultNeighborhood]];
            [self addNotNilToDictionary:resultDict key:@"neighborhood" value:result.neighborhood.neighborhoodName];
            [self addNotNilToDictionary:resultDict key:@"city" value:result.neighborhood.cityName];
            [self addNotNilToDictionary:resultDict key:@"stateAbbr" value:result.neighborhood.stateAbbr];
            [self addNotNilToDictionary:resultDict key:@"countryAbbr" value:result.neighborhood.countryAbbr];
            [self addNotNilToDictionary:resultDict key:@"county" value:result.neighborhood.county];
            
            [tempArray addObject:[NSDictionary dictionaryWithDictionary:resultDict]];
        }
        if (result.searchResultType == SearchResultFriend) {
            //translate and persist necessary info
            
            if (result.person.userToken.length == 0) {
                return;
            }
            if (result.person.firstname.length == 0) {
                return;
            }
            if (result.person.lastname.length == 0) {
                return;
            }
            if (!result.person.profilePhotoAssetInfo) {
                return;
            }
            if (result.person.handle.length == 0) {
                return;
            }
            
            NSDictionary *resultDict =  @{ @"type" : [NSString stringWithFormat:@"%i", (int)SearchResultFriend],
                                           @"userToken" : result.person.userToken,
                                           @"firstname" : result.person.firstname,
                                           @"lastname" : result.person.lastname,
                                           @"friendStatus" : @"FRIEND",
                                           @"profilePhotoAssetID" : result.person.profilePhotoAssetID,
                                           @"profilePhotoAssetInfo" : result.person.profilePhotoAssetInfo,
                                           @"handle" : result.person.handle,
                                           @"starCount" : @(result.person.starCount)
                                           };
            
            
            [tempArray addObject:resultDict];

        }
        if (result.searchResultType == SearchResultStranger) {
            //translate and persist necessary info
            
            if (result.person.userToken.length == 0) {
                return;
            }
            if (result.person.firstname.length == 0) {
                return;
            }
            if (result.person.lastname.length == 0) {
                return;
            }
            if (!result.person.profilePhotoAssetInfo) {
                return;
            }
            if (result.person.handle.length == 0) {
                return;
            }
            
            
            NSDictionary *resultDict =  @{ @"type" : [NSString stringWithFormat:@"%i", (int)SearchResultStranger],
                                           @"userToken" : result.person.userToken,
                                           @"firstname" : result.person.firstname,
                                           @"lastname" : result.person.lastname,
                                           @"friendStatus" : @"NONE",
                                           @"profilePhotoAssetID" : result.person.profilePhotoAssetID,
                                           @"profilePhotoAssetInfo" : result.person.profilePhotoAssetInfo,
                                           @"handle" : result.person.handle,
                                           @"starCount" : @(result.person.starCount)
                                           };
            
            
            [tempArray addObject:resultDict];
            
        }
        if (result.searchResultType == SearchResultCeleb) {
            //translate and persist necessary info
            
            if (result.person.userToken.length == 0) {
                return;
            }
            if (result.person.firstname.length == 0) {
                return;
            }
            if (result.person.lastname.length == 0) {
                return;
            }
            if (!result.person.profilePhotoAssetInfo) {
                return;
            }
            if (result.person.handle.length == 0) {
                return;
            }
            
            NSDictionary *resultDict =  @{ @"type" : [NSString stringWithFormat:@"%i",(int)SearchResultCeleb],
                                           @"userToken" : result.person.userToken,
                                           @"firstname" : result.person.firstname,
                                           @"lastname" : result.person.lastname,
                                           @"friendStatus" : @"NONE",
                                           @"profilePhotoAssetID" : result.person.profilePhotoAssetID,
                                           @"profilePhotoAssetInfo" : result.person.profilePhotoAssetInfo,
                                           @"handle" : result.person.handle,
                                           @"starCount" : @(result.person.starCount)
                                           };
            
            [tempArray addObject:resultDict];
        }
        
    }
    
    // persist searches
    [[NSUserDefaults standardUserDefaults] setObject:tempArray forKey:@"recentSearches"];
}

- (void)addNotNilToDictionary:(NSMutableDictionary *)dictionary key:(NSString *)key value:(NSObject *)value {
    if (value) {
        dictionary[key] = value;
    }
}

- (NSArray *)restoreRecentSearches:(NSArray *)restoredSearches {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < restoredSearches.count; i++) {
        
        NSDictionary *dict = restoredSearches[i];
        NSString *type = [dict objectForKey:@"type"];
        NSInteger intType = [type integerValue];
        
        if (intType == SearchResultCity) {
            SPCCity *city = [[SPCCity alloc] initWithAttributes:dict];
            SPCPeopleSearchResult *searchResult = [[SPCPeopleSearchResult alloc] initWithCity:city];
            searchResult.searchResultType = SearchResultCity;
            [tempArray addObject:searchResult];
        }
        
        if (intType == SearchResultNeighborhood) {
            SPCNeighborhood *neighborhood = [[SPCNeighborhood alloc] initWithAttributes:dict];
            SPCPeopleSearchResult *searchResult = [[SPCPeopleSearchResult alloc] initWithNeighborhood:neighborhood];
            searchResult.searchResultType = SearchResultNeighborhood;
            [tempArray addObject:searchResult];
        }
        
        if (intType == SearchResultFriend) {
            Person *person = [[Person alloc] initWithAttributes:dict];
            SPCPeopleSearchResult *searchResult = [[SPCPeopleSearchResult alloc] initWithPerson:person];
            person.followingStatus = FollowingStatusFollowing;
            searchResult.searchResultType = SearchResultFriend;
            [tempArray addObject:searchResult];
        }
    
        if (intType == SearchResultStranger) {
            Person *person = [[Person alloc] initWithAttributes:dict];
            SPCPeopleSearchResult *searchResult = [[SPCPeopleSearchResult alloc] initWithPerson:person];
            person.followingStatus = FollowingStatusNotFollowing;
            searchResult.searchResultType = SearchResultStranger;
            [tempArray addObject:searchResult];
        }
        
        if (intType == SearchResultCeleb) {
            Person *person = [[Person alloc] initWithAttributes:dict];
            SPCPeopleSearchResult *searchResult = [[SPCPeopleSearchResult alloc] initWithPerson:person];
            person.followingStatus = FollowingStatusNotFollowing;
            searchResult.searchResultType = SearchResultCeleb;
            [tempArray addObject:searchResult];
        }
    }
    
    return tempArray;
}

#pragma mark - Private

- (void)fetchFollowedUsers {
    
    [self spc_hideNotificationBanner];
    
    self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
}


- (void)fetchRankedUsersForCity:(SPCCity *)city cacheResults:(BOOL)cityDefault {
    [self spc_hideNotificationBanner];
  
    __weak typeof(self)weakSelf = self;
    
    [MeetManager fetchRankedUserForCity:(SPCCity *)city
                      completionHandler:^(NSArray *cityUsers, NSInteger cityPop) {
                          
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          if (!strongSelf) {
                              return ;
                          }
                          
                          if ([city.countryAbbr isEqualToString:@"US"]) {
                              strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", city.cityName,city.stateAbbr];
                          }
                          else {
                              strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", city.cityName,city.countryAbbr];
                              
                              if (city.stateAbbr.length > 0) {
                                  strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@, %@", city.cityName, city.stateAbbr, city.countryAbbr];
                              }
                          }
                      
                          if (cityPop > 0) {
                              strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 30, self.view.bounds.size.width-20, 20);
                              strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2);
                              strongSelf.headerSubtitleLabel.text = [self commaPopulation:cityPop];
                          }
                          else {
                              strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 15, self.view.bounds.size.width-20, 20);
                              strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2 + 10);
                              strongSelf.headerSubtitleLabel.text = @"";
                          }
                          
                          // Sort array
                          NSMutableArray *unsortedArray = [NSMutableArray arrayWithArray:cityUsers];
                          NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starCount" ascending:NO];
                          [unsortedArray sortUsingDescriptors:@[starSorter]];
                          NSArray *sortedArray = [NSArray arrayWithArray:unsortedArray];
                          
                          if (strongSelf.currPeopleState == PeopleStateCitySearchResults) {
                              // Reload view
                              strongSelf.rankedUsers = sortedArray;
                              strongSelf.promptText.alpha = 0;
                              strongSelf.textField.text = city.cityName;
                              strongSelf.cancelSearchBtn.hidden = YES;
                              strongSelf.resetSearchBtn.hidden = NO;
                              strongSelf.isLoadingCurrentData = NO;
                              [strongSelf reloadData];
                          }
                          
                          // prefetch
                          [strongSelf performSelector:@selector(prefetchUserAssets:) withObject:cityUsers afterDelay:0.1f];
                              
                      } errorHandler:^(NSError *error) {

                      }];
}

- (void)fetchRankedUsersForNeighborhood:(SPCNeighborhood *)neighborhood cacheResults:(BOOL)localDefault {
    [self spc_hideNotificationBanner];
    
    __weak typeof(self)weakSelf = self;
    
    [MeetManager fetchRankedUserForNeighborhood:(SPCNeighborhood *)neighborhood
                         rankInCityIfFewResults:localDefault
                      completionHandler:^(NSArray *neighborhoodUsers, SPCCity *city, NSInteger cityPop) {
                          __strong typeof(weakSelf)strongSelf = weakSelf;
                          if (!strongSelf) {
                              return ;
                          }
                          //use the city/neighborhood we got back from server if it's there
                          if (city) {
                              if (localDefault) {
                                  strongSelf.currLocalResult = city;
                              }
                              if (city.neighborhoodName.length > 0) {
                                  strongSelf.activePlacename = city.neighborhoodName;
                                  strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", city.neighborhoodName,city.cityName];
                                  strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 15, strongSelf.view.bounds.size.width-20, 20);
                                  strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2 + 10);
                                  strongSelf.headerSubtitleLabel.text = @"";
                              }
                              else {
                                  
                                  strongSelf.activePlacename = city.cityName;
                                  
                                  if ([city.countryAbbr isEqualToString:@"US"]) {
                                      strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", city.cityName,city.stateAbbr];
                                  }
                                  else {
                                      strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", city.cityName,city.countryAbbr];
                                      
                                      if (city.stateAbbr.length > 0) {
                                          strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@, %@", city.cityName, city.stateAbbr, city.countryAbbr];
                                      }
                                  }
                                  
                                  if (cityPop > 0) {
                                      strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 30, strongSelf.view.bounds.size.width-20, 20);
                                      strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2);
                                      strongSelf.headerSubtitleLabel.text = [self commaPopulation:cityPop];
                                      if (localDefault) {
                                          strongSelf.cachedPop = [self commaPopulation:cityPop];
                                          NSLog(@"strongSelf.cachedPopulation: %@",strongSelf.cachedPop);
                                      }
                                  }
                                  else {
                                      strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 15, strongSelf.view.bounds.size.width-20, 20);
                                      strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2 + 10);
                                      strongSelf.headerSubtitleLabel.text = @"";
                                  }
                              }
                          }
                          //fallback to display our params for the place if the server didn't provide us with a location
                          else {
                              if (localDefault) {
                                  strongSelf.currLocalResult = neighborhood;
                              }
                              if (neighborhood.neighborhoodName.length > 0) {
                                  strongSelf.activePlacename = neighborhood.neighborhoodName;
                                  strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", neighborhood.neighborhoodName,neighborhood.cityName];
                                  strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 15, strongSelf.view.bounds.size.width-20, 20);
                                  strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2 + 10);
                                  strongSelf.headerSubtitleLabel.text = @"";
                              }
                              else {
                                  strongSelf.activePlacename = neighborhood.cityName;

                                  if ([neighborhood.countryAbbr isEqualToString:@"US"]) {
                                      strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", neighborhood.cityName,neighborhood.stateAbbr];
                                  }
                                  else {
                                      strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@", neighborhood.cityName,neighborhood.countryAbbr];
                                      
                                      if (neighborhood.stateAbbr.length > 0) {
                                          strongSelf.headerTitleLabel.text = [NSString stringWithFormat:@"%@, %@, %@", neighborhood.cityName, neighborhood.stateAbbr, neighborhood.countryAbbr];
                                      }
                                  }
                                  
                                  
                                  if (cityPop > 0) {
                                      strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 30, self.view.bounds.size.width-20, 20);
                                      strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2);
                                      strongSelf.headerSubtitleLabel.text = [self commaPopulation:cityPop];
                                      if (localDefault) {
                                          strongSelf.cachedPop = [self commaPopulation:cityPop];
                                          NSLog(@"strongSelf.cachedPopulation: %@",strongSelf.cachedPop);
                                      }
                                  }
                                  else {
                                      strongSelf.headerTitleLabel.frame = CGRectMake(10, (strongSelf.headerHeight / 2) - 15, self.view.bounds.size.width-20, 20);
                                      strongSelf.headerUnderline.center = CGPointMake(strongSelf.headerView.frame.size.width/2, strongSelf.headerHeight / 2 + 10);
                                      strongSelf.headerSubtitleLabel.text = @"";
                                  }
                                  
                              }
                          }
                          
                    
                       
                          // Sort array
                          NSMutableArray *unsortedArray = [NSMutableArray arrayWithArray:neighborhoodUsers];
                          NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starCount" ascending:NO];
                          [unsortedArray sortUsingDescriptors:@[starSorter]];
                          NSArray *sortedArray = [NSArray arrayWithArray:unsortedArray];
                          
                          if (strongSelf.currPeopleState == PeopleStateNeighborhoodSearchResults) {
                              strongSelf.rankedUsers = sortedArray;
                          }
                          
                          if (localDefault) {
                              //NSLog(@"caching local default! %@ %@",neighborhood.cityName,neighborhood.neighborhoodName);
                              strongSelf.cachedLocal = neighborhood;
                              strongSelf.cachedLocalResults = sortedArray;
                          }
                          
                          
                          // Reload view
                          if (strongSelf.currPeopleState == PeopleStateNeighborhoodSearchResults) {
                              strongSelf.activePlacename = neighborhood.neighborhoodName;
                              strongSelf.promptText.alpha = 0;
                              strongSelf.textField.text = neighborhood.neighborhoodName;
                              [strongSelf.textField resignFirstResponder];
                              strongSelf.cancelSearchBtn.hidden = YES;
                              strongSelf.resetSearchBtn.hidden = NO;
                              strongSelf.isLoadingCurrentData = NO;
                              [strongSelf reloadData];
                          }
                          
                          // prefetch
                          [strongSelf performSelector:@selector(prefetchUserAssets:) withObject:neighborhoodUsers afterDelay:0.1f];
                          
                      } errorHandler:^(NSError *error) {

                      }];
}

- (void)fetchUnifiedResultsWithSearchString:(NSString *)searchStr {
    [self spc_hideNotificationBanner];
    
    
    [MeetManager fetchUsersWithSearch:searchStr
                    completionHandler:^(NSArray *users) {
                        [self spc_hideNotificationBanner];
                        self.currPeopleState = PeopleStateSearchResults;
                        
                        self.unrankedUsers = users;
                        
                        // Reload view
                        self.isLoadingCurrentData = NO;
                        [self processSearchResults];
                        
                        [self reloadData];
                        
                        if (![searchStr isEqualToString:self.textField.text]){
                            
                            //NSLog(@"Search string has changed since search occurred!");
                            //DO ANOTHER SEARCH!
                            
                            if (self.searchOperationQueue) {
                                [self.searchOperationQueue cancelAllOperations];
                            }
                            
                            
                            if (self.textField.text.length > 0) {
                                
                                NSBlockOperation *operation = [[NSBlockOperation alloc] init];
                                
                                __weak typeof(self) weakSelf = self;
                                __weak typeof(operation) weakOperation = operation;
                                
                                [operation addExecutionBlock:^{
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    __strong typeof(weakOperation) strongOperation = weakOperation;
                                    
                                    if (strongOperation.isCancelled) {
                                        return;
                                    }
                                    
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        if (strongOperation.isCancelled) {
                                            return;
                                        }
                                        [strongSelf fetchUnifiedResultsWithSearchString:strongSelf.textField.text];
                                    }];
                                }];
                                [self.searchOperationQueue addOperation:operation];
                            }
                            else {
                                [self clearSearch];
                                
                                self.textField.text = nil;                                
                            }
                        }
                        
                        // prefetch
                        [self performSelector:@selector(prefetchUserAssets:) withObject:users afterDelay:0.1f];
                        
                    } errorHandler:^(NSError *error) {
                        //                                                                         NSLog(@"no users with search str %@",searchStr);
                        
                        // Reload view
                        self.isLoadingCurrentData = NO;
                        [self processSearchResults];
                        
                        [self reloadData];
                    }];
    
    // ---------  KEEP FOR WHEN UNIFIED SEARCH IS RESTORED IN EARLY MARCH !!!!
    
    /*
    //1. fetch cities
    [MeetManager fetchCitiesWithSearch:searchStr
                     completionHandler:^(NSArray *cities) {
                         [self spc_hideNotificationBanner];
     
                         int maxResult = cities.count > 10 ? 10 : (int)cities.count;
     
                         //limit city results to a max of 10
                         NSMutableArray *tempArray = [[NSMutableArray alloc] init];
                         for (int i = 0; i < maxResult; i++) {
                             [tempArray addObject:cities[i]];
                         }
     
                         self.currPeopleState = PeopleStateSearchResults;
                         self.cityResults = [NSArray arrayWithArray:tempArray];
     
     
                         //2. fetch neighborhoods
     
                         [MeetManager fetchNeighborhoodsWithSearch:searchStr
                                                 completionHandler:^(NSArray *neighborhoods) {
                                                     [self spc_hideNotificationBanner];
     
                                                     self.neighborhoodResults = neighborhoods;
     
                                                     [NSObject cancelPreviousPerformRequestsWithTarget:self];
     
                                                     // 3. fetch users
                                                     [MeetManager fetchUsersWithSearch:searchStr
                                                                     completionHandler:^(NSArray *users) {
                                                                         [self spc_hideNotificationBanner];
     
                                                                         self.unrankedUsers = users;
     
                                                                         // Reload view
                                                                         self.isLoadingCurrentData = NO;
                                                                         [self processSearchResults];
     
                                                                         [self reloadData];
     
                                                                         if (![searchStr isEqualToString:self.textField.text]){
     
                                                                             //NSLog(@"Search string has changed since search occurred!");
                                                                             //DO ANOTHER SEARCH!
                                                                             
                                                                             if (self.searchOperationQueue) {
                                                                                 [self.searchOperationQueue cancelAllOperations];
                                                                             }
                                                                             
                                                                             
                                                                             if (self.textField.text.length > 0) {
                                                                                 
                                                                                 NSBlockOperation *operation = [[NSBlockOperation alloc] init];
                                                                                 
                                                                                 __weak typeof(self) weakSelf = self;
                                                                                 __weak typeof(operation) weakOperation = operation;
                                                                                 
                                                                                 [operation addExecutionBlock:^{
                                                                                     __strong typeof(weakSelf) strongSelf = weakSelf;
                                                                                     __strong typeof(weakOperation) strongOperation = weakOperation;
                                                                                     
                                                                                     if (strongOperation.isCancelled) {
                                                                                         return;
                                                                                     }
                                                                                     
                                                                                     [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                                                         if (strongOperation.isCancelled) {
                                                                                             return;
                                                                                         }
                                                                                         [strongSelf fetchUnifiedResultsWithSearchString:strongSelf.textField.text];
                                                                                     }];
                                                                                 }];
                                                                                 [self.searchOperationQueue addOperation:operation];
                                                                             }
                                                                             else {
                                                                                 [self clearSearch];
                                                                                 
                                                                                 self.textField.text = nil;
                                                                                 if ([self.textField isFirstResponder]) {
                                                                                     [self.textField resignFirstResponder];
                                                                                 }

                                                                             }
                                                                         }
                                                                         
                                                                         // prefetch
                                                                         [self performSelector:@selector(prefetchUserAssets:) withObject:users afterDelay:0.1f];
                                                                         
                                                                     } errorHandler:^(NSError *error) {
//                                                                         NSLog(@"no users with search str %@",searchStr);
                                                                         
                                                                         // Reload view
                                                                         self.isLoadingCurrentData = NO;
                                                                         [self processSearchResults];
                                                                         
                                                                         [self reloadData];
                                                                     }];
                                                     
                                                 } errorHandler:^(NSError *error) {
                                                 }];
                         
         } errorHandler:^(NSError *error) {
         }];
     */
}

- (void)fadeUpPrompt {
    if (self.textField.text.length == 0 && ![self.textField isFirstResponder]) {
        self.promptContainer.alpha = 1;
        self.promptText.alpha = 1;
        self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    }
}

-(void)applicationDidBecomeActive:(id)sender {
    
    [self clearCachedResults];

}


#pragma mark - Actions

- (void)handleProfileImageTap:(id)sender {
    int tag = (int)[sender tag];
    Person * friend;
    
    if (self.currPeopleState == PeopleStateSearchResults) {
        SPCPeopleSearchResult *result = self.searchResults[tag];
        friend = result.person;
    }
    else {
        friend = self.rankedUsers[tag];
    }
   
    
    if (friend.recordID == -2) {
        [[[UIAlertView alloc] initWithTitle:nil message:@"Anonymous memories don't have a profile." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
    }
    
    else {
        if (self.currPeopleState >= PeopleStateSearchResults) {
            //add to recent searches
            SPCPeopleSearchResult *result = [[SPCPeopleSearchResult alloc] initWithPerson:friend];
            [self addSearchToRecentSearch:result];
        }
    
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:friend.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}


- (void)reloadData {

    //update header for currPeopleState
    
    self.spinner.alpha = 0;
    [self.spinner stopAnimating];
    
    if ((self.currPeopleState == PeopleStateCitySearchResults)) {
        
        if (self.isLoadingCurrentData) {
            //we have started a serach, but we're still be waiting for results - don't show a header yet
            self.headerView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 0);
            self.tableView.tableHeaderView = self.headerView;
            self.spinner.alpha = 1;
            [self.spinner startAnimating];

        }
        else {
            self.headerView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, self.headerHeight);
            UIImage *image = [UIImage imageNamed:@"city-header"];
            self.mapPreviewImg.image = image;
            self.overlayView.backgroundColor = [UIColor colorWithRed:106.0f/255.0f green:177.0f/255.0f blue:251.0f/255.0f alpha:0.7f];
            self.tableView.tableHeaderView = self.headerView;
        }
    }
    else if (self.currPeopleState == PeopleStateSearchResults){
            self.headerView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, 0);
            self.tableView.tableHeaderView = self.headerView;
    }

    self.collectionView.hidden = YES;
    self.tableView.hidden = NO;
    [self.tableView reloadData];
}


#pragma mark - Invite / Add Actions

- (void)inviteFriends:(id)sender {
    if ([self.delegate respondsToSelector:@selector(peopleViewControllerPerformPlaceholderAction:)]) {
        [self.delegate peopleViewControllerPerformPlaceholderAction:self];
    }
}

-(void)dismissHeader {
    [self reloadData];
}


#pragma mark - Keyboard

- (void)keyboardDidShowNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGRect kbRect = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize kbSize = [self.view convertRect:kbRect toView:nil].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame), 0.0, kbSize.height - CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0);
    

    
    [UIView animateWithDuration:0.3 animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
    }];
}

- (void)keyboardWillHideNotification:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(CGRectGetMaxY(self.textField.frame), 0.0, 0.0, 0.0);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

}


#pragma mark - Other notifications

-(void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    NSLog(@"applyPersonUpdateWithNotification");
    if (personUpdate) {
        BOOL changed = [personUpdate applyToArray:self.rankedUsers];
        changed = [personUpdate applyToArray:self.unrankedUsers] || changed;
        if (self.currentUser) {
            changed = [personUpdate applyToPerson:self.currentUser] || changed;
        }
        NSLog(@"applied to ranked users, unranked users, current user with changed %d", changed);
        if (changed && _tableView) {
            [self reloadData];
        }
    }
}

-(void)resetToDefault {
    if (self.currPeopleState != PeopleStateEmpty) {
        self.currPeopleState = PeopleStateEmpty;
    }
}




-(void)clearCachedResults {
    self.cachedRankedFriends = nil;
    self.cachedLocalResults = nil;
    self.cachedGlobalResults = nil;
    self.currLocalResult = nil;
    self.allCachedFriends = nil;
}

#pragma mark - Recent searches UI

-(void)clearSearch {
    self.currPeopleState = PeopleStateEmpty;
    
    self.cancelSearchBtn.hidden = NO;
    self.resetSearchBtn.hidden = YES;
    
    [self reloadData];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(-1 + CGRectGetMaxY(self.textField.frame),0,0,0);
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
}

-(void)resetSearch {
    self.textField.text = @"";
    self.promptContainer.alpha = 1;
    self.promptText.alpha = 1;
    self.searchIcon.image = [UIImage imageNamed:@"magnifying-glass-off"];
    [self clearSearch];
}

-(void)cancelSearch {

    //return to our previously selected state

    
    self.textField.text = @"";
    [self.textField resignFirstResponder];
    self.cancelSearchBtn.hidden = YES;
    self.resetSearchBtn.hidden = YES;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(40.0, 0.0, 0.0, 0.0);
    [self.tableView setContentInset:contentInsets];
    UIEdgeInsets scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    [self.tableView setScrollIndicatorInsets:scrollIndicatorInsets];
    
    [self fadeUpPrompt];
    [self reloadData];
}


# pragma mark - Prefetching profile asset photos


- (void)prefetchUserAssets:(NSArray *)users {
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:users.count];
    
    for (NSObject *obj in users) {
        if ([obj isKindOfClass:[Friend class]]) {
            Friend *friend = (Friend *)obj;
            if (friend.imageAsset && ![assets containsObject:friend.imageAsset]) {
                [assets addObject:friend.imageAsset];
            }
        } else if ([obj isKindOfClass:[Person class]]) {
            Person *person = (Person *)obj;
            if (person.imageAsset && ![assets containsObject:person.imageAsset]) {
                [assets addObject:person.imageAsset];
            }
        } else if ([obj isKindOfClass:[SPCPeopleSearchResult class]]) {
            SPCPeopleSearchResult *result = (SPCPeopleSearchResult *)obj;
            if (result.searchResultType == SearchResultCeleb || result.searchResultType == SearchResultFriend || result.searchResultType == SearchResultStranger) {
                
                Person *person = result.person;
                if (person.imageAsset && ![assets containsObject:person.imageAsset]) {
                    [assets addObject:person.imageAsset];
                }
            }
        }
    }
    
    NSMutableArray *mutArray = [NSMutableArray arrayWithArray:self.allUserAssets];
    for (Asset *asset in assets) {
        if (![self.prefetchedAssetIds containsObject:@(asset.assetID)]) {
            [mutArray addObject:asset];
        }
    }
    self.allUserAssets = [NSArray arrayWithArray:mutArray];
    
    if (!self.prefetchPaused && !self.prefetchInProgress) {
        [self prefetchNextAsset];
    }
}


- (void)prefetchNextAsset {
    //NSLog(@"prefetchNextAsset");
    if (self.prefetchPaused || self.prefetchInProgress) {
        return;
    }
    
    if (self.allUserAssets.count > 0) {
        self.prefetchInProgress = YES;
        NSMutableArray *mutArray = [NSMutableArray arrayWithArray:self.allUserAssets];
        Asset *asset = nil;
        NSURL *url = nil;
        while (!asset && mutArray.count > 0) {
            asset = mutArray[0];
            [mutArray removeObjectAtIndex:0];
            url = [NSURL URLWithString:[asset imageUrlThumbnail]];
            if ([self.prefetchedAssetIds containsObject:@(asset.assetID)]) {
                asset = nil;
            } else if ([[SDWebImageManager sharedManager] cachedImageExistsForURL:url]) {
                asset = nil;
            } else if ([[SDWebImageManager sharedManager] diskImageExistsForURL:url]) {
                asset = nil;
            }
        }
        
        self.allUserAssets = [NSArray arrayWithArray:mutArray];
        
        if (!asset || !url) {
            self.prefetchInProgress = NO;
            return;
        }
        
        //NSLog(@"prefetching asset %d", asset.assetID);
        
        // prefetch
        __weak typeof(self) weakSelf = self;
        [self.prefetchImageView sd_cancelCurrentImageLoad];
        [self.prefetchImageView sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf ) {
                return ;
            }
            
            NSMutableSet *mutSet = [NSMutableSet setWithSet:strongSelf.prefetchedAssetIds];
            [mutSet addObject:@(asset.assetID)];
            strongSelf.prefetchedAssetIds = [NSSet setWithSet:mutSet];
            
            strongSelf.prefetchInProgress = NO;
            [strongSelf prefetchNextAsset];
        }];
    }
}

#pragma mark - Helper methods

- (NSString *)commaPopulation:(NSInteger)popInteger {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterNoStyle];
    NSString *groupingSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleGroupingSeparator];
    [formatter setGroupingSeparator:groupingSeparator];
    [formatter setGroupingSize:3];
    [formatter setAlwaysShowsDecimalSeparator:NO];
    [formatter setUsesGroupingSeparator:YES];
    NSString *formattedString = [NSString stringWithFormat:@"%@ PEOPLE",[formatter stringFromNumber:[NSNumber numberWithInteger:popInteger]]];
    return formattedString;
}


#pragma mark - Resizing for Status Bar

- (void)handleStatusBarChange:(NSNotification*)notification {
    self.collectionView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetHeight(self.tabBarController.tabBar.frame));
    
}


@end
