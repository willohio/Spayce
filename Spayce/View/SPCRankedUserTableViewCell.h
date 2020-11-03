//
//  SPCRankedUserTableViewCell.h
//  Spayce
//
//  Created by Christopher Taylor on 5/29/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Person;
@class Star;

@interface SPCRankedUserTableViewCell : UITableViewCell

@property (nonatomic, strong) UIButton *imageButton;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *starCountLabel;
@property (nonatomic, strong) UILabel *territoryNameLabel;
@property (nonatomic, strong) UILabel *rankLabel;
@property (nonatomic, strong) UILabel *handleLabel;
@property (nonatomic, strong) UILabel *youBadge;
@property (nonatomic) NSInteger rank;

- (void)configureWithPerson:(Person *)f peopleState:(NSInteger)peopleState;
- (void)configureWithStar:(Star *)s;
- (NSString *)findSuperscript:(NSInteger)rank;

@end
