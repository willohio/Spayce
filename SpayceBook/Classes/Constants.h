//
//  Constants.h
//  Spayce
//
//  Created by Joseph Jupin on 10/2/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Face
extern NSString * const FIRST_TIME_FACE_SCAN;
extern NSString * const FIRST_TIME_SPAYCE_MEET_1_ON_1;
extern NSString * const FIRST_TIME_SPAYCE_MEET_GROUP;

// Social services
extern NSString * kSocialServicesTwitterConsumerKey;
extern NSString * kSocialServicesTwitterConsumerSecret;
extern NSString * kSocialServicesLinkedInURL;
extern NSString * kSocialServicesLinkedInConsumerKey;
extern NSString * kSocialServicesLinkedInConsumerSecret;
extern NSString * kSocialServicesLinkedInConsumerState;

// friend requests
extern NSString * kFriendRequestResponseCompleteRefreshNotificationDisplay;

extern NSString * kFollowRequestResponseDidComplete;
extern NSString * kFollowRequestResponseCompleteRefreshNotificationDisplay;
extern NSString * kFollowRequestResponseDidAcceptWithUserToken;
extern NSString * kFollowRequestResponseDidRejectWithUserToken;

extern NSString *kFollowDidRequestWithUserToken;
extern NSString *kFollowDidFollowWithUserToken;
extern NSString *kFollowDidUnfollowWithUserToken;


extern NSString * kUserDidMove;

// Star count
extern NSString *kStarCountDateUpdatedKey;

// Tab Bar selected item
extern NSString * kSPCTabBarSelectedItemDidChangeNotification;
extern NSUInteger const TAB_BAR_HOME_ITEM_INDEX;
extern NSUInteger const TAB_BAR_FEED_ITEM_INDEX;
extern NSUInteger const TAB_BAR_MAM_ITEM_INDEX;
extern NSUInteger const TAB_BAR_ACTIVITY_ITEM_INDEX;
extern NSUInteger const TAB_BAR_PROFILE_ITEM_INDEX;

// NSUserDefaults New User Welcome Screen
extern NSString *kSPCWelcomeIntroWasShown;

// NSUserDefaults New User Education Screens
extern NSString *kSPCAddFriendsCalloutWasShown;
extern NSString *kSPCPeopleEducationScreenWasShown;
extern NSString *kSPCTerritoriesEducationScreenWasShown;
extern NSString *kSPCAnonUnlockScreenWasShown;
extern NSString *kSPCAnonWarningScreenWasShown;
extern NSString *kSPCAnonWarningScreenLastWarningCountWasShown;
extern NSString *kSPCAdminWarningScreenWasShown;
extern NSString *kSPCAdminWarningScreenLastWarningCountWasShown;

// NSUserDefaults strings for callout/coachmark screens
extern NSString *kSPCCalloutWorldWasShown;
extern NSString *kSPCCalloutLocalWasShown;
extern NSString *kSPCCalloutFlyWasShown;
extern NSString *kSPCCalloutMAMWasShown;

// Montage
extern NSString *kSPCMontageLastMemoriesViewedWorld;
extern NSString *kSPCMontageLastMemoriesViewedLocal;
extern NSString *kSPCMontageCoachmarkWasShown;
extern NSString *kSPCMAMCaptureCoachmarkWasShown;
extern NSString *kSPCMAMAdjustmentCoachmarkWasShown;

extern NSString *kSPCCalloutLimitationFacebookWasShown;
extern NSString *kSPCCalloutLimitationTwitterWasShown;

// Suggested Friends
extern NSString *kSPCSuggestedFriendsFreshPageKey;

// Friending Activity
extern NSString *kSPCFriendingActivityLatestActivityDate;
extern NSString *kSPCFriendingActivityDismissedByUser;

// Feed Activity
extern NSString * const kSPCFeedHasAppearedBefore;
extern NSString * const kSPCFeedFindPressCountUpToTwo;
