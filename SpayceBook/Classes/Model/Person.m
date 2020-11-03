//
//  Person.m
//  Spayce
//
//  Created by Pavel Dušátko on 12/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Person.h"

// Model
#import "Asset.h"
#import "SPCNeighborhood.h"

// Utility
#import "TranslationUtils.h"

CGFloat kMAX_STARS = 1000.0f;

@interface Person ()

@property (nonatomic, copy) NSDictionary *attributes;

@end

@implementation Person

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        _attributes = [attributes copy];
        
        [self configureWithAttributes:attributes];
    }
    return self;
}

- (void)configureWithAttributes:(NSDictionary *)attributes {
    _recordID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"userId"];
    if (!_recordID) {
        _recordID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"id"];
    }
    _userToken = (NSString *)[TranslationUtils valueOrNil:attributes[@"userToken"]];
    _handle = (NSString *)[TranslationUtils valueOrNil:attributes[@"handle"]];
    
    if ([attributes valueForKey:@"firstname"]) {
        _firstname = (NSString *)[TranslationUtils valueOrNil:attributes[@"firstname"]];
    }
    else if ([attributes valueForKey:@"firstName"]) {
        _firstname = (NSString *)[TranslationUtils valueOrNil:attributes[@"firstName"]];
    }
    
    if ([attributes valueForKey:@"lastname"]) {
        _lastname = (NSString *)[TranslationUtils valueOrNil:attributes[@"lastname"]];
    }
    else if ([attributes valueForKey:@"lastName"]) {
        _lastname = (NSString *)[TranslationUtils valueOrNil:attributes[@"lastName"]];
    }
    
    _mutualFriendsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"mutualFriendsCount"];
    _starCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"starCount"];
    _rankedStarCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"rankedStarCount"];
    _isCeleb = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"isCeleb"];
    _topCity = (NSString *)[TranslationUtils valueOrNil:attributes[@"topCity"]];
    _topNeighborhood = (NSString *)[TranslationUtils valueOrNil:attributes[@"topNeighborhood"]];
    _followingStatus = [self followingStatusFromString:(NSString *)[TranslationUtils valueOrNil:attributes[@"followingStatus"]]];
    _followerStatus = [self followingStatusFromString:(NSString *)[TranslationUtils valueOrNil:attributes[@"followerStatus"]]];
    
    NSDictionary *risingStarTerritoryAttributes = attributes[@"risingStarTerritory"];
    if (risingStarTerritoryAttributes) {
        _risingStarTerritory = [[SPCNeighborhood alloc] initWithAttributes:risingStarTerritoryAttributes];
    }
    
    [self initializeDateBlockedWithAttributes:attributes];
    [self initializeImageAssetsWithAttributes:attributes];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.attributes forKey:@"attributes"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        [self configureWithAttributes:[aDecoder decodeObjectForKey:@"attributes"]];
    }
    
    return self;
}

- (void)initializeDateBlockedWithAttributes:(NSDictionary *)attributes {
    NSNumber *dateBlocked = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"dateBlocked"]];
    if (dateBlocked) {
        NSTimeInterval seconds = [dateBlocked doubleValue];
        NSTimeInterval miliseconds = seconds/1000;
        _dateBlocked = [NSDate dateWithTimeIntervalSince1970:miliseconds];
    }
}

- (void)initializeImageAssetsWithAttributes:(NSDictionary *)attributes {
    
    _profilePhotoAssetInfo = (NSString *)[TranslationUtils valueOrNil:attributes[@"profilePhotoAssetInfo"]];
    _profilePhotoAssetID = (NSString *)[TranslationUtils valueOrNil:attributes[@"profilePhotoAssetID"]];
    
    _imageAsset = [Asset assetFromDictionary:attributes withAssetKey:@"profilePhotoAssetInfo" assetIdKey:@"profilePhotoAssetID"];
    if (!_imageAsset) {
        _imageAsset = [Asset assetFromDictionary:attributes withAssetKey:@"profilePhotoAssetInfo" assetIdKey:@"profilePhotoAssetId"];
    }
}

#pragma mark - NSObject - Identifying and Comparing Objects

- (BOOL)isEqual:(Person *)person {
    return (self.recordID == person.recordID);
}

#pragma mark - Accessors

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
    return [NSString stringWithString:mutableString];
}

- (NSString *)displayStarCount {
    if (self.starCount == 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ star", nil), @(self.starCount)];
    }
    else if (self.starCount > 1) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ stars", nil), @(self.starCount)];
    }
    else {
        return NSLocalizedString(@"Zero stars", nil);
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

@end
