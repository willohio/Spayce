//
//  SPCGrid.h
//  Spayce
//
//  Created by Christopher Taylor on 12/2/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCTrendingVenueCell.h"
@class Venue;
@class Memory;
@class Person;
@class SPCMontageView;

@protocol SPCGridDelegate <NSObject>

@optional

@property (nonatomic, assign) BOOL pullToRefreshInProgress;

- (void)showVenueDetail:(Venue *)v;
- (void)showVenueDetail:(Venue *)v jumpToMemory:(Memory *)memory withImage:(UIImage *)image atRect:(CGRect)rect;
- (void)showMemoryComments:(Memory *)m;
- (void)showMemoryComments:(Memory *)m withImage:(UIImage *)image atRect:(CGRect)rect;
- (void)showVenueDetailFeed:(Venue *)v;
- (void)showPerson:(Person *)p;
- (void)scrollingUpAdjustViewsWithDelta:(float)deltaAdj;
- (void)scrollingDownAdjustViewsWithDelta:(float)deltaAdj;
- (void)worldContentComplete;   
- (void)nearbyContentComplete;
- (void)contentComplete;
- (void)gridScrolled:(UIScrollView *)scrollView;
- (void)gridDragEnded:(UIScrollView *)scrollView  willDecelerate:(BOOL)decelerate;
- (void)showFeedForMemories:(NSArray *)memories;
- (void)restoreGridHeadersAndFooters;

@end


typedef NS_ENUM(NSInteger, GridState) {
    GridStateLocal,
    GridStateWorld,
    GridStateHash
};

@interface SPCGrid : UIView <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SPCTrendingVenueCellDelegate>

@property (nonatomic, weak) NSObject <SPCGridDelegate> *delegate;
@property (nonatomic, strong) UICollectionView * collectionView;
@property (nonatomic, assign) BOOL draggingScrollView;
@property (nonatomic, assign) float baseOffSetY;
@property (nonatomic, readonly) NSInteger cellCount;
@property (nonatomic, strong) NSArray *memories;
@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, strong) NSArray *people;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, weak) SPCMontageView *viewMontage;
@property (nonatomic, strong) NSDate *dateMontageLoadFailed;
@property (nonatomic, strong) NSArray *montageLastViewedMemories;
- (void)gridDidAppear;
- (void)gridDidDisappear;
- (void)fetchGridContent;
- (void)fetchNearbyGridContent;
- (void)fetchContentForHash:(NSString *)hashTag memory:(Memory *)fallbackMem;
- (void)setBaseContentOffset:(float)baseOffsetY;
- (void)resetScrollingAdjustment;
- (void)refreshMontageContentIfNeeded;

@end
