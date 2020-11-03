//
//  SPCRisingStarHeaderCell.h
//  Spayce
//
//  Created by Jake Rosin on 4/1/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SPCNeighborhood;

@interface SPCRisingStarHeaderCell : UICollectionViewCell

@property (nonatomic, readonly) SPCNeighborhood *neighborhood;
@property (nonatomic, readonly) BOOL risingStars;
@property (nonatomic, assign) CGPoint textCenterOffset;
@property (nonatomic, assign) CGFloat bottomOverreach;

- (void)configureWithNeighborhood:(SPCNeighborhood *)neighborhood risingStars:(BOOL)risingStars;

@end
