//
//  RadialProgressBarView.m
//  Radial Progress Bar
//
//  Created by Dmitry Miller on 7/22/13.
//  Copyright (c) 2013 Dmitry Miller. All rights reserved.
//

#import "RadialProgressBarView.h"

@implementation RadialProgressBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self != nil)
    {
        self.backgroundColor = [UIColor clearColor];
        _emptyColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        _progressColor = [UIColor colorWithRed:76.0f/255.0f green:176.0f/255.0f blue:251.0f/255.0f alpha:1.0f];
        _progressBarWidth = 3;
        _progress = 0;
    }

    return self;
}

- (void)layoutSubviews
{
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    int numSectors = 2 * M_PI * self.bounds.size.width / 7;

    CGFloat sectorAngle  = 2.0f * M_PI / numSectors;
    CGFloat segmentAngle = 0.8f * sectorAngle;

    CGFloat currentAngle = 3.0f * M_PI / 2.0f;
    double singleSectorProgressPrecent = 100.0f / numSectors;
    double progressPercent = 0.0;

    for (int i=0; i < numSectors * 2; i++)
    {
        if (progressPercent < self.progress)
        {
            [self.progressColor setStroke];
        }
        else
        {
            [self.emptyColor setStroke];
        }

        UIBezierPath * path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2)
                                                             radius:self.bounds.size.width / 2 - self.progressBarWidth
                                                         startAngle:currentAngle
                                                           endAngle:currentAngle  + segmentAngle
                                                          clockwise:YES];
        path.lineWidth = self.progressBarWidth;
        [path stroke];

        currentAngle += sectorAngle;
        progressPercent += singleSectorProgressPrecent;

        i++;
    }
}

#pragma mark - misc

- (void)setProgress:(CGFloat)value
{
    _progress = value;
    [self setNeedsDisplay];
}

- (void)setEmptyColor:(UIColor *)value
{
    _emptyColor = value;
    [self setNeedsDisplay];
}

- (void)setProgressBarWidth:(CGFloat)value
{
    _progressBarWidth = value;
    [self setNeedsDisplay];
}

- (void)setProgressColor:(UIColor *)value
{
    _progressColor = value;
    [self setNeedsDisplay];
}

@end
