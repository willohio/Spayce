//
//  SPCMemoryGridCell.h
//  Spayce
//
//  Created by Arria P. Owlia on 3/20/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *SPCMemoryGridCellIdentifier;

@class Memory;

typedef enum MemoryGridCellQuality {
    MemoryGridCellQualityUnknown,
    MemoryGridCellQualityLow,
    MemoryGridCellQualityMedium,
    MemoryGridCellQualityHigh,
} MemoryGridCellQuality;

@interface SPCMemoryGridCell : UICollectionViewCell

@property (nonatomic, weak) Memory *memory;

// Configuration
- (void)configureWithMemory:(Memory *)memory andQuality:(MemoryGridCellQuality)quality;

// Actions
- (void)playIfVideo;
- (void)pauseIfVideo;

@end
