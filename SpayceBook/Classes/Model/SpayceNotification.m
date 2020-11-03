//
//  SpayceNotification.m
//  Spayce
//
//  Created by Joseph Jupin on 10/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SpayceNotification.h"

// Model
#import "Asset.h"
#import "User.h"
#import "Comment.h"

@implementation SpayceNotification

#pragma mark - NSCoding - Initializing with a Coder

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.notificationId = [aDecoder decodeIntegerForKey:@"Id"];
        self.notificationDate = (NSDate *)[aDecoder decodeObjectForKey:@"notificationDate"];
        self.notificationText = (NSString *)[aDecoder decodeObjectForKey:@"notificationText"];
        self.notificationType = (NSString *)[aDecoder decodeObjectForKey:@"notificationType"];
        self.hasBeenRead  = [aDecoder decodeBoolForKey:@"hasBeenRead"];
        self.objectId = [aDecoder decodeIntegerForKey:@"objectId"];
        self.user = [[User alloc] init];
        self.user.userId = [aDecoder decodeIntegerForKey:@"userId"];
        self.user.username = (NSString *)[aDecoder decodeObjectForKey:@"userName"];
        self.user.lastName = (NSString *)[aDecoder decodeObjectForKey:@"lastName"];
        self.user.firstName = (NSString *)[aDecoder decodeObjectForKey:@"firstName"];
        self.user.imageAsset = (Asset *)[aDecoder decodeObjectForKey:@"imageAsset"];
        self.user.userToken = (NSString *)[aDecoder decodeObjectForKey:@"userToken"];
        self.param1 = (NSString *)[aDecoder decodeObjectForKey:@"param1"];
        self.param2 = (NSString *)[aDecoder decodeObjectForKey:@"param2"];
        self.createdTime =  (NSString *)[aDecoder decodeObjectForKey:@"createdTime"];
        self.commentText = (NSString *)[aDecoder decodeObjectForKey:@"commentText"];
        self.memoryAddressName = (NSString *)[aDecoder decodeObjectForKey:@"memoryAddressName"];
        self.memoryParticipants = (NSArray *)[aDecoder decodeObjectForKey:@"memoryParticipants"];
        self.recipientUserToken = (NSString *)[aDecoder decodeObjectForKey:@"recipientUserToken"];
        self.commentDict = (NSDictionary *)[aDecoder decodeObjectForKey:@"comment"];
    }
    
    return self;
}

#pragma mark - NSCoding - Encoding with a Coder

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:self.notificationId forKey:@"Id"];
    [aCoder encodeObject:self.notificationDate forKey:@"notificationDate"];
    [aCoder encodeObject:self.createdTime forKey:@"createdTime"];
    [aCoder encodeObject:self.notificationText forKey:@"notificationText"];
    [aCoder encodeObject:self.notificationType forKey:@"notificationType"];
    [aCoder encodeObject:self.param1 forKey:@"param1"];
    [aCoder encodeObject:self.param2 forKey:@"param2"];
    [aCoder encodeBool:self.hasBeenRead forKey:@"hasBeenRead"];
    [aCoder encodeInteger:self.objectId forKey:@"objectId"];
    [aCoder encodeObject:self.recipientUserToken forKey:@"recipientUserToken"];
    [aCoder encodeObject:self.commentDict forKey:@"comment"];
    
    if (self.commentText){
        [aCoder encodeObject:self.commentText forKey:@"commentText"];
    }
    if (self.memoryAddressName){
        [aCoder encodeObject:self.memoryAddressName forKey:@"memoryAddressName"];
    }
    [aCoder encodeObject:self.memoryParticipants forKey:@"memoryParticipants"];
    
    
    if (self.user) {
        [aCoder encodeObject:self.user.username forKey:@"userName"];
        [aCoder encodeInteger:self.user.userId forKey:@"userId"];
        [aCoder encodeObject:self.user.imageAsset forKey:@"imageAsset"];
        [aCoder encodeObject:self.user.lastName forKey:@"lastName"];
        [aCoder encodeObject:self.user.firstName forKey:@"firstName"];
        [aCoder encodeObject:self.user.userToken forKey:@"userToken"];
    }
}

#pragma mark - NSCopying - Copying

- (id)copyWithZone:(NSZone *)zone {
    SpayceNotification *res = [[SpayceNotification alloc] init];
    res.notificationId   = self.notificationId;
    res.notificationDate = [self.notificationDate copyWithZone:zone];
    res.createdTime = [self.createdTime copyWithZone:zone];
    res.notificationText = [self.notificationText copyWithZone:zone];
    res.notificationType = [self.notificationType copyWithZone:zone];
    res.param1 = [self.param1 copyWithZone:zone];
    res.param2 = [self.param2 copyWithZone:zone];
    res.objectId         = self.objectId;
    res.user = [[User alloc] init];
    res.user.username         = [self.user.username copyWithZone:zone];
    res.user.userId           = self.user.userId;
    res.user.firstName        = [self.user.firstName copyWithZone:zone];
    res.user.lastName         = [self.user.lastName copyWithZone:zone];
    res.user.imageAsset       = self.user.imageAsset;
    res.user.userToken        = self.user.userToken;
    res.commentText     = [self.commentText copyWithZone:zone];
    res.memoryAddressName     = [self.memoryAddressName copyWithZone:zone];
    res.memoryParticipants = [self.memoryParticipants copyWithZone:zone];
    res.hasBeenRead      = self.hasBeenRead;
    res.recipientUserToken = [self.recipientUserToken copyWithZone:zone];
    res.commentDict = [self.commentDict copyWithZone:zone];
    return res;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"SpayceNotification : {"];

    [desc appendFormat:@" notificationId: %@,", @(self.notificationId)];
    [desc appendFormat:@" notificationDate: '%@',", self.notificationDate];
    [desc appendFormat:@" createdTime: '%@',", self.createdTime];
    [desc appendFormat:@" notificationText: '%@',", self.notificationText];
    [desc appendFormat:@" notificationType: '%@',", self.notificationType];
    [desc appendFormat:@" hasBeenRead: %d,", self.hasBeenRead];
    [desc appendFormat:@" objectId: %@", @(self.objectId)];
    [desc appendFormat:@" param1: %@",self.param1];
    [desc appendFormat:@" param2: %@",self.param2];
    [desc appendFormat:@" commentText %@",self.commentText];
    [desc appendFormat:@" memoryAddressName %@",self.memoryAddressName];
    [desc appendFormat:@" memoryParticipants %@",self.memoryParticipants];
    [desc appendString:@" }"];

    return desc;
}

