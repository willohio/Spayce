//
//  SPCProfileSegmentedControlCell.h
//  Spayce
//
//  Created by Arria P. Owlia on 3/19/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Enums.h"

extern NSString *SPCProfileSegmentedControlCellIdentifier;

@class SPCProfileSegmentedControlCell;
@protocol SPCProfileSegmentedControllCellDelegate <NSObject>

- (void)tappedMemoryCellDisplayType:(MemoryCellDisplayType)type onProfileSegmentedControl:(SPCProfileSegmentedControlCell *)profileSegmentedControl;

@end

@interface SPCProfileSegmentedControlCell : UITableViewCell

@property (nonatomic) MemoryCellDisplayType memoryCellDisplayType;
@property (weak, nonatomic) id<SPCProfileSegmentedControllCellDelegate> delegate;

- (void)configureWithNumberOfMemories:(NSInteger)numberOfMemories;

@end
