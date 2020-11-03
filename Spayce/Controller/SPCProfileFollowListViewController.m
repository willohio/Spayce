//
//  SPCProfileFollowListViewController.m
//  Spayce
//
//  Created by Jake Rosin on 3/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCProfileFollowListViewController.h"
#import "Constants.h"
#import "Flurry.h"

// View Controllers
#import "SPCAlertViewController.h"
#import "SPCProfileViewController.h"

// Managers
#import "MeetManager.h"
#import "SPCAlertTransitionAnimator.h"
#import "AuthenticationManager.h"

// Model
#import "Person.h"
#import "Asset.h"
#import "SPCAlertAction.h"
#import "User.h"
#import "UserProfile.h"

// View
#import "SPCNoSearchResultsCell.h"
#import "SPCFollowListCell.h"
#import "UIAlertView+SPCAdditions.h"

// Category
#import "UITableView+SPXRevealAdditions.h"

static NSString *followCellIdentifier = @"followCellIdentifier";
static NSString *noResultsCellIdentifier = @"noResultsCellIdentifier";


@interface SPCProfileFollowListViewController()<SPCProfileFollowListViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIViewControllerTransitioningDelegate, UITextViewDelegate>

// config
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, assign) SPCFollowListType followListType;

// state
@property (nonatomic, assign) BOOL viewHasAppeared;
@property (nonatomic, assign) BOOL fetchInProgress;
@property (nonatomic, assign) BOOL tabBarWasVisibleOnLoad;
@property (nonatomic, assign) BOOL isVisible;

// people
@property (nonatomic, strong) NSMutableArray *people;
@property (nonatomic, strong) NSString *nextPageKey;
@property (nonatomic, strong) NSString *peopleSearchFilter;
@property (nonatomic, assign) NSInteger searchNumber;

// views and view data
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *mutualBtn;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;

// Text search
@property (nonatomic, assign) CGFloat textEntryViewHeight;
@property (nonatomic, assign) CGFloat keyboardHeight;

@property (nonatomic, strong) UIButton *textEntryButton;
@property (nonatomic, strong) UIView *textEntryView;
@property (nonatomic, strong) UIView *textEntryBackground;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIButton *textEntryCancelButton;
@property (nonatomic, strong) UIButton *textEntryCancelOverlay;

@property (nonatomic, strong) NSString * searchFilter;
@property (nonatomic, assign) CGFloat heightForRecipientText;
@property (nonatomic, strong) UITextView *placeholderTextLabel;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL isSearching;
@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation SPCProfileFollowListViewController


#pragma mark Object Lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (instancetype)initWithFollowListType:(SPCFollowListType)followListType {
    return [self initWithFollowListType:followListType userToken:nil];
}


- (instancetype)initWithFollowListType:(SPCFollowListType)followListType userToken:(NSString *)userToken {
    self = [super init];
    if (self) {
        self.followListType = followListType;
        self.userToken = userToken;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    self.textEntryViewHeight = 50;
    
    [self.view addSubview:self.textEntryView];
    [self.view addSubview:self.tableView];
    [self.view addSubview:self.textEntryCancelOverlay];
    [self.view addSubview:self.textEntryButton];
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.loadingSpinner];
    
    [self.tableView registerClass:[SPCFollowListCell class] forCellReuseIdentifier:followCellIdentifier];
    [self.tableView registerClass:[SPCNoSearchResultsCell class] forCellReuseIdentifier:noResultsCellIdentifier];
    [self.tableView enableRevealableViewForDirection:SPXRevealableViewGestureDirectionLeft];
    self.tabBarWasVisibleOnLoad = !self.tabBarController.tabBar.hidden && self.tabBarController.tabBar.alpha > 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRequestFollowNotification:) name:kFollowDidRequestWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFollowNotification:) name:kFollowDidFollowWithUserToken object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnfollowNotification:) name:kFollowDidUnfollowWithUserToken object:nil];
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Update tab bar visibility
    if (self.tabBarWasVisibleOnLoad) {
        self.tabBarController.tabBar.alpha = 0;
        self.tabBarController.tabBar.hidden = YES;
    }
    
    if (self.viewHasAppeared && self.people) {
        [self reloadData];
    } else if (!self.viewHasAppeared) {
        [self fetchPeople];
    }
    self.viewHasAppeared = YES;
    self.isVisible = YES;
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Show bottom bar when popped
    if (self.tabBarWasVisibleOnLoad) {
        self.tabBarController.tabBar.alpha = 1;
        self.tabBarController.tabBar.hidden = NO;
    }
    self.isVisible = NO;
}


