//
//  SPCGetStartedTableViewCell.m
//  Spayce
//
//  Created by Christopher Taylor on 11/18/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCGetStartedTableViewCell.h"

@interface SPCGetStartedTableViewCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;

@end

@implementation SPCGetStartedTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.text = @"Add Friends!";
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont spc_boldSystemFontOfSize:14];
        self.titleLabel.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        
        [self.contentView addSubview:self.titleLabel];
        
        self.subTitleLabel = [[UILabel alloc] init];
        self.subTitleLabel.text = NSLocalizedString(@"Spayce is better with friends.", nil);
        self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
        self.subTitleLabel.font = [UIFont spc_regularSystemFontOfSize:14];
        self.subTitleLabel.numberOfLines = 0;
        self.subTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.subTitleLabel.textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
        
        [self.contentView addSubview:self.subTitleLabel];
        
        self.addFriendsButton = [[UIButton alloc] init];
        self.addFriendsButton.backgroundColor = [UIColor colorWithRGBHex:0x6ab1fb];
        self.addFriendsButton.titleLabel.font = [UIFont spc_boldSystemFontOfSize:14.0f];
        self.addFriendsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self.addFriendsButton setTitle:@"Add Friends" forState:UIControlStateNormal];
        [self.addFriendsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.addFriendsButton.layer.cornerRadius = 2.0f;
        
        [self.contentView addSubview:self.addFriendsButton];        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.titleLabel.frame = CGRectMake(0, 115, self.bounds.size.width, 20);
    self.subTitleLabel.frame = CGRectMake(0, 140, self.bounds.size.width, self.subTitleLabel.font.lineHeight);
    self.addFriendsButton.frame = CGRectMake((CGRectGetWidth(self.bounds) - 250) / 2, CGRectGetMaxY(self.subTitleLabel.frame) + 17, 250, 45);
}

@end
