//
//  MeetManager.h
//  Spayce
//
//  Created by Howard Cantrell on 11/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Enums.h"

@class Venue;
@class SPCCity;
@class SPCNeighborhood;
@class Memory;
@class Comment;
@class Person;

@interface MeetManager : NSObject

+ (MeetManager *)sharedInstance;

// Friends

- (void)fetchSuggestedFriendsWithPageKey:(NSString *)pageKey
                        resultCallback:(void (^)(NSArray *people, NSString *freshPageKey))resultCallback
                         faultCallback:(void (^)(NSError *fault))faultCallback;

// Memories
+ (void)fetchSharedMemoriesWithUserToken:(NSString *)userToken
                 completionHandler:(void (^)(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories))completionHandler
                      errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchUserMemoriesWithUserToken:(NSString *)userToken
                        memorySortType:(MemorySortType)memorySortType
                                 count:(NSInteger)count
                               pageKey:(NSString *)pageKey
                       completionHandler:(void (^)(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories, NSString *nextPageKey))completionHandler
                            errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchMemoryParticipantsWithMemoryID:(NSInteger)memoryID
                          completionHandler:(void (^)(NSArray *participants))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler;

- (void)fetchFeaturedMemoriesWithLatitude:(CGFloat)latitude
                              longitude:(CGFloat)longitude
                  withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchMontageWorldMemoriesWithCurrentMemoryKeys:(NSArray *)memoryKeys
                                     completionHandler:(void (^)(NSArray *memories, BOOL wasMontageStale))completionHandler
                                          errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchMontageNearbyMemoriesWithCurrentMemoryKeys:(NSArray *)memoryKeys
                                               latitude:(CGFloat)latitude
                                              longitude:(CGFloat)longitude
                                  withCompletionHandler:(void (^)(NSArray *memories, BOOL wasMontageStale))completionHandler
                                           errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchRegionMemoriesWithLatitude:(CGFloat)latitude
                              longitude:(CGFloat)longitude
                                 radius:(CGFloat)radius
                  withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchRegionMemoriesWithLatitude:(CGFloat)latitude
                              longitude:(CGFloat)longitude
                                 radius:(CGFloat)radius
                         omitIdsBetween:(NSInteger)omitIdMin
                                    and:(NSInteger)omitIdMax
                  withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchRegionMemoriesWithSouthWestLatitude:(CGFloat)southWestLatitude
                              southWestLongitude:(CGFloat)southWestLongitude
                               northEastLatitude:(CGFloat)northEastLatitude
                              northEastLongitude:(CGFloat)northEastLongitude
                                         pageKey:(NSString *)pageKey
                           withCompletionHandler:(void (^)(NSArray *memories, NSString *nextPageKey))completionHandler
                                    errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchRegionMemoriesWithCity:(SPCCity *)city
                            pageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *memories, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler;


+ (void)fetchRegionMemoriesWithNeighborhood:(SPCNeighborhood *)neighborhood
                                    pageKey:(NSString *)pageKey
                          completionHandler:(void (^)(NSArray *memories, NSString *nextPageKey))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler;




+ (void)fetchLocationMemoriesFeedForVenue:(Venue *)venue
                   includeFeaturedContent:(BOOL)includeFeaturedContent
                    withCompletionHandler:(void (^)(NSArray *memories, NSArray *featuredContent,NSArray *venueHashTags))completionHandler
                             errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchLocationMemoriesFeedForVenue:(Venue *)venue
                             createdSince:(NSDate *)createdSince
                    withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                             errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchLocationMemoriesFeedForLocation:(NSInteger)addressId
                            manuallySelected:(BOOL)manuallySelected
                      includeFeaturedContent:(BOOL)includeFeaturedContent
                       withCompletionHandler:(void (^)(NSArray *memories, NSArray *featuredContent))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler;


