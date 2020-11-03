//
//  SPCSuggestedFriendsHeaderView.m
//  Spayce
//
//  Created by Arria P. Owlia on 1/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCSuggestedFriendsBannerView.h"

NSString *SPCSuggestedFriendsBannerViewIdentifier = @"SPCSuggestedFriendsBannerViewIdentifier";

@interface SPCSuggestedFriendsBannerView()

// Text
@property (strong, nonatomic) UILabel *lblContent;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation SPCSuggestedFriendsBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRGBHex:0x4ca4ff];
        
        _lblContent = [[UILabel alloc] init];
        _lblContent.textColor = [UIColor whiteColor];
        _lblContent.textAlignment = NSTextAlignmentCenter;
        _lblContent.numberOfLines = 0;
        [self addSubview:_lblContent];
      
        _btnAction = [[UIButton alloc] init];
        _btnAction.backgroundColor = [UIColor clearColor];
        [self addSubview:_btnAction];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:_activityIndicator];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.lblContent.font = [UIFont fontWithName:@"OpenSans" size:(34.0f * CGRectGetHeight(self.bounds)/150.0f)];
    
    CGFloat leftRightPadding = 60.0f/750.0f * CGRectGetWidth(self.bounds);
    self.lblContent.frame = CGRectMake(leftRightPadding, 0, CGRectGetWidth(self.bounds) - 2 * leftRightPadding, CGRectGetHeight(self.bounds));
    
    self.btnAction.frame = self.bounds;
    
    CGFloat activityIndicatorDimension = MIN(CGRectGetHeight(self.lblContent.frame), CGRectGetWidth(self.lblContent.frame));
    self.activityIndicator.frame = CGRectMake(0, 0, activityIndicatorDimension, activityIndicatorDimension);
    self.activityIndicator.center = self.btnAction.center;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    // Clear text
    self.lblContent.text = nil;
    self.lblContent.hidden = YES;
    
    // Clear button actions
    [self.btnAction removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    
    // Hide the activity indicator
    self.activityIndicator.hidden = YES;
    [self.activityIndicator stopAnimating];
}

- (void)configureWithString:(NSString *)string {
    self.lblContent.hidden = NO;
    self.lblContent.text = string;
    
    self.activityIndicator.hidden = YES;
}

- (void)configureWithActivityIndicator {
    [self.activityIndicator startAnimating];
    self.activityIndicator.hidden = NO;
    
    self.lblContent.hidden = YES;
}

@end
