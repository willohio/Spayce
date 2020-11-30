//
//  SPCProfileConnectionCell.m
//  Spayce
//
//  Created by William Santiago on 2014-10-22.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileConnectionCell.h"

@implementation SPCProfileConnectionCell

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _titleLabel = [[UILabel alloc] init]; // 'Friends', 'Following', 'Followers', etc
        _titleLabel.font = [UIFont spc_regularSystemFontOfSize:11];
        _titleLabel.textColor = [UIColor colorWithRGBHex:0x3f5578];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 1;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_titleLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_titleLabel.font.lineHeight]];
        
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = [UIFont spc_boldSystemFontOfSize:18];
        _valueLabel.textColor = [UIColor colorWithRGBHex:0x3f5578];
        _valueLabel.textAlignment = NSTextAlignmentCenter;
        _valueLabel.numberOfLines = 1;
        _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_valueLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeTop multiplier:1.0 constant:-3]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_valueLabel.font.lineHeight]];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    self.contentView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.tag = 0;
    self.valueLabel.text = nil;
    self.titleLabel.text = nil;
}

@end
