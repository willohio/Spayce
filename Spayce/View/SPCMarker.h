//
//  SPCMarker.h
//  Spayce
//
//  Created by Christopher Taylor on 9/29/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>

@interface SPCMarker : GMSMarker

@property (nonatomic, strong) UIImage *selectedIcon;
@property (nonatomic, strong) UIImage *nonSelectedIcon;
@property (nonatomic, strong) UIImage *exploreIcon;
@property (nonatomic, assign) BOOL isFadedForFilters;
@property (nonatomic, assign) BOOL isFadedForFeature;
@property (nonatomic, assign) CGFloat distanceFromBasePin;
@property (nonatomic, assign) NSInteger markerIndex;
@end
