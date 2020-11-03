//
//  SPCTerritoryFavoritedVenueCell.h
//  Spayce
//
//  Created by Jake Rosin on 11/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Venue;
@class Memory;

extern NSString * SPCTerritoryFavoritedVenueTappedNotification;

@interface SPCTerritoryFavoritedVenueCellVenueTapped : NSObject

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) Memory *memoryDisplayed;
@property (nonatomic, strong) UIImage *imageDisplayed;
@property (nonatomic, assign) CGRect gridRect;

@end

@interface SPCTerritoryFavoritedVenueCell : UITableViewCell

- (instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier;

- (void)configureWithVenues:(NSArray *)venues;

@end
