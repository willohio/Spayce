//
//  SPCCallout.m
//  Spayce
//
//  Created by Arria P. Owlia on 1/28/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCCallout.h"

@interface SPCCallout()

// UI
// Rectangle that encloses the callout's text and dismiss button
@property (nonatomic, strong) UIView *viewContentRectangle;

// Arrow that points from a set position
@property (nonatomic, strong) UIView *viewArrow;

// Whether the arrow will point to above or below the callout's content
@property (nonatomic) CalloutArrowLocation arrowLocation;

// Between [0, self.bounds.width] - the center offset of the arrow from the left of the content rectangle
@property (nonatomic) CGFloat arrowOffset;

// Label for displaying the callout
@property (nonatomic, strong) UILabel *labelCallout;

// Internal UI
@property (nonatomic, strong) UIColor *colorBackground;
@property (nonatomic, strong) UIColor *colorText;

// Data
// The string as it was passed in by the caller
@property (strong, nonatomic) NSAttributedString *strCallout;

@end

@implementation SPCCallout

#pragma mark - Configuration

- (instancetype)init {
    if (self = [super init]) {
        [self initAppearance];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initAppearance];
    }
    
    return self;
}

- (void)initAppearance {
    // Set class-wide members
    self.colorBackground = [UIColor colorWithRGBHex:0x4ca4ff];
    self.colorText = [UIColor whiteColor];
    
    CGFloat fScreenScale = [UIScreen mainScreen].scale;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.25f;
    self.layer.shadowOffset = CGSizeMake(0, 2.0f / fScreenScale);
    self.layer.shadowRadius = 6.0f / fScreenScale;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // Content Rectangle
    // Its height is the height of this SPCCallout minus the height of the arrow (the arrow's height is half the height of the DIAMOND_DIMENSION const
    // If the arrow's location is on top (or unknown), the rectangles y-offset is equal to the arrow's height. Otherwise, it's y-offset is 0
    CGFloat fRectangleYOffset = 0.0f;
    if (CalloutArrowLocationTop == self.arrowLocation || CalloutArrowLocationUnknown == self.arrowLocation) {
        fRectangleYOffset = DIAMOND_DIMENSION / 2.0f;
    }
    self.viewContentRectangle.frame = CGRectMake(0, fRectangleYOffset, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - (DIAMOND_DIMENSION / 2.0f));
    
    // Arrow
    // The arrow's center x is equal to: this view's bounds * arrow's offset
    // The arrow's center y is equal to: the content rectangle's min or max y, depending on if the arrow is on top or on bottom, respectively.
    CGFloat fArrowCenterX = self.arrowOffset;
    CGFloat fArrowCenterY = 0.0f;
    if (CalloutArrowLocationTop == self.arrowLocation || CalloutArrowLocationUnknown == self.arrowLocation) {
        fArrowCenterY = DIAMOND_DIMENSION / 2.0f;
    } else {
        fArrowCenterY = CGRectGetMaxY(self.viewContentRectangle.frame);
    }
    self.viewArrow.center = CGPointMake(fArrowCenterX, fArrowCenterY);
    
    // Dismiss button
    // Y-offset and height are equal to the content rectangle's y-offset and height
    // Width should be 44pt, with x-offset being equal to this callout's bounds minus 44pt
    CGFloat fDismissBtnWidth = 44.0f;
    self.btnDismiss.frame = CGRectMake(CGRectGetWidth(self.bounds) - fDismissBtnWidth, CGRectGetMinY(self.viewContentRectangle.frame), fDismissBtnWidth, CGRectGetHeight(self.viewContentRectangle.frame));
    
    // Text
    // Frame equal to the content rectangle, excluding most of the dismiss button
    // This implementation assumes that the dismiss button is on the right side of the view
    CGFloat fLeftRightPadding = 0.0f;
    CGFloat fTopBottomPadding = 0.0f;
    CGRect finalLabelFrame = self.viewContentRectangle.frame;
    finalLabelFrame.size.width = finalLabelFrame.size.width - CGRectGetWidth(self.btnDismiss.frame) + ((CGRectGetWidth(self.btnDismiss.frame) - self.btnDismiss.imageView.image.size.width) / 3.0f);
    finalLabelFrame = CGRectInset(finalLabelFrame, fLeftRightPadding, fTopBottomPadding);
    self.labelCallout.frame = finalLabelFrame;
    // We also need to edit the font color of the text
    NSMutableAttributedString *finalCalloutString = [[NSMutableAttributedString alloc] initWithAttributedString:self.strCallout];
    [finalCalloutString addAttribute:NSForegroundColorAttributeName value:self.colorText range:NSMakeRange(0, [finalCalloutString length])];
    self.labelCallout.attributedText = finalCalloutString;
    
    CGPoint labelCenter = self.labelCallout.center;
    CGSize newSize = [self.labelCallout sizeThatFits:self.labelCallout.frame.size];
    self.labelCallout.frame = CGRectMake(0, 0, newSize.width, newSize.height);
    self.labelCallout.center = CGPointMake(labelCenter.x + self.labelHorizontalOffset, labelCenter.y);
    
    // Shadow path
    // We must trace the content rectangle and account for the arrow as well
    // Get the arrow's left and right bounds that intersect the content rectangle
    // The arrow's left x-coordinate = arrow's center.x minus (arrowWidth / 2)
    // The arrow's right x-coordinate = arrow's center.x plus (arrowWidth / 2)
    CGFloat arrowLeftBound = self.viewArrow.center.x - (CGRectGetWidth(self.viewArrow.frame) / 2);
    CGFloat arrowRightBound = self.viewArrow.center.x + (CGRectGetWidth(self.viewArrow.frame) / 2);
    
    // To make it simple and readable, let's set the entire path for the two cases (arrow on top, arrow on bottom) in separate blocks (one path per if-statement block)
    UIBezierPath *pathShadow = [UIBezierPath bezierPath];
    if (CalloutArrowLocationTop == self.arrowLocation || CalloutArrowLocationUnknown == self.arrowLocation) {
        // We will start at the content rectangle's top left corner, move to the arrow's left bound, then the arrow's top, then the arrow's right bound, then the content rectangle's right bound. This will work regardless of whether the arrow's bounds are outside the content rectangles edges.
        
        [pathShadow moveToPoint:CGPointMake(CGRectGetMinX(self.viewContentRectangle.frame), CGRectGetMinY(self.viewContentRectangle.frame))]; // top-left
        [pathShadow addLineToPoint:CGPointMake(arrowLeftBound, CGRectGetMinY(self.viewContentRectangle.frame))]; // arrow's left
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMidX(self.viewArrow.frame), CGRectGetMinY(self.viewArrow.frame))]; // arrow's top
        [pathShadow addLineToPoint:CGPointMake(arrowRightBound, CGRectGetMinY(self.viewContentRectangle.frame))]; // arrow's right
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMaxX(self.viewContentRectangle.frame), CGRectGetMinY(self.viewContentRectangle.frame))]; // top-right
        
        // Now, simply move to the bottom-right, then bottom-left, then close the path
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMaxX(self.viewContentRectangle.frame), CGRectGetMaxY(self.viewContentRectangle.frame))]; // bottom-right
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMinX(self.viewContentRectangle.frame), CGRectGetMaxY(self.viewContentRectangle.frame))]; // bottom-left
        [pathShadow closePath];
    } else {
        // This will be very similar to the operation in the 'if' just above, starting at the top left of the content rectangle, however, the arrow is on the bottom, so the arrow portions of the line will come a bit later
        
        [pathShadow moveToPoint:CGPointMake(CGRectGetMinX(self.viewContentRectangle.frame), CGRectGetMinY(self.viewContentRectangle.frame))]; // top-left
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMaxX(self.viewContentRectangle.frame), CGRectGetMinY(self.viewContentRectangle.frame))]; // top-right
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMaxX(self.viewContentRectangle.frame), CGRectGetMaxY(self.viewContentRectangle.frame))]; // bottom-right
        
        [pathShadow addLineToPoint:CGPointMake(arrowRightBound, CGRectGetMaxY(self.viewContentRectangle.frame))]; // arrow's right
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMidX(self.viewArrow.frame), CGRectGetMaxY(self.viewArrow.frame))]; // arrow's bottom
        [pathShadow addLineToPoint:CGPointMake(arrowLeftBound, CGRectGetMaxY(self.viewContentRectangle.frame))]; // arrow's left
        
        [pathShadow addLineToPoint:CGPointMake(CGRectGetMinX(self.viewContentRectangle.frame), CGRectGetMaxY(self.viewContentRectangle.frame))]; // bottom-left
        [pathShadow closePath];
    }
    
    // Finally, set the path
    self.layer.shadowPath = pathShadow.CGPath;
}

