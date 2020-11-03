//
//  SPCTrendingDataSource.m
//  Spayce
//
//  Created by Jake Rosin on 7/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTrendingDataSource.h"

#define FAST_SCROLL_CAPTURE_INTERVAL 0.1

@interface SPCTrendingDataSource()

@property (nonatomic, assign) CGFloat scrollViewLastOffset;
@property (nonatomic, assign) BOOL isAccordionStuck;
@property (nonatomic, assign) CGFloat accordionIsStuckAtOffset;
@property (nonatomic, assign) CGFloat accordionUnstickingAttemptOffset;

@property (nonatomic, assign) CGFloat scrollViewFastCheckLastOffset;
@property (nonatomic, assign) NSTimeInterval scrollViewFastCheckLastOffsetCapture;
@property (nonatomic, assign) BOOL isScrollingUpFast;

@end

@implementation SPCTrendingDataSource

- (instancetype) init {
    self = [super init];
    if (self) {
        self.ignoreLocationSetting = YES;
    }
    return self;
}

#pragma mark - Properties

- (BOOL)hasSegmentedControlCustomTransitionRatio {
    return YES;
}

- (CGFloat) segmentedControlCustomTransitionRatio {
    // At 0.0 we display the "as list item" appearance of the segmented
    // controls: gray background with possible Card-styling.  At 1.0 we
    // display the "screen header / navigation control" styling of the
    // segmented controls: a blue background, full width.
    
    // This is equivalent to the proportion of the 1st accordion view
    // that has scrolled off screen.  (slight variation: if the 1st accordion
    // view is very small -- say, < 30 pixels -- we extend this to the height of
    // the 2nd accordion view if we can.  Otherwise the animation is far
    // too fast and limited in scroll-range).
    
    // When nothing is offscreen, 0.
    // When all of it is offscreen, 1.0.
    // Adjust this ratio to take into account how much of the view
    // can actually be moved offscreen, based on min / max accordion height.
    if (self.accordionViews.count == 0) {
        return 1.0f;
    } else {
        UIView * view = self.accordionViewsUnfoldOrder[0];
        CGFloat height = view.frame.size.height;
        if (height < 30 && self.accordionViewsUnfoldOrder.count >= 2) {
            UIView *nextView = self.accordionViewsUnfoldOrder[1];
            CGFloat nextHeight = nextView.frame.size.height;
            height = nextHeight + (nextHeight >= 30 ? 0 : height);
        }
        CGFloat offscreen;
        CGFloat max = MIN(self.accordionHeightMax, height);
        if (self.accordionHeight <= self.accordionHeightMin) {
            offscreen = 1.0;
        } else if (self.accordionHeight >= max) {
            offscreen = 0.0;
        } else {
            offscreen = (max - self.accordionHeight) / (max - self.accordionHeightMin);
        }
        return offscreen;
    }
}

- (NSString *)loadingMessageWhenFullFeedIsEmpty {
    return NSLocalizedString(@"\n\nNo memories visible\nat this location\n\n", nil);
}

- (NSString *)loadingMessageWhenFullFeedIsNotEmptyButFeedIsEmpty {
    return NSLocalizedString(@"\n\nNo personal memories\nat this location\n\n", nil);
}

- (void)setAccordionHeight:(CGFloat)accordionHeight {
    //NSLog(@"setAccordionHeight %f", accordionHeight);
    if (_accordionHeight != accordionHeight) {
        _accordionHeight = accordionHeight;
        // adjust the height / position of accordion views
        // this is a bit tricky, because the vertical order is determined
        // by their order in 'accordionViews', but the amount of height provided
        // to each is determined by 'accordingViewsUnfoldOrder'.  Two loops:
        // first, determine which view is partially unfolded (if any), then arrange
        // them.
        CGFloat heightUsed = 0;
        CGFloat partiallyVisibleHeight = 0;
        UIView *partiallyVisibleView;
        for (int i = 0; i < self.accordionViewsUnfoldOrder.count; i++) {
            UIView *view = self.accordionViewsUnfoldOrder[i];
            CGRect frame = view.frame;
            CGFloat heightRemaining = accordionHeight - heightUsed;
            CGFloat heightForView = MIN(heightRemaining, frame.size.height);
            if (heightForView == frame.size.height) {
                // this view is fully visible
                view.hidden = NO;
            } else if (heightForView > 0) {
                // this view is PARTIALLY visible
                partiallyVisibleHeight = heightForView;
                partiallyVisibleView = view;
                view.hidden = NO;
            } else {
                // this view is completely hidden
                view.hidden = YES;
            }
            
            heightUsed += heightForView;
        }
        
        heightUsed = 0;
        for (int i = 0; i < self.accordionViews.count; i++) {
            UIView *view = self.accordionViews[i];
            if (!view.hidden) {
                CGFloat heightForView = view == partiallyVisibleView ? partiallyVisibleHeight : view.frame.size.height;
                CGRect frame = view.frame;
                frame.origin.y = self.accordionTop + heightUsed - frame.size.height + heightForView;
                view.frame = frame;
                
                heightUsed += heightForView;
            }
        }
    }
}