+ (void)fetchPopularMemoriesByUserWithToken:(NSString *)userToken
                                       city:(SPCCity *)city
                                      count:(NSInteger)count
                          completionHandler:(void (^)(NSArray *memories))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchPopularMemoriesByUserWithToken:(NSString *)userToken
                               neighborhood:(SPCNeighborhood *)neighborhood
                                      count:(NSInteger)count
                          completionHandler:(void (^)(NSArray *memories))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler;


+ (void)postMemoryWithUserIds:(NSString *)includedUserIds
                         text:(NSString *)memoryText
                     assetIds:(NSString *)assetIds
                    addressId:(int)addressId
                     latitude:(double)gpsLat
                    longitude:(double)gpsLong
                   accessType:(NSString *)access
                     hashtags:(NSString *)hashtags
               fbShareEnabled:(BOOL)fbShareEnabled
             twitShareEnabled:(BOOL)twitShareEnabled
                       isAnon:(BOOL)isAnon
                    territory:(SPCCity *)territory
                         type:(int)currType
               resultCallback:(void (^)(NSInteger memId, Venue *memVenue, NSString *memoryKey))resultCallback
                faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)updateMemoryParticipantsWithMemoryID:(NSInteger)memoryID
                        taggedUserIdsUserIds:(NSArray *)taggedUserIdsUserIds
                              resultCallback:(void (^)(NSDictionary *results))resultCallback
                               faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchMemoriesFeedWithCount:(NSInteger) count
                         idsBefore:(NSInteger) before
                 completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved))completionHandler
                      errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchMemoriesFeedWithCount:(NSInteger) count
                 completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved))completionHandler
                      errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchNewFeedCountSince:(NSInteger)milisecSinceLastChecked
             completionHandler:(void (^)(NSInteger newCount))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchMemoryWithMemoryId:(NSInteger)memoryID
                 resultCallback:(void (^)(NSDictionary *results))resultCallback
                  faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchLookBackMemoriesWithID:(NSInteger)notificationID
                  completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved, NSDate *lookBackDate))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)deleteMemoryWithMemoryId:(NSInteger)memoryID
                  resultCallback:(void (^)(NSDictionary *results))resultCallback
                   faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)reportMemoryWithMemoryId:(NSInteger)memoryID
                      reportType:(SPCReportType)reportType
                            text:(NSString *)text
                  resultCallback:(void (^)(NSDictionary *results))resultCallback
                   faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)updateMemoryWithMemoryId:(NSInteger)memoryID
                       addressId:(NSInteger)addressID
                  resultCallback:(void (^)(NSDictionary *results))resultCallback
                   faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchStarsWithMemoryId:(NSInteger)memoryID
             completionHandler:(void (^)(NSArray *stars))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)addStarToMemory:(Memory *)memory
         resultCallback:(void (^)(NSDictionary *results))resultCallback
          faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)addStarToMemory:(Memory *)memory
           asSockPuppet:(Person *)sockPuppet
         resultCallback:(void (^)(NSDictionary *results))resultCallback
          faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)deleteStarFromMemory:(Memory *)memory
              resultCallback:(void (^)(NSDictionary *results))resultCallback
               faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)deleteStarFromMemory:(Memory *)memory
                asSockPuppet:(Person *)sockPuppet
              resultCallback:(void (^)(NSDictionary *results))resultCallback
               faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchCustomPlaceName:(NSInteger)addressId
              resultCallback:(void (^)(NSDictionary *customLocation))resultCallback
               faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)postVenueWithLat:(double)gpsLat
               longitude:(double)gpsLong
                    name:(NSString *)name
     locationMainPhotoId:(int)mainPhotoId
          resultCallback:(void (^)(Venue *))resultCallback
           faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)updateVenueWithLocationId:(NSInteger)locationId
                             name:(NSString *)name
              locationMainPhotoId:(int)mainPhotoId
                   resultCallback:(void (^)(Venue *))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)deleteVenueWithLocationId:(NSInteger)locationId
                   resultCallback:(void (^)(Venue *))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchDefaultLocationNameWithLat:(double)gpsLat
                              longitude:(double)gpsLong
                         resultCallback:(void (^)(NSDictionary *resultsDic))resultCallback
                          faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchNearbyAddressesWithResultCallback:(void (^)(NSArray *places))resultCallback
                                 faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchNearbyAddressesWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                          resultCallback:(void (^)(NSArray *))resultCallback
                           faultCallback:(void (^)(NSError *))faultCallback;

