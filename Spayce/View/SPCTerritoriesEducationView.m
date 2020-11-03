//
//  SPCTerritoriesEducationView.m
//  Spayce
//
//  Created by Arria P. Owlia on 1/21/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCTerritoriesEducationView.h"

@interface SPCTerritoriesEducationView()

// Images
@property (nonatomic, strong) UIImageView *imageViewFlag;

// Text
@property (nonatomic, strong) UILabel *labelFlag;

// Frame
@property (nonatomic, strong) UIView *contentView;

@end

@implementation SPCTerritoriesEducationView

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
    _imageViewFlag = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"education-flag"]];
    _imageViewFlag.contentMode = UIViewContentModeScaleAspectFit;
    [_contentView addSubview:_imageViewFlag];
    
    // Labels
    UIFont *textFont = [UIFont fontWithName:@"OpenSans" size:42.0f/600.0f * CGRectGetWidth(frame)];
    UIColor *textColor = [UIColor blackColor];
    _labelFlag = [[UILabel alloc] init];
    _labelFlag.text = @"Collect territories as you leave memories in new cities and neighborhoods";
    _labelFlag.font = textFont;
    _labelFlag.textColor = textColor;
    _labelFlag.textAlignment = NSTextAlignmentCenter;
    _labelFlag.numberOfLines = 0;
    _labelFlag.lineBreakMode = NSLineBreakByWordWrapping;
    [_contentView addSubview:_labelFlag];
    
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
  self.btnFinished.center = CGPointMake(self.contentView.center.x, 580.0f/700.0f * CGRectGetHeight(self.contentView.frame));
  
  // Images - Size first, then center
  self.imageViewFlag.frame = CGRectMake(0, 0, 112.0f/600.0f * CGRectGetWidth(self.contentView.frame), 130.0f/700.0f * CGRectGetHeight(self.contentView.frame));
  self.imageViewFlag.center = CGPointMake(self.contentView.center.x, 148.0f/700.0f * CGRectGetHeight(self.contentView.frame));
  
  // Labels - Padding and frame - The text label looks better when it's 3 lines of text in the center of a 4-line-spaced rect
  CGFloat leftRightPadding = 40.0f/600.0f * CGRectGetWidth(self.contentView.frame);
  CGFloat imageToTextPadding = 24.0f/700.0f * CGRectGetHeight(self.contentView.frame);
  self.labelFlag.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.imageViewFlag.frame) + imageToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.labelFlag.font.lineHeight * 4);
}

@end
