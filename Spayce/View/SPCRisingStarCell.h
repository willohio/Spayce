//
//  SPCRisingStarCell.h
//  Spayce
//
//  Created by Jake Rosin on 4/1/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Person;

@interface SPCRisingStarCell : UICollectionViewCell

@property (nonatomic, readonly) Person *person;
@property (nonatomic, assign) CGFloat horizontalOverreach;

- (void)configureWithPerson:(Person *)person;

@end
