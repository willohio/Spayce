//
//  SPCTerritory.h
//  Spayce
//
//  Created by Jake Rosin on 4/1/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCTerritory : NSObject

+ (NSString *)countryNameForCountryCode:(NSString *)countryCode;
+ (NSString *)stateNameForStateCode:(NSString *)stateCode countryCode:(NSString *)countryCode;
+ (NSString *)fixCityName:(NSString *)cityName stateCode:(NSString *)stateCode countryCode:(NSString *)countryCode;

@end
