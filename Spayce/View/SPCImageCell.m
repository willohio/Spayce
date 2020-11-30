//
//  SPCImageCell.m
//  Spayce
//
//  Created by William Santiago on 4/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCImageCell.h"

@implementation SPCImageCell

#pragma mark - UIView - Laying out Subviews

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = self.contentView.bounds;
}

@end
