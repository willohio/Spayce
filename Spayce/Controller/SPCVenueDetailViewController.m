//
//  SPCVenueDetailViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 9/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCVenueDetailViewController.h"

// Framework
#import "Flurry.h"

// Model
#import "SPCVenueDetailDataSource.h"
#import "SPCVenueTypes.h"
#import "Venue.h"
#import "Asset.h"

// View
#import "CoachMarks.h"
#import "SPCSolidButton.h"
#import "SPCVenueDetailHeaderView.h"
#import "SPCAlertAction.h"
#import "PXAlertView.h"
#import "SPCView.h"
#import "SPCReportAlertView.h"
#import "MemoryCell.h"

// Controller
#import "SPCCreateVenuePostViewController.h"
#import "SPCVenueHashTagsViewController.h"
#import "SPCAlertViewController.h"
#import "SPCReportViewController.h"
#import "SPCCustomNavigationController.h"

// Category
#import "NSString+SPCAdditions.h"
#import "UIColor+SPCAdditions.h"
#import "UIScrollView+SPCParallax.h"
#import "UIApplication+SPCAdditions.h"
#import "UIViewController+SPCAdditions.h"
#import "UIImageView+WebCache.h"
#import "UITableView+SPXRevealAdditions.h"

// General
#import "SPCLiterals.h"

// Manager
#import "MeetManager.h"
#import "AuthenticationManager.h"
#import "VenueManager.h"
#import "LocationContentManager.h"
#import "LocationManager.h"

// Utils
#import "SPCAlertTransitionAnimator.h"
#import "ImageUtils.h"
#import "GKImagePicker.h"
#import "APIUtils.h"
#import "SPCTerritory.h"


@interface SPCVenueDetailViewController () <SPCVenueHashTagsViewControllerDelegate, UIViewControllerTransitioningDelegate, SPCReportAlertViewDelegate, SPCReportViewControllerDelegate, UICollectionViewDelegate>

// Data
@property (nonatomic, strong) SPCVenueDetailDataSource *dataSource;
@property (nonatomic, strong) NSArray *venueHashTags;
@property (nonatomic, strong) NSString *selectedTag;
@property (nonatomic, assign) BOOL fetchInProgress;
@property (nonatomic, assign) BOOL didFetchMemories;
@property (nonatomic, assign) BOOL didConfigureWithFetchedMemories;
@property (nonatomic, strong) NSArray *reportVenueOptions;
@property (nonatomic, assign) SPCReportType reportType;

// Data - Automatic refresh
@property (nonatomic, assign) BOOL viewIsVisible;
@property (nonatomic, assign) BOOL viewIsFullyVisible;
@property (nonatomic, assign) BOOL viewHasLoaded;

// UI
@property (nonatomic, strong) UIView *statusBar;
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *navActionButton;
@property (nonatomic, strong) UIButton *navSearchHashtagsButton;
@property (nonatomic, strong) UIButton *navSearchHashtagsTextButton;
@property (nonatomic, strong) UILabel *navVenueLabel;
@property (nonatomic, strong) UILabel *navLocationLabel;
@property (nonatomic, strong) UIView *navOverBar;
@property (nonatomic, strong) UIButton *navOverActionButton;
@property (nonatomic, strong) UIButton *navOverSearchHashtagsButton;
@property (nonatomic, strong) UIButton *navOverSearchHashtagsTextButton;
@property (nonatomic, strong) UILabel *navOverVenueLabel;
@property (nonatomic, strong) UILabel *navOverLocationLabel;
@property (nonatomic, strong) UIButton *navOverScrollToTopButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) SPCMemoryGridCollectionView *memoryGridCollectionView;
@property (nonatomic, strong) UIColor *navBarContentColor;
@property (nonatomic, strong) UIColor *navOverBarContentColor;

// Navigation - Moving to MCVC from grid cell tap
@property (nonatomic, strong) UINavigationController *navFromGrid;
@property (nonatomic, strong) UIView *clippingView;
@property (nonatomic, strong) UIImageView *expandingImageView;
@property (nonatomic) CGRect expandingImageRect;
@property (nonatomic) BOOL expandingDidHideTabBar;

// UI - Header view
@property (nonatomic, strong) SPCVenueDetailHeaderView *headerView;
@property (nonatomic, strong) UIImage *headerImage;
@property (nonatomic, assign) CGFloat tableHeaderViewHeight;

// UI - alert
@property (nonatomic, strong) PXAlertView *alertView;
@property (nonatomic, strong) SPCReportAlertView *reportAlertView;

// Updating images
@property (nonatomic, strong) GKImagePicker *imagePicker;

// Prefetch banner image
@property (nonatomic, strong) UIImageView *prefetchImageView;


@end

@implementation SPCVenueDetailViewController {
  NSInteger alertViewTagReport;
}

#pragma mark - Object lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // Cancel any previous requests that were set to execute on a delay!!
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:_tableView];
    
    if (_memoryGridCollectionView) {
        _memoryGridCollectionView = nil;
    }
    
    @try {
        [_dataSource removeObserver:self forKeyPath:@"draggingScrollView"];
    } @catch (NSException *exception) {}
    
    if (_tableView) {
        [_tableView removeParallaxView];
    }
}

#pragma mark - View's lifecycle

