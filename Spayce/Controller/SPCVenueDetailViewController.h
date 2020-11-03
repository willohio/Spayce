//
//  SPCVenueDetailViewController.h
//  Spayce
//
//  Created by Pavel Dusatko on 9/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Memory.h"
#import "SPCBaseDataSource.h"
#import "SPCVenueSegmentedControlCell.h"

@class Venue;

@protocol SPCVenueDetailViewControllerDelegate

-(void) spcVenueDetailViewControllerDidFinish:(UIViewController *)viewController;

@end

@interface SPCVenueDetailViewController : UIViewController <SPCDataSourceDelegate, SPCVenueSegmentedControllCellDelegate>

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, weak) NSObject<SPCVenueDetailViewControllerDelegate> *delegate;

- (void)jumpToPopular;
- (void)jumpToMem:(Memory *)m;

- (void)fetchMemories;

@end