#pragma mark Subview Accessors


- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 70)];
        _navBar.backgroundColor = [UIColor whiteColor];
        
        [_navBar addSubview:self.backBtn];
        [_navBar addSubview:self.titleLbl];
        if (self.followListType == SPCFollowListTypeUserFollowers || self.followListType == SPCFollowListTypeUserFollows) {
            // TODO: restore when mutual follower lists are supported.
            //[_navBar addSubview:self.mutualBtn];
        }
    }
    return _navBar;
}


-(UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 15, 60, 60)];
        [_backBtn addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchDown];
        [_backBtn setBackgroundImage:[UIImage imageNamed:@"mamBackToCapture"] forState:UIControlStateNormal];
        [_backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return _backBtn;
}

-(UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width - 140, 50)];
        _titleLbl.text = [SPCProfileFollowListViewController titleForFollowListType:self.followListType];
        _titleLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:16];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y);
    }
    return _titleLbl;
}

-(UIButton *)mutualBtn {
    if (!_mutualBtn) {
        _mutualBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 80, 20, 80, 50)];
        [_mutualBtn setTitle:@"MUTUAL" forState:UIControlStateNormal];
        _mutualBtn.titleLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:12];
        [_mutualBtn addTarget:self action:@selector(showMutual) forControlEvents:UIControlEventTouchDown];
        [_mutualBtn setTitleColor:[UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
    }
    return _mutualBtn;
}


- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.navBar.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.navBar.frame))];
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        //_tableView.translatesAutoresizingMaskIntoConstraints = NO;
        _tableView.autoresizingMask = UIViewAutoresizingNone;
        //UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.hidden = NO;
        _tableView.contentInset = UIEdgeInsetsMake(self.textEntryViewHeight, 0, 0, 0);
        
    }
    return _tableView;
}


- (UIView *)textEntryView {
    if (!_textEntryView) {
        _textEntryView = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.navBar.frame), CGRectGetWidth(self.view.frame), self.textEntryViewHeight)];
        _textEntryView.backgroundColor = [UIColor colorWithRGBHex:0xe6f1f8];
        
        CGFloat sepHeight = 1.0 / [UIScreen mainScreen].scale;
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.textEntryViewHeight - sepHeight, CGRectGetWidth(self.view.frame), sepHeight)];
        [_textEntryView addSubview:separatorView];
        
        [_textEntryView addSubview:self.textEntryBackground];
        [_textEntryView addSubview:self.textEntryCancelButton];
        
        [_textEntryView addSubview:self.textView];
        [_textEntryView addSubview:self.placeholderTextLabel];
    }
    return _textEntryView;
}


- (UIView *)textEntryBackground {
    if (!_textEntryBackground) {
        _textEntryBackground = [[UIView alloc] initWithFrame:CGRectMake(37, 10, CGRectGetWidth(self.textEntryView.frame) - 74, self.textEntryViewHeight - 20)];
        _textEntryBackground.backgroundColor = [UIColor whiteColor];
        _textEntryBackground.layer.cornerRadius = 4;
    }
    return _textEntryBackground;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectZero];
        _textView.delegate = self;
        _textView.text = @"Search Followers...";
        if (self.followListType == SPCFollowListTypeMyFollows || self.followListType == SPCFollowListTypeUserFollows || self.followListType == SPCFollowListTypeUserMutualFollows) {
            _textView.text = @"Search Followed Users...";
        }
        _textView.font = [UIFont fontWithName:@"OpenSans" size:13];
        _textView.frame = CGRectMake(0, 0, CGRectGetWidth(self.textEntryBackground.frame) - 30, _textView.font.lineHeight);
        [_textView sizeToFit];
        CGRect frame = _textView.frame;
        frame.size = CGSizeMake(CGRectGetWidth(self.textEntryBackground.frame) - 30, frame.size.height);
        _textView.frame = frame;
        _textView.center = CGPointMake(CGRectGetWidth(self.textEntryView.frame)/2, CGRectGetHeight(self.textEntryView.frame)/2);
        _textView.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _textView.autocorrectionType = UITextAutocorrectionTypeNo;
        _textView.returnKeyType = UIReturnKeySearch;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.alpha = 0;
        _textView.text = nil;
    }
    return _textView;
}


