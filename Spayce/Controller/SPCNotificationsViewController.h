//
//  SpayceNotificationsViewController.h
//  Spayce
//
//  Created by Joseph Jupin on 10/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LargeBlockingProgressView.h"
#import "SPCLookBackViewController.h"

@interface SPCNotificationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SPCLookBackViewControllerDelegate> {
    BOOL tapped;
}

@property (weak,nonatomic) UIView *pullToRefreshFadingHeader;
@property (nonatomic, strong) UITableView *tableView;

- (void)initializeTableView;
- (void)refreshFollowRequests;
@end
