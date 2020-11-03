//
//  SPCPeopleFinderCollectionViewCell.m
//  Spayce
//
//  Created by Jordan Perry on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCPeopleFinderCollectionViewCell.h"

#import "Asset.h"
#import "Enums.h"
#import "Person.h"
#import "SocialProfile.h"
#import "SPCInitialsImageView.h"

CGFloat const SPCPeopleFinderCollectionViewCellFollowButtonWidth = 90.0;

@interface SPCPeopleFinderCollectionViewCell ()

@property (nonatomic, strong) SPCInitialsImageView *profileImageView;
@property (nonatomic, strong) UIButton *profileImageButton;
@property (nonatomic, strong) UIImageView *celebCheckmark;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *starImageView;
@property (nonatomic, strong) UILabel *reputationOrFollowStatusLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIImageView *followButtonImageView;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation SPCPeopleFinderCollectionViewCell

#pragma mark - Creation, Destroy

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        _profileImageView = [[SPCInitialsImageView alloc] init];
        _profileImageView.clipsToBounds = YES;
        [self.contentView addSubview:_profileImageView];
        
        _profileImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_profileImageButton addTarget:self action:@selector(profileImageSelected:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_profileImageButton];
        
        _celebCheckmark = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-celeb-large"]];
        _celebCheckmark.backgroundColor = [UIColor whiteColor];
        _celebCheckmark.contentMode = UIViewContentModeCenter;
        _celebCheckmark.clipsToBounds = YES;
        [self.contentView addSubview:_celebCheckmark];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        _nameLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:10.0];
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nameLabel.minimumScaleFactor = 0.5;
        _nameLabel.numberOfLines = 1;
        _nameLabel.textColor = [UIColor colorWithRed:38.0/255.0 green:38.0/255.0 blue:38.0/255.0 alpha:1.0];
        [self.contentView addSubview:_nameLabel];
        
        _starImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-gray-xxx-small"]];
        [self.contentView addSubview:_starImageView];
        
        _reputationOrFollowStatusLabel = [[UILabel alloc] init];
        _reputationOrFollowStatusLabel.font = [UIFont fontWithName:@"OpenSans" size:8.0];
        _reputationOrFollowStatusLabel.minimumScaleFactor = 0.5;
        _reputationOrFollowStatusLabel.numberOfLines = 1;
        _reputationOrFollowStatusLabel.textColor = [UIColor colorWithRed:187.0/255.0 green:189.0/255.0 blue:193.0/255.0 alpha:1.0];
        [self.contentView addSubview:_reputationOrFollowStatusLabel];
        
        _followButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _followButton.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(frame), 25.0);
        _followButton.layer.cornerRadius = 3;
        _followButton.layer.borderWidth = 1.0;
        [_followButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:11.0]];
        [_followButton addTarget:self action:@selector(followButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_followButton];
        
        _followButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus-blue-small"]];
        _followButtonImageView.clipsToBounds = YES;
        _followButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
        _followButtonImageView.frame = CGRectMake(0.0, 0.0, 8.0, 8.0);
        _followButtonImageView.userInteractionEnabled = NO;
        [_followButton addSubview:_followButtonImageView];
        
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        _separatorView.hidden = YES;
        [self.contentView addSubview:_separatorView];
    }
    
    return self;
}