-(UITextView *)placeholderTextLabel {
    if (!_placeholderTextLabel) {
        _placeholderTextLabel = [[UITextView alloc] initWithFrame:CGRectZero];
        _placeholderTextLabel.text = @"Search Followers...";
        if (self.followListType == SPCFollowListTypeMyFollows || self.followListType == SPCFollowListTypeUserFollows || self.followListType == SPCFollowListTypeUserMutualFollows) {
            _placeholderTextLabel.text = @"Search Followed Users...";
        }
        _placeholderTextLabel.font = [UIFont fontWithName:@"OpenSans" size:13];
        _placeholderTextLabel.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), _placeholderTextLabel.font.lineHeight);
        _placeholderTextLabel.textColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        [_placeholderTextLabel sizeToFit];
        _placeholderTextLabel.center = CGPointMake(CGRectGetWidth(self.textEntryView.frame)/2, CGRectGetHeight(self.textEntryView.frame)/2);
        _placeholderTextLabel.userInteractionEnabled = NO;
        _placeholderTextLabel.backgroundColor = [UIColor clearColor];
    }
    return _placeholderTextLabel;
}

- (UIButton *)textEntryButton {
    if (!_textEntryButton) {
        _textEntryButton = [[UIButton alloc] initWithFrame:self.textEntryView.frame];
        _textEntryButton.backgroundColor = [UIColor clearColor];
        
        [_textEntryButton addTarget:self action:@selector(startSearch) forControlEvents:UIControlEventTouchDown];
    }
    return _textEntryButton;
}


- (UIButton *)textEntryCancelButton {
    if (!_textEntryCancelButton) {
        _textEntryCancelButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.view.bounds), 0, 80, 50)];
        [_textEntryCancelButton addTarget:self action:@selector(endSearch) forControlEvents:UIControlEventTouchUpInside];
        _textEntryCancelButton.enabled = NO;
        _textEntryCancelButton.alpha = 0;
        
        [_textEntryCancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_textEntryCancelButton setTitle:NSLocalizedString(@"CANCEL", nil) forState:UIControlStateNormal];
        _textEntryCancelButton.titleLabel.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:12];
    }
    return _textEntryCancelButton;
}


- (UIButton *)textEntryCancelOverlay {
    if (!_textEntryCancelOverlay) {
        _textEntryCancelOverlay = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMinY(self.tableView.frame), CGRectGetWidth(self.view.frame), CGRectGetHeight(self.tableView.frame))];
        [_textEntryCancelOverlay addTarget:self action:@selector(endSearch) forControlEvents:UIControlEventTouchUpInside];
        _textEntryCancelOverlay.enabled = NO;
        _textEntryCancelOverlay.hidden = YES;
        _textEntryCancelOverlay.alpha = 0;
        _textEntryCancelOverlay.backgroundColor = [UIColor blackColor];
    }
    return _textEntryCancelOverlay;
}


- (UIView *)loadingSpinner {
    if (!_loadingSpinner) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.center = CGPointMake(self.view.center.x, self.view.frame.size.height/2);
        indicatorView.color = [UIColor grayColor];
        [indicatorView startAnimating];
        
        _loadingSpinner = indicatorView;
    }
    return _loadingSpinner;
}



#pragma mark accessors

