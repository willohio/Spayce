//
//  SPCFriendPicker.m
//  Spayce
//
//  Created by Christopher Taylor on 6/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFriendPicker.h"

// Model
#import "Friend.h"

// View
#import "AddFriendsCollectionViewCell.h"

// Manager
#import "MeetManager.h"

static NSString *CollectionViewCellIdentifier = @"FriendCell";
static NSString *LoadingCellIdentifier = @"LoadingCell";

@interface SPCFriendPicker () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray *followersArray;
@property (nonatomic, strong) NSString *nextPageKey;
@property (nonatomic, strong) NSString *currentSearchTerm;
@property (nonatomic, assign) BOOL isFetching;
@property (nonatomic, assign) NSInteger fetchNumber;

@property (nonatomic, strong) NSString *searchFilter;
@property (nonatomic, strong) NSString *matchFilter;

@end

@implementation SPCFriendPicker

#pragma mark - Object lifecycle

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        UICollectionViewFlowLayout *layout=[[UICollectionViewFlowLayout alloc] init];
        layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
        layout.minimumInteritemSpacing = 5;
        layout.minimumLineSpacing = 5;
        CGRect collectionFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:collectionFrame collectionViewLayout:layout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.allowsMultipleSelection = YES;
        [self addSubview:_collectionView];
        
        [_collectionView registerClass:[AddFriendsCollectionViewCell class] forCellWithReuseIdentifier:CollectionViewCellIdentifier];
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:LoadingCellIdentifier];
        
        [self fetchFollowers];
    }
    return self;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.followersArray.count + (self.nextPageKey == nil ? 0 : 1);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView customCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AddFriendsCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CollectionViewCellIdentifier forIndexPath:indexPath];
    
    Friend *tempFriend = self.followersArray[indexPath.row];
    [cell configureWithFriend:tempFriend];
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView loadingCellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
    UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)[cell viewWithTag:111];
    if (indicatorView) {
        [indicatorView startAnimating];
    } else {
        cell.backgroundColor = [UIColor clearColor];
        
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicatorView.tag = 111;
        indicatorView.color = [UIColor grayColor];
        indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:indicatorView];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:indicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:cell.contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        
        [indicatorView startAnimating];
    }
    return cell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item + 6 >= self.followersArray.count && self.nextPageKey) {
        [self fetchMoreFollowers];
    }
    
    if (indexPath.item < self.followersArray.count) {
        return [self collectionView:collectionView customCellForItemAtIndexPath:indexPath];
    } else {
        return [self collectionView:collectionView loadingCellForItemAtIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    
    // 3.5" & 4" screens
    float itemWidth = 100;
    float itemHeight = 110;
    
    //4.7"
    if ([UIScreen mainScreen].bounds.size.width == 375) {
        itemWidth = 118;
        itemHeight = 110;
    }
    
    //5"
    if ([UIScreen mainScreen].bounds.size.width > 375) {
        itemWidth = 131;
        itemHeight = 157;
    }
    
    if (indexPath.item < self.followersArray.count) {
        return CGSizeMake(itemWidth, itemHeight);
    } else {
        int cellSpan = 3 - (indexPath.item % 3);
        return CGSizeMake(cellSpan * itemWidth, itemHeight);
    }
    
    // loading spinner...
    return CGSizeMake(CGRectGetWidth(self.collectionView.frame), 80);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    if (indexPath.item < self.followersArray.count) {
        Friend *tempFriend = self.followersArray[indexPath.item];
        [self.delegate selectedFriend:tempFriend];
    }
}

#pragma mark - Private

- (void)pickFriend:(Friend *)f {
    [self.delegate selectedFriend:f];
}

- (void)setIsSearching:(BOOL)isSearching {
    _isSearching = isSearching;
    if (!isSearching) {
        self.matchFilter = nil;
        [self filterContentForSearchText:nil];
    }
}

- (void)updateFilterString:(NSString *)searchStr {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(filterContentForSearchText:) withObject:searchStr afterDelay:0.5];
}

- (void)matchFilterString:(NSString *)searchStr {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if ([searchStr isEqualToString:self.currentSearchTerm] && self.followersArray.count > 0) {
        [self.delegate selectedFriend:((Friend *)self.followersArray[0])];
    } else {
        self.matchFilter = searchStr;
        [self filterContentForSearchText:searchStr];
    }
}


- (void)filterContentForSearchText:(NSString *)searchText {
    self.searchFilter = searchText;
    
    if (!self.searchFilter || self.searchFilter.length == 0) {
        // no search...
        // TODO restore the original first page?
        if (self.currentSearchTerm && self.currentSearchTerm.length > 0) {
            self.nextPageKey = nil;
            self.isFetching = NO;
            [self fetchFollowers];
        }
    } else {
        // Perform this search
        if (!self.currentSearchTerm || self.currentSearchTerm.length == 0 || ![self.currentSearchTerm isEqualToString:self.searchFilter]) {
            self.nextPageKey = nil;
            self.isFetching = NO;
            [self fetchFollowers];
        }
    }
}



-(void)fetchFollowers {
    
    if (self.isFetching) {
        return;
    }
    
    self.fetchNumber++;
    self.isFetching = YES;
    
    __weak typeof(self)weakSelf = self;
    NSString *partialSearch = self.searchFilter;
    NSInteger fetchNumber = self.fetchNumber;
    [MeetManager fetchFollowersWithPartialSearch:partialSearch pageKey:nil completionHandler:^(NSArray *followers, NSString *nextPageKey) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        
        if (strongSelf.matchFilter && [strongSelf.matchFilter isEqualToString:partialSearch] && followers.count > 0) {
            [strongSelf.delegate selectedFriend:((Friend *)followers[0])];
        }
        
        strongSelf.followersArray = followers;
        strongSelf.nextPageKey = nextPageKey;
        strongSelf.currentSearchTerm = partialSearch;
        strongSelf.isFetching = NO;
        [strongSelf reloadData];
        
    } errorHandler:^(NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        strongSelf.isFetching = NO;
    }];
}

-(void)fetchMoreFollowers {
    if (self.isFetching || !self.nextPageKey) {
        return;
    }
    
    self.isFetching = YES;
    
    __weak typeof(self)weakSelf = self;
    NSString *partialSearch = self.currentSearchTerm;
    NSInteger fetchNumber = self.fetchNumber;
    [MeetManager fetchFollowersWithPartialSearch:partialSearch pageKey:self.nextPageKey completionHandler:^(NSArray *followers, NSString *nextPageKey) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        
        strongSelf.followersArray = [self.followersArray arrayByAddingObjectsFromArray:followers];
        strongSelf.nextPageKey = nextPageKey;
        strongSelf.isFetching = NO;
        [strongSelf reloadData];
        
    } errorHandler:^(NSError *error) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf || strongSelf.fetchNumber != fetchNumber) {
            return ;
        }
        strongSelf.isFetching = NO;
    }];
}


- (void)reloadData {
    if (self.followersArray.count > 0 || !self.isFetching) {
        [self.collectionView reloadData];
    }
}


@end
