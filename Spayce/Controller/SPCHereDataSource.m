//
//  SPCHereDataSource.m
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCHereDataSource.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "User.h"

// View
#import "SPCSegmentedControlHeaderView.h"

// Category
#import "UIColor+CrossFade.h"
#import "UIImageView+WebCache.h"
#import "UIScreen+Size.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"

// Utility
#import "APIUtils.h"

NSString * SPCHereTriggeringOffsetNotification = @"SPCHereTriggeringOffsetNotification";
NSString * SPCHereSignificantScrollTowardsTriggerNotification = @"SPCHereSignificantScrollTowardsTriggerNotification";
NSString * SPCHereSignificantScrollAwayFromTriggerNotification = @"SPCHereSignificantScrollAwayFromTriggerNotification";
NSString * SPCHereSignificantScrollNotification = @"SPCHereSignificantScrollNotification";
NSString * SPCHereLoadMoreDataNotification = @"SPCHereLoadMoreDataNotification";
NSString * SPCHereScrollHeaderOffContentAreaNotification = @"SPCHereScrollHeaderOffContentAreaNotification";
NSString * SPCHereScrollHeaderOnContentAreaNotification = @"SPCHereScrollHeaderOnContentAreaNotification";
NSString * SPCHereScrollHeaderOffTableNotification = @"SPCHereScrollHeaderOffTableNotification";
NSString * SPCHereScrollHeaderOnTableNotification = @"SPCHereScrollHeaderOnTableNotification";

NSString * SPCHerePushingViewController = @"SPCHerePushingViewController";

@interface SPCHereDataSource ()

@property (nonatomic, strong) SPCSegmentedControlHeaderView *headerView;
@property (nonatomic, strong) UIView *segmentedControlBackgroundView;
@property (nonatomic, strong) UIView *segmentedControlShadowView;

@end

@implementation SPCHereDataSource

#pragma mark - SPCBaseDataSource methods

