//
//  SocialService.h
//  Spayce
//
//  Created by Pavel Dušátko on 1/25/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface SocialService : NSObject

+ (SocialService *)sharedInstance;

// Service name
- (NSString *)serviceNameForType:(NSInteger)type;

// Availability
- (BOOL)availabilityForServiceType:(NSInteger)type;

// Authentication
- (void)authSocialServiceType:(NSInteger)type
               viewController:(UIViewController *)viewController
            completionHandler:(void (^)())completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler;

- (void)authFacebookWithCompletionHandler:(void (^)())completionHandler
                             errorHandler:(void (^)(NSError *error))errorHandler;

- (void)authTwitterWithViewController:(UIViewController *)viewController
                    completionHandler:(void (^)())completionHandler
                         errorHandler:(void (^)(NSError *error))errorHandler;

- (void)authLinkedInWithViewController:(UIViewController *)viewController
                     completionHandler:(void (^)())completionHandler
                          errorHandler:(void (^)(NSError *error))errorHandler;

- (void)loginToFacebook;

// Lists

- (void)fetchABFriendsWithCompletionHandler:(void (^)(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler;

- (void)syncFriendsFromAddressBook:(ABAddressBookRef)addressBook
                  completionHandler:(void (^)(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler;

- (void)fetchFriendsForServiceOfType:(NSInteger)type
                   completionHandler:(void (^)(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends))completionHandler
                        errorHandler:(void (^)(NSError *error))errorHandler;

// Invite

- (void)inviteFriendWithUid:(NSString *)uid
               contactToken:(NSString *)contactToken
              socialService:(NSInteger)type
         completionHandler:(void (^)())completionHandler
              errorHandler:(void (^)(NSError *error))errorHandler;

- (void)inviteFBBatch:(NSArray *)batchIds
              allSent:(BOOL)allSent
    completionHandler:(void (^)())completionHandler
         errorHandler:(void (^)(NSError *error))errorHandler;

- (void)forceFacebookLogout;
- (void)forceTwitterLogout;

@end
