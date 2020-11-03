//
//  SPCFollowListCell.m
//  Spayce
//
//  Created by Jake Rosin on 3/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCFollowListCell.h"

// Views
#import "SPCInitialsImageView.h"

// Model
#import "Person.h"

// Category
#import "NSString+SPCAdditions.h"

// Utils
#import "Enums.h"


@interface SPCFollowListCell()

@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UIButton *followButton;

@property (nonatomic, strong) UIImageView *followButtonImageView;
@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDetailTextLabel;
@property (nonatomic, strong) UIImageView *isCelebBadge;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UILabel *userIsYouLabel;

@end

@implementation SPCFollowListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _customImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(10, 15, 46, 46)];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.layer.cornerRadius = 23;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        
        _imageButton = [[UIButton alloc] initWithFrame:_customImageView.frame];
        _imageButton.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_imageButton];
        
        _userIsYouLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 36, 15)];
        _userIsYouLabel.center = CGPointMake(33, 57);
        _userIsYouLabel.layer.cornerRadius = 7;
        _userIsYouLabel.backgroundColor = [UIColor colorWithRGBHex:0x998fcc];
        _userIsYouLabel.layer.borderColor = [UIColor whiteColor].CGColor;
        _userIsYouLabel.layer.borderWidth = 3.0f / [UIScreen mainScreen].scale;
        _userIsYouLabel.textColor = [UIColor whiteColor];
        _userIsYouLabel.text = @"You";
        _userIsYouLabel.font = [UIFont spc_boldSystemFontOfSize:8];
        _userIsYouLabel.textAlignment = NSTextAlignmentCenter;
        _userIsYouLabel.hidden = YES;
        _userIsYouLabel.clipsToBounds = YES;
        [self.contentView addSubview:_userIsYouLabel];
        
        CGFloat buttonWidth = 100;
        if ([UIScreen mainScreen].bounds.size.width < 375) {
            buttonWidth = 90;
        }
        _followButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, 25)];
        _followButton.layer.cornerRadius = 3;
        _followButton.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        [_followButton.titleLabel setFont:[UIFont fontWithName:@"OpenSans" size:11.0f]];
        [self.contentView addSubview:_followButton];
        
        _followButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plus-blue-small"]];
        [_followButton addSubview:_followButtonImageView];
        
        _customTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _customTextLabel.textColor = [UIColor colorWithRGBHex:0x14294b];
        _customTextLabel.font = [UIFont boldSystemFontOfSize:14];
        _customTextLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_customTextLabel];
        
        _customDetailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _customDetailTextLabel.textColor = [UIColor colorWithRGBHex:0x6ab1fb];
        _customDetailTextLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
        _customDetailTextLabel.textAlignment = NSTextAlignmentLeft;
        _customDetailTextLabel.adjustsFontSizeToFitWidth = YES;
        _customDetailTextLabel.minimumScaleFactor = .75;
        [self.contentView addSubview:_customDetailTextLabel];
        
        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:_separatorView];
        
        _isCelebBadge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"celebrity-check"]];
        _isCelebBadge.hidden = YES;
        [self.contentView addSubview:_isCelebBadge];
    }
    return self;
}


- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    // clear text
    self.customTextLabel.text = nil;
    self.customDetailTextLabel.text = nil;
    self.isCelebBadge.hidden = YES;
    
    self.imageButton.tag = 0;
    self.followButton.tag = 0;
    
    // Clear target action
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.followButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    self.followButtonImageView.image = nil;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.followButton.center = CGPointMake(CGRectGetWidth(self.contentView.frame) - 10.0f - CGRectGetWidth(self.followButton.frame) / 2, CGRectGetMidY(self.contentView.frame));
    
    CGFloat maxTextSpace = CGRectGetMinX(self.followButton.frame) - 10 - CGRectGetMaxX(self.customImageView.frame);
    
    self.customTextLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, 18, self.bounds.size.width - 100, 20);
    [self.customTextLabel sizeToFit];
    if (self.customTextLabel.frame.size.width > maxTextSpace) {
        self.customTextLabel.frame = CGRectMake(CGRectGetMaxX(self.customImageView.frame)+10, 18, maxTextSpace, 20);
    }
    
    self.customDetailTextLabel.frame =  CGRectMake(CGRectGetMinX(self.customTextLabel.frame), CGRectGetMaxY(self.customTextLabel.frame)+1, 50, 15);
    [self.customDetailTextLabel sizeToFit];
    
    if (self.customDetailTextLabel.frame.size.width > maxTextSpace) {
        self.customDetailTextLabel.frame = CGRectMake(CGRectGetMinX(self.customTextLabel.frame), CGRectGetMaxY(self.customTextLabel.frame)+1, maxTextSpace, 15);
    }
    
    
    self.isCelebBadge.center = CGPointMake(CGRectGetMaxX(self.customTextLabel.frame)+8, self.customTextLabel.center.y);
    
    CGFloat separatorHeight = 1.0f / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(0, CGRectGetHeight(self.contentView.frame) - separatorHeight, CGRectGetWidth(self.contentView.frame), separatorHeight);
}


