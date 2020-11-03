//
//  SPCPeopleFinderCollectionViewCell.h
//  Spayce
//
//  Created by Jordan Perry on 3/26/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SPCPeopleFinderCollectionViewCellDelegate;

@class Person;
@class SocialProfile;

@interface SPCPeopleFinderCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<SPCPeopleFinderCollectionViewCellDelegate> delegate;
@property (nonatomic, strong) Person *person;
@property (nonatomic, strong) SocialProfile *socialProfile;

@end

@protocol SPCPeopleFinderCollectionViewCellDelegate <NSObject>
@optional
- (void)peopleFinderCollectionViewCell:(SPCPeopleFinderCollectionViewCell *)cell profileImageSelectedForPerson:(Person *)person;
- (void)peopleFinderCollectionViewCell:(SPCPeopleFinderCollectionViewCell *)cell followButtonSelectedForPerson:(Person *)person;
- (void)peopleFinderCollectionViewCell:(SPCPeopleFinderCollectionViewCell *)cell inviteButtonSelectedForSocialProfile:(SocialProfile *)socialProfile;

@end
