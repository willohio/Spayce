//
//  MNMPullToRefreshView.h
//  Spayce
//
//  Created by Jake Rosin on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


/**
 * Enumerates control's state
 */
typedef enum {
    
    MNMPullToRefreshViewStateIdle = 0, //<! The control is invisible right after being created or after a reloading was completed
    MNMPullToRefreshViewStatePull, //<! The control is becoming visible and shows "pull to refresh" message
    MNMPullToRefreshViewStateRelease, //<! The control is whole visible and shows "release to load" message
    MNMPullToRefreshViewStateLoading, //<! The control is loading and shows activity indicator
    MNMPullToRefreshViewStateLoadingRetract,
    
    MNMPullToRefreshViewStateUnset   //<! State has never been set
} MNMPullToRefreshViewState;

/**
 * Pull to refresh view. Its state, visuals and behavior is managed by an instance of `MNMPullToRefreshManager`.
 */
@interface MNMPullToRefreshView : UIView

@property (nonatomic, assign) BOOL isInTable;

/**
 * Returns YES if the view is in Loading state.
 */
@property (nonatomic, readonly) BOOL isLoading;

/**
 * Last update date.
 */
@property (nonatomic, readwrite, strong) NSDate *lastUpdateDate;

/**
 * Fixed height of the view. This value is used to check the triggering of the refreshing.
 */
@property (nonatomic, readonly) CGFloat fixedHeight;


/**
 * Frame height of the view.  This value is used to configure the view frame,
 * can be >= fixedHeight.
 */
@property (nonatomic, readonly) CGFloat frameHeight;

/**
 * Content height of the view.  The number of pixels of offset which are
 * necessary to display the "total view content."  Recommended
 * to be <= fixedHeight.
 */
@property (nonatomic, readonly) CGFloat contentHeight;


- (id)initWithHeight:(CGFloat)height;

- (id)initWithFixedHeight:(CGFloat)fixedHeight frameHeight:(CGFloat)frameHeight;

- (id)initWithFixedHeight:(CGFloat)fixedHeight frameHeight:(CGFloat)frameHeight contentHeight:(CGFloat)contentHeight;

/**
 * Changes the state of the control depending in state and offset values.
 *
 * Values of *MNMPullToRefreshViewState*:
 *
 * - `MNMPullToRefreshViewStateIdle` The control is invisible right after being created or after a reloading was completed.
 * - `MNMPullToRefreshViewStatePull` The control is becoming visible and shows "pull to refresh" message.
 * - `MNMPullToRefreshViewStateRelease` The control is whole visible and shows "release to load" message.
 * - `MNMPullToRefreshViewStateLoading` The control is loading and shows activity indicator.
 *
 * @param state The state to set.
 * @param offset The offset of the table scroll.
 */
- (void)changeStateOfControl:(MNMPullToRefreshViewState)state withOffset:(CGFloat)offset;
- (void)changeOffset:(CGFloat)offset;


@end
