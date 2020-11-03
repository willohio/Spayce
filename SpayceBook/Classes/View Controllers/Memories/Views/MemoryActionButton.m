//
//  MemoryActionButton.m
//  Spayce
//
//  Created by Pavel Dušátko on 12/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "MemoryActionButton.h"

#define kPADDING_VERTICAL 0
#define kPADDING_HORIZONTAL 4

@interface MemoryActionButton ()

@property (strong, nonatomic) UIImage *iconImage;
@property (assign, nonatomic) NSInteger count;
@property (assign, nonatomic) BOOL rounded;

@property (assign, nonatomic) BOOL showCount;

@end

@implementation MemoryActionButton

- (MemoryActionButton *)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageSize = 24;
        self.roundedCorners = UIRectCornerAllCorners;
    }
    return self;
}

#pragma mark - Private

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [self setNeedsDisplay];
}

#pragma mark - Accessors

- (void)setIconImage:(UIImage *)iconImage
{
    if (_iconImage != iconImage) {
        _iconImage = iconImage;
        
        [self setNeedsDisplay];
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Configure colors
    UIColor *backgroundColor = self.color;
    UIColor *textColor;
    
    if (self.clearBg) {
        textColor = [UIColor whiteColor];
    }
    else {
        textColor = [UIColor colorWithRed:172.0f/255.0f green:182.0f/255.0f blue:198.0f/255.0f alpha:1.0f];
    }
    
    // Visible area
    CGRect frame;
    frame = CGRectInset(rect, kPADDING_HORIZONTAL, kPADDING_VERTICAL);
    frame = CGRectOffset(frame, 0, -kPADDING_VERTICAL/2);
    
    // Background
    CGContextSaveGState(context);
    CGPathRef clippingBackgroundPath = [UIBezierPath bezierPathWithRoundedRect:frame byRoundingCorners:self.roundedCorners cornerRadii:CGSizeMake(2, 2)].CGPath;
    CGContextAddPath(context, clippingBackgroundPath);
    CGContextClip(context);
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, frame);
    CGContextRestoreGState(context);
    
    if (!self.clearBg) {
        CGContextSaveGState(context);
        
        // draw a border
        CGPathRef strokePath = [UIBezierPath bezierPathWithRoundedRect:frame byRoundingCorners:self.roundedCorners cornerRadii:CGSizeMake(2, 2)].CGPath;
        CGContextAddPath(context, strokePath);

        CGContextSetLineWidth(context, 1.0);
        CGContextSetFillColorWithColor(context, textColor.CGColor);
        CGContextSetStrokeColorWithColor(context, textColor.CGColor);
        CGContextStrokePath(context);
        CGContextRestoreGState(context);
    }
    
    
    if (self.showCount) {
        [textColor setFill];
        
        CGRect textRect = CGRectMake(CGRectGetMinX(frame)+8, CGRectGetMidY(frame)-8, CGRectGetWidth(frame)-self.imageSize-16, 16);
        
        NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_memory_actionButtonFont],
                                      NSForegroundColorAttributeName: textColor };
        
        [[NSString stringWithFormat:@"%@", @(self.count)] drawWithRect:CGRectOffset(textRect, 0.0, 13.0)
                                                               options:NSStringDrawingUsesFontLeading
                                                            attributes:attributes
                                                               context:NULL];
    }

    // Icon
    if (self.iconImage) {
        CGRect imageFrame;
        if (self.showCount) {
            imageFrame = CGRectMake(CGRectGetMaxX(frame)-self.imageSize-5.0, CGRectGetMinY(frame)+5, self.imageSize, self.imageSize);
        } else {
            imageFrame = CGRectMake(CGRectGetMidX(frame)-self.imageSize/2.0, CGRectGetMidY(frame)-self.imageSize/2.0, self.imageSize, self.imageSize);
        }
        
        if (self.rounded && self.iconImage) {
            CGContextSaveGState(context);
            
            // draw a circle as a background / outline
            CGRect circle = CGRectInset(imageFrame, -2, -2);
            CGContextSetLineWidth(context, 0.0);
            CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextFillEllipseInRect(context, circle);
            CGContextRestoreGState(context);
            
            // draw the image
            CGContextSaveGState(context);
            CGPathRef clippingPath = [UIBezierPath bezierPathWithRoundedRect:imageFrame cornerRadius:CGRectGetHeight(imageFrame)/2].CGPath;
            CGContextAddPath(context, clippingPath);
            CGContextClip(context);
            
            [self.iconImage drawInRect:imageFrame];
            
            CGContextRestoreGState(context);
        } else {
            [self.iconImage drawInRect:imageFrame];
        }
    }

}

#pragma mark - Configuration

- (void)configureWithIconImage:(UIImage *)iconImage clearBG:(BOOL)clearBG {
    [self configureWithIconImage:iconImage count:0 rounded:NO clearBG:clearBG];
    self.showCount = NO;
}

- (void)configureWithIconImage:(UIImage *)iconImage rounded:(BOOL)rounded clearBG:(BOOL)clearBG {
    [self configureWithIconImage:iconImage count:0 rounded:rounded clearBG:clearBG];
    self.showCount = NO;
}

- (void)configureWithIconImage:(UIImage *)iconImage count:(NSInteger)count clearBG:(BOOL)clearBG {
    [self configureWithIconImage:iconImage count:count rounded:NO clearBG:clearBG];
}

- (void)configureWithIconImage:(UIImage *)iconImage count:(NSInteger)count rounded:(BOOL)rounded clearBG:(BOOL)clearBackground {
    self.iconImage = iconImage;
    self.count = count;
    self.rounded = rounded;
    self.clearBg = clearBackground;
    self.showCount = YES;
    
  self.color = clearBackground ? [UIColor colorWithWhite:0.0  alpha:.3] : [UIColor whiteColor];
    
    [self setNeedsDisplay];
}


@end
