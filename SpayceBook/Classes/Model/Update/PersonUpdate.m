//
//  PersonUpdate.m
//  Spayce
//
//  Created by Jake Rosin on 8/28/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "PersonUpdate.h"
#import "Person.h"
#import "Memory.h"
#import "Comment.h"
#import "User.h"
#import "SpayceNotification.h"

NSString * kPersonUpdateNotificationName = @"kPersonUpdateNotificationName";

@interface PersonUpdate()

@property (nonatomic, assign) NSInteger recordID;
@property (nonatomic, strong) NSString *userToken;
@property (nonatomic, strong) Asset *imageAsset;
@property (nonatomic, strong) NSString *firstName;
@property (nonatomic, strong) NSString *lastName;


@end

@implementation PersonUpdate

#pragma mark - Object initialization

-(instancetype)initWithRecordID:(NSInteger)recordID userToken:(NSString *)userToken imageAsset:(Asset *)imageAsset firstName:(NSString *)firstName lastName:(NSString *)lastName {
    self = [super init];
    if (self) {
        self.recordID = recordID;
        self.userToken = userToken;
        self.imageAsset = imageAsset;
        self.firstName = firstName;
        self.lastName = lastName;
    }
    return self;
}

#pragma mark - Application methods

-(BOOL)applyToPerson:(Person *)person {
    if (!person || (person.recordID != self.recordID && ![person.userToken isEqualToString:self.userToken])) {
        return NO;
    }
    
    // update!
    if (self.imageAsset) {
        person.imageAsset = self.imageAsset;
    }
    
    if (self.firstName) {
        person.firstname = self.firstName;
    }
    
    if (self.lastName) {
        person.lastname = self.lastName;
    }
    
    return YES;
}

-(BOOL)applyToUser:(User *)user {
    if (!user || user.userId != self.recordID) {
        return NO;
    }
    
    // update!
    if (self.imageAsset) {
        user.imageAsset = self.imageAsset;
    }
    
    if (self.firstName) {
        user.firstName = self.firstName;
    }
    
    if (self.lastName) {
        user.lastName = self.lastName;
    }
    
    return YES;
}

-(BOOL)applyToMemory:(Memory *)memory {
    if (!memory) {
        return NO;
    }
    
    BOOL changed = [self applyToPerson:memory.author];
    changed = [self applyToPerson:memory.userToStarMostRecently] || changed;
    changed = [self applyToArray:memory.taggedUsers] || changed;
    changed = [self applyToArray:memory.recentComments] || changed;
    
    if (changed) {
        [memory refreshMetadata];
    }
    
    return changed;
}

-(BOOL)applyToNotification:(SpayceNotification *)notification {
    if (!notification) {
        return NO;
    }
    
    return [self applyToUser:notification.user];
}

-(BOOL)applyToComment:(Comment *)comment {
    if (!comment) {
        return NO;
    }
    
    BOOL changed = NO;
    if ([comment.userToken isEqualToString:self.userToken]) {
        if (self.firstName) {
            comment.userName = self.firstName;
        }
        if (self.imageAsset) {
            comment.pic = self.imageAsset;
        }
        changed = YES;
    }
    
    NSMutableArray *usernames = [NSMutableArray arrayWithArray:comment.taggedUserNames];
    for (int i = 0; i < usernames.count; i++) {
        NSString *token = comment.taggedUserTokens[i];
        if ([token isEqualToString:self.userToken] && self.firstName) {
            usernames[i] = self.firstName;
            changed = YES;
        }
    }
    comment.taggedUserNames = [NSArray arrayWithArray:usernames];
    
    if (changed) {
        [comment refreshMetadata];
    }
    
    return changed;
}

-(BOOL)applyToObject:(NSObject *)object {
    if (!object) {
        return NO;
    }
    
    if ([object isKindOfClass:[Person class]]) {
        return [self applyToPerson:(Person *)object];
    } else if ([object isKindOfClass:[Memory class]]) {
        return [self applyToMemory:(Memory *)object];
    } else if ([object isKindOfClass:[Comment class]]) {
        return [self applyToComment:(Comment *)object];
    } else if ([object isKindOfClass:[User class]]) {
        return [self applyToUser:(User *)object];
    } else if ([object isKindOfClass:[SpayceNotification class]]) {
        return [self applyToNotification:(SpayceNotification *)object];
    }
    
    return NO;
}

-(BOOL)applyToArray:(NSArray *)array {
    if (!array) {
        return NO;
    }
    
    BOOL changed = NO;
    for (NSObject *object in array) {
        changed = [self applyToObject:object] || changed;
    }
    return changed;
}

#pragma mark - Posting notifications

-(void)postAsNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kPersonUpdateNotificationName object:self];
}

@end
