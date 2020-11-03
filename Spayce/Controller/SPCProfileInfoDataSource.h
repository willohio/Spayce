//
//  SPCProfileInfoDataSource.h
//  Spayce
//
//  Created by Howard Cantrell Jr on 5/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCBaseDataSource.h"

@class UserProfile;

extern NSString * SPCProfileInfoStarPowerCell;
extern NSString * SPCProfileInfoFriendsCell;
extern NSString * SPCProfileInfoFriendCell;
extern NSString * SPCProfileInfoTerritoriesCell;

extern NSString * SPCProfileDidSelectFriendNotification;

@interface SPCProfileInfoDataSource : SPCBaseDataSource

@property (nonatomic, strong) UserProfile *profile;

@end
