//
//  ProfileDetail.h
//  Spayce
//
//  Created by Pavel Dusatko on 9/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Asset;

@interface ProfileDetail : NSObject <NSCopying>

@property (nonatomic, assign) NSInteger profileId;
@property (nonatomic, strong) NSString *handle;
@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, strong) Asset *imageAsset;
@property (nonatomic, strong) Asset *bannerAsset;
@property (nonatomic, strong) Asset *anonImageAsset;

@property (nonatomic, strong) NSArray *adminActions;

// TODO: Unused property
@property (nonatomic, assign) NSInteger totalFriendCount;
@property (nonatomic, assign) NSInteger starCount;
// TODO: Unused property
@property (nonatomic, assign) NSInteger memCount;
@property (nonatomic, assign) NSInteger mutualFriendsCount;
@property (nonatomic, strong) NSArray *mutualFriendProfiles;
@property (nonatomic, assign) NSInteger friendsCount;
@property (nonatomic, assign) NSInteger followersCount;
@property (nonatomic, assign) NSInteger followingCount;
@property (nonatomic, assign) NSInteger blockedCount;
@property (nonatomic, assign) BOOL isCeleb;
@property (nonatomic, assign) BOOL profileLocked;

@property (nonatomic, strong) NSArray *photosAssets;
@property (nonatomic, strong) NSString *maritalStatus;
@property (nonatomic, strong) NSDate *birthday;
@property (nonatomic, strong) NSString *gender;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic, strong) NSString *aboutMe;
@property (nonatomic, assign) NSInteger followingStatus;        // Are we following this user?
@property (nonatomic, assign) NSInteger followerStatus;         // Is this user a follower of us?
@property (nonatomic, strong) NSArray *affiliatedCities;
@property (nonatomic, strong) NSArray *affiliatedNeighborhoods;
@property (nonatomic, strong) UIImage *profileImg;

- (id)initWithAttributes:(NSDictionary *)attributes;
- (void)updateWithAttributes:(NSDictionary *)attributes;
- (void)updateWithFriendCount:(int)totalFriends;

- (NSInteger)mutualFriendsCountExcludingSpayceProfile;

+ (NSArray *)genderList;

- (NSString *)displayName;

- (NSString *)genderEnumForString:(NSString *)string;

@end