- (void)loadView {
    [super loadView];
    self.tableHeaderViewHeight = 250;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    /*
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        self.tableHeaderViewHeight = 215;
    }
    
    //5"
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        self.tableHeaderViewHeight = 215;
    }
     */
    
    
    [self.view addSubview:self.statusBar];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.statusBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.statusBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.statusBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.statusBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)]];
    
    [self.view insertSubview:self.tableView belowSubview:self.statusBar];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
    
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.navOverBar];
    
    self.viewIsVisible = NO;
    self.viewIsFullyVisible = NO;
    self.viewHasLoaded = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:SPCReloadForFilters object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_addMemoryLocally:) name:@"addMemoryLocally" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFailedToLoad) name:@"videoLoadFailed" object:nil];
    
    [self configureVenueDetail];
    [self configureDataSource];
    [self configureTableView];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    
    [self fetchMemories];
    
    alertViewTagReport = 100;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
    
    self.dataSource.prefetchPaused = NO;
    self.viewIsVisible = YES;
    
    [self.memoryGridCollectionView viewWillAppear];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.viewIsFullyVisible = YES;
    [self scrollViewDidScroll:self.tableView travel:0 continuousTravel:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.dataSource.prefetchPaused = YES;
    self.viewIsVisible = NO;
    self.viewIsFullyVisible = NO;
    
    [self.memoryGridCollectionView viewWillDisappear];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Configuring the View’s Layout Behavior

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Accessors

- (SPCVenueDetailDataSource *)dataSource {
    if (!_dataSource) {
        _dataSource = [[SPCVenueDetailDataSource alloc] init];
        _dataSource.tableViewWidth = CGRectGetWidth(self.view.frame);
        _dataSource.memoryGridCollectionView = self.memoryGridCollectionView;
        _dataSource.venue = self.venue;
        _dataSource.delegate = self;
    }
    return _dataSource;
}

- (UIView *)statusBar {
    if (!_statusBar) {
        _statusBar = [[UIView alloc] init];
        _statusBar.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:0.9f];
        _statusBar.translatesAutoresizingMaskIntoConstraints = NO;
        _statusBar.hidden = YES;
    }
    return _statusBar;
}

- (UIColor *)navBarContentColor {
    if (!_navBarContentColor) {
        _navBarContentColor = [UIColor whiteColor];
    }
    return _navBarContentColor;
}

- (UIColor *)navOverBarContentColor {
    if (!_navOverBarContentColor) {
        _navOverBarContentColor = [UIColor colorWithRGBHex:0x4cb0fb];
    }
    return _navOverBarContentColor;
}



- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 50)];
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        UIImage *baseImage = [UIImage imageNamed:@"button-back-arrow-white"];
        UIImage *image = [baseImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [backButton setImage:image forState:UIControlStateNormal];
        backButton.tintColor = self.navBarContentColor;
        [backButton addTarget:self action:@selector(dismissViewController:) forControlEvents:UIControlEventTouchUpInside];
        
        [_navBar addSubview:backButton];
        [_navBar addSubview:self.navActionButton];
        [_navBar addSubview:self.navVenueLabel];
        [_navBar addSubview:self.navLocationLabel];
        [_navBar addSubview:self.navSearchHashtagsButton];
        [_navBar addSubview:self.navSearchHashtagsTextButton];
    }
    return _navBar;
}


- (UIButton *)navSearchHashtagsButton {
    if (!_navSearchHashtagsButton) {
        _navSearchHashtagsButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-CGRectGetWidth(self.navActionButton.frame) - 35, 0.0, 35, 50.0)];
        UIImage *imageBase = [UIImage imageNamed:@"button-action-search"];
        UIImage *image = [imageBase imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_navSearchHashtagsButton setImage:image forState:UIControlStateNormal];
        [_navSearchHashtagsButton setImage:image forState:UIControlStateSelected];
        [_navSearchHashtagsButton setImage:image forState:UIControlStateHighlighted];
        _navSearchHashtagsButton.tintColor = self.navBarContentColor;
        
        _navSearchHashtagsButton.backgroundColor = [UIColor redColor];
        
        _navSearchHashtagsButton.backgroundColor = [UIColor clearColor];
        [_navSearchHashtagsButton addTarget:self action:@selector(searchHashTags) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navSearchHashtagsButton;
}

- (UIButton *)navSearchHashtagsTextButton {
    if (!_navSearchHashtagsTextButton) {
        CGFloat margin = CGRectGetWidth(self.view.frame) - CGRectGetMinX(self.navSearchHashtagsButton.frame);
        _navSearchHashtagsTextButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, 0, CGRectGetWidth(self.view.frame) - margin*2, 50)];
        [_navSearchHashtagsTextButton.titleLabel setFont:[UIFont spc_mediumSystemFontOfSize:14]];
        _navSearchHashtagsTextButton.backgroundColor = [UIColor clearColor];
        [_navSearchHashtagsTextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_navSearchHashtagsTextButton addTarget:self action:@selector(searchHashTags) forControlEvents:UIControlEventTouchUpInside];
        _navSearchHashtagsTextButton.enabled = NO;
    }
    return _navSearchHashtagsTextButton;
}

- (UIButton *)navActionButton {
    if (!_navActionButton) {
        _navActionButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 50.0, 0, 50.0, 50.0)];
        UIImage *baseImage = [UIImage imageNamed:@"button-action-vertical-white"];
        UIImage *image = [baseImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_navActionButton setImage:image forState:UIControlStateNormal];
        _navActionButton.tintColor = self.navBarContentColor;
        [_navActionButton addTarget:self action:@selector(showVenueActions:) forControlEvents:UIControlEventTouchUpInside];
        _navActionButton.contentMode = UIViewContentModeCenter;
    }
    return _navActionButton;
}

- (UILabel *)navVenueLabel {
    if (!_navVenueLabel) {
        CGFloat rightMargin = CGRectGetMinX(self.navSearchHashtagsButton.frame);
        _navVenueLabel = [[UILabel alloc] init];
        _navVenueLabel.font = [UIFont spc_boldSystemFontOfSize:19];
        _navVenueLabel.textColor = [UIColor whiteColor];
        _navVenueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _navVenueLabel.textAlignment = NSTextAlignmentCenter;
        _navVenueLabel.frame = CGRectMake(rightMargin, 4, CGRectGetWidth(self.view.frame) - rightMargin*2, _navVenueLabel.font.lineHeight);
        _navVenueLabel.alpha = 1;
    }
    return _navVenueLabel;
}

- (UILabel *)navLocationLabel {
    if (!_navLocationLabel) {
        CGFloat rightMargin = CGRectGetMinX(self.navSearchHashtagsButton.frame);
        _navLocationLabel = [[UILabel alloc] init];
        _navLocationLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _navLocationLabel.textColor = [UIColor colorWithRGBHex:0xdcdbdb];
        _navLocationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _navLocationLabel.textAlignment = NSTextAlignmentCenter;
        _navLocationLabel.frame = CGRectMake(rightMargin, CGRectGetMaxY(self.navVenueLabel.frame)-2, CGRectGetWidth(self.view.frame) - rightMargin*2, _navLocationLabel.font.lineHeight);
        _navLocationLabel.alpha = 1;
    }
    return _navLocationLabel;
}

// Overlay (white background)

