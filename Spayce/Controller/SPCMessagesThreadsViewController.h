//
//  SPCMessagesThreadsViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCMessagesRecipientsViewController.h"

@interface SPCMessagesThreadsViewController : UIViewController <SPCMessagesRecipientsViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

- (void)createNewThreadWithRecipients:(NSArray *)recipients;

@end
