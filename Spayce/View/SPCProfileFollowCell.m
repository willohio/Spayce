//
//  SPCProfileFollowCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 8/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileFollowCell.h"

@interface SPCProfileFollowCell ()

@property (nonatomic, strong) UIView *customBackgroundView;
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *titleSeparatorView;
@property (nonatomic, strong) UIView *followersView;
@property (nonatomic, strong) UIView *followingView;
@property (nonatomic, strong) UIView *verticalSeparatorView;
@property (nonatomic, strong) UILabel *followersLabel;
@property (nonatomic, strong) UILabel *followingLabel;
@property (nonatomic, strong) UIButton *followersButton;
@property (nonatomic, strong) UIButton *followingButton;
@property (nonatomic, strong) NSLayoutConstraint *followersRightConstraint;

@end

@implementation SPCProfileFollowCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customBackgroundView = [[UIView alloc] init];
        _customBackgroundView.backgroundColor = [UIColor whiteColor];
        _customBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        _customBackgroundView.layer.masksToBounds = NO;
        _customBackgroundView.layer.cornerRadius = 2;
        _customBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
        _customBackgroundView.layer.shadowOpacity = 0.2;
        _customBackgroundView.layer.shadowRadius = 0.5;
        _customBackgroundView.layer.shadowOffset = CGSizeMake(0, 1);
        _customBackgroundView.layer.shouldRasterize = YES;
        _customBackgroundView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        [self.contentView addSubview:_customBackgroundView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.clipsToBounds = YES;
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.cornerRadius = 2;
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = NSLocalizedString(@"People", nil);
        _titleLabel.font = [UIFont spc_profileInfo_boldSectionFont];
        _titleLabel.textColor = [UIColor colorWithWhite:159.0/255.0 alpha:1.0];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_titleLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_titleLabel.font.lineHeight]];

        _titleSeparatorView = [[UIView alloc] init];
        _titleSeparatorView.backgroundColor = [UIColor colorWithWhite:231.0/255.0 alpha:1.0];
        _titleSeparatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_titleSeparatorView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationLessThanOrEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:35]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleSeparatorView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.5]];

        _followersView = [[UIView alloc] init];
        _followersView.backgroundColor = [UIColor whiteColor];
        _followersView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_followersView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followersView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleSeparatorView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followersView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followersView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];

        _followersRightConstraint = [NSLayoutConstraint constraintWithItem:_followersView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-1];
        [_customContentView addConstraint:_followersRightConstraint];

        UILabel *followersTitleLabel = [[UILabel alloc] init];
        followersTitleLabel.font = [UIFont spc_lightFont];
        followersTitleLabel.text = NSLocalizedString(@"Followers", nil);
        followersTitleLabel.textAlignment = NSTextAlignmentCenter;
        followersTitleLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        followersTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_followersView addSubview:followersTitleLabel];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:followersTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:2]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:followersTitleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:followersTitleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:followersTitleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:followersTitleLabel.font.lineHeight]];

        _followersLabel = [[UILabel alloc] init];
        _followersLabel.font = [UIFont spc_boldFont];
        _followersLabel.textAlignment = NSTextAlignmentCenter;
        _followersLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_followersView addSubview:_followersLabel];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-2]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_followersLabel.font.lineHeight]];

        _followersButton = [[UIButton alloc] init];
        _followersButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_followersView addSubview:_followersButton];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_followersView addConstraint:[NSLayoutConstraint constraintWithItem:_followersButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];

        _verticalSeparatorView = [[UIView alloc] init];
        _verticalSeparatorView.backgroundColor = [UIColor colorWithWhite:231.0/255.0 alpha:1.0];
        _verticalSeparatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_verticalSeparatorView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_verticalSeparatorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleSeparatorView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_verticalSeparatorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_verticalSeparatorView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_verticalSeparatorView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.5]];
        
        _followingView = [[UIView alloc] init];
        _followingView.backgroundColor = [UIColor whiteColor];
        _followingView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_followingView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followingView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleSeparatorView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followingView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followersView attribute:NSLayoutAttributeRight multiplier:1.0 constant:2]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followingView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_followingView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        UILabel *followingTitleLabel = [[UILabel alloc] init];
        followingTitleLabel.font = [UIFont spc_lightFont];
        followingTitleLabel.text = NSLocalizedString(@"Following", nil);
        followingTitleLabel.textAlignment = NSTextAlignmentCenter;
        followingTitleLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        followingTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_followingView addSubview:followingTitleLabel];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:followingTitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:2]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:followingTitleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:followingTitleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:followingTitleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:followingTitleLabel.font.lineHeight]];
        
        _followingLabel = [[UILabel alloc] init];
        _followingLabel.font = [UIFont spc_boldFont];
        _followingLabel.textAlignment = NSTextAlignmentCenter;
        _followingLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_followingView addSubview:_followingLabel];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-2]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_followingLabel.font.lineHeight]];
        
        _followingButton = [[UIButton alloc] init];
        _followingButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_followingView addSubview:_followingButton];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_followingView addConstraint:[NSLayoutConstraint constraintWithItem:_followingButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_followingView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    self.followersLabel.text = nil;
    self.followingLabel.text = nil;
}

#pragma mark - Configuration

- (void)configureWithFollowersCount:(NSInteger)followersCount followingCount:(NSInteger)followingCount {
    // Update labels
    self.followersLabel.text = [NSString stringWithFormat:@"%@", @(followersCount)];
    self.followingLabel.text = [NSString stringWithFormat:@"%@", @(followingCount)];
    
    // Update layout
    [self.customContentView removeConstraint:self.followersRightConstraint];
    
    if (followersCount > 0) {
        self.followersRightConstraint = [NSLayoutConstraint constraintWithItem:self.followersView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:-1];
    }
    else {
        self.followersRightConstraint = [NSLayoutConstraint constraintWithItem:self.followersView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    }
    
    [self.customContentView addConstraint:self.followersRightConstraint];
    [self.followersView setNeedsUpdateConstraints];
}

- (void)configureWithFollowersTarget:(id)target action:(SEL)action {
    [self.followersButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.followersButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureWithFollowingTarget:(id)target action:(SEL)action {
    [self.followingButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.followingButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

@end