- (UIView *)navOverBar {
    if (!_navOverBar) {
        _navOverBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 50)];
        _navOverBar.backgroundColor = [UIColor whiteColor];
        _navOverBar.alpha = 0;
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        UIImage *baseImage = [UIImage imageNamed:@"button-back-arrow-white"];
        UIImage *image = [baseImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [backButton setImage:image forState:UIControlStateNormal];
        backButton.tintColor = self.navOverBarContentColor;
        [backButton addTarget:self action:@selector(dismissViewController:) forControlEvents:UIControlEventTouchUpInside];
        
        [_navOverBar addSubview:backButton];
        [_navOverBar addSubview:self.navOverActionButton];
        [_navOverBar addSubview:self.navOverVenueLabel];
        [_navOverBar addSubview:self.navOverLocationLabel];
        [_navOverBar addSubview:self.navOverSearchHashtagsButton];
        [_navOverBar addSubview:self.navOverSearchHashtagsTextButton];
        [_navOverBar addSubview:self.navOverScrollToTopButton];
    }
    return _navOverBar;
}


- (UIButton *)navOverSearchHashtagsButton {
    if (!_navOverSearchHashtagsButton) {
        _navOverSearchHashtagsButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame)-CGRectGetWidth(self.navOverActionButton.frame) - 35, 0.0, 35, 50.0)];
        UIImage *imageBase = [UIImage imageNamed:@"button-action-search"];
        UIImage *image = [imageBase imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_navOverSearchHashtagsButton setImage:image forState:UIControlStateNormal];
        [_navOverSearchHashtagsButton setImage:image forState:UIControlStateSelected];
        [_navOverSearchHashtagsButton setImage:image forState:UIControlStateHighlighted];
        _navOverSearchHashtagsButton.tintColor = self.navOverBarContentColor;
        
        _navOverSearchHashtagsButton.backgroundColor = [UIColor redColor];
        
        _navOverSearchHashtagsButton.backgroundColor = [UIColor clearColor];
        [_navOverSearchHashtagsButton addTarget:self action:@selector(searchHashTags) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navOverSearchHashtagsButton;
}

- (UIButton *)navOverSearchHashtagsTextButton {
    if (!_navOverSearchHashtagsTextButton) {
        CGFloat margin = CGRectGetWidth(self.view.frame) - CGRectGetMinX(self.navOverSearchHashtagsButton.frame);
        _navOverSearchHashtagsTextButton = [[UIButton alloc] initWithFrame:CGRectMake(margin, 0, CGRectGetWidth(self.view.frame) - margin*2, 50)];
        [_navOverSearchHashtagsTextButton.titleLabel setFont:[UIFont spc_mediumSystemFontOfSize:14]];
        _navOverSearchHashtagsTextButton.backgroundColor = [UIColor clearColor];
        [_navOverSearchHashtagsTextButton setTitleColor:[UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_navOverSearchHashtagsTextButton addTarget:self action:@selector(searchHashTags) forControlEvents:UIControlEventTouchUpInside];
        _navOverSearchHashtagsTextButton.enabled = NO;
    }
    return _navOverSearchHashtagsTextButton;
}

- (UIButton *)navOverActionButton {
    if (!_navOverActionButton) {
        _navOverActionButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.frame) - 50.0, 0, 50.0, 50.0)];
        UIImage *baseImage = [UIImage imageNamed:@"button-action-vertical-white"];
        UIImage *image = [baseImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_navOverActionButton setImage:image forState:UIControlStateNormal];
        _navOverActionButton.tintColor = self.navOverBarContentColor;
        [_navOverActionButton addTarget:self action:@selector(showVenueActions:) forControlEvents:UIControlEventTouchUpInside];
        _navOverActionButton.contentMode = UIViewContentModeCenter;
    }
    return _navOverActionButton;
}

- (UILabel *)navOverVenueLabel {
    if (!_navOverVenueLabel) {
        CGFloat rightMargin = CGRectGetMinX(self.navSearchHashtagsButton.frame);
        _navOverVenueLabel = [[UILabel alloc] init];
        _navOverVenueLabel.font = [UIFont spc_boldSystemFontOfSize:19];
        _navOverVenueLabel.textColor = [UIColor colorWithRGBHex:0x333333];
        _navOverVenueLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _navOverVenueLabel.textAlignment = NSTextAlignmentCenter;
        _navOverVenueLabel.frame = CGRectMake(rightMargin, 4, CGRectGetWidth(self.view.frame) - rightMargin*2, _navOverVenueLabel.font.lineHeight);
        _navOverVenueLabel.alpha = 1;
    }
    return _navOverVenueLabel;
}

- (UILabel *)navOverLocationLabel {
    if (!_navOverLocationLabel) {
        CGFloat rightMargin = CGRectGetMinX(self.navSearchHashtagsButton.frame);
        _navOverLocationLabel = [[UILabel alloc] init];
        _navOverLocationLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _navOverLocationLabel.textColor = [UIColor colorWithRGBHex:0xdcdbdb];
        _navOverLocationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _navOverLocationLabel.textAlignment = NSTextAlignmentCenter;
        _navOverLocationLabel.frame = CGRectMake(rightMargin, CGRectGetMaxY(self.navOverVenueLabel.frame)-2, CGRectGetWidth(self.view.frame) - rightMargin*2, _navOverLocationLabel.font.lineHeight);
        _navOverLocationLabel.alpha = 1;
    }
    return _navOverLocationLabel;
}


- (UIButton *)navOverScrollToTopButton {
    if (!_navOverScrollToTopButton) {
        CGFloat rightMargin = CGRectGetMinX(self.navOverSearchHashtagsButton.frame);
        _navOverScrollToTopButton = [[UIButton alloc] initWithFrame:CGRectMake(rightMargin, 0, CGRectGetWidth(self.view.frame) - rightMargin*2, 50)];
        [_navOverScrollToTopButton addTarget:self action:@selector(scrollToTop) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navOverScrollToTopButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0f];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.dataSource = self.dataSource;
        _tableView.delegate = self.dataSource;
        _tableView.showsVerticalScrollIndicator = YES;
    }
    return _tableView;
}


