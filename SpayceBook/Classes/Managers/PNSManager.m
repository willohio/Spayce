//
//  PNSManager.m
//  SpayceBook
//
//  Created by Dmitry Miller on 8/5/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "PNSManager.h"
#import "Flurry.h"

// Model
#import "PersonUpdate.h"
#import "SpayceNotification.h"
#import "User.h"
#import "Friend.h"

// Controller
#import "SPCMainViewController.h"
#import "SPCFeedViewController.h"

// Category
#import "NSDate-Utilities.h"
#import "NSArray+SPCAdditions.h"

// General
#import "AppDelegate.h"
#import "Constants.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"
#import "SPCMessageManager.h"

// Utility
#import "APIService.h"
#import "CollectionUtils.h"

NSString *PNSManagerDidReceiveRemoteNotification = @"pnsManagerDidReceiveRemoteNotification";
NSString *PNSManagerDidReceiveNotifications = @"pnsManagerDidReceiveRemoteNotifications";
NSString *PNSManagerDidSortNotifications = @"pnsManagerDidSortNotifications";
NSString *PNSManagerDidReceiveSpayceVaultPhotos = @"pnsManagerDidReceiveSpayceVaultPhotos";
NSString *PNSManagerNotificationsLoaded = @"pnsManagerNotificationsLoaded";

NSString *NotificationsFileName = @"notifications.plist";
NSString *NotficationsListRequestTimestamp = @"notificationsTimeStamp";

@interface PNSManager () {
    NSMutableDictionary *dateToNotification;
    NSArray *dateArr;
}


@property (nonatomic) BOOL pnsTokenRegistered;
@property (nonatomic) NSTimeInterval lastCheckedFeedTimeStamp;
@property (nonatomic, assign) BOOL provideFalseCount;
@property (nonatomic, strong) NSArray *recentNotifsToPersist;

- (void)checkForNotifications:(NSTimer *)timer;

- (NSDate *)lastNotificationsListRequest;
- (void)storeLastNotificationsListRequest:(NSDate *)timeOfRequest;
- (void)removeLastNotificationsListRequest;

@end

@implementation PNSManager

SINGLETON_GCD(PNSManager);

- (id)init
{
    self = [super init];

    if (self != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthenticationSuccess:)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:)
                                                     name:kAuthenticationDidLogoutNotification
                                                   object:nil];
            
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteFollowRequestNotificationWithUserToken:)
                                                     name:kFollowRequestResponseDidAcceptWithUserToken
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteFollowRequestNotificationWithUserToken:)
                                                     name:kFollowRequestResponseDidRejectWithUserToken
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyPersonUpdateWithNotification:) name:kPersonUpdateNotificationName object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markasReadNewsLogOnDelay) name:@"markNewsLogReadOnDelay" object:nil];
        
        
        self.notifications = [[NSMutableArray alloc] init];
        self.totalCount = 0;
        [NSTimer scheduledTimerWithTimeInterval:30.0f target:self selector:@selector(checkForNotifications:) userInfo:nil repeats:YES];
    }

    return self;
}

- (void)checkForNotifications:(NSTimer *)timer
{
    [self requestNotificationsListWithFaultCallback:^(NSError *fault) {
        NSLog(@"%@", [fault description]);
    }];
}

- (void)registerPnsDeviceToken:(NSString *)deviceTokenValue
                resultCallback:(void (^)(NSString *pnsDeviceToken))resultCallback
                 faultCallback:(void (^)(NSError *fault))faultCallback
{
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    mutableParams[@"deviceType"] = DEVICE_TYPE;

    if (deviceTokenValue) {
        mutableParams[@"pnsToken"] = deviceTokenValue;
        
        __weak typeof(self)weakSelf = self;
        
        [APIService makeApiCallWithMethodUrl:@"/notification/registerPNSToken"
                              andRequestType:RequestTypeGet
                               andPathParams:nil
                              andQueryParams:mutableParams
                              resultCallback:^(NSObject *result) {
                                  __strong typeof(weakSelf)strongSelf = weakSelf;
                                  if (!strongSelf) {
                                      return;
                                  }
                                  //NSLog(@"url params %@ notification/registerPNSToken result %@",mutableParams,result);
                                  
                                  self.pnsTokenRegistered = YES;
                                  
                                  if (resultCallback) {
                                      resultCallback(deviceTokenValue);
                                  }
                              } faultCallback:^(NSError * fault) {
                                  NSLog(@"notification/registerPNSToken fault %@",fault);
                                  if (faultCallback) {
                                      faultCallback(fault);
                                  }
                              }];
    }
}

