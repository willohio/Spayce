//
//  UIFont+SPCAdditions.h
//  Spayce
//
//  Created by Pavel Dusatko on 5/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (SPCAdditions)

// System
+ (UIFont *)spc_regularSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)spc_mediumSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)spc_boldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)spc_lightSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)spc_romanSystemFontOfSize:(CGFloat)fontSize;

// Default
+ (UIFont *)spc_regularFont;
+ (UIFont *)spc_lightFont;
+ (UIFont *)spc_thinFont;
+ (UIFont *)spc_mediumFont;
+ (UIFont *)spc_boldFont;

// Common
+ (UIFont *)spc_tabBarFont;
+ (UIFont *)spc_navigationBarTitleFont;
+ (UIFont *)spc_segmentedControlFont;
+ (UIFont *)spc_inputFont;
+ (UIFont *)spc_titleFont;
+ (UIFont *)spc_placeholderFont;
+ (UIFont *)spc_roundedButtonFont;

// Memory
+ (UIFont *)spc_memory_placeholderFont;
+ (UIFont *)spc_memory_authorFont;
+ (UIFont *)spc_memory_locationFont;
+ (UIFont *)spc_memory_textFont;
+ (UIFont *)spc_memory_actionButtonFont;

// MAM
+ (UIFont *)spc_mam_tagFont;

// Coach marks
+ (UIFont *)spc_coachMarkTitleFont;
+ (UIFont *)spc_coachMarkTextFont;
+ (UIFont *)spc_coachMarkButtonFont;

// Notifications
+ (UIFont *)spc_notificationTimestampFont;

// Map
+ (UIFont *)spc_map_subtitleFont;

// Profile
+ (UIFont *)spc_profile_usernameFont;
+ (UIFont *)spc_profile_statusFont;
+ (UIFont *)spc_profileInfo_regularSectionFont;
+ (UIFont *)spc_profileInfo_boldSectionFont;
+ (UIFont *)spc_profileInfo_placeholderFont;

// Invite
+ (UIFont *)spc_inviteFriends_inviteAllFont;
+ (UIFont *)spc_inviteFriends_inviteAllHighlightedFont;
+ (UIFont *)spc_inviteFriends_inviteButtonFont;
+ (UIFont *)spc_inviteFriends_mutualFriendsFont;

// Banners
+ (UIFont *)spc_notificationBanner_titleFont;
+ (UIFont *)spc_notificationBanner_subtitleFont;

// Search
+ (UIFont *)spc_searchFontSmall;
+ (UIFont *)spc_searchFontLarge;

// Badge
+ (UIFont *)spc_badgeFont;

@end
