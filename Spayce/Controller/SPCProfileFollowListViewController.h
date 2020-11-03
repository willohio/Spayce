//
//  SPCProfileFollowListViewController.h
//  Spayce
//
//  Created by Jake Rosin on 3/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Person;

@protocol SPCProfileFollowListViewControllerDelegate <NSObject>
@optional
- (void)followListFollowStatusChanged:(Person *)person;
@end


@interface SPCProfileFollowListViewController : UIViewController

- (instancetype)initWithFollowListType:(SPCFollowListType)followListType;
- (instancetype)initWithFollowListType:(SPCFollowListType)followListType userToken:(NSString *)userToken;

+ (NSString *)titleForFollowListType:(SPCFollowListType)followListType;

@property (nonatomic, weak) id<SPCProfileFollowListViewControllerDelegate> delegate;

@end
