//
//  SPCProfileFriendCell.m
//  Spayce
//
//  Created by William Santiago on 8/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileFriendCell.h"

// Model
#import "Asset.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

@interface SPCProfileFriendCell ()

@property (nonatomic, strong) SPCInitialsImageView *customImageView;

@end

@implementation SPCProfileFriendCell

#pragma mark - Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _customImageView = [[SPCInitialsImageView alloc] init];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _customImageView.layer.cornerRadius = 31;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_profileInfo_placeholderFont];
        [self.contentView addSubview:_customImageView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
}

#pragma mark - Configuration

- (void)configureWithName:(NSString *)name url:(NSURL *)url {
    [self.customImageView configureWithText:[name.firstLetter capitalizedString] url:url];
}

@end
