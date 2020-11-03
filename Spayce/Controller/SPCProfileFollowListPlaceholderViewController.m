//
//  SPCFollowListPlaceholderViewController.m
//  Spayce
//
//  Created by Jake Rosin on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCProfileFollowListPlaceholderViewController.h"

// Controller
#import "SPCProfileFollowListViewController.h"

// Enums
#import "Enums.h"

// Model
#import "UserProfile.h"
#import "ProfileDetail.h"


@interface SPCFollowListPlaceholderViewController ()

// Data
@property (nonatomic, strong) UserProfile *userProfile;
@property (nonatomic, assign) SPCFollowListType followListType;

// UI
@property (nonatomic, strong) UIView *customNavigationBar;
@property (nonatomic, strong) UILabel *messageTitleLabel;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation SPCFollowListPlaceholderViewController

#pragma mark Object Lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFollowListType:(SPCFollowListType)followListType userProfile:(UserProfile *)userProfile {
    self = [super init];
    if (self) {
        self.followListType = followListType;
        self.userProfile = userProfile;
    }
    return self;
}

#pragma mark - Accessors

- (UIView *)customNavigationBar {
    if (!_customNavigationBar) {
        _customNavigationBar = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(self.view.frame), 70)];
        _customNavigationBar.backgroundColor = [UIColor whiteColor];
        _customNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 15, 60, 60)];
        [backBtn addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchDown];
        [backBtn setBackgroundImage:[UIImage imageNamed:@"mamBackToCapture"] forState:UIControlStateNormal];
        [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
        
        NSString *titleText = @"UNAVAILABLE"; // default
        if (SPCFollowListTypeUserFollowers == self.followListType) {
            titleText = NSLocalizedString(@"Followers", nil);
        } else if (SPCFollowListTypeUserFollows == self.followListType) {
            titleText = NSLocalizedString(@"Following", nil);
        }
        
        UILabel *titleLbl  = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.view.bounds.size.width - 140, 50)];
        titleLbl.text = [SPCProfileFollowListViewController titleForFollowListType:self.followListType];
        titleLbl.font = [UIFont fontWithName:@"OpenSans-SemiBold" size:16];
        titleLbl.textAlignment = NSTextAlignmentCenter;
        titleLbl.center = CGPointMake(self.view.bounds.size.width/2, titleLbl.center.y);
        
        [_customNavigationBar addSubview:backBtn];
        [_customNavigationBar addSubview:titleLbl];
    }
    return _customNavigationBar;
}

- (UILabel *)messageTitleLabel {
    if (!_messageTitleLabel) {
        NSString *message = @"Unavailable"; // default
        if (SPCFollowListTypeUserFollowers == self.followListType || SPCFollowListTypeUserFollows == self.followListType) {
            message = NSLocalizedString(@"Hang On!", nil);
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
        
        if (SPCFollowListTypeUserFollowers == self.followListType) {
            message = [NSString stringWithFormat:@"Follow %@ to see their followers.", self.userProfile.profileDetail.firstname];
        } else if (SPCFollowListTypeUserFollows == self.followListType) {
            message = [NSString stringWithFormat:@"Follow %@ to see the who they follow.", self.userProfile.profileDetail.firstname];
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
