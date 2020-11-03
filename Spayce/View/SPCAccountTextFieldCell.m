//
//  SPCAccountTextFieldCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-06.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAccountTextFieldCell.h"

@interface SPCAccountTextFieldCell ()

@property (nonatomic, strong) UIView *customContentView;

@end

@implementation SPCAccountTextFieldCell

#pragma mark - Initialization

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Setup cell
        self.backgroundColor = [UIColor colorWithWhite:243.0/255.0 alpha:1.0];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Setup views
        _customContentView = [[UIView alloc] init];
        _customContentView.backgroundColor = [UIColor whiteColor];
        _customContentView.translatesAutoresizingMaskIntoConstraints = NO;
        
        _customTextField = [[UITextField alloc] init];
        _customTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        _customTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _customTextField.clearButtonMode = UITextFieldViewModeAlways;
        _customTextField.font = [UIFont spc_regularSystemFontOfSize:14];
        _customTextField.textColor = [UIColor colorWithRed:20.0/255.0 green:41.0/255.0 blue:75.0/255.0 alpha:1.0];
        _customTextField.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Add to view hierarchy
        [self.contentView addSubview:_customContentView];
        [_customContentView addSubview:_customTextField];
        
        // Setup auto layout constraints
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-0.5]];
        [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:_customContentView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
        
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextField attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextField attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeLeft multiplier:1.0 constant:10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextField attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeRight multiplier:1.0 constant:-10]];
        [_customContentView addConstraint:[NSLayoutConstraint constraintWithItem:_customTextField attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:_customContentView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-1]];
    }
    return self;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.customTextField.text = nil;
}

#pragma mark - Selection

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    self.customContentView.backgroundColor = highlighted ? [UIColor colorWithWhite:0.98 alpha:1.0] : [UIColor whiteColor];
}

@end
