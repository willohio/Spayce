//
//  SPCTileSupportingDataSource.m
//  Spayce
//
//  Created by Jake Rosin on 4/8/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCTileSupportingDataSource.h"

@implementation SPCTileSupportingDataSource


#pragma mark lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        self.memoryCellDisplayType = MemoryCellDisplayTypeGrid;
    }
    return self;
}


#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRowsRet = 0;
    if (MemoryCellDisplayTypeGrid == self.memoryCellDisplayType && 0 < self.feed.count) {
        numberOfRowsRet = 1;
    } else {
        numberOfRowsRet = [super tableView:tableView numberOfRowsInSection:section];
    }
    
    return numberOfRowsRet;
}

- (BOOL)isMemoryAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section != 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cellRet;
    if (self.hasLoaded && 0 < self.feed.count && MemoryCellDisplayTypeGrid == self.memoryCellDisplayType) {
        cellRet = [tableView dequeueReusableCellWithIdentifier:SPCFeedCellIdentifier forIndexPath:indexPath];
        self.memoryGridCollectionView.frame = CGRectMake(0, 0, self.tableViewWidth, self.memoryGridCollectionView.totalGridHeight);
        [cellRet addSubview:self.memoryGridCollectionView];
    } else {
        cellRet = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    return cellRet;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightRet = 0.0f;
    if (self.hasLoaded && 0 < self.memoryGridCollectionView.memories.count && MemoryCellDisplayTypeGrid == self.memoryCellDisplayType) {
        heightRet = self.memoryGridCollectionView.totalGridHeight;
    } else {
        heightRet = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    return heightRet;
}

@end
