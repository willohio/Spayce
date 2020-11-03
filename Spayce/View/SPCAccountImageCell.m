//
//  SPCAccountImageCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-06.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAccountImageCell.h"

// View
#import "SPCInitialsImageView.h"

@interface SPCAccountImageCell ()

@property (nonatomic, strong) UIView *customBackgroundView;
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UIImageView *customAccessoryIndicatorImageView;

@end

@implementation SPCAccountImageCell

#pragma mark - Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Setup cell
        self.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
        self.clipsToBounds = YES;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.clipsToBounds = YES;
        
        // Setup views
        _customBackgroundView = [[UIView alloc] init];
        _customBackgroundView.backgroundColor = [UIColor whiteColor];
        _customBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customImageView = [[SPCInitialsImageView alloc] init];
        _customImageView.backgroundColor = [UIColor lightGrayColor];
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _customTextLabel.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
        _customTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customAccessoryIndicatorImageView = [[UIImageView alloc] init];
        _customAccessoryIndicatorImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _customAccessoryIndicatorImageView.image = [UIImage imageNamed:@"disclosure-indicator-gray"];
        
        // Add to view hierarchy
        [self.contentView addSubview:_customBackgroundView];
        [_customBackgroundView addSubview:_customContentView];
        [_customContentView addSubview:_customImageView];
        [_customContentView addSubview:_customTextLabel];
        [_customContentView addSubview:_customAccessoryIndicatorImageView];
        
        // Setup auto layout constraints
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-0.5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeTop multiplier:1.0 constant:2]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:8]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:80]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-5]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customTextLabel.font.lineHeight]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customAccessoryIndicatorImageView.image.size.width]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customAccessoryIndicatorImageView.image.size.height]];
    }
    return self;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.customImageView.image = nil;
    self.customTextLabel.text = nil;
}

#pragma mark - Selection

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.customContentView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

@end
