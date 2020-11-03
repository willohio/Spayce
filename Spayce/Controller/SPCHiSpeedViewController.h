//
//  SPCHiSpeedViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 9/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCHighSpeedMemCell.h"
#import "Memory.h"
#import "Venue.h"

@protocol SPCHiSpeedViewControllerDelegate <NSObject>

@optional
- (void)showCommentsForHighSpeedMemory:(Memory *)memory;
- (void)showFeedForHighSpeedVenue:(Venue *)venue;
@end

@interface SPCHiSpeedViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SPCHighSpeedMemCellDelegate >

@property (nonatomic, strong) UILabel *mapTitle;
@property (nonatomic, strong) NSArray *venues;
@property (nonatomic, strong) NSArray *mems;
@property (nonatomic, assign) BOOL neighborhoodExists;
@property (nonatomic, weak) id <SPCHiSpeedViewControllerDelegate> delegate;

-(void)reloadData;

@end
