//
//  Comment.h
//  Spayce
//
//  Created by Christopher Taylor on 6/24/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TranslationUtils.h"

@class Asset;
@class Person;

@interface Comment : NSObject

@property (strong, nonatomic) NSString *dateCreated;
@property (assign, nonatomic) NSInteger recordID;
@property (strong, nonatomic) Person *author;
@property (strong, nonatomic) Asset *pic;
@property (assign, nonatomic) NSInteger starCount;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSString *markupText;
@property (nonatomic, assign) BOOL userHasStarred;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) NSArray *taggedUserTokens;
@property (nonatomic, strong) NSArray *taggedUserNames;
@property (nonatomic, strong) NSArray *taggedUserIds;
@property (nonatomic, strong) NSString *localPicUrl;

@property (nonatomic, strong, readonly) NSAttributedString *attributedText;
@property (nonatomic, readonly) CGFloat attributedTextHeight;

- (id)initWithAttributes:(NSDictionary *)attributes;

- (void)refreshMetadata;

@end
