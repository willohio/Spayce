//
//  PXProgressView.m
//  Spayce
//
//  Created by Pavel Dušátko on 10/17/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "PXProgressView.h"

@implementation PXProgressView

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    NSUInteger ticks = self.ticks;
    NSUInteger progressTicks = MIN(self.progressTicks, ticks);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIImage *tickImage = [UIImage imageNamed:@"ellipsis-blue"];
    CGFloat elipsesRadius = 6;
    CGFloat paddingHorizontal = 20;
    CGFloat width = rect.size.width-2*paddingHorizontal;
    CGFloat tickWidth = width/(ticks-1);
    
    // Line
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:103.0/255.0 green:120.0/255.0 blue:140.0/255.0 alpha:1.0].CGColor);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, paddingHorizontal, rect.size.height/2);
    CGContextAddLineToPoint(context, paddingHorizontal+width, rect.size.height/2);
    CGContextStrokePath(context);
    
    // Ticks
    for (int i = 0; i < ticks; i++) {
        if (i < progressTicks) {
            if (i > 0) {
                CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:74.0/255.0 green:203.0/255.0 blue:235.0/255.0 alpha:1.0].CGColor);
                
                CGContextBeginPath(context);
                CGContextMoveToPoint(context, paddingHorizontal+(i-1)*tickWidth, rect.size.height/2);
                CGContextAddLineToPoint(context, paddingHorizontal+i*tickWidth, rect.size.height/2);
                CGContextStrokePath(context);
            }
            
            CGRect frame = CGRectMake(paddingHorizontal+i*tickWidth-tickImage.size.width/2,
                                      rect.size.height/2-tickImage.size.height/2,
                                      tickImage.size.width,
                                      tickImage.size.height);
            [tickImage drawInRect:frame];
        } else {
            CGRect frame = CGRectMake(paddingHorizontal+i*tickWidth-elipsesRadius/2,
                                      rect.size.height/2-elipsesRadius/2,
                                      elipsesRadius,
                                      elipsesRadius);
            CGContextSetFillColorWithColor(context, [UIColor colorWithRed:103.0/255.0 green:120.0/255.0 blue:140.0/255.0 alpha:1.0].CGColor);
            CGContextFillEllipseInRect(context, frame);
        }
    }
}

@end
