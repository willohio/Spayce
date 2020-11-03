//
//  SPCPullToRefreshManager.h
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPCPullToRefreshView.h"
@class SPCPullToRefreshManager;


@protocol SPCPullToRefreshManagerDelegate

/**
 * Tells delegate that refreshing has been triggered.
 *
 * It is the delegate's responsibility to call
 * [manager refreshFinished] after this call.
 *
 * @param manager The pull to refresh manager.
 */
- (void)pullToRefreshTriggered:(SPCPullToRefreshManager *)manager;

@end


@interface SPCPullToRefreshManager : NSObject<UIScrollViewDelegate, UITableViewDelegate, UICollectionViewDelegate>

@property (nonatomic, weak) UIView *fadingHeaderView;
@property (nonatomic, weak) NSObject <SPCPullToRefreshManagerDelegate> *delegate;
@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, weak) SPCPullToRefreshView *loadingView;

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

/**
 * This is the same delegate method of `UIScrollViewDelegate`.
 *
 * Either attach this instance as the delegate of its UIScrollView, or
 * pass the delegate method calls to this instance.
 *
 * @param scrollView The scroll-view object in which the scrolling occurred.
 */
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

/**
 * This is the same delegate method of `UIScrollViewDelegate`.
 *
 * Either attach this instance as the delegate of its UIScrollView, or
 * pass the delegate method calls to this instance.
 *
 * @param scrollView The scroll-view object that finished scrolling the content view.
 * @param decelerate YES if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
 */
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;


/**
 * Indicates that the reload of the table is completed.
 */
- (void)refreshFinished;

/**
 * Indicates that the reload of the table is completed.
 *
 * @param animated YES to animate the transition from Loading state to Idle state.
 */
- (void)refreshFinishedAnimated:(BOOL)animated;


- (void)setPullToRefreshViewVisible:(BOOL)visible;

- (void)hideContentUntilStateChange;

@end