-(void)setAccordionHeight:(CGFloat)accordionHeight forScrollView:(UIScrollView *)scrollView {
    [self setAccordionHeight:accordionHeight forScrollView:scrollView callSuperScrollViewDidScroll:YES];
}

-(void)setAccordionHeight:(CGFloat)accordionHeight forScrollView:(UIScrollView *)scrollView callSuperScrollViewDidScroll:(BOOL)callSuperScrollViewDidScroll {
    self.accordionHeight = MIN(MAX(accordionHeight, self.accordionHeightMin), self.accordionHeightMax);
    UIEdgeInsets insets = scrollView.contentInset;
    insets.top = self.accordionHeight;
    scrollView.contentInset = insets;
    
    if (callSuperScrollViewDidScroll) {
        [super scrollViewDidScroll:scrollView];
    }
}

-(void)configureAccordionViewsWithViewOrder:(NSArray *)viewsInViewOrder unfoldOrder:(NSArray *)viewsInUnfoldOrder accordionTop:(CGFloat)accordionTop {
    CGFloat totalHeight = 0;
    for (int i = 0; i < viewsInViewOrder.count; i++) {
        totalHeight += ((UIView *)viewsInViewOrder[i]).frame.size.height;
    }
    
    self.accordionTop = accordionTop;
    self.accordionHeightMax = totalHeight;
    self.accordionHeightMin = 0.0;
    self.accordionViews = viewsInViewOrder;
    self.accordionViewsUnfoldOrder = viewsInUnfoldOrder;
    
    // this call will position the accordion views
    self.accordionHeight = totalHeight;
}


#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = MAX(-self.accordionHeightMax, scrollView.contentOffset.y);
    CGFloat overscrollOffset = MAX(0, scrollView.contentSize.height - scrollView.frame.size.height);
    
    if (overscrollOffset < scrollView.frame.size.height) {
        // erm...?  Don't allow a change in accordion height; there's not
        // enough content to justify it.
        [self setAccordionHeight:self.accordionHeightMax forScrollView:scrollView callSuperScrollViewDidScroll:YES];
        return;
    }
    
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    
    NSTimeInterval timeDiff = currentTime - self.scrollViewFastCheckLastOffsetCapture;
    
    // check if scrolling fast?
    if (timeDiff > FAST_SCROLL_CAPTURE_INTERVAL) {
        CGFloat distance = offset - self.scrollViewFastCheckLastOffset;
        CGFloat scrollSpeedNotAbs = (distance / timeDiff) / 1000;  // in pixels per millisecond
        self.isScrollingUpFast = offset < overscrollOffset && scrollSpeedNotAbs < -0.5;
        self.scrollViewFastCheckLastOffset = offset;
        self.scrollViewFastCheckLastOffsetCapture = currentTime;
    }
    
    CGFloat diff = offset - self.scrollViewLastOffset;
    
    if (diff > 0) {
        // scrolling down...
        //NSLog(@"scrolling down...");
        if (self.accordionHeight > self.accordionHeightMin) {
            [self setAccordionHeight:MAX(self.accordionHeightMin, self.accordionHeight - diff) forScrollView:scrollView callSuperScrollViewDidScroll:NO];
        }
        
        if (self.accordionHeight == self.accordionHeightMin && (!self.isAccordionStuck || self.accordionIsStuckAtOffset < offset)) {
            self.isAccordionStuck = YES;
            self.accordionIsStuckAtOffset = MIN(offset, overscrollOffset);
            self.accordionUnstickingAttemptOffset = FLT_MAX;
        } else if (self.isAccordionStuck && offset - self.accordionUnstickingAttemptOffset >= self.accordionStickyPixelsRestick) {
            self.isAccordionStuck = YES;
            self.accordionIsStuckAtOffset = MIN(offset, overscrollOffset);
            self.accordionUnstickingAttemptOffset = FLT_MAX;
        }
    } else if (diff < 0 && offset < overscrollOffset) {
        // scrolling up...
        // NSLog(@"scrolling up... stuck at %f, current %f, stick height %f", self.accordionIsStuckAtOffset, offset, self.accordionStickyPixels);
        
        // unstick the accordion?
        if (self.isScrollingUpFast || self.accordionIsStuckAtOffset - offset >= self.accordionStickyPixels || offset <= 0) {
            self.isAccordionStuck = NO;
        } else if (self.isAccordionStuck) {
            self.accordionUnstickingAttemptOffset = offset;
        }
        
        // adjust?
        if (!self.isAccordionStuck && self.accordionHeight < self.accordionHeightMax) {
            [self setAccordionHeight:MIN(self.accordionHeightMax, self.accordionHeight - diff) forScrollView:scrollView callSuperScrollViewDidScroll:NO];
        }
    }
    self.scrollViewLastOffset = offset;
    
    [super scrollViewDidScroll:scrollView];
}

@end
