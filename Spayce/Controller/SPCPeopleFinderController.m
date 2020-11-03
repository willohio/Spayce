//
//  SPCPeopleFinderController.m
//  Spayce
//
//  Created by Jordan Perry on 3/25/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCPeopleFinderController.h"
#import "Flurry.h"
#import <AddressBook/AddressBook.h>

#import "AuthenticationManager.h"
#import "Constants.h"
#import "MeetManager.h"
#import "Person.h"
#import "SocialProfile.h"
#import "SocialService.h"
#import "SPCLiterals.h"
#import "SuggestedFriend.h"
#import "User.h"

NSString *const SPCPeopleFinderControllerSearchHistoryUserDefaultsKey = @"SPCPeopleFinderControllerSearchHistoryUserDefaultsKey";

@interface SPCPeopleFinderController ()

@property (nonatomic, copy) NSArray *people;
@property (nonatomic, strong) NSMutableArray *searchHistory;
@property (nonatomic, copy) NSArray *suggestedFriends;

@property (nonatomic, copy) NSArray *socialProfilesInAddressBook;

@property (nonatomic, copy) void (^pendingAddressBookCompletionBlock)(NSError *error);

@property (nonatomic, assign) BOOL searchHistoryHasChanged;

@end

@implementation SPCPeopleFinderController

#pragma Creation / Destroying

- (void)dealloc {
    if (self.searchHistoryHasChanged) {
        [[NSUserDefaults standardUserDefaults] setObject:[self.searchHistory copy] forKey:SPCPeopleFinderControllerSearchHistoryUserDefaultsKey];
    }
}

#pragma mark - People Fetching via Search Term

