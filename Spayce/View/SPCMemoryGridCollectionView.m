//
//  SPCMemoryGridCollectionView.m
//  Spayce
//
//  Created by Arria P. Owlia on 3/20/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCMemoryGridCollectionView.h"

// Model
#import "SPCMemoryGridCell.h"
#import "Memory.h"

@interface SPCMemoryGridCollectionView() <UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource, SPCMemoryGridCollectionViewLayoutDelegate>

@property (strong, nonatomic) NSArray *cellSizes;

@end

@implementation SPCMemoryGridCollectionView

- (void)dealloc {
    _memories = nil;
    _cellSizes = nil;
}

#pragma mark - Accessors

- (CGFloat)totalGridHeight {
    return self.collectionViewLayout.collectionViewContentSize.height;
}

@synthesize cellSizes = _cellSizes;
- (NSArray *)cellSizes {
    if (nil == _cellSizes) {
        _cellSizes = [NSArray array];
    }
    
    return _cellSizes;
}

@synthesize memories = _memories;
- (NSArray *)memories {
    if (nil == _memories) {
        _memories = [NSArray array];
    }
    return _memories;
}

- (void)setMemories:(NSArray *)memories {
    _memories = memories;
}

#pragma mark - Events

- (void)viewWillAppear {
    NSInteger numSections = [self numberOfSections];
    for (NSInteger section = 0; section < numSections; ++section) {
        NSInteger numItems = [self numberOfItemsInSection:section];
        for (NSInteger item = 0; item < numItems; ++item) {
            UICollectionViewCell *cell = [self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
            
            if ([cell isKindOfClass:[SPCMemoryGridCell class]]) {
                SPCMemoryGridCell *memoryGridCell = (SPCMemoryGridCell *)cell;
                
                [memoryGridCell playIfVideo];
            }
        }
    }
}

- (void)viewWillDisappear {
    NSInteger numSections = [self numberOfSections];
    for (NSInteger section = 0; section < numSections; ++section) {
        NSInteger numItems = [self numberOfItemsInSection:section];
        for (NSInteger item = 0; item < numItems; ++item) {
            UICollectionViewCell *cell = [self cellForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:section]];
            
            if ([cell isKindOfClass:[SPCMemoryGridCell class]]) {
                SPCMemoryGridCell *memoryGridCell = (SPCMemoryGridCell *)cell;
                
                [memoryGridCell pauseIfVideo];
            }
        }
    }
}

#pragma mark - Data

