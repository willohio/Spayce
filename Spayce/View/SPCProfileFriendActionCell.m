//
//  SPCProfileFriendActionCell.m
//  Spayce
//
//  Created by William Santiago on 2014-10-24.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileFriendActionCell.h"

@interface SPCProfileFriendActionCell ()

// Data
@property (nonatomic, weak) id dataSource;
@property (nonatomic, strong) NSString *name;

// Temporary pointers to icons that are not permanent throughout the life of the view
@property (nonatomic, weak) UIImageView *ivLeftButtonIcon;
@property (nonatomic, weak) UIImageView *ivRightButtonIcon;
@property (nonatomic, weak) UIImageView *ivLargeButtonIcon;

// Internal 'model' variables
@property (nonatomic, assign) FollowingStatus followingStatus;
@property (nonatomic, assign) FollowingStatus followerStatus;
@property (nonatomic) BOOL isUserProfileLocked;

// Internal 'state' variables
@property (nonatomic) enum LeftRightButtonSize buttonSizes;

@end

@implementation SPCProfileFriendActionCell

typedef enum LeftRightButtonSize {
    LeftRightButtonSizeLargeLeft,
    LeftRightButtonSizeLargeRight
} LeftRightButtonSize;

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _btnLarge = [[UIButton alloc] init];
        _btnLarge.layer.cornerRadius = 6.0f;
        _btnLarge.layer.borderWidth = 1.0f;
        _btnLarge.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        [self.contentView addSubview:_btnLarge];
        
        _btnLeft = [[UIButton alloc] init];
        _btnLeft.layer.cornerRadius = 6.0f;
        _btnLeft.layer.borderWidth = 1.0f;
        _btnLeft.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        [self.contentView addSubview:_btnLeft];
        
        _btnRight = [[UIButton alloc] init];
        _btnRight.layer.cornerRadius = 6.0f;
        _btnRight.layer.borderWidth = 1.0f;
        _btnRight.titleLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
        _btnRight.backgroundColor = [UIColor colorWithRGBHex:0x4cb0fb];
        [_btnRight setTitle:NSLocalizedString(@"FOLLOWING", nil) forState:UIControlStateNormal];
        [_btnRight setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.contentView addSubview:_btnRight];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.dataSource = nil;
    self.name = nil;

    // Buttons
    self.btnLarge.hidden = YES;
    self.btnLeft.hidden = YES;
    self.btnRight.hidden = YES;
    [self.ivLeftButtonIcon removeFromSuperview];
    [self.ivLargeButtonIcon removeFromSuperview];
    [self.ivRightButtonIcon removeFromSuperview];
    // Remove targets
    [self.btnLarge removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.btnLeft removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.btnRight removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    // Set up buttons
    CGFloat leftRightPadding = 10.0f;
    CGFloat topBottomPadding = 7.5f;
    CGFloat buttonsWidth = CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding;
    CGFloat buttonsHeight = CGRectGetHeight(self.contentView.bounds) - 2 * topBottomPadding;
    
    self.btnLarge.frame = CGRectMake(leftRightPadding, topBottomPadding, buttonsWidth, buttonsHeight);
    
    CGFloat totalButtonPSDWidth = 710.0f;
    CGFloat leftButtonPSDWidth = LeftRightButtonSizeLargeLeft == self.buttonSizes ? 470.0f : 220.0f;
    CGFloat rightButtonPSDWidth = totalButtonPSDWidth - leftButtonPSDWidth;

    CGFloat btnLeftWidth = leftButtonPSDWidth/totalButtonPSDWidth * buttonsWidth - leftRightPadding/2.0f;
    self.btnLeft.frame = CGRectMake(leftRightPadding, topBottomPadding, btnLeftWidth, buttonsHeight);
    
    CGFloat btnRightWidth = rightButtonPSDWidth/totalButtonPSDWidth * buttonsWidth - leftRightPadding/2.0f;
    self.btnRight.frame = CGRectMake(CGRectGetMaxX(self.btnLeft.frame) + leftRightPadding, topBottomPadding, btnRightWidth, buttonsHeight);
    
    CGFloat iconToTextSpacing = 3.0f;
    // Set the right button's icon/text placement - This guy's text doesn't change
    CGSize sizeBtnRightText = [self.btnRight.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.btnRight.titleLabel.font }];
    CGFloat btnRightLabelInsetLeft = self.ivRightButtonIcon.image.size.width + iconToTextSpacing;
    [self.btnRight setTitleEdgeInsets:UIEdgeInsetsMake(0, btnRightLabelInsetLeft, 0, 0)];
    self.ivRightButtonIcon.center = CGPointMake(round(CGRectGetWidth(self.btnRight.bounds)/2.0f - sizeBtnRightText.width/2.0f - iconToTextSpacing), round(self.btnRight.titleLabel.center.y + 1.0/[UIScreen mainScreen].scale));
    
    // Set the left button's icon/text placement
    CGSize sizeBtnLeftText = [self.btnLeft.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.btnLeft.titleLabel.font }];
    CGFloat btnLeftLabelInsetLeft = self.ivLeftButtonIcon.image.size.width + iconToTextSpacing;
    [self.btnLeft setTitleEdgeInsets:UIEdgeInsetsMake(0, btnLeftLabelInsetLeft, 0, 0)];
    self.ivLeftButtonIcon.center = CGPointMake(round(CGRectGetWidth(self.btnLeft.bounds)/2.0f - sizeBtnLeftText.width/2.0f - iconToTextSpacing), round(self.btnLeft.titleLabel.center.y + 1.0/[UIScreen mainScreen].scale));
    
    // Set the large button's icon/text placement
    CGSize sizeBtnLargeText = [self.btnLarge.titleLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.btnLarge.titleLabel.font }];
    CGFloat btnLargeLabelInsetLeft = self.ivLargeButtonIcon.image.size.width + iconToTextSpacing;
    [self.btnLarge setTitleEdgeInsets:UIEdgeInsetsMake(0, btnLargeLabelInsetLeft, 0, 0)];
    self.ivLargeButtonIcon.center = CGPointMake(round(CGRectGetWidth(self.btnLarge.bounds)/2.0f - sizeBtnLargeText.width/2.0f - iconToTextSpacing), round(self.btnLarge.titleLabel.center.y + 1.0/[UIScreen mainScreen].scale));
}

