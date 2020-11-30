//
//  SPCRoundedLineButton.m
//  Spayce
//
//  Created by William Santiago on 9/18/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCRoundedLineButton.h"

@implementation SPCRoundedLineButton

#pragma mark - Private

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    self.layer.borderColor = highlighted ? self.highlightedLineColor.CGColor : self.normalLineColor.CGColor;
}

@end
