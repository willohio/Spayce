//
//  SPCNeighborhood.m
//  Spayce
//
//  Created by Howard Cantrell on 6/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNeighborhood.h"
#import "TranslationUtils.h"

@implementation SPCNeighborhood

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super initWithAttributes:attributes];
    if (self) {
        _personalStarsInNeighborhood = [TranslationUtils integerValueFromDictionary:attributes withKey:@"personalStarsInNeighborhood"];
        _neighborhood = (NSString *)[TranslationUtils valueOrNil:attributes[@"neighborhood"]];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SPCNeighborhood *neighborhood = [super copyWithZone:zone];
    neighborhood.personalStarsInNeighborhood = self.personalStarsInNeighborhood;
    neighborhood.neighborhood = [self.neighborhood copyWithZone:zone];
    return neighborhood;
}

@end
