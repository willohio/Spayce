//
//  SignUpTextField.m
//  Spayce
//
//  Created by William Santiago on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpTextField.h"
#import "UIView+Shake.h"

@implementation SignUpTextField

#pragma mark - Managing the Responder Chain

- (BOOL)becomeFirstResponder {
    if (self.isInvalid) {
        [self shake:10 withDelta:5 andSpeed:0.03 shakeDirection:ShakeDirectionHorizontal];
    }
    return [super becomeFirstResponder];
}

#pragma mark - Accessors

- (void)setInvalid:(BOOL)invalid {
    if (_invalid != invalid) {
        _invalid = invalid;
        [self setNeedsLayout];
    }
}

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Only highlight text if there's some text
    // We don't want to show the text changed
    // for a brief amount of time when typing
    // the first character
    if (self.isInvalid && self.text.length > 0) {
        self.textColor = self.highlightedTextColor;
    } else {
        self.textColor = self.normalTextColor;
    }
    self.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14];
}

#pragma mark - UITextField - Drawing and Positioning Overrides

- (CGRect)textRectForBounds:(CGRect)bounds {
	return [self adjustedRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	return [self adjustedRectForBounds:bounds];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
	return [self adjustedRectForBounds:bounds];
}

- (CGRect)adjustedRectForBounds:(CGRect)bounds {
	CGFloat	indentation		= 10.0;
	CGRect	adjustedBounds	= bounds;
	
	adjustedBounds.size.width -= indentation * 2;
    adjustedBounds.size.width -= (self.rightViewMode == UITextFieldViewModeAlways ? CGRectGetWidth(self.rightView.frame) : 0.0);
	adjustedBounds.origin.x += indentation;
	
	return adjustedBounds;
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
    return CGRectMake(CGRectGetWidth(bounds)-CGRectGetWidth(self.rightView.frame)-10, CGRectGetMidY(bounds)-CGRectGetHeight(self.rightView.frame)/2, CGRectGetWidth(self.rightView.frame), CGRectGetHeight(self.rightView.frame));
}

@end
