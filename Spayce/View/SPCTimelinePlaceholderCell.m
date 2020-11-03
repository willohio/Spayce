//
//  SPCTimelinePlaceholderCell.m
//  Spayce
//
//  Created by Arria P. Owlia on 4/10/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCTimelinePlaceholderCell.h"

NSString *SPCTimelinePlaceholderCellIdentifier = @"SPCTimelinePlaceholderCellIdentifier";

@interface SPCTimelinePlaceholderCell()

@property (strong, nonatomic) UIImageView *ivArrow;
@property (strong, nonatomic) UIImageView *ivImages;
@property (strong, nonatomic) UILabel *lblPlaceholderText;

@end

@implementation SPCTimelinePlaceholderCell

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    CGFloat viewWidth = CGRectGetWidth(self.contentView.frame);
    CGFloat viewHeight = CGRectGetHeight(self.contentView.frame);
    const CGFloat PSD_WIDTH = 750.0f;
    const CGFloat PSD_HEIGHT = 1114.0f;
    
    self.ivImages.frame = CGRectMake(0, 0, 398.0f/PSD_WIDTH * viewWidth, 275.0f/PSD_HEIGHT * viewHeight);
    self.ivImages.center = CGPointMake(viewWidth/2.0f, 486.0f/PSD_HEIGHT * viewHeight);
    
    CGFloat arrowWidth = 186.0f/PSD_WIDTH * viewWidth;
    self.ivArrow.frame = CGRectMake(viewWidth - arrowWidth - 58.0f/PSD_WIDTH * viewWidth, 20.0f/PSD_HEIGHT * viewHeight, arrowWidth, 303.0f/PSD_HEIGHT * viewHeight);
    
    [self.lblPlaceholderText sizeToFit];
    self.lblPlaceholderText.frame = CGRectMake(viewWidth/2.0f - CGRectGetWidth(self.lblPlaceholderText.frame)/2.0f, CGRectGetMaxY(self.ivImages.frame) + 8.0f, CGRectGetWidth(self.lblPlaceholderText.frame), CGRectGetHeight(self.lblPlaceholderText.frame));
}

- (void)createPlaceholderText {
    if (nil != _lblPlaceholderText) {
        [_lblPlaceholderText removeFromSuperview];
    }
    
    // fontSize is based on screen width
    // 640 -> 14.0f; 750 -> 16.0f; 1242 -> 18.0f
    CGFloat viewWidth = CGRectGetWidth(self.bounds) * [UIScreen mainScreen].scale;
    CGFloat fontSize = 14.0f; // default
    if (640 >= viewWidth) {
        // stick with the default value
    } else if (750 >= viewWidth) {
        fontSize = 16.0f;
    } else if (1242 >= viewWidth) {
        fontSize = 18.0f;
    } else {
        fontSize = 20.0f; // even larger screen? say wutt
    }
    
    NSDictionary *textAttributes = @{ NSFontAttributeName : [UIFont fontWithName:@"OpenSans" size:fontSize],
                                      NSForegroundColorAttributeName : [UIColor colorWithRGBHex:0xa2a2a2] };
    
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:@"See today's moments made\nby the people you follow." attributes:textAttributes];
    
    _lblPlaceholderText = [[UILabel alloc] init];
    _lblPlaceholderText.textAlignment = NSTextAlignmentCenter;
    _lblPlaceholderText.numberOfLines = 2;
    _lblPlaceholderText.attributedText = attrText;
    [self.contentView addSubview:_lblPlaceholderText];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self createPlaceholderText];
    
    [self layoutSubviews];
}

#pragma mark - Init

- (instancetype)init {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // Label
    [self createPlaceholderText];
    
    // Images
    _ivImages = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-timeline-images"]];
    [self.contentView addSubview:_ivImages];
    
    // Arrow
    _ivArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-timeline-arrow"]];
    [self.contentView addSubview:_ivArrow];
}

@end