- (void)unregisterPnsDeviceToken:(NSString *)deviceToken
                  resultCallback:(void (^)(void))resultCallback
                   faultCallback:(void (^)(NSError *fault))faultCallabck
{
    [APIService makeApiCallWithMethodUrl:@"/notification/unregisterPNSToken"
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:(deviceToken) ? @{@"pnsToken" : deviceToken} : nil
                          resultCallback:^(NSObject *result) {
                              NSLog(@"result %@",result);
                              if (resultCallback) {
                                  resultCallback();
                              }
                          } faultCallback:faultCallabck];
}

#pragma mark - events  / notifications

- (void)handleAuthenticationSuccess:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRemotePushNotificationReceived:)
                                                 name:PNSManagerDidReceiveRemoteNotification
                                               object:nil];

    if (scheduledNotification != nil)
    {
        [self processRemoteNotification:scheduledNotification];
        scheduledNotification = nil;
    }
    [self requestNotificationsListWithFaultCallback:^(NSError *fault) {}];

#if !TARGET_IPHONE_SIMULATOR
    if (self.pnsTokenRegistered) {
        return;
    }
    
    [self registerPnsDeviceToken:self.pnsDeviceToken
                  resultCallback:nil
                   faultCallback:^(NSError *fault) {
         [Flurry logError:@"registerPnsDeviceToken" message:@"Failed to register for notifications" error:fault];
     }];
#endif
}

- (void)handleLogout:(NSNotification *)notification
{
    // unregister PNS
    self.pnsTokenRegistered = NO;
    scheduledNotification = nil;

    // on logout - removing all persisted notifications...
    [self persistNotifications:nil];

    //clear cached data
    dateArr = nil;
    dateToNotification = nil;
    self.friendRequests = nil;
    self.allFriendRequests = nil;
    
    // Remove the last request date
    [self removeLastNotificationsListRequest];

    // next, reseting badge number to zero...
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;


    //remove notification listener for PNS
    [[NSNotificationCenter defaultCenter] removeObserver:self name:PNSManagerDidReceiveRemoteNotification object:nil];
}

- (void)handleRemotePushNotificationReceived:(NSNotification *)notification
{
    NSLog(@"handleRemotePushNotificationReceived %@",notification);
    [self processRemoteNotification:(NSDictionary *)notification.object];
}

#pragma mark - misc functinos

- (void)processRemoteNotification:(NSDictionary *)remoteNotification
{
    NSString *type = remoteNotification[@"type"];
    
    if ([type isEqualToString:@"dailyPns"]) {
        if ([AuthenticationManager sharedInstance].currentUser != nil) {
        BOOL launchedFromOutsideApp = [(NSNumber *) remoteNotification[@"launchedFromOutsideApp"] boolValue];
            if (!launchedFromOutsideApp) {
                //do nothing
            }
            else {
                
                /*  TO DO: Update when notifications are back
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                UITabBarController *uiTabBarController = [appDelegate.mainViewController customTabBarController];
                [uiTabBarController setSelectedIndex:TAB_BAR_FEED_ITEM_INDEX];
                
                UINavigationController *spayceNavController = uiTabBarController.viewControllers[1];
                SPCFeedViewController *feedViewController = spayceNavController.viewControllers[0];
                [feedViewController showNotifications];
                [feedViewController onLookBackNotificationClick:remoteNotification];
                 */
            }
        }
    }
    
    NSDictionary *pnsDict = remoteNotification[@"aps"];
    NSString *typeStr;
    
    if ([pnsDict respondsToSelector:@selector(objectForKey:)]) {
        typeStr = [pnsDict objectForKey:@"type"];
    }
    
    if ([typeStr isEqualToString:@"Message"]) {
        
        if ([AuthenticationManager sharedInstance].currentUser != nil) {
            [[SPCMessageManager sharedInstance] updateThreadsAfterPNS];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"playPNSSound" object:nil];
        }
    }

    // Refresh Notification List
    [self requestNotificationsListWithFaultCallback:^(NSError *fault) {
    }];
}

