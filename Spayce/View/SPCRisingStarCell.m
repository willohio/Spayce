//
//  SPCRisingStarCell.m
//  Spayce
//
//  Created by Jake Rosin on 4/1/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCRisingStarCell.h"

// Model
#import "Person.h"
#import "Asset.h"

// Views
#import "SPCInitialsImageView.h"

// Category
#import "UIImageView+WebCache.h"
#import "NSString+SPCAdditions.h"



@interface SPCRisingStarCell()

// Data
@property (nonatomic, strong) Person *person;

// Backdrop
@property (nonatomic, strong) UIView *backdropView;

// Profile image
@property (nonatomic, strong) SPCInitialsImageView *profileImageView;

// Name, handle, and stars
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *handleAndStarsLabel;
@property (nonatomic, strong) UIImageView *starImageView;

@end


@implementation SPCRisingStarCell


#pragma mark lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.clipsToBounds = NO;
        
        // Background
        _backdropView = [[UIView alloc] initWithFrame:self.bounds];
        _backdropView.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        [self addSubview:_backdropView];
        
        // Profile image
        _profileImageView = [[SPCInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        if ([UIScreen mainScreen].bounds.size.width <= 375) {
            _profileImageView.center = CGPointMake(CGRectGetWidth(frame)/2, 40);
        } else { // 5"
            _profileImageView.center = CGPointMake(CGRectGetWidth(frame)/2, 35 + 5 * ([UIScreen mainScreen].bounds.size.width / 375.0));
        }
        _profileImageView.layer.cornerRadius = 35;
        _profileImageView.clipsToBounds = YES;
        [self addSubview:_profileImageView];
        
        // Name, handle, and stars
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.font = [UIFont fontWithName:@"OpenSans" size:35.0f/375.0f * CGRectGetWidth(self.bounds)];
        _nameLabel.textColor = [UIColor colorWithRGBHex:0x262626];
        _nameLabel.numberOfLines = 1;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.minimumScaleFactor = 0.7;
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        [self addSubview:_nameLabel];
        
        _handleAndStarsLabel = [[UILabel alloc] init];
        _handleAndStarsLabel.font = [UIFont fontWithName:@"OpenSans" size:32.0f/375.0f * CGRectGetWidth(self.bounds)];
        _handleAndStarsLabel.numberOfLines = 1;
        _handleAndStarsLabel.textColor = [UIColor colorWithRGBHex:0x898989];
        _handleAndStarsLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_handleAndStarsLabel];
        
        UIImage *starImage = [[UIImage imageNamed:@"star-white-x-small2"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _starImageView = [[UIImageView alloc] initWithImage:starImage];
        _starImageView.tintColor = [UIColor colorWithRGBHex:0x898989];
        //_starImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_starImageView];
    }
    
    return self;
}

#pragma mark

- (void)layoutSubviews {
    self.backdropView.frame = CGRectInset(self.bounds, -self.horizontalOverreach, 0);
    
    [self.nameLabel sizeToFit];
    CGFloat labelWidth = MIN(CGRectGetWidth(self.frame) - 10, CGRectGetWidth(self.nameLabel.frame));
    self.nameLabel.frame = CGRectInset(self.nameLabel.frame, (CGRectGetWidth(self.nameLabel.frame) - labelWidth)/2, 0);
    self.nameLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetMaxY(self.profileImageView.frame) + 15);
    //self.nameLabel.backgroundColor = labelWidth == CGRectGetWidth(self.frame) - 10 ? [UIColor redColor] : [UIColor clearColor];
    
    [self.handleAndStarsLabel sizeToFit];
    self.handleAndStarsLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2 + CGRectGetWidth(self.starImageView.frame)/2 + 2, CGRectGetMaxY(self.nameLabel.frame) + CGRectGetHeight(self.handleAndStarsLabel.frame)/2);
    
    self.starImageView.center = CGPointMake(CGRectGetMinX(self.handleAndStarsLabel.frame) - CGRectGetWidth(self.starImageView.frame)/2 - 4, CGRectGetMidY(self.handleAndStarsLabel.frame) - 0.5);
}


#pragma mark mutators

- (void)setHorizontalOverreach:(CGFloat)horizontalOverreach {
    _horizontalOverreach = horizontalOverreach;
    self.backdropView.frame = CGRectInset(self.bounds, -self.horizontalOverreach, 0);
}


#pragma mark Configuration

- (void)configureWithPerson:(Person *)person {
    self.person = person;
    
    NSString *text = [person.displayName substringWithRange:NSMakeRange(0, 1)];
    NSURL *url = [NSURL URLWithString:person.imageAsset.imageUrlHalfSquare];
    [self.profileImageView configureWithText:text url:url];
    
    self.nameLabel.text = [person.displayName uppercaseString];
    
    self.handleAndStarsLabel.text = [NSString stringByFormattingInteger:person.starCount];
    
    [self.nameLabel sizeToFit];
    CGFloat labelWidth = MIN(CGRectGetWidth(self.frame) - 10, CGRectGetWidth(self.nameLabel.frame));
    self.nameLabel.frame = CGRectInset(self.nameLabel.frame, (CGRectGetWidth(self.nameLabel.frame) - labelWidth)/2, 0);
    self.nameLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetMaxY(self.profileImageView.frame) + 15);
    //self.nameLabel.backgroundColor = labelWidth == CGRectGetWidth(self.frame) - 10 ? [UIColor redColor] : [UIColor clearColor];
    
    [self.handleAndStarsLabel sizeToFit];
    self.handleAndStarsLabel.center = CGPointMake(CGRectGetWidth(self.bounds)/2 + CGRectGetWidth(self.starImageView.frame)/2 + 2, CGRectGetMaxY(self.nameLabel.frame) + CGRectGetHeight(self.handleAndStarsLabel.frame)/2);
    
    self.starImageView.center = CGPointMake(CGRectGetMinX(self.handleAndStarsLabel.frame) - CGRectGetWidth(self.starImageView.frame)/2 - 4, CGRectGetMidY(self.handleAndStarsLabel.frame) - 0.5);
}


@end
