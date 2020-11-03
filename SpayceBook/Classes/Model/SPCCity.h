//
//  SPCCity.h
//  Spayce
//
//  Created by Christopher Taylor on 6/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCCity : NSObject <NSCopying>

@property (strong, nonatomic) NSString *cityName;
@property (strong, nonatomic) NSString *countryAbbr;
@property (strong, nonatomic) NSString *county;
@property (strong, nonatomic) NSString *stateAbbr;
@property (assign, nonatomic) NSInteger personalStarsInCity;
@property (strong, nonatomic) NSString *neighborhoodName;

@property (readonly, nonatomic) NSString *countryFullName;
@property (readonly, nonatomic) NSString *stateFullName;
@property (readonly, nonatomic) NSString *cityFullName;

@property (strong, nonatomic) NSNumber *latitude;
@property (strong, nonatomic) NSNumber *longitude;

- (id)initWithAttributes:(NSDictionary *)attributes;

@end
