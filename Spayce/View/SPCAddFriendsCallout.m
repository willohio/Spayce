//
//  SPCAddFriendsCallout.m
//  Spayce
//
//  Created by Arria P. Owlia on 12/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAddFriendsCallout.h"

@interface SPCAddFriendsCallout()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation SPCAddFriendsCallout

// Init
- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
    
    // Create title tabel
    _textLabel = [[UILabel alloc] init];
    NSDictionary *textAttributes = @{ NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x8b99af],
                                      NSFontAttributeName : [UIFont spc_regularSystemFontOfSize:14.0f] };
    NSString *text = NSLocalizedString(@"The Feed shows all of your\nfriends' memories.", nil);
    _textLabel.numberOfLines = 2;
    _textLabel.textAlignment = NSTextAlignmentCenter;
    _textLabel.attributedText = [[NSAttributedString alloc] initWithString:text attributes:textAttributes];
    [self addSubview:_textLabel];
    
    // Create Add Friends button
    UIButton *addFriendsButton = [[UIButton alloc] init];
    NSDictionary *buttonTextAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                            NSFontAttributeName : [UIFont spc_boldSystemFontOfSize:14.0f]};
    NSString *buttonText = NSLocalizedString(@"Add Friends", nil);
    NSAttributedString *attributedButtonText = [[NSAttributedString alloc] initWithString:buttonText attributes:buttonTextAttributes];
    [addFriendsButton setAttributedTitle:attributedButtonText forState:UIControlStateNormal];
    [addFriendsButton setBackgroundColor:[UIColor colorWithRGBHex:0x6ab1fb]];
    addFriendsButton.layer.cornerRadius = 2.0f;
    _addFriendsButton = addFriendsButton;
    [self addSubview:_addFriendsButton];
    
    // Create Close button
    UIButton *closeButton = [[UIButton alloc] init];
    [closeButton setImage:[UIImage imageNamed:@"button-close-gray-thin"] forState:UIControlStateNormal];
    [closeButton.imageView setContentMode:UIViewContentModeCenter]; // Do not scale the image
    _closeButton = closeButton;
    [self addSubview:_closeButton];
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.textLabel.frame = CGRectMake(0, 28, CGRectGetWidth(self.bounds), 2 * self.textLabel.font.lineHeight);
  self.addFriendsButton.frame = CGRectMake((CGRectGetWidth(self.bounds) - 250) / 2, CGRectGetMaxY(self.textLabel.frame) + 12, 250, 45);
  self.closeButton.frame = CGRectMake(CGRectGetWidth(self.bounds) - 44, 0, 44, 44);
}

@end
