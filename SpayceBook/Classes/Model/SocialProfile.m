//
//  SocialProfile.m
//  Spayce
//
//  Created by Pavel Dušátko on 2/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SocialProfile.h"
#import "Person.h"
#import "TranslationUtils.h"
#import "Asset.h"

@implementation SocialProfile

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        _firstname = (NSString *)[TranslationUtils valueOrNil:attributes[@"firstname"]];
        _lastname = (NSString *)[TranslationUtils valueOrNil:attributes[@"lastname"]];
        _mutualFriendsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"mutualFriendsCount"];
        _uid = (NSString *)[TranslationUtils valueOrNil:attributes[@"id"]];
        _contactToken = (NSString *)[TranslationUtils valueOrNil:attributes[@"contactToken"]];
        _spayceMember = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"spayceMember"];
        _profilePictureUrlString = (NSString *)[TranslationUtils valueOrNil:attributes[@"profilePhotoAssetID"]];
        _followingStatus = [self followingStatusFromString:(NSString *)[TranslationUtils valueOrNil:attributes[@"followingStatus"]]];
        _invited = ((NSString *)[TranslationUtils valueOrNil:attributes[@"status"]]) != nil;
        
        [TranslationUtils integerValueFromDictionary:attributes withKey:@"profilePhotoAssetId"];
        
        if ([_firstname length] == 0) {
            _firstname = (NSString *)[TranslationUtils valueOrNil:attributes[@"firstName"]];
        }
        
        _userId =[TranslationUtils integerValueFromDictionary:attributes withKey:@"userId"];
        _starCount =[TranslationUtils integerValueFromDictionary:attributes withKey:@"starCount"];
        
        if (_spayceMember) {
            NSDictionary *personAttributes = @{
                                               @"userToken": attributes[@"userToken"] ?: @"",
                                               @"handle": attributes[@"handle"] ?: @"",
                                               @"profilePhotoAssetInfo": attributes[@"profilePhotoAssetInfo"] ?: @{},
                                               @"friendStatus": attributes[@"friendStatus"] ?: @"",
                                               @"followingStatus": attributes[@"followingStatus"] ?: @""
                                               };
            _person = [[Person alloc] initWithAttributes:personAttributes];
        }
    }
    return self;
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
