//
//  SPCProfileStarPowerCell.m
//  Spayce
//
//  Created by William Santiago on 8/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileStarPowerCell.h"

// Model
#import "Person.h"

@interface SPCProfileStarPowerCell ()

@property (nonatomic, strong) UIView *customContentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *valueTextField;
@property (nonatomic, strong) UIView *progressViewBackground;
@property (nonatomic, strong) UIView *progressViewForeground;
@property (nonatomic, strong) UIImageView *progressImageView;
@property (nonatomic, strong) NSLayoutConstraint *progressWidthConstraint;

@end

@implementation SPCProfileStarPowerCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        _customContentView.layer.masksToBounds = NO;
        _customContentView.layer.cornerRadius = 2;
        _customContentView.layer.shadowColor = [UIColor blackColor].CGColor;
        _customContentView.layer.shadowOpacity = 0.2;
        _customContentView.layer.shadowRadius = 0.5;
        _customContentView.layer.shadowOffset = CGSizeMake(0, 1);
        [self.contentView addSubview:_customContentView];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = NSLocalizedString(@"Star Power", nil);
        _titleLabel.font = [UIFont spc_lightFont];
        _titleLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_titleLabel];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_titleLabel.font.lineHeight]];

        _valueTextField = [[UITextField alloc] init];
        _valueTextField.font = [UIFont spc_boldFont];
        _valueTextField.textColor = [UIColor colorWithRed:74.0/255.0 green:107.0/255.0 blue:140.0/255.0 alpha:1.0];
        _valueTextField.textAlignment = NSTextAlignmentCenter;
        _valueTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        _valueTextField.translatesAutoresizingMaskIntoConstraints = NO;
        _valueTextField.leftViewMode = UITextFieldViewModeAlways;
        _valueTextField.leftView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-gray-xxx-small"]];
        [_customContentView addSubview:_valueTextField];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueTextField attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueTextField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:_valueTextField.font.lineHeight]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_valueTextField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:_customContentView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-10]];

        _progressViewBackground = [[UIView alloc] init];
        _progressViewBackground.backgroundColor = [UIColor colorWithWhite:230.0/255.0 alpha:1.0];
        _progressViewBackground.layer.cornerRadius = 12;
        _progressViewBackground.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_progressViewBackground];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewBackground attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewBackground attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewBackground attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewBackground attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:2*_progressViewBackground.layer.cornerRadius]];

        _progressViewForeground = [[UIView alloc] init];
        _progressViewForeground.backgroundColor = [UIColor colorWithRed:74.0/255.0 green:107.0/255.0 blue:140.0/255.0 alpha:1.0];
        _progressViewForeground.layer.cornerRadius = 12;
        _progressViewForeground.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_progressViewForeground];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewForeground attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_progressViewBackground attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewForeground attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_progressViewBackground attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressViewForeground attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_progressViewBackground attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];

        UIImage *image = [UIImage imageNamed:@"bar-star-thumb"];
        _progressImageView = [[UIImageView alloc] initWithImage:image];
        _progressImageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_customContentView addSubview:_progressImageView];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:image.size.width]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:image.size.height]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_progressViewForeground attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_progressImageView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:_progressViewForeground attribute:NSLayoutAttributeRight multiplier:1.0 constant:-image.size.width/2]];

        _progressWidthConstraint = [NSLayoutConstraint constraintWithItem:_progressViewForeground attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:_progressImageView.image.size.width];
        [_customContentView addConstraint:_progressWidthConstraint];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear display values
    self.valueTextField.text = nil;
    self.progressWidthConstraint.constant = self.progressImageView.image.size.width;
    [self.progressViewForeground setNeedsUpdateConstraints];
}

#pragma mark - Configuration

- (void)configureWithStarCount:(NSInteger)starCount {
    // Update value label
    self.valueTextField.text = [NSString stringWithFormat:@"%@", @(starCount)];
    
    // Update progress indicator
    CGFloat minOffsetX = starCount > 0 ? 5 : 0;
    CGFloat minX = self.progressImageView.image.size.width + minOffsetX;
    CGFloat maxX = CGRectGetWidth(self.contentView.frame) - 30;
    CGFloat progress = maxX * MIN(starCount/kMAX_STARS, 1);
    CGFloat constant = MAX(minX, MIN(progress, maxX));
    
    self.progressWidthConstraint.constant = constant;
    [self.progressViewForeground setNeedsUpdateConstraints];
}

@end
