//
//  SPCSettingsHeaderView.m
//  Spayce
//
//  Created by William Santiago on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSettingsHeaderView.h"

@implementation SPCSettingsHeaderView

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.textLabel.frame = CGRectOffset(self.textLabel.frame, 0, 5);
}

@end