#pragma mark - Configuration


- (void)configureWithPerson:(Person *)person url:(NSURL *)url {
    self.person = person;
    
    // Handle the name
    NSString *nameToDisplay = person.displayName;
    if (person.firstname && person.lastname) {
        nameToDisplay = [NSString stringWithFormat:@"%@ %@",person.firstname,person.lastname];
    }
    // Setting attributes here, because we need kern
    NSDictionary *nameAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Bold" size:13],
                                      NSForegroundColorAttributeName : [UIColor colorWithWhite:61.0f/255.0f alpha:1.0f],
                                      NSKernAttributeName : @(0.5) };
    self.customTextLabel.attributedText = [[NSAttributedString alloc] initWithString:nameToDisplay attributes:nameAttributes];
    
    // Handle the handle
    self.detailTextLabel.text = @"";
    if (person.handle.length > 0) {
        NSDictionary *handleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:13],
                                            NSForegroundColorAttributeName : [UIColor colorWithRed:187.0f/255.0f green:189.0f/255.0f blue:193.0f/255.0f alpha:1.0f],
                                            NSKernAttributeName : @(0.5) };
        self.customDetailTextLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"@%@",person.handle] attributes:handleAttributes];
    }
    
    // Handle celeb
    self.isCelebBadge.hidden = !person.isCeleb;
    self.userIsYouLabel.hidden = YES;
    
    // Handle follow button
    [self configureForFollowingStatus:person.followingStatus];
    
    // User image
    [self.customImageView configureWithText:[person.firstname firstLetter] url:url];
    
    [self setNeedsLayout];
}

- (void)configureWithCurrentUser:(Person *)person url:(NSURL *)url {
    [self configureWithPerson:person url:url];
    [self configureForFollowingStatus:FollowingStatusUnknown];
    self.userIsYouLabel.hidden = NO;
}

- (void)configureForFollowingStatus:(FollowingStatus)followingStatus {
    switch(followingStatus) {
        case FollowingStatusNotFollowing:
            [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor whiteColor] image:[UIImage imageNamed:@"plus-blue-small"] titleText:NSLocalizedString(@"FOLLOW", nil) titleColor:[UIColor colorWithRGBHex:0x4cb0fb] setEnabled:YES andSetHidden:NO];
            break;
            
        case FollowingStatusRequested:
            [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x898989] fillColor:[UIColor colorWithRGBHex:0x898989] image:[UIImage imageNamed:@"lock-white-outline-small"] titleText:NSLocalizedString(@"REQUESTED", nil) titleColor:[UIColor whiteColor] setEnabled:NO andSetHidden:NO];
            break;
            
        case FollowingStatusFollowing:
            [self configureFollowButtonWithBorderColor:[UIColor colorWithRGBHex:0x4cb0fb] fillColor:[UIColor colorWithRGBHex:0x4cb0fb] image:[UIImage imageNamed:@"check-white-small"] titleText:NSLocalizedString(@"FOLLOWING", nil) titleColor:[UIColor whiteColor] setEnabled:YES andSetHidden:NO];
            break;
            
        default:
            self.followButton.hidden = YES;
            self.followButton.userInteractionEnabled = NO;
            break;
    }
}


- (void)configureFollowButtonWithBorderColor:(UIColor *)borderColor fillColor:(UIColor *)fillColor image:(UIImage *)image titleText:(NSString *)titleText titleColor:(UIColor *)titleColor setEnabled:(BOOL)setEnabled andSetHidden:(BOOL)setHidden {
    
    [self.followButton setTitle:titleText forState:UIControlStateNormal];
    [self.followButton setTitleColor:titleColor forState:UIControlStateNormal];
    self.followButton.layer.borderColor = borderColor.CGColor;
    self.followButton.backgroundColor = fillColor;
    self.followButtonImageView.image = image;
    self.followButton.titleLabel.text = titleText;
    
    self.followButtonImageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    [self.followButton setTitleEdgeInsets:UIEdgeInsetsMake(0, image.size.width + 4.0f, 0, 0)];
    [self.followButton layoutSubviews];
    
    self.followButtonImageView.center = CGPointMake(self.followButton.titleLabel.center.x - CGRectGetWidth(self.followButton.titleLabel.frame)/2.0f - image.size.width/2.0f - 4.0f, self.followButton.titleLabel.center.y);
    
    self.followButton.enabled = setEnabled;
    self.followButton.hidden = setHidden;
}


@end