-(void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)updateSegmentedControlWithLockedToTopAppearanceProportion:(CGFloat)proportion {
    CGFloat tableWidth = CGRectGetWidth(self.headerView.frame);
    
    if (proportion <= 0) {
        
        // set background and shadow views to their list-cell appearance
        CGRect frame = self.segmentedControlShadowView.frame;
        frame.origin.x = 4.5;
        frame.size.width = tableWidth - 9;
        self.segmentedControlShadowView.frame = frame;
        self.segmentedControlShadowView.backgroundColor = [UIColor  colorWithRGBHex:0xc4c5c5];
        self.segmentedControlShadowView.layer.cornerRadius = 1.5;
        // and the background view...
        frame = self.segmentedControlBackgroundView.frame;
        frame.origin.x = 5;
        frame.size.width = tableWidth - 10;
        self.segmentedControlBackgroundView.frame = frame;
        self.segmentedControlBackgroundView.backgroundColor = [UIColor  whiteColor];
        self.segmentedControlBackgroundView.layer.cornerRadius = 1.5;
        
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateHighlighted];
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateDisabled];
        [self.segmentedControl setTitleColor:[UIColor colorWithWhite:137.0/255.0 alpha:1.0] forState:UIControlStateSelected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarColorNotification object:self userInfo:@{ @"backgroundColor": self.statusBarBackgroundColorMin, @"proportion": @(proportion) }];
    } else if (proportion < 1) {
        CGFloat edgeInset = 5 * (1-proportion);
        
        // adjust corner radius over the last 0.5 of the offset...
        CGFloat cornerRadius = 1.5;
        if (edgeInset < 0.5) {
            cornerRadius = 1.5 * (edgeInset / 0.5);
        }
        
        UIColor *bgSrcColor = [UIColor  colorWithRGBHex:0xc4c5c5];
        UIColor *srcColor = [UIColor whiteColor];
        UIColor *dstColor = [UIColor colorWithRGBHex:0x374357 alpha:1.0f];
    
        UIColor *bgColor = [UIColor colorForFadeBetweenFirstColor:bgSrcColor secondColor:dstColor atRatio:proportion];
        UIColor *color = [UIColor colorForFadeBetweenFirstColor:srcColor secondColor:dstColor atRatio:proportion];
        
        // set background and shadow views halfway between their cell-view
        // and locked-to-top appearances.
        CGRect frame = self.segmentedControlShadowView.frame;
        frame.origin.x = edgeInset - 0.5;
        frame.size.width = tableWidth - (frame.origin.x * 2);
        self.segmentedControlShadowView.frame = frame;
        self.segmentedControlShadowView.backgroundColor = bgColor;
        self.segmentedControlShadowView.layer.cornerRadius = cornerRadius;
        // and the background view...
        frame = self.segmentedControlBackgroundView.frame;
        frame.origin.x = edgeInset;
        frame.size.width = tableWidth - (frame.origin.x * 2);
        self.segmentedControlBackgroundView.frame = frame;
        self.segmentedControlBackgroundView.backgroundColor = color;
        self.segmentedControlBackgroundView.layer.cornerRadius = cornerRadius;
        
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarColorNotification object:self userInfo:@{ @"backgroundColor": [UIColor colorForFadeBetweenFirstColor:self.statusBarBackgroundColorMin secondColor:self.statusBarBackgroundColorMax atRatio:proportion], @"proportion": @(proportion) }];
    }
    else {
        // set background and shadow views to their locked-to-top appearance.
        // slightly beyond the edges of the table (2 px. each side) to cover up
        // the rounded corners.
        CGRect frame = self.segmentedControlShadowView.frame;
        frame.origin.x = -0.5;
        frame.size.width = tableWidth + 1;
        self.segmentedControlShadowView.frame = frame;
        self.segmentedControlShadowView.backgroundColor = [UIColor colorWithRGBHex:0x374357 alpha:1.0f];
        self.segmentedControlShadowView.layer.cornerRadius = 0;
        // and the background view...
        frame = self.segmentedControlBackgroundView.frame;
        frame.origin.x = 0;
        frame.size.width = tableWidth;
        self.segmentedControlBackgroundView.frame = frame;
        self.segmentedControlBackgroundView.backgroundColor = [UIColor colorWithRGBHex:0x374357 alpha:1.0f];
        self.segmentedControlBackgroundView.layer.cornerRadius = 0;
        
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
        [self.segmentedControl setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarColorNotification object:self userInfo:@{ @"backgroundColor": self.statusBarBackgroundColorMax, @"proportion": @(proportion) }];
    }
}



#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (self.fullFeed && self.fullFeed.count > 0) ? 45 : 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!self.fullFeed || self.fullFeed.count == 0) {
        return nil;
    }
    
    CGFloat headerHeight = [self tableView:tableView heightForHeaderInSection:section];
    _headerView = [[SPCSegmentedControlHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(tableView.frame), headerHeight)];
    _headerView.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:231.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
    _headerView.defaultHeight = 45.0;
    _headerView.bannerHeight = 60.0;
    
    _segmentedControlShadowView = [[UIView alloc] initWithFrame:CGRectMake(4.5, 0.0, CGRectGetWidth(tableView.frame)-9, headerHeight)];
    _segmentedControlShadowView.backgroundColor = [UIColor  colorWithRGBHex:0xc4c5c5];
    [_segmentedControlShadowView.layer setCornerRadius:1.5f];
    [_headerView addSubview:_segmentedControlShadowView];
    
    _segmentedControlBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(5, 0.0, CGRectGetWidth(tableView.frame)-10, headerHeight-1)];
    _segmentedControlBackgroundView.backgroundColor = [UIColor  whiteColor];
    [_segmentedControlBackgroundView.layer setCornerRadius:1.5f];
    [_headerView addSubview:_segmentedControlBackgroundView];
    
    self.segmentedControl = [[DZNSegmentedControl alloc] initWithItems:self.segmentItems];
    self.segmentedControl.frame = _headerView.bounds;
    self.segmentedControl.contentInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
    self.segmentedControl.tintColor = [UIColor colorWithRed:254.0/255.0f green:150.0/255.0f blue:30.0/255.0f alpha:1.0f];;
    self.segmentedControl.delegate = self;
    self.segmentedControl.selectedSegmentIndex = self.selectedSegmentIndex;
    self.segmentedControl.height = 45.0;
    self.segmentedControl.selectionIndicatorOffset = 7;
    self.segmentedControl.layer.cornerRadius = 1.5f;
    self.segmentedControl.layer.masksToBounds = YES;
    [self.segmentedControl addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
    [_headerView addSubview:self.segmentedControl];
    
    [self updateSegmentedControlWithScrollView:tableView];

    return _headerView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView loadMoreDataCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCFeedCellIdentifier];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}


