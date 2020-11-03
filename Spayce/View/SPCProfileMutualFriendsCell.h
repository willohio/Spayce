//
//  SPCProfileMutualFriendsCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-22.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileMutualFriendsCell : UITableViewCell

- (void)configureWithMutualFriends:(NSArray *)mutualFriends cellStyle:(SPCCellStyle)cellStyle;
- (void)configureWithMutualFriendCount:(NSInteger)mutualFriendCount mutualFriends:(NSArray *)mutualFriends cellStyle:(SPCCellStyle)cellStyle;

@end