- (SPCMemoryGridCollectionView *)memoryGridCollectionView {
    if (nil == _memoryGridCollectionView) {
        SPCMemoryGridCollectionViewLayout *layout = [[SPCMemoryGridCollectionViewLayout alloc] init];
        _memoryGridCollectionView = [[SPCMemoryGridCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _memoryGridCollectionView.scrollEnabled = NO;
        _memoryGridCollectionView.backgroundColor = [UIColor clearColor];
        _memoryGridCollectionView.delegate = self;
        _memoryGridCollectionView.tableViewWidth = CGRectGetWidth(self.view.frame);
    }
    
    return _memoryGridCollectionView;
}

- (SPCVenueDetailHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[SPCVenueDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), self.tableHeaderViewHeight) venue:self.venue];
    }
    return _headerView;
}

-(UIImage *)headerImage {
    
    return [UIImage imageNamed:@"fuzzy-banner"];
}


- (UIImageView *)prefetchImageView {
    if (!_prefetchImageView) {
        _prefetchImageView = [[UIImageView alloc] init];
    }
    return _prefetchImageView;
}

- (NSArray *)reportVenueOptions {
    if (nil == _reportVenueOptions) {
        _reportVenueOptions = @[@"ABUSE", @"SPAM", @"PERTAINS TO ME", @"DOESN'T EXIST"];
    }
    
    return _reportVenueOptions;
}

- (UIImageView *)expandingImageView {
    if (!_expandingImageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        imageView.hidden = YES;
        _expandingImageView = imageView;
    }
    return _expandingImageView;
}

- (UIView *)clippingView {
    if (!_clippingView) {
        _clippingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    }
    return _clippingView;
}


#pragma mark - Mutators

- (void)setVenue:(Venue *)venue {
    _venue = venue;
    if (_dataSource) {
        _dataSource.venue = venue;
    }
}


#pragma mark - Private


- (void)configureVenueDetail {
    if (self.venue) {
        NSString *venueLabel = self.venue.displayNameTitle;
        NSString *locationLabel = nil;
        if (self.venue.city && self.venue.state) {
            locationLabel = [NSString stringWithFormat:@"%@, %@",[SPCTerritory fixCityName:self.venue.city stateCode:self.venue.state countryCode:self.venue.country],self.venue.state];
        }
        else if (self.venue.city && self.venue.country) {
            locationLabel = [NSString stringWithFormat:@"%@, %@",[SPCTerritory fixCityName:self.venue.city stateCode:self.venue.state countryCode:self.venue.country],self.venue.country];
        }
        else {
            locationLabel = self.venue.country;
        }
        if (self.venue.specificity == SPCVenueIsReal) {
            self.headerView.venueImageView.image = [SPCVenueTypes imageForVenue:self.venue withIconType:VenueIconTypeIconNewColorLarge];
        }
        else {
            if (self.venue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                venueLabel = self.venue.neighborhood;
            }
            if (self.venue.specificity == SPCVenueIsFuzzedToCity) {
                venueLabel = [SPCTerritory fixCityName:self.venue.city stateCode:self.venue.state countryCode:self.venue.country];
            }
            self.headerView.venueImageView.hidden = YES;
            self.headerView.distanceLabel.hidden = YES;
            
        }
        
        self.navVenueLabel.text = self.navOverVenueLabel.text =  venueLabel;
        self.navLocationLabel.text = self.navOverLocationLabel.text = locationLabel;
            
        if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
            self.headerView.distanceLabel.text = [NSString stringInTruncatedFeetOrMilesFromDistance:self.venue.distanceAway];
        } else {
            self.headerView.distanceLabel.text = @"   ";
        }
    }
}

- (void)configureDataSource {
    self.dataSource.navigationController = self.navigationController;
    
    self.dataSource.isWithinMAMDistance = NO;
}

- (void)configureTableView {
    // Set bottom inset to accomodate memory button
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    // Add table header and footer
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), self.tableHeaderViewHeight)];
    self.tableView.tableHeaderView.userInteractionEnabled = NO;
    
    // Add parallax header
    if (self.venue.bannerAsset) {
        [self.tableView addParallaxViewWithImageUrl:[NSURL URLWithString:self.venue.bannerAsset.imageUrlDefault] overlayColor:[UIColor colorWithRGBHex:0x000000 alpha:0.3] contentView:self.headerView bottomView:self.headerView.venueMapView flushWithBottom:YES];
    } else {
        [self.tableView addParallaxViewWithImage:nil overlayColor:[UIColor colorWithRGBHex:0x4cb0fb] contentView:self.headerView bottomView:self.headerView.venueMapView flushWithBottom:YES];
    }
    
    // Reusable cells
    [self.tableView registerClass:[SPCVenueSegmentedControlCell class] forCellReuseIdentifier:SPCVenueSegmentedControlCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCFeedCellIdentifier];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:SPCLoadMoreDataCellIdentifier];
}

#pragma mark - Private

- (void)fetchMemories {
    //NSLog(@"fetchMemories");
    if (self.fetchInProgress) {
        //NSLog(@"fetchInProgress -- cancelling");
        return;
    }
    
    if (!self.didFetchMemories) {
        NSLog(@"fetching memories...");
        self.fetchInProgress = YES;
        __weak typeof(self)weakSelf = self;
        [MeetManager fetchLocationMemoriesFeedForVenue:self.venue
                                includeFeaturedContent:NO
                                 withCompletionHandler:^(NSArray *memories, NSArray *featuredContent,NSArray *venueHashTags) {
                                     
                                     NSLog(@"fetched memories");
                                     
                                     __strong typeof(weakSelf)strongSelf = weakSelf;
                                     if (!strongSelf) {
                                         return;
                                     }
                                     
                                     strongSelf.didFetchMemories = YES;
                                     strongSelf.fetchInProgress = NO;
                                         
                                     strongSelf.dataSource.fullFeed = memories;
                                     strongSelf.dataSource.feed = memories;
                                     
                                     strongSelf.dataSource.hasLoaded = YES;
                                     
                                     strongSelf.venueHashTags = venueHashTags;
                                     
                                     if (strongSelf.viewHasLoaded) {
                                         //NSLog(@"configuring with fetched memories...");
                                         [strongSelf configureForFetchedMemories];
                                     } else {
                                         [strongSelf prefetchBannerWithMostPopularImage];
                                     }
                                     
                                 } errorHandler:^(NSError *error) {
                                     __strong typeof(weakSelf)strongSelf = weakSelf;
                                     if (!strongSelf) {
                                         return;
                                     }
                                     
                                     strongSelf.fetchInProgress = NO;
                                 }];
    } else if (!self.didConfigureWithFetchedMemories && self.viewHasLoaded) {
        //NSLog(@"configuring previously fetched memories...");
        [self configureForFetchedMemories];
    }
}

