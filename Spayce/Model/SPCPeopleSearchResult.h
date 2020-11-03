//
//  SPCPeopleSearchResult.h
//  Spayce
//
//  Created by Christopher Taylor on 11/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"
#import "SPCCity.h"
#import "SPCNeighborhood.h"

typedef NS_ENUM(NSInteger, resultType) {
    SearchResultFriend,
    SearchResultCeleb,
    SearchResultStranger,
    SearchResultCity,
    SearchResultNeighborhood
};

@interface SPCPeopleSearchResult : NSObject
@property (nonatomic,strong) Person *person;
@property (nonatomic,strong) SPCCity *city;
@property (nonatomic,strong) SPCNeighborhood *neighborhood;
@property (nonatomic, assign) NSInteger searchResultType;

// Custom initializer
- (id)initWithPerson:(Person *)person;
- (id)initWithCity:(SPCCity *)city;
- (id)initWithNeighborhood:(SPCNeighborhood *)neighborhood;



@end
