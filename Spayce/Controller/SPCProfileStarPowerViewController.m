//
//  SPCProfileStarPowerViewController.m
//  Spayce
//
//  Created by Jake Rosin on 3/25/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCProfileStarPowerViewController.h"

#import "MeetManager.h"

// Model
#import "UserProfile.h"
#import "ProfileDetail.h"

// Category
#import "NSString+SPCAdditions.h"


@interface SPCProfileStarPowerViewController ()

// user data
@property (nonatomic, strong) UserProfile *userProfile;

// content state
@property (nonatomic, readonly) BOOL loaded;
@property (nonatomic, readonly) BOOL loadError;

@property (nonatomic, assign) BOOL loadedMoments;
@property (nonatomic, assign) BOOL loadErrorMoments;

// content
@property (nonatomic, strong) NSArray *moments;

// views
@property (nonatomic, strong) UIView *navBar;
@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UILabel *titleLbl;
@property (nonatomic, strong) UILabel *starLbl;

@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;

@end

@implementation SPCProfileStarPowerViewController

#pragma mark lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithUserProfile:(UserProfile *)userProfile {
    self = [super init];
    if (self) {
        self.userProfile = userProfile;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    
    [self.view addSubview:self.navBar];
    [self.view addSubview:self.loadingSpinner];
    
    // fetch content
    [self fetchMoments];
}


#pragma mark accessors

- (BOOL)loaded {
    return self.loadedMoments;
}

- (BOOL)loadError {
    return self.loadErrorMoments;
}


- (UIView *)navBar {
    if (!_navBar) {
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 70)];
        _navBar.backgroundColor = [UIColor whiteColor];
        
        [_navBar addSubview:self.backBtn];
        [_navBar addSubview:self.titleLbl];
        [_navBar addSubview:self.starLbl];
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

- (UILabel *)titleLbl {
    if (!_titleLbl) {
        _titleLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width - 140, 50)];
        _titleLbl.text = @"Star Power";
        _titleLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:16];
        _titleLbl.textAlignment = NSTextAlignmentCenter;
        _titleLbl.center = CGPointMake(self.view.bounds.size.width/2, _titleLbl.center.y - _titleLbl.font.lineHeight/2 + 1);
    }
    return _titleLbl;
}

- (UILabel *)starLbl {
    if (!_starLbl) {
        _starLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width - 140, 50)];
        _starLbl.text = [NSString stringByFormattingInteger:self.userProfile.profileDetail.starCount];
        _starLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:12];
        _starLbl.textColor = [UIColor colorWithRGBHex:0xbbbdc1];
        _starLbl.textAlignment = NSTextAlignmentCenter;
        _starLbl.center = CGPointMake(self.view.bounds.size.width/2, _starLbl.center.y + _starLbl.font.lineHeight/2 - 1);
    }
    return _starLbl;
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


#pragma mark Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)reloadData {
    if (self.loaded) {
        // TODO
    } else if (self.loadError) {
        // TODO
    } else {
        // TODO
    }
}

- (void)fetchMoments {
    __weak typeof(self) weakSelf = self;
    [MeetManager fetchUserMemoriesWithUserToken:self.userProfile.userToken memorySortType:MemorySortTypeRecency count:6 pageKey:nil completionHandler:^(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories, NSString *nextPageKey) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        strongSelf.moments = memories;
        strongSelf.loadedMoments = YES;
        [strongSelf reloadData];
        
    } errorHandler:^(NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        strongSelf.loadErrorMoments = YES;
        [strongSelf reloadData];
    }];
}


@end
