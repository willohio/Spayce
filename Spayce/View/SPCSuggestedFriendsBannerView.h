//
//  SPCSuggestedFriendsHeaderView.h
//  Spayce
//
//  Created by Arria P. Owlia on 1/23/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *SPCSuggestedFriendsBannerViewIdentifier;

@interface SPCSuggestedFriendsBannerView : UICollectionReusableView

// Button covering the entire view
@property (strong, nonatomic) UIButton *btnAction;

- (void)configureWithString:(NSString *)string;
- (void)configureWithActivityIndicator;

@end
