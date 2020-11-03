//
//  SPCProfileDescriptionView.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-20.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileDescriptionView.h"

// Model
#import "Person.h"

@interface SPCProfileDescriptionView ()

@property (nonatomic, strong) UILabel *lblFollowers;
@property (nonatomic, strong) UILabel *lblFollowing;
@property (nonatomic, strong) UILabel *lblStars;

@property (nonatomic, strong) UILabel *lblFollowerCount;
@property (nonatomic, strong) UILabel *lblFollowingCount;
@property (nonatomic, strong) UILabel *lblStarCount;

@property (nonatomic, strong) UIButton *btnFollowers;
@property (nonatomic, strong) UIButton *btnFollowing;
@property (nonatomic, strong) UIButton *btnStars;

@end

@implementation SPCProfileDescriptionView

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Count labels
        _lblFollowers = [[UILabel alloc] init];
        _lblFollowers.font = [UIFont fontWithName:@"OpenSans" size:10.0f];
        _lblFollowers.textColor = [UIColor colorWithRGBHex:0xbbbdc1];
        _lblFollowers.textAlignment = NSTextAlignmentCenter;
        _lblFollowers.text = @"Followers";
        [_lblFollowers sizeToFit];
        [self addSubview:_lblFollowers];
        _lblFollowing = [[UILabel alloc] init];
        _lblFollowing.font = [UIFont fontWithName:@"OpenSans" size:10.0f];
        _lblFollowing.textColor = [UIColor colorWithRGBHex:0xbbbdc1];
        _lblFollowing.textAlignment = NSTextAlignmentCenter;
        _lblFollowing.text = @"Following";
        [_lblFollowing sizeToFit];
        [self addSubview:_lblFollowing];
        _lblStars = [[UILabel alloc] init];
        _lblStars.font = [UIFont fontWithName:@"OpenSans" size:10.0f];
        _lblStars.textColor = [UIColor colorWithRGBHex:0xbbbdc1];
        _lblStars.textAlignment = NSTextAlignmentCenter;
        _lblStars.text = @"Stars";
        [_lblStars sizeToFit];
        [self addSubview:_lblStars];
        
        // Counts
        _lblFollowerCount = [[UILabel alloc] init];
        _lblFollowerCount.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _lblFollowerCount.textColor = [UIColor colorWithRGBHex:0x3d3d3d];
        _lblFollowerCount.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblFollowerCount];
        _lblFollowingCount = [[UILabel alloc] init];
        _lblFollowingCount.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _lblFollowingCount.textColor = [UIColor colorWithRGBHex:0x3d3d3d];
        _lblFollowingCount.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblFollowingCount];
        _lblStarCount = [[UILabel alloc] init];
        _lblStarCount.font = [UIFont fontWithName:@"OpenSans-Semibold" size:14.0f];
        _lblStarCount.textColor = [UIColor colorWithRGBHex:0x3d3d3d];
        _lblStarCount.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_lblStarCount];
        
        // Buttons
        _btnFollowers = [[UIButton alloc] init];
        _btnFollowers.backgroundColor = [UIColor clearColor];
        [_btnFollowers addTarget:self action:@selector(tappedFollowersButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnFollowers];
        _btnFollowing = [[UIButton alloc] init];
        _btnFollowing.backgroundColor = [UIColor clearColor];
        [_btnFollowing addTarget:self action:@selector(tappedFollowingButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnFollowing];
        _btnStars = [[UIButton alloc] init];
        _btnStars.backgroundColor = [UIColor clearColor];
        [_btnStars addTarget:self action:@selector(tappedStarsButton:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_btnStars];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat PSD_WIDTH = 560.0f;
    CGFloat PSD_HEIGHT = 48.0f;
    CGFloat viewWidth = CGRectGetWidth(self.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.bounds);
    
    // Labels
    CGFloat labelsCenterY = 40.0f/PSD_HEIGHT * viewHeight;
    self.lblStars.center = CGPointMake(76.0f/PSD_WIDTH * viewWidth, labelsCenterY);
    self.lblFollowers.center = CGPointMake(266.0f/PSD_WIDTH * viewWidth, labelsCenterY);
    self.lblFollowing.center = CGPointMake(461.0f/PSD_WIDTH * viewWidth, labelsCenterY);
    // These CGRectIntegral calls do make a difference
    self.lblStars.frame = CGRectIntegral(self.lblStars.frame);
    self.lblFollowers.frame = CGRectIntegral(self.lblFollowers.frame);
    self.lblFollowing.frame = CGRectIntegral(self.lblFollowing.frame);
    
    // Counts
    CGFloat countsCenterY = 10.0f/PSD_HEIGHT * viewHeight;
    [self.lblFollowerCount sizeToFit];
    [self.lblFollowingCount sizeToFit];
    [self.lblStarCount sizeToFit];
    self.lblStarCount.center = CGPointMake(76.0f/PSD_WIDTH * viewWidth, countsCenterY);
    self.lblFollowerCount.center = CGPointMake(266.0f/PSD_WIDTH * viewWidth, countsCenterY);
    self.lblFollowingCount.center = CGPointMake(461.0f/PSD_WIDTH * viewWidth, countsCenterY);
    self.lblFollowerCount.frame = CGRectIntegral(self.lblFollowerCount.frame);
    self.lblFollowingCount.frame = CGRectIntegral(self.lblFollowingCount.frame);
    self.lblStarCount.frame = CGRectIntegral(self.lblStarCount.frame);
    
    // Buttons
    CGFloat btnHeight = CGRectGetHeight(self.bounds);
    CGFloat btnStarsEnd = (self.lblFollowers.center.x + self.lblStars.center.x)/2.0f;
    self.btnStars.frame = CGRectMake(0, 0, btnStarsEnd, btnHeight);
    CGFloat btnFollowersEnd = (self.lblFollowing.center.x + self.lblFollowers.center.x)/2.0f;
    self.btnFollowers.frame = CGRectMake(btnStarsEnd, 0, btnFollowersEnd - btnStarsEnd, btnHeight);
    CGFloat btnFollowingEnd = 	CGRectGetWidth(self.bounds);
    self.btnFollowing.frame = CGRectMake(btnFollowersEnd, 0, btnFollowingEnd - btnFollowersEnd, btnHeight);
}

#pragma mark - Configuration

- (void)configureWithStarCount:(NSInteger)starCount followerCount:(NSInteger)followerCount followingCount:(NSInteger)followingCount buttonsEnabled:(BOOL)buttonsEnabled {
    self.btnStars.enabled = buttonsEnabled;
    self.btnFollowers.enabled = buttonsEnabled;
    self.btnFollowing.enabled = buttonsEnabled;
    
    self.lblFollowerCount.text = [NSString stringWithFormat:@"%lu", followerCount];
    self.lblFollowingCount.text = [NSString stringWithFormat:@"%lu", followingCount];
    self.lblStarCount.text = [NSString stringWithFormat:@"%lu", starCount];
    
    self.lblFollowers.alpha = self.lblFollowing.alpha = self.lblStars.alpha = self.lblFollowerCount.alpha = self.lblFollowingCount.alpha = self.lblStarCount.alpha = buttonsEnabled ? 1.0 : 0.5;
    
    [self setNeedsLayout];
}

- (void)configureWithInfiniteCounts {
    self.btnStars.enabled = NO;
    self.btnFollowers.enabled = NO;
    self.btnFollowing.enabled = NO;
    
    self.lblFollowerCount.text = @"∞";
    self.lblFollowingCount.text = @"∞";
    self.lblStarCount.text = @"∞";
    
    [self setNeedsLayout];
}

#pragma mark - Target-Actions

- (void)tappedStarsButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedDescriptionType:onDescriptionView:)]) {
        [self.delegate tappedDescriptionType:SPCProfileDescriptionTypeStars onDescriptionView:self];
    }
}

- (void)tappedFollowersButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedDescriptionType:onDescriptionView:)]) {
        [self.delegate tappedDescriptionType:SPCProfileDescriptionTypeFollowers onDescriptionView:self];
    }
}

- (void)tappedFollowingButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedDescriptionType:onDescriptionView:)]) {
        [self.delegate tappedDescriptionType:SPCProfileDescriptionTypeFollowing onDescriptionView:self];
    }
}

@end