- (void)dealloc {
    
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.person && !self.socialProfile) {
        return;
    }
    
    if (self.person) {
        [self configureWithPerson:self.person];
    } else {
        [self configureWithSocialProfile:self.socialProfile];
    }
    
    if (self.person) {
        self.profileImageView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.contentView.bounds), CGRectGetWidth(self.contentView.bounds));
        self.profileImageView.layer.cornerRadius = CGRectGetWidth(self.profileImageView.frame) / 2.0;
        self.profileImageButton.frame = self.profileImageView.frame;
        
        self.celebCheckmark.frame = CGRectMake(0.0, CGRectGetMaxY(self.profileImageView.frame) - 15.0, 25.0, 25.0);
        self.celebCheckmark.center = CGPointMake(self.profileImageView.center.x, self.celebCheckmark.center.y);
        self.celebCheckmark.layer.cornerRadius = CGRectGetWidth(self.celebCheckmark.frame) / 2.0;
        
        CGFloat maxLabelWidth = CGRectGetWidth(self.contentView.bounds) - 10.0;
        CGFloat labelCenterX = CGRectGetWidth(self.contentView.bounds) / 2.0;
        
        [self.nameLabel sizeToFit];
        CGRect nameLabelFrame = self.nameLabel.frame;
        nameLabelFrame.origin.y = CGRectGetMaxY(self.celebCheckmark.frame);
        nameLabelFrame.size.width = MIN(CGRectGetWidth(nameLabelFrame), maxLabelWidth);
        self.nameLabel.frame = nameLabelFrame;
        self.nameLabel.center = CGPointMake(labelCenterX, self.nameLabel.center.y);
        
        CGFloat starWidth = 8.0;
        CGFloat starPadding = 2.0;
        if (self.person.followerStatus == FollowingStatusFollowing) {
            starWidth = 0.0;
            starPadding = 0.0;
        }
        
        [self.reputationOrFollowStatusLabel sizeToFit];
        CGRect reputationOrFollowStatusLabelFrame = self.reputationOrFollowStatusLabel.frame;
        reputationOrFollowStatusLabelFrame.origin.y = CGRectGetMaxY(self.nameLabel.frame);
        reputationOrFollowStatusLabelFrame.size.width = MIN(CGRectGetWidth(reputationOrFollowStatusLabelFrame), maxLabelWidth - (starWidth + starPadding));
        self.reputationOrFollowStatusLabel.frame = reputationOrFollowStatusLabelFrame;
        self.reputationOrFollowStatusLabel.center = CGPointMake(labelCenterX + ((starWidth + starPadding) / 2.0), self.reputationOrFollowStatusLabel.center.y);
        
        CGRect starImageViewFrame = self.starImageView.frame;
        starImageViewFrame.origin.x = CGRectGetMinX(self.reputationOrFollowStatusLabel.frame) - (starWidth + starPadding);
        starImageViewFrame.size = CGSizeMake(starWidth, starWidth);
        self.starImageView.frame = starImageViewFrame;
        self.starImageView.center = CGPointMake(self.starImageView.center.x, self.reputationOrFollowStatusLabel.center.y);
        
        CGRect followButtonFrame = self.followButton.frame;
        followButtonFrame.origin.x = 0.0;
        followButtonFrame.origin.y = CGRectGetMaxY(self.reputationOrFollowStatusLabel.frame) + 2.0;
        followButtonFrame.size.width = SPCPeopleFinderCollectionViewCellFollowButtonWidth;
        self.followButton.frame = followButtonFrame;
        
        [self.followButtonImageView sizeToFit];
        CGFloat followButtonImageViewWidth = CGRectGetWidth(self.followButtonImageView.frame);
        [self.followButton setTitleEdgeInsets:UIEdgeInsetsMake(0, followButtonImageViewWidth + 4.0, 0, 0)];
        [self.followButton layoutIfNeeded];
        self.followButtonImageView.center = CGPointMake(CGRectGetMinX(self.followButton.titleLabel.frame) - followButtonImageViewWidth / 2.0f - 4.0f, self.followButton.titleLabel.center.y);
        
        CGFloat height = 1.0 / [[UIScreen mainScreen] scale];
        self.separatorView.frame = CGRectMake(0.0, CGRectGetHeight(self.contentView.bounds) - height, CGRectGetWidth(self.contentView.bounds), height);
    } else {
        self.profileImageView.frame = CGRectMake(10.0, 10.0, CGRectGetHeight(CGRectInset(self.contentView.bounds, 10.0, 10.0)), CGRectGetHeight(CGRectInset(self.contentView.bounds, 10.0, 10.0)));
        self.profileImageView.layer.cornerRadius = CGRectGetWidth(self.profileImageView.frame) / 2.0;
        self.profileImageButton.frame = self.profileImageView.frame;
        
        self.celebCheckmark.frame = CGRectZero;
        
        CGFloat maxLabelWidth = CGRectGetWidth(self.contentView.bounds) - CGRectGetMaxX(self.profileImageView.frame) - CGRectGetWidth(self.followButton.frame) - 20.0;
        
        [self.nameLabel sizeToFit];
        CGRect nameLabelFrame = self.nameLabel.frame;
        nameLabelFrame.origin.x = CGRectGetMaxX(self.profileImageView.frame) + 5.0;
        nameLabelFrame.origin.y = self.profileImageView.center.y - CGRectGetHeight(self.nameLabel.frame);
        nameLabelFrame.size.width = MIN(CGRectGetWidth(nameLabelFrame), maxLabelWidth);
        self.nameLabel.frame = nameLabelFrame;
        
        [self.reputationOrFollowStatusLabel sizeToFit];
        CGRect reputationOrFollowStatusLabelFrame = self.reputationOrFollowStatusLabel.frame;
        reputationOrFollowStatusLabelFrame.origin.x = CGRectGetMinX(self.nameLabel.frame);
        reputationOrFollowStatusLabelFrame.origin.y = CGRectGetMaxY(self.nameLabel.frame);
        reputationOrFollowStatusLabelFrame.size.width = MIN(CGRectGetWidth(reputationOrFollowStatusLabelFrame), maxLabelWidth);
        self.reputationOrFollowStatusLabel.frame = reputationOrFollowStatusLabelFrame;
        
        self.starImageView.frame = CGRectZero;
        
        CGRect followButtonFrame = self.followButton.frame;
        followButtonFrame.origin.x = CGRectGetWidth(self.contentView.bounds) - CGRectGetWidth(followButtonFrame) - 10.0;
        followButtonFrame.size.width = SPCPeopleFinderCollectionViewCellFollowButtonWidth;
        self.followButton.frame = followButtonFrame;
        self.followButton.center = CGPointMake(self.followButton.center.x, CGRectGetHeight(self.contentView.bounds) / 2.0);
        
        [self.followButtonImageView sizeToFit];
        CGFloat followButtonImageViewWidth = CGRectGetWidth(self.followButtonImageView.frame);
        [self.followButton setTitleEdgeInsets:UIEdgeInsetsMake(0, followButtonImageViewWidth + 4.0, 0, 0)];
        [self.followButton layoutIfNeeded];
        self.followButtonImageView.center = CGPointMake(CGRectGetMinX(self.followButton.titleLabel.frame) - followButtonImageViewWidth / 2.0f - 4.0f, self.followButton.titleLabel.center.y);
        
        CGFloat height = 1.0 / [[UIScreen mainScreen] scale];
        self.separatorView.frame = CGRectMake(0.0, CGRectGetHeight(self.contentView.bounds) - height, CGRectGetWidth(self.contentView.bounds), height);
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.person = nil;
    self.socialProfile = nil;
    
    [self.profileImageView prepareForReuse];
    
    // Even though it is highly unlikely to occur, the
    // thought here is that we probably don't even want
    // this flashing for any amount of time as a celebrity
    // account due to reuse issues, so the hidden state
    // should be treated as the default state.
    self.celebCheckmark.hidden = YES;
    
    self.nameLabel.text = @"";
    
    self.reputationOrFollowStatusLabel.text = @"";
    
    self.separatorView.hidden = YES;
}

