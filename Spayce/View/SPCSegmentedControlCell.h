//
//  SPCSegmentedControlCell.h
//  Spayce
//
//  Created by Arria P. Owlia on 12/13/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// Segmented Control
#import "HMSegmentedControl.h"

@interface SPCSegmentedControlCell : UITableViewCell

@property (nonatomic, strong) HMSegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray *segmentItems;

- (void)configureWithTitles:(NSArray *)titles;

@end
