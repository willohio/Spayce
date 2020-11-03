//
//  SPCPeopleFinderController.h
//  Spayce
//
//  Created by Jordan Perry on 3/25/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Person;
@class SuggestedFriend;
@class SocialProfile;

@interface SPCPeopleFinderController : NSObject

@property (nonatomic, assign) BOOL addressBookAccessGranted;
@property (nonatomic, assign) BOOL canAskForAddressBookAccess;

#pragma mark - People Fetching via Search Term

- (void)fetchPeopleWithText:(NSString *)text
                completion:(void (^)(NSError *error))completion;
- (Person *)personInPeopleAtIndex:(NSUInteger)index;
- (NSUInteger)countOfPeople;

#pragma mark - Recent Search Fetching

- (void)fetchSearchHistoryWithCompletion:(void (^)(NSError *error))completion;
- (Person *)personInSearchHistoryAtIndex:(NSUInteger)index;
- (NSUInteger)countOfPeopleInSearchHistory;
- (void)addPersonToSearchHistory:(Person *)person;
- (void)clearSearchHistory;

#pragma mark - Suggested Person Fetching

- (void)fetchSuggestedPeopleWithCompletion:(void (^)(NSError *error))completion;
- (SuggestedFriend *)suggestedPersonInSuggestedPeopleAtIndex:(NSUInteger)index;
- (NSUInteger)countOfSuggestedPeople;

#pragma mark - Cool People Nearby Fetching

- (NSUInteger)countOfCoolPeopleNearby;

#pragma mark - Contacts Fetching

- (void)fetchAddressBookProfilesWithCompletion:(void (^)(NSError *error))completion;
- (SocialProfile *)socialProfileInAddressBookAtIndex:(NSUInteger)index;
- (NSUInteger)countOfSocialProfilesInAddressBook;

#pragma mark - Person Handling

- (void)followOrUnfollowPerson:(Person *)person withCompletion:(void (^)(NSError *error))completion;

#pragma mark - Social Profile Handling

- (void)inviteSocialProfile:(SocialProfile *)socialProfile withCompletion:(void (^)(NSError *error))completion;

@end
