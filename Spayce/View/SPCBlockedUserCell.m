//
//  BlockedUserCell.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/23/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SPCBlockedUserCell.h"

// View
#import "SPCInitialsImageView.h"

// Category
#import "NSString+SPCAdditions.h"

@interface SPCBlockedUserCell ()

@property (nonatomic, strong) SPCInitialsImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDetailTextLabel;

@end

@implementation SPCBlockedUserCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.backgroundColor = self.contentView.backgroundColor;
        _customTextLabel.font = [UIFont spc_regularFont];
        _customTextLabel.textColor = [UIColor colorWithRGBHex:0x484451];
        _customTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_customTextLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-_customTextLabel.font.lineHeight / 2]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_customTextLabel.font.lineHeight]];
        
        _customDetailTextLabel = [[UILabel alloc] init];
        _customDetailTextLabel.backgroundColor = self.contentView.backgroundColor;
        _customDetailTextLabel.font = [UIFont spc_regularFont];
        _customDetailTextLabel.textColor = [UIColor lightGrayColor];
        _customDetailTextLabel.adjustsFontSizeToFitWidth = YES;
        _customDetailTextLabel.minimumScaleFactor = 0.7;
        _customDetailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_customDetailTextLabel];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:_customDetailTextLabel.font.lineHeight / 2]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_customDetailTextLabel.font.lineHeight]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customTextLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDetailTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customTextLabel attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _customImageView = [[SPCInitialsImageView alloc] init];
        _customImageView.backgroundColor = [UIColor whiteColor];
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _customImageView.layer.cornerRadius = 20;
        _customImageView.layer.masksToBounds = YES;
        _customImageView.textLabel.font = [UIFont spc_placeholderFont];
        [self.contentView addSubview:_customImageView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:_customImageView.layer.cornerRadius * 2]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_customImageView.layer.cornerRadius * 2]];
        
        _imageButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _imageButton.backgroundColor = [UIColor clearColor];
        _imageButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_imageButton];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_imageButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        
        _actionButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _actionButton.titleLabel.font = [UIFont spc_roundedButtonFont];
        _actionButton.layer.cornerRadius = 4;
        _actionButton.layer.borderColor = [UIColor colorWithRed:155.0/255.0 green:202.0/255.0 blue:62.0/255.0 alpha:1.0].CGColor;
        _actionButton.layer.borderWidth = 0.5;
        _actionButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_actionButton setTitleColor:[UIColor colorWithRed:155.0/255.0 green:202.0/255.0 blue:62.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [_actionButton setTitle:NSLocalizedString(@"Unblock", nil) forState:UIControlStateNormal];
        [self.contentView addSubview:_actionButton];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:65]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_actionButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-20]];
        
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_actionButton attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-5]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    [self.customImageView prepareForReuse];
    
    self.customTextLabel.text = nil;
    self.customDetailTextLabel.text = nil;
    
    self.actionButton.tag = 0;
    self.imageButton.tag = 0;
    
    // Clear target action
    [self.actionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [self.imageButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

#pragma mark - Configuration

- (void)configureWithText:(NSString *)text detailText:(NSString *)detailText url:(NSURL *)url {
    self.customTextLabel.text = text;
    self.customDetailTextLabel.text = detailText;
    [self.customImageView configureWithText:[text.firstLetter capitalizedString] url:url];
}

@end
