//
//  SPCProfileHeaderView.h
//  Spayce
//
//  Created by Pavel Dusatko on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCInitialsImageView;
@class SPCProfileDescriptionView;
@class SPCProfileTitleView;

@interface SPCProfileHeaderView : UIView

@property (nonatomic, strong) UIView *headerBackgroundView;
@property (nonatomic, strong) SPCInitialsImageView *profileImageView;
@property (nonatomic, strong) SPCProfileTitleView *titleView;
@property (nonatomic, strong) SPCProfileDescriptionView *descriptionView;
@property (nonatomic, strong) UILabel *textLockedLabel;
@property (nonatomic, strong) UIButton *profileButton;
@property (nonatomic, strong) UIButton *bannerButton;
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *actionButton;


// Configure display values
- (void)configureWithName:(NSString *)name handle:(NSString *)handle isCeleb:(BOOL)isCeleb starCount:(NSInteger)starCount followerCount:(NSInteger)followerCount followingCount:(NSInteger)followingCount isLocked:(BOOL)isLocked;

@end
