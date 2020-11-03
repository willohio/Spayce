//
//  SPCSettingsTableViewController.h
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserProfile;

@interface SPCSettingsTableViewController : UITableViewController

@property (nonatomic, strong) UserProfile *profile;
@property (nonatomic, assign) BOOL addedLogoutNotification;

@end
