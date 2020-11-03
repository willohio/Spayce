//
//  ProfileViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 3/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCProfileFeedDataSource.h"

@interface SPCProfileViewController : UIViewController <SPCDataSourceDelegate>

- (instancetype)initWithUserToken:(NSString *)userToken;

- (void)updateCellToPrivate:(NSIndexPath *)indexPath;
- (void)updateCellToPublic:(NSIndexPath *)indexPath;
- (void)fetchUserProfile;
- (void)enableBackButtonsWithTarget:(id)target andSelector:(SEL)selector; // This hack-y method should be called after the view is loaded

@end
