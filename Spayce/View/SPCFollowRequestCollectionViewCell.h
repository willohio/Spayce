//
//  SPCFollowRequestCollectionViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 4/7/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Person.h"

@interface SPCFollowRequestCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIButton *authorBtn;
@property (nonatomic, strong) UIButton *acceptBtn;
@property (nonatomic, strong) UIButton *declineBtn;

- (void)configureWithPerson:(Person *)person;

@end
