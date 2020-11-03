/*
 * Copyright (c) 13/11/2012 Mario Negro (@emenegro)
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MNMPullToRefreshView.h"

@interface MNMPullToRefreshView()

@end

@implementation MNMPullToRefreshView

@dynamic isLoading;
@synthesize lastUpdateDate = lastUpdateDate_;
@synthesize fixedHeight = fixedHeight_;
@synthesize frameHeight = frameHeight_;
@synthesize contentHeight = contentHeight_;

#pragma mark -
#pragma mark Initialization

/*
 * Initializes and returns a newly allocated view object with the specified frame rectangle.
 *
 * @param frame The frame rectangle for the view, measured in points.
 * @return An initialized view object or nil if the object couldn't be created.
 */
- (id)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        fixedHeight_ = CGRectGetHeight(frame);
        frameHeight_ = fixedHeight_;
        contentHeight_ = contentHeight_;
        lastUpdateDate_ = [NSDate date];
        
        [self changeStateOfControl:MNMPullToRefreshViewStateIdle withOffset:CGFLOAT_MAX];
    }
    
    return self;
}

- (id)initWithHeight:(CGFloat)height {
    return [self initWithFixedHeight:height frameHeight:height contentHeight:height];
}

- (id)initWithFixedHeight:(CGFloat)fixedHeight frameHeight:(CGFloat)frameHeight {
    return [self initWithFixedHeight:fixedHeight frameHeight:frameHeight contentHeight:fixedHeight];
}

- (id)initWithFixedHeight:(CGFloat)fixedHeight frameHeight:(CGFloat)frameHeight contentHeight:(CGFloat)contentHeight {
    if (self = [super init]) {
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        fixedHeight_ = fixedHeight;
        frameHeight_ = frameHeight;
        contentHeight_ = contentHeight;
        lastUpdateDate_ = [NSDate date];
        
        [self changeStateOfControl:MNMPullToRefreshViewStateIdle withOffset:CGFLOAT_MAX];
    }
    return self;
}

#pragma mark -
#pragma mark Visuals

/*
 * Changes the state of the control depending in state and offset values
 */

- (void)changeStateOfControl:(MNMPullToRefreshViewState)state withOffset:(CGFloat)offset {
    NSLog(@"MNMPullToRefreshView changeStateOfControl:withOffset: empty implementation.  Override this method and don't bother calling [super ...]");
}

- (void)changeOffset:(CGFloat)offset {
    NSLog(@"MNMPullToRefreshView changeOffset: empty implementation.  Override this method and don't bother calling [super ...]");
}

#pragma mark -
#pragma mark Properties

/*
 * Returns state of activity indicator
 */
- (BOOL)isLoading {
    NSLog(@"MNMPullToRefreshView isLoading empty implementation.  Override this method and don't bother calling [super ...]");
    return NO;
}

@end
