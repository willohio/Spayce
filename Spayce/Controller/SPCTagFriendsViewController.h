//
//  SPCTagFriendsViewController.h
//  Spayce
//
//  Created by Christopher Taylor on 5/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Memory;
@class SPCTagFriendsViewController;

@protocol SPCTagFriendsViewControllerDelegate <NSObject>

@optional

// FIXME: Deprecated
- (void)cancelTaggingFriends;
- (void)pickedFriends:(NSArray *)selectedFriends;

- (void)tagFriendsViewController:(SPCTagFriendsViewController *)viewController finishedPickingFriends:(NSArray *)selectedFriends;
- (void)tagFriendsViewControllerDidCancel:(SPCTagFriendsViewController *)viewController;

@end

@interface SPCTagFriendsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate, UITextFieldDelegate>

@property (nonatomic, weak) NSObject <SPCTagFriendsViewControllerDelegate> *delegate;
@property (nonatomic, strong) Memory *memory;

-(void)updateForCall;

// FIXME: Deprecated
- (id)initWithSelectedFriends:(NSArray *)selectedFriends;

- (instancetype)initWithMemory:(Memory *)memory;

@end
