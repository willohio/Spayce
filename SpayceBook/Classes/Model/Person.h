//
//  Person.h
//  Spayce
//
//  Created by Pavel Dušátko on 12/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Asset;
@class SPCNeighborhood;

extern CGFloat kMAX_STARS;

@interface Person : NSObject <NSCoding>

@property (nonatomic, assign) NSInteger recordID;
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) NSString *handle;
@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, strong) Asset *imageAsset;

@property (nonatomic, strong) NSDate *dateBlocked;
@property (nonatomic, assign) NSInteger mutualFriendsCount;
@property (nonatomic, assign) NSInteger starCount;
@property (nonatomic, assign) NSInteger rankedStarCount;
@property (nonatomic, assign) BOOL isCeleb;
@property (nonatomic, assign) BOOL isHandleOnly;
@property (nonatomic, strong) NSString *topCity;
@property (nonatomic, strong) NSString *topNeighborhood;
@property (nonatomic, assign) NSInteger followingStatus;        // Are we following this user?
@property (nonatomic, assign) NSInteger followerStatus;         // Is this user a follower of us?

@property (nonatomic, strong) NSString *profilePhotoAssetID;
@property (nonatomic, strong) NSString *profilePhotoAssetInfo;
@property (nonatomic, assign) BOOL friendRequestHasBeenViewed;

@property (nonatomic, strong) SPCNeighborhood *risingStarTerritory;

// Custom initializer
- (id)initWithAttributes:(NSDictionary *)attributes;

- (NSString *)displayName;
- (NSString *)displayStarCount;

@end
