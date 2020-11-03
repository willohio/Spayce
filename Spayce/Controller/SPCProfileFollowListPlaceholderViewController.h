//
//  SPCFollowListPlaceholderViewController.h
//  Spayce
//
//  Created by Jake Rosin on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class UserProfile;

@interface SPCFollowListPlaceholderViewController : UIViewController

- (instancetype)initWithFollowListType:(SPCFollowListType)followListType userProfile:(UserProfile *)userProfile;

@end
