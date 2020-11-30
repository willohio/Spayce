//
//  SignUpButton.m
//  Spayce
//
//  Created by William Santiago on 3/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SignUpButton.h"

@implementation SignUpButton

#pragma mark - Setting and Getting Control Attributes

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (highlighted) {
        self.backgroundColor = self.highlightedBackgroundColor;
    } else {
        self.backgroundColor = self.normalBackgroundColor;
    }
}

@end
