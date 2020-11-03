//
//  SPCVenueDetailHeaderView.h
//  Spayce
//
//  Created by Pavel Dusatko on 9/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Venue;

@interface SPCVenueDetailHeaderView : UIView

@property (nonatomic, strong) UIView *venueMapView;
@property (nonatomic, strong) UIImageView *venueImageView;
@property (nonatomic, strong) UILabel *distanceLabel;

- (instancetype)initWithFrame:(CGRect)frame venue:(Venue *)venue;

@end
