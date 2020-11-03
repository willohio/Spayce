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

#import "MNMPullToRefreshManager.h"
#import "MNMPullToRefreshViewImpl.h"

static CGFloat const kAnimationDuration = 0.2f;

@interface MNMPullToRefreshManager()

/*
 * The pull-to-refresh view to add to the top of the table.
 */
@property (nonatomic, readwrite, strong) MNMPullToRefreshView *pullToRefreshView;

@property (nonatomic, readwrite, strong) MNMPullToRefreshView *pullToRefreshLoadingView;

/*
 * Table view in which pull to refresh view will be added.
 */
@property (nonatomic, readwrite, weak) UIScrollView *table;

/*
 * Client object that observes changes in the pull-to-refresh.
 */
@property (nonatomic, readwrite, weak) id<MNMPullToRefreshManagerClient> client;

@property (nonatomic, readwrite, assign) CGFloat tableOffsetOnLoad;
@property (nonatomic, readwrite, assign) BOOL tableScrolledAfterLoad;

@property (nonatomic, readwrite, assign) UIEdgeInsets tableOriginalEdgeInsets;
@property (nonatomic, readwrite, assign) BOOL tableScrollable;

@property (nonatomic, readwrite, assign) MNMPullToRefreshViewState state;

@end

@implementation MNMPullToRefreshManager

@synthesize pullToRefreshView = pullToRefreshView_;
@synthesize pullToRefreshLoadingView = pullToRefreshLoadingView_;
@synthesize table = table_;
@synthesize client = client_;
@synthesize tableOffsetOnLoad = tableOffsetOnLoad_;
@synthesize tableScrolledAfterLoad = tableScrolledAfterLoad_;
@synthesize tableOriginalEdgeInsets = tableOriginalEdgeInsets_;
@synthesize tableScrollable = tableScrollable_;

#pragma mark -
#pragma mark Instance initialization

/*
 * Initializes the manager object with the information to link view and table
 */
- (id)initWithPullToRefreshViewHeight:(CGFloat)height scrollView:(UIScrollView *)scrollView withClient:(id<MNMPullToRefreshManagerClient>)client {

    if (self = [super init]) {
        
        client_ = client;
        table_ = scrollView;
        pullToRefreshView_ = [[MNMPullToRefreshViewImpl alloc] initWithFrame:CGRectMake(0.0f, -height, CGRectGetWidth([table_ frame]), height)];
        pullToRefreshView_.isInTable = YES;
        
        [table_ addSubview:pullToRefreshView_];
        
        tableOriginalEdgeInsets_ = table_.contentInset;
    }
    
    return self;
}

/*
 * Initializes the manager object with the information to link view and table,
 * with a custom pull-to-refresh view implementation.
 */
- (id)initWithPullToRefreshView:(MNMPullToRefreshView *)pullToRefreshView scrollView:(UIScrollView *)scrollView withClient:(id<MNMPullToRefreshManagerClient>)client {
    
    if (self = [super init]) {
        
        client_ = client;
        table_ = scrollView;
        pullToRefreshView_ = pullToRefreshView;
        pullToRefreshView_.frame = CGRectMake(0.0f, -pullToRefreshView.frameHeight, CGRectGetWidth([table_ frame]), pullToRefreshView.frameHeight);
        pullToRefreshView_.isInTable = YES;
        
        [table_ addSubview:pullToRefreshView_];
        
        tableOriginalEdgeInsets_ = table_.contentInset;
    }
    
    return self;
}

/*
 * Initializes the manager object with the information to link view and table,
 * with a custom pull-to-refresh view implementation.
 */
- (id)initWithPullToRefreshView:(MNMPullToRefreshView *)pullToRefreshView pullToRefreshLoadingView:(MNMPullToRefreshView *)pullToRefreshLoadingView scrollView:(UIScrollView *)scrollView withClient:(id<MNMPullToRefreshManagerClient>)client {
    
    if (self = [self initWithPullToRefreshView:pullToRefreshView scrollView:scrollView withClient:client]) {
        pullToRefreshLoadingView_ = pullToRefreshLoadingView;
        pullToRefreshLoadingView.frame = CGRectMake(table_.frame.origin.x, table_.frame.origin.y, CGRectGetWidth([table_ frame]), pullToRefreshLoadingView.fixedHeight + table_.contentInset.top);
        pullToRefreshLoadingView_.isInTable = NO;
    }
    
    return self;
}


#pragma mark -
#pragma mark Table view scroll management

-(CGFloat) tableOffset {
    return [table_ contentOffset].y + [table_ contentInset].top;
}

- (void)informListenerOfOffset:(CGFloat)offset {
    if ([self.listener respondsToSelector:@selector(pullToRefreshManager:didChangeOffsetWithContentProportionDisplayed:refreshProportionDisplayed:contentRefreshMarginDisplayed:)]) {
        CGFloat contentProportionDisplayed = 0.0;
        CGFloat refreshProportionDisplayed = 0.0;
        CGFloat contentRefreshMarginDisplayed = 0.0;
        if (self.state == MNMPullToRefreshViewStateLoading) {
            contentProportionDisplayed = 1.0;
            refreshProportionDisplayed = 1.0;
            contentRefreshMarginDisplayed = 1.0;
        } else if (offset < CGFLOAT_MAX) {
            contentProportionDisplayed = MIN(1.0, (-offset) / pullToRefreshView_.contentHeight);
            refreshProportionDisplayed = MIN(1.0, (-offset) / pullToRefreshView_.fixedHeight);
            if (contentProportionDisplayed == 1.0 && pullToRefreshView_.contentHeight < pullToRefreshView_.fixedHeight) {
                contentRefreshMarginDisplayed = MIN(1.0, (-offset - pullToRefreshView_.contentHeight) / (pullToRefreshView_.fixedHeight - pullToRefreshView_.contentHeight));
            } else {
                contentRefreshMarginDisplayed = refreshProportionDisplayed == 1.0 ? 1.0 : 0.0;
            }
        }
        [self.listener pullToRefreshManager:self didChangeOffsetWithContentProportionDisplayed:contentProportionDisplayed refreshProportionDisplayed:refreshProportionDisplayed contentRefreshMarginDisplayed:contentRefreshMarginDisplayed];
        }
}

