//
//  SPCMessageRecipientCell.h
//  Spayce
//
//  Created by Christopher Taylor on 3/17/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Person;

@interface SPCMessageRecipientCell : UITableViewCell




@property (nonatomic, readonly) Person *person;
@property (nonatomic, readonly) UIButton *imageButton;
@property (nonatomic, readonly) UIButton *actionButton;

- (void)configureWithPerson:(Person *)person url:(NSURL *)url;
- (void)displayCustomCheck:(BOOL)shouldDisplayCheck;

@end
