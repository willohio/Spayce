//
//  SPCProfileFriendActionCell.h
//  Spayce
//
//  Created by William Santiago on 2014-10-24.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCProfileFriendActionCell : UITableViewCell

// Buttons
@property (nonatomic, strong) UIButton *btnLarge; // Visible when we have a single button
@property (nonatomic, strong) UIButton *btnLeft; // Visible when we have two buttons
@property (nonatomic, strong) UIButton *btnRight; // Visible when we have two buttons

- (void)configureWithDataSource:(id)dataSource cellStyle:(SPCCellStyle)cellStyle name:(NSString *)name followingStatus:(FollowingStatus)followingStatus followerStatus:(FollowingStatus)followerStatus isUserCeleb:(BOOL)isUserCeleb isUserProfileLocked:(BOOL)isUserProfileLocked;

@end
