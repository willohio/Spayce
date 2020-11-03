//
//  AddFriendsCollectionViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 12/2/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Friend;

@interface AddFriendsCollectionViewCell : UICollectionViewCell {
    BOOL isIncluded;
}

- (void)configureWithFriend:(Friend *)f;
- (void)includeFriend:(BOOL)included;
- (BOOL)friendIsIncluded;

@end