- (void)fetchMoreMemories {
    
}

- (void)configureForFetchedMemories {
    [self updateBannerWithMostPopularImage];
    [self.tableView reloadData];
    
    self.didConfigureWithFetchedMemories = YES;
}



-(void)videoFailedToLoad {
    if (self.viewIsVisible) {
        [self  spc_hideNotificationBanner];
        [self spc_showNotificationBannerInParentView:self.view title:NSLocalizedString(@"Video failed to load", nil) customText:NSLocalizedString(@"Please check your network and try again.",nil)];
    }
}

-(NSString *)bannerUrlString {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.dataSource.fullFeed];
    NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starsCount" ascending:NO];
    [tempArray sortUsingDescriptors:@[starSorter]];
    
    NSString *imageUrlStr;
    
    for (int i = 0; i < tempArray.count; i ++) {
        
        ImageMemory *tempMem = tempArray[i];
        
        if (tempMem.type == MemoryTypeImage) {
            
            //set image url & placeholder
            id imageAsset = tempMem.images[0];
            if ([imageAsset isKindOfClass:[Asset class]]) {
                Asset * asset = (Asset *)imageAsset;
                imageUrlStr = [asset imageUrlDefault];
            } else {
                NSString *imageName = [NSString stringWithFormat:@"%@", tempMem.images[0]];
                int photoID = [imageName intValue];
                imageUrlStr = [APIUtils imageUrlStringForAssetId:photoID size:ImageCacheSizeDefault];
            }
            break;
        }
    }
    
    return imageUrlStr;
}

-(void)prefetchBannerWithMostPopularImage {
    //NSLog(@"prefetchBannerWithMostPopularImage");
    NSString *imageUrlString = [self bannerUrlString];
    [self.prefetchImageView sd_setImageWithURL:[NSURL URLWithString:imageUrlString] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        //NSLog(@"prefetch complete");
        self.prefetchImageView.image = nil;
    }];
}

-(void)updateBannerWithMostPopularImage {
    //NSLog(@"updateBannerWithMostPopularImage");
    NSString *imageUrlString = [self bannerUrlString];
    [self.tableView updateParallaxViewWithImageUrl:[NSURL URLWithString:imageUrlString] overlayColor:[UIColor colorWithWhite:0 alpha:0.3]];
}


#pragma mark - Data source delegate


- (void)scrollViewDidScroll:(UIScrollView *)scrollView travel:(CGFloat)travel continuousTravel:(CGFloat)continuousTravel {
    if (!self.viewIsFullyVisible) {
        return;
    }
    
    // main nav bar scrolls offscreen
    CGFloat navBarTop = MIN(0, -self.tableView.contentOffset.y);
    CGRect frame = self.navBar.frame;
    frame.origin.y = navBarTop;
    self.navBar.frame = frame;
    
    CGFloat transitionMinOffset = CGRectGetMinY(self.headerView.venueMapView.frame) - CGRectGetHeight(self.navOverBar.frame);
    CGFloat transitionMaxOffset = CGRectGetMaxY(self.headerView.venueMapView.frame) - CGRectGetHeight(self.navOverBar.frame);
    CGFloat offset = self.tableView.contentOffset.y + self.tableView.contentInset.top;
    
    CGFloat overAlpha;
    if (offset < transitionMinOffset) {
        overAlpha = 0;
    } else if (offset > transitionMaxOffset) {
        overAlpha = 1;
    } else {
        overAlpha = 1 - (transitionMaxOffset - offset)/(transitionMaxOffset - transitionMinOffset);
    }
    CGFloat navWhiteAlpha = overAlpha;
    //NSLog(@"navWhiteAlpha %f: offset %f, inset %f", overAlpha, self.tableView.contentOffset.y, self.tableView.contentInset.top);
    
    self.navOverBar.alpha = navWhiteAlpha;
    self.navOverBar.userInteractionEnabled = navWhiteAlpha > 0;
}


#pragma mark - SPCProfileSegmentedControlCellDelegate

