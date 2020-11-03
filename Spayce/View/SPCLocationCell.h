//
//  SPCLocationCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 5/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCVenueTypes.h"
#import "NSString+SPCAdditions.h"
@class Venue;

extern const NSInteger spc_LOCATION_CELL_BADGE_CURRENT;
extern const NSInteger spc_LOCATION_CELL_BADGE_DEVICE;
extern const NSInteger spc_LOCATION_CELL_BADGE_DEVICE_SELECTED;
extern const NSInteger spc_LOCATION_CELL_BADGE_GOLD_STAR;
extern const NSInteger spc_LOCATION_CELL_BADGE_SILVER_STAR;
extern const NSInteger spc_LOCATION_CELL_BADGE_BRONZE_STAR;
extern const NSInteger spc_LOCATION_CELL_BADGE_FAVORITED;

@interface SPCLocationCell : UITableViewCell

@property (nonatomic, strong) Venue *venue;
@property (nonatomic, strong) UILabel *starsLabel;
@property (nonatomic, strong) UILabel *memoriesLabel;
@property (nonatomic, assign) BOOL hasSeparator;
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, strong) UILabel *distanceLabel;
@property (nonatomic, strong) NSArray *badgeViews;
@property (nonatomic, assign) NSInteger badgeCount;

// Top/Bottom gray padding for fuzzed locations
@property (strong, nonatomic) UIView *topGrayPadding;
@property (strong, nonatomic) UIView *bottomGrayPadding;


- (void)configureCellWithVenue:(Venue *)venue badges:(NSInteger)badges;
- (void)setBadges:(NSInteger)badges;
- (CGFloat)widthForStarsLabel;
- (CGFloat)widthForMemoriesLabel;
@end
