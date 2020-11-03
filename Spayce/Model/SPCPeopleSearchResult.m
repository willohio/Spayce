//
//  SPCPeopleSearchResult.m
//  Spayce
//
//  Created by Christopher Taylor on 11/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCPeopleSearchResult.h"

@implementation SPCPeopleSearchResult

- (id)initWithPerson:(Person *)person {
    self = [super init];
    if (self) {
        self.person = person;
        
        if (person.followingStatus == FollowingStatusFollowing) {
            self.searchResultType = SearchResultFriend;
        }
        else if ([person isCeleb]) {
            self.searchResultType = SearchResultCeleb;
        }
        else {
            self.searchResultType = SearchResultStranger;
        }
    }
    return self;
    
}
- (id)initWithCity:(SPCCity *)city {
    self = [super init];
    if (self) {
        self.city = city;
        self.searchResultType = SearchResultCity;
    }
    return self;
}

- (id)initWithNeighborhood:(SPCNeighborhood *)neighborhood {
    self = [super init];
    if (self) {
        self.neighborhood = neighborhood;
        self.searchResultType = SearchResultNeighborhood;
        
    }
    return self;
}

@end
