//
//  User.h
//  SpayceBook
//
//  Created by Dmitry Miller on 5/15/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Asset;

extern NSInteger UserMinRequiredIdentityImages;

@interface User : NSObject

@property (assign, nonatomic) NSInteger userId;
@property (strong, nonatomic) NSString *username;

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) Asset *imageAsset;

@property (strong, nonatomic) NSString *userToken;

@property (nonatomic) BOOL isCeleb;

@property (nonatomic) BOOL isAdmin;

- (id)initWithAttributes:(NSDictionary *)attributes;

@end