+ (NSString *)titleForFollowListType:(SPCFollowListType)followListType {
    switch (followListType) {
        case SPCFollowListTypeMyFollowers:
        case SPCFollowListTypeUserFollowers:
            return @"Followers";
        case SPCFollowListTypeMyFollows:
        case SPCFollowListTypeUserFollows:
            return @"Following";
        case SPCFollowListTypeUserMutualFollowers:
            return @"Mutual Followers";
        case SPCFollowListTypeUserMutualFollows:
            return @"Mutual Following";
    }
    return nil;
}


#pragma mark actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)startSearch {
    if (!self.isSearching) {
        self.isSearching = YES;
        self.textEntryButton.enabled = NO;
        self.tableView.userInteractionEnabled = NO;
        
        self.navBar.userInteractionEnabled = NO;
        
        self.textEntryCancelButton.center = CGPointMake(CGRectGetWidth(self.textEntryView.frame) + CGRectGetWidth(self.textEntryCancelButton.frame)/2, CGRectGetHeight(self.textEntryView.frame)/2);
        CGFloat textEntryBottom = MAX(CGRectGetMinY(self.tableView.frame), CGRectGetMaxY(self.textEntryView.frame));
        self.textEntryCancelOverlay.frame = CGRectMake(0, textEntryBottom, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.tableView.frame) - textEntryBottom + CGRectGetMinY(self.tableView.frame));
        
        self.isAnimating = YES;
        
        self.textView.text = nil;
        self.textView.userInteractionEnabled = YES;
        [self.textView becomeFirstResponder];
        
        self.textEntryCancelOverlay.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBar.center.y - CGRectGetHeight(self.navBar.frame));
            
            self.textEntryView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 70);
            self.textEntryView.backgroundColor = [UIColor colorWithRGBHex:0x4cb0fb];
            
            self.textEntryBackground.frame = CGRectMake(10, 30, CGRectGetWidth(self.view.frame) - 10 - CGRectGetWidth(self.textEntryCancelButton.frame), 30);
            
            self.textView.center = CGPointMake(CGRectGetWidth(self.textView.frame)/2 + 15, 45);
            self.placeholderTextLabel.center = CGPointMake(CGRectGetWidth(self.placeholderTextLabel.frame)/2 + 15, 45);
            
            self.textEntryCancelButton.alpha = 1.0;
            self.textEntryCancelButton.center = CGPointMake(CGRectGetWidth(self.textEntryView.frame) - CGRectGetWidth(self.textEntryCancelButton.frame)/2, 20 + CGRectGetHeight(self.textEntryCancelButton.frame)/2);
            
            self.textEntryCancelOverlay.frame = self.tableView.frame;
            
            self.textEntryCancelOverlay.alpha = 0.4;
            
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.keyboardHeight, 0);
        } completion:^(BOOL finished) {
            self.textView.alpha = 1;
            
            self.textEntryCancelButton.enabled = YES;
            self.textEntryCancelOverlay.enabled = YES;
            self.tableView.userInteractionEnabled = YES;
            
            self.tableView.contentInset = UIEdgeInsetsMake(0, 0, self.keyboardHeight, 0);
            self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
            
            self.isAnimating = NO;
            
            //self.textView.userInteractionEnabled = YES;
            //[self.textView becomeFirstResponder];
        }];
    }
}

