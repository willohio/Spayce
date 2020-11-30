//
//  SPCLocationPromptCell.m
//  Spayce
//
//  Created by William Santiago on 6/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLocationPromptCell.h"
#import "UIScreen+Size.h"

@implementation SPCLocationPromptCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
        
        self.contentView.backgroundColor = [UIColor whiteColor];
        self.contentView.layer.cornerRadius = 3.0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        self.textLabel.font = [UIFont spc_memory_actionButtonFont];
        self.textLabel.textColor = [UIColor colorWithRed:0.408 green:0.588 blue:0.875 alpha:1.000];
        self.textLabel.backgroundColor = [UIColor clearColor];
        
        self.detailTextLabel.font = [UIFont spc_regularFont];
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.588 alpha:1.000];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        self.detailTextLabel.numberOfLines = 3;
        self.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        
        _actionButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _actionButton.backgroundColor = [UIColor colorWithRed:0.553 green:0.765 blue:0.192 alpha:1.000];
        _actionButton.layer.cornerRadius = 3.0;
        _actionButton.titleLabel.font = [UIFont spc_mediumFont];
        [_actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.contentView addSubview:_actionButton];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat verticalOffset = 5.0;
    CGFloat contentHeight = 160.0;
    CGFloat buttonOffset = 15.0;
    
    if (![UIScreen isLegacyScreen]) {
        verticalOffset = 30.0;
        contentHeight = 190.0;
        buttonOffset = 55.0;
    }
    
    self.contentView.frame = CGRectMake(5.0, verticalOffset, CGRectGetWidth(self.frame) - 10.0, contentHeight);
    self.textLabel.frame = CGRectMake(40.0, 20.0, CGRectGetWidth(self.contentView.frame) - 80.0, CGRectGetHeight(self.textLabel.frame));
    self.detailTextLabel.frame = CGRectMake(CGRectGetMinX(self.textLabel.frame), CGRectGetMaxY(self.textLabel.frame) + 5.0, CGRectGetWidth(self.textLabel.frame), self.detailTextLabel.font.lineHeight * 3.0);
    self.actionButton.frame = CGRectMake(35.0, CGRectGetMaxY(self.contentView.frame) - 50.0 - buttonOffset, 250.0, 50.0);
}

@end
