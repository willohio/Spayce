//
//  SignUpDoubleTextFieldCell.m
//  Spayce
//
//  Created by William Santiago on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpDoubleTextFieldCell.h"

// View
#import "SignUpTextField.h"

@implementation SignUpDoubleTextFieldCell

#pragma mark - UITableViewCell - Initializing a UITableViewCell Object

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UIView *shadeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
        shadeView.backgroundColor = [UIColor colorWithWhite:234.0f/255.0f alpha:1.0f];
        [self.contentView addSubview:shadeView];
        
        self.button = [[SignUpProfileButton alloc] init];
        self.button.backgroundColor = [UIColor whiteColor];
        self.button.contentMode = UIViewContentModeScaleAspectFit;
        self.button.clipsToBounds = YES;
        self.button.highlightedBorderColor = [UIColor redColor];
        [self.contentView addSubview:self.button];
        
        NSMutableArray *mutableTextFields = [NSMutableArray arrayWithCapacity:2];
        
        SignUpTextField *textField = [[SignUpTextField alloc] init];
        textField.tag = 0;
        textField.normalTextColor = [UIColor blackColor];
        textField.highlightedTextColor = [UIColor redColor];
        [mutableTextFields addObject:textField];
        [self.contentView addSubview:textField];
        
        textField = [[SignUpTextField alloc] init];
        textField.tag = 1;
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
    
    //layout button
    CGFloat radius = 32.0;
    
    // Layout button
    self.button.frame = CGRectMake(13, 13, radius * 2, radius * 2);
    self.button.layer.cornerRadius = radius;
    self.button.backgroundColor = [UIColor clearColor];
    
    // Layout firstname text field
    UITextField *firstTextField = self.textFields[0];
    firstTextField.frame = CGRectMake(90, 0, CGRectGetWidth(self.contentView.frame) - radius * 2, CGRectGetHeight(self.contentView.frame)/2);
    
    // Layout lastname text field
    UITextField *lastTextField = self.textFields[1];
    lastTextField.frame = CGRectMake(90, CGRectGetMaxY(firstTextField.frame), CGRectGetWidth(self.contentView.frame) - 90, CGRectGetHeight(self.contentView.frame)/2);
    
    // Layout separators
    UIView *separatorView = [self.contentView viewWithTag:666];
    separatorView.frame = CGRectMake(90, CGRectGetMaxY(firstTextField.frame)-1.0, CGRectGetWidth(self.contentView.frame) - 90, 1.0);
    
}

@end
