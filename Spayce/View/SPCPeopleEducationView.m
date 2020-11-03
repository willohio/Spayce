//
//  SPCPeopleEducationView.m
//  Spayce
//
//  Created by Arria P. Owlia on 12/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCPeopleEducationView.h"

// Category
#import "UIFont+SPCAdditions.h"

@interface SPCPeopleEducationView()

// Images
@property (nonatomic, strong) UIImageView *imageViewStars;
@property (nonatomic, strong) UIImageView *imageViewTrophies;

// Text
@property (nonatomic, strong) UILabel *labelStars;
@property (nonatomic, strong) UILabel *labelTrophies;

// Frame
@property (nonatomic, strong) UIView *contentView;

@end

@implementation SPCPeopleEducationView

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
        _imageViewStars = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"education-stars"]];
        _imageViewStars.contentMode = UIViewContentModeScaleAspectFit;
        [_contentView addSubview:_imageViewStars];
        
        _imageViewTrophies = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"education-trophies"]];
        _imageViewTrophies.contentMode = UIViewContentModeScaleAspectFit;
        [_contentView addSubview:_imageViewTrophies];
        
        // Labels
        UIFont *textFont = [UIFont fontWithName:@"OpenSans" size:42.0f/600.0f * CGRectGetWidth(frame)];
        UIColor *textColor = [UIColor blackColor];
        _labelStars = [[UILabel alloc] init];
        _labelStars.text = @"Stars are likes. Earn them\non great memories";
        _labelStars.font = textFont;
        _labelStars.textColor = textColor;
        _labelStars.textAlignment = NSTextAlignmentCenter;
        _labelStars.numberOfLines = 0;
        _labelStars.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentView addSubview:_labelStars];
        
        _labelTrophies = [[UILabel alloc] init];
        _labelTrophies.text = @"Grow your local popularity\nby earning stars";
        _labelTrophies.font = textFont;
        _labelTrophies.textColor = textColor;
        _labelTrophies.textAlignment = NSTextAlignmentCenter;
        _labelTrophies.numberOfLines = 0;
        _labelTrophies.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentView addSubview:_labelTrophies];
        
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
    self.btnFinished.frame = CGRectMake(0, 0, 340.0f/600.0f * CGRectGetWidth(self.contentView.frame), 80.0f/880.0f * CGRectGetHeight(self.contentView.frame));
    self.btnFinished.center = CGPointMake(self.contentView.center.x, 778.0f/880.0f * CGRectGetHeight(self.contentView.frame));
    
    // For the iPhone 4/5/s screen, we have an explicit request for custom spacing.
    CGFloat customSpacing = 0.0f; if (320 == [UIScreen mainScreen].bounds.size.width) { customSpacing = 8.0f; }
    // Images - Size first, then center
    self.imageViewStars.frame = CGRectMake(0, 0, 123.0f/600.0f * CGRectGetWidth(self.contentView.frame), 116.0f/880.0f * CGRectGetHeight(self.contentView.frame));
    self.imageViewStars.center = CGPointMake(self.contentView.center.x, (152.0f - customSpacing)/880.0f * CGRectGetHeight(self.contentView.frame));
    self.imageViewTrophies.frame = CGRectMake(0, 0, 146.0f/600.0f * CGRectGetWidth(self.contentView.frame), 93.0f/880.0f * CGRectGetHeight(self.contentView.frame));
    self.imageViewTrophies.center = CGPointMake(self.contentView.center.x, (474.0f + customSpacing)/880.0f * CGRectGetHeight(self.contentView.frame));
    NSLog( @"Trophies Frame: %@", NSStringFromCGRect(self.imageViewTrophies.frame));
    
    // Labels - Padding and frame
    CGFloat leftRightPadding = 40.0f/600.0f * CGRectGetWidth(self.contentView.frame);
    CGFloat imageToTextPadding = 16.0f/880.0f * CGRectGetHeight(self.contentView.frame);
    self.labelStars.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.imageViewStars.frame) + imageToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.labelStars.font.lineHeight * 2);
    self.labelTrophies.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.imageViewTrophies.frame) + imageToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.labelTrophies.font.lineHeight * 2);
}

@end
