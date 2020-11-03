//
//  SPCProfileFollowCell.h
//  Spayce
//
//  Created by Pavel Dusatko on 8/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileFollowCell : UITableViewCell

- (void)configureWithFollowersCount:(NSInteger)followersCount followingCount:(NSInteger)followingCount;
- (void)configureWithFollowersTarget:(id)target action:(SEL)action;
- (void)configureWithFollowingTarget:(id)target action:(SEL)action;

@end
