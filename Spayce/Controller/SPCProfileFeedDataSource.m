//
//  SPCProfileFeedDataSource.m
//  Spayce
//
//  Created by William Santiago on 8/29/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileFeedDataSource.h"

// Model
#import "Location.h"
#import "Person.h"
#import "ProfileDetail.h"
#import "UserProfile.h"
#import "SpayceNotification.h"
#import "Asset.h"
#import "User.h"

// View
#import "SPCProfileBioCell.h"
#import "SPCProfileConnectionsCell.h"
#import "SPCProfileFriendActionCell.h"
#import "SPCProfileMapsCell.h"
#import "SPCProfileMutualFriendsCell.h"
#import "SPCNewsLogCell.h"
#import "SPCProfileSegmentedControlCell.h"
#import "SPCProfilePlaceholderCell.h"
#import "SPCRelationshipDetailCell.h"
#import "SPCMemoryGridCollectionView.h"

// Category
#import "UIAlertView+SPCAdditions.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "MeetManager.h"
#import "PNSManager.h"

// Utilties
#import "APIUtils.h"

NSString * SPCProfileReload = @"SPCProfileReload";

NSString * SPCProfileNewsCellIdentifier = @"SPCProfileNewsCellIdentifier";
NSString * SPCProfileFriendActionCellIdentifier = @"SPCProfileFriendActionCellIdentifier";
NSString * SPCProfileMutualFriendsCellIdentifier = @"SPCProfileMutualFriendsCellIdentifier";
NSString * SPCProfileConnectionsCellIdentifier = @"SPCProfileConnectionsCellIdentifier";
NSString * SPCProfileBioCellIdentifier = @"SPCProfileBioCellIdentifier";
NSString * SPCProfileMapsCellIdentifier = @"SPCProfileMapsCellIdentifier";
NSString * SPCSegmentedControlCellIdentifier = @"SPCSegmentedControlCellIdentifier";
NSString * SPCProfilePlaceholderCellIdentifier = @"SPCProfilePlaceholderCellIdentifier";

NSString * SPCProfileDidSelectNewsNotification = @"SPCProfileDidSelectNewsNotification";
NSString * SPCProfileDidSelectMutualFriendsNotification = @"SPCProfileDidSelectMutualFriendsNotification";
NSString * SPCProfileDidSelectBioUpdateNotification = @"SPCProfileDidSelectBioUpdateNotification";
NSString * SPCProfileDidSelectCityNotification = @"SPCProfileDidSelectCityNotification";
NSString * SPCProfileDidSelectNeighborhoodNotification = @"SPCProfileDidSelectNeighborhoodNotification";
NSString * SPCProfileDidAddNewCellNotification = @"SPCProfileDidAddNewCellNotification";

NSString * SPCProfileDidSelectFollowNotification = @"SPCProfileDidSelectFollowNotification";
NSString * SPCProfileDidSelectUnfollowNotification = @"SPCProfileDidSelectUnfollowNotification";
NSString * SPCProfileDidSelectAcceptFollowNotification = @"SPCProfileDidSelectAcceptFollowNotification";

@interface SPCProfileFeedDataSource ()

@property (nonatomic) NSInteger friendActionIndex;
@property (nonatomic) NSInteger relationshipDetailIndex;
@property (nonatomic) NSInteger bioIndex;
@property (nonatomic) NSInteger mapIndex;
@property (nonatomic) NSInteger segmentedSortIndex;
@property (nonatomic) NSInteger profileLockedIndex;
@property (nonatomic) NSInteger noMemoriesPlaceholderIndex;
@property (nonatomic) BOOL profileLocked;
@property (weak, nonatomic) SPCProfileSegmentedControlCell *segmentedControlCell;

@end

@implementation SPCProfileFeedDataSource

#pragma mark - Object lifecycle

- (void)dealloc {
    @try {
        [self removeObserver:self forKeyPath:@"hasLoaded"];
        [self removeObserver:self forKeyPath:@"hasLoadedProfile"];
        
        [[PNSManager sharedInstance] removeObserver:self forKeyPath:@"totalCount"];
    }
    @catch (NSException *exception) {}
}

- (id)init {
    self = [super init];
    if (self) {
        [self addObserver:self forKeyPath:@"hasLoaded" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"hasLoadedProfile" options:NSKeyValueObservingOptionNew context:nil];
        
        [[PNSManager sharedInstance] addObserver:self forKeyPath:@"totalCount" options:NSKeyValueObservingOptionInitial context:nil];
    }
    return self;
}

#pragma mark - Accessors

- (SpayceNotification *)mostRecentNotification {
    if (!_mostRecentNotification) {
        NSArray *recentNotifs = [[PNSManager sharedInstance] getNotificationsForSection:0];
        if (recentNotifs.count > 0) {
            _mostRecentNotification = [recentNotifs objectAtIndex:0];
        }
    }
    return _mostRecentNotification;
}

- (void)setFeed:(NSArray *)feed {
    [super setFeed:feed];
    
    [self.memoryGridCollectionView addMemories:feed andAddToTop:NO];
}

- (void)setFeed:(NSArray *)feed andAddToTop:(BOOL)addToTop {
    [super setFeed:feed];
    
    [self.memoryGridCollectionView addMemories:feed andAddToTop:addToTop];
}

#pragma mark - Private

- (void)reloadData {
    self.friendActionIndex = -1;
    self.relationshipDetailIndex = -1;
    self.bioIndex = -1;
    self.mapIndex = -1;
    self.segmentedSortIndex = -1;
    self.profileLockedIndex = -1;
    self.noMemoriesPlaceholderIndex = -1;
    
    // Is this profile locked to the current user?
    self.profileLocked = self.profile.profileDetail.profileLocked;
    // If the user is a friend or the current user, the profile is NOT locked to the current user
    if (self.profile.isCurrentUser || self.profile.isFollowedByUser || [AuthenticationManager sharedInstance].currentUser.isAdmin) {
        self.profileLocked = NO;
    }
    
    NSInteger row = 0;
    
    // Friend action
    if (!self.profile.isCurrentUser) {
        BOOL followingStatusIsNotUnknownOrBlocked = FollowingStatusUnknown != self.profile.profileDetail.followingStatus && FollowingStatusBlocked != self.profile.profileDetail.followingStatus;
        BOOL followerStatusIsNotUnknownOrBlocked = FollowingStatusUnknown != self.profile.profileDetail.followerStatus && FollowingStatusBlocked != self.profile.profileDetail.followerStatus;
        
        if (self.profile.profileUserId > 0 && followingStatusIsNotUnknownOrBlocked && followerStatusIsNotUnknownOrBlocked) {
            self.friendActionIndex = row++;
        }
    }
    
    // Relationship detail
    if (FollowingStatusFollowing == self.profile.profileDetail.followerStatus || (FollowingStatusFollowing == self.profile.profileDetail.followingStatus && FollowingStatusRequested == self.profile.profileDetail.followerStatus)) {
        self.relationshipDetailIndex = row++;
    }

    // Bio
    if (self.profile.profileDetail.statusMessage.length > 0) {
        self.bioIndex = row++;
    }
    // Maps
    if (self.profile.profileDetail.affiliatedCities.count > 0) {
        if (self.profile.profileUserId > 0) {
            self.mapIndex = row++;
        }
    }
    // Segmented Control / 'No Moments yet'
    if (!self.profileLocked) {
        if (self.hasLoaded) {
            self.segmentedSortIndex = row++;
            
            if (0 == self.feed.count) {
                self.noMemoriesPlaceholderIndex = row++;
            }
        }
    } else {
        self.profileLockedIndex = row++;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ((self.hasLoaded && 0 < self.feed.count) || self.hasLoadedProfile) {
        return 2;
    }
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.hasLoaded || self.hasLoadedProfile) {
        if (section == 0) {
            NSInteger numberOfRowsInSection = 7;
            if (self.friendActionIndex < 0) {
                numberOfRowsInSection--;
            }
            if (self.relationshipDetailIndex < 0) {
                numberOfRowsInSection--;
            }
            if (self.profileLockedIndex < 0) {
                numberOfRowsInSection--;
            }
            if (self.bioIndex < 0) {
                numberOfRowsInSection--;
            }
            if (self.mapIndex < 0) {
                numberOfRowsInSection--;
            }
            if (self.segmentedSortIndex < 0) {
                numberOfRowsInSection--;
            }
            if (self.noMemoriesPlaceholderIndex < 0) {
                numberOfRowsInSection--;
            }
            return numberOfRowsInSection;
        }
    }
    
    // Memory section
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (BOOL)isMemoryAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section != 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.hasLoaded || self.hasLoadedProfile) {
        if (![self isMemoryAtIndexPath:indexPath]) {
            if (indexPath.row == self.friendActionIndex) {
                SPCProfileFriendActionCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileFriendActionCellIdentifier forIndexPath:indexPath];
                SPCCellStyle cellStyle = SPCCellStyleSingle;
                [cell configureWithDataSource:self cellStyle:cellStyle name:self.profile.profileDetail.firstname followingStatus:self.profile.profileDetail.followingStatus followerStatus:self.profile.profileDetail.followerStatus isUserCeleb:self.profile.profileDetail.isCeleb isUserProfileLocked:self.profile.profileDetail.profileLocked];
                
                if (self.profile.profileDetail.followerStatus == FollowingStatusFollowing) {
                    [cell.btnLeft addTarget:self action:@selector(chatWithUser:) forControlEvents:UIControlEventTouchDown];
                }
                
                return cell;
            } else if (indexPath.row == self.relationshipDetailIndex) {
                SPCRelationshipDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCRelationshipDetailCellIdentifier forIndexPath:indexPath];
                [cell configureWithFollowingStatus:self.profile.profileDetail.followingStatus andFollowerStatus:self.profile.profileDetail.followerStatus];
                return cell;
            } else if (indexPath.row == self.profileLockedIndex) {
                SPCProfilePlaceholderCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfilePlaceholderCellIdentifier forIndexPath:indexPath];
                [cell configureWithImage:[UIImage imageNamed:@"profile-locked"] andText:@"This user is private."];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            } else if (indexPath.row == self.bioIndex) {
                SPCProfileBioCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileBioCellIdentifier forIndexPath:indexPath];
                [cell configureWithDataSource:self text:self.profile.profileDetail.statusMessage andCanEditProfile:self.profile.isCurrentUser];
                [cell.btnBioEdit addTarget:self action:@selector(showBioUpdate:) forControlEvents:UIControlEventTouchUpInside];
                return cell;
            } else if (indexPath.row == self.mapIndex) {
                SPCProfileMapsCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileMapsCellIdentifier forIndexPath:indexPath];
                [cell configureWithDataSource:self cities:self.profile.profileDetail.affiliatedCities neightborhoods:self.profile.profileDetail.affiliatedNeighborhoods name:self.profile.profileDetail.firstname isCurrentUser:self.profile.isCurrentUser];
                return cell;
            } else if (indexPath.row == self.segmentedSortIndex) {
                SPCProfileSegmentedControlCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileSegmentedControlCellIdentifier forIndexPath:indexPath];
                [cell configureWithNumberOfMemories:self.profile.profileDetail.memCount];
                if ([self.delegate respondsToSelector:@selector(tappedMemoryCellDisplayType:onProfileSegmentedControl:)]) {
                    cell.delegate = (id<SPCProfileSegmentedControllCellDelegate>)self.delegate;
                }
                self.segmentedControlCell = cell;
                return cell;
            } else if (indexPath.row == self.noMemoriesPlaceholderIndex) {
                SPCProfilePlaceholderCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfilePlaceholderCellIdentifier forIndexPath:indexPath];
                [cell configureWithImage:[UIImage imageNamed:@"placeholder-no-moments"] andText:@"No Moments yet."];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                return cell;
            }
        }
    }
    
    // Section 1 (2nd section)
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.hasLoaded || self.hasLoadedProfile) {
        if (indexPath.section == 0) {
            if (indexPath.row == self.friendActionIndex) {
                return 50;
            }
            else if (indexPath.row == self.relationshipDetailIndex) {
                return 20;
            }
            else if (indexPath.row == self.profileLockedIndex) {
                return 260;
            }
            else if (indexPath.row == self.bioIndex) {
                CGFloat contentHeight = [SPCProfileBioCell heightOfCellWithText:self.profile.profileDetail.statusMessage andTableWidth:self.tableViewWidth];
                
                // Extra padding only if there is no map cell or if this is the SpayceTeam profile
                CGFloat mapOrSpayceTeamAdjustment = 0.0f;
                if (0 > self.mapIndex && 0 < self.profile.profileUserId) {
                    mapOrSpayceTeamAdjustment = 10.0f; // Add 10pt, because this is the bottom cell in the section
                } else if (0 >= self.profile.profileUserId) {
                    mapOrSpayceTeamAdjustment = 20.0f; // Add 20pt, because this is the top and bottom cell
                }
                
                return contentHeight + mapOrSpayceTeamAdjustment;
            }
            else if (indexPath.row == self.mapIndex) {
                return 35.0f;
            }
            else if (indexPath.row == self.segmentedSortIndex) {
                return 90.0f/750.0f * self.tableViewWidth; // 90pt height on a 750pt-wide psd
            }
            else if (indexPath.row == self.noMemoriesPlaceholderIndex) {
                return 260.0f;
            }
        } else {
            if (self.feed.count == 0 && self.hasLoaded) {
                return 0;
            }
        }
    }
    
    // Section 1 (memories)
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Data Consistency

- (void)addMemory:(Memory *)memory {
    // Grab our current recent feed. Must not be nil, so that we can add an object to it.
    NSMutableArray *currentFeed = nil == self.feed ? [NSMutableArray array] : [NSMutableArray arrayWithArray:self.feed];
    
    // throw it on top!
    [currentFeed insertObject:memory atIndex:0];
    NSArray *finalFeed = [NSArray arrayWithArray:currentFeed];
    [self setFeed:finalFeed andAddToTop:YES];
}

- (void)removeMemory:(Memory *)memory {
    __block Memory *memoryToDelete = nil;
    
    if (nil != self.feed) {
        NSMutableArray *currentFeed = [NSMutableArray arrayWithArray:self.feed];
        [currentFeed enumerateObjectsUsingBlock:^(Memory *obj, NSUInteger idx, BOOL *stop) {
            if (obj.recordID == memory.recordID) {
                memoryToDelete = obj;
                *stop = YES;
            }
        }];
        [currentFeed removeObject:memoryToDelete];
        self.feed = [NSArray arrayWithArray:currentFeed];
        [self.memoryGridCollectionView removeMemory:memoryToDelete];
        memoryToDelete = nil;
    }
}

#pragma mark - Actions

-(void)chatWithUser:(id)sender {
     if (self.profile.profileDetail.followerStatus == FollowingStatusFollowing) {
         [self.delegate showChat];
     }
}