+ (void)fetchNearbyLocationsWithResultCallback:(void (^)(NSArray *locations))resultCallback
                                 faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)shareMemoryWithMemoryId:(NSInteger)memoryId
                    serviceName:(NSString *)serviceName
              completionHandler:(void (^)())completionHandler
                   errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)updateMemoryAccessTypeWithMemoryId:(NSInteger)memoryId
                                accessType:(NSString *)accessType
                         completionHandler:(void (^)())completionHandler
                              errorHandler:(void (^)(NSError *error))errorHandler;

+(void)watchMemoryWithMemoryKey:(NSString *)memoryKey
                 resultCallback:(void (^)(NSDictionary *results))resultCallback
                  faultCallback:(void (^)(NSError *fault))faultCallback;

+(void)unwatchMemoryWithMemoryKey:(NSString *)memoryKey
                   resultCallback:(void (^)(NSDictionary *results))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback;



// Comments
+ (void)postCommentWithMemoryID:(NSInteger)memoryID
                           text:(NSString *)commentText
                  taggedUserIDs:(NSString *)taggedIDs
                       hashtags:(NSString *)hashtags
                   asSockPuppet:(Person *)sockPuppet
                 resultCallback:(void (^)(NSInteger commentId))resultCallback
                  faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)fetchCommentsWithMemoryID:(NSInteger)memoryID
                   resultCallback:(void (^)(NSArray *comments))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)reportCommentWithCommentId:(NSInteger)commentId
                        reportType:(SPCReportType)reportType
                              text:(NSString *)text
                    resultCallback:(void (^)())resultCallback
                     faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)deleteCommentWithCommentId:(NSInteger)commentId
                    resultCallback:(void (^)())resultCallback
                     faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)addStarToComment:(Comment *)comment
          resultCallback:(void (^)())resultCallback
           faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)deleteStarFromComment:(Comment *)comment
               resultCallback:(void (^)())resultCallback
                faultCallback:(void (^)(NSError *fault))faultCallback;

// Blocking
+ (void)fetchBlockedUsersResultCallback:(void (^)(NSArray *blockedUsers))resultCallback
                          faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)blockUserWithId:(NSInteger)blockUserId
         resultCallback:(void (^)(NSDictionary *result))resultCallback
          faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)unblockUserWithId:(NSInteger)userId
           resultCallback:(void (^)())resultCallback
            faultCallback:(void (^)(NSError *fault))faultCallback;

+ (void)setBlockedIds:(NSArray *)blockedIds;
+ (NSArray *)getBlockedIds;
+ (void)getOrFetchBlockedIdsWithCompletionHandler:(void (^)(NSArray *ids))completionHandler;
+ (void)setBlockedIdsRefreshTime;
+ (NSDate *)getBlockedIdsRefreshTime;


// Reputation
+ (void)fetchCitiesWithSearch:(NSString *)searchString
            completionHandler:(void (^)(NSArray *cities))completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchNeighborhoodsWithSearch:(NSString *)searchString
                   completionHandler:(void (^)(NSArray *cities))completionHandler
                        errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchRankedUserForCity:(SPCCity *)city
             completionHandler:(void (^)(NSArray *cityUsers, NSInteger cityPop))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchRankedUserForNeighborhood:(SPCNeighborhood *)neighborhood
                rankInCityIfFewResults:(BOOL)rankInCityIfFewResults
                     completionHandler:(void (^)(NSArray *cityUsers, SPCCity *city, NSInteger cityPop))completionHandler
                          errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchUsersWithSearch:(NSString *)searchString
           completionHandler:(void (^)(NSArray *cities))completionHandler
                errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchGlobalRankedUsersWithCompletionHandler:(void (^)(NSArray *rankedUsers))completionHandler
                                       errorHandler:(void (^)(NSError *error))errorHandler;

