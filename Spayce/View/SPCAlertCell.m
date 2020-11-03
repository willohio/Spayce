//
//  SPCAlertCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 10/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAlertCell.h"

@interface SPCAlertCell ()

@property (nonatomic, strong) UIColor *normalTextColor;
@property (nonatomic, strong) UIColor *normalSubtitleColor;
@property (nonatomic, strong) UIColor *highlightedTextColor;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customSubtitleLabel;
@property (nonatomic, strong) UIImageView *customImageView;
@property (nonatomic, strong) UIView *separatorView;

@end

@implementation SPCAlertCell

#pragma mark - Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customTextLabel = [[UILabel alloc] init];
        _customTextLabel.textAlignment = NSTextAlignmentCenter;
        _customTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_customTextLabel];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customTextLabel
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1.0
                                       constant:0.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customTextLabel
                                      attribute:NSLayoutAttributeBaseline
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1.0
                                       constant:30.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customTextLabel
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationLessThanOrEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeWidth
                                     multiplier:1.0
                                       constant:-70]
         ];
        
        _customSubtitleLabel = [[UILabel alloc] init];
        _customSubtitleLabel.textAlignment = NSTextAlignmentCenter;
        _customSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_customSubtitleLabel];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customSubtitleLabel
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeCenterX
                                     multiplier:1.0
                                       constant:0.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customSubtitleLabel
                                      attribute:NSLayoutAttributeBaseline
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_customTextLabel
                                      attribute:NSLayoutAttributeBaseline
                                     multiplier:1.0
                                       constant:20.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customSubtitleLabel
                                      attribute:NSLayoutAttributeWidth
                                      relatedBy:NSLayoutRelationLessThanOrEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeWidth
                                     multiplier:1.0
                                       constant:-20]
         ];
        
        
        _customImageView = [[UIImageView alloc] init];
        _customImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_customImageView];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customImageView
                                      attribute:NSLayoutAttributeRight
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_customTextLabel
                                      attribute:NSLayoutAttributeLeft
                                     multiplier:1.0
                                       constant:-10.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_customImageView
                                      attribute:NSLayoutAttributeBottom
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:_customTextLabel
                                      attribute:NSLayoutAttributeBaseline
                                     multiplier:1.0
                                       constant:1.0]
         ];
        
        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = [UIColor colorWithRed:206.0/255.0 green:207.0/255.0 blue:209.0/255.0 alpha:1.0];
        _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_separatorView];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_separatorView
                                      attribute:NSLayoutAttributeLeft
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeLeft
                                     multiplier:1.0
                                       constant:0.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_separatorView
                                      attribute:NSLayoutAttributeRight
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeRight
                                     multiplier:1.0
                                       constant:0.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_separatorView
                                      attribute:NSLayoutAttributeBottom
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:self.contentView
                                      attribute:NSLayoutAttributeBottom
                                     multiplier:1.0
                                       constant:0.0]
         ];
        [self.contentView addConstraint:
         [NSLayoutConstraint constraintWithItem:_separatorView
                                      attribute:NSLayoutAttributeHeight
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:nil
                                      attribute:NSLayoutAttributeNotAnAttribute
                                     multiplier:1.0
                                       constant:0.5]
         ];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.customTextLabel.text = nil;
    self.customSubtitleLabel.text = nil;
    self.customImageView.image = nil;
}

#pragma mark - Private

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.customTextLabel.textColor = highlighted ? self.highlightedTextColor : self.normalTextColor;
    self.customSubtitleLabel.textColor = highlighted ? self.highlightedTextColor : self.normalSubtitleColor;
    self.customImageView.tintColor = highlighted ? self.highlightedTextColor : self.normalTextColor;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    self.customTextLabel.textColor = selected ? self.highlightedTextColor : self.normalTextColor;
    self.customSubtitleLabel.textColor = selected ? self.highlightedTextColor : self.normalSubtitleColor;
    self.customImageView.tintColor = selected ? self.highlightedTextColor : self.normalTextColor;
}

#pragma mark - Configuration

- (void)configureWithTitle:(NSString *)title subtitle:(NSString *)subtitle style:(NSInteger)style image:(UIImage *)image {
    self.customTextLabel.text = title;
    self.customSubtitleLabel.text = subtitle;
    self.customImageView.image = image;
    self.highlightedTextColor = [UIColor lightGrayColor];
    
    if (style == 0) {
        self.normalTextColor = [UIColor colorWithRed:63.0/255.0 green:85.0/255.0 blue:120.0/255.0 alpha:1.0];
        self.normalSubtitleColor = [UIColor colorWithRed:172.0/255.0 green:185.0/255.0 blue:196.0/255.0 alpha:1.0];
        self.customTextLabel.font = [UIFont spc_regularSystemFontOfSize:18];
        self.customSubtitleLabel.font = [UIFont spc_regularSystemFontOfSize:13];
        self.separatorView.hidden = NO;
    }
    else if (style == 1) {
        self.normalTextColor = [UIColor colorWithRed:243.0/255.0 green:133.0/255.0 blue:131.0/255.0 alpha:1.0];
        self.normalSubtitleColor = [UIColor colorWithRed:243.0/255.0 green:189.0/255.0 blue:188.0/255.0 alpha:1.0];
        self.customTextLabel.font = [UIFont spc_regularSystemFontOfSize:18];
        self.customSubtitleLabel.font = [UIFont spc_regularSystemFontOfSize:13];
        self.separatorView.hidden = NO;
    }
    else if (style == 2) {
        self.normalTextColor = [UIColor colorWithRed:243.0/255.0 green:133.0/255.0 blue:131.0/255.0 alpha:1.0];
        self.normalSubtitleColor = [UIColor colorWithRed:243.0/255.0 green:189.0/255.0 blue:188.0/255.0 alpha:1.0];
        self.customTextLabel.font = [UIFont spc_boldSystemFontOfSize:18];
        self.customSubtitleLabel.font = [UIFont spc_regularSystemFontOfSize:13];
        self.separatorView.hidden = YES;
    }
    
    [self setNeedsLayout];
}

@end