- (void)addMemories:(NSArray *)memories andAddToTop:(BOOL)addToTop {
    // We should be getting between 0 and 25 new mems here.
    // Remove any mems from 'memories' that we already have in our memories member
    NSMutableArray *newMemories = [NSMutableArray array];
    NSMutableSet *setCurrentMemoryRecordIds = [NSMutableSet set];
    for (Memory *memory in self.memories) {
        [setCurrentMemoryRecordIds addObject:@(memory.recordID)];
    }
    for (Memory *memory in memories) {
        if (NO == [setCurrentMemoryRecordIds containsObject:@(memory.recordID)]) {
            [setCurrentMemoryRecordIds addObject:@(memory.recordID)];
            [newMemories addObject:memory];
        }
    }
    
    // First, get a set of cell sizes/star counts from the memories
    NSArray *cellSizes = [self getCellSizesFromMemories:newMemories];
    
    // Second, order the mems
    [self orderCellSizes:&cellSizes withMemories:&newMemories];
    
    // Now, add the cellSizes/memories to our current cellSizes/memories
    NSMutableArray *finalMemories = [NSMutableArray arrayWithArray:self.memories];
    NSMutableArray *finalCellSizes = [NSMutableArray arrayWithArray:self.cellSizes];
    NSMutableArray *newIndexPaths = [NSMutableArray array];
    for (NSInteger i = 0; i < newMemories.count; ++i) {
        if (addToTop) {
            [finalMemories insertObject:[newMemories objectAtIndex:i] atIndex:0];
            [finalCellSizes insertObject:[cellSizes objectAtIndex:i] atIndex:0];
            [newIndexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
        } else {
            [finalMemories addObject:[newMemories objectAtIndex:i]];
            [finalCellSizes addObject:[cellSizes objectAtIndex:i]];
            [newIndexPaths addObject:[NSIndexPath indexPathForItem:i + self.memories.count inSection:0]];
        }
    }
    
    @try
    {
        [self performBatchUpdates:^{
            self.memories = finalMemories;
            self.cellSizes = finalCellSizes;
            [self insertItemsAtIndexPaths:newIndexPaths];
        } completion:^(BOOL finished) {
            [self reloadItemsAtIndexPaths:newIndexPaths];
        }];
    }
    @catch (NSException *except)
    {
        NSLog(@"DEBUG: failure to batch update.  %@", except.description);
    }
}

- (void)resetMemories:(NSArray *)memories {
    // First, get a set of cell sizes/star counts from the memories
    NSArray *cellSizes = [self getCellSizesFromMemories:memories];
    
    // Second, order the mems
    [self orderCellSizes:&cellSizes withMemories:&memories];
    
    // Now, add the cellSizes/memories to our current cellSizes/memories
    
    @try
    {
        self.memories = memories;
        self.cellSizes = cellSizes;
        [self reloadData];
    }
    @catch (NSException *except)
    {
        NSLog(@"DEBUG: failure to batch update.  %@", except.description);
    }
}

- (void)removeMemory:(Memory *)memory {
    __block Memory *memoryToRemove = nil;
    __block NSUInteger indexOfMemoryToRemove = NSNotFound;
    [self.memories enumerateObjectsUsingBlock:^(Memory *currentMemory, NSUInteger idx, BOOL *stop) {
        if (currentMemory.recordID == memory.recordID) {
            memoryToRemove = currentMemory;
            indexOfMemoryToRemove = idx;
            *stop = YES;
        }
    }];
    
    if (nil != memoryToRemove && NSNotFound != indexOfMemoryToRemove) {
        // Proceed with the removal
        MemoryGridCollectionViewCellSize memoryCellSize = (MemoryGridCollectionViewCellSize)[self.cellSizes objectAtIndex:indexOfMemoryToRemove];
        
        NSMutableArray *finalMemories = [NSMutableArray arrayWithArray:self.memories];
        NSMutableArray *finalCellSizes = [NSMutableArray arrayWithArray:self.cellSizes];
        NSMutableArray *indexPathsToReload = [NSMutableArray array];
        if (MemoryGridCollectionViewCellSizeThreeByThree == memoryCellSize) {
            // We're already good to go, i.e. no need to touch cell sizes
            [finalMemories removeObjectAtIndex:indexOfMemoryToRemove];
            [finalCellSizes removeObjectAtIndex:indexOfMemoryToRemove];
        } else {
            // We do need to meddle with the cell sizes
            // There are 9 cases where this cell could be
            // What matters though is whether it's on the left, middle, or right of a group of three
            // Get the modulo of the area prior to this cell's location
            NSInteger cellUnitArea = 0;
            for (NSInteger i = 0;i < indexOfMemoryToRemove; ++i) {
                MemoryGridCollectionViewCellSize cellSize = (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:i] integerValue];
                
                if (MemoryGridCollectionViewCellSizeThreeByThree == cellSize) {
                    cellUnitArea = cellUnitArea + 9;
                } else if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSize) {
                    cellUnitArea = cellUnitArea + 4;
                } else if (MemoryGridCollectionViewCellSizeOneByOne == cellSize) {
                    cellUnitArea = cellUnitArea + 1;
                }
            }
            
            // The modulo of the grid cell area gives us if it's a left/middle/right cell
            NSInteger modulo = cellUnitArea % 3;
            NSInteger indexFirstCellToUpsize = NSNotFound;
            NSInteger indexSecondCellToUpsize = NSNotFound;
            NSIndexPath *indexPathFirstToReload;
            NSIndexPath *indexPathSecondToReload;
            if (0 == modulo) {
                indexFirstCellToUpsize = indexOfMemoryToRemove + 1;
                indexSecondCellToUpsize = indexOfMemoryToRemove + 2;
                indexPathFirstToReload = [NSIndexPath indexPathForItem:indexOfMemoryToRemove inSection:0];
                indexPathSecondToReload = [NSIndexPath indexPathForItem:indexOfMemoryToRemove + 1 inSection:0];
            } else if (1 == modulo) {
                indexFirstCellToUpsize = indexOfMemoryToRemove - 1;
                indexSecondCellToUpsize = indexOfMemoryToRemove + 1;
                indexPathFirstToReload = [NSIndexPath indexPathForItem:indexOfMemoryToRemove - 1 inSection:0];
                indexPathSecondToReload = [NSIndexPath indexPathForItem:indexOfMemoryToRemove inSection:0];
            } else if (2 == modulo) {
                indexFirstCellToUpsize = indexOfMemoryToRemove - 2;
                indexSecondCellToUpsize = indexOfMemoryToRemove - 1;
                indexPathFirstToReload = [NSIndexPath indexPathForItem:indexOfMemoryToRemove - 2 inSection:0];
                indexPathSecondToReload = [NSIndexPath indexPathForItem:indexOfMemoryToRemove - 1 inSection:0];
            }
            
            // Upsize the two indexes
            if (0 <= indexFirstCellToUpsize && indexFirstCellToUpsize < finalCellSizes.count) {
                [finalCellSizes replaceObjectAtIndex:indexFirstCellToUpsize withObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                [indexPathsToReload addObject:indexPathFirstToReload];
            }
            
            if (0 <= indexSecondCellToUpsize && indexSecondCellToUpsize < finalCellSizes.count) {
                [finalCellSizes replaceObjectAtIndex:indexSecondCellToUpsize withObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                [indexPathsToReload addObject:indexPathSecondToReload];
            }
            
            // Finally, remove the memory from the arrays
            [finalMemories removeObjectAtIndex:indexOfMemoryToRemove];
            [finalCellSizes removeObjectAtIndex:indexOfMemoryToRemove];
        }
        
        @try
        {
            [self performBatchUpdates:^{
                self.memories = finalMemories;
                self.cellSizes = finalCellSizes;
                [self deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:indexOfMemoryToRemove inSection:0]]];
            } completion:^(BOOL finished) {
                [self reloadItemsAtIndexPaths:indexPathsToReload];
            }];
        }
        @catch (NSException *except)
        {
            NSLog(@"DEBUG: failure to batch update.  %@", except.description);
        }
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.memories.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCMemoryGridCell *cell = [self dequeueReusableCellWithReuseIdentifier:SPCMemoryGridCellIdentifier forIndexPath:indexPath];
    
    MemoryGridCollectionViewCellSize size = (MemoryGridCollectionViewCellSize)[[self.cellSizes objectAtIndex:indexPath.row] integerValue];
    [cell configureWithMemory:[self.memories objectAtIndex:indexPath.row] andQuality:(MemoryGridCellQuality)size];
    
    return cell;
}

