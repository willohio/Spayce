//
//  SPCFeaturedPlaceCell.m
//  Spayce
//
//  Created by Jake Rosin on 2/27/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCFeaturedPlaceCell.h"

// Model
#import "Venue.h"
#import "Asset.h"
#import "Memory.h"

// Utilities
#import "UIFont+SPCAdditions.h"
#import "UIImageView+WebCache.h"

const static CGFloat IMAGE_FADE_TIME = 0.5f;

@interface SPCFeaturedPlaceCell()

@property (nonatomic, strong) UILabel *venueNameLabel;
@property (nonatomic, strong) UILabel *featuredPlaceLabel;
@property (nonatomic, strong) UIView *enterFrame;
@property (nonatomic, strong) UILabel *enterLabel;

@property (nonatomic, strong) UIImageView *venueImageView;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) UIView *colorView;

@end

@implementation SPCFeaturedPlaceCell

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self.contentView addSubview:self.venueImageView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        [self.contentView addSubview:self.colorView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.colorView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.colorView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.colorView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.colorView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        
        [self.contentView addSubview:self.featuredPlaceLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.featuredPlaceLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.featuredPlaceLabel.font.lineHeight]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.featuredPlaceLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.featuredPlaceLabel attribute:NSLayoutAttributeBaseline relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:0.45 constant:0]];
        
        [self.contentView addSubview:self.venueNameLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueNameLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.venueNameLabel.font.lineHeight]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueNameLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueNameLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.featuredPlaceLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-1]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.venueNameLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-40]];
        
        [self.contentView addSubview:self.enterFrame];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.enterFrame attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.enterFrame attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:0.71 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.enterFrame attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:0.25 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.enterFrame attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeWidth multiplier:0.2 constant:0]];
        
    }
    return self;
}


#pragma mark Subviews

- (UILabel *)venueNameLabel {
    if (!_venueNameLabel) {
        _venueNameLabel = [[UILabel alloc] init];
        _venueNameLabel.textColor = [UIColor whiteColor];
        _venueNameLabel.backgroundColor = [UIColor clearColor];
        _venueNameLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:36.0f/750.0f * CGRectGetWidth(self.frame)];
        _venueNameLabel.numberOfLines = 1;
        _venueNameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _venueNameLabel.textAlignment = NSTextAlignmentCenter;
        
        _venueNameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _venueNameLabel;
}


- (UILabel *)featuredPlaceLabel {
    if (!_featuredPlaceLabel) {
        _featuredPlaceLabel = [[UILabel alloc] init];
        _featuredPlaceLabel.textColor = [UIColor whiteColor];
        _featuredPlaceLabel.backgroundColor = [UIColor clearColor];
        _featuredPlaceLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:16.0f/750.0f * CGRectGetWidth(self.frame)];
        _featuredPlaceLabel.numberOfLines = 1;
        _featuredPlaceLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _featuredPlaceLabel.textAlignment = NSTextAlignmentCenter;
        
        _featuredPlaceLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _featuredPlaceLabel;
}

- (UIView *)enterFrame {
    if (!_enterFrame) {
        _enterFrame = [[UIView alloc] init];
        _enterFrame.layer.borderColor = [UIColor whiteColor].CGColor;
        _enterFrame.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
        _enterFrame.layer.cornerRadius = 1;
        
        _enterFrame.translatesAutoresizingMaskIntoConstraints = NO;
        [_enterFrame addSubview:self.enterLabel];
        [_enterFrame addConstraint:[NSLayoutConstraint constraintWithItem:self.enterLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.enterLabel.font.lineHeight]];
        [_enterFrame addConstraint:[NSLayoutConstraint constraintWithItem:self.enterLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_enterFrame attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_enterFrame addConstraint:[NSLayoutConstraint constraintWithItem:self.enterLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_enterFrame attribute:NSLayoutAttributeCenterY multiplier:0.98 constant:0]];
    }
    return _enterFrame;
}

- (UILabel *)enterLabel {
    if (!_enterLabel) {
        _enterLabel = [[UILabel alloc] init];
        _enterLabel.textColor = [UIColor whiteColor];
        _enterLabel.backgroundColor = [UIColor clearColor];
        _enterLabel.font = [UIFont fontWithName:@"OpenSans-Semibold" size:20.0f/750.0f * CGRectGetWidth(self.frame)];
        _enterLabel.numberOfLines = 1;
        _enterLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _enterLabel.textAlignment = NSTextAlignmentCenter;
        
        _enterLabel.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _enterLabel;
}


- (UIImageView *)venueImageView {
    if (!_venueImageView) {
        _venueImageView = [[UIImageView alloc] init];
        _venueImageView.contentMode = UIViewContentModeScaleAspectFill;
        _venueImageView.backgroundColor = [UIColor clearColor];
        _venueImageView.clipsToBounds = YES;
        
        _venueImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _venueImageView;
}

- (UIImageView *)loadingImageView {
    if (!_loadingImageView) {
        _loadingImageView = [[UIImageView alloc] init];
        _loadingImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return _loadingImageView;
}

- (UIView *)colorView {
    if (!_colorView) {
        _colorView = [[UIView alloc] init];
        _colorView.alpha = 0.8;
        
        _colorView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _colorView;
}

#pragma mark - UICollectionReusableView - Reusing Cells

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.layer removeAllAnimations];
    [self.venueImageView sd_cancelCurrentImageLoad];
    [self.loadingImageView sd_cancelCurrentImageLoad];
    
    self.venueNameLabel.text = nil;
    self.featuredPlaceLabel.text = nil;
    self.enterLabel.text = nil;
    
    self.venueImageView.image = nil;
}

#pragma mark public configuration

-(void)setColor:(UIColor *)color {
    _color = color;
    self.colorView.backgroundColor = color;
    self.contentView.backgroundColor = color;
}

-(void)configureWithFeaturedVenue:(Venue *)venue {
    [self configureWithVenue:venue];
    self.featuredPlaceLabel.text = NSLocalizedString(@"FEATURED PLACE", nil);
    self.enterLabel.text = NSLocalizedString(@"ENTER", nil);
}


-(void)configureWithSuggestedVenue:(Venue *)venue {
    [self configureWithVenue:venue];
    self.featuredPlaceLabel.text = NSLocalizedString(@"SUGGESTED DESTINATION", nil);
    self.enterLabel.text = NSLocalizedString(@"FLY", nil);
}

-(void)configureWithVenue:(Venue *)venue {
    self.venue = venue;
    self.venueNameLabel.text = venue.displayNameTitle;
    
    Asset *asset = nil;
    NSInteger starCount = -1;
    for (Memory *memory in venue.popularMemories) {
        if ([memory isKindOfClass:[ImageMemory class]]) {
            ImageMemory *imageMem = (ImageMemory *)memory;
            Asset *memAsset = imageMem.images[0];
            if (!asset || starCount < imageMem.starsCount) {
                asset = memAsset;
                starCount = imageMem.starsCount;
            }
        }
    }
    [self.loadingImageView sd_cancelCurrentImageLoad];
    if (asset) {
        [self.loadingImageView sd_setImageWithURL:[NSURL URLWithString:asset.imageUrlHalfSquare] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (venue == self.venue) {
                self.venueImageView.alpha = 0;
                self.venueImageView.image = image;
                [UIView animateWithDuration:IMAGE_FADE_TIME animations:^{
                    self.venueImageView.alpha = 1.0f;
                }];
            }
            self.loadingImageView.image = nil;
        }];
    }
}

@end
