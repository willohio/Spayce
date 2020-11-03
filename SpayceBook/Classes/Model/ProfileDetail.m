//
//  ProfileDetail.m
//  Spayce
//
//  Created by Pavel Dusatko on 9/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "ProfileDetail.h"

// Model
#import "Asset.h"
#import "Person.h"
#import "SPCCity.h"
#import "SPCNeighborhood.h"

// Utilities
#import "TranslationUtils.h"
#import "UIImageView+WebCache.h"
#import "APIUtils.h"

@implementation ProfileDetail

- (id)copyWithZone:(NSZone *)zone {
    ProfileDetail *profileDetail = [[self class] allocWithZone:zone];
    profileDetail.firstname = [self.firstname copyWithZone:zone];
    profileDetail.imageAsset = self.imageAsset;
    profileDetail.photosAssets = [self.photosAssets copyWithZone:zone];
    profileDetail.maritalStatus = [self.maritalStatus copyWithZone:zone];
    profileDetail.gender = [self.gender copyWithZone:zone];
    profileDetail.statusMessage = [self.statusMessage copyWithZone:zone];
    profileDetail.aboutMe = [self.aboutMe copyWithZone:zone];
    profileDetail.affiliatedCities = [self.affiliatedCities copyWithZone:zone];
    profileDetail.affiliatedNeighborhoods = [self.affiliatedNeighborhoods copyWithZone:zone];
    profileDetail.profileImg = self.profileImg;
    
    return profileDetail;
}

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        _profileId = [TranslationUtils integerValueFromDictionary:attributes withKey:@"userId"];
        _isCeleb =   [TranslationUtils booleanValueFromDictionary:attributes withKey:@"isCeleb"];
        _handle = (NSString *)[TranslationUtils valueOrNil:attributes[@"handle"]];
        _firstname = (NSString *)[TranslationUtils valueOrNil:attributes[@"firstName"]];
        _lastname = (NSString *)[TranslationUtils valueOrNil:attributes[@"lastName"]];
        
        _adminActions = (NSArray *)[TranslationUtils valueOrNil:attributes[@"adminActions"]];
        
        _imageAsset = [Asset assetFromDictionary:attributes withAssetKey:@"profilePhotoAssetInfo" assetIdKey:@"profilePhotoAssetId"];
        _bannerAsset = [Asset assetFromDictionary:attributes withAssetKey:@"profileBannerAssetInfo" assetIdKey:@"profileBannerAssetId"];
        _totalFriendCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"totalFriendCount"];
        _starCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"starCount"];
        _memCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"totalPublicMemoriesCount"];
        _mutualFriendsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"mutualFriendsCount"];
        _friendsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"friendsCount"];
        _followersCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"followersCount"];
        _followingCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"followingCount"];
        _blockedCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"blockedCount"];
        _profileLocked =   [TranslationUtils booleanValueFromDictionary:attributes withKey:@"profileLocked"];
        
        _photosAssets = [Asset assetArrayFromDictionary:attributes withAssetsKey:@"photosAssetInfo" assetIdsKey:@"photosAssetIds"];
        _maritalStatus = (NSString *)[TranslationUtils valueOrNil:attributes[@"maritalStatus"]];
        _gender = (NSString *)[TranslationUtils valueOrNil:attributes[@"gender"]];
        _statusMessage = (NSString *)[TranslationUtils valueOrNil:attributes[@"statusMessage"]];
        _aboutMe = (NSString *)[TranslationUtils valueOrNil:attributes[@"aboutMe"]];
        _followingStatus = [self followingStatusFromString:(NSString *)[TranslationUtils valueOrNil:attributes[@"followingStatus"]]];
        _followerStatus = [self followingStatusFromString:(NSString *)[TranslationUtils valueOrNil:attributes[@"followerStatus"]]];
        
        NSMutableArray *mutualFriendProfiles = [NSMutableArray array];
        NSArray *mutualFriendProfilesDicts = (NSArray *)[TranslationUtils valueOrNil:attributes[@"mutualFriendProfiles"]];
        for (NSDictionary *mutualFriendProfile in mutualFriendProfilesDicts) {
            [mutualFriendProfiles addObject:[[Person alloc] initWithAttributes:mutualFriendProfile]];
        }
        _mutualFriendProfiles = mutualFriendProfiles;
        
        NSMutableArray *affiliatedCities = [NSMutableArray array];
        NSArray *affiliatedCitiesDicts = (NSArray *)[TranslationUtils valueOrNil:attributes[@"affiliatedCities"]];
        for (NSDictionary *affiliatedCitiesDict in affiliatedCitiesDicts) {
            [affiliatedCities addObject:[[SPCCity alloc] initWithAttributes:affiliatedCitiesDict]];
        }
        _affiliatedCities = affiliatedCities;
        
        NSMutableArray *affiliatedNeighborhoods = [NSMutableArray array];
        NSArray *affiliatedNeighborhoodsDicts = (NSArray *)[TranslationUtils valueOrNil:attributes[@"affiliatedNeighborhoods"]];
        for (NSDictionary *affiliatedNeighborhoodsDict in affiliatedNeighborhoodsDicts) {
            
            SPCNeighborhood *neighborhood = [[SPCNeighborhood alloc] initWithAttributes:affiliatedNeighborhoodsDict];
            
            if (neighborhood.neighborhoodName.length > 0) {
                [affiliatedNeighborhoods addObject:neighborhood];
            }
        }
        _affiliatedNeighborhoods = affiliatedNeighborhoods;
        
        [self initializeBirthdayWithAttributes:attributes];
    }
    return self;
}