- (void)requestNotificationsListWithFaultCallback:(void (^)(NSError *fault))faultCallback {
    if ([AuthenticationManager sharedInstance].currentUser != nil) {
    
        //set-up params for /notification/list call
        NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
        mutableParams[@"deviceType"] = DEVICE_TYPE;
        if ([self lastNotificationsListRequest] != nil)  {
            long long currentTime = (long long)(NSTimeInterval)([[self lastNotificationsListRequest] timeIntervalSince1970] * 1000);
            mutableParams[@"since"] = @(currentTime);
        }

        //persist notifications (only) if needed
        if (self.notifications.count == 0) {
            self.notifications = [NSMutableArray arrayWithArray:[self loadPersistedNotifications]];
            [self sortNotificationsByDate];  //the notifications view controller looks for notifications sorted by date, so this is required here
        }

        if (self.notifications != nil && self.notifications.count > 0) {
            //do nothing
        }
        else {
            [self removeLastNotificationsListRequest];
        }

        __weak typeof(self)weakSelf = self;

        [APIService makeApiCallWithMethodUrl:@"/notification/list"
                              andRequestType:RequestTypeGet
                               andPathParams:nil
                              andQueryParams:mutableParams
                              resultCallback:^(NSObject *result) {
                                  __strong typeof(weakSelf)strongSelf = weakSelf;
                                  if (!strongSelf) {
                                      return;
                                  }

                                  NSArray *src = (NSArray *)result;
                                  //NSLog(@"notification/list result %@",result);
                                  BOOL updatedArray = NO;
                                  BOOL fetchUpdatedRequests = NO;
                                  
                                  for (NSDictionary *notificationSrc in src) {
                                      
                                      SpayceNotification *note = [strongSelf translateNotificationFromDictionary:notificationSrc];
                                      
                                      bool doAdd = YES;

                                      if ([note.notificationType isEqualToString:@"confirmed"]) {
                                          [[NSNotificationCenter defaultCenter] postNotificationName:@"hideRegBanner" object:nil];
                                          doAdd = NO;
                                      }
                                      
                                      for (SpayceNotification *notie in strongSelf.notifications) {
                                          if (notie.notificationId == note.notificationId) {
                                              doAdd = NO;  // item is already in the list...
                                              break;
                                          }
                                      }

                                      int type = [SpayceNotification retrieveNotificationType:note];
                                      
                                      if (type == NOTIFICATION_TYPE_MESSAGE) {
                                          doAdd = NO;
                                      }
                                    
                                      if (type == NOTIFICATION_TYPE_FRIEND_REQUEST) {
                                          doAdd = NO;
                                      }
                                      
                                      if (type == NOTIFICATION_TYPE_FRIEND) {
                                          doAdd = NO;
                                      }
                                      
                                      if (type == NOTIFICATION_TYPE_FRIEND_REQUEST_SENT) {
                                          doAdd = NO;
                                      }
                                      
                                      if (doAdd) {
                                          updatedArray = YES;
                                          [strongSelf.notifications addObject:note];
                                      }
                                  }

                                  if (nil != strongSelf.notifications && strongSelf.notifications.count > 0) {
                                      //only combine, store, persist if any changes happened as a result of api call
                                      if (updatedArray) {
                                          NSLog(@"new notifications in: combine, store and persist");
                                          [strongSelf findStarNotificationsToCombine];
                                          [strongSelf storeLastNotificationsListRequest:[NSDate date]];
                                          [strongSelf persistNotifications:strongSelf.recentNotifsToPersist];
                                          strongSelf.notifications = [NSMutableArray arrayWithArray:strongSelf.recentNotifsToPersist];
                                          [strongSelf sortNotificationsByDate];
                                          
                                      }
                                  }
                                  
                                  self.provideFalseCount = NO; //after fecthing notifications, we revert to correct behavior after our false count adventures
                                  [[NSNotificationCenter defaultCenter] postNotificationName:PNSManagerNotificationsLoaded object:nil];
                                  
                                  
                                  //TODO -- figure out what to do with unhandled friend request when we transition to Following??  just discard 'em?
                                  // That's my vote.  --JR
                                  //update our total count now that we've update friend requests too
                                  strongSelf.totalCount = (int)strongSelf.unreadCount;  //+ (int)strongSelf.unseenFriendRequests;
                                  [strongSelf updateBadgeIcon];
                              }
                               faultCallback:^(NSError * fault) {
                                   if (faultCallback) {
                                       faultCallback(fault);
                                   }
                               }
         ];
    }
}

- (void)scheduleRemoteNotificationOnAuthenticationSuccess:(NSDictionary *)remoteNotification
{
    if ([AuthenticationManager sharedInstance].currentUser != nil)
    {
        [self processRemoteNotification:remoteNotification];
        scheduledNotification = nil;
    }
    else
    {
        scheduledNotification = remoteNotification;
    }
}

