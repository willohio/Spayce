//
//  Enums.h
//  Spayce
//
//  Created by Pavel Dušátko on 10/3/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#ifndef Spayce_Enums_h
#define Spayce_Enums_h

// Find friends
typedef NS_ENUM(NSInteger, SocialServiceType) {
    SocialServiceTypeFacebook,
    SocialServiceTypeTwitter,
    SocialServiceTypeAddressBook,
    SocialServiceTypeLinkedIn
};

// Following status
typedef NS_ENUM(NSInteger, FollowingStatus) {
    FollowingStatusUnknown             = 0,    // Unknown
    FollowingStatusNotFollowing        = 1,    // Not following yet
    FollowingStatusRequested           = 2,    // Requested to follow this user
    FollowingStatusFollowing           = 3,    // Following this user
    FollowingStatusBlocked             = 4     // Blocked
};

// Memory sort type
typedef NS_ENUM(NSInteger, MemorySortType) {
    MemorySortTypeUnknown               = 0,    // Unknown - defaults to Recency
    MemorySortTypeRecency               = 1,    // Sorted by recency, with a limit and page count
    MemorySortTypePopularity            = 2,    // Sorted by popularity, with a limit
    MemorySortTypePopularityRecency     = 3,    // Sorted by recency and popularity, with a limit
};

// Profile memory segment types
typedef NS_ENUM(NSInteger, MemoryCellDisplayType) {
    MemoryCellDisplayTypeUnknown            = 0,    // Unknown - defaults to Grid
    MemoryCellDisplayTypeGrid               = 1,    // Display as Grid
    MemoryCellDisplayTypeList               = 2,    // Display as List/Feed
};

typedef NS_ENUM(NSInteger, ImageCacheSize) {
    ImageCacheSizeDefault = 0,
    ImageCacheSizeThumbnailXSmall = 32,
    ImageCacheSizeThumbnailSmall = 60,
    ImageCacheSizeThumbnailMedium = 100,
    ImageCacheSizeThumbnailLarge = 200,
    ImageCacheSizeThumbnailXLarge = 300,
    ImageCacheSizeSquare = 620,
    ImageCacheSizeSquareMedium = 310,
};


typedef NS_ENUM (NSInteger, MemoryDisplayType) {
    MemoryDisplayTypeFriendsAll,
    MemoryDisplayTypeFriendsNearby,
    MemoryDisplayTypePublic,
    MemoryDisplayTypeVenue
};

typedef NS_ENUM (NSInteger, SPCReportType) {
    SPCReportTypeUnknown,
    SPCReportTypeAbuse,
    SPCReportTypeSpam,
    SPCReportTypePersonal,
    SPCReportTypeIncorrect,
};

typedef NS_ENUM (NSInteger, CoachMarkScreenType) {
    CoachMarkTypeMAMSkip,
    CoachMarkTypeMAMPublic,
    CoachMarkTypeMAMPrivate,
    CoachMarkTypeVenueFav,
    CoachMarkTypeSpayce
};

typedef NS_ENUM(NSInteger, CalloutArrowLocation) {
    CalloutArrowLocationUnknown = 0,                // Defaults to top in Callout.m
    CalloutArrowLocationTop = 1,
    CalloutArrowLocationBottom = 2,
};

typedef NS_ENUM(NSInteger, GoogleApiResult) {
    GoogleApiResultSuccess,
    GoogleApiResultRateLimited,
    GoogleApiResultFailureGoogleCall,
    GoogleApiResultFailureServerCall
};

typedef NS_ENUM(NSInteger, SPCCellStyle){
    SPCCellStyleSingle,
    SPCCellStyleTop,
    SPCCellStyleMiddle,
    SPCCellStyleBottom
};

typedef NS_ENUM(NSInteger, SPCProfileDescriptionType) {
    SPCProfileDescriptionTypeUnknown,
    SPCProfileDescriptionTypeStars,
    SPCProfileDescriptionTypeFollowers,
    SPCProfileDescriptionTypeFollowing,
};

typedef NS_ENUM(NSInteger, SPCFriendsListType) {
    SPCFriendsListTypeUserFriends,
    SPCFriendsListTypeMyFriends,
    SPCFriendsListTypeUserMutualFriends,
};

typedef NS_ENUM(NSInteger, SPCFollowListType) {
    SPCFollowListTypeUserFollowers,
    SPCFollowListTypeUserFollows,
    SPCFollowListTypeMyFollowers,
    SPCFollowListTypeMyFollows,
    SPCFollowListTypeUserMutualFollowers,
    SPCFollowListTypeUserMutualFollows
};


typedef NS_ENUM(NSInteger, SPCVenueSpecifiity) {
    SPCVenueIsReal,
    SPCVenueIsFuzzedToNeighhborhood,
    SPCVenueIsFuzzedToCity,
};
#endif