#pragma mark - SPCMemoryGridCollectionViewLayoutDelegate

- (MemoryGridCollectionViewCellSize)cellSizeForItemAtIndexPath:(NSIndexPath *)indexPath usingLayout:(SPCMemoryGridCollectionViewLayout *)layout {
    return (MemoryGridCollectionViewCellSize)[[self.cellSizes objectAtIndex:indexPath.row] integerValue];
}

- (CGFloat)collectionViewWidthUsingLayout:(SPCMemoryGridCollectionViewLayout *)layout {
    return self.tableViewWidth;
}

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithFrame:frame collectionViewLayout:layout]) {
        if ([layout isKindOfClass:[SPCMemoryGridCollectionViewLayout class]]) {
            SPCMemoryGridCollectionViewLayout *mgcvl = (SPCMemoryGridCollectionViewLayout *)layout;
            mgcvl.delegate = self;
        }
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.dataSource = self;
    
    [self registerClass:[SPCMemoryGridCell class] forCellWithReuseIdentifier:SPCMemoryGridCellIdentifier];
}

#pragma mark - Helpers

- (NSArray *)getCellSizesFromMemories:(NSArray *)memories {
    // Make an array of all the star counts
    NSMutableArray *arrayStarCounts = [[NSMutableArray alloc] initWithCapacity:memories.count];
    for (Memory *memory in memories) {
        [arrayStarCounts addObject:@(memory.starsCount)];
    }
    
    // Sort the star counts - Highest to lowest
    [arrayStarCounts sortUsingComparator:^NSComparisonResult(id starCount1, id starCount2) {
        NSNumber *first = (NSNumber *)starCount1;
        NSNumber *second = (NSNumber *)starCount2;
        return [second compare:first];
    }];
    
    NSMutableArray *cellSizes = [NSMutableArray array];
    if (memories.count == 0) {
        // Do not add to the array
    } else if (3 >= memories.count) { // Here, we'll show 1x1 cells
        for (int i = 0; i < memories.count; ++i) {
            [cellSizes addObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
        }
    } else if (7 >= memories.count) { // Here, we'll use 1 3x3, 1 2x2, and the rest 1x1
        BOOL have3x3 = NO;
        BOOL have2x2 = NO;
        NSNumber *starCount1num = [arrayStarCounts objectAtIndex:0];
        NSInteger starCount1 = [starCount1num integerValue];
        NSNumber *starCount2num = [arrayStarCounts objectAtIndex:1];
        NSInteger starCount2 = [starCount2num integerValue];
        for (Memory *memory in memories) {
            if (NO == have3x3 && starCount1 == memory.starsCount) {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                have3x3 = YES;
            } else if (NO == have2x2 && starCount2 == memory.starsCount) {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeTwoByTwo)];
                have2x2 = YES;
            } else {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeOneByOne)];
            }
        }
    } else { // Here, we can use 1 3x3, 2 2x2s, and the rest 1x1
        BOOL have3x3 = NO;
        BOOL haveFirst2x2 = NO;
        BOOL haveSecond2x2 = NO;
        NSNumber *starCount1num = [arrayStarCounts objectAtIndex:0];
        NSInteger starCount1 = [starCount1num integerValue];
        NSNumber *starCount2num = [arrayStarCounts objectAtIndex:1];
        NSInteger starCount2 = [starCount2num integerValue];
        NSNumber *starCount3num = [arrayStarCounts objectAtIndex:2];
        NSInteger starCount3 = [starCount3num integerValue];
        for (Memory *memory in memories) {
            if (NO == have3x3 && starCount1 == memory.starsCount) {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                have3x3 = YES;
            } else if (NO == haveFirst2x2 && starCount2 == memory.starsCount) {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeTwoByTwo)];
                haveFirst2x2 = YES;
            } else if (NO == haveSecond2x2 && starCount3 == memory.starsCount) {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeTwoByTwo)];
                haveSecond2x2 = YES;
            } else {
                [cellSizes addObject:@(MemoryGridCollectionViewCellSizeOneByOne)];
            }
        }
    }
    
    return cellSizes;
}