- (SpayceNotification *)translateNotificationFromDictionary:(NSDictionary *)src
{
    //NSLog(@"Notification data: %@", src);

    SpayceNotification *res = [[SpayceNotification alloc] init];

    res.hasBeenRead = [(NSNumber *) src[@"hasBeenRead"] boolValue];
    res.notificationDate = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)src[@"createdTime"] doubleValue]/1000];
    res.createdTime = src[@"createdTime"];
    res.notificationId   = [(NSNumber *) src[@"id"] integerValue];
    res.notificationText = src[@"text"];
    res.notificationType = src[@"icon"];
    res.objectId         = [(NSNumber *) src[@"objectId"] integerValue];
    res.param1           = src[@"param1"];
    res.param2           = src[@"param2"];
    res.recipientUserToken = src[@"recipientUserToken"];

    NSDictionary *userDict = (NSDictionary *)src[@"user"];
    res.user = [[User alloc] init];
    res.user.username = userDict[@"name"];
    res.user.userId = [(NSNumber *)userDict[@"userId"] integerValue];
    res.user.lastName = userDict[@"lastName"];
    res.user.firstName = userDict[@"firstName"];
    res.user.imageAsset = [Asset assetFromDictionary:userDict withAssetKey:@"userPhotoAssetInfo" assetIdKey:@"userPhotoAssetId"];
    res.user.userToken = userDict[@"userToken"];
    
    res.memoryParticipants = src[@"memoryParticipants"];
    res.memoryAddressName = src[@"memoryAddressName"];
    
    if ([res.notificationType isEqualToString:@"comment"]) {
        res.commentText = src[@"commentText"];
        
        if (src[@"comment"]) {
            NSLog(@"comment attached to handle tagged users!");
            res.commentDict = src[@"comment"];
        }
        
    }

    //NSLog(@"notification %d has been read ? %@, has user token %@", res.notificationId, (res.hasBeenRead == YES ? @"YES" : @"NO"), res.user.userToken);

    return res;
}

- (void)findStarNotificationsToCombine {
    NSMutableArray *starNotifArray = [[NSMutableArray alloc] init];
    NSMutableSet *memIdsHandled = [[NSMutableSet alloc] init];
    NSMutableSet *memIdsComboed = [[NSMutableSet alloc] init];
    
    // TODO: You can do this using a predicate (it will perform better in most cases)
    // NSPredicate *predicate = [NSPredicate predicateWithFormat:@"notificationType == %@", @"star"];
    // NSArray *filteredArray = [self.notifications filteredArrayUsingPredicate:predicate];
    // Using key-value store (NSDictionary) to compare object containment has O(n) complexity
    // Using for loops has O(n^2) complexity (depending on how many loops we make)
    for (SpayceNotification *notification in self.notifications) {
        if ([notification.notificationType isEqualToString:@"star"]) {
            [starNotifArray addObject:notification];
        }
    }
    
    for (int i = 0; i < starNotifArray.count; i++) {
        SpayceNotification *notification = starNotifArray[i];
        
        NSString *recordIdString = [NSString stringWithFormat:@"%@", @(notification.objectId)];
        
        // Only look for matches if we haven't handled this mem id yet
        if (![memIdsHandled containsObject:recordIdString]) {
            [memIdsHandled addObject:recordIdString];
            
            NSMutableArray *starArray = [[NSMutableArray alloc] init];
            [starArray addObject:notification];
            
            // Loop thru starNotifArray to look for matching mem ids
            for (int j = 0; j < starNotifArray.count; j++) {
                SpayceNotification *note = starNotifArray[j];
                
                if (note.objectId == notification.objectId) {
                    [starArray addObject:note];
                }
            }
        
            if (starArray.count > 1) {
                NSMutableArray *peopleWhoStarred = [[NSMutableArray alloc] init];
                NSMutableSet *participantSet = [[NSMutableSet alloc] init];
                
                for (int j = 0; j < starArray.count; j++) {
                    SpayceNotification *note = (SpayceNotification *)starArray[j];
                    User *tempUser = note.user;
                    
                    // Do not add duplicate users to new participants array
                    if (![participantSet containsObject:tempUser.userToken]) {
                        [participantSet addObject:tempUser.userToken];
                        
                        NSString *firstname = tempUser.firstName;
                        NSString *token = tempUser.userToken;
                        
                        if (firstname.length == 0) {
                            firstname = @"";
                        }
                        
                        NSDictionary *userDict =  @{ @"firstname" : firstname, @"userToken": token };
                        [peopleWhoStarred addObject:userDict];
                    }
                }

                NSArray* orderedParticipants = [[peopleWhoStarred reverseObjectEnumerator] allObjects];
                [participantSet removeAllObjects];
                
                // Create new combo notification with info based on most recent star notification for this mem id
                SpayceNotification *originalNote = (SpayceNotification *)starArray[starArray.count - 1];
                SpayceNotification *comboNote = [self createComboStarNotification:originalNote participants:orderedParticipants];
                [self.notifications addObject:comboNote];
                
                NSString *memoryIdString = [NSString stringWithFormat:@"%@", @(comboNote.objectId)];
                [memIdsComboed addObject:memoryIdString];
            }
        }
    }
    
    // Remove star notifs that were just combined
    NSMutableArray *tempArray = [NSMutableArray arrayWithArray:self.notifications];
    
    for (int i = 0; i < self.notifications.count; i++) {
        SpayceNotification *note = (SpayceNotification *)self.notifications[i];
        if ([note.notificationType isEqualToString:@"star"]) {
            for (NSString *string in memIdsComboed) {
                int tempId = [string intValue];
                if (tempId == note.objectId) {
                    // Set notificationType to discarded and ignore, becasue if we simply delete them locally, then they are regenerated by server
                    note.notificationType = @"discarded";
                    note.hasBeenRead = YES;
                }
            }
        }
    }
    
    self.notifications = [NSMutableArray arrayWithArray:tempArray];
    [self sortNotificationsByDate];
}

