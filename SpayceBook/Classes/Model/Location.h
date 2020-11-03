//
//  Location.h
//  Spayce
//
//  Created by Pavel Dušátko on 10/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@interface Location : NSObject

@property (strong, nonatomic) NSNumber *latitude;
@property (strong, nonatomic) NSNumber *longitude;
@property (assign, nonatomic) NSInteger distance;

- (id)initWithAttributes:(NSDictionary *)attributes;

- (CLLocation *)location;

@end