- (void)fetchPeopleWithText:(NSString *)text completion:(void (^)(NSError *))completion {
    if (![text length]) {
        self.people = nil;
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    [MeetManager fetchUsersWithSearch:text
                    completionHandler:^(NSArray *people) {
                        __strong typeof(weakSelf) strongSelf = weakSelf;
                        
                        strongSelf.people = people;
                        
                        if (completion) {
                            completion(nil);
                        }
                    } errorHandler:^(NSError *error) {
                        if (completion) {
                            completion(error);
                        }
                    }];
}

- (Person *)personInPeopleAtIndex:(NSUInteger)index {
    return [self itemAtIndex:index inArray:self.people];
}

- (NSUInteger)countOfPeople {
    return [self.people count];
}

#pragma mark - Recent Search Fetching

- (void)fetchSearchHistoryWithCompletion:(void (^)(NSError *error))completion {
    // Pre-fetch from user defaults for immediate retrieval
    [self searchHistory];
    completion(nil);
}

- (Person *)personInSearchHistoryAtIndex:(NSUInteger)index {
    NSData *encodedPerson = [self itemAtIndex:index inArray:self.searchHistory];
    return [NSKeyedUnarchiver unarchiveObjectWithData:encodedPerson];
}

- (NSUInteger)countOfPeopleInSearchHistory {
    return [self.searchHistory count];
}

- (void)addPersonToSearchHistory:(Person *)person {
    NSData *encodedPerson = [NSKeyedArchiver archivedDataWithRootObject:person];
    [self.searchHistory removeObject:encodedPerson];
    [self.searchHistory insertObject:encodedPerson atIndex:0];
    
    self.searchHistoryHasChanged = YES;
}

- (void)clearSearchHistory {
    [self.searchHistory removeAllObjects];
    self.searchHistoryHasChanged = YES;
}

- (NSMutableArray *)searchHistory {
    if (!_searchHistory) {
        NSArray *existingSearchHistory = [[NSUserDefaults standardUserDefaults] objectForKey:SPCPeopleFinderControllerSearchHistoryUserDefaultsKey];
        if (!existingSearchHistory) {
            _searchHistory = [[NSMutableArray alloc] init];
        } else {
            _searchHistory = [existingSearchHistory mutableCopy];
        }
    }
    
    return _searchHistory;
}

#pragma mark - Suggested Friend Fetching

- (void)fetchSuggestedPeopleWithCompletion:(void (^)(NSError *))completion {
    __weak typeof(self) weakSelf = self;
    
    [[MeetManager sharedInstance] fetchSuggestedFriendsWithPageKey:[self suggestionsFreshPageKey]
                                                    resultCallback:^(NSArray *people, NSString *freshPageKey) {
                                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                                        
                                                        strongSelf.suggestedFriends = people;
                                                        
                                                        if (completion) {
                                                            completion(nil);
                                                        }
                                                    } faultCallback:^(NSError *fault) {
                                                        if (completion) {
                                                            completion(fault);
                                                        }
                                                    }];
}

- (SuggestedFriend *)suggestedPersonInSuggestedPeopleAtIndex:(NSUInteger)index {
    return [self itemAtIndex:index inArray:self.suggestedFriends];
}

- (NSUInteger)countOfSuggestedPeople {
    return [self.suggestedFriends count];
}

- (void)setSuggestionsFreshPageKey:(NSString *)suggestionsFreshPageKey {
    NSString *strSuggestedFriendsFreshPageKey = [SPCLiterals literal:kSPCSuggestedFriendsFreshPageKey forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    [[NSUserDefaults standardUserDefaults] setObject:suggestionsFreshPageKey forKey:strSuggestedFriendsFreshPageKey];
}

- (NSString *)suggestionsFreshPageKey {
    NSString *strSuggestedFriendsFreshPageKey = [SPCLiterals literal:kSPCSuggestedFriendsFreshPageKey forUser:[[AuthenticationManager sharedInstance] currentUser]];
    
    return [[NSUserDefaults standardUserDefaults] objectForKey:strSuggestedFriendsFreshPageKey];
}

#pragma mark - Cool People Nearby Fetching

- (NSUInteger)countOfCoolPeopleNearby {
    return 0;
}

#pragma mark - Contacts Fetching

- (void)fetchAddressBookProfilesWithCompletion:(void (^)(NSError *))completion {
    if (![self addressBookAccessGranted]) {
        if ([self canAskForAddressBookAccess]) {
            self.pendingAddressBookCompletionBlock = completion;
            [self requestAddressBookAuthorization];
            return;
        } else {
            if (completion) {
                completion([self errorForDeniedAddressBookAccess]);
            }
            return;
        }
    }
    
    CFErrorRef error = NULL;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    
    if (error == NULL) {
        __weak typeof(self) weakSelf = self;
        
        [[SocialService sharedInstance] syncFriendsFromAddressBook:addressBookRef
                                                 completionHandler:^(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends) {
                                                     __strong typeof(weakSelf) strongSelf = weakSelf;
                                                     
                                                     [[SocialService sharedInstance] fetchABFriendsWithCompletionHandler:^(BOOL inviteAllSent, NSArray *spayceFriends, NSArray *nonSpayceFriends) {
                                                         NSMutableArray *socialProfiles = [[NSMutableArray alloc] init];
                                                         for (SocialProfile *socialProfile in spayceFriends) {
                                                             NSArray *itemsMatching = [socialProfiles filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SocialProfile *evaluatedObject, NSDictionary *bindings) {
                                                                 if (![evaluatedObject isKindOfClass:[SocialProfile class]]) {
                                                                     return NO;
                                                                 }
                                                                 
                                                                 if (![evaluatedObject.person.handle isEqualToString:socialProfile.person.handle]) {
                                                                     return NO;
                                                                 }
                                                                 
                                                                 return YES;
                                                             }]];
                                                             
                                                             User *signedInUser = [AuthenticationManager sharedInstance].currentUser;
                                                             if ([itemsMatching count] == 0 &&
                                                                 ![signedInUser.userToken isEqualToString:socialProfile.person.userToken]) {
                                                                 [socialProfiles addObject:socialProfile];
                                                             }
                                                         }
                                                         
                                                         [socialProfiles addObjectsFromArray:nonSpayceFriends];
                                                         
                                                         strongSelf.socialProfilesInAddressBook = [socialProfiles copy];
                                                         
                                                         if (completion) {
                                                             completion(nil);
                                                         }
                                                     } errorHandler:^(NSError *error) {
                                                         if (completion) {
                                                             completion(error);
                                                         }
                                                     }];
                                                     
                                                     CFRelease(addressBookRef);
                                                 } errorHandler:^(NSError *error) {
                                                     if (completion) {
                                                         completion(error);
                                                     }
                                                     
                                                     CFRelease(addressBookRef);
                                                 }];
    } else {
        CFRelease(error);
    }
}

