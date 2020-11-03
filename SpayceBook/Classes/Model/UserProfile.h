//
//  UserProfile.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/15/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProfileDetail;

@interface UserProfile : NSObject <NSCopying>

@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, assign) NSInteger profileUserId;
@property (nonatomic, assign) NSInteger totalFriendCount;
@property (nonatomic, assign) NSInteger starCount;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) ProfileDetail *profileDetail;

- (id)initWithAttributes:(NSDictionary *)attributes;

- (void)updateWithFriendCount:(NSInteger)totalFriends;

- (BOOL)isCurrentUser;
- (BOOL)isFollowingUser;
- (BOOL)isFollowedByUser;

@end
