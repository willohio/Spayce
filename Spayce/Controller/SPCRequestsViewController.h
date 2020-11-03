//
//  SPCRequestsViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 10/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCFriendRequestCell.h"

@interface SPCRequestsViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,SPCFriendRequestCelllDelegate>

- (Friend *)getRequestForRecordId:(int)recordId;
@end