#pragma mark - UIScrollViewDelegate

- (void)detectedTrigger {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereTriggeringOffsetNotification object:nil];
}

- (void)detectedScrolledSignificantlyAwayFromTrigger {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereSignificantScrollAwayFromTriggerNotification object:nil];
}

- (void)detectedScrolledSignificantlyTowardsTrigger {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereSignificantScrollTowardsTriggerNotification object:nil];
}

- (void)detectedSignificantOffsetChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereSignificantScrollNotification object:nil];
}

- (void)detectedReachingTableBottom {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereLoadMoreDataNotification object:nil];
}

- (void)detectedHeaderScrolledOffScreen {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereScrollHeaderOffTableNotification object:nil];
}

- (void)detectedHeaderScrolledOnScreen {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereScrollHeaderOnTableNotification object:nil];
}

- (void)detectedHeaderScrolledOffContentArea {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereScrollHeaderOffContentAreaNotification object:nil];
}

- (void)detectedHeaderScrolledOnContentArea {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHereScrollHeaderOnContentAreaNotification object:nil];
}

- (void)pushedNewViewController {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCHerePushingViewController object:nil];
}

#pragma mark - Actions

- (void)selectedSegment:(id)sender {
    [super selectedSegment:sender];

    //delay sorting slightly to allow seg control animation to finish before the table header view gets refreshed
    if (self.selectedSegmentIndex == 0) {
        [self performSelector:@selector(filterByRecency) withObject:nil afterDelay:.2];
    }
    else if (self.selectedSegmentIndex == 1) {
        [self performSelector:@selector(filterByStars) withObject:nil afterDelay:.2];
    }
    else if (self.selectedSegmentIndex == 2) {
        [self performSelector:@selector(filterByPersonal) withObject:nil afterDelay:.2];
    }
}

#pragma mark - Filters

- (void)filterByRecency {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.fullFeed];
    NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
    [tempArray sortUsingDescriptors:@[dateSorter]];
    NSArray *sortedArray = [NSArray arrayWithArray:tempArray];
    self.feed = sortedArray;
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadForFilters object:nil];
}

- (void)filterByStars {
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.fullFeed];
    NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starsCount" ascending:NO];
    [tempArray sortUsingDescriptors:@[starSorter]];
    NSArray *sortedArray = [NSArray arrayWithArray:tempArray];
    self.feed = sortedArray;
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadForFilters object:nil];
}

- (void)filterByPersonal {
    int currUserId = (int)[AuthenticationManager sharedInstance].currentUser.userId;
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    for (int i=0; i<[self.fullFeed count]; i++){
        
        Memory *m = (Memory *)self.fullFeed[i];
        
        //current user is author
        if (m.author.recordID == currUserId) {
            [tempArray addObject:m];
        } else if (m.author.followingStatus == FollowingStatusFollowing) {
            [tempArray addObject:m];
        }
    }
    
    self.feed = [NSArray arrayWithArray:tempArray];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadData object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCReloadForFilters object:nil];
}

- (NSString *)loadingMessageWhenFullFeedIsNotEmptyButFeedIsEmpty {
    if ([UIScreen isLegacyScreen]) {
        return NSLocalizedString(@"\nLeave a memory in this location\nand become a part of history.\n", nil);
    }
    else {
    return NSLocalizedString(@"\n\nBe a Legend\nLeave a memory in this location\nand become a part of history.\n\n", nil);
    }
}


@end