- (void)tappedMemoryCellDisplayType:(MemoryCellDisplayType)type onVenueSegmentedControl:(SPCVenueSegmentedControlCell *)venueSegmentedControl {
    
    // Reload 1st section if it's available
    if (1 <= self.tableView.numberOfSections) {
        self.dataSource.memoryCellDisplayType = venueSegmentedControl.memoryCellDisplayType;
        
        //[self showLoaderAnimationWithLoader:self.memoriesLoader];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        //[self hideLoaderAnimationWithLoader:self.memoriesLoader];
    }
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([collectionView isEqual:self.memoryGridCollectionView]&& indexPath.row < self.memoryGridCollectionView.memories.count) {
        Memory *m = [self.memoryGridCollectionView.memories objectAtIndex:indexPath.row];
        
        if (nil != m) {
            UIImage *image = nil;
            if (MemoryTypeImage == m.type || MemoryTypeVideo == m.type) {
                UICollectionViewCell *cellTapped = [collectionView cellForItemAtIndexPath:indexPath];
                UIGraphicsBeginImageContextWithOptions(cellTapped.contentView.bounds.size, cellTapped.contentView.opaque, 0.0f);
                [cellTapped.contentView.layer renderInContext:UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            NSLog(@"memory image %@", image);
            
            // clip rect?
            CGRect maskRect = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
            
            // Create a mask layer
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            
            // Create a path with our clip rect in it
            CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
            maskLayer.path = path;
            
            // The path is not covered by ARC
            CGPathRelease(path);
            
            self.clippingView.layer.mask = maskLayer;
            
            BOOL hasImage = image != nil;
            
            UICollectionViewLayoutAttributes *attributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
            CGRect cellRect = attributes.frame;
            CGRect cellFrameInTableView = [collectionView convertRect:cellRect toView:self.tableView];
            CGRect rect = [self.tableView convertRect:cellFrameInTableView toView:self.view];
            
            self.expandingImageView.image = image;
            self.expandingImageView.frame = rect;
            
            self.expandingImageView.hidden = !hasImage;
            
            self.expandingImageRect = rect;
            
            // Create the mcvc
            MemoryCommentsViewController *mcvc = [[MemoryCommentsViewController alloc] initWithMemory:m];
            mcvc.viewingFromVenueDetail = YES;
            mcvc.gridCellImage = image;
            mcvc.animateTransition = NO;
            
            self.navFromGrid = [[SPCCustomNavigationController alloc] initWithRootViewController:mcvc];
            
            // Get the memory's new center
            CGSize constraint = CGSizeMake([UIScreen mainScreen].bounds.size.width, CGFLOAT_MAX);
            CGFloat newTop = [MemoryCell measureMainContentOffsetWithMemory:m constrainedToSize:constraint] + mcvc.tableStart;
            CGRect newFrame = hasImage ? CGRectMake(0, newTop, CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame)) : CGRectZero;
            
            // Animate in the MCVC (alpha 0 -> 1), while shifting the montage view to its new center (while above the MCVC)
            self.navFromGrid.view.alpha = 0.0f;
            [self addChildViewController:self.navFromGrid];
            [self.view addSubview:self.navFromGrid.view];
            [self.view addSubview:self.clippingView];
            [self.view addSubview:self.expandingImageView];
            
            NSTimeInterval timeToTravelDistance = 0;
            if (hasImage) {
                CGFloat xDist = CGRectGetMidX(rect) - CGRectGetMidX(newFrame);
                CGFloat yDist = CGRectGetMidY(rect) - CGRectGetMidY(newFrame);
                timeToTravelDistance = 0.0015f * sqrt(xDist * xDist + yDist * yDist);
            }
            NSTimeInterval minTime = 0.3;
            NSTimeInterval travelTime = MAX(minTime, timeToTravelDistance);
            [UIView animateWithDuration:travelTime animations:^{
                // Adjust the frame
                self.expandingImageView.frame = newFrame;
            }];
            [UIView animateWithDuration:travelTime delay:0.12 options:0 animations:^{
                self.navFromGrid.view.alpha = 1.0f;
            } completion:^(BOOL finished) {
                if (finished) {
                    // Our hack to make the back button usable on the MCVC
                    [mcvc.backButton addTarget:self action:@selector(returnToGridFromNav) forControlEvents:UIControlEventTouchUpInside];
                    
                    [self setNeedsStatusBarAppearanceUpdate];
                    
                    // Send the images behind the MCVC
                    [self.view insertSubview:self.clippingView belowSubview:self.navFromGrid.view];
                    [self.view insertSubview:self.expandingImageView belowSubview:self.navFromGrid.view];
                }
            }];
        }
    }
}


- (void)returnToGridFromNav {
    [self setNeedsStatusBarAppearanceUpdate];
    UINavigationController *nav = self.navFromGrid;
    self.navFromGrid = nil;
    if (nil != nav.parentViewController) {
        BOOL hasImage = !self.expandingImageView.hidden;
        NSTimeInterval timeToTravelDistance = 0;
        if (hasImage) {
            CGFloat xDist = CGRectGetMidX(self.expandingImageView.frame) - CGRectGetMidX(self.expandingImageRect);
            CGFloat yDist = CGRectGetMidY(self.expandingImageView.frame) - CGRectGetMidY(self.expandingImageRect);
            timeToTravelDistance = 0.0015f * sqrt(xDist * xDist + yDist * yDist);
        }
        NSTimeInterval minTime = 0.3;
        NSTimeInterval travelTime = MAX(minTime, timeToTravelDistance);
        [UIView animateWithDuration:(travelTime) animations:^{
            nav.view.alpha = 0.0f;
            self.expandingImageView.frame = self.expandingImageRect;
        } completion:^(BOOL finished) {
            [nav.view removeFromSuperview];
            [nav removeFromParentViewController];
            for (UIViewController *viewController in nav.childViewControllers) {
                if ([viewController isKindOfClass:[MemoryCommentsViewController class]]) {
                    NSLog(@"clean up comments so it will dealloc??");
                    MemoryCommentsViewController *memCVC = (MemoryCommentsViewController *)viewController;
                    memCVC.gridCellImage = nil;
                    memCVC.backgroundImage = nil;
                    memCVC.exitBackgroundImage = nil;
                    [memCVC removeKeyControl];
                    [memCVC cleanUp];
                }
            }
            
            [self.expandingImageView removeFromSuperview];
            [self.clippingView removeFromSuperview];
            [self cleanUpNavAnimation];
            
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else {
        [nav dismissViewControllerAnimated:YES completion:^{
            [self cleanUpNavAnimation];
        }];
        [self.expandingImageView removeFromSuperview];
        [self.clippingView removeFromSuperview];
    }
}

-(void)cleanUpNavAnimation {
    
    for (UIViewController *viewController in self.navFromGrid.childViewControllers) {
        [viewController removeFromParentViewController];
        [viewController.view removeFromSuperview];
    }
    
    self.navFromGrid = nil;
}



#pragma mark - SPCVenueHashTagsViewController delegate

- (void)showMemoriesForHashTag:(NSString *)hashTag {
 
    self.selectedTag = hashTag;
    
    if (hashTag && hashTag.length > 0) {
        [_navSearchHashtagsTextButton setTitle:[NSString stringWithFormat:@"#%@", hashTag] forState:UIControlStateNormal];
        [_navOverSearchHashtagsTextButton setTitle:[NSString stringWithFormat:@"#%@", hashTag] forState:UIControlStateNormal];
        _navSearchHashtagsTextButton.enabled = _navOverSearchHashtagsTextButton.enabled = YES;
        _navOverScrollToTopButton.enabled = NO;
        _navVenueLabel.hidden = _navOverVenueLabel.hidden = YES;
        _navLocationLabel.hidden = _navOverLocationLabel.hidden = YES;
        self.dataSource.hashTagFilter = hashTag;
        [self.tableView reloadData];
        
        // make sure the tile height gets adjusted
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
    } else {
        [_navSearchHashtagsTextButton setTitle:nil forState:UIControlStateNormal];
        [_navOverSearchHashtagsTextButton setTitle:nil forState:UIControlStateNormal];
        _navSearchHashtagsTextButton.enabled = _navOverSearchHashtagsTextButton.enabled = NO;
        _navOverScrollToTopButton.enabled = YES;
        _navVenueLabel.hidden = _navOverVenueLabel.hidden = NO;
        _navLocationLabel.hidden = _navOverLocationLabel.hidden = NO;
        self.dataSource.hashTagFilter = nil;
        [self.tableView reloadData];
        
        // make sure the tile height gets adjusted
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
    }
    
}

#pragma mark - Actions

- (void)scrollToTop {
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}


- (void)dismissViewController:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; //stop any video playback currently in progress
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(spcVenueDetailViewControllerDidFinish:)]) {
        [self.delegate spcVenueDetailViewControllerDidFinish:self];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)showVenueActions:(id)sender {
    if (!self.venue) {
        return;
    }
    [Flurry logEvent:@"VENUE_ACTIONS_TAPPED"];
    
    NSLog(@"show venue actions");
    
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    // Alert view controller - title
    alertViewController.alertTitle = self.venue.displayNameTitle;
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Upload Banner Photo", nil)
                                                          subtitle:NSLocalizedString(@"If your photo is selected you earn 10 stars", nil)
                                                             style:SPCAlertActionStyleNormal
                                                           handler:^(SPCAlertAction *action) {
                                                               [self showBannerActions:self];
                                                           }]];
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Report or Correct", nil)
                                                          subtitle:NSLocalizedString(@"Report abuse or correct venue detail mistakes", nil)
                                                             style:SPCAlertActionStyleNormal
                                                           handler:^(SPCAlertAction *action) {
                                                               [self showReportPromptForVenue];
                                                           }]];
    
    if (self.venue.favorited) {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Unfavorite", nil)
                                                              subtitle:NSLocalizedString(@"Remove this venue from your profile", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self setFavorite:NO];
                                                               }]];
    } else {
        [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Favorite", nil)
                                                              subtitle:NSLocalizedString(@"This venue will show up on your profile", nil)
                                                                 style:SPCAlertActionStyleNormal
                                                               handler:^(SPCAlertAction *action) {
                                                                   [self setFavorite:YES];
                                                               }]];
    }
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self presentViewController:alertViewController animated:YES completion:nil];
}


