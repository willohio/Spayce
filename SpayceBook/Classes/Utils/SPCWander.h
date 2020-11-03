//
//  SPCWander.h
//  Spayce
//
//  Created by Jake Rosin on 7/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <CoreLocation/CoreLocation.h>

@interface SPCWander : NSObject

-(instancetype) initWithLocation:(CLLocationCoordinate2D)location;
-(instancetype) initWithLocation:(CLLocationCoordinate2D)location realLocation:(CLLocationCoordinate2D)realLocation;

@property (nonatomic, assign) CGFloat metersPerSecond;
@property (nonatomic, assign) CGFloat headingDeltaRadiansPerSecond;
@property (nonatomic, assign) CGFloat headingResetsPerSecond;

@property (nonatomic, assign) CLLocationCoordinate2D realLocation;
@property (nonatomic, readonly) CLLocationCoordinate2D location;

@end
