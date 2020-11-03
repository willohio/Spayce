//
//  SPCProfileMapCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-23.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileMapCell.h"

// Model
#import "SPCCity.h"

@interface SPCProfileMapCell ()

@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailTextLabel;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SPCProfileMapCell

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        UIView *backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor whiteColor];
        backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:backgroundView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:backgroundView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.masksToBounds = YES;
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:backgroundView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _imageView.layer.masksToBounds = YES;
        [_customContentView addSubview:_imageView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:65]];
        
        _detailTextLabel = [[UILabel alloc] init];
        _detailTextLabel.adjustsFontSizeToFitWidth = YES;
        _detailTextLabel.minimumScaleFactor = 0.75;
        _detailTextLabel.font = [UIFont spc_regularSystemFontOfSize:13];
        _detailTextLabel.textAlignment = NSTextAlignmentCenter;
        _detailTextLabel.textColor = [UIColor colorWithRGBHex:0x3f5578];
        _detailTextLabel.numberOfLines = 1;
        _detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_detailTextLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_detailTextLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_detailTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_imageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_detailTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.minimumScaleFactor = 0.75;
        _textLabel.font = [UIFont spc_mediumSystemFontOfSize:13];
        _textLabel.textAlignment = NSTextAlignmentCenter;
        _textLabel.textColor = [UIColor colorWithRGBHex:0x3f5578];
        _textLabel.numberOfLines = 1;
        _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_textLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_imageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:3]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_imageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_imageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.imageView.image = nil;
}

#pragma mark - Configuration

- (void)configureWithText:(NSString *)text detailedText:(NSString *)detailedText image:(UIImage *)image {
    // Force auto layout because I don't know why
    [self.contentView layoutIfNeeded];
    
    // Update label
    self.textLabel.text = text;
    self.detailTextLabel.text = detailedText;
    self.imageView.image = image;
}

@end
