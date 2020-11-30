//
//  SPCProfileTitleView.m
//  Spayce
//
//  Created by William Santiago on 2014-10-20.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileTitleView.h"

@interface SPCProfileTitleView ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailedTextLabel;
@property (nonatomic, strong) UIImageView *celebImageView;

@end

@implementation SPCProfileTitleView

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        // Title
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.minimumScaleFactor = 0.75;
        _textLabel.font = [UIFont spc_boldSystemFontOfSize:15];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor colorWithRGBHex:0xffffff];
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_textLabel];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:2.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_textLabel.font.lineHeight]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
        
        // Subtitle
        
        _detailedTextLabel = [[UILabel alloc] init];
        _detailedTextLabel.adjustsFontSizeToFitWidth = YES;
        _detailedTextLabel.minimumScaleFactor = 0.75;
        _detailedTextLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        _detailedTextLabel.textAlignment = NSTextAlignmentCenter;
        _detailedTextLabel.textColor = [UIColor colorWithRGBHex:0xffffff];
        _detailedTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_detailedTextLabel];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_detailedTextLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_textLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-2.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_detailedTextLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_detailedTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_detailedTextLabel.font.lineHeight]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_detailedTextLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0.0]];
        
        // Celeb image
        
        _celebImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark-celeb"]];
        _celebImageView.hidden = YES;
        _celebImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_celebImageView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:_detailedTextLabel.font.lineHeight]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_detailedTextLabel.font.lineHeight]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_detailedTextLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_celebImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_detailedTextLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-3]];
    }
    return self;
}

#pragma mark - Configuration

- (void)configureWithName:(NSString *)name handle:(NSString *)handle isCeleb:(BOOL)isCeleb useLightContent:(BOOL)useLightContent{
    self.textLabel.text = name;
    self.detailedTextLabel.text = [NSString stringWithFormat:@"@%@", handle];
    self.celebImageView.hidden = !isCeleb;
    
    if (useLightContent) {
        _textLabel.textColor = [UIColor colorWithRGBHex:0xffffff];
        _detailedTextLabel.textColor = [UIColor colorWithRGBHex:0xffffff];
    } else {
        _textLabel.textColor = [UIColor colorWithRGBHex:0x2e2e2e];
        _detailedTextLabel.textColor = [UIColor colorWithRGBHex:0x2e2e2e];
    }
}

@end
