//
//  SPCInitialsImageView.m
//  Spayce
//
//  Created by William Santiago on 9/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCInitialsImageView.h"

// Category
#import "UIImageView+WebCache.h"

@implementation SPCInitialsImageView

#pragma mark - Object lifecycle

- (void)dealloc {
    [self sd_cancelCurrentImageLoad];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInitializer];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInitializer];
    }
    return self;
}

#pragma mark - Private

- (void)customInitializer {
    _textLabel = [[UILabel alloc] init];
    _textLabel.backgroundColor = [UIColor greenColor];
    _textLabel.font = [UIFont spc_thinFont];
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];
    _textLabel.textColor = [UIColor lightGrayColor];
    _textLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _textLabel.layer.masksToBounds = YES;
    [self addSubview:_textLabel];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_textLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

#pragma mark - Accessors

- (void)prepareForReuse {
    // Cancel image load
    [self sd_cancelCurrentImageLoad];
    
    // Clear display values
    self.image = nil;
    self.textLabel.text = nil;
    self.textLabel.hidden = NO;
}

#pragma mark - Configuration

- (void)configureWithText:(NSString *)text url:(NSURL *)url {
    self.textLabel.text = text;
    
    [self sd_setImageWithURL:url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        self.textLabel.hidden = image != nil;
    }];
}

@end
