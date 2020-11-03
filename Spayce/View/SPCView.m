//
//  SPCView.m
//  Spayce
//
//  Created by Jake Rosin on 5/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//
//  A general-purpose view that allows customized blocks for pointInside and hitTest.

#import "SPCView.h"

@implementation SPCView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.clipsHitsToBounds = YES;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.pointInsideBlock) {
        return self.pointInsideBlock(point, event);
    } else if (!self.clipsHitsToBounds) {
        return [self hitTest:point withEvent:event] != nil;
    }
    return [super pointInside:point withEvent:event];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hitTestBlock) {
        return self.hitTestBlock(point, event);
    } else if (!self.clipsHitsToBounds && !self.hidden && self.alpha > 0) {
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


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    //NSLog(@"drawRect %@", NSStringFromCGRect(rect));
    if (self.hairlineFooterColor) {
        CGFloat lineWidth = 2.0 / [UIScreen mainScreen].scale;
        CGFloat inset = 0; //lineWidth / 2;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSaveGState(context);
        CGContextSetAllowsAntialiasing(context, NO);
        CGContextClipToRect(context, rect);
        // draw
        CGContextSetLineWidth(context, lineWidth);
        CGContextSetStrokeColorWithColor(context, self.hairlineFooterColor.CGColor);
        CGContextMoveToPoint(context, 0, CGRectGetHeight(rect) - inset);
        CGContextAddLineToPoint(context, CGRectGetWidth(rect), CGRectGetHeight(rect) - inset);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }
}

@end
