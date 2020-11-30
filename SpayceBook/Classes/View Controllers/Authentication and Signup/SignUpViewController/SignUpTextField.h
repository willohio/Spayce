//
//  SignUpTextField.h
//  Spayce
//
//  Created by William Santiago on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignUpTextField : UITextField

@property (nonatomic, assign, getter = isInvalid) BOOL invalid;
@property (nonatomic, strong) UIColor *normalTextColor;
@property (nonatomic, strong) UIColor *highlightedTextColor;

- (CGRect)adjustedRectForBounds:(CGRect)bounds;

@end