// Fly
+ (void)fetchExplorePlacesWithSearch:(NSString *)searchString
                   completionHandler:(void (^)(NSArray *neighborhoods, NSArray *cities))completionHandler
                        errorHandler:(void (^)(NSError *error))errorHandler;

// Followers

+ (void)acceptFollowRequestWithUserToken:(NSString *)userToken
                       completionHandler:(void (^)())completionHandler
                            errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)rejectFollowRequestWithUserToken:(NSString *)userToken
                       completionHandler:(void (^)())completionHandler
                            errorHandler:(void (^)(NSError *error))errorHandler;



+ (void)unfollowWithUserToken:(NSString *)userToken
                completionHandler:(void (^)())completionHandler
                     errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)sendFollowRequestWithUserToken:(NSString *)targetUserToken
                           completionHandler:(void (^)(BOOL followingNow))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowersWithPageKey:(NSString *)pageKey
                completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                     errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowersWithUserToken:(NSString *)targetUserToken
                        withPageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowersOrderedByLastMessageWithPageKey:(NSString *)pageKey
                                    completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                                         errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowersWithPartialSearch:(NSString *)partialSearch
                                pageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowersWithUserToken:(NSString *)targetUserToken
                      partialSearch:(NSString *)partialSearch
                        withPageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowedUsersWithPartialSearch:(NSString *)partialSearch
                                pageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchFollowedUsersWithUserToken:(NSString *)targetUserToken
                      partialSearch:(NSString *)partialSearch
                        withPageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler;

+ (void)fetchUnhandleFollowRequestsCountWithResultCallback:(void (^)(NSInteger totalUnhandledRequests))resultCallback
                                             faultCallback:(void (^)(NSError *fault))faultCallback;


+ (void)fetchFollowerRequestsWithPageKey:(NSString *)pageKey
                completionHandler:(void (^)(NSArray *followerRequests, NSString *nextPageKey))completionHandler
                     errorHandler:(void (^)(NSError *error))errorHandler;


// Grid content (legacy - locations only)

-(void)fetchFeaturedGridPageWithPageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *featuredContent, NSString *nextPageKey, NSString *stalePageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;


-(void)checkForFreshFirstPageWorldGridWithStaleKey:(NSString *)staleKey
                                 completionHandler:(void (^)(BOOL firstPageIsStale))completionHandler
                                      errorHandler:(void (^)(NSError *error))errorHandler;


// Grid content (new - memories with rising stars)


-(void)fetchWorldFeaturedMemoryAndVenueGridPageWithPageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler;


-(void)checkForFreshFirstPageWorldFeaturedMemoryAndVenueGridWithStaleKey:(NSString *)staleKey
                                 completionHandler:(void (^)(BOOL firstPageIsStale))completionHandler
                                      errorHandler:(void (^)(NSError *error))errorHandler;

-(void)fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:(NSString *)pageKey
                                     latitude:(double)latitude
                                    longitude:(double)longitude
                               resultCallback:(void (^)(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey))resultCallback
                                faultCallback:(void (^)(NSError *fault))faultCallback;


-(void)checkForFreshFirstPageNearbyFeaturedMemoryAndVenueGridWithStalePageKey:(NSString *)pageKey
                                               latitude:(double)latitude
                                              longitude:(double)longitude
                                         resultCallback:(void (^)(BOOL firstPageIsStale))resultCallback
                                          faultCallback:(void (^)(NSError *fault))faultCallback;


-(void)fetchGridPageForHashTag:(NSString *)hashtag
                   withPageKey:(NSString *)pageKey
             completionHandler:(void (^)(NSArray *featuredContent, NSString *nextPageKey))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler;



@end
