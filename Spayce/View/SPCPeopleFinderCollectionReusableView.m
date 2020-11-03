//
//  SPCPeopleFinderCollectionReusableView.m
//  Spayce
//
//  Created by Jordan Perry on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCPeopleFinderCollectionReusableView.h"

@interface SPCPeopleFinderCollectionReusableView ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *xButton;

@end

@implementation SPCPeopleFinderCollectionReusableView

#pragma mark - Creation

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRGBHex:0xf8f8f8];
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, CGRectGetWidth(frame) - 47.0, CGRectGetHeight(frame))];
        _label.font = [UIFont fontWithName:@"OpenSans" size:10.0];
        _label.lineBreakMode = NSLineBreakByTruncatingTail;
        _label.textColor = [UIColor colorWithRGBHex:0xbbbdc1];
        _label.numberOfLines = 1;
        [self addSubview:_label];
        
        _xButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _xButton.frame = CGRectMake(CGRectGetWidth(frame) - 27.0, 0.0, 17.0, 17.0);
        _xButton.center = CGPointMake(_xButton.center.x, CGRectGetHeight(frame) / 2.0);
        _xButton.hidden = YES;
        [_xButton setImage:[UIImage imageNamed:@"button-close-gray-thin"] forState:UIControlStateNormal];
        [_xButton addTarget:self action:@selector(xButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_xButton];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.label.text = self.text;
    
    self.xButton.hidden = !self.showXButton;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.label.text = @"";
    
    self.xButton.hidden = YES;
}

- (void)setText:(NSString *)text {
    _text = [text copy];
    
    [self setNeedsLayout];
}

- (void)setShowXButton:(BOOL)showXButton {
    _showXButton = showXButton;
    
    [self setNeedsLayout];
}

- (void)xButtonPressed:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didSelectXButtonForPeopleFinderReusableView:)]) {
        [self.delegate didSelectXButtonForPeopleFinderReusableView:self];
    }
}

@end