- (void)showBannerActions:(id)sender {
    if (!self.venue) {
        return;
    }
    [Flurry logEvent:@"VENUE_UPLOAD_BANNER_TAPPED"];
    // Alert view controller
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    
    alertViewController.alertTitle = NSLocalizedString(@"Upload Banner", nil);
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Take Photo", nil)
                                                             style:SPCAlertActionStyleNormal
                                                           handler:^(SPCAlertAction *action) {
                                                               NSLog(@"Take Photo");
                                                               self.imagePicker = [[GKImagePicker alloc] initWithType:1];
                                                               CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
                                                               self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension * 0.81);
                                                               self.imagePicker.delegate = (id)self;
                                                               self.imagePicker.showCircleMask = NO;
                                                               self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                                                               self.imagePicker.imagePickerController.view.tag = 0;
                                                               if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) {
                                                                   self.imagePicker.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
                                                               }
                                                               [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
                                                           }]];
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Choose Existing", nil)
                                                             style:SPCAlertActionStyleNormal
                                                           handler:^(SPCAlertAction *action) {
                                                               NSLog(@"Choose Existing");
                                                               self.imagePicker = [[GKImagePicker alloc] initWithType:0];
                                                               CGFloat cropDimension = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
                                                               self.imagePicker.cropSize = CGSizeMake(cropDimension, cropDimension * 0.81);
                                                               self.imagePicker.showCircleMask = NO;
                                                               self.imagePicker.delegate = (id)self;
                                                               self.imagePicker.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                                                               self.imagePicker.imagePickerController.view.tag = 1;
                                                               [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
                                                           }]];
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                             style:SPCAlertActionStyleCancel
                                                           handler:nil]];
    
    // Alert view controller - show
    [self presentViewController:alertViewController animated:YES completion:nil];
}


- (void)setFavorite:(BOOL)favorite {
    if (self.venue) {
        self.venue.favorited = favorite;
        self.navActionButton.userInteractionEnabled = NO;
        self.navOverActionButton.userInteractionEnabled = NO;
        
        __weak typeof(self)weakSelf = self;
        [[VenueManager sharedInstance] setVenue:self.venue asFavorite:favorite resultCallback:^(NSDictionary *results) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            strongSelf.navActionButton.userInteractionEnabled = YES;
            strongSelf.navOverActionButton.userInteractionEnabled = YES;
            
            // update local instances of this venue
            [[NSNotificationCenter defaultCenter] postNotificationName:kSPCDidUpdateVenue object:strongSelf.venue];
            
            // inform the user
            NSString *message = [NSString stringWithFormat:(favorite ? @"Added %@ to your favorite venues." : @"Removed %@ from your favorite venues."), self.venue.displayNameTitle];
            [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } faultCallback:^(NSError *fault) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            strongSelf.navActionButton.userInteractionEnabled = YES;
            strongSelf.navOverActionButton.userInteractionEnabled = YES;
            
            NSString *message = favorite ? @"Error setting as favorite.  Please try again later." : @"Error removing from favorites.  Please try again later.";
            [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
        }];
    }
}


- (void)showReportPromptForVenue {
    self.reportAlertView = [[SPCReportAlertView alloc] initWithTitle:@"Choose type of report" stringOptions:self.reportVenueOptions dismissTitles:@[@"CANCEL"] andDelegate:self];
    
    [self.reportAlertView showAnimated:YES];
}

- (void)dismissAlert:(id)sender {
    [self.alertView dismiss:sender];
    self.alertView = nil;
}


- (void)searchHashTags {
    
    [Flurry logEvent:@"VENUE_HASHTAG_SEARCH_TAPPED"];
    
    SPCVenueHashTagsViewController *hashTagController = [[SPCVenueHashTagsViewController alloc] init];
    [hashTagController configureForHashTags:self.venueHashTags withSelectedTag:self.selectedTag];
    hashTagController.delegate = self;
    [self presentViewController:hashTagController animated:YES completion:nil];
    
}



#pragma mark - Memories CRUD

- (void)applicationDidBecomeActive:(NSNotification *)note {
    // nothing
}

