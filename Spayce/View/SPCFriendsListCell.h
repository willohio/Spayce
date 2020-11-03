//
//  SPCFriendsListCell.h
//  Spayce
//
//  Created by Jake Rosin on 10/20/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Person;

@interface SPCFriendsListCell : UITableViewCell

@property (nonatomic, readonly) Person *person;
@property (nonatomic, readonly) UIButton *imageButton;

- (void)configureWithCurrentUser:(Person *)person url:(NSURL *)url;
- (void)configureWithPerson:(Person *)person url:(NSURL *)url;

@end
