//
//  SPCMemoryGridCollectionView.h
//  Spayce
//
//  Created by Arria P. Owlia on 3/20/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum MemoryGridCollectionViewCellSize {
    // These values match up with multipliers used in code! Edit mapped integer with caution
    MemoryGridCollectionViewCellSizeUnknown = 0,
    MemoryGridCollectionViewCellSizeOneByOne = 1,
    MemoryGridCollectionViewCellSizeTwoByTwo = 2,
    MemoryGridCollectionViewCellSizeThreeByThree = 3,
} MemoryGridCollectionViewCellSize;

@class SPCMemoryGridCollectionViewLayout;
@protocol SPCMemoryGridCollectionViewLayoutDelegate <NSObject>

- (MemoryGridCollectionViewCellSize)cellSizeForItemAtIndexPath:(NSIndexPath *)indexPath usingLayout:(SPCMemoryGridCollectionViewLayout *)layout;
- (CGFloat)collectionViewWidthUsingLayout:(SPCMemoryGridCollectionViewLayout *)layout;

@end

@interface SPCMemoryGridCollectionViewLayout : UICollectionViewLayout

@property (nonatomic, weak) id<SPCMemoryGridCollectionViewLayoutDelegate> delegate;

@end

@class Memory;
@interface SPCMemoryGridCollectionView : UICollectionView <SPCMemoryGridCollectionViewLayoutDelegate>

// Memories to display
@property (strong, nonatomic, readonly) NSArray *memories;

// TableView width - input
@property (nonatomic) CGFloat tableViewWidth;

// Height of the grid
@property (nonatomic, readonly) CGFloat totalGridHeight;

// Appear/Dsappear handlers
- (void)viewWillAppear;
- (void)viewWillDisappear;

// Data
// ONLY ADDs memories. Should be called with ideally ~20 mems at a time
- (void)addMemories:(NSArray *)memories andAddToTop:(BOOL)addToTop;
- (void)resetMemories:(NSArray *)memories;
- (void)removeMemory:(Memory *)memory;

@end