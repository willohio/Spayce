//
//  SPCFriendsListPlaceholderViewController.h
//  Spayce
//
//  Created by William Santiago on 2014-11-10.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserProfile;

@interface SPCFriendsListPlaceholderViewController : UIViewController

- (instancetype)initWithFriendsListType:(SPCFriendsListType)friendsListType andUserProfile:(UserProfile *)userProfile;

@end