- (void)reportOffset:(CGFloat)offset {
    [pullToRefreshView_ changeOffset:offset];
    [pullToRefreshLoadingView_ changeOffset:offset];
    [self informListenerOfOffset:offset];
}

- (void)reportState:(MNMPullToRefreshViewState)state withOffset:(CGFloat)offset {
    self.state = state;
    
    [pullToRefreshView_ changeStateOfControl:state withOffset:offset];
    [pullToRefreshLoadingView_ changeStateOfControl:state withOffset:offset];
    [self informListenerOfOffset:offset];
}

/*
 * Checks state of control depending on tableView scroll offset
 */
- (void)tableViewScrolled {
    
    if (![pullToRefreshView_ isHidden] && ![pullToRefreshView_ isLoading]) {
        CGFloat offset = [self tableOffset];
        tableOffsetOnLoad_ = offset;

        if (offset >= 0.0f) {
        
            [self reportState:MNMPullToRefreshViewStateIdle withOffset:offset];
            
        } else if (offset <= 0.0f && offset >= -[pullToRefreshView_ fixedHeight]) {
            
            [self reportState:MNMPullToRefreshViewStatePull withOffset:offset];
            
        } else {
            
            [self reportState:MNMPullToRefreshViewStateRelease withOffset:offset];
            
        }
    } else if (![pullToRefreshView_ isHidden]) {
        CGFloat offset = tableScrolledAfterLoad_ ? [self tableOffset] : tableOffsetOnLoad_;
        tableOffsetOnLoad_ = offset;
        [self reportOffset:offset];
    }
    tableScrolledAfterLoad_ = YES;
}

/*
 * Checks releasing of the tableView
 */
- (void)tableViewReleased {
    
    if (![pullToRefreshView_ isHidden] && ![pullToRefreshView_ isLoading]) {
        
        CGFloat offset = tableOffsetOnLoad_;
        
        if (offset <= 0.0f && offset < -[pullToRefreshView_ fixedHeight]) {
            tableScrolledAfterLoad_ = NO;
            
            [self reportState:MNMPullToRefreshViewStateLoading withOffset:offset];
            if (pullToRefreshLoadingView_) {
                [pullToRefreshLoadingView_ removeFromSuperview];
                [table_.superview insertSubview:pullToRefreshLoadingView_ aboveSubview:table_];
                pullToRefreshLoadingView_.hidden = NO;
                CGRect frame = pullToRefreshLoadingView_.frame;
                frame.origin = table_.frame.origin;
                pullToRefreshLoadingView_.frame = frame;
            }
            
            tableOriginalEdgeInsets_ = table_.contentInset;
            tableScrollable_ = table_.scrollEnabled;
            UIEdgeInsets insets = UIEdgeInsetsMake(
                                                   [pullToRefreshView_ fixedHeight] + tableOriginalEdgeInsets_.top,
                                                   tableOriginalEdgeInsets_.left,
                                                   tableOriginalEdgeInsets_.bottom,
                                                   tableOriginalEdgeInsets_.right);
            
            table_.scrollEnabled = NO;
            [UIView animateWithDuration:kAnimationDuration animations:^{
                [table_ setContentInset:insets];
            }];
            
            [client_ pullToRefreshTriggered:self];
        }
    }
}

/*
 * The reload of the table is completed
 */
- (void)tableViewReloadFinishedAnimated:(BOOL)animated {
    [self performViewLoadFinishedAnimated:[NSNumber numberWithBool:animated]];
}

- (void)performViewLoadFinishedAnimated:(NSNumber *)animated {
    BOOL anim = [animated boolValue];
    if (self.state == MNMPullToRefreshViewStateLoading) {
        CGFloat offset = tableOffsetOnLoad_;
        [self reportState:MNMPullToRefreshViewStateLoadingRetract withOffset:offset];
        if (pullToRefreshLoadingView_) {
            pullToRefreshLoadingView_.hidden = YES;
        }
        
        table_.scrollEnabled = tableScrollable_;
        [UIView animateWithDuration:(anim ? kAnimationDuration : 0.0f) animations:^{
            
            [table_ setContentInset:tableOriginalEdgeInsets_];
            
        } completion:^(BOOL finished) {
            
            [pullToRefreshView_ setLastUpdateDate:[NSDate date]];
            [pullToRefreshLoadingView_ setLastUpdateDate:[NSDate date]];
            [self reportState:MNMPullToRefreshViewStateIdle withOffset:CGFLOAT_MAX];
        }];
    }
}

#pragma mark -
#pragma mark Properties

/*
 * Sets the pull-to-refresh view visible or not. Visible by default
 */
- (void)setPullToRefreshViewVisible:(BOOL)visible {
    
    [pullToRefreshView_ setHidden:!visible];
}

- (BOOL)isLoading {
    return pullToRefreshView_.isLoading;
}

@end