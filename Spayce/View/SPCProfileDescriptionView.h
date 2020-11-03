//
//  SPCProfileDescriptionView.h
//  Spayce
//
//  Created by Pavel Dusatko on 2014-10-20.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCProfileDescriptionView;
@protocol SPCProfileDescriptionViewDelegate <NSObject>

- (void)tappedDescriptionType:(SPCProfileDescriptionType)descriptionType onDescriptionView:(SPCProfileDescriptionView *)descriptionView;

@end

@interface SPCProfileDescriptionView : UIView

@property (weak, nonatomic) id<SPCProfileDescriptionViewDelegate> delegate;

- (void)configureWithStarCount:(NSInteger)starCount followerCount:(NSInteger)followerCount followingCount:(NSInteger)followingCount buttonsEnabled:(BOOL)buttonsEnabled;
- (void)configureWithInfiniteCounts;

@end
