//
//  SPCNotifications.m
//  Spayce
//
//  Created by William Santiago on 9/10/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCNotifications.h"

NSString * kUserProfileDidUpdateNotification = @"UserProfileDidUpdateNotification";

NSString * kBusinessCardDidUpdateNotification = @"BusinessCardDidUpdateNotification";
NSString * kPersonalCardDidUpdateNotification = @"PersonalCardDidUpdateNotification";

NSString * kProfessionalProfileDidUpdateNotification = @"ProfessionalProfileDidUpdateNotification";
NSString * kPersonalProfileDidUpdateNotification = @"PersonalProfileDidUpdateNotification";

NSString * kUpdateProfileView = @"ProfileDidUpdateRefreshView";

NSString * kProfileLoaded = @"UserProfileDidUpdate";

NSString * kStatusUpdate = @"UserStatusUpdate";

NSString * kFriendsDidDeleteFriendNotification = @"FriendsDidDeleteFriendNotification";
NSString * kMeetDidBlockUserNotification = @"MeetDidBlockUserNotification";
NSString * kMeetDidUnblockUserNotification = @"MeetDidUnblockUserNotification";

NSString * kUpdateProfilePrivacy = @"profilePrivacyDidChange";

NSString * kFollowersCollectionMarkDirty = @"FollowersCollectionMarkDirty";
NSString * kFollowedUsersCollectionMarkDirty = @"FollowedUsersCollectionMarkDirty";
NSString * kBlockedCollectionMarkDirty = @"BlockedCollectionMarkDirty";

NSString * kDidStarMemory = @"DidStarMemory";
NSString * kDidUnstarMemory = @"DidUnstarMemory";

NSString * kDidStarComment = @"DidStarComment";
NSString * kDidUnstarComment = @"DidUnstarComment";

NSString * kDidChangeRelationship = @"DidChangeRelationship";
NSString * kDidAddFriend = @"kDidAddFriend";
NSString * kDidRemoveFriend = @"kDidRemoveFriend";
NSString * kDidAddBlock = @"kDidAddBlock";
NSString * kDidRemoveBlock = @"kDidRemoveBlock";
NSString * kDidAddFollower = @"kDidAddFollower";
NSString * kDidRemoveFollower = @"kDidRemoveFollower";

NSString * kStatusBarColorNotification = @"StatusBarColorNotification";

NSString * kLocationServicesAuthorizationStatusWillChangeNotification = @"LocationServicesAuthorizationStatusWillChangeNotification";
NSString * kLocationServicesAuthorizationStatusDidChangeNotification = @"LocationServicesAuthorizationStatusDidChangeNotification";

NSString * kFriendRequestDisplaysNeedUpdating = @"FriendRequestDisplaysNeedUpating";
NSString * kFollowRequestDisplaysNeedUpdating = @"FollowRequestDisplaysNeedUpating";
