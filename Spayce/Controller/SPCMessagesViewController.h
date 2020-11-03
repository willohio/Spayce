//
//  SPCMessagesViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 3/18/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SPCMessageThread.h"
#import "Person.h"
#import "SPCAlertViewController.h"

@interface SPCMessagesViewController : UIViewController <UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate>

-(void)configureWithRecipients:(NSArray *)recipients;
-(void)configureWithMessageThread:(SPCMessageThread *)messageThread;
-(void)configureWithPerson:(Person *)person;


@end
