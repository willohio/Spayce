//
//  SPCProfilePlaceholderCell.m
//  Spayce
//
//  Created by Arria P. Owlia on 12/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfilePlaceholderCell.h"

@interface SPCProfilePlaceholderCell()

@property (nonatomic, strong) UIImageView *lockedImageView;
@property (nonatomic, strong) UILabel *lockedLabel;

@end

@implementation SPCProfilePlaceholderCell

// Init
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _lockedImageView = [[UIImageView alloc] init];
        _lockedImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_lockedImageView];
        
        _lockedLabel = [[UILabel alloc] init];
        _lockedLabel.font = [UIFont fontWithName:@"OpenSans" size:11.0f];
        _lockedLabel.textColor = [UIColor colorWithRGBHex:0x898989];
        [_lockedLabel sizeToFit];
        [self addSubview:_lockedLabel];
    }
    return self;
}

// Reuse
- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.lockedImageView.image = nil;
    self.lockedLabel.text = nil;
}

// Layout
- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.lockedImageView sizeToFit];
    [self.lockedLabel sizeToFit];
    
    _lockedImageView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2, CGRectGetHeight(self.bounds) / 2);
    _lockedLabel.center = CGPointMake(_lockedImageView.center.x, CGRectGetMaxY(_lockedImageView.frame) + CGRectGetHeight(_lockedLabel.frame)/2 + 8);
}

// Configuration
- (void)configureWithImage:(UIImage *)image andText:(NSString *)text {
    self.lockedImageView.image = image;
    self.lockedLabel.text = text;
    
    [self setNeedsLayout];
}

@end
