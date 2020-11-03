//
//  UIFont+SPCAdditions.m
//  Spayce
//
//  Created by Pavel Dusatko on 5/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "UIFont+SPCAdditions.h"

@implementation UIFont (SPCAdditions)

#pragma mark - Private

+ (NSString *)regularFontName {
    return @"HelveticaNeue";
}

+ (NSString *)lightFontName {
    return @"HelveticaNeue-Light";
}

+ (NSString *)mediumFontName {
    return @"HelveticaNeue-Medium";
}

+ (NSString *)boldFontName {
    return @"HelveticaNeue-Bold";
}

+ (NSString *)thinFontName {
    return @"HelveticaNeue-Thin";
}

#pragma mark - System

+ (UIFont *)spc_regularSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"AvenirNext-Regular" size:fontSize];
}

+ (UIFont *)spc_mediumSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"AvenirNext-Medium" size:fontSize];
}

+ (UIFont *)spc_boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"AvenirNext-DemiBold" size:fontSize];
}

+ (UIFont *)spc_lightSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"Avenir-Light" size:fontSize];
}

+ (UIFont *)spc_romanSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"Avenir-Roman" size:fontSize];
}

#pragma mark - Default

+ (UIFont *)spc_regularFont {
    return [UIFont fontWithName:[[self class] regularFontName] size:14.0];
}

+ (UIFont *)spc_lightFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:14.0];
}

+ (UIFont *)spc_thinFont {
    return [UIFont fontWithName:[[self class] thinFontName] size:14.0];
}

+ (UIFont *)spc_mediumFont {
    return [UIFont fontWithName:[[self class] mediumFontName] size:14.0];
}

+ (UIFont *)spc_boldFont {
    return [UIFont fontWithName:[[self class] boldFontName] size:14.0];
}

#pragma mark - Common

+ (UIFont *)spc_tabBarFont {
    return [[self class] spc_regularSystemFontOfSize:7];
}

+ (UIFont *)spc_navigationBarTitleFont {
    return [UIFont spc_mediumSystemFontOfSize:17];
}

+ (UIFont *)spc_segmentedControlFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:15.0];
}

+ (UIFont *)spc_inputFont {
    return [UIFont fontWithName:[[self class] regularFontName] size:16.0];
}

+ (UIFont *)spc_titleFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:22.0];
}

+ (UIFont *)spc_placeholderFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:15.0];
}

+ (UIFont *)spc_roundedButtonFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:13.0];
}

#pragma mark - Memories

+ (UIFont *)spc_memory_placeholderFont {
    return [UIFont fontWithName:[[self class] mediumFontName] size:20];
}

+ (UIFont *)spc_memory_authorFont {
    return [UIFont spc_boldSystemFontOfSize:14];
}

+ (UIFont *)spc_memory_locationFont {
    return [UIFont spc_regularSystemFontOfSize:12];
}

+ (UIFont *)spc_memory_textFont {
    return [UIFont spc_regularSystemFontOfSize:14];
}

+ (UIFont *)spc_memory_actionButtonFont {
    return [UIFont spc_regularSystemFontOfSize:17];
}

#pragma mark - MAM

+ (UIFont *)spc_mam_tagFont {
    return [UIFont fontWithName:[[self class] regularFontName] size:13.0];
}

#pragma mark - Coach marks

+ (UIFont *)spc_coachMarkTitleFont {
    return [UIFont fontWithName:[[self class] boldFontName] size:14.0];
}

+ (UIFont *)spc_coachMarkTextFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:14.0];
}

+ (UIFont *)spc_coachMarkButtonFont {
    return [UIFont fontWithName:[[self class] mediumFontName] size:15.0];
}

#pragma mark - Notifications

+ (UIFont *)spc_notificationTimestampFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:14.0];
}

#pragma mark - Map

+ (UIFont *)spc_map_subtitleFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:12.0];
}

#pragma mark - Profile

+ (UIFont *)spc_profile_usernameFont {
    return [UIFont fontWithName:[[self class] mediumFontName] size:16.0];
}

+ (UIFont *)spc_profile_statusFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:14.0];
}

+ (UIFont *)spc_profileInfo_regularSectionFont {
    return [UIFont fontWithName:[[self class] regularFontName] size:12.0];
}

+ (UIFont *)spc_profileInfo_boldSectionFont {
    return [UIFont fontWithName:[[self class] boldFontName] size:12.0];
}

+ (UIFont *)spc_profileInfo_placeholderFont {
    return [UIFont fontWithName:[[self class] thinFontName] size:30.0];
}

#pragma mark - Invite

+ (UIFont *)spc_inviteFriends_inviteAllFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:13.0];
}

+ (UIFont *)spc_inviteFriends_inviteAllHighlightedFont {
    return [UIFont fontWithName:[[self class] mediumFontName] size:13.0];
}

+ (UIFont *)spc_inviteFriends_inviteButtonFont {
    return [UIFont fontWithName:[[self class] mediumFontName] size:12.0];
}

+ (UIFont *)spc_inviteFriends_mutualFriendsFont {
    return [UIFont systemFontOfSize:13];
}

#pragma mark - Banners

+ (UIFont *)spc_notificationBanner_titleFont {
    return [UIFont fontWithName:[[self class] regularFontName] size:16.0];
}

+ (UIFont *)spc_notificationBanner_subtitleFont {
    return [UIFont fontWithName:[[self class] lightFontName] size:12.0];
}

#pragma mark - Search

+ (UIFont *)spc_searchFontSmall {
    return [UIFont fontWithName:[[self class] thinFontName] size:12.0];
}

+ (UIFont *)spc_searchFontLarge {
    return [UIFont fontWithName:[[self class] thinFontName] size:18.0];
}

#pragma mark - Badges

+ (UIFont *)spc_badgeFont {
  return [[self class] spc_mediumSystemFontOfSize:12];
}

@end
