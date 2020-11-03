//
//  SpayceNotification.h
//  Spayce
//
//  Created by Joseph Jupin on 10/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Comment.h"

@class User;

static const int NOTIFICATION_TYPE_UNKNOWN           = -1;
static const int NOTIFICATION_TYPE_MESSAGE           = 0;
static const int NOTIFICATION_TYPE_PERSONAL_CARD     = 1;
static const int NOTIFICATION_TYPE_PROFESSIONAL_CARD = 2;
static const int NOTIFICATION_TYPE_EMAIL             = 3;
static const int NOTIFICATION_TYPE_FACEBOOK          = 4;
static const int NOTIFICATION_TYPE_TWITTER           = 5;
static const int NOTIFICATION_TYPE_LINKEDIN          = 6;
static const int NOTIFICATION_TYPE_STATUS            = 7;
static const int NOTIFICATION_TYPE_FRIEND_REQUEST    = 8;
static const int NOTIFICATION_TYPE_FRIEND            = 9;
static const int NOTIFICATION_TYPE_MEMORY            = 10;
static const int NOTIFICATION_TYPE_COMMENT           = 11;
static const int NOTIFICATION_TYPE_STAR              = 12;
static const int NOTIFICATION_TYPE_PLACEINVITE       = 13;
static const int NOTIFICATION_TYPE_CONFIRMED         = 14;
static const int NOTIFICATION_TYPE_VIP               = 15;  // FIXME: Deprecated
static const int NOTIFICATION_TYPE_LOCATION_FRIEND   = 16;
static const int NOTIFICATION_TYPE_LOCATION_PUBLIC   = 17;
static const int NOTIFICATION_TYPE_LOCATION_OLD      = 18;
static const int NOTIFICATION_TYPE_LOCATION_NONE     = 19;
static const int NOTIFICATION_TYPE_DAILY             = 20;
static const int NOTIFICATION_TYPE_DAILY_REWARD      = 21;
static const int NOTIFICATION_TYPE_COMMENT_NEW       = 22;
static const int NOTIFICATION_TYPE_COMMENT_STAR      = 23;
static const int NOTIFICATION_TYPE_TAGGED_COMMENT    = 24;
static const int NOTIFICATION_TYPE_FRIEND_REQUEST_SENT    = 25;
static const int NOTIFICATION_TYPE_FOLLOWED_BY       = 26;
static const int NOTIFICATION_TYPE_FOLLOW_REQUEST    = 27;
static const int NOTIFICATION_TYPE_FOLLOWING         = 28;


@interface SpayceNotification : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) NSInteger notificationId;
@property (nonatomic, strong) NSDate *notificationDate;
@property (nonatomic, strong) NSString *notificationText;
@property (nonatomic, strong) NSString *notificationType;
@property (nonatomic, assign) BOOL hasBeenRead;
@property (nonatomic, strong) User *user;
@property (nonatomic, assign) NSInteger objectId;
@property (nonatomic, strong) NSString *param1;
@property (nonatomic, strong) NSString *param2;
@property (nonatomic, strong) NSString *createdTime;
@property (nonatomic, strong) NSString *commentText;
@property (nonatomic, strong) NSString *memoryAddressName;
@property (nonatomic, strong) NSArray *memoryParticipants;
@property (nonatomic, strong) NSString *recipientUserToken;
@property (nonatomic, strong) NSDictionary *commentDict;

+ (int)retrieveNotificationType:(SpayceNotification *)notification;

@end