- (void)follow:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectFollowNotification object:self];
}

- (void)unfollow:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectUnfollowNotification object:self];
}

- (void)acceptFollowerRequest:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectAcceptFollowNotification object:self];
}


- (void)showBioUpdate:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectBioUpdateNotification object:self];
}

- (void)showCity:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectCityNotification object:self userInfo:@{ @"city": self.profile.profileDetail.affiliatedCities[0] }];
}

- (void)showNeighborhood:(id)sender {
     [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectNeighborhoodNotification object:self userInfo:@{ @"neighborhood": self.profile.profileDetail.affiliatedNeighborhoods[0] }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self) {
        if ([keyPath isEqualToString:@"hasLoaded"] || [keyPath isEqualToString:@"hasLoadedProfile"]) {
            BOOL hasLoaded = [[object valueForKeyPath:keyPath] boolValue];
            if (hasLoaded) {
                [self reloadData];
            }
        }
    }
    else if (object == [PNSManager sharedInstance]) {
        if ([keyPath isEqualToString:@"totalCount"])  {
            NSArray *recentNotifs = [[PNSManager sharedInstance] getNotificationsForSection:0];
            BOOL needsReload = NO;
            
            if (recentNotifs.count > 0) {
                if (!self.mostRecentNotification) {
                    needsReload = YES;
                }
                self.mostRecentNotification = [recentNotifs objectAtIndex:0];
            }
            if (needsReload) {
                [self reloadData];
            }
        }
    }
}

@end
