//
//  SPCVenueSegmentedControlCell.h
//  Spayce
//
//  Created by Jake Rosin on 4/9/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Enums.h"

extern NSString *SPCVenueSegmentedControlCellIdentifier;

@class SPCVenueSegmentedControlCell;
@protocol SPCVenueSegmentedControllCellDelegate <NSObject>

- (void)tappedMemoryCellDisplayType:(MemoryCellDisplayType)type onVenueSegmentedControl:(SPCVenueSegmentedControlCell *)venueSegmentedControl;

@end

@interface SPCVenueSegmentedControlCell : UITableViewCell

@property (nonatomic) MemoryCellDisplayType memoryCellDisplayType;
@property (weak, nonatomic) id<SPCVenueSegmentedControllCellDelegate> delegate;

- (void)configureWithNumberOfMemories:(NSInteger)numberOfMemories;

@end