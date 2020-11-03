//
//  SPCFollowersViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 7/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCFollowersViewController : UIViewController {
    BOOL fetchedFollowers;
}
- (id)initWithUserToken:(NSString *)userToken userName:(NSString *)userName isUsersProfile:(BOOL)isUsersProfile;

@end