- (SpayceNotification *)createComboStarNotification:(SpayceNotification *)originalNotification participants:(NSArray *)participantsArray {
    
    SpayceNotification *res = [[SpayceNotification alloc] init];
    
    res.hasBeenRead = originalNotification.hasBeenRead;
    res.notificationDate = originalNotification.notificationDate;
    res.createdTime = originalNotification.createdTime;
    res.notificationId   = originalNotification.notificationId;
    res.notificationText = originalNotification.notificationText;
    res.notificationType = @"comboStar";
    res.objectId         = originalNotification.objectId;
    res.param1           = originalNotification.param1;
    res.param2           = originalNotification.param2;
    
    res.user = [[User alloc] init];
    res.user.username = originalNotification.user.username;
    res.user.userId = originalNotification.user.userId;
    res.user.lastName = originalNotification.user.username;
    res.user.firstName = originalNotification.user.firstName;
    res.user.imageAsset = originalNotification.user.imageAsset;
    res.user.userToken = originalNotification.user.userToken;
    
    res.memoryParticipants = [NSArray arrayWithArray:participantsArray];
    
    return res;
}

- (void)sortNotificationsByDate
{
    dateToNotification = [[NSMutableDictionary alloc] init];
    NSMutableArray *dateArray = [[NSMutableArray alloc] init];

    for (SpayceNotification *note in self.notifications)
    {
        BOOL addToDateArray = YES;
        
        // do not add any notifications that have been 'combined' or any friend request notifications
        if ([note.notificationType isEqualToString:@"discarded"] || [note.notificationType isEqualToString:@"friendRequest"]) {
            addToDateArray = NO;
        }
        
        //do not add any notifications for the current user unless it's the daily look back PNS
        
        if (note.user.userId == [AuthenticationManager sharedInstance].currentUser.userId) {
            //if (![note.notificationType isEqualToString:@"dailyPns"]) {
                addToDateArray = NO;
            //}
        }
            
        if (addToDateArray) {
        
            NSDate *noteDate = [note.notificationDate dateAtStartOfDay];
            NSMutableArray *sortedByDate = (NSMutableArray *)dateToNotification[noteDate];

            if (nil == sortedByDate) {
                sortedByDate = [[NSMutableArray alloc] init];
                dateToNotification[noteDate] = sortedByDate;
                [dateArray addObject:noteDate]; // only do this once!
                
            }
            [sortedByDate addObject:note];
        }
    }

    NSSortDescriptor *descriptor=[[NSSortDescriptor alloc] initWithKey:@"self" ascending:NO];
    NSArray *descriptors = @[descriptor];
    dateArr = [dateArray sortedArrayUsingDescriptors:descriptors];

    for (NSDate *aDate in dateArr) {
        NSArray *sortedByDate = (NSArray *)dateToNotification[aDate];
        sortedByDate = [sortedByDate sortArrayDescending:sortedByDate basedOnField:@"notificationDate"];
        dateToNotification[aDate] = sortedByDate;
    }

    //
    // when all is said and done, we're ready to send out a message that the notifications have been sorted and
    // are ready to be used...
    //

    [[NSNotificationCenter defaultCenter] postNotificationName:PNSManagerDidSortNotifications object:nil];
}



