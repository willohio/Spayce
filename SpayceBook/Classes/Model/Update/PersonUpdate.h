//
//  PersonUpdate.h
//  Spayce
//
//  Created by Jake Rosin on 8/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Asset;
@class Person;
@class Memory;
@class Comment;
@class User;
@class SpayceNotification;

extern NSString * kPersonUpdateNotificationName;

@interface PersonUpdate : NSObject

-(instancetype)initWithRecordID:(NSInteger)recordID userToken:(NSString *)userToken imageAsset:(Asset *)imageAsset firstName:(NSString *)firstName lastName:(NSString *)lastName;

-(BOOL)applyToPerson:(Person *)person;
-(BOOL)applyToUser:(User *)user;
-(BOOL)applyToMemory:(Memory *)memory;
-(BOOL)applyToNotification:(SpayceNotification *)notification;
-(BOOL)applyToComment:(Comment *)comment;

-(BOOL)applyToArray:(NSArray *)array;

-(void)postAsNotification;

@end
