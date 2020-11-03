//
//  SPCStarCountButton.m
//  Spayce
//
//  Created by Pavel Dusatko on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCStarCountButton.h"

@implementation SPCStarCountButton

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideButton) object:nil];
}

#pragma mark - Accessors

- (void)setCount:(NSInteger)count {
    _count = count;
    
    [self updateTitle];
}

#pragma mark - Private

- (NSString *)titleString {
    NSInteger count = self.count;
    
    if (count > 99) {
        return [NSString stringWithFormat:@"99+"];
    }
    else {
        return [NSString stringWithFormat:@"%@", @(count)];
    }
}

- (void)updateTitle {
    NSInteger count = self.count;
    
    if (count > 0) {
        NSString *titleString = [self titleString];
        
        [self setTitleEdgeInsets:UIEdgeInsetsMake(- 3.0, - (CGRectGetWidth(self.frame) / 2.0 + 2.0 + (3.0 - titleString.length)), 0.0, 0.0)];
        [self setTitle:titleString forState:UIControlStateNormal];
    }
    else {
        [self setTitleEdgeInsets:UIEdgeInsetsMake(- 3.0, - (CGRectGetWidth(self.frame) / 2.0 + 2.0 + (3.0 - 1.0)), 0.0, 0.0)];
        [self setTitle:@"1" forState:UIControlStateNormal];
    }
    
    self.tag = count > 0 ? 101 : 100;
}

#pragma mark - Actions

- (void)hideButton {
    self.tag = 100;
    
    [UIView animateWithDuration:0.35 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)hideButtonAfterDelay:(NSTimeInterval)delay {
    // Cancel previous attempts to hide with delay
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideButton) object:nil];
    // Hide after a delay of X seconds
    [self performSelector:@selector(hideButton) withObject:nil afterDelay:delay];
}

@end
