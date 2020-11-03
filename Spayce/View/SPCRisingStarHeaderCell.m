//
//  SPCRisingStarHeaderCell.m
//  Spayce
//
//  Created by Jake Rosin on 4/1/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCRisingStarHeaderCell.h"

// Model
#import "SPCNeighborhood.h"

@interface SPCRisingStarHeaderCell()

// Data
@property (nonatomic, assign) BOOL risingStars;
@property (nonatomic, strong) SPCNeighborhood *neighborhood;

// Views
@property (nonatomic, strong) UIView *backdropView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation SPCRisingStarHeaderCell


#pragma mark Object lifecycle

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _backdropView = [[UIView alloc] initWithFrame:self.bounds];
        _backdropView.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        self.contentView.clipsToBounds = NO;
        self.clipsToBounds = NO;
        [self addSubview:_backdropView];
        
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont fontWithName:@"OpenSans" size:14.0f/375.0f * CGRectGetWidth(self.bounds)];
        _label.textColor = [UIColor colorWithRGBHex:0x898989];
        [self addSubview:_label];
    }
    return self;
}


#pragma mark layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.label sizeToFit];
    self.label.center = CGPointMake(CGRectGetWidth(self.frame)/2 + self.textCenterOffset.x, CGRectGetHeight(self.frame)/2 + self.textCenterOffset.y);
    CGRect backdropFrame = self.bounds;
    backdropFrame.size.height += self.bottomOverreach;
    self.backdropView.frame = backdropFrame;
}


# pragma mark mutators

- (void)setTextCenterOffset:(CGPoint)textCenterOffset {
    _textCenterOffset = textCenterOffset;
    _label.center = CGPointMake(CGRectGetWidth(self.frame)/2 + textCenterOffset.x, CGRectGetHeight(self.frame)/2 + textCenterOffset.y);
}

- (void)setBottomOverreach:(CGFloat)bottomOverreach {
    _bottomOverreach = bottomOverreach;
    CGRect backdropFrame = self.bounds;
    backdropFrame.size.height += bottomOverreach;
    self.backdropView.frame = backdropFrame;
}


#pragma mark content changes

- (void)configureWithNeighborhood:(SPCNeighborhood *)neighborhood risingStars:(BOOL)risingStars {
    _neighborhood = neighborhood;
    _risingStars = risingStars;
    
    NSString *formatString = NSLocalizedString(@"RISING STARS IN %@", nil);
    
    // we want the most specific possible text.
    NSString *placeName = nil;
    if (neighborhood.neighborhood.length > 0) {
        placeName = neighborhood.neighborhood;
    } else if (neighborhood.cityFullName.length > 0) {
        placeName = neighborhood.cityFullName;
    } else if (neighborhood.county.length > 0) {
        placeName = neighborhood.county;
    } else if (neighborhood.stateFullName.length > 0) {
        placeName = neighborhood.stateFullName;
    } else if (neighborhood.countryFullName.length > 0) {
        placeName = neighborhood.countryFullName;
    }
    
    NSString *text;
    if (!placeName) {
        text = NSLocalizedString(@"RISING STARS", nil);
    } else {
        text = [NSString stringWithFormat:formatString, [placeName uppercaseString]];
    }
    
    _label.text = text;
    [_label sizeToFit];
    _label.center = CGPointMake(CGRectGetWidth(self.frame)/2 + self.textCenterOffset.x, CGRectGetHeight(self.frame)/2 + self.textCenterOffset.y);
}


@end
