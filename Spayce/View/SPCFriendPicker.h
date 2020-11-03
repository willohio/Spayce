//
//  SPCFriendPicker.h
//  Spayce
//
//  Created by Christopher Taylor on 6/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Friend;

@protocol SPCFriendPickerDelegate <NSObject>

@optional
- (void)selectedFriend:(Friend *)f;

@end

@interface SPCFriendPicker : UIView

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, weak) NSObject <SPCFriendPickerDelegate> *delegate;
@property (nonatomic) BOOL isSearching;

- (void)matchFilterString:(NSString *)filter;
- (void)updateFilterString:(NSString *)filter;
- (void)reloadData;

@end
