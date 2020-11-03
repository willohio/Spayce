//
//  SignUpErrorCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpErrorCell.h"

@implementation SignUpErrorCell

#pragma mark - UITableViewCell - Initializing a UITableViewCell Object

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _errorLabel = [[UILabel alloc] init];
        _errorLabel.textAlignment = NSTextAlignmentCenter;
        _errorLabel.textColor = [UIColor redColor];
        _errorLabel.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_errorLabel];
    }
    return self;
}

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat offsetY = 3.0;
    
    // Layout label
    self.errorLabel.frame = CGRectMake(0.0, offsetY, CGRectGetWidth(self.contentView.frame), CGRectGetHeight(self.contentView.frame)-offsetY);
}

@end
