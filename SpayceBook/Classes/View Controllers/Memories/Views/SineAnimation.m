//
//  SineAnimation.m
//  Spayce
//
//  Created by Christopher Taylor on 1/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SineAnimation.h"

@implementation SineAnimation

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)updateAmplitude:(float)amp {
    float adjAmp = amp;
    
    if (amp < -50) {
        adjAmp = amp - 50;
    }
    if (amp < -45) {
        adjAmp = amp - 40;
    }
    
    amplitude = adjAmp;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGMutablePathRef path = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:178.0f/255.0f green:207.0f/255.0f blue:231.0f/255.0f alpha:1.0f].CGColor);
    
    float x=75;
    float yc=amplitude;
    float w=0;
    float y=self.frame.size.height;
    
    while (w<=self.frame.size.width) {
        CGPathMoveToPoint(path, nil, w,y/2);
        CGPathAddQuadCurveToPoint(path, nil, w+x/4, -yc,w+ x/2, y/2);
        CGPathMoveToPoint(path, nil, w+x/2,y/2);
        CGPathAddQuadCurveToPoint(path, nil, w+3*x/4, y+yc, w+x, y/2);
        CGContextAddPath(context, path);
        CGContextDrawPath(context, kCGPathStroke);
        w+=x;
    }
    
    CGPathRelease(path);
    
    // Drawing code
    CGContextRef context2 = UIGraphicsGetCurrentContext();
    CGMutablePathRef path2 = CGPathCreateMutable();
    CGContextSetStrokeColorWithColor(context2, [UIColor colorWithRed:0.0f/255.0f green:149.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor);
    
    
    float x2=100;
    float yc2=amplitude;
    float w2=0;
    float y2=self.frame.size.height;
    
    while (w2<=self.frame.size.width) {
        CGPathMoveToPoint(path2, nil, w2,y2/2);
        CGPathAddQuadCurveToPoint(path2, nil, w2+x2/4, -yc2,w2+ x2/2, y2/2);
        CGPathMoveToPoint(path2, nil, w2+x2/2,y2/2);
        CGPathAddQuadCurveToPoint(path2, nil, w2+3*x2/4, y2+yc2, w2+x2, y2/2);
        CGContextAddPath(context2, path2);
        CGContextDrawPath(context2, kCGPathStroke);
        w2+=x2;
    }
    
    CGPathRelease(path2);
}

@end
