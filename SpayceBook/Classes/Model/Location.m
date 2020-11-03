//
//  Location.m
//  Spayce
//
//  Created by Pavel Dušátko on 10/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Location.h"
#import "TranslationUtils.h"

@implementation Location

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        _latitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"latitude"]];
        _longitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"longitude"]];
        _distance = [TranslationUtils integerValueFromDictionary:attributes withKey:@"distance"];
    }
    return self;
}

#pragma mark - Accessors

- (CLLocation *)location
{
    if (self.latitude && self.longitude) {
        return [[CLLocation alloc] initWithLatitude:[self.latitude doubleValue]
                                          longitude:[self.longitude doubleValue]];
    } else {
        return nil;
    }
}

@end