-(NSArray *)recentNotifsToPersist{
    NSMutableArray *notifsToKeep = [[NSMutableArray alloc] init];
    if (self.notifications.count < 100) {
        notifsToKeep = [NSMutableArray arrayWithArray:self.notifications];
    }
    else {
        NSArray *sortedByDate = [self.notifications sortArrayDescending:self.notifications basedOnField:@"createdTime"];
        for (int i = 0; i < 100; i++) {
            //SpayceNotification *notif = (SpayceNotification *)sortedByDate[i];
            //NSLog(@"keep notif index %i and date %@",i,notif.notificationDate);
            if (sortedByDate.count > i) {
                [notifsToKeep addObject:sortedByDate[i]];
            }
        }
    }
    NSArray *persistNotifs = [NSArray arrayWithArray:notifsToKeep];
    return persistNotifs;
    
}

- (void)deleteFriendRequestNotificationWithUserToken:(NSNotification *)notification {
    NSString *userToken = (NSString *)[notification object];
    NSLog(@"delete friend request with userToken %@ after responding to it",userToken);
    
    NSMutableArray *updatedRequests = [NSMutableArray arrayWithArray:self.friendRequests];
    for (int i = 0; i < self.friendRequests.count; i++) {
        Friend *prevRequests = self.friendRequests[i];
        if ([prevRequests.userToken isEqualToString:userToken]) {
            [updatedRequests removeObjectAtIndex:i];
            break;
        }
    }
    self.friendRequests = [NSMutableArray arrayWithArray:updatedRequests];
    
    //we have responded to a friend request - update our request badges (tab, nav) and our header w/in people
    [[NSNotificationCenter defaultCenter] postNotificationName:kFriendRequestDisplaysNeedUpdating object:nil];
}

- (void)deleteFollowRequestNotificationWithUserToken:(NSNotification *)notification {
    NSString *userToken = (NSString *)[notification object];
    NSLog(@"delete follow request with userToken %@ after responding to it",userToken);
    
    for (int i = 0; i < self.notifications.count; i++) {
        SpayceNotification *notification = self.notifications[i];
        if ([SpayceNotification retrieveNotificationType:notification] == NOTIFICATION_TYPE_FOLLOW_REQUEST && [notification.user.userToken isEqualToString:userToken]) {
            [self.notifications removeObjectAtIndex:i];
        }
    }
    [self persistNotifications:self.recentNotifsToPersist];
    
    //we have responded to a friend request - update our request badges (tab, nav) and our header w/in people
    [[NSNotificationCenter defaultCenter] postNotificationName:kFollowRequestDisplaysNeedUpdating object:nil];
}



#pragma mark - Badge count methods

- (NSInteger)unreadCount {
    NSInteger count = 0;
    
    for (SpayceNotification *notification in self.notifications) {
        if ((!notification.hasBeenRead) && (![notification.notificationType isEqualToString:@"discarded"] && (![notification.notificationType isEqualToString:@"friendRequest"]))){
            
            if (notification.user.userId != [AuthenticationManager sharedInstance].currentUser.userId) {
                count++;
            }
        }
    }
    return count;
}

- (NSInteger)unreadNews {
    
    NSInteger unreadNewsCount = self.unreadCount;
    
    if (self.provideFalseCount) {
        unreadNewsCount = 0;  //it takes a moment or so to mark all news log items as read, so we cheat and temporarily hard set this to 0 until the next time we fetch notifications.
    }
    
    return unreadNewsCount;
}

- (NSInteger)unseenFriendRequests {
   
    NSInteger unseenRequests = 0;

    for (Friend *person in [PNSManager sharedInstance].friendRequests) {
        if (!person.friendRequestHasBeenViewed) {
            unseenRequests++;
        }
    }
    return unseenRequests;
}


#pragma mark - Notifications methods

- (int)getSectionsCount
{
    return (int)dateArr.count;
}

- (NSArray *)getNotificationsForSection:(int)section
{
    if (dateArr.count > 0) {
        return (NSArray *)dateToNotification[dateArr[section]];
    }
    else {
        return nil;
    }
}

- (SpayceNotification *)getNotificationForId:(int)notificationId {
    for (int i = 0; i < self.notifications.count; i++) {
        if (((SpayceNotification *)self.notifications[i]).notificationId == notificationId) {
            return self.notifications[i];
        }
    }
    return nil; 
}

- (void)markAsReadSingleNotification:(SpayceNotification *)notification
{
    NSLog(@"markAsReadSingleNotification with id %li",notification.notificationId);
    [self markAsReadNotifications:@[notification]];
}


-(void)markAsReadFriendRequests {
    
    for (Friend *person in [PNSManager sharedInstance].friendRequests) {
        if (!person.friendRequestHasBeenViewed) {
            person.friendRequestHasBeenViewed = YES;
        }
    }
    
    //we have updated our friend request unseen count - update our request badges (tab, nav) and our header w/in people
    [[NSNotificationCenter defaultCenter] postNotificationName:kFriendRequestDisplaysNeedUpdating object:nil];
    self.totalCount = (int)self.unreadCount + (int)self.unseenFriendRequests;
    [self updateBadgeIcon];
    
}