- (void)orderCellSizes:(NSArray **)cellSizesPtr withMemories:(NSArray **)memoriesPtr {
    NSArray *cellSizes = *cellSizesPtr;
    NSArray *memories = *memoriesPtr;
    NSMutableArray *finalCellSizes = [NSMutableArray arrayWithArray:cellSizes];
    NSMutableArray *finalMemories = [NSMutableArray arrayWithArray:memories];
    // We need to order the cell sizes in such a way that we do not display empty blocks (cell units)
    // In other words, THIS METHOD RE-ORDERS the self.cellSizes and self.memories arrays' order
    
    NSInteger num1x1Cells = 0;
    NSInteger num2x2Cells = 0;
    NSInteger num3x3Cells = 0;
    NSInteger totalCellUnitArea = 0;
    for (NSInteger i = 0; i < cellSizes.count; ++i) {
        MemoryGridCollectionViewCellSize cellSize = (MemoryGridCollectionViewCellSize)[[cellSizes objectAtIndex:i] integerValue];
        if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSize) {
            num2x2Cells = num2x2Cells + 1;
            totalCellUnitArea = totalCellUnitArea + 4;
        } else if (MemoryGridCollectionViewCellSizeThreeByThree == cellSize) {
            num3x3Cells = num3x3Cells + 1;
            totalCellUnitArea = totalCellUnitArea + 9;
        } else {
            num1x1Cells = num1x1Cells + 1;
            totalCellUnitArea = totalCellUnitArea + 1;
        }
    }
    
    BOOL performedAction = YES;
    while (NO == [self validateOrderOnCellSizes:finalCellSizes] && YES == performedAction) {
        NSInteger index2x2Cell = NSNotFound;
        NSInteger indexSecond2x2Cell = NSNotFound;
        NSInteger index3x3Cell = NSNotFound;
        for (NSInteger i = 0; i < finalCellSizes.count; ++i) {
            MemoryGridCollectionViewCellSize cellSize = (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:i] integerValue];
            
            if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSize && NSNotFound == index2x2Cell) {
                index2x2Cell = i;
            } else if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSize && NSNotFound == indexSecond2x2Cell) {
                indexSecond2x2Cell = i;
            } else if (MemoryGridCollectionViewCellSizeThreeByThree == cellSize && NSNotFound == index3x3Cell) {
                index3x3Cell = i;
            }
        }
        
        // 2x2 cells must be spaced at least 2 cells away from each other and, if they are after a 3x3, 2 + 3i cells after the 3x3
        performedAction = NO;
        for (NSInteger i = 0; i < finalCellSizes.count && NO == performedAction; ++i) {
            // 1. Check if the top-most non-1x1 cell is low (in index) enough to support the non-1x1 cells below it.
            NSInteger trailingCellUnits = totalCellUnitArea % 3; // # of trailing cells at the bottom of the grid
            NSInteger lowestNon1x1Index = MIN(index2x2Cell, MIN(indexSecond2x2Cell, index3x3Cell));
            // The number of cells we need following the lowestNon1x1Index is: MAX(0, #trailingCellUnits (this one may be iffy) + #non1x1Cells besides the first one + 2*#2x2cells)
            NSInteger numNon1x1CellsBesidesThisOne = (NSNotFound == indexSecond2x2Cell ? (NSNotFound == index2x2Cell ? 0 : 1) : 2); // We MUST have a 3x3 cell, so this formula needs info on just the 2x2s
            NSInteger num2x2Cells = numNon1x1CellsBesidesThisOne; // heh, interesting this holds true
            NSInteger lowestValidNon1x1Index = MAX(0, trailingCellUnits + numNon1x1CellsBesidesThisOne + (2 * num2x2Cells));
            if (lowestNon1x1Index > lowestValidNon1x1Index) {
                // Remove and place this object at its lowest valid position
                id cellSize = [finalCellSizes objectAtIndex:lowestNon1x1Index];
                id memory = [finalMemories objectAtIndex:lowestNon1x1Index];
                [finalCellSizes removeObjectAtIndex:lowestNon1x1Index];
                [finalMemories removeObjectAtIndex:lowestNon1x1Index];
                [finalCellSizes insertObject:cellSize atIndex:lowestValidNon1x1Index];
                [finalMemories insertObject:memory atIndex:lowestValidNon1x1Index];
                performedAction = YES;
            }
        }
        
        // Start(ed) from the bottom (now we here)
        BOOL passed2x2Cell = NO;
        BOOL passedSecond2x2Cell = NO;
        BOOL passed3x3Cell = NO;
        NSInteger cellUnitArea = 0;
        for (NSInteger i = 0; i < finalCellSizes.count && NO == performedAction; ++i) {
            MemoryGridCollectionViewCellSize cellSize = (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:i] integerValue];
            NSInteger moduloPreviousCellArea = cellUnitArea % 3;
            
            if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSize) {
                MemoryGridCollectionViewCellSize secondPreviousCellSize = i > 1 ? (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:i-2] integerValue] : MemoryGridCollectionViewCellSizeUnknown;
                if ((0 == moduloPreviousCellArea) || (2 == moduloPreviousCellArea && MemoryGridCollectionViewCellSizeTwoByTwo != secondPreviousCellSize)) {
                    // We're good
                } else {
                    // We need to move this cell
                    // Check if the cell previous to this one was a 2x2
                    MemoryGridCollectionViewCellSize previousCellSize = i > 0 ? (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:i-1] integerValue] : MemoryGridCollectionViewCellSizeUnknown;
                    if (MemoryGridCollectionViewCellSizeTwoByTwo == previousCellSize || MemoryGridCollectionViewCellSizeTwoByTwo == secondPreviousCellSize) {
                        // We need to move up the next 1x1 cell
                        for (NSInteger j = i; j < finalCellSizes.count && NO == performedAction; ++j) {
                            MemoryGridCollectionViewCellSize thisCellSize = (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:j] integerValue];
                            if (MemoryGridCollectionViewCellSizeOneByOne == thisCellSize) {
                                id idCellSize = [finalCellSizes objectAtIndex:j];
                                id idMemory = [finalMemories objectAtIndex:j];
                                [finalCellSizes removeObjectAtIndex:j];
                                [finalMemories removeObjectAtIndex:j];
                                [finalCellSizes insertObject:idCellSize atIndex:i];
                                [finalMemories insertObject:idMemory atIndex:i];
                                performedAction = YES;
                            }
                        }
                        if (NO == performedAction) {
                            // Special case. No more 1x1s below to pull up. Let's grab the second previous 1x1 and place it just above the previous 1x1
                            NSInteger indexPrior1x1Cell = NSNotFound;
                            NSInteger indexSecondPrior1x1Cell = NSNotFound;
                            for (NSInteger j = i-1; j > 0 && NSNotFound == indexSecondPrior1x1Cell; --j) {
                                MemoryGridCollectionViewCellSize thisCellSize = (MemoryGridCollectionViewCellSize)[[finalCellSizes objectAtIndex:j] integerValue];
                                if (MemoryGridCollectionViewCellSizeOneByOne == thisCellSize) {
                                    if (NSNotFound == indexPrior1x1Cell) {
                                        indexPrior1x1Cell = j;
                                    } else if (NSNotFound == indexSecondPrior1x1Cell)
                                    {
                                        indexSecondPrior1x1Cell = j;
                                    }
                                }
                            }
                            
                            if (NSNotFound != indexPrior1x1Cell && NSNotFound != indexSecondPrior1x1Cell) {
                                id idCellSize = [finalCellSizes objectAtIndex:indexSecondPrior1x1Cell];
                                id idMemory = [finalMemories objectAtIndex:indexSecondPrior1x1Cell];
                                [finalCellSizes removeObjectAtIndex:indexSecondPrior1x1Cell];
                                [finalMemories removeObjectAtIndex:indexSecondPrior1x1Cell];
                                [finalCellSizes insertObject:idCellSize atIndex:indexPrior1x1Cell-1];
                                [finalMemories insertObject:idMemory atIndex:indexPrior1x1Cell-1];
                                performedAction = YES;
                            }
                            
                            if (NO == performedAction) {
                                NSLog("Failed to perform necessary action on cellSizes: %@", finalCellSizes.description);
                            }
                        }
                    } else {
                        [finalCellSizes exchangeObjectAtIndex:i withObjectAtIndex:i-1];
                        [finalMemories exchangeObjectAtIndex:i withObjectAtIndex:i-1];
                        performedAction = YES;
                    }
                }
                
                if (NO == passed2x2Cell) {
                    passed2x2Cell = YES;
                } else if (NO == passedSecond2x2Cell) {
                    passedSecond2x2Cell = YES;
                }
                cellUnitArea = cellUnitArea + 4;
            } else if (MemoryGridCollectionViewCellSizeThreeByThree == cellSize) {
                if (0 != moduloPreviousCellArea) {
                    [finalCellSizes exchangeObjectAtIndex:i withObjectAtIndex:i-1];
                    [finalMemories exchangeObjectAtIndex:i withObjectAtIndex:i-1];
                    performedAction = YES;
                }
                
                if (NO == passed3x3Cell) {
                    passed3x3Cell = YES;
                }
                cellUnitArea = cellUnitArea + 9;
            } else {
                cellUnitArea = cellUnitArea + 1;
            }
        }
        
        // If we haven't performed an action by now, let's make sure the grid bottom is flush, i.e. its area is divisible by three
        
        if (NO == performedAction && 0 != cellUnitArea % 3)
        {
            // We need to make some changes.
            // This section OVERRIDES CELL SIZE as well as order
            // There are a few cases whereby this case can happen:
            // 1. Single 1x1
            // 2. 2 1x1s
            // 3. Single 2x2
            // 4. 1 1x1, 1 2x2
            NSInteger modulo = cellUnitArea % 3;
            if (1 == modulo)
            {
                // Upgrade the last cell to a 3x3
                [finalCellSizes replaceObjectAtIndex:finalCellSizes.count - 1 withObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                performedAction = YES;
            }
            else if (2 == modulo)
            {
                // Upgrade the last two cells to a 3x3
                [finalCellSizes replaceObjectAtIndex:finalCellSizes.count - 1 withObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                [finalCellSizes replaceObjectAtIndex:finalCellSizes.count - 2 withObject:@(MemoryGridCollectionViewCellSizeThreeByThree)];
                performedAction = YES;
            }
        }
    }
    
    *cellSizesPtr = finalCellSizes;
    *memoriesPtr = finalMemories;
}

