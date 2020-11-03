//
//  SPCCity.m
//  Spayce
//
//  Created by Christopher Taylor on 6/1/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCCity.h"
#import "TranslationUtils.h"
#import "SPCTerritory.h"

@implementation SPCCity


- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        _cityName = (NSString *)[TranslationUtils valueOrNil:attributes[@"city"]];
        _neighborhoodName = (NSString *)[TranslationUtils valueOrNil:attributes[@"neighborhood"]];
        _countryAbbr = (NSString *)[TranslationUtils valueOrNil:attributes[@"countryAbbr"]];
        _county = (NSString *)[TranslationUtils valueOrNil:attributes[@"county"]];
        _stateAbbr = (NSString *)[TranslationUtils valueOrNil:attributes[@"stateAbbr"]];
        
        _personalStarsInCity = [TranslationUtils integerValueFromDictionary:attributes withKey:@"personalStarsInCity"];
        
        _latitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"latitude"]];
        _longitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"longitude"]];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SPCCity *city = [[[self class] alloc] init];
    city.cityName = [self.cityName copyWithZone:zone];
    city.countryAbbr = [self.countryAbbr copyWithZone:zone];
    city.county = [self.county copyWithZone:zone];
    city.stateAbbr = [self.stateAbbr copyWithZone:zone];
    city.latitude = [self.latitude copyWithZone:zone];
    city.longitude = [self.longitude copyWithZone:zone];
    city.personalStarsInCity = self.personalStarsInCity;
    return city;
}

- (NSString *)countryFullName {
    return [SPCTerritory countryNameForCountryCode:_countryAbbr];
}

- (NSString *)stateFullName {
    return [SPCTerritory stateNameForStateCode:_stateAbbr countryCode:_countryAbbr];
}

- (NSString *)cityFullName {
    return [SPCTerritory fixCityName:_cityName stateCode:_stateAbbr countryCode:_countryAbbr];
}

@end
