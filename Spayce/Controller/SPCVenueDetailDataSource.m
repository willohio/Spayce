//
//  SPCVenueDetailDataSource.m
//  Spayce
//
//  Created by William Santiago on 9/30/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCVenueDetailDataSource.h"

// Model
#import "Asset.h"
#import "Memory.h"
#import "Person.h"
#import "User.h"

// View
#import "SPCSegmentedControlHeaderView.h"
#import "SPCVenueSegmentedControlCell.h"

// Category
#import "UIImageView+WebCache.h"
#import "UIScreen+Size.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"

// Utils
#import "APIUtils.h"


@interface SPCVenueDetailDataSource()

@property (nonatomic, strong) SPCVenueSegmentedControlCell *segmentedControlCell;

@end


@implementation SPCVenueDetailDataSource

#pragma mark - Object lifecycle

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}


#pragma mark - Accessors

- (NSString *)loadingMessageWhenFullFeedIsNotEmptyButFeedIsEmpty {
    if ([UIScreen isLegacyScreen]) {
        return NSLocalizedString(@"\nLeave a memory in this location\nand become a part of history.\n", nil);
    }
    else {
        return NSLocalizedString(@"\n\nBe a Legend\nLeave a memory in this location\nand become a part of history.\n\n", nil);
    }
}

#pragma mark - Private

- (NSArray *)feedFilteredByHashTag:(NSString *)hashTag {
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:self.fullFeed.count];
    if (!self.hashTagFilter) {
        [tempArray addObjectsFromArray:self.fullFeed];
    } else {
        for (Memory *memory in self.fullFeed) {
            if ([memory matchesHashTag:hashTag]) {
                [tempArray addObject:memory];
            }
        }
    }
    
    return [NSArray arrayWithArray:tempArray];
}


#pragma mark - Setters


- (void)setFullFeed:(NSArray *)fullFeed {
    [super setFullFeed:fullFeed];
}

- (void)setFeed:(NSArray *)feed {
    [super setFeed:feed];
    
    [self.memoryGridCollectionView addMemories:feed andAddToTop:NO];
}

- (void)setHashTagFilter:(NSString *)hashTagFilter {
    if (!hashTagFilter && !self.hashTagFilter) {
        // no change
        return;
    } else if ([hashTagFilter isEqualToString:self.hashTagFilter]) {
        // no change
        return;
    }
    
    [super setHashTagFilter:hashTagFilter];
    
    NSMutableArray *includedMems = [NSMutableArray array];
    for (Memory *memory in self.fullFeed) {
        if (!hashTagFilter) {
            [includedMems addObject:memory];
        } else if ([memory.hashTags containsObject:hashTagFilter]) {
            [includedMems addObject:memory];
        }
    }
    
    [super setFeed:[NSArray arrayWithArray:includedMems]];
    [self.memoryGridCollectionView resetMemories:self.feed];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ((self.hasLoaded && 0 < self.feed.count)) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.hasLoaded && 0 < self.feed.count) {
        if (section == 0) {
            return 1;
        }
    }
    
    // Memory section
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (BOOL)isMemoryAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section != 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.hasLoaded && 0 < self.feed.count) {
        if (![self isMemoryAtIndexPath:indexPath]) {
            SPCVenueSegmentedControlCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCVenueSegmentedControlCellIdentifier forIndexPath:indexPath];
            [cell configureWithNumberOfMemories:self.hashTagFilter ? self.feed.count : self.venue.totalMemories];
            if ([self.delegate respondsToSelector:@selector(tappedMemoryCellDisplayType:onVenueSegmentedControl:)]) {
                cell.delegate = (id<SPCVenueSegmentedControllCellDelegate>)self.delegate;
            }
            self.segmentedControlCell = cell;
            return cell;
        }
    }
    
    // Section 1 (2nd section)
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.hasLoaded) {
        if (indexPath.section == 0) {
            return 90.0f/750.0f * self.tableViewWidth; // 90pt height on a 750pt-wide psd
        } else {
            if (self.feed.count == 0 && self.hasLoaded) {
                return 0;
            }
        }
    }
    
    // Section 1 (memories)
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}



@end
