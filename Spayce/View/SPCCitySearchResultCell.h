//
//  SPCCitySearchResultCell.h
//  Spayce
//
//  Created by Christopher Taylor on 6/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCCity.h"

@interface SPCCitySearchResultCell : UITableViewCell

@property (nonatomic, strong) UILabel *placeNameLabel;
@property (nonatomic, strong) UILabel *placeNameSubtitle;

-(void)configureWithCity:(SPCCity *)city;
-(void)updateForNeighborhood:(SPCCity *)city;

@end
