//
//  SPCAdminWarningView.m
//  Spayce
//
//  Created by Jake Rosin on 3/4/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCAdminWarningView.h"

@interface SPCAdminWarningView ()

// Images
@property (nonatomic, strong) UIImageView *imageView;

// Text
@property (nonatomic, strong) UILabel *headerLabel;
@property (nonatomic, strong) UILabel *subheadLabel;

// Frame
@property (nonatomic, strong) UIView *contentView;

@end

@implementation SPCAdminWarningView

// Init
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        // Content
        self.backgroundColor = [UIColor clearColor];
        
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
        _contentView.layer.cornerRadius = 12.0f;
        _contentView.clipsToBounds = YES;
        [self addSubview:_contentView];
        
        // Images
        _imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"anonWarning"]];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_contentView addSubview:_imageView];
        
        // Labels
        UIFont *textFont = [UIFont fontWithName:@"OpenSans" size:42.0f/600.0f * CGRectGetWidth(frame)];
        UIColor *textColor = [UIColor blackColor];
        if ([UIScreen mainScreen].bounds.size.height <= 480) {
            textFont = [UIFont fontWithName:@"OpenSans" size:16];
        }
        _headerLabel = [[UILabel alloc] init];
        _headerLabel.text = @"Spayce Authorities are investigating you for inappropriate or abusive behavior.";
        _headerLabel.font = textFont;
        _headerLabel.textColor = textColor;
        _headerLabel.textAlignment = NSTextAlignmentCenter;
        _headerLabel.numberOfLines = 0;
        _headerLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentView addSubview:_headerLabel];
        
        
        UIFont *subheadFont = [UIFont fontWithName:@"OpenSans" size:24.0f/600.0f * CGRectGetWidth(frame)];
        UIColor *subheadColor = [UIColor colorWithRed:170.0f/255.0f green:176.0f/255.0f blue:185.0f/255.0f alpha:1.0f];
        if ([UIScreen mainScreen].bounds.size.height <= 480) {
            subheadFont = [UIFont fontWithName:@"OpenSans" size:11];
        }
        
        _subheadLabel = [[UILabel alloc] init];
        _subheadLabel.text = @"Be cautious with the content you post\ngoing forward or you will lose\naccess to your Spayce account.";
        _subheadLabel.font = subheadFont;
        _subheadLabel.textColor = subheadColor;
        _subheadLabel.textAlignment = NSTextAlignmentCenter;
        _subheadLabel.numberOfLines = 0;
        _subheadLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentView addSubview:_subheadLabel];
        
        // Button
        _btnFinished = [[UIButton alloc] init];
        _btnFinished.layer.cornerRadius = 2.0f;
        _btnFinished.layer.borderWidth = 1.0f / [UIScreen mainScreen].scale;
        _btnFinished.layer.borderColor = [UIColor colorWithRGBHex:0x6ab1fb].CGColor;
        NSDictionary *dicTitleAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:28.0f/600.0f * CGRectGetWidth(frame)],
                                              NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0x6ab1fb] };
        NSAttributedString *stringGotIt = [[NSAttributedString alloc] initWithString:@"GOT IT!" attributes:dicTitleAttributes];
        [_btnFinished setAttributedTitle:stringGotIt forState:UIControlStateNormal];
        [_contentView addSubview:_btnFinished];
    }
    return self;
}

// Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    // Finished Button - Set the size first, then the center
    self.btnFinished.frame = CGRectMake(0, 0, 340.0f/600.0f * CGRectGetWidth(self.contentView.frame), 80.0f/700.0f * CGRectGetHeight(self.contentView.frame));
    self.btnFinished.center = CGPointMake(self.contentView.center.x, 620.0f/700.0f * CGRectGetHeight(self.contentView.frame));
    
    // Images - Size first, then center
    self.imageView.frame = CGRectMake(0, 0, 266.0f/600.0f * CGRectGetWidth(self.contentView.frame), 266.0f/700.0f * CGRectGetHeight(self.contentView.frame));
    if ([UIScreen mainScreen].bounds.size.height <= 480) {
        self.imageView.frame = CGRectMake(0, 0, 246.0f/600.0f * CGRectGetWidth(self.contentView.frame), 246.0f/700.0f * CGRectGetHeight(self.contentView.frame));
    }
    
    self.imageView.center = CGPointMake(self.contentView.center.x, 130.0f/700.0f * CGRectGetHeight(self.contentView.frame));
    
    // Labels - Padding and frame - The text label looks better when it's 3 lines of text in the center of a 4-line-spaced rect
    CGFloat leftRightPadding = 40.0f/600.0f * CGRectGetWidth(self.contentView.frame);
    CGFloat imageToTextPadding = 4.0f/700.0f * CGRectGetHeight(self.contentView.frame);
    CGFloat subheadToTextPadding = 30.0f/700.0f * CGRectGetHeight(self.contentView.frame);
    self.headerLabel.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.imageView.frame) + imageToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.headerLabel.font.lineHeight * 4);
    
    self.subheadLabel.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.headerLabel.frame) + subheadToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.subheadLabel.font.lineHeight * 3);
    
}

@end