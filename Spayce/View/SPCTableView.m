//
//  SPCTableView.m
//  Spayce
//
//  Created by Jake Rosin on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTableView.h"



@implementation SPCTableView


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clipsHitsToBounds = YES;
    }
    return self;
}

- (void)addUntouchableContentRegion:(CGRect)rect {
    [self.untouchableContentRegions addObject:[NSValue valueWithCGRect:rect]];
}


#pragma mark - Accessors

- (NSMutableArray *) untouchableContentRegions {
    if (!_untouchableContentRegions) {
        _untouchableContentRegions = [[NSMutableArray alloc] init];
    }
    return _untouchableContentRegions;
}

#pragma mark - Touch Events

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    for (NSValue * value in self.untouchableContentRegions) {
        CGRect rect = [value CGRectValue];
        if (CGRectContainsPoint(rect, point)) {
            // untouchable!
            return nil;
        }
    }
    if (!self.clipsHitsToBounds) {
        for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if (result) {
                return result;
            }
        }
        return nil;
    }
    return [super hitTest:point withEvent:event];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (NSValue * value in self.untouchableContentRegions) {
        CGRect rect = [value CGRectValue];
        if (CGRectContainsPoint(rect, point)) {
            // untouchable!
            return NO;
        }
    }
    if (!self.clipsHitsToBounds) {
        return YES;
    }
    return [super pointInside:point withEvent:event];
}

@end