-(void)markasReadNewsLogOnDelay {
    //handle this on a slight delay to allow news log vc to cleanly dismiss first
    
    self.provideFalseCount = YES;
    self.totalCount = 0; //cheat and set our count to 0 now since are going to mark everything read anyway
    
    [self performSelector:@selector(markasReadNewsLog) withObject:nil afterDelay:1];
}

-(void)markasReadNewsLog {
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    
    //update locally
    for (SpayceNotification *msg in self.notifications)
    {
        if (![msg.notificationType isEqualToString:@"friendRequest"]) {
            msg.hasBeenRead = YES;
            [tempArray addObject:msg];
        }
    }
    
    NSArray *markAsReadArray = [NSArray arrayWithArray:tempArray];
    [self markAsReadNotifications:markAsReadArray];
    
    ///handle badging for app icon
    [self updateBadgeIcon];
}

- (void)markAsReadNotifications:(NSArray *)notificationsList
{
    if (notificationsList.count == 0)
    {
        return;
    }

    NSMutableArray *messageIds = [[NSMutableArray alloc] initWithCapacity:notificationsList.count];
   
    //compile list of read notifs
    for (SpayceNotification *msg in notificationsList)    {
        [messageIds addObject:@(msg.notificationId)];
    }
    
    //NSLog(@"mark as read: %@", messageIds);
    
    __weak typeof(self)weakSelf = self;

    [APIService makeApiCallWithMethodUrl:@"/notification/markRead"
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:@{@"ids" : [CollectionUtils listFromCollection:messageIds withSeparator:@","]}
                          resultCallback:^(NSObject *result) {
                              __strong typeof(weakSelf)strongSelf = weakSelf;
                              if (!strongSelf) {
                                  return;
                              }
                              //NSLog(@"url /notification/markRead result %@",result);
                              [self refreshNotificationDisplay];
                              
                              strongSelf.totalCount = (int)strongSelf.unreadCount;

                              BOOL havePermission = NO; //todo update
                              
                              if (havePermission) {
                                  [[UIApplication sharedApplication] setApplicationIconBadgeNumber:strongSelf.unreadCount];
                              }
                              [strongSelf persistNotifications:strongSelf.recentNotifsToPersist];
                              
                          } faultCallback:^(NSError *fault) {
                               //do nothing
                              //NSLog(@"url /notification/markReadfault %@",fault);
                           }
     ];

}

- (void)markAsReadAllNotifications:(NSArray *)notificationsList {
    /*
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        if (notificationsList.count == 0)
        {
            return;
        }
        NSLog(@"markAllNotifsAsRead");
        
        NSMutableArray *messageIds = [[NSMutableArray alloc] initWithCapacity:notificationsList.count];
        NSMutableArray *actualMessages = [[NSMutableArray alloc] initWithCapacity:notificationsList.count];
        
        for (SpayceNotification *msg in notificationsList)
        {
            if (!msg.hasBeenRead) {
                msg.hasBeenRead = YES;
            }

            [messageIds addObject:@(msg.notificationId)];
            [actualMessages addObject:msg];
            
        }
        
        //NSLog(@"mark as read - notifs with ids: %@",[CollectionUtils listFromCollection:messageIds withSeparator:@","]);
        
        __weak typeof(self)weakSelf = self;
        [APIService makeApiCallWithMethodUrl:@"/notification/markRead"
                              andRequestType:RequestTypePost
                               andPathParams:nil
                              andQueryParams:@{@"ids" : [CollectionUtils listFromCollection:messageIds withSeparator:@","]}
                              resultCallback:^(NSObject *result) {
                                  NSLog(@"mark all read result %@",result);
                                  
                                  __strong typeof(weakSelf)strongSelf = weakSelf;
                                  if (!strongSelf) {
                                      return;
                                  }
                                  
                                  [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                                  [strongSelf persistNotifications:strongSelf.notifications];
                              }
                               faultCallback:^(NSError *fault) {
                                   //do nothing
                               }
         ];
        
         
     });
     */
}

