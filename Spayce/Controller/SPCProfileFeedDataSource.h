//
//  SPCProfileFeedDataSource.h
//  Spayce
//
//  Created by Pavel Dusatko on 8/29/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTileSupportingDataSource.h"
#import "Enums.h"

extern NSString * SPCProfileReload;

extern NSString * SPCProfileNewsCellIdentifier;
extern NSString * SPCProfileFriendActionCellIdentifier;
extern NSString * SPCProfileMutualFriendsCellIdentifier;
extern NSString * SPCProfileConnectionsCellIdentifier;
extern NSString * SPCProfileBioCellIdentifier;
extern NSString * SPCProfileMapsCellIdentifier;
extern NSString * SPCSegmentedControlCellIdentifier;
extern NSString * SPCProfilePlaceholderCellIdentifier;

extern NSString * SPCProfileDidSelectNewsNotification;
extern NSString * SPCProfileDidSelectMutualFriendsNotification;
extern NSString * SPCProfileDidSelectBioUpdateNotification;
extern NSString * SPCProfileDidSelectCityNotification;
extern NSString * SPCProfileDidSelectNeighborhoodNotification;
extern NSString * SPCProfileDidAddNewCellNotification;

extern NSString * SPCProfileDidSelectFollowNotification;
extern NSString * SPCProfileDidSelectUnfollowNotification;
extern NSString * SPCProfileDidSelectAcceptFollowNotification;

@class UserProfile;
@class SPCMemoryGridCollectionView;

@interface SPCProfileFeedDataSource : SPCTileSupportingDataSource

@property (nonatomic, strong) UserProfile *profile;
@property (nonatomic, strong) SpayceNotification *mostRecentNotification;

@property (nonatomic, assign) BOOL hasLoadedProfile;

- (BOOL)isMemoryAtIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;

- (void)follow:(id)sender;
- (void)unfollow:(id)sender;

- (void)addMemory:(Memory *)memory;
- (void)removeMemory:(Memory *)memory;

@end