- (SocialProfile *)socialProfileInAddressBookAtIndex:(NSUInteger)index {
    return [self itemAtIndex:index inArray:self.socialProfilesInAddressBook];
}

- (NSUInteger)countOfSocialProfilesInAddressBook {
    return [self.socialProfilesInAddressBook count];
}

- (BOOL)addressBookAccessGranted {
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized;
}

- (BOOL)canAskForAddressBookAccess {
    return ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined;
}

- (void)requestAddressBookAuthorization {
    CFErrorRef error;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    
    if (error == NULL) {
        __weak typeof(self) weakSelf = self;
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                if (strongSelf.pendingAddressBookCompletionBlock) {
                    if (!granted || error != NULL) {
                        strongSelf.pendingAddressBookCompletionBlock([self errorForDeniedAddressBookAccess]);
                        strongSelf.pendingAddressBookCompletionBlock = nil;
                    } else {
                        [strongSelf fetchAddressBookProfilesWithCompletion:strongSelf.pendingAddressBookCompletionBlock];
                        strongSelf.pendingAddressBookCompletionBlock = nil;
                    }
                }
            });
        });
    }
    
    if (addressBookRef != NULL) {
        CFRelease(addressBookRef);
    }
}

- (NSError *)errorForDeniedAddressBookAccess {
    return [NSError errorWithDomain:NSLocalizedString(@"Access Denied", nil)
                               code:403
                           userInfo:@{
                                      NSLocalizedDescriptionKey: NSLocalizedString(NSLocalizedString(@"You can enable Contacts access in Privacy Settings.", nil), @"")
                                      }];
}

#pragma mark - Person Handling

- (void)followOrUnfollowPerson:(Person *)person withCompletion:(void (^)(NSError *))completion {
    if (person.followingStatus == FollowingStatusFollowing) {
        [MeetManager unfollowWithUserToken:person.userToken
                         completionHandler:^{
                             [Flurry logEvent:@"UNFOLLOW_IN_PEOPLE_FINDER"];
                             person.followingStatus = FollowingStatusNotFollowing;
                             
                             if (completion) {
                                 completion(nil);
                             }
                         } errorHandler:^(NSError *error) {
                             if (completion) {
                                 completion(error);
                             }
                         }];
    } else {
        [MeetManager sendFollowRequestWithUserToken:person.userToken
                                  completionHandler:^(BOOL followingNow) {
                                      
                                      [Flurry logEvent:@"FOLLOW_REQ_IN_PEOPLE_FINDER"];
                                      person.followingStatus = followingNow ? FollowingStatusFollowing : FollowingStatusRequested;
                                      
                                      if (completion) {
                                          completion(nil);
                                      }
                                  } errorHandler:^(NSError *error) {
                                      if (completion) {
                                          completion(error);
                                      }
                                  }];
    }
}

#pragma mark - Social Profile Handling

- (void)inviteSocialProfile:(SocialProfile *)socialProfile withCompletion:(void (^)(NSError *error))completion {
    [[SocialService sharedInstance] inviteFriendWithUid:socialProfile.uid
                                           contactToken:socialProfile.contactToken
                                          socialService:SocialServiceTypeAddressBook
                                      completionHandler:^{
                                          
                                          socialProfile.invited = YES;
                                          if (completion) {
                                              completion(nil);
                                          }
                                      } errorHandler:^(NSError *error) {
                                          if (completion) {
                                              completion(error);
                                          }
                                      }];
}

#pragma mark - Universal Helpers

- (id)itemAtIndex:(NSUInteger)index inArray:(NSArray *)array {
    if (index >= [array count]) {
        return nil;
    }
    
    return array[index];
}

@end
