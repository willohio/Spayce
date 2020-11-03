//
//  EmailTableCell.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/12/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "EmailTableCell.h"

@implementation EmailTableCell

#pragma mark - Object lifecycle

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.font = [UIFont boldSystemFontOfSize:15];
        self.textLabel.textColor = [UIColor colorWithRGBHex:0x484451];
        
        _textField = [[UITextField alloc] init];
        _textField.font = [UIFont spc_regularSystemFontOfSize:14];
        _textField.textColor = [UIColor colorWithRGBHex:0x817f88];
        
        [self.contentView addSubview:_textField];
    }
    return self;
}


#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectMake(10, CGRectGetMidY(self.contentView.frame)-self.textLabel.font.lineHeight/2, 50, self.textLabel.font.lineHeight);
    self.textField.frame = CGRectMake(45, CGRectGetMidY(self.contentView.frame)-self.textField.font.lineHeight/2, CGRectGetWidth(self.frame)-45, self.textField.font.lineHeight);
    
    [self roundCornersForView:self.contentView
            byRoundingCorners:UIRectCornerAllCorners
             withCornerRadius:3.0];
}

- (void)roundCornersForView:(UIView *)view byRoundingCorners:(UIRectCorner)roundingCorners withCornerRadius:(CGFloat)cornerRadius
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                               byRoundingCorners:roundingCorners
                                                     cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.path = path.CGPath;
    
    view.layer.mask = maskLayer;
}

@end
