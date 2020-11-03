//
//  SignUpButtonCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpButtonCell.h"

@implementation SignUpButtonCell

#pragma mark - UITableViewCell - Initializing a UITableViewCell Object

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _button = [[SignUpButton alloc] init];
        _button.backgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _button.normalBackgroundColor = _button.backgroundColor;
        _button.highlightedBackgroundColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        _button.layer.cornerRadius = 3.0;
        _button.titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:13];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_button setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.contentView addSubview:_button];
    }
    return self;
}

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout button
    if (!self.isResetPassBtn) {
        self.button.frame = CGRectMake(0.0, CGRectGetMidY(self.contentView.frame)-25.0, CGRectGetWidth(self.contentView.frame), 50.0);
    }
    else {
        self.button.frame = CGRectMake(20.0, CGRectGetMidY(self.contentView.frame)-25.0, CGRectGetWidth(self.contentView.frame)-40, 50.0);
    }
}
@end