- (void)endSearch {
    if (self.isSearching) {
        self.textEntryCancelButton.enabled = NO;
        self.textEntryCancelOverlay.enabled = NO;
        self.tableView.userInteractionEnabled = NO;
        
        self.textView.alpha = 0;
        self.textView.text = nil;
        [self filterContentForSearchText];
        
        self.isAnimating = YES;
        
        [self.textView resignFirstResponder];
        
        self.placeholderTextLabel.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            
            self.navBar.center = CGPointMake(self.navBar.center.x, self.navBar.center.y + CGRectGetHeight(self.navBar.frame));
            
            self.textEntryView.frame = CGRectMake(0, CGRectGetHeight(self.navBar.frame), CGRectGetWidth(self.view.frame), self.textEntryViewHeight);
            self.textEntryView.backgroundColor = [UIColor colorWithRGBHex:0xe6f1f8];
            
            self.textEntryBackground.frame = CGRectMake(37, 10, CGRectGetWidth(self.view.frame) - 74, self.textEntryViewHeight - 20);
            
            self.textView.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, self.textEntryViewHeight / 2);
            self.placeholderTextLabel.center = CGPointMake(CGRectGetWidth(self.view.frame)/2, self.textEntryViewHeight / 2);
            
            self.textEntryCancelButton.alpha = 0;
            self.textEntryCancelButton.center = CGPointMake(CGRectGetWidth(self.view.frame) + CGRectGetWidth(self.textEntryCancelButton.frame)/2, CGRectGetHeight(self.textEntryCancelButton.frame)/2);
            
            self.textEntryCancelOverlay.frame = CGRectMake(0, CGRectGetMinY(self.tableView.frame) + self.textEntryViewHeight, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.tableView.frame) - self.textEntryViewHeight);
            
            self.textEntryCancelOverlay.alpha = 0;
            
            self.tableView.contentInset = UIEdgeInsetsMake(self.textEntryViewHeight, 0, 0, 0);
            self.tableView.contentOffset = CGPointMake(0, -self.textEntryViewHeight);
            
        } completion:^(BOOL finished) {
            self.textEntryButton.enabled = YES;
            self.isSearching = NO;
            self.tableView.userInteractionEnabled = YES;
            self.navBar.userInteractionEnabled = YES;
            
            self.textEntryCancelOverlay.hidden = YES;
            
            self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
            
            self.isAnimating = NO;
            
            //[self.textView resignFirstResponder];
        }];
    }
}

- (void)showMutual {
    if (self.followListType == SPCFollowListTypeUserFollowers) {
        SPCProfileFollowListViewController *vc = [[SPCProfileFollowListViewController alloc] initWithFollowListType:SPCFollowListTypeUserMutualFollowers userToken:self.userToken];
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (self.followListType == SPCFollowListTypeUserFollows) {
        SPCProfileFollowListViewController *vc = [[SPCProfileFollowListViewController alloc] initWithFollowListType:SPCFollowListTypeUserMutualFollows userToken:self.userToken];
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    }
}


- (void)followListFollowStatusChanged:(Person *)person {
    NSLog(@"TODO: followListFollowStatusChanged");
}


- (void)reloadData {
    [self.loadingSpinner stopAnimating];
    self.loadingSpinner.hidden = YES;
    [self.tableView reloadData];
}


- (void)fetchPeople {
    if (self.fetchInProgress) {
        return;
    }
    
    self.searchNumber++;
    self.fetchInProgress = YES;
    self.nextPageKey = nil;
    
    NSString *searchFilter = self.searchFilter;
    NSInteger searchNumber = self.searchNumber;
    
    __weak typeof(self) weakSelf = self;
    
    [self fetchPeopleWithPartialSearch:searchFilter pageKey:nil completionHandler:^(NSArray *followers, NSString *nextPageKey) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (searchNumber == self.searchNumber) {
            strongSelf.fetchInProgress = NO;
            strongSelf.nextPageKey = nextPageKey;
            strongSelf.people = [NSMutableArray arrayWithArray:followers];
            strongSelf.peopleSearchFilter = searchFilter;
        
            //update display
            [strongSelf reloadData];
            
            if (strongSelf.isSearching && !strongSelf.isAnimating && searchFilter.length > 0) {
                strongSelf.textEntryCancelOverlay.hidden = YES;
                strongSelf.textEntryCancelOverlay.enabled = NO;
            }
        }
        
    } errorHandler:^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (searchNumber == strongSelf.searchNumber) {
            strongSelf.fetchInProgress = NO;
            
            //update display
            [strongSelf reloadData];
        }
    }];
}