#pragma mark - Contextual Configuration

- (void)setPerson:(Person *)person {
    _person = person;
    
    if (person) {
        [self setNeedsLayout];
    }
}

- (void)setSocialProfile:(SocialProfile *)socialProfile {
    _socialProfile = socialProfile;
    
    if (socialProfile) {
        [self setNeedsLayout];
    }
}

- (void)configureWithPerson:(Person *)person {
    NSString *firstInitial = [person.firstname length] > 0 ? [person.firstname substringToIndex:1] : @"";
    NSString *lastInitial = [person.lastname length] > 0 ? [person.lastname substringToIndex:1] : @"";
    NSURL *url = [NSURL URLWithString:person.imageAsset.imageUrlHalfSquare];
    [self.profileImageView configureWithText:[NSString stringWithFormat:@"%@%@", firstInitial, lastInitial]
                                         url:url];
    
    self.celebCheckmark.hidden = !person.isCeleb;
    
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", person.firstname ?: @"", person.lastname ?: @""];
    
    if (person.followerStatus == FollowingStatusFollowing) {
        self.reputationOrFollowStatusLabel.text = @"FOLLOWS YOU";
    } else {
        self.reputationOrFollowStatusLabel.text = [NSString stringWithFormat:@"%@", @(person.starCount)];
    }
    
    [self configureFollowButtonWithPerson:person];
}

- (void)configureFollowButtonWithPerson:(Person *)person {
    switch (person.followingStatus) {
        case FollowingStatusRequested:
            [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x898989]
                                             fillColor:[UIColor colorWithRGBHex:0x898989]
                                                 image:[UIImage imageNamed:@"lock-white-outline-small"]
                                             titleText:NSLocalizedString(@"REQUESTED", nil)
                                            titleColor:[UIColor whiteColor]
                                            setEnabled:NO
                                          andSetHidden:NO];
            break;
        case FollowingStatusFollowing:
            [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                             fillColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                 image:[UIImage imageNamed:@"check-white-small"]
                                             titleText:NSLocalizedString(@"FOLLOWING", nil)
                                            titleColor:[UIColor whiteColor]
                                            setEnabled:YES
                                          andSetHidden:NO];
            break;
        case FollowingStatusNotFollowing:
        default:
            [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                             fillColor:[UIColor whiteColor]
                                                 image:[UIImage imageNamed:@"plus-blue-xsmall"]
                                             titleText:NSLocalizedString(@"FOLLOW", nil)
                                            titleColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                            setEnabled:YES
                                          andSetHidden:NO];
            break;
    }
}

