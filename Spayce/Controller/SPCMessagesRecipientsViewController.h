//
//  SPCMessagesRecipientsViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SPCMessagesRecipientsViewControllerDelegate <NSObject>

@optional

- (void)createNewThreadWithRecipients:(NSArray *)recipients;

@end



@interface SPCMessagesRecipientsViewController : UIViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) NSObject <SPCMessagesRecipientsViewControllerDelegate> *delegate;

@end
