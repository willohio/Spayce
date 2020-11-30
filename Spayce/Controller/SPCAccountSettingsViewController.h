//
//  SPCAccountSettingsViewController.h
//  Spayce
//
//  Created by William Santiago on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserProfile;

@interface SPCAccountSettingsViewController : UITableViewController

@property (nonatomic, strong) UserProfile *profile;

@end
