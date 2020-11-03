//
//  SPCTerritoryCell.h
//  Spayce
//
//  Created by Jake Rosin on 11/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCCity;
@class SPCNeighborhood;

@interface SPCTerritoryCell : UITableViewCell

- (void)configureWithCity:(SPCCity *)city cityNumber:(NSInteger)cityNumber expanded:(BOOL)expanded;
- (void)configureWithNeighborhood:(SPCNeighborhood *)neighborhood neighborhoodNumber:(NSInteger)neighborhoodNumber expanded:(BOOL)expanded;

@end
