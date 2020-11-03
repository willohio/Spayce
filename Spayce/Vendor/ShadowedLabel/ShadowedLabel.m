//
//  ShadowedLabel.m
//
//  Created by Tyler Neylon on 4/19/10.
//  Copyleft 2010 Bynomial.
//

#import "ShadowedLabel.h"


@implementation ShadowedLabel

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        
        _textShadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        _textShadowOffset = CGSizeMake(0, 1);
        _textShadowRadius = 1;
    }
    
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGFloat r, g, b, a;
  [self.textShadowColor getRed:&r green:&g blue:&b alpha:&a];
  CGFloat colorValues[] = {r, g, b, a};
  CGColorRef shadowColor = CGColorCreate(colorSpace, colorValues);
  CGContextSetShadowWithColor (context, self.textShadowOffset, self.textShadowRadius, shadowColor);
  [super drawTextInRect:rect];

  CGColorRelease(shadowColor);
  CGColorSpaceRelease(colorSpace);
  CGContextRestoreGState(context);
}

@end
