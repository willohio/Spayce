//
//  SPCSettingsRegularCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSettingsRegularCell.h"

@interface SPCSettingsRegularCell ()

@property (nonatomic, strong) UIView *customBackgroundView;
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UIImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UIImageView *customAccessoryIndicatorImageView;

@property (nonatomic, strong) NSLayoutConstraint *backgroundViewBottomLayoutConstraint;

@end

@implementation SPCSettingsRegularCell

#pragma mark - Object lifecycle

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
        _customBackgroundView.layer.cornerRadius = 2;
        _customBackgroundView.layer.shadowColor = [UIColor grayColor].CGColor;
        _customBackgroundView.layer.shadowOpacity = 0.2;
        _customBackgroundView.layer.shadowRadius = 0.5;
        _customBackgroundView.layer.shadowOffset = CGSizeMake(0, 0.5);
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customImageView = [[UIImageView alloc] init];
        _customImageView.contentMode = UIViewContentModeCenter;
        _customImageView.tintColor = [UIColor colorWithRed:139.0/255.0 green:154.0/255.0 blue:174.0/255.0 alpha:1.0];
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _customTextLabel.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
        _customTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customAccessoryIndicatorImageView = [[UIImageView alloc] init];
        _customAccessoryIndicatorImageView.image = [UIImage imageNamed:@"disclosure-indicator-gray"];
        _customAccessoryIndicatorImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Add to view hierarchy
        [self.contentView addSubview:_customBackgroundView];
        [_customBackgroundView addSubview:_customContentView];
        [_customContentView addSubview:_customImageView];
        [_customContentView addSubview:_customTextLabel];
        [_customContentView addSubview:_customAccessoryIndicatorImageView];
        
        // Setup auto layout constraints
        _backgroundViewBottomLayoutConstraint = [NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:_backgroundViewBottomLayoutConstraint];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customBackgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customBackgroundView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customTextLabel.font.lineHeight]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customAccessoryIndicatorImageView.image.size.width]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customAccessoryIndicatorImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customAccessoryIndicatorImageView.image.size.width]];
    }
    return self;
}

#pragma mark - Selection

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.customContentView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

#pragma mark - Configuration

- (void)configureWithStyle:(SPCGroupedStyle)style image:(UIImage *)image text:(NSString *)text {
    CGFloat backgroundViewBottomConstant = self.backgroundViewBottomLayoutConstraint.constant;
    CGColorRef shadowColor = self.backgroundView.layer.shadowColor;
    
    switch (style) {
        case SPCGroupedStyleTop: {
            backgroundViewBottomConstant = -0.5;
            shadowColor = self.backgroundColor.CGColor;
            break;
        }
        case SPCGroupedStyleMiddle: {
            backgroundViewBottomConstant = -0.5;
            shadowColor = self.backgroundColor.CGColor;
            break;
        }
        case SPCGroupedStyleBottom: {
            backgroundViewBottomConstant = -1;
            shadowColor = [UIColor grayColor].CGColor;
            break;
        }
        default: {
            backgroundViewBottomConstant = -1;
            shadowColor = [UIColor grayColor].CGColor;
            break;
        }
    }
    
    // Update auto layout constraints
    self.backgroundViewBottomLayoutConstraint.constant = backgroundViewBottomConstant;
    [self.contentView setNeedsUpdateConstraints];
    
    // Update shadow color
    self.customBackgroundView.layer.shadowColor = shadowColor;
    
    // Update image
    self.customImageView.image = image;
    // Update text
    self.customTextLabel.text = text;
}

@end
