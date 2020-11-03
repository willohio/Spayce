//
//  SignUpSingleTextFieldCell.m
//  Spayce
//
//  Created by Pavel Dusatko on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpSingleTextFieldCell.h"
#import "SignUpTextField.h"

@implementation SignUpSingleTextFieldCell

#pragma mark - UITableViewCell - Initializing a UITableViewCell Object

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        NSMutableArray *mutableTextFields = [NSMutableArray arrayWithCapacity:2];
        
        self.iconImgView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self.iconImgView];
        
        SignUpTextField *textField = [[SignUpTextField alloc] init];
        textField.tag = 0;
        textField.normalTextColor = [UIColor blackColor];
        textField.highlightedTextColor = [UIColor redColor];
        [mutableTextFields addObject:textField];
        [self.contentView addSubview:textField];
        
        self.textFields = [NSArray arrayWithArray:mutableTextFields];
        
        UIView *separatorView = [[UIView alloc] init];
        separatorView.backgroundColor = [UIColor colorWithWhite:240.0/255.0 alpha:1.0];
        separatorView.tag = 666;
        [self.contentView addSubview:separatorView];
    }
    return self;
}

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Layout firstname text field
    
    self.iconImgView.frame = CGRectMake(10, 10, 20, 20);
    
    UITextField *firstTextField = self.textFields[0];
    firstTextField.frame = CGRectMake(30, 0, CGRectGetWidth(self.contentView.frame)-30, CGRectGetHeight(self.contentView.frame));
    
    // Layout separator
    UIView *separatorView = [self.contentView viewWithTag:666];
    separatorView.frame = CGRectMake(0.0, CGRectGetMaxY(self.contentView.frame)-1.0, CGRectGetWidth(self.contentView.frame), 1.0);
    
    if (self.down) {
        separatorView.hidden = YES;
    }

}

@end