#pragma mark - Configuration

// Public
- (void)configureWithString:(NSAttributedString *)string arrowLocation:(CalloutArrowLocation)arrowLocation andArrowOffset:(CGFloat)arrowOffset {
    self.strCallout = string;
    self.arrowLocation = arrowLocation;
    self.arrowOffset = arrowOffset;
    
    [self setNeedsLayout];
}

#pragma mark - Accessors

- (UIView *)viewContentRectangle {
    if (nil == _viewContentRectangle) {
        _viewContentRectangle = [[UIView alloc] init];
        _viewContentRectangle.backgroundColor = self.colorBackground;
        _viewContentRectangle.layer.cornerRadius = 2.0f;
        
        [self addSubview:_viewContentRectangle];
    }
    
    return _viewContentRectangle;
}

static const CGFloat DIAMOND_DIMENSION = 15.0f; // Initial dimension for rendering the arrow/diamond
- (UIView *)viewArrow {
    // For the arrow, we'll use a UIImageView, with a diamond image we render once per instance (should be infrequently). We could render this image just once per run, but it's possible we want to change the colors of the background/arrow per-instance in the future.
    if (nil == _viewArrow) {
        UIImageView *imageViewArrow = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, DIAMOND_DIMENSION, DIAMOND_DIMENSION)];
        
        UIImage *imageDiamond;
        // Create the diamond's path
        UIBezierPath *pathDiamond = [UIBezierPath bezierPath];
        [pathDiamond moveToPoint:CGPointMake(DIAMOND_DIMENSION / 2.0f, 0)]; // Top
        [pathDiamond addLineToPoint:CGPointMake(DIAMOND_DIMENSION, DIAMOND_DIMENSION / 2.0f)]; // Right
        [pathDiamond addLineToPoint:CGPointMake(DIAMOND_DIMENSION / 2.0f, DIAMOND_DIMENSION)]; // Bottom
        [pathDiamond addLineToPoint:CGPointMake(0, DIAMOND_DIMENSION / 2.0f)]; // Left
        [pathDiamond closePath]; // Close the path
        
        // Draw the diamond into our ImageView
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(DIAMOND_DIMENSION, DIAMOND_DIMENSION), NO, 0.0f);
        [self.colorBackground setFill];
        [pathDiamond fill];
        imageDiamond = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        imageViewArrow.image = imageDiamond;
        
        _viewArrow = imageViewArrow;
        
        // Insert the arrow below the content rectangle
        [self insertSubview:_viewArrow belowSubview:self.viewContentRectangle];
    }
    
    return _viewArrow;
}

- (UILabel *)labelCallout {
    if (nil == _labelCallout) {
        _labelCallout = [[UILabel alloc] init];
        _labelCallout.textAlignment = NSTextAlignmentLeft;
        _labelCallout.numberOfLines = 0;
        
        // Insert the label above the content rectangle
        [self insertSubview:_labelCallout aboveSubview:self.viewContentRectangle];
    }
    
    return _labelCallout;
}

- (UIButton *)btnDismiss {
    if (nil == _btnDismiss) {
        _btnDismiss = [[UIButton alloc] init];
        [_btnDismiss setImage:[UIImage imageNamed:@"callout-close"] forState:UIControlStateNormal];
        _btnDismiss.imageView.contentMode = UIViewContentModeCenter;
        
        // Insert the button above the content rectangle
        [self insertSubview:_btnDismiss aboveSubview:self.viewContentRectangle];
    }
    
    return _btnDismiss;
}

@end