- (void)updateWithAttributes:(NSDictionary *)attributes
{
    NSString *firstname = (NSString *)[TranslationUtils valueOrNil:attributes[@"firstName"]];
    if (firstname) {
        self.firstname = firstname;
    }
    NSString *handle = (NSString *)[TranslationUtils valueOrNil:attributes[@"handle"]];
    if (handle) {
        self.handle = handle;
    }
    
    Asset *imageAsset = [Asset assetFromDictionary:attributes withAssetKey:@"profilePhotoAssetInfo" assetIdKey:@"profilePhotoAssetId"];
    if (imageAsset != nil) {
        self.imageAsset = imageAsset;
    }
    
    NSArray *photosAssets = [Asset assetArrayFromDictionary:attributes withAssetsKey:@"photosAssetInfo" assetIdsKey:@"photosAssetIds"];
    if (photosAssets) {
        self.photosAssets = photosAssets;
    } else {
        self.photosAssets = nil;
    }
    
    NSString *maritalStatus = (NSString *)[TranslationUtils valueOrNil:attributes[@"maritalStatus"]];
    if (maritalStatus) {
        self.maritalStatus = maritalStatus;
    }
    
    NSString *gender = (NSString *)[TranslationUtils valueOrNil:attributes[@"gender"]];
    if (gender) {
        self.gender = gender;
    }
    
    NSString *statusMessage = (NSString *)[TranslationUtils valueOrNil:attributes[@"statusMessage"]];
    if (statusMessage) {
        self.statusMessage = statusMessage;
    }
    
    NSString *aboutMe = (NSString *)[TranslationUtils valueOrNil:attributes[@"aboutMe"]];
    if (aboutMe) {
        self.aboutMe = aboutMe;
    }
    
    [self initializeBirthdayWithAttributes:attributes];
}

#pragma mark - Private

- (void)initializeBirthdayWithAttributes:(NSDictionary *)attributes
{
    NSNumber *birthday = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"birthDay"]];
    
    if (birthday) {
        NSTimeInterval seconds = [birthday doubleValue];
        NSTimeInterval miliseconds = seconds/1000;
        _birthday = [NSDate dateWithTimeIntervalSince1970:miliseconds];
    }
}


- (NSInteger)followingStatusFromString:(NSString *)statusString {
    if ([statusString isEqualToString:@"NOT_FOLLOWING"]) {
        return FollowingStatusNotFollowing;
    }
    else if ([statusString isEqualToString:@"REQUESTED"]) {
        return FollowingStatusRequested;
    }
    else if ([statusString isEqualToString:@"FOLLOWING"]) {
        return FollowingStatusFollowing;
    }
    else if ([statusString isEqualToString:@"BLOCKED"]) {
        return FollowingStatusBlocked;
    }
    else {
        return FollowingStatusUnknown;
    }
}

                    

+ (NSArray *)genderList {
    return @[
             NSLocalizedString(@"Male", nil),
             NSLocalizedString(@"Female", nil)
             ];
}

- (NSString *)displayName {
    NSMutableString *mutableString = [NSMutableString string];
    
    if (self.firstname.length > 0) {
        [mutableString appendString:self.firstname];
    }
    if (self.lastname.length > 0) {
        if (mutableString.length > 0) {
            [mutableString appendString:@" "];
        }
        [mutableString appendString:self.lastname];
    }
    
    if (mutableString.length > 0) {
        return [NSString stringWithString:mutableString];
    }
    else {
        return NSLocalizedString(@"Spayce Member", nil);
    }
}

- (NSString *)genderEnumForString:(NSString *)string
{
    NSArray *list = [ProfileDetail genderList];
    
    if ([string isEqualToString:list[0]]) {
        return @"M";
    } else if ([string isEqualToString:list[1]]) {
        return @"F";
    } else {
        return nil;
    }
}

#pragma mark - Accessors

- (NSInteger)mutualFriendsCountExcludingSpayceProfile {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"recordID != %@", @-1];
    NSArray *filteredArray = [self.mutualFriendProfiles filteredArrayUsingPredicate:predicate];
    return filteredArray.count;
}

#pragma mark - Actions

- (void)updateWithFriendCount:(int)totalFriends {
    self.totalFriendCount = totalFriends;
}

@end
