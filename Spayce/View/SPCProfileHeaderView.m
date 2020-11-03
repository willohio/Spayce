//
//  SPCProfileHeaderView.m
//  Spayce
//
//  Created by Pavel Dusatko on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileHeaderView.h"

// View
#import "SPCInitialsImageView.h"
#import "SPCProfileDescriptionView.h"
#import "SPCProfileTitleView.h"

// Literals
#import "SPCLiterals.h" // For @"SpayceTeam" handle

@interface SPCProfileHeaderView ()

@property (nonatomic, strong) UIView *overlayView;

@end

@implementation SPCProfileHeaderView

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        // Overlay view
        
        _overlayView = [[UIView alloc] init];
        _overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.15];
        _overlayView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_overlayView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-45]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_overlayView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        // Banner button
        
        _bannerButton = [[UIButton  alloc] init];
        _bannerButton.backgroundColor = [UIColor clearColor];
        _bannerButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_bannerButton];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_bannerButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_bannerButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_bannerButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_bannerButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        // Background view
        
        _headerBackgroundView = [[UIView alloc] init];
        _headerBackgroundView.backgroundColor = [UIColor whiteColor];
        _headerBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_headerBackgroundView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_overlayView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerBackgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_headerBackgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        // Title view
        
        _titleView = [[SPCProfileTitleView alloc] init];
        _titleView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_titleView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_titleView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_titleView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:CGRectGetHeight([UIApplication sharedApplication].statusBarFrame)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_titleView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:CGRectGetWidth(self.frame) - 90 - 20]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_titleView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44.0]];
        
        // Settings button
        
        _settingsButton = [[UIButton alloc] init];
        _settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_settingsButton setImage:[UIImage imageNamed:@"button-settings-white"] forState:UIControlStateNormal];
        [self addSubview:_settingsButton];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_settingsButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:45]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_settingsButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:35]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_settingsButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:5]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_settingsButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:25]];
        
        // Action button
        
        _actionButton = [[UIButton alloc] init];
        _actionButton.backgroundColor = [UIColor clearColor];
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_actionButton setImage:[UIImage imageNamed:@"button-action-vertical-white"] forState:UIControlStateNormal];
        [self addSubview:_actionButton];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:15]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:58]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:58]];
        
        // Profile image
        
        _profileImageView = [[SPCInitialsImageView  alloc] init];
        _profileImageView.backgroundColor = [UIColor clearColor];
        _profileImageView.contentMode = UIViewContentModeScaleAspectFill;
        _profileImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _profileImageView.userInteractionEnabled = YES;
        _profileImageView.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        _profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _profileImageView.layer.borderWidth = 3.0f;
        _profileImageView.layer.masksToBounds = YES;
        [self addSubview:_profileImageView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:74]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:74]];
        
        // Profile button
        
        _profileButton = [[UIButton  alloc] init];
        _profileButton.backgroundColor = [UIColor clearColor];
        _profileButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_profileButton];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_profileButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        // Description view
        
        _descriptionView = [[SPCProfileDescriptionView alloc] init];
        _descriptionView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_descriptionView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_descriptionView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_descriptionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_headerBackgroundView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_descriptionView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_headerBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_descriptionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-_profileImageView.layer.borderWidth]];
        _descriptionView.hidden = YES;
        
        // Profile Locked label - takes the place of the description view on locked profiles
        
        _textLockedLabel = [[UILabel alloc] init];
        _textLockedLabel.adjustsFontSizeToFitWidth = YES;
        _textLockedLabel.minimumScaleFactor = 0.75;
        _textLockedLabel.font = [UIFont spc_regularSystemFontOfSize:14.0f];
        _textLockedLabel.textColor = [UIColor colorWithRGBHex:0x8b99af];
        _textLockedLabel.numberOfLines = 2;
        _textLockedLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_textLockedLabel];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLockedLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLockedLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_headerBackgroundView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLockedLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_headerBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLockedLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_profileImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-_profileImageView.layer.borderWidth]];
        _textLockedLabel.hidden = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutIfNeeded];
    self.profileImageView.layer.cornerRadius = CGRectGetHeight(self.profileImageView.frame)/2.0f;
}

#pragma mark - Configuration

- (void)configureWithName:(NSString *)name handle:(NSString *)handle isCeleb:(BOOL)isCeleb starCount:(NSInteger)starCount followerCount:(NSInteger)followerCount followingCount:(NSInteger)followingCount isLocked:(BOOL)isLocked {
    [self.titleView configureWithName:name handle:handle isCeleb:isCeleb useLightContent:YES];
    if (NSOrderedSame == [handle caseInsensitiveCompare:kSPCSpayceTeamHandle]) {
        [self.descriptionView configureWithInfiniteCounts];
    } else {
        [self.descriptionView configureWithStarCount:starCount followerCount:followerCount followingCount:followingCount buttonsEnabled:!isLocked];
    }
    self.descriptionView.hidden = NO;
}

@end
