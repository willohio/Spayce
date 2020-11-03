//
//  SPCSolidButton.m
//  Spayce
//
//  Created by Pavel Dusatko on 10/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSolidButton.h"

@implementation SPCSolidButton

#pragma mark - Private

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    self.backgroundColor = highlighted ? self.highlightedBackgroundColor : self.normalBackgroundColor;
}

@end