- (BOOL)validateOrderOnCellSizes:(NSArray *)cellSizes {
    BOOL bValidated = NO;
    if (3 >= cellSizes.count) {
        bValidated = YES;
    } else {
        NSInteger cellUnitArea = 0;
        BOOL foundValidationProblem = NO;
        for (NSInteger i = 0; i < cellSizes.count && NO == foundValidationProblem; ++i) {
            MemoryGridCollectionViewCellSize cellSize = (MemoryGridCollectionViewCellSize)[[cellSizes objectAtIndex:i] integerValue];
            NSInteger modulo = cellUnitArea % 3;
            if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSize) {
                // We need this 2x2 cell to be either a top-left or top-right cell
                // Top-left means that there is a modulo 0 for the cellUnitArea/3
                // Top-right means that there is a modulo 2 for the cellUnitArea/3
                MemoryGridCollectionViewCellSize secondPreviousCellSize = i >= 2 ? (MemoryGridCollectionViewCellSize)[[cellSizes objectAtIndex:i-2] integerValue] : MemoryGridCollectionViewCellSizeUnknown;
                if ((0 == modulo) || (2 == modulo && MemoryGridCollectionViewCellSizeTwoByTwo != secondPreviousCellSize)) {
                    // We're good
                } else {
                    foundValidationProblem = YES;
                }
                
                cellUnitArea = cellUnitArea + 4;
            } else if (MemoryGridCollectionViewCellSizeThreeByThree == cellSize) {
                // Here, we need a modulo of 0 for the cellUnitArea/3
                if (0 == modulo) {
                    // We're good
                } else {
                    foundValidationProblem = YES;
                }
                
                cellUnitArea = cellUnitArea + 9;
            } else {
                cellUnitArea = cellUnitArea + 1;
            }
        }
        
        // Finally, check if the grid is flush, i.e. its area is divisible by 3
        if (0 != cellUnitArea % 3)
        {
            foundValidationProblem = YES;
        }
        
        bValidated = !foundValidationProblem;
    }
    
    return bValidated;
}