- (void)spc_addMemoryLocally:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    if (memory.venue.locationId == self.venue.locationId) {
        if (![self.dataSource.fullFeed containsObject:memory]) {
            NSMutableArray *mutableMemories = [self.dataSource.feed mutableCopy];
            [mutableMemories insertObject:memory atIndex:0];
            NSArray *memories = [mutableMemories copy];
            
            self.dataSource.fullFeed = memories;
            self.dataSource.feed = memories;
        }
        
        [self.tableView reloadData];
    }
}


- (void)spc_localMemoryDeleted:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    if (memory.venue.locationId == self.venue.locationId) {
        if ([self.dataSource.fullFeed containsObject:memory]) {
            NSMutableArray *mutableMemories = [self.dataSource.fullFeed mutableCopy];
            [mutableMemories removeObject:memory];
            NSArray *memories = [mutableMemories copy];
            
            self.dataSource.fullFeed = memories;
            self.dataSource.feed = memories;
        }
        
        [self.tableView reloadData];
    }
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    Memory *memory = (Memory *)note.object;
    
    NSUInteger index = [self.dataSource.feed indexOfObject:memory];
    
    if (NSNotFound != index) {
        Memory *updatedMem = self.dataSource.feed[index];
        [updatedMem updateWithMemory:memory];
        
        // If the view is currently in front of the user, we do NOT want to reload all of the cells and risk altering the cells' placement. So, only refilter if the view is NOT visible
        if (NO == self.viewIsVisible) {
            self.dataSource.fullFeed = self.dataSource.fullFeed;
            self.dataSource.feed = self.dataSource.feed;
        }
        
        [self.tableView reloadData];
    }
}


#pragma mark - Coach mark

- (void)showCoachMarkFav {
    NSString *key = [SPCLiterals literal:kCoachMarkVenueFavKey forUser:[AuthenticationManager sharedInstance].currentUser];
    BOOL shouldDislayCoachMark = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    
    if (!shouldDislayCoachMark) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //self.navigationItem.rightBarButtonItem
        CGRect f1 = self.navigationItem.rightBarButtonItem.customView.frame;
        f1.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
       
        
        CoachMarks *coachMark = [[CoachMarks alloc] initWithFrame:self.view.bounds type:CoachMarkTypeVenueFav boundFrame:f1];
        coachMark.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2.0, CGRectGetHeight(self.view.bounds) / 2.0 - 50.0);
        coachMark.alpha = 0.0;
        [[UIApplication sharedApplication] addSubviewToWindow:coachMark];
        
        [UIView animateWithDuration:0.8
                              delay:0.0
                            options:0
                         animations:^{
                             coachMark.alpha = 1.0;
                             coachMark.center = self.view.center;
                         }
                         completion:^(BOOL finished) {
                             [coachMark performSelector:@selector(setDismissOnTouch:) withObject:@(YES) afterDelay:1.0];
                         }];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        if (alertView.tag == alertViewTagReport) {
            // These buttons were configured so that buttonIndex 1 = 'Send', buttonIndex 0 = 'Add Detail'
            if (1 == buttonIndex) {
                [Flurry logEvent:@"VENUE_REPORTED"];
                [[VenueManager sharedInstance] reportOrCorrectVenue:self.venue reportType:self.reportType text:nil completionHandler:^(BOOL success) {
                    if (success) {
                        [self showVenueReportWithSuccess:YES];
                    } else {
                        [self showVenueReportWithSuccess:NO];
                    }
                }];
            } else if (0 == buttonIndex) {
                SPCReportViewController *rvc = [[SPCReportViewController alloc] initWithReportObject:self.venue reportType:self.reportType andDelegate:self];
                [self.navigationController pushViewController:rvc animated:YES];
            }
        }
    }
}

#pragma mark - SPCReportAlertViewDelegate

- (void)tappedOption:(NSString *)option onSPCReportAlertView:(SPCReportAlertView *)reportView {
    if ([reportView isEqual:self.reportAlertView]) {
        self.reportType = [self.reportVenueOptions indexOfObject:option] + 1;
        
        [reportView hideAnimated:YES];
        
        // Now, we need to show an alert view asking the user if they want to "Add Detail" or "Send"
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send Report Immediately?" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Add Detail", @"Send", nil];
        alertView.tag = alertViewTagReport;
        [alertView show];
        
        self.reportAlertView = nil;
    }
}

- (void)tappedDismissTitle:(NSString *)dismissTitle onSPCReportAlertView:(SPCReportAlertView *)reportView {
    // We only have one dismiss option, so go ahead and remove the view
    [self.reportAlertView hideAnimated:YES];
    
    self.reportAlertView = nil;
}

#pragma mark - SPCReportViewControllerDelegate

- (void)invalidReportObjectOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showVenueReportWithSuccess:NO];
}

- (void)canceledReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
}

- (void)sendFailedOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showVenueReportWithSuccess:NO];
}

- (void)sentReportOnSPCReportViewController:(SPCReportViewController *)reportViewController {
    [reportViewController.navigationController popViewControllerAnimated:YES];
    
    [self showVenueReportWithSuccess:YES];
}

#pragma mark - Report/Flagging Results

- (void)showVenueReportWithSuccess:(BOOL)succeeded {
    if (succeeded) {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"This venue has been reported. Thank you.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"Error reporting this venue. Please try again later.", nil)
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Dismiss", nil)
                          otherButtonTitles:nil] show];
    }
}

#pragma mark - GKImagePickerDelegate

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image{
    UIImage *rescaledImage = [ImageUtils rescaleImageToScreenBounds:image];
    
    NSLog(@"uploading banner photo image...");
    [[VenueManager sharedInstance] updateVenue:self.venue
                                   bannerImage:rescaledImage
                             completionHandler:^(BOOL success) {
                                 if (success) {
                                     NSString *message = NSLocalizedString(@"Thank you for your photo submission!  If it's selected for this venue, you will earn 10 stars.", nil);
                                     [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                 } else {
                                     NSString *message = NSLocalizedString(@"An error occurred uploading your photo.  Please try again later.", nil);
                                     [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
                                 }
                             }];
    
    [self.imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    animator.presenting = YES;
    return animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    SPCAlertTransitionAnimator *animator = [SPCAlertTransitionAnimator new];
    return animator;
}


@end