- (void)fetchMorePeople {
    if (self.fetchInProgress || !self.nextPageKey) {
        return;
    }
    
    self.fetchInProgress = YES;
    NSInteger searchNumber = self.searchNumber;
    
    __weak typeof(self) weakSelf = self;
    
    [self fetchPeopleWithPartialSearch:self.searchFilter pageKey:self.nextPageKey completionHandler:^(NSArray *followers, NSString *nextPageKey) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (searchNumber == strongSelf.searchNumber) {
            strongSelf.fetchInProgress = NO;
            strongSelf.nextPageKey = nextPageKey;
            [strongSelf.people addObjectsFromArray:followers];
            
            //update display
            [strongSelf reloadData];
        }
        
    } errorHandler:^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (searchNumber == strongSelf.searchNumber) {
            strongSelf.fetchInProgress = NO;
        
            //update display
            [strongSelf reloadData];
        }
    }];
}


- (void)fetchPeopleWithPartialSearch:(NSString *)partialSearch pageKey:(NSString *)pageKey completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                        errorHandler:(void (^)(NSError *error))errorHandler {
    switch (self.followListType) {
        case SPCFollowListTypeMyFollowers:
            [MeetManager fetchFollowersWithPartialSearch:partialSearch pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
            break;
            
        case SPCFollowListTypeMyFollows:
            [MeetManager fetchFollowedUsersWithPartialSearch:partialSearch pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
            break;
            
        case SPCFollowListTypeUserFollowers:
            [MeetManager fetchFollowersWithUserToken:self.userToken partialSearch:partialSearch withPageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
            break;
            
        case SPCFollowListTypeUserFollows:
            [MeetManager fetchFollowedUsersWithUserToken:self.userToken partialSearch:partialSearch withPageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
            break;
            
        case SPCFollowListTypeUserMutualFollowers:
            break;
            
        case SPCFollowListTypeUserMutualFollows:
            break;
    }
}


- (void)followButtonTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger tag = button.tag;
    Person *person = self.people[tag];
    
    switch(person.followingStatus) {
        case FollowingStatusNotFollowing:
            // start following...
            button.enabled = NO;
            [self followPerson:person];
            break;
            
        case FollowingStatusFollowing:
            // stop following...
            button.enabled = NO;
            [self unfollowPerson:person];
            break;
    }
}


- (void)userImageTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger tag = button.tag;
    Person *person = self.people[tag];
    if (![person.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
        SPCProfileViewController *profileViewController = [[SPCProfileViewController alloc] initWithUserToken:person.userToken];
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}


- (void)followPerson:(Person *)person {
    // perform follow.  No need for an alert view; we only show that when the user UNfollows.
    [MeetManager sendFollowRequestWithUserToken:person.userToken completionHandler:^(BOOL followingNow) {
        [Flurry logEvent:@"FOLLOW_REQ_IN_PROFILE_FOLLOW"];
        if (followingNow) {
            person.followingStatus = FollowingStatusFollowing;
        } else {
            person.followingStatus = FollowingStatusRequested;
        }
        SPCFollowListCell *cell = [self currentCellForPerson:person];
        if (cell) {
            [cell configureWithPerson:person url:[NSURL URLWithString:person.imageAsset.imageUrlThumbnail]];
        }
    } errorHandler:^(NSError *error) {
        SPCFollowListCell *cell = [self currentCellForPerson:person];
        if (cell) {
            cell.followButton.enabled = YES;
        }
        [UIAlertView showError:error];
    }];
}


- (void)unfollowPerson:(Person *)person {
    SPCAlertViewController *alertViewController = [[SPCAlertViewController alloc] init];
    alertViewController.modalPresentationStyle = UIModalPresentationCustom;
    alertViewController.transitioningDelegate = self;
    alertViewController.alertTitle = [NSString stringWithFormat:NSLocalizedString(@"%@ %@", nil), person.firstname, person.lastname];
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Unfollow", nil) style:SPCAlertActionStyleDestructive handler:^(SPCAlertAction *action) {
        // perform follow
        __weak typeof(self) weakSelf = self;
        [MeetManager unfollowWithUserToken:person.userToken completionHandler:^{
            [Flurry logEvent:@"UNFOLLOW_IN_PROFILE_FOLLOW"];
            __strong typeof(self) strongSelf = weakSelf;
            person.followingStatus = FollowingStatusNotFollowing;
            SPCFollowListCell *cell = [strongSelf currentCellForPerson:person];
            if (cell) {
                [cell configureWithPerson:person url:[NSURL URLWithString:person.imageAsset.imageUrlThumbnail]];
            }
        } errorHandler:^(NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            SPCFollowListCell *cell = [strongSelf currentCellForPerson:person];
            if (cell) {
                cell.followButton.enabled = YES;
            }
            [UIAlertView showError:error];
            
        }];
    }]];
    
    [alertViewController addAction:[SPCAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:SPCAlertActionStyleCancel handler:nil]];
    
    [self.navigationController presentViewController:alertViewController animated:YES completion:nil];
}


- (SPCFollowListCell *)currentCellForPerson:(Person *)person {
    NSArray *cells = self.tableView.visibleCells;
    for (UITableViewCell *cell in cells) {
        if ([cell isKindOfClass:[SPCFollowListCell class]]) {
            SPCFollowListCell *followCell = (SPCFollowListCell *)cell;
            if (followCell.person && [followCell.person.userToken isEqualToString:person.userToken]) {
                return followCell;
            }
        }
    }
    return nil;
}


- (void)adjustScrollPositionIfNeeded {
    if (!self.isSearching) {
        CGFloat textTop = CGRectGetMinY(self.textEntryView.frame);
        CGFloat min = CGRectGetHeight(self.navBar.frame) - CGRectGetHeight(self.textEntryView.frame);
        CGFloat max = CGRectGetHeight(self.navBar.frame);
        if (textTop > min && textTop < max && self.tableView.contentSize.height > self.tableView.frame.size.height + CGRectGetHeight(self.textEntryView.frame)) {
            // partially visible
            if (ABS(textTop - min) > ABS(textTop - max)) {
                // closer to the bottom -- scroll to 0.
                [UIView animateWithDuration:0.3 animations:^{
                    self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top);
                }];
            } else {
                // closer to the top -- scroll to 50
                [UIView animateWithDuration:0.3 animations:^{
                    self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top + CGRectGetHeight(self.textEntryView.frame));
                }];
            }
        }
    }
}