- (void)configureFollowButtonWithBorderColor:(UIColor *)borderColor fillColor:(UIColor *)fillColor image:(UIImage *)image titleText:(NSString *)titleText titleColor:(UIColor *)titleColor setEnabled:(BOOL)setEnabled andSetHidden:(BOOL)setHidden {

    [self.followButton setTitle:titleText forState:UIControlStateNormal];
    [self.followButton setTitleColor:titleColor forState:UIControlStateNormal];
    self.followButton.layer.borderColor = borderColor.CGColor;
    self.followButton.backgroundColor = fillColor;
    
    self.followButtonImageView.image = image;
    
    self.followButton.enabled = setEnabled;
    self.followButton.hidden = setHidden;
}

- (void)configureWithSocialProfile:(SocialProfile *)socialProfile {
    NSString *firstInitial = [socialProfile.firstname length] > 0 ? [socialProfile.firstname substringToIndex:1] : @"";
    NSString *lastInitial = [socialProfile.lastname length] > 0 ? [socialProfile.lastname substringToIndex:1] : @"";
    NSURL *url = [NSURL URLWithString:socialProfile.person.imageAsset.imageUrlHalfSquare ?: @""];
    [self.profileImageView configureWithText:[NSString stringWithFormat:@"%@%@", firstInitial, lastInitial]
                                         url:url];
    
    self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", socialProfile.firstname ?: @"", socialProfile.lastname ?: @""];
    
    NSString *handle = socialProfile.person.handle ?: @"";
    if ([handle length] && ![handle hasPrefix:@"@"]) {
        handle = [@"@" stringByAppendingString:handle];
    }
    self.reputationOrFollowStatusLabel.text = handle;
    
    if (socialProfile.person) {
        [self configureFollowButtonWithPerson:socialProfile.person];
    } else {
        switch (socialProfile.followingStatus) {
            case FollowingStatusFollowing:
            case FollowingStatusRequested:
                [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                 fillColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                     image:[UIImage imageNamed:@"friendship-status-invite-sent"]
                                                 titleText:NSLocalizedString(@"SENT!", nil)
                                                titleColor:[UIColor whiteColor]
                                                setEnabled:NO
                                              andSetHidden:NO];
                break;
            default:
                if (socialProfile.invited) {
                    [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                     fillColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                         image:[UIImage imageNamed:@"friendship-status-invite-sent"]
                                                     titleText:NSLocalizedString(@"SENT!", nil)
                                                    titleColor:[UIColor whiteColor]
                                                    setEnabled:NO
                                                  andSetHidden:NO];
                } else {
                    [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                     fillColor:[UIColor whiteColor]
                                                         image:[UIImage imageNamed:@"friendship-status-invite-blue"]
                                                     titleText:NSLocalizedString(@"Invite", nil)
                                                    titleColor:[UIColor colorWithRGBHex:0x4cb0fb]
                                                    setEnabled:YES
                                                  andSetHidden:NO];
                }
                break;
        }
    }
    
    self.separatorView.hidden = NO;
}

#pragma mark - Actions

- (void)profileImageSelected:(UIButton *)sender {
    if (self.person || self.socialProfile.person) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(peopleFinderCollectionViewCell:profileImageSelectedForPerson:)]) {
            [self.delegate peopleFinderCollectionViewCell:self profileImageSelectedForPerson:self.person ?: self.socialProfile.person];
        }
    }
}

- (void)followButtonPressed:(UIButton *)sender {
    if (self.person || self.socialProfile.person) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(peopleFinderCollectionViewCell:followButtonSelectedForPerson:)]) {
            sender.enabled = NO;
            
            [self.delegate peopleFinderCollectionViewCell:self followButtonSelectedForPerson:self.person ?: self.socialProfile.person];
        }
    } else if (self.socialProfile) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(peopleFinderCollectionViewCell:inviteButtonSelectedForSocialProfile:)]) {
            sender.enabled = NO;
            
            [self.delegate peopleFinderCollectionViewCell:self inviteButtonSelectedForSocialProfile:self.socialProfile];
        }
    }
}

@end
