//
//  SocialProfile.h
//  Spayce
//
//  Created by Pavel Dušátko on 2/3/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Asset;
@class Person;

@interface SocialProfile : NSObject

@property (nonatomic, strong) NSString *firstname;
@property (nonatomic, strong) NSString *lastname;
@property (nonatomic, assign) NSInteger mutualFriendsCount;
@property (nonatomic, strong) NSString *uid;
@property (nonatomic, strong) NSString *contactToken;
@property (nonatomic, assign, getter = isSpayceMember) BOOL spayceMember;
@property (nonatomic, strong) NSString *profilePictureUrlString;
@property (nonatomic, assign) NSInteger followingStatus;
@property (nonatomic, assign) NSInteger userId;
@property (nonatomic, assign) NSInteger starCount;
@property (nonatomic, strong) Person *person;
@property (nonatomic, assign) BOOL invited;

- (instancetype)initWithAttributes:(NSDictionary *)attributes;

@end
