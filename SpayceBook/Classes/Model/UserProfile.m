//
//  UserProfile.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/15/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "UserProfile.h"

// Model
#import "ProfileDetail.h"
#import "User.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"

@implementation UserProfile

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        _profileUserId = [attributes[@"userId"] integerValue];
        
        for (NSDictionary *profile in attributes[@"spayceMeetProfiles"]) {
            NSString *profileType = profile[@"profileType"];
            if ([profileType isEqualToString:@"PERSONAL"]) {
                _profileDetail = [[ProfileDetail alloc] initWithAttributes:profile];
            }
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    UserProfile *profile = [[self class] allocWithZone:zone];
    profile.profileUserId = self.profileUserId;
    profile.name = [self.name copyWithZone:zone];
    profile.profileDetail = [self.profileDetail copyWithZone:zone];
    
    return profile;
}

- (void)updateWithFriendCount:(NSInteger)totalFriends {
    self.totalFriendCount = totalFriends;
    [self.profileDetail updateWithFriendCount:(int)self.totalFriendCount];
}

- (BOOL)isCurrentUser {
    return [self.userToken isEqualToString:[AuthenticationManager sharedInstance].currentUser.userToken];
}

- (BOOL)isFollowingUser {
    return self.profileDetail.followerStatus == FollowingStatusFollowing;
}

- (BOOL)isFollowedByUser {
    return self.profileDetail.followingStatus == FollowingStatusFollowing;
}

@end
