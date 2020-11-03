//
//  SPCFeaturedPlaceCell.h
//  Spayce
//
//  Created by Jake Rosin on 2/27/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Memory;
@class Venue;

@interface SPCFeaturedPlaceCell : UICollectionViewCell

@property (nonatomic, strong) Venue * venue;

@property (nonatomic, strong) UIColor *color;

-(void)configureWithFeaturedVenue:(Venue *)venue;
-(void)configureWithSuggestedVenue:(Venue *)venue;

@end
