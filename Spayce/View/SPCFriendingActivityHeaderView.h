//
//  SPCFriendingActivityHeaderView.h
//  Spayce
//
//  Created by Arria P. Owlia on 2/13/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCFriendingActivityHeaderView;
@class Memory;
@class Person;
@protocol SPCFriendingActivityHeaderViewDelegate <NSObject>

@optional
- (void)didTapFriendMemory:(Memory *)memory fromFriendingActivityHeaderView:(SPCFriendingActivityHeaderView *)friendingActivityHeaderView;
- (void)didTapPerson:(Person *)person fromFriendingActivityHeaderView:(SPCFriendingActivityHeaderView *)friendingActivityHeaderView;

@end

@interface SPCFriendingActivityHeaderView : UIView

// Delegate
@property (weak, nonatomic) id<SPCFriendingActivityHeaderViewDelegate> delegate;

// Action buttons
@property (strong, nonatomic) UIButton *btnViewAll;
@property (strong, nonatomic) UIButton *btnDismiss;

// Accessors
- (NSArray *)memories;

// Configuration
- (void)configureWithFriendTypeMemories:(NSArray *)memories;

@end
