//
//  AdminManager.h
//  Spayce
//
//  Created by Jake Rosin on 3/3/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Memory;

typedef NS_ENUM(NSInteger, AdminActionResult) {
    AdminActionResultSuccess = 1,
    AdminActionResultQueued = 2,
    AdminActionResultRedundant = 3,
    AdminActionResultNotImplemented = 4
};

@interface AdminManager : NSObject

+ (AdminManager *)sharedInstance;

- (void)warnUserWithUserKey:(NSString *)userKey completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)deleteUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)banUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)unbanUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)blockUserDeviceWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)unblockUserDeviceWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)muteUserWithUserKey:(NSString *)userKey shadow:(BOOL)shadow completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)unmuteUserWithUserKey:(NSString *)userKey completionHandler:(void (^)(AdminActionResult))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)promoteMemory:(Memory *)memory completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)demoteMemory:(Memory *)memory completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler;

- (void)fetchSockPuppetListPageWithPageKey:(NSString *)pageKey completionHandler:(void (^)(NSArray *puppets, NSString *nextPageKey))completionHandler errorHandler:(void (^)(NSError *))errorHandler;

@end
