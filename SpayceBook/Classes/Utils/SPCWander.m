//
//  SPCWander.m
//  Spayce
//
//  Created by Jake Rosin on 7/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCWander.h"
#import <tgmath.h>

@interface SPCWander()

@property (nonatomic, assign) CLLocationCoordinate2D location;
@property (nonatomic, assign) NSTimeInterval locationTime;

@property (nonatomic, assign) CGFloat bearing;

@property (nonatomic, readonly) CGFloat randomFloat;
@property (nonatomic, readonly) CGFloat randomBearing;

@end

@implementation SPCWander

-(instancetype) initWithLocation:(CLLocationCoordinate2D)location {
    self = [self initWithLocation:location realLocation:location];
    return self;
}

-(instancetype) initWithLocation:(CLLocationCoordinate2D)location realLocation:(CLLocationCoordinate2D)realLocation {
    self = [super init];
    if (self) {
        _location = location;
        _realLocation = realLocation;
        _locationTime = [[NSDate date] timeIntervalSince1970];
        
        _bearing = self.randomBearing;
        
        _metersPerSecond = 2.f; // 0.8f;
        _headingDeltaRadiansPerSecond = M_PI * (1.0 / 20.0);
        _headingResetsPerSecond = 0.015;
    }
    return self;
}




-(void)setRealLocation:(CLLocationCoordinate2D)realLocation {
    // Sets the real location.  Determine a distance and bearing
    // adjustment from the previous real location, and apply that
    // same adjustment to _location.
    CGFloat distance = [self distanceBetweenCoordinate:_realLocation andCoordinate:realLocation];
    CGFloat bearing = [self bearingForDirectionFromCoordinate:_realLocation toCoordinate:realLocation];
    
    CLLocationCoordinate2D location = [self locationAtDistance:distance andBearing:bearing fromLocation:_location];
    
    //NSLog(@"Adjusted to %f, %f, with bearing %f: %f away last position", location.latitude, location.longitude, _bearing, [self distanceBetweenCoordinate:location andCoordinate:_location]);
    
    _location = location;
    _realLocation = realLocation;
}

-(CGFloat)bearingForDirectionFromCoordinate:(CLLocationCoordinate2D)fromLoc toCoordinate:(CLLocationCoordinate2D)toLoc {
    CGFloat fLat = fromLoc.latitude * M_PI / 180.0;
    CGFloat fLng = fromLoc.longitude * M_PI / 180.0;
    CGFloat tLat = toLoc.latitude * M_PI / 180.0;
    CGFloat tLng = toLoc.longitude * M_PI / 180.0;
    
    CGFloat dLng = tLng - fLng;
    
    return atan2(sin(dLng)*cos(tLat), cos(fLat)*sin(tLat)-sin(fLat)*cos(tLat)*cos(dLng));
}


-(CLLocationCoordinate2D) location {
    // Adjust by a whole number of seconds
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval timeDelta = currentTime - self.locationTime;
    NSInteger secondsPassed = floor(timeDelta);
    if (secondsPassed > 10000) {
        secondsPassed = 10000;
    }
    for (int i = 0; i < secondsPassed; i++) {
        // adjust bearing
        if (self.randomFloat < self.headingResetsPerSecond) {
            // reset
            _bearing = self.randomBearing;
        } else {
            // adjust slightly
            _bearing = [self adjustBearing:_bearing];
        }
        
        // step
        CGFloat distance = 2.0 * self.metersPerSecond * self.randomFloat;
        _location = [self locationAtDistance:distance andBearing:_bearing fromLocation:_location];
    }
    
    //NSLog(@"After %d at %f / %f: Wandered to %f, %f, with bearing %f: %f away last position", secondsPassed, _locationTime, currentTime, _location.latitude, _location.longitude, _bearing, [self distanceBetweenCoordinate:location andCoordinate:_location]);
    
    _locationTime += secondsPassed;
    return _location;
}

-(CLLocationCoordinate2D) locationAtDistance:(CGFloat)distance andBearing:(CGFloat)bearing fromLocation:(CLLocationCoordinate2D)location {
    // This calculation is taken wholesale from http://www.movable-type.co.uk/scripts/latlong.html
    // Taken from the "Destination point given distance and bearing from start point" section
    const int R = 6371000;
    double dOverR = distance/R;
    // Bearing is in radians: Lat and lon need to be radians, too
    double currentLat = location.latitude * M_PI / 180;
    double currentLon = location.longitude * M_PI / 180;
    double newLat = asin(sin(currentLat)*cos(dOverR) + cos(currentLat)*sin(dOverR)*cos(bearing));
    double newLon = currentLon + atan2(sin(bearing)*sin(dOverR)*cos(currentLat), cos(dOverR) - sin(currentLat)*sin(newLat));
    
    // Convert back to degrees for the CLLocationCoordinate2D
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(newLat * 180/M_PI, newLon * 180/M_PI);
    return coord;
}

-(CGFloat) adjustBearing:(CGFloat)bearing {
    CGFloat magnitude = 2.0 * self.headingDeltaRadiansPerSecond * self.randomFloat;
    CGFloat newBearing = bearing + ((self.randomFloat >= 0.5) ? magnitude : -magnitude);
    while (newBearing < 0) {
        newBearing += M_PI * 2;
    }
    while (newBearing > M_PI * 2) {
        newBearing -= M_PI * 2;
    }
    return newBearing;
}

-(CGFloat) randomFloat {
    return (CGFloat)rand() / RAND_MAX;
}

-(CGFloat) randomBearing {
    return 2 * M_PI * (self.randomFloat);
}

-(CGFloat) distanceBetweenCoordinate:(CLLocationCoordinate2D)coord1 andCoordinate:(CLLocationCoordinate2D)coord2 {
    CLLocation * location1 = [[CLLocation alloc] initWithLatitude:coord1.latitude longitude:coord1.longitude];
    CLLocation * location2 = [[CLLocation alloc] initWithLatitude:coord2.latitude longitude:coord2.longitude];
    
    return [location1 distanceFromLocation:location2];
}

@end
