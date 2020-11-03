//
//  SPCProfileInfoDataSource.m
//  Spayce
//
//  Created by Howard Cantrell Jr on 5/9/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCProfileInfoDataSource.h"

// Model
#import "Asset.h"
#import "Friend.h"
#import "ProfileDetail.h"
#import "UserProfile.h"

// View
#import "SPCSegmentedControlHeaderView.h"
#import "SPCProfileStarPowerCell.h"
#import "SPCProfileFriendsCell.h"
#import "SPCProfileFriendCell.h"
#import "SPCProfileTerritoriesCell.h"

// Utilities
#import "APIUtils.h"

NSString * SPCProfileInfoStarPowerCell = @"SPCProfileInfoStarPowerCell";
NSString * SPCProfileInfoFriendsCell = @"SPCProfileInfoFriendsCell";
NSString * SPCProfileInfoFriendCell = @"SPCProfileInfoFriendCell";
NSString * SPCProfileInfoTerritoriesCell = @"SPCProfileInfoTerritoriesCell";

NSString * SPCProfileDidSelectFriendNotification = @"SPCProfileDidSelectFriendNotification";

@interface SPCProfileInfoDataSource () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic) NSInteger starPowerCellIndex;
@property (nonatomic) NSInteger friendsCellIndex;
@property (nonatomic) NSInteger territoriesCellIndex;

@end

@implementation SPCProfileInfoDataSource

#pragma mark - Object lifecycle

- (id)init {
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

#pragma mark - Accessors

- (void)setProfile:(UserProfile *)profile {
    _profile = profile;
    
    [self initialize];
    [self reloadData];
}

#pragma mark - Private

- (void)initialize {
    self.starPowerCellIndex = -1;
    self.friendsCellIndex = -1;
    self.territoriesCellIndex = -1;
}

- (void)reloadData {
    NSInteger row = 0;
    
    // Star power
    self.starPowerCellIndex = row++;
    // Friends
    if (self.profile.profileDetail.mutualFriendsCountExcludingSpayceProfile > 0) {
        self.friendsCellIndex = row++;
    }
    // Territories
    if (self.profile.profileDetail.affiliatedCities.count > 0 ||
        self.profile.profileDetail.affiliatedNeighborhoods.count > 0) {
        self.territoriesCellIndex = row;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRowsInSection = 3;
    if (self.friendsCellIndex < 0) {
        numberOfRowsInSection--;
    }
    if (self.territoriesCellIndex < 0) {
        numberOfRowsInSection--;
    }
    return numberOfRowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.starPowerCellIndex) {
        SPCProfileStarPowerCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileInfoStarPowerCell forIndexPath:indexPath];
        [cell configureWithStarCount:self.profile.profileDetail.starCount];
        return cell;
    }
    else if (indexPath.row == self.friendsCellIndex) {
        SPCProfileFriendsCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileInfoFriendsCell forIndexPath:indexPath];
        [cell.collectionView registerClass:[SPCProfileFriendCell class] forCellWithReuseIdentifier:SPCProfileInfoFriendCell];
        cell.collectionView.delegate = self;
        cell.collectionView.dataSource = self;
        [cell.collectionView reloadData];
        [cell configureWithFriendsCount:self.profile.profileDetail.friendsCount mutualFriendsCount:self.profile.profileDetail.mutualFriendsCount showsMutualFriends:!self.profile.isCurrentUser];
        return cell;
    }
    else if (indexPath.row == self.territoriesCellIndex) {
        SPCProfileTerritoriesCell *cell = [tableView dequeueReusableCellWithIdentifier:SPCProfileInfoTerritoriesCell forIndexPath:indexPath];
        [cell configureWithCities:self.profile.profileDetail.affiliatedCities neighborhoods:self.profile.profileDetail.affiliatedNeighborhoods];
        return cell;
    }
    else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.starPowerCellIndex) {
        return 130;
    }
    else if (indexPath.row == self.friendsCellIndex) {
        return 120;
    }
    else if (indexPath.row == self.territoriesCellIndex) {
        if (self.profile.profileDetail.affiliatedCities.count > 1 && self.profile.profileDetail.affiliatedNeighborhoods.count > 1) {
            return 209;
        }
        else {
            return 144;
        }
    }
    else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SPCSegmentedControlHeaderView *view = [[SPCSegmentedControlHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(tableView.frame), [self tableView:tableView heightForHeaderInSection:section])];
    view.backgroundColor = [UIColor colorWithWhite:246.0f/255.0f alpha:1.0f];
    view.defaultHeight = 44.0;
    view.bannerHeight = 60.0;
    
    DZNSegmentedControl *segmentedControl = [[DZNSegmentedControl alloc] initWithItems:self.segmentItems];
    segmentedControl.frame = view.bounds;
    segmentedControl.contentInsets = UIEdgeInsetsMake(0.0, 30.0, 0.0, 30.0);
    segmentedControl.tintColor = [UIColor colorWithRed:106.0f/255.0f green:179.0f/255.0f blue:249.0f/255.0f alpha:1.0f];
    segmentedControl.delegate = self;
    segmentedControl.selectedSegmentIndex = self.selectedSegmentIndex;
    segmentedControl.height = 45.0;
    segmentedControl.selectionIndicatorOffset = 7;
    [segmentedControl addTarget:self action:@selector(selectedSegment:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:segmentedControl];
    
    self.segmentedControl = segmentedControl;
    
    [self updateSegmentedControlWithScrollView:tableView];

    return view;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(62, 62);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 12, 0, 12);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 18;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray *friends = self.profile.profileDetail.mutualFriendProfiles;
    if (friends) {
        return friends.count;
    }
    return 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPCProfileFriendCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:SPCProfileInfoFriendCell forIndexPath:indexPath];
    Person *friend = self.profile.profileDetail.mutualFriendProfiles[indexPath.row];
    
    NSURL *url = [NSURL URLWithString:[APIUtils imageUrlStringForUrlString:friend.imageAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailLarge]];
    
    [cell configureWithName:friend.firstname url:url];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Person *friend = self.profile.profileDetail.mutualFriendProfiles[indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:SPCProfileDidSelectFriendNotification object:self userInfo:@{ @"selectedFriend": friend }];
}

#pragma mark - Actions

- (void)selectedSegment:(id)sender {
    DZNSegmentedControl *segmentedControl = (DZNSegmentedControl *)sender;
    if ([self.delegate respondsToSelector:@selector(segmentedControlValueChanged:)]) {
        [self.delegate segmentedControlValueChanged:segmentedControl.selectedSegmentIndex];
    }
}

@end