@end

#pragma mark - SPCMemoryGridCollectionViewLayout

@interface SPCMemoryGridCollectionViewLayout()

@property (nonatomic, strong) NSDictionary *layoutInformation;

@property (nonatomic) CGFloat collectionViewWidth;
@property (nonatomic) NSInteger gridAreaInCellUnits;
@property (nonatomic) CGFloat gridHeight;

@end

@implementation SPCMemoryGridCollectionViewLayout

- (void)prepareLayout {
    // Get the the width for a single 1x1 cell
    self.collectionViewWidth = 0.0f;
    CGFloat cellUnitDim = 0.0f;
    if ([self.delegate respondsToSelector:@selector(collectionViewWidthUsingLayout:)]) {
        self.collectionViewWidth = [self.delegate collectionViewWidthUsingLayout:self];
        cellUnitDim = self.collectionViewWidth / 3.0f;
    }
    NSInteger gridAreaInCellUnits = 0;
    CGFloat gridHeight = 0.0f;
    
    NSMutableDictionary *layoutInformation = [NSMutableDictionary dictionary];
    NSMutableDictionary *cellInformation = [NSMutableDictionary dictionary];
    NSIndexPath *indexPath;
    MemoryGridCollectionViewCellSize cellSizePreviousCell = MemoryGridCollectionViewCellSizeUnknown;
    CGRect framePreviousCell = CGRectZero;
    MemoryGridCollectionViewCellSize cellSizeSecondPreviousCell = MemoryGridCollectionViewCellSizeUnknown;
    CGRect frameSecondPreviousCell = CGRectZero;
    
    // Go through all of the cells, top-down, in order to calculate their frame
    NSInteger numSections = [self.collectionView numberOfSections];
    for(NSInteger section = 0; section < numSections; section++) {
        NSInteger numItems = [self.collectionView numberOfItemsInSection:section];
        for(NSInteger item = 0; item < numItems; item++){
            indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
            MemoryGridCollectionViewCellSize cellSizeEnum = [self cellSizeForItemAtIndexPath:indexPath];
            
            // Local variables, to be adjusted
            CGSize cellSize = CGSizeMake(cellSizeEnum * cellUnitDim, cellSizeEnum * cellUnitDim);
            CGPoint cellOrigin = CGPointMake(CGRectGetMaxX(framePreviousCell), CGRectGetMinY(framePreviousCell));
            
            CGFloat insetX = 0.0f;
            CGFloat insetY = 0.0f;
            if (MemoryGridCollectionViewCellSizeThreeByThree == cellSizeEnum) {
                // This cell's origin should be on a new line and start at x = 0;
                cellOrigin = CGPointMake(0, CGRectGetMaxY(framePreviousCell));
//                insetX = 2.0f;
                
                gridAreaInCellUnits = gridAreaInCellUnits + 9;
            } else if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSizeEnum) {
                // This can be tricky. A 2x2 can be either on the left or the right of the 3x3 grid.
                // It will be on the right if the previous cell's MaxX is less than collectionViewWidth/2
                if (NO == CGRectEqualToRect(CGRectZero, framePreviousCell) && self.collectionViewWidth/2.0f > CGRectGetMaxX(framePreviousCell)) {
                    cellOrigin = CGPointMake(CGRectGetMaxX(frameSecondPreviousCell) + 2.0f, CGRectGetMinY(frameSecondPreviousCell)); // Since this means there are 2 1x1 cells on the left of the current item, the previous item's frame is a 1x1 at the bottom left of a 2rowx3column grid
//                    insetX = 2.0f;
                } else {
                    // This cell is at the left of the grid
                    cellOrigin = CGPointMake(0, CGRectGetMaxY(framePreviousCell));
                    cellSize.width = cellSize.width - 2.0f;
//                    insetX = 2.0f;
                }
                
                gridAreaInCellUnits = gridAreaInCellUnits + 4;
            } else if (MemoryGridCollectionViewCellSizeOneByOne == cellSizeEnum) {
                // This can get tricky as well. Possibilities (we could be calculating for ANY of the *s):
                // * * *    * x x   x x *
                // x x x    * x x   x x *
                // x x x    x x x   x x x
                
                MemoryGridCollectionViewCellSize cellSizeNextCellEnum = MemoryGridCollectionViewCellSizeUnknown;
                if (item + 1 < numItems) {
                    cellSizeNextCellEnum = [self cellSizeForItemAtIndexPath:[NSIndexPath indexPathForItem:item + 1 inSection:section]];
                }
                
                // It's a top-left cell if the previous cell's MaxX is > collectionViewWidth*3/4 and the second previous cell is NOT a 2x2 OR the previous cell is a 3x3
                if (CGRectEqualToRect(CGRectZero, framePreviousCell) || (self.collectionViewWidth*3.0/4.0f < CGRectGetMaxX(framePreviousCell) && (MemoryGridCollectionViewCellSizeTwoByTwo != cellSizeSecondPreviousCell || MemoryGridCollectionViewCellSizeThreeByThree == cellSizePreviousCell))) {
                    cellOrigin = CGPointMake(0, CGRectGetMaxY(framePreviousCell));
                    cellSize.width = cellSize.width - 2.0f;
//                    insetX = 2.0f;
                } else if (self.collectionViewWidth/2.0f > CGRectGetMaxX(framePreviousCell)) {
                    // This will be a middle 1x1 or below-a-1x1-and-to-the-left-of-a-2x2 cell
                    if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSizeNextCellEnum) {
                        cellOrigin = CGPointMake(0, CGRectGetMaxY(framePreviousCell));
                        cellSize.width = cellSize.width - 2.0f;
//                        insetX = 2.0f;
                        cellSize.height = cellSize.height - 2.0f;
                    } else {
                        cellOrigin = CGPointMake(self.collectionViewWidth/2.0f - cellUnitDim/2.0f, CGRectGetMinY(framePreviousCell));
                        cellSize.width = cellSize.width - 2.0f;
//                        insetX = 1.0f;
                    }
                } else if (self.collectionViewWidth*3.0/4.0f > CGRectGetMaxX(framePreviousCell)) {
                    // This is a top-right cell
                    if (MemoryGridCollectionViewCellSizeTwoByTwo == cellSizePreviousCell) {
                        cellOrigin = CGPointMake(CGRectGetMaxX(framePreviousCell) + 2.0f, CGRectGetMinY(framePreviousCell));
//                        cellSize.width = cellSize.width - 2.0f;
                    } else {
                        cellOrigin = CGPointMake(CGRectGetMaxX(framePreviousCell) + 2.0f, CGRectGetMinY(framePreviousCell));
//                        cellSize.width = cellSize.width - 2.0f;
                    }
                } else {
                    // This is a below-a-1x1-and-to-the-right-of-a-2x2 cell
                    cellOrigin = CGPointMake(CGRectGetMinX(framePreviousCell), CGRectGetMaxY(framePreviousCell) + 2.0f);
                    cellSize.height = cellSize.height - 2.0f;
//                    cellSize.width = cellSize.width - 2.0f;
                }
                
                gridAreaInCellUnits = gridAreaInCellUnits + 1;
            }
            
            attributes.indexPath = indexPath;
            
            CGFloat ySpacing = 0.0f == cellOrigin.x && 0.0f != cellOrigin.y ? 2.0f : 0.0f; // Add 2px at each new line
            
            CGRect finalFrame = CGRectMake(cellOrigin.x, cellOrigin.y + ySpacing, cellSize.width, cellSize.height);
            attributes.frame = CGRectInset(finalFrame, insetX, insetY);
            [cellInformation setObject:attributes forKey:indexPath];
            
            gridHeight = MAX(gridHeight, CGRectGetMaxY(attributes.frame));
            
            // Set variables for future reference
            frameSecondPreviousCell = framePreviousCell;
            framePreviousCell = attributes.frame;
            cellSizeSecondPreviousCell = cellSizePreviousCell;
            cellSizePreviousCell = cellSizeEnum;
        }
    }
    
    self.gridHeight = gridHeight;
    self.gridAreaInCellUnits = gridAreaInCellUnits;
    [layoutInformation setObject:cellInformation forKey:SPCMemoryGridCellIdentifier];
    self.layoutInformation = layoutInformation;
}

- (MemoryGridCollectionViewCellSize)cellSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    MemoryGridCollectionViewCellSize cellSize = MemoryGridCollectionViewCellSizeUnknown;
    if ([self.delegate respondsToSelector:@selector(cellSizeForItemAtIndexPath:usingLayout:)]) {
        cellSize = [self.delegate cellSizeForItemAtIndexPath:indexPath usingLayout:self];
    }
    
    return cellSize;
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionViewWidth, self.gridHeight + 2.0f);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *myAttributes = [NSMutableArray arrayWithCapacity:self.layoutInformation.count];
    for(NSString *key in self.layoutInformation){
        NSDictionary *attributesDict = [self.layoutInformation objectForKey:key];
        for(NSIndexPath *key in attributesDict){
            UICollectionViewLayoutAttributes *attributes =
            [attributesDict objectForKey:key];
            if(CGRectIntersectsRect(rect, attributes.frame)){
                [myAttributes addObject:attributes];
            }
        }
    }
    return myAttributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *memoryGridCellAttributes = [self.layoutInformation objectForKey:SPCMemoryGridCellIdentifier];
    UICollectionViewLayoutAttributes *attributes = [memoryGridCellAttributes objectForKey:indexPath];
    return attributes;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
}

@end