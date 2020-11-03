//
//  SPCFriendCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFriendCell.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

@interface SPCFriendCell ()

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *celebImageView;
@property (nonatomic, strong) UIView *bgView;

@end

@implementation SPCFriendCell

#pragma mark - Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor clearColor];
        
        UIView *dropShadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height)];
        dropShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
        dropShadowView.layer.shadowOffset = CGSizeMake(0, 1);
        dropShadowView.layer.shadowRadius = 1;
        dropShadowView.layer.shadowOpacity = 0.2f;
        dropShadowView.layer.masksToBounds = NO;
        dropShadowView.clipsToBounds = NO;
        [self.contentView addSubview:dropShadowView];
        
        self.bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height)];
        self.bgView.backgroundColor = [UIColor whiteColor];
        self.bgView.layer.cornerRadius = 2;
        self.bgView.layer.masksToBounds = YES;
        self.bgView.clipsToBounds = YES;
        [dropShadowView addSubview:self.bgView];
        
        
        _customImageView = [[SPCInitialsImageView alloc] init];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        float cornerRadius = 38;
        float topAnchorPadding = 10;
        float bottomAnchorPadding = -8;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            cornerRadius = 42.5;
            topAnchorPadding = 15;
            bottomAnchorPadding = -15;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            cornerRadius = 42.5;
            topAnchorPadding = 20;
            bottomAnchorPadding = -20;
        }
        
        
        _customImageView.layer.cornerRadius = cornerRadius;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [self.contentView addSubview:_customImageView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:topAnchorPadding]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:_customImageView.layer.cornerRadius * 2]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_customImageView.layer.cornerRadius * 2]];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = [UIColor colorWithWhite:151.0f/255.0f alpha:1.0f];
        _nameLabel.font = [UIFont spc_regularSystemFontOfSize:11];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nameLabel.minimumScaleFactor = 0.8;
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_nameLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:bottomAnchorPadding]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_nameLabel.font.lineHeight]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_nameLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:CGRectGetWidth(self.contentView.frame) - 2 * 20]];
        
        UIImage *image = [UIImage imageNamed:@"checkmark-celeb"];
        
        _celebImageView = [[UIImageView alloc] initWithImage:image];
        _celebImageView.hidden = YES;
        _celebImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_celebImageView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:15]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:15]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_nameLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_nameLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:2]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.contentView.backgroundColor = [UIColor clearColor];
    // Clear display values
    [self.customImageView prepareForReuse];
    
    self.nameLabel.text = nil;
    self.celebImageView.hidden = YES;
}

#pragma mark - Selection

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.bgView.backgroundColor = (selected) ? [UIColor colorWithWhite:0.9 alpha:1.0] : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    self.bgView.backgroundColor = (highlighted) ? [UIColor colorWithWhite:0.9 alpha:1.0] : [UIColor whiteColor];
}

#pragma mark - Configuration

- (void)configureWithName:(NSString *)name isCeleb:(BOOL)isCeleb url:(NSURL *)url {
    self.nameLabel.text = name;
    self.celebImageView.hidden = !isCeleb;
    
    [self.customImageView configureWithText:name.firstLetter.capitalizedString url:url];
}

@end