// To clear the notification cache, add 1 to PERSISTED_FORMAT
// This is necessary if e.g. the format of a SpayceNotification changes
// (such as by adding userToken).
// Format history:
// "0": no format.  Notifications not stored under a key.
// 1: Format # and Notifications stored under their own keys.  Notifications
//      now carry "userToken" in their 'user' field; the cache must be
//      regenerated.
// 2: createdTime string added under its own key
// 3: commentText (string), memoryAddressName (string) and memoryParticipants (array) added under their own keys
// 4: notification content changed (asset id --> Asset*)
// 5: no longer using notifications to handle friend requests; need to clear cache to delete these locally
// 6: limiting persistence to max of 40 notificationsf

#define PERSISTED_FORMAT 6
#define PERSISTED_FORMAT_KEY @"PERSISTED_FORMAT"
#define PERSISTED_NOTIFICATIONS_KEY @"PERSISTED_NOTIFICATIONS"

- (NSArray *)loadPersistedNotifications
{
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:[self filePath]];
    
    if (codedData != nil) {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
    NSNumber *format = [unarchiver decodeObjectForKey:PERSISTED_FORMAT_KEY];
    if (!format || [format intValue] != PERSISTED_FORMAT) {
        // clear the persisted cache.  Our format has changed, or
        // some other event requires us to delete the existing cache.
        [self persistNotifications:nil];
        return nil;
    }
    NSArray *res =  (NSArray *)[unarchiver decodeObjectForKey:PERSISTED_NOTIFICATIONS_KEY];
    [unarchiver finishDecoding];
    //NSLog(@"load persistedNotifications %@", res);

    return res;
    }
    else {
        return nil;
    }
}

- (void)persistNotifications:(NSArray *)notificationsToPersist
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (notificationsToPersist == nil)
        {
            NSString *filePath = [strongSelf filePath];
            NSFileManager *fm = [NSFileManager defaultManager];
            BOOL exists = [fm fileExistsAtPath:filePath];
            
            if (exists) {
                //NSLog(@"delete stored notifications!");
                NSError *err = nil;
                [fm removeItemAtPath:filePath error:&err];
                //NSLog(@"clear active copy of notifications!");
                strongSelf.notifications = nil;
            }
        }
        else {
            strongSelf.notifications= [NSMutableArray arrayWithArray:notificationsToPersist];
            NSMutableData *archivedData = [[NSMutableData alloc] init];
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
            [archiver encodeObject:@PERSISTED_FORMAT forKey:PERSISTED_FORMAT_KEY];
            [archiver encodeObject:notificationsToPersist forKey:PERSISTED_NOTIFICATIONS_KEY];
            [archiver finishEncoding];
            [archivedData writeToFile:[strongSelf filePath] atomically:YES];
        }
    });
}

- (NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];

    return [documentsDirectory stringByAppendingPathComponent:NotificationsFileName];
}

- (NSDate *)lastNotificationsListRequest
{
    NSUserDefaults *userData = [NSUserDefaults standardUserDefaults];
    return (NSDate *)[userData objectForKey:NotficationsListRequestTimestamp];
}

- (void)storeLastNotificationsListRequest:(NSDate *)timeOfRequest
{
    NSUserDefaults *userData = [NSUserDefaults standardUserDefaults];
    [userData setObject:timeOfRequest forKey:NotficationsListRequestTimestamp];
    [userData synchronize];
}

- (void)removeLastNotificationsListRequest
{
    NSUserDefaults *userData = [NSUserDefaults standardUserDefaults];
    [userData removeObjectForKey:NotficationsListRequestTimestamp];
    [userData synchronize];
}

#pragma mark - Notification Cleanup

-(void)applyPersonUpdateWithNotification:(NSNotification *)note {
    PersonUpdate *personUpdate = [note object];
    NSArray *persistedNotifs = self.recentNotifsToPersist;
    BOOL changed = [personUpdate applyToArray:persistedNotifs];
    if (changed) {
        [self persistNotifications:persistedNotifs];
        [self performSelector:@selector(refreshNotificationDisplay) withObject:nil afterDelay:.1];
    }
}

-(void)refreshNotificationDisplay {
    //NSLog(@"refreshNotificationDisplay");
    [[NSNotificationCenter defaultCenter] postNotificationName:kFriendRequestResponseCompleteRefreshNotificationDisplay object:nil];
}

#pragma mark - App Icon Badging

- (BOOL)checkNotificationType:(UIUserNotificationType)type
{
    UIUserNotificationSettings *currentSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    
    return (currentSettings.types & type);
}
-(void)updateBadgeIcon {
    BOOL havePermission = NO;
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        //iOS 8
        if ([self checkNotificationType:UIUserNotificationTypeBadge]) {
            havePermission = YES;
        }
    }
    else {
        //iOS 7
        havePermission = YES;
    }
    
    if (havePermission) {
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:self.totalCount];
    }
}


@end
