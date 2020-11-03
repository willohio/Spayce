//
//  SPCSettingsSwitchCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSettingsSwitchCell.h"
#import "NSString+SPCAdditions.h"

// Swift
#ifdef IS_ENTERPRISE_TARGET
    #import "SpayceEnterprise-Swift.h"
#else
    #import "Spayce-Swift.h"
#endif

@interface SPCSettingsSwitchCell ()

@property (nonatomic, strong) UIView *customBackgroundView;
@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UIImageView *customImageView;
@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) UILabel *customDescriptionLabel;
@property (nonatomic, strong) SevenSwitch *customSwitch;

@property (nonatomic, strong) NSLayoutConstraint *backgroundViewBottomLayoutConstraint;
@property (nonatomic, strong) NSLayoutConstraint *textLabelCenterYLayoutConstraint;

@property (nonatomic, strong) UIImage *offImage;
@property (nonatomic, strong) UIImage *onImage;

@end

@implementation SPCSettingsSwitchCell

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
        
        _customDescriptionLabel = [[UILabel alloc] init];
        _customDescriptionLabel.font = [UIFont spc_regularSystemFontOfSize:12];
        _customDescriptionLabel.textColor = [UIColor colorWithRed:185.0/255.0 green:184.0/255.0 blue:184.0/255.0 alpha:1.0];
        _customDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _customDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _customDescriptionLabel.numberOfLines = 0;
        
        _customSwitch = [[SevenSwitch alloc] init];
        _customSwitch.onTintColor = [UIColor colorWithRed:106.0/255.0 green:179.0/255.0 blue:249.0/255.0 alpha:1.0];
        _customSwitch.inactiveColor = [UIColor colorWithRed:222.0/255.0 green:222.0/255.0 blue:222.0/255.0 alpha:1.0];
        _customSwitch.translatesAutoresizingMaskIntoConstraints = NO;
        [_customSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        // Add to view hierarchy
        [self.contentView addSubview:_customBackgroundView];
        [_customBackgroundView addSubview:_customContentView];
        [_customContentView addSubview:_customImageView];
        [_customContentView addSubview:_customTextLabel];
        [_customContentView addSubview:_customSwitch];
        [_customContentView addSubview:_customDescriptionLabel];
        
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
        
        _textLabelCenterYLayoutConstraint = [NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
        [_customContentView addConstraint:_textLabelCenterYLayoutConstraint];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:75]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customSwitch attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:_customTextLabel.font.lineHeight]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customTextLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customSwitch attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-8]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customSwitch attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customTextLabel attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customSwitch attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:51]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customSwitch attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:31]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDescriptionLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customTextLabel attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDescriptionLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customImageView attribute:NSLayoutAttributeRight multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDescriptionLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customSwitch attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customDescriptionLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:(_customDescriptionLabel.font.lineHeight*2 + 1)]];
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
    [self configureWithStyle:style image:image text:text description:nil];
}

- (void)configureWithStyle:(SPCGroupedStyle)style image:(UIImage *)image text:(NSString *)text description:(NSString *)description {
    [self configureWithStyle:style offImage:image onImage:image text:text description:description];
}

- (void)configureWithStyle:(SPCGroupedStyle)style offImage:(UIImage *)offImage onImage:(UIImage *)onImage text:(NSString *)text {
    [self configureWithStyle:style offImage:offImage onImage:onImage text:text description:nil];
}

- (void)configureWithStyle:(SPCGroupedStyle)style offImage:(UIImage *)offImage onImage:(UIImage *)onImage text:(NSString *)text description:(NSString *)description {
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
    
    // Update shadow color
    self.customBackgroundView.layer.shadowColor = shadowColor;
    
    // Update image
    self.offImage = offImage;
    self.onImage = onImage;
    self.customImageView.image = self.customSwitch.on ? onImage : offImage;
    // Update text
    self.customTextLabel.text = text;
    // Update description
    self.customDescriptionLabel.text = description;
    
    // Update positioning.
    if (!description) {
        self.textLabelCenterYLayoutConstraint.constant = 0;
    } else {
        self.textLabelCenterYLayoutConstraint.constant = -22 + self.customTextLabel.font.lineHeight / 2;
    }
    
    [self.contentView setNeedsUpdateConstraints];
}


#pragma mark Switch state

- (void)setOn:(BOOL)on {
    _on = on;
    if (self.customSwitch.on != on) {
        self.customSwitch.on = on;
    }
    self.customImageView.image = on ? self.onImage : self.offImage;
}

- (void)switchValueChanged:(id)sender {
    self.on = [sender on];
    if (self.switchChangeHandler) {
        self.switchChangeHandler(self, self.on);
    }
}


@end
