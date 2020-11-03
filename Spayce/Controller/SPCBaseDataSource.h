//
//  SPCBaseDataSource.h
//  Spayce
//
//  Created by Pavel Dusatko on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Memory.h"
#import "DZNSegmentedControl.h"
#import "MemoryCommentsViewController.h"
#import "SPCAdjustMemoryLocationViewController.h"
#import "SPCMapViewController.h"
#import "SPCTagFriendsViewController.h"
#import "PersonUpdate.h"

#define kHereTableViewTag       666
#define kProfileTableViewTag    777
#define kTrendingTableViewTag   888
#define kHashTagTableViewTag   999


#define kHere35NavigationBarTransitionOffsetMinY 355.0
#define kHere35NavigationBarTransitionOffsetMaxY 405.0
#define kHere4NavigationBarTransitionOffsetMinY 455.0
#define kHere4NavigationBarTransitionOffsetMaxY 505.0
#define kProfileNavigationBarTransitionOffsetMinY 600.0
#define kProfileNavigationBarTransitionOffsetMaxY 640.0
#define kTrendingNavigaionBarTransitionOffsetMinY FLT_MAX-1
#define kTrendingNavigaionBarTransitionOffsetMaxY FLT_MAX


extern NSString * SPCFeedCellIdentifier;
extern NSString * SPCLoadMoreDataCellIdentifier;
extern NSString * SPCLoadFirstMemoryStarCellIdentifier;
extern NSString * SPCLoadOutsideVicinityCellIdentifier;
extern NSString * SPCLoadInitialDataCellIdentifier;
extern NSString * SPCLoadFailedDataCellIdentifier;
extern NSString * SPCReloadProfileData;
extern NSString * SPCReloadProfileForFilters;
extern NSString * SPCReloadData;
extern NSString * SPCReloadForFilters;
extern NSString * SPCMemoryDeleted;
extern NSString * SPCMemoryUpdated;

@protocol SPCDataSourceDelegate <NSObject>
@optional
- (void)segmentedControlValueChanged:(NSInteger)index;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView travel:(CGFloat)travel continuousTravel:(CGFloat)continuousTravel;
- (void)detectedSignificantOffsetChange;
- (void)detectedHeaderScrolledOffContentArea;
- (void)detectedHeaderScrolledOnContentArea;
- (void)updateCellToPrivate:(NSIndexPath *)indexPath;
- (void)updateCellToPublic:(NSIndexPath *)indexPath;
- (void)didGetCellForMemory:(Memory *)memory atIndexPath:(NSIndexPath *)indexPath;
- (void)updateMaxIndexViewed:(NSInteger)maxIndexViewed;
- (void)fetchUserProfile;
- (void)showChat;
@end

@interface SPCBaseDataSource : NSObject <UITableViewDataSource, UITableViewDelegate, DZNSegmentedControlDelegate, UIActionSheetDelegate, SPCMapViewControllerDelegate, SPCAdjustMemoryLocationViewControllerDelegate, SPCTagFriendsViewControllerDelegate>

@property (nonatomic, weak) id<SPCDataSourceDelegate> delegate;

@property (nonatomic, strong) NSArray *segmentItems;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;
@property (nonatomic, strong) DZNSegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray *feed;
@property (nonatomic, strong) NSArray *fullFeed;
@property (nonatomic, assign) NSInteger profileIdToIgnoreForAuthorTaps;
@property (nonatomic, assign) NSString *userTokenToIgnoreForAuthorTaps;
@property (nonatomic, assign) BOOL userIsViewingComments;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, assign) BOOL hasLoaded;
@property (nonatomic, assign) BOOL feedUnavailable;
@property (nonatomic, assign) BOOL isProfileData;
@property (nonatomic, assign) BOOL isWithinMAMDistance;
@property (nonatomic, assign) BOOL ignoreLocationSetting;

@property (nonatomic, strong) NSString *hashTagFilter;

@property (nonatomic, assign, getter = isDraggingSrollView) BOOL draggingScrollView;

@property (nonatomic, assign) CGFloat restingOffset;
@property (nonatomic, assign) CGFloat triggeringOffset;

@property (nonatomic, assign) BOOL hasSegmentedControlCustomTransitionRatio;
@property (nonatomic, readonly) CGFloat segmentedControlCustomTransitionRatio;

@property (nonatomic, strong) UIColor *statusBarBackgroundColorMin;
@property (nonatomic, strong) UIColor *statusBarBackgroundColorMax;

//prefetching feed iamges
@property (nonatomic, assign) NSInteger maxIndexViewed;
@property (nonatomic, strong) NSArray *assetQueue;
@property (nonatomic, strong) NSMutableSet *prefetchedList;
@property (nonatomic, assign) NSInteger currentPrefetchIndex;
@property (nonatomic, strong) UIImageView *prefetchImageView;
@property (nonatomic, assign) BOOL feedIsNew;
@property (nonatomic, assign) BOOL prefetchPaused;


// Bouncing *dancing* arrow
@property (nonatomic, strong) UIImageView *bouncingArrowImageView;
@property (nonatomic) BOOL shouldShowBouncingArrowImageView;

// Sets the current feed to the feed provided such that the
// memories currently displayed in the table view are not displaced.
// In other words, although the feed itself has potentially changed and the
// TableView offset updated, the user should not notice that anything is different
// (until they scroll up or down).  Obviously this requires that
// 1. The memories currently displayed in the table exist in the same contiguous
//      order in the new feed
// 2. There is enough content in the list, and the user has scrolled far enough,
//      that no header / content height issues are caused as a result.
//
// If this method returns 'YES', the 'feed' property has been updated, the table
// data reloaded, and the table content offset changed appropriately.
// Otherwise, nothing has changed.  It is up to the caller to determine the
// next course of action -- do they e.g. update the feed in a way that disturbs
// user experience?
- (BOOL)setFeed:(NSArray *)feed andReloadWithoutDisplacingTableView:(UITableView *)tableView;

- (int)fullStarCount;
- (void)selectedSegment:(id)sender;

- (void)resetToRestingIfNecessary:(UIScrollView *)scrollView animated:(BOOL)animated;

- (void)updateSegmentedControlWithScrollView:(UIScrollView *)scrollView;
- (void)updateSegmentedControlWithLockedToTopAppearanceProportion:(CGFloat)proportion;

-(void)updatePrefetchQueueWithMemAtIndex;
-(void)prefetchNextImageInQueue;

-(void)updateWithPersonUpdate:(PersonUpdate *)personUpdate;


@end