#pragma mark - Accessors

+ (int)retrieveNotificationType:(SpayceNotification *)notification {
    NSString *iconType = notification.notificationType;
    //NSLog(@"notification icon type %@",iconType);
    
    if ([iconType isEqualToString:@"message"]) {
        return NOTIFICATION_TYPE_MESSAGE;
    } else if ([iconType isEqualToString:@"status"]) {
        return NOTIFICATION_TYPE_STATUS;
    } else if ([iconType isEqualToString:@"twitter"]) {
        return NOTIFICATION_TYPE_TWITTER;
    } else if ([iconType isEqualToString:@"email"]) {
        return NOTIFICATION_TYPE_EMAIL;
    } else if ([iconType isEqualToString:@"facebook"]) {
        return NOTIFICATION_TYPE_FACEBOOK;
    } else if ([iconType isEqualToString:@"linkedin"]) {
        return NOTIFICATION_TYPE_LINKEDIN;
    } else if ([iconType isEqualToString:@"professionalCard"]) {
        return NOTIFICATION_TYPE_PROFESSIONAL_CARD;
    } else if ([iconType isEqualToString:@"personalCard"]) {
        return NOTIFICATION_TYPE_PERSONAL_CARD;
    } else if ([iconType isEqualToString:@"friendRequest"]){
        return NOTIFICATION_TYPE_FRIEND_REQUEST;
    } else if ([iconType isEqualToString:@"friend"]){
        return NOTIFICATION_TYPE_FRIEND;
    } else if ([iconType isEqualToString:@"memory"]){
        return NOTIFICATION_TYPE_MEMORY;
    } else if ([iconType isEqualToString:@"comment"]){
        return NOTIFICATION_TYPE_COMMENT;
    } else if ([iconType isEqualToString:@"star"]){
        return NOTIFICATION_TYPE_STAR;
    } else if ([iconType isEqualToString:@"comboStar"]){
        return NOTIFICATION_TYPE_STAR;
    } else if ([iconType isEqualToString:@"locationInvite"]){
        return NOTIFICATION_TYPE_PLACEINVITE;
    } else if ([iconType isEqualToString:@"confirmed"]){
        return NOTIFICATION_TYPE_CONFIRMED;
    } else if ([iconType isEqualToString:@"vip"]){
        return NOTIFICATION_TYPE_VIP;
    } else if ([iconType isEqualToString:@"locationBasedNotificationFriend"]){
        return NOTIFICATION_TYPE_LOCATION_FRIEND;
    } else if ([iconType isEqualToString:@"locationBasedNotificationPublic"]){
        return NOTIFICATION_TYPE_LOCATION_PUBLIC;
    } else if ([iconType isEqualToString:@"locationBasedNotificationOld"]){
        return NOTIFICATION_TYPE_LOCATION_OLD;
    } else if ([iconType isEqualToString:@"locationBasedNotificationNone"]){
        return NOTIFICATION_TYPE_LOCATION_NONE;
    } else if ([iconType isEqualToString:@"dailyPns"]){
        return NOTIFICATION_TYPE_DAILY;
    } else if ([iconType isEqualToString:@"dailyPnsReward"]){
        return NOTIFICATION_TYPE_DAILY_REWARD;
    } else if ([iconType isEqualToString:@"newComment"]){
        return NOTIFICATION_TYPE_COMMENT_NEW;
    } else if ([iconType isEqualToString:@"commentStar"]){
        return NOTIFICATION_TYPE_COMMENT_STAR;
    } else if ([iconType isEqualToString:@"taggedInComment"]){
        return NOTIFICATION_TYPE_TAGGED_COMMENT;
    }  else if ([iconType isEqualToString:@"sentFriendRequest"]){
        return NOTIFICATION_TYPE_FRIEND_REQUEST_SENT;
    } else if ([iconType isEqualToString:@"followedBy"]) {
        return NOTIFICATION_TYPE_FOLLOWED_BY;
    } else if ([iconType isEqualToString:@"followRequest"]) {
        return NOTIFICATION_TYPE_FOLLOW_REQUEST;
    } else if ([iconType isEqualToString:@"follow"]) {
        return NOTIFICATION_TYPE_FOLLOWING;
    }
    else {
        return NOTIFICATION_TYPE_UNKNOWN;
    }
}

@end
