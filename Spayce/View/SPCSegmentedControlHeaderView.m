//
//  SPCSegmentedControlHeaderView.m
//  Spayce
//
//  Created by Pavel Dusatko on 7/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCSegmentedControlHeaderView.h"

@interface SPCSegmentedControlHeaderView ()

// Returns preferred height based on the state of the view
// that is being stored in the tag property
- (CGFloat)preferredHeight;

@end

@implementation SPCSegmentedControlHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    frame.size.height = self.preferredHeight;
    self.frame = frame;
}

#pragma mark - Private

- (CGFloat)preferredHeight {
    if (self.tag == 1) {
        return self.defaultHeight + self.bannerHeight;
    }
    else {
        return self.defaultHeight;
    }
}

@end
