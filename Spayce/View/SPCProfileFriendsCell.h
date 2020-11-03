//
//  SPCProfileFriendsCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 8/23/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileFriendsCell : UITableViewCell

@property (nonatomic, strong, readonly) UICollectionView *collectionView;

- (void)configureWithFriendsCount:(NSInteger)friendsCount mutualFriendsCount:(NSInteger)mutualFriendsCount showsMutualFriends:(BOOL)showsMutualFriends;

@end
