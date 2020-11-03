//
//  Constants.m
//  Spayce
//
//  Created by Joseph Jupin on 10/2/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Constants.h"

// Face detection
NSString * const FIRST_TIME_FACE_SCAN          = @"first_time_face_scan";
NSString * const FIRST_TIME_SPAYCE_MEET_1_ON_1 = @"first_time_spayce_meet_1_on_1";
NSString * const FIRST_TIME_SPAYCE_MEET_GROUP  = @"first_time_spayce_meet_group";

// Social services
NSString * kSocialServicesTwitterConsumerKey = @"jdXpOBuGaPVhYPdnQusg";
NSString * kSocialServicesTwitterConsumerSecret = @"BCDMO77PdEhP40t8CviOq6mJkv8O3de2OkaRHFRFP0M";
NSString * kSocialServicesLinkedInURL = @"http://www.spayce.com";
NSString * kSocialServicesLinkedInConsumerKey = @"tja6oy6yqp9w";
NSString * kSocialServicesLinkedInConsumerSecret = @"DX9hvGdkkLlga0uW";
NSString * kSocialServicesLinkedInConsumerState = @"HaveYouHeardTheOneAboutSandraBullockHatingSpayce?";

//Friend requests
NSString * kFriendRequestResponseCompleteRefreshNotificationDisplay = @"refreshNotificationDisplay";

NSString * kFollowRequestResponseDidComplete = @"deleteFollowRequestNotificationWithObjectId";
NSString * kFollowRequestResponseCompleteRefreshNotificationDisplay = @"refreshNotificationDisplay";
NSString * kFollowRequestResponseDidAcceptWithUserToken = @"followRequestResponseDidAcceptWithUserToken";
NSString * kFollowRequestResponseDidRejectWithUserToken = @"followRequestResponseDidRejectWithUserToken";


NSString *kFollowDidRequestWithUserToken = @"followDidRequestWithUserToken";
NSString *kFollowDidFollowWithUserToken = @"followDidFollowWithUserToken";
NSString *kFollowDidUnfollowWithUserToken = @"followDidUnfollowWithUserToken";


//location
NSString *kUserDidMove = @"updateFiltersWithNewLocation";

// Star count
NSString *kStarCountDateUpdatedKey = @"StarCountDateUpdatedKey";

// Tab Bar selected item
NSString * kSPCTabBarSelectedItemDidChangeNotification = @"SPCTabBarSelectedItemDidChangeNotification";
NSUInteger const TAB_BAR_HOME_ITEM_INDEX = 0;
NSUInteger const TAB_BAR_FEED_ITEM_INDEX = 1;
NSUInteger const TAB_BAR_MAM_ITEM_INDEX = 2;
NSUInteger const TAB_BAR_ACTIVITY_ITEM_INDEX = 3;
NSUInteger const TAB_BAR_PROFILE_ITEM_INDEX = 4;

// New User Welcome Screen
NSString *kSPCWelcomeIntroWasShown = @"welcomeIntroWasShown";

// New User Education Screens
// People education screen nsuserdefaults key
NSString *kSPCPeopleEducationScreenWasShown = @"peopleEducationScreenWasShown";
// Territories education screen nsuserdefaults key
NSString *kSPCTerritoriesEducationScreenWasShown = @"territoriesEducationScreenWasShown";

NSString *kSPCAnonUnlockScreenWasShown = @"anonUnlockScreenWasShown";

NSString *kSPCAnonWarningScreenWasShown = @"anonWarningScreenWasShown";
NSString *kSPCAnonWarningScreenLastWarningCountWasShown = @"lastWarningCount";
NSString *kSPCAdminWarningScreenWasShown = @"adminWarningScreenWasShown";
NSString *kSPCAdminWarningScreenLastWarningCountWasShown = @"adminWarningCount";

// Montage, Latest Memories Viewed
NSString *kSPCMontageLastMemoriesViewedWorld = @"montageLastMemoriesViewedWorld";
NSString *kSPCMontageLastMemoriesViewedLocal = @"montageLastMemoriesViewedLocal";

// Callout/coachmark screens
// World Callout nsuserdefaults key
NSString *kSPCCalloutWorldWasShown = @"calloutWorldWasShown";
// Local Callout nsuserdefaults key
NSString *kSPCCalloutLocalWasShown = @"calloutLocalWasShown";
// Fly Callout nsuserdefaults key
NSString *kSPCCalloutFlyWasShown = @"calloutFlyWasShown";
// MAM Callout nsuserdefaults key
NSString *kSPCCalloutMAMWasShown = @"calloutMAMWasShown";

// Montage Coachmark
NSString *kSPCMontageCoachmarkWasShown = @"montageCoachmarkWasShown";
// MAM Capture Coachmark
NSString *kSPCMAMCaptureCoachmarkWasShown = @"mamCaptureCoachmarkWasShown";
// MAM Adjustment Coachmark
NSString *kSPCMAMAdjustmentCoachmarkWasShown = @"mamAdjustmentCoachmarkWasShown";

// Facebook limitation
NSString *kSPCCalloutLimitationFacebookWasShown = @"calloutLimitationFacebookWasShown";
// Twitter limitation
NSString *kSPCCalloutLimitationTwitterWasShown = @"calloutLimitationTwitterWasShown";

// Suggested Friends Fresh Page Key
NSString *kSPCSuggestedFriendsFreshPageKey = @"suggestedFriendsFreshPageKey";

// Friending Activity
NSString *kSPCFriendingActivityLatestActivityDate = @"kSPCFriendingActivityLatestActivityDate";
NSString *kSPCFriendingActivityDismissedByUser = @"kSPCFriendingActivityDismissedByUser";

// Feed Activity
NSString * const kSPCFeedHasAppearedBefore = @"kSPCFeedHasAppearedBefore";
NSString * const kSPCFeedFindPressCountUpToTwo = @"kSPCFeedFindPressCountUpToTwo";
