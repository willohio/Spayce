//
//  SignUpProfileButton.m
//  Spayce
//
//  Created by Pavel Dusatko on 3/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpProfileButton.h"
#import "UIView+Shake.h"

@implementation SignUpProfileButton

#pragma mark - UIButton - Managing the Responder Chain

- (BOOL)becomeFirstResponder {
    if (self.isInvalid) {
        [self shake:10 withDelta:5 andSpeed:0.03 shakeDirection:ShakeDirectionHorizontal];
    }
    return [super becomeFirstResponder];
}

#pragma mark - UIButton - ?

- (void)setBackgroundImage:(UIImage *)image forState:(UIControlState)state {
    if (!image) {
        [super setBackgroundImage:self.customPlaceholderImage forState:state];
    } else {
        [super setBackgroundImage:image forState:state];
    }
}

#pragma mark - Accessors

- (void)setInvalid:(BOOL)invalid {
    if (_invalid != invalid) {
        _invalid = invalid;
        [self setNeedsLayout];
    }
}

- (void)setCustomPlaceholderImage:(UIImage *)customPlaceholderImage {
    if (_customPlaceholderImage != customPlaceholderImage) {
        _customPlaceholderImage = customPlaceholderImage;
        
        if (!_customBackgroundImage) {
            _customBackgroundImage = customPlaceholderImage;
        }
    }
}

- (void)setCustomBackgroundImage:(UIImage *)customBackgroundImage {
    if (_customBackgroundImage != customBackgroundImage) {
        _customBackgroundImage = customBackgroundImage;
        
        [self setBackgroundImage:customBackgroundImage forState:UIControlStateNormal];
    }
}

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.isInvalid) {
        self.layer.borderColor = self.highlightedBorderColor.CGColor;
        self.layer.borderWidth = 1.0;
    } else {
        self.layer.borderColor = nil;
        self.layer.borderWidth = 0.0;
    }
}

@end
