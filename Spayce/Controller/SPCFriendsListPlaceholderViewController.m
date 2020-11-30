//
//  SPCFriendsListPlaceholderViewController.m
//  Spayce
//
//  Created by William Santiago on 2014-11-10.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFriendsListPlaceholderViewController.h"

// Model
#import "UserProfile.h"
#import "ProfileDetail.h"

@interface SPCFriendsListPlaceholderViewController ()

// Data
@property (nonatomic) SPCFriendsListType friendsListType;
@property (nonatomic, strong) UserProfile *userProfile;

// UI
@property (nonatomic, strong) UIView *customNavigationBar;
@property (nonatomic, strong) UILabel *messageTitleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation SPCFriendsListPlaceholderViewController

#pragma mark - Object lifecycle

- (instancetype)initWithFriendsListType:(SPCFriendsListType)friendsListType andUserProfile:(UserProfile *)userProfile {
    self = [super init];
    if (self) {
        _friendsListType = friendsListType;
        _userProfile = userProfile;
    }
    return self;
}

#pragma mark - Accessors

- (UIView *)customNavigationBar {
    if (!_customNavigationBar) {
        _customNavigationBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 70)];
        _customNavigationBar.backgroundColor = [UIColor whiteColor];
        _customNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectZero];
        backButton.titleLabel.font = [UIFont spc_regularSystemFontOfSize: 14];
        backButton.layer.cornerRadius = 2;
        backButton.backgroundColor = [UIColor clearColor];
        NSDictionary *backStringAttributes = @{ NSFontAttributeName : backButton.titleLabel.font,
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] };
        NSAttributedString *backString = [[NSAttributedString alloc] initWithString:@"Done" attributes:backStringAttributes];
        [backButton setAttributedTitle:backString forState:UIControlStateNormal];
        backButton.frame = CGRectMake(0, CGRectGetHeight(_customNavigationBar.frame) - 44.0f, 60, 44);
        [backButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
        
        NSString *titleText = @"UNAVAILABLE"; // default
        if (SPCFriendsListTypeUserFriends == self.friendsListType) {
            titleText = NSLocalizedString(@"FRIENDS", nil);
        }
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        NSDictionary *titleLabelAttributes = @{ NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:16],
                                                NSForegroundColorAttributeName : [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f],
                                                NSKernAttributeName : @(1.1) };
        titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleText attributes:titleLabelAttributes];
        CGSize sizeOfTitle = [titleLabel.text sizeWithAttributes:titleLabelAttributes];
        titleLabel.frame = CGRectMake(0, 0, sizeOfTitle.width, sizeOfTitle.height);
        titleLabel.center = CGPointMake(CGRectGetMidX(_customNavigationBar.frame), CGRectGetMidY(backButton.frame) - 2);
        
        [_customNavigationBar addSubview:backButton];
        [_customNavigationBar addSubview:titleLabel];
    }
    return _customNavigationBar;
}

- (UILabel *)messageTitleLabel {
    if (!_messageTitleLabel) {
        NSString *message = @"Unavailable"; // default
        
        if (SPCFriendsListTypeUserFriends == self.friendsListType) {
            message = [NSString stringWithFormat:@"Hang On!"];
        }
        
        NSDictionary *messageAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f],
                                             NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:14]
                                             };
        CGRect messageSizeRect = [message boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.view.frame), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:messageAttributes context:nil];
        
        _messageTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMidY(self.view.frame) - 28, CGRectGetWidth(self.view.frame), messageSizeRect.size.height)];
        _messageTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:message attributes:messageAttributes];
        _messageTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _messageTitleLabel;
}

- (UILabel *)messageLabel {
    if (!_messageLabel) {
        NSString *message = @"This content is currently unavailable."; // default
        
        if (SPCFriendsListTypeUserFriends == self.friendsListType) {
            message = [NSString stringWithFormat:@"Add %@ to see this friends list.", self.userProfile.profileDetail.firstname];
        }
        
        NSDictionary *messageAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRed:184.0f/255.0f green:193.0f/255.0f blue:201.0f/255.0f alpha:1.0f],
                                             NSFontAttributeName : [UIFont spc_regularSystemFontOfSize:14]
                                             };
        
        _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMidY(self.view.frame), CGRectGetWidth(self.view.frame), 16)];
        _messageLabel.attributedText = [[NSAttributedString alloc] initWithString:message attributes:messageAttributes];
        _messageLabel.textAlignment = NSTextAlignmentCenter;
        
    }
    return _messageLabel;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor colorWithWhite:248.0f/255.0f alpha:1.0f];
    
    // Add to view hierarchy
    [self.view addSubview:self.customNavigationBar];
    [self.view addSubview:self.messageTitleLabel];
    [self.view addSubview:self.messageLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
