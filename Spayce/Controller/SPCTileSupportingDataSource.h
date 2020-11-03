//
//  SPCTileSupportingDataSource.h
//  Spayce
//
//  Created by Jake Rosin on 4/8/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCBaseDataSource.h"
#import "SPCMemoryGridCollectionView.h"
#import "Enums.h"

@interface SPCTileSupportingDataSource : SPCBaseDataSource

@property (nonatomic) CGFloat tableViewWidth;
@property (nonatomic, weak) SPCMemoryGridCollectionView *memoryGridCollectionView;
@property (nonatomic, assign) MemoryCellDisplayType memoryCellDisplayType;


@end