- (void)keyboardDidShow:(NSNotification *)not {
    self.keyboardHeight = CGRectGetHeight([[[not userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue]);
    if (!self.isAnimating) {
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.bottom = self.keyboardHeight;
        self.tableView.contentInset = insets;
    }
}

- (void)keyboardWillHide:(NSNotification *)not {
    if (!self.isAnimating) {
        UIEdgeInsets insets = self.tableView.contentInset;
        insets.bottom = 0;
        self.tableView.contentInset = insets;
    }
}


- (void)didRequestFollowNotification:(NSNotification *)note {
    if (!self.isVisible) {
        // change originated from elsewhere; we should update
        NSString *userToken = (NSString *)note.object;
        for (Person *person in self.people) {
            if ([person.userToken isEqualToString:userToken]) {
                person.followingStatus = FollowingStatusRequested;
                [self reloadData];
                break;
            }
        }
    }
}

- (void)didFollowNotification:(NSNotification *)note {
    if (!self.isVisible) {
        // change originated from elsewhere; we should update
        NSString *userToken = (NSString *)note.object;
        for (Person *person in self.people) {
            if ([person.userToken isEqualToString:userToken]) {
                person.followingStatus = FollowingStatusFollowing;
                [self reloadData];
                break;
            }
        }
    }
}

- (void)didUnfollowNotification:(NSNotification *)note {
    if (!self.isVisible) {
        // change originated from elsewhere; we should update
        NSString *userToken = (NSString *)note.object;
        for (Person *person in self.people) {
            if ([person.userToken isEqualToString:userToken]) {
                person.followingStatus = FollowingStatusNotFollowing;
                [self reloadData];
                break;
            }
        }
    }
}


- (void)filterContentForSearchText {
    self.searchFilter = self.textView.text;
    
    if (!self.searchFilter || self.searchFilter.length == 0) {
        // no search...
        // TODO restore the original first page?
        if (self.peopleSearchFilter && self.peopleSearchFilter.length > 0) {
            self.nextPageKey = nil;
            self.fetchInProgress = NO;
            [self fetchPeople];
        }
    } else {
        // Perform this search
        if (!self.peopleSearchFilter || self.peopleSearchFilter.length == 0 || ![self.peopleSearchFilter isEqualToString:self.searchFilter]) {
            self.nextPageKey = nil;
            self.fetchInProgress = NO;
            [self fetchPeople];
        }
    }
}


#pragma mark - UITextViewDelegate


-(BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    return YES;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [self filterContentForSearchText];
        [self.textView resignFirstResponder];
        return NO;
    }
    
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    //NSLog(@"newText %@",newText);
    BOOL hasText = newText.length > 0;
    self.placeholderTextLabel.hidden = hasText;
    
    if (!hasText && self.isSearching && !self.isAnimating) {
        self.textEntryCancelOverlay.enabled = YES;
        self.textEntryCancelOverlay.hidden = NO;
    }
    
    // Cancel previous filter request
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
        
    // Schedule delayed filter request in order to allow textField to update it's internal state
    [self performSelector:@selector(filterContentForSearchText) withObject:nil afterDelay:.5];
    
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView {
    self.isEditing = YES;
}

-(void)textViewDidEndEditing:(UITextView *)textView {
    self.isEditing = NO;
}



#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (!self.nextPageKey) {
        if ((self.searchFilter.length > 0) && (self.people.count == 0)) {
            return 1;
        } else {
            return self.people.count;
        }
    } else {
        return self.people.count +1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.people.count > 0) {
        if (indexPath.row < self.people.count) {
            return [self tableView:tableView personCellForRowAtIndexPath:indexPath];
        }
        else {
            return [self tableView:tableView loadingCellForRowAtIndexPath:indexPath];
        }
    }
    else {
        if (self.searchFilter.length > 0) {
            return [self tableView:tableView noSearchResultsCellAtIndexPath:indexPath];
        }
        else {
            return [self tableView:tableView placeHolderCellForRowAtIndexPath:indexPath];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    float triggerPoint = 70 * (self.people.count - 10);
    if (scrollView.contentOffset.y > triggerPoint) {
        [self fetchMorePeople];
    }
    
    if (!self.isSearching) {
        self.textEntryButton.frame = self.textEntryView.frame = CGRectMake(0, CGRectGetMaxY(self.navBar.frame) - scrollView.contentOffset.y - scrollView.contentInset.top, CGRectGetWidth(self.textEntryView.frame), CGRectGetHeight(self.textEntryView.frame));
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self adjustScrollPositionIfNeeded];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self adjustScrollPositionIfNeeded];
}



- (UITableViewCell *)tableView:(UITableView *)tableView personCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Person *recipient = self.people[indexPath.row];
    SPCFollowListCell *cell = [tableView dequeueReusableCellWithIdentifier:followCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCFollowListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:followCellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellEditingStyleNone;
    
    if ([recipient.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken]) {
        [cell configureWithCurrentUser:recipient url:[NSURL URLWithString:recipient.imageAsset.imageUrlThumbnail]];
    } else {
        [cell configureWithPerson:recipient url:[NSURL URLWithString:recipient.imageAsset.imageUrlThumbnail]];
    }
    
    [cell.followButton addTarget:self action:@selector(followButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.imageButton addTarget:self action:@selector(userImageTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    cell.tag = indexPath.row;
    cell.followButton.tag = indexPath.row;
    cell.imageButton.tag = indexPath.row;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView noSearchResultsCellAtIndexPath:(NSIndexPath *)indexPath {
    SPCNoSearchResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:noResultsCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[SPCNoSearchResultsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noResultsCellIdentifier];
        cell.userInteractionEnabled = NO;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView placeHolderCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PlaceHolder";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView loadingCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"LoadingMore";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.tag = 111;
        indicatorView.color = [UIColor grayColor];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:indicatorView];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        [indicatorView startAnimating];
    } else {
        UIActivityIndicatorView *animation = (UIActivityIndicatorView *)[cell viewWithTag:111];
        [animation startAnimating];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
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
