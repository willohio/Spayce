//
//  SPCFollowListCell.h
//  Spayce
//
//  Created by Jake Rosin on 3/24/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Person;

@interface SPCFollowListCell : UITableViewCell

@property (nonatomic, readonly) Person *person;
@property (nonatomic, readonly) UIButton *imageButton;
@property (nonatomic, readonly) UIButton *followButton;

- (void)configureWithPerson:(Person *)person url:(NSURL *)url;
- (void)configureWithCurrentUser:(Person *)person url:(NSURL *)url;

@end
