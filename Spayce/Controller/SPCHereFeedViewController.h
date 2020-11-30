//
//  SPCHereFeedViewController.h
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCHereFeedViewControllerDelegate.h"
#import "MemoryCommentsViewController.h"
#import "Venue.h"
#import "SPCBaseDataSource.h"
#import "SPCHereEnums.h"
#import "SPCFeaturedContentCell.h"

@class SPCHereDataSource;

@interface SPCHereFeedViewController : UIViewController <SPCDataSourceDelegate, SPCFeaturedContentCellDelegate>

@property (nonatomic, strong) SPCHereDataSource *dataSource;
@property (nonatomic, weak) NSObject <SPCHereFeedViewControllerDelegate> *delegate;
@property (nonatomic, assign) BOOL manualLocationResetInProgress;
@property (nonatomic, readonly) CGFloat transparentPixelsAtTop;
@property (nonatomic, assign) CGFloat featuredContentWidth;
@property (nonatomic, assign) CGFloat featuredContentSpacing;
@property (nonatomic, assign) CGFloat featuredContentHeight;
@property (nonatomic, strong) UIActivityIndicatorView *locationLoadingMemoriesActivityIndicatorView;
@property (nonatomic, assign) BOOL contentFetched;
@property (nonatomic, assign) SpayceState spayceState;

- (void)locationResetManually;
- (void)updateUserLocationToVenue:(Venue *)venue withMemories:(NSArray *)memories nearbyVenues:(NSArray *)nearbyVenues featuredContent:(NSArray *)featuredContent spayceState:(SpayceState)spayceState;
- (void)updateCellToPrivate:(NSIndexPath *)indexPath;
- (void)updateCellToPublic:(NSIndexPath *)indexPath;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)updateMaxIndexViewed:(NSInteger)maxIndexViewed;
- (void)resetScrollerAndMap;
- (void)showVenueDetailFeedForNewMemory:(Memory *)memory;
- (void)setHeaderForCurrentVenue:(Venue *)venue withSpayceState:(SpayceState)spayceState;
-(void)refreshLocationButtonPressed;
@end
