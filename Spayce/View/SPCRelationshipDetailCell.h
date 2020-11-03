//
//  SPCRelationshipDetailCell
//  Spayce
//
//  Created by Arria P. Owlia on 3/18/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *SPCRelationshipDetailCellIdentifier;

@interface SPCRelationshipDetailCell : UITableViewCell

- (void)configureWithFollowingStatus:(FollowingStatus)followingStatus andFollowerStatus:(FollowingStatus)followerStatus;

@end
