//
//  SPCFriendPlaceholderCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFriendPlaceholderCell.h"

@implementation SPCFriendPlaceholderCell

#pragma mark - Object lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UILabel *textLabel = [[UILabel alloc] init];
        textLabel.text = NSLocalizedString(@"You don't have any friends on Spayce yet!", nil);
        textLabel.textAlignment = NSTextAlignmentCenter;
        textLabel.font = [UIFont spc_regularFont];
        textLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:textLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:20]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:textLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:textLabel.font.lineHeight]];
        
        _button = [[UIButton alloc] init];
        _button.titleLabel.font = [UIFont spc_regularFont];
        _button.translatesAutoresizingMaskIntoConstraints = NO;
        _button.layer.cornerRadius = 4.0;
        _button.layer.borderColor = [UIColor colorWithRed:0.980 green:0.439 blue:0.113 alpha:1.000].CGColor;
        _button.layer.borderWidth = 1.0;
        [_button setTitleColor:[UIColor colorWithRed:0.980 green:0.439 blue:0.113 alpha:1.000] forState:UIControlStateNormal];
        [_button setTitle:NSLocalizedString(@"Invite Friends", nil) forState:UIControlStateNormal];
        [self.contentView addSubview:_button];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:40]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:130]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-20]];
    }
    return self;
}

@end