#pragma mark - Configuration

- (void)configureWithName:(NSString *)name followingStatus:(FollowingStatus)followingStatus followerStatus:(FollowingStatus)followerStatus isUserCeleb:(BOOL)isUserCeleb isUserProfileLocked:(BOOL)isUserProfileLocked {
    
    self.followingStatus = followingStatus;
    self.isUserProfileLocked = isUserProfileLocked;
    
    // Set our default leftRightButtonSize state
    self.buttonSizes = LeftRightButtonSizeLargeLeft;
    
    // The cases in which following/followerStatus is blocked or unknown, this cell should not be displayed
    switch (followingStatus) {
        case FollowingStatusFollowing:
            switch (followerStatus) {
                case FollowingStatusFollowing:
                    [self.btnRight addTarget:self action:@selector(changeFollowingStatus:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLeftRightButtonsWithLeftBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] leftFillColor:[UIColor whiteColor] leftImage:[UIImage imageNamed:@"chat-bubble-icon-blue"] leftTitleText:NSLocalizedString(@"CHAT", nil) leftTitleColor:[UIColor colorWithRGBHex:0x4cb0fb] rightBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] rightFillColor:[UIColor colorWithRGBHex:0x4cb0fb] rightImage:[UIImage imageNamed:@"check-white-small"] rightTitleText:NSLocalizedString(@"FOLLOWING", nil) rightTitleColor:[UIColor whiteColor]];
                    break;
                    
                case FollowingStatusNotFollowing:
                    [self.btnLarge addTarget:self action:@selector(changeFollowingStatus:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLargeButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor colorWithRGBHex:0x4cb0fb] image:[UIImage imageNamed:@"check-white-small"] titleText:NSLocalizedString(@"FOLLOWING", nil) titleColor:[UIColor whiteColor] andSetEnabled:YES];
                    break;
                    
                case FollowingStatusRequested:
                    [self.btnLarge addTarget:self action:@selector(acceptFollowerRequest:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLargeButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor colorWithRGBHex:0x4cb0fb] image:[UIImage imageNamed:@"check-white-small"] titleText:NSLocalizedString(@"ACCEPT FOLLOW REQUEST", nil) titleColor:[UIColor whiteColor] andSetEnabled:YES];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case FollowingStatusNotFollowing:
            switch (followerStatus) {
                case FollowingStatusFollowing:
                    self.buttonSizes = LeftRightButtonSizeLargeRight;
                    [self.btnRight addTarget:self action:@selector(changeFollowingStatus:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLeftRightButtonsWithLeftBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] leftFillColor:[UIColor whiteColor] leftImage:[UIImage imageNamed:@"chat-bubble-icon-blue"] leftTitleText:NSLocalizedString(@"CHAT", nil) leftTitleColor:[UIColor colorWithRGBHex:0x4cb0fb] rightBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] rightFillColor:[UIColor whiteColor] rightImage:[UIImage imageNamed:@"plus-blue-small"] rightTitleText:NSLocalizedString(@"FOLLOW BACK", nil) rightTitleColor:[UIColor colorWithRGBHex:0x4cb0fb]];
                    break;
                    
                case FollowingStatusNotFollowing:
                    [self.btnLarge addTarget:self action:@selector(changeFollowingStatus:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLargeButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor whiteColor] image:[UIImage imageNamed:@"plus-blue-small"] titleText:NSLocalizedString(@"FOLLOW", nil) titleColor:[UIColor colorWithRGBHex:0x4cb0fb] andSetEnabled:YES];
                    break;
                    
                case FollowingStatusRequested:
                    [self.btnLarge addTarget:self action:@selector(acceptFollowerRequest:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLargeButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor colorWithRGBHex:0x4cb0fb] image:[UIImage imageNamed:@"check-white-small"] titleText:NSLocalizedString(@"ACCEPT FOLLOW REQUEST", nil) titleColor:[UIColor whiteColor] andSetEnabled:YES];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case FollowingStatusRequested:
            switch (followerStatus) {
                case FollowingStatusFollowing:
                    self.buttonSizes = LeftRightButtonSizeLargeRight;
                    [self useLeftRightButtonsWithLeftBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] leftFillColor:[UIColor whiteColor] leftImage:[UIImage imageNamed:@"chat-bubble-icon-blue"] leftTitleText:NSLocalizedString(@"CHAT", nil) leftTitleColor:[UIColor colorWithRGBHex:0x4cb0fb] rightBorderColor:[UIColor colorWithRGBHex:0x898989] rightFillColor:[UIColor colorWithRGBHex:0x898989] rightImage:[UIImage imageNamed:@"lock-white-outline-small"] rightTitleText:NSLocalizedString(@"REQUESTED", nil) rightTitleColor:[UIColor whiteColor]];
                    break;
                    
                case FollowingStatusNotFollowing:
                    [self useLargeButtonWithBorderColor:[UIColor colorWithRGBHex:0x898989] fillColor:[UIColor colorWithRGBHex:0x898989] image:[UIImage imageNamed:@"lock-white-outline-small"] titleText:NSLocalizedString(@"REQUESTED", nil) titleColor:[UIColor whiteColor] andSetEnabled:NO];
                    break;
                    
                case FollowingStatusRequested:
                    [self.btnLarge addTarget:self action:@selector(changeFollowingStatus:) forControlEvents:UIControlEventTouchUpInside];
                    [self useLargeButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor colorWithRGBHex:0x4cb0fb] image:[UIImage imageNamed:@"check-white-small"] titleText:NSLocalizedString(@"ACCEPT FOLLOW REQUEST", nil) titleColor:[UIColor whiteColor] andSetEnabled:YES];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

- (void)configureWithDataSource:(id)dataSource cellStyle:(SPCCellStyle)cellStyle name:(NSString *)name followingStatus:(FollowingStatus)followingStatus followerStatus:(FollowingStatus)followerStatus isUserCeleb:(BOOL)isUserCeleb isUserProfileLocked:(BOOL)isUserProfileLocked {
    self.dataSource = dataSource;
    self.name = name;
    
    [self configureWithName:name followingStatus:followingStatus followerStatus:followerStatus isUserCeleb:isUserCeleb isUserProfileLocked:isUserProfileLocked];
}


- (void)useLargeButtonWithBorderColor:(UIColor *)borderColor fillColor:(UIColor *)fillColor image:(UIImage *)image titleText:(NSString *)titleText titleColor:(UIColor *)titleColor andSetEnabled:(BOOL)enabled {
    // Hide the left/right buttons
    self.btnLeft.hidden = YES;
    self.btnRight.hidden = YES;
    
    // Un-hide the large button
    self.btnLarge.hidden = NO;
    self.btnLarge.userInteractionEnabled = enabled;
    
    // Configure
    [self.ivLargeButtonIcon removeFromSuperview];
    UIImageView *ivToUse = [[UIImageView alloc] initWithImage:image];
    self.btnLarge.layer.borderColor = borderColor.CGColor;
    self.btnLarge.backgroundColor = fillColor;
    [self.btnLarge setTitle:titleText forState:UIControlStateNormal];
    [self.btnLarge setTitleColor:titleColor forState:UIControlStateNormal];
    [self.btnLarge addSubview:ivToUse]; // Add the icon to the button
    self.ivLargeButtonIcon = ivToUse; // Finally, store it in our weak pointer, so we can remove it from the button later
    
    [self.ivRightButtonIcon removeFromSuperview];
    UIImageView *ivRightToUse = [[UIImageView alloc] initWithImage:image];
    self.btnRight.layer.borderColor = borderColor.CGColor;
    self.btnRight.backgroundColor = fillColor;
    [self.btnRight setTitle:titleText forState:UIControlStateNormal];
    [self.btnRight setTitleColor:titleColor forState:UIControlStateNormal];
    [self.btnRight addSubview:ivRightToUse];
    [_btnRight setTitleEdgeInsets:UIEdgeInsetsMake(0, ivRightToUse.image.size.width + 4.0f, 0, 0)];
    ivRightToUse.center = CGPointMake(self.btnRight.titleLabel.center.x - CGRectGetWidth(self.btnRight.titleLabel.frame)/2.0f - ivRightToUse.image.size.width/2.0f - 4.0f, self.btnRight.titleLabel.center.y);
    self.ivRightButtonIcon = ivRightToUse;
    
    [self setNeedsLayout];
}

- (void)useLeftRightButtonsWithLeftBorderColor:(UIColor *)leftBorderColor leftFillColor:(UIColor *)leftFillColor leftImage:(UIImage *)leftImage leftTitleText:(NSString *)leftTitleText leftTitleColor:(UIColor *)leftTitleColor rightBorderColor:(UIColor *)rightBorderColor rightFillColor:(UIColor *)rightFillColor rightImage:(UIImage *)rightImage rightTitleText:(NSString *)rightTitleText rightTitleColor:(UIColor *)rightTitleColor {
    // Hide the large button
    self.btnLarge.hidden = YES;
    
    // Un-ide the left/right buttons
    self.btnLeft.hidden = NO;
    self.btnRight.hidden = NO;
    
    // Configure
    // Left button
    [self.ivLeftButtonIcon removeFromSuperview]; // Remove any previous icon this button had
    UIImageView *ivToUseLeft = [[UIImageView alloc] initWithImage:leftImage];
    self.btnLeft.layer.borderColor = leftBorderColor.CGColor;
    self.btnLeft.backgroundColor = leftFillColor;
    [self.btnLeft setTitle:leftTitleText forState:UIControlStateNormal];
    [self.btnLeft setTitleColor:leftTitleColor forState:UIControlStateNormal];
    [self.btnLeft addSubview:ivToUseLeft]; // Add the icon to the button
    self.ivLeftButtonIcon = ivToUseLeft; // Finally, store it in our weak pointer, so we can remove it from the button later
    // Right button
    [self.ivRightButtonIcon removeFromSuperview]; // Remove any previous icon this button had
    UIImageView *ivToUseRight = [[UIImageView alloc] initWithImage:rightImage];
    self.btnRight.layer.borderColor = rightBorderColor.CGColor;
    self.btnRight.backgroundColor = rightFillColor;
    [self.btnRight setTitle:rightTitleText forState:UIControlStateNormal];
    [self.btnRight setTitleColor:rightTitleColor forState:UIControlStateNormal];
    [self.btnRight addSubview:ivToUseRight]; // Add the icon to the button
    self.ivRightButtonIcon = ivToUseRight; // Finally, store it in our weak pointer, so we can remove it from the button later
    
    [self setNeedsLayout];
}

#pragma mark - Actions

- (void)changeFollowingStatus:(id)sender {
    if (self.followingStatus == FollowingStatusNotFollowing) {
        if ([self.dataSource respondsToSelector:@selector(follow:)]) {
            [self.dataSource performSelector:@selector(follow:) withObject:self];
        }
    } else if (self.followingStatus == FollowingStatusFollowing) {
        if ([self.dataSource respondsToSelector:@selector(unfollow:)]) {
            [self.dataSource performSelector:@selector(unfollow:) withObject:self];
        }
    }
}

- (void)acceptFollowerRequest:(id)sender {
    if (self.followerStatus == FollowingStatusRequested) {
        if ([self.dataSource respondsToSelector:@selector(acceptFollow:)]) {
            [self.dataSource performSelector:@selector(acceptFollow:) withObject:self];
        }
    }
}

@end
