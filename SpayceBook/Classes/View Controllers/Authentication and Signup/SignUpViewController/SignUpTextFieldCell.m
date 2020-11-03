//
//  SignUpTextFieldCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpTextFieldCell.h"
#import "SignUpSingleTextFieldCell.h"
#import "SignUpDoubleTextFieldCell.h"

@implementation SignUpTextFieldCell

#pragma mark - UITableViewCell - Initializing a UITableViewCell Object

+ (id)createCellWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier type:(NSInteger)type {
    if (type == TextFieldCellTypeSingle) {
        return [[SignUpSingleTextFieldCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
    } else if (type == TextFieldCellTypeDouble) {
        return [[SignUpDoubleTextFieldCell alloc] initWithStyle:style reuseIdentifier:reuseIdentifier];
    } else {
        return nil;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    float cRad = 2;
    
    if (self.top && self.down) {
        self.layer.cornerRadius = cRad;
        self.layer.masksToBounds = YES;
    }
    else if (self.top) {
        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
        shape.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(cRad, cRad)].CGPath;
        self.layer.mask = shape;
        self.layer.masksToBounds = YES;
    }
    else if (self.down) {
        CAShapeLayer *shape = [[CAShapeLayer alloc] init];
        shape.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height) byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight cornerRadii:CGSizeMake(cRad, cRad)].CGPath;
        self.layer.mask = shape;
        self.layer.masksToBounds = YES;
    }
    else {
        self.layer.masksToBounds = NO;
    }
}

@end
