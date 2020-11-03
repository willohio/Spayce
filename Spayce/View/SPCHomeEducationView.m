//
//  SPCHomeEducationView.m
//  Spayce
//
//  Created by Arria P. Owlia on 12/18/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHomeEducationView.h"

// Category
#import "UIFont+SPCAdditions.h"

@interface SPCHomeEducationView()

// Images
@property (nonatomic, strong) UIImageView *imageViewAround;
@property (nonatomic, strong) UIImageView *imageViewPlaces;

// Text
@property (nonatomic, strong) UILabel *labelAround;
@property (nonatomic, strong) UILabel *labelPlaces;

// Frame
@property (nonatomic, strong) UIView *contentView;

@end

@implementation SPCHomeEducationView

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
        NSAssert(nil != [UIImage imageNamed:@"education-around"], @"This image was deleted from the asset catalog. Do not use this view until the image has been re-added");
        _imageViewAround = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"education-around"]];
        _imageViewAround.contentMode = UIViewContentModeScaleAspectFit;
        [_contentView addSubview:_imageViewAround];
        
        NSAssert(nil != [UIImage imageNamed:@"education-places"], @"This image was deleted from the asset catalog. Do not use this view until the image has been re-added");
        _imageViewPlaces = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"education-places"]];
        _imageViewPlaces.contentMode = UIViewContentModeScaleAspectFit;
        [_contentView addSubview:_imageViewPlaces];
      
        // Labels
        UIFont *textFont = [UIFont fontWithName:@"OpenSans" size:42.0f/600.0f * CGRectGetWidth(frame)];
        UIColor *textColor = [UIColor blackColor];
        _labelAround = [[UILabel alloc] init];
        _labelAround.text = @"See what's happening\naround you in real time";
        _labelAround.font = textFont;
        _labelAround.textColor = textColor;
        _labelAround.textAlignment = NSTextAlignmentCenter;
        _labelAround.numberOfLines = 0;
        _labelAround.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentView addSubview:_labelAround];
        
        _labelPlaces = [[UILabel alloc] init];
        _labelPlaces.text = @"Leave memories in places everywhere you go";
        _labelPlaces.font = textFont;
        _labelPlaces.textColor = textColor;
        _labelPlaces.textAlignment = NSTextAlignmentCenter;
        _labelPlaces.numberOfLines = 0;
        _labelPlaces.lineBreakMode = NSLineBreakByWordWrapping;
        [_contentView addSubview:_labelPlaces];
      
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
    self.imageViewAround.frame = CGRectMake(0, 0, 146.0f/600.0f * CGRectGetWidth(self.contentView.frame), 146.0f/880.0f * CGRectGetHeight(self.contentView.frame));
    self.imageViewAround.center = CGPointMake(self.contentView.center.x, (152.0f - customSpacing)/880.0f * CGRectGetHeight(self.contentView.frame));
    self.imageViewPlaces.frame = CGRectMake(0, 0, 136.0f/600.0f * CGRectGetWidth(self.contentView.frame), 118.0f/880.0f * CGRectGetHeight(self.contentView.frame));
    self.imageViewPlaces.center = CGPointMake(self.contentView.center.x, (474.0f + customSpacing)/880.0f * CGRectGetHeight(self.contentView.frame));
    
    // Labels - Padding and frame
    CGFloat leftRightPadding = 40.0f/600.0f * CGRectGetWidth(self.contentView.frame);
    CGFloat imageToTextPadding = 16.0f/880.0f * CGRectGetHeight(self.contentView.frame);
    self.labelAround.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.imageViewAround.frame) + imageToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.labelAround.font.lineHeight * 2);
    self.labelPlaces.frame = CGRectMake(leftRightPadding, CGRectGetMaxY(self.imageViewPlaces.frame) + imageToTextPadding, CGRectGetWidth(self.contentView.frame) - 2 * leftRightPadding, self.labelPlaces.font.lineHeight * 2);
}
@end
