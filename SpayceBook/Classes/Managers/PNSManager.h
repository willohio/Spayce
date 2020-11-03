//
//  PNSManager.h
//  SpayceBook
//
//  Created by Dmitry Miller on 8/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"

@class SpayceNotification;

extern NSString *PNSManagerDidReceiveRemoteNotification;
extern NSString *PNSManagerDidReceiveNotifications;
extern NSString *PNSManagerDidSortNotifications;
extern NSString *PNSManagerDidReceiveSpayceVaultPhotos;
extern NSString *PNSManagerNotificationsLoaded;

@interface PNSManager : NSObject
{
    NSDictionary *scheduledNotification;
}

@property (nonatomic, strong) NSString *pnsDeviceToken;
#if !TARGET_IPHONE_SIMULATOR
@property (nonatomic, readonly) BOOL pnsTokenRegistered;
#endif
@property (nonatomic) int totalCount;
@property (nonatomic, assign) NSInteger unreadCount;
@property (nonatomic, assign) NSInteger unreadFeedCount;
@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, readonly) NSInteger unreadNews;
@property (nonatomic, readonly) NSInteger unseenFriendRequests;
@property (nonatomic, strong) NSArray *friendRequests;
@property (nonatomic, strong) NSArray *allFriendRequests;

+ (PNSManager *)sharedInstance;

- (void)registerPnsDeviceToken:(NSString *)deviceToken
                resultCallback:(void (^)(NSString *pnsDeviceToken))resultCallback
                 faultCallback:(void (^)(NSError *fault))faultCallabck;

- (void)unregisterPnsDeviceToken:(NSString *)deviceToken
                  resultCallback:(void (^)(void))resultCallback
                   faultCallback:(void (^)(NSError *fault))faultCallabck;

- (void)scheduleRemoteNotificationOnAuthenticationSuccess:(NSDictionary *)remoteNotification;
- (int)getSectionsCount;
- (NSArray *)getNotificationsForSection:(int)section;
- (SpayceNotification *)getNotificationForId:(int)notificationId;

// persistence methods for notifications

- (void)markAsReadNotifications:(NSArray *)notificationsList;
- (void)markAsReadSingleNotification:(SpayceNotification *)notification;
- (void)markasReadNewsLog;
- (void)markasReadNewsLogOnDelay;
- (void)markAsReadFriendRequests;
- (void)markAsReadAllNotifications:(NSArray *)notificationsList;
- (void)requestNotificationsListWithFaultCallback:(void (^)(NSError *fault))faultCallback;


@end
