//
//  MeetManager.m
//  Spayce
//
//  Created by Howard Cantrell on 11/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "MeetManager.h"
#import "Flurry.h"

// Framework
#import <GoogleMaps/GoogleMaps.h>

// Model
#import "Friend.h"
#import "Memory.h"
#import "User.h"
#import "Star.h"
#import "Comment.h"
#import "Venue.h"
#import "SPCNeighborhood.h"
#import "SPCFeaturedContent.h"
#import "SuggestedFriend.h"
#import "Location.h"

// View
#import "IntroAnimation.h"

// Manager
#import "AuthenticationManager.h"
#import "LocationManager.h"
#import "VenueManager.h"

// API
#import "APIService.h"

// Literals
#import "SPCLiterals.h"
#import "Constants.h"

// Singleton
#import "Singleton.h"

@implementation MeetManager

static NSString *kMeetManagerFilter = @"MeetManagerFilter";

SINGLETON_GCD(MeetManager);

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fetchStarCount)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(fetchStarCount)
                                                     name:kIntroAnimationDidEndNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearStarCount)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAuthenticationSuccess)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLogout)
                                                     name:kAuthenticationDidLogoutNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Friends

- (void)fetchSuggestedFriendsWithPageKey:(NSString *)pageKey
                        resultCallback:(void (^)(NSArray *people, NSString *freshPageKey))resultCallback
                         faultCallback:(void (^)(NSError *fault))faultCallback {
  NSString *strApiUrl = @"/friends/suggested";
  
  NSDictionary *queryParams = nil;
  if (nil != pageKey) {
    queryParams = @{ @"pageKey" : pageKey };
  }
    
    [APIService makeApiCallWithMethodUrl:strApiUrl
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:queryParams
                          resultCallback:^(NSObject *result) {
                              if (nil != resultCallback) {
                                  if ([result isKindOfClass:[NSDictionary class]]) {
                                      NSDictionary *dicResult = (NSDictionary *)result;
                                      NSObject *friendsObj = [dicResult objectForKey:@"friends"];
                                      NSObject *freshPageKeyObj = [dicResult objectForKey:@"freshPageKey"];
                                      
                                      if ([friendsObj isKindOfClass:[NSArray class]] && ([freshPageKeyObj isKindOfClass:[NSString class]] || nil == freshPageKeyObj)) {
                                          NSArray *friendArray = (NSArray *)friendsObj;
                                          NSString *freshPageKey = (NSString *)freshPageKeyObj;
                                          
                                          NSMutableArray *peopleInitialized = [[NSMutableArray alloc] initWithCapacity:[friendArray count]];
                                          for (NSObject *friendObj in friendArray) {
                                              if ([friendObj isKindOfClass:[NSDictionary class]]) {
                                                  SuggestedFriend *suggestion = [[SuggestedFriend alloc] initWithAttributes:(NSDictionary *)friendObj];
                                                  [peopleInitialized addObject:suggestion];
                                              }
                                          }
                                          
                                          resultCallback(peopleInitialized, freshPageKey);
                                      } else {
                                          NSLog(@"Parsing Error: friends or freshPageKey object invalid");
                                      }
                                  } else {
                                      NSLog(@"Parsing Error: result object is not a dictionary");
                                  }
                              }
                          }
                           faultCallback:^(NSError *fault) {
                               if (nil != fault) {
                                   NSLog(@"url %@ params %@ fault %@",strApiUrl,queryParams,[fault localizedDescription]);
                                   NSLog(@"getSuggestedFriends API Fault: %@", [fault localizedDescription]);
                               }
                               
                               if (nil != faultCallback) {
                                   faultCallback(fault);
                               }
                           }];
}

#pragma mark - Memories

+ (void)fetchSharedMemoriesWithUserToken:(NSString *)userToken
                 completionHandler:(void (^)(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories))completionHandler
                      errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/memories/friendV2/%@", userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *memories = JSON[@"memories"];
                              NSMutableArray *mutableMemories = [self translateMemoriesFromResponse:JSON];
                              
                              NSMutableArray *locationMemories = [NSMutableArray arrayWithCapacity:memories.count];
                              NSMutableArray *nonlocationMemories = [NSMutableArray arrayWithCapacity:memories.count];
                              
                              for (NSDictionary *attributes in memories) {
                                  Memory *memory = [Memory memoryWithAttributes:attributes];
                                  BOOL isNearby = [attributes[@"nearBy"] boolValue];
                                  
                                  if (isNearby) {
                                      [locationMemories addObject:memory];
                                  }
                                  else {
                                      [nonlocationMemories addObject:memory];
                                  }
                                  
                              }
                              
                              // Sort by creation date
                              NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
                              [mutableMemories sortUsingDescriptors:@[dateSorter]];
                              [locationMemories sortUsingDescriptors:@[dateSorter]];
                              [nonlocationMemories sortUsingDescriptors:@[dateSorter]];
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:locationMemories];
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:nonlocationMemories];
                              
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories],[NSArray arrayWithArray:locationMemories],[NSArray arrayWithArray:nonlocationMemories]);
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

+ (void)fetchUserMemoriesWithUserToken:(NSString *)userToken
                        memorySortType:(MemorySortType)memorySortType
                                 count:(NSInteger)count
                               pageKey:(NSString *)pageKey
                     completionHandler:(void (^)(NSArray *memories, NSArray *locationMemories, NSArray *nonLocationMemories, NSString *nextPageKey))completionHandler
                          errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/memories/user/%@", userToken];
    
    // Convert memorySortType param into its server-recognizable string representation
    NSString *sortType = @"RECENCY"; // Default sort type
    if (MemorySortTypePopularity == memorySortType) {
        sortType = @"POPULARITY";
    } else if (MemorySortTypePopularityRecency == memorySortType) {
        sortType = @"POPULARITY_RECENCY";
    }
    
    // Set the params
    NSMutableDictionary *params = [@{ @"memorySortType" : sortType,
                              @"limit" : @(count) } mutableCopy];
    if (nil != pageKey) {
        params[@"pageKey"] = pageKey;
    }
    
    // Make the call
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                             
                              // dispatch the processing to a background thread to avoid tying up
                              // the main thread 
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  
                                  NSDictionary *JSON = (NSDictionary *)result;
                                  
                                  NSArray *memories = JSON[@"memories"];
                                  NSString *nextPageKey = [JSON objectForKey:@"nextPageKey"];
                                  NSMutableArray *mutableMemories = [self translateMemoriesFromResponse:JSON];
                                  
                                  NSMutableArray *locationMemories = [NSMutableArray arrayWithCapacity:memories.count];
                                  NSMutableArray *nonlocationMemories = [NSMutableArray arrayWithCapacity:memories.count];
                                  
                                  for (NSDictionary *attributes in memories) {
                                      Memory *memory = [Memory memoryWithAttributes:attributes];
                                      BOOL isNearby = [attributes[@"nearBy"] boolValue];
                                      
                                      if (isNearby) {
                                          [locationMemories addObject:memory];
                                      }
                                      else {
                                          [nonlocationMemories addObject:memory];
                                      }
                                  }

                                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                                      
                                      [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:locationMemories];
                                      [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:nonlocationMemories];
                                    
                                      if (completionHandler) {
                                          completionHandler([NSArray arrayWithArray:mutableMemories],[NSArray arrayWithArray:locationMemories],[NSArray arrayWithArray:nonlocationMemories], nextPageKey);
                                      }
                                  });
                              });
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

+ (void)fetchMemoryParticipantsWithMemoryID:(NSInteger)memoryID
                          completionHandler:(void (^)(NSArray *participants))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/memories/%i/participants", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              BOOL hasParticipants = YES;
                              
                              if ([resultsDict respondsToSelector:@selector(objectForKey:)]){
                                  NSString *resultStr = resultsDict[@"success"];
                                  if ([resultStr intValue] == 1) {
                                      hasParticipants = NO;
                                  }
                              }
                              if (hasParticipants){
                                  NSArray *resultsArray = (NSArray *)result;
                                  NSMutableArray *mutableParticipants = [NSMutableArray arrayWithCapacity:resultsArray.count];
                                  
                                  for (int i = 0; i<[resultsArray count]; i++){
                                      NSDictionary *attributes = resultsArray[i];
                                      Person *person = [[Person alloc] initWithAttributes:attributes];
                                      [mutableParticipants addObject:person];
                                  }
                                  
                                  if (completionHandler) {
                                      completionHandler([NSArray arrayWithArray:mutableParticipants]);
                                  }
                              } else {
                                  NSArray *array = [[NSArray alloc] init];
                                  if (completionHandler) {
                                      completionHandler(array);
                                  }
                              }
                              
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

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
          faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/memories";
    
    int fShareEnabled = 0;
    if (fbShareEnabled) {
        NSLog(@"fb share enabled??");
        fShareEnabled = 1;
        [Flurry logEvent:@"MEMORY_SHARED_TO_FB"];
    }
    
    int tShareEnabled = 0;
    if (twitShareEnabled) {
        tShareEnabled = 1;
        NSLog(@"twit share enabled??");
        [Flurry logEvent:@"MEMORY_SHARED_TO_TWITTER"];
    }
    
    int isAnonymousPost = 0;
    if (isAnon) {
        isAnonymousPost = 1;
        [Flurry logEvent:@"MEMORY_POSTED_AS_ANON"];
    }
    
    
    
    NSString *addyId = [NSString stringWithFormat:@"%i",(int)addressId];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    params = [@{ @"taggedUserIds": includedUserIds,
                              @"text": memoryText,
                              @"assetIds": assetIds,
                              @"addressId": addyId,
                              @"latitude": @(gpsLat),
                              @"longitude": @(gpsLong),
                              @"hashtags" : hashtags,
                              @"accessType": access,
                              @"type": @(currType),
                              @"shareToFacebook" : @(fShareEnabled),
                              @"shareToTwitter" : @(tShareEnabled),
                              @"isAnon" : @(isAnonymousPost)
                 } mutableCopy];
    
    
    if (territory.neighborhoodName) {
        params[@"neighborhood"] = territory.neighborhoodName;
    }
    if (territory.cityName.length > 0) {
        params[@"city"] = territory.cityName;
    }
    if (territory.county.length > 0) {
        params[@"county"] = territory.county;
    }
    if (territory.stateAbbr.length) {
        params[@"stateAbbr"] = territory.stateAbbr;
    }
    if (territory.countryAbbr.length) {
        params[@"countryAbbr"] = territory.countryAbbr;
    }
    
    
    NSLog(@"params %@",params);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              NSLog(@"result %@",result);
                              NSDictionary *resDict = (NSDictionary *)result;
                              

                              
                              NSMutableDictionary *venueDictionary  = [NSMutableDictionary dictionary];
                              Venue *venueForTerritory;
                              
                              if ([resDict objectForKey:@"displayName"]) {
                                  venueDictionary[@"displayName"] = [resDict objectForKey:@"displayName"];
                              }
                              if ([resDict objectForKey:@"neighborhood"]) {
                                  venueDictionary[@"neighborhood"] = [resDict objectForKey:@"neighborhood"];
                              }
                              if ([resDict objectForKey:@"city"]) {
                                  venueDictionary[@"city"] = [resDict objectForKey:@"city"];
                              }
                              if ([resDict objectForKey:@"state"]) {
                                  venueDictionary[@"state"] = [resDict objectForKey:@"state"];
                              }
                              if ([resDict objectForKey:@"country"]) {
                                  venueDictionary[@"country"] = [resDict objectForKey:@"country"];
                              }
                              if ([resDict objectForKey:@"county"]) {
                                  venueDictionary[@"county"] = [resDict objectForKey:@"county"];
                              }
                              if ([resDict objectForKey:@"specificity"]) {
                                  venueDictionary[@"specificity"] = [resDict objectForKey:@"specificity"];
                              }
                              if ([resDict objectForKey:@"latitude"]) {
                                  venueDictionary[@"latitude"] = [resDict objectForKey:@"latitude"];
                              }
                              if ([resDict objectForKey:@"longitude"]) {
                                  venueDictionary[@"longitude"] = [resDict objectForKey:@"longitude"];
                              }
                              if ([resDict objectForKey:@"totalMemories"]) {
                                  venueDictionary[@"totalMemories"] = [resDict objectForKey:@"totalMemories"];
                              }
                              if ([resDict objectForKey:@"totalStars"]) {
                                  venueDictionary[@"totalStars"] = [resDict objectForKey:@"totalStars"];
                              }
                              
                              
                              if ([resDict objectForKey:@"addressId"]) {
                                  venueDictionary[@"addressId"] = [resDict objectForKey:@"addressId"];
                                  NSDictionary *vDict = [NSDictionary dictionaryWithDictionary:venueDictionary];
                                  venueForTerritory = [[Venue alloc] initWithAttributes:vDict];
                              }
                              
                              int memID = (int)[resDict[@"number"] integerValue];
                              
                              if ([resDict objectForKey:@"createdMemoryId"]) {
                                  memID = (int)[resDict[@"createdMemoryId"] integerValue];
                              }
                              
                              NSString *memKey;
                              
                              if ([resDict objectForKey:@"createdMemoryKey"]) {
                                  
                                  memKey = [resDict objectForKey:@"createdMemoryKey"];
                              }
                              
                              
                              [Flurry logEvent:@"MEMORY_POSTED"];
                              
                              if (currType == 1) {
                                 [Flurry logEvent:@"MEMORY_TEXT_POSTED"];
                              }
                              if (currType == 2) {
                                  [Flurry logEvent:@"MEMORY_IMAGE_POSTED"];
                              }
                              if (currType == 3) {
                                  [Flurry logEvent:@"MEMORY_VIDEO_POSTED"];
                              }
                              
                              if (resultCallback) {
                                  resultCallback(memID,venueForTerritory,memKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                                  message:@"There was an error posting this memory. Please try again"
                                                                                 delegate:nil
                                                                        cancelButtonTitle:@"Dismiss"
                                                                        otherButtonTitles:nil];
                              [alertView show];
                              
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)updateMemoryParticipantsWithMemoryID:(NSInteger)memoryID
                        taggedUserIdsUserIds:(NSArray *)taggedUserIdsUserIds
                              resultCallback:(void (^)(NSDictionary *results))resultCallback
                               faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/%i/taggedUsers", (int)memoryID];
    NSDictionary *params = @{ @"taggedUserIds": [taggedUserIdsUserIds componentsJoinedByString:@","] };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resDict = (NSDictionary *)result;
                              
                              if (resultCallback) {
                                  resultCallback(resDict);
                              }
                          } faultCallback:^(NSError *fault) {
                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                                                  message:@"There was an error tagging this memory. Please try again"
                                                                                 delegate:nil
                                                                        cancelButtonTitle:@"Dismiss"
                                                                        otherButtonTitles:nil];
                              [alertView show];
                              
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)fetchMemoriesFeedWithCount:(NSInteger) count
                         idsBefore:(NSInteger) before
                 completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved))completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler {
    double gpsLat = 0;
    double gpsLong = 0;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        gpsLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
        gpsLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    }

    NSDictionary *params = @{ @"latitude": @(gpsLat),
                              @"longitude": @(gpsLong),
                              @"count": @(count),
                              @"idsBefore": @(before)
                              };
    
    [MeetManager fetchMemoriesFeedWithParams:params completionHandler:completionHandler errorHandler:errorHandler];
}

+ (void)fetchMemoriesFeedWithCount:(NSInteger) count
                 completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved))completionHandler
                      errorHandler:(void (^)(NSError *error))errorHandler {
   
    double gpsLat = 0;
    double gpsLong = 0;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        gpsLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
        gpsLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    }
    
    NSDictionary *params = @{ @"latitude": @(gpsLat),
                              @"longitude": @(gpsLong),
                              @"count": @(count)
                              };
    
    [MeetManager fetchMemoriesFeedWithParams:params completionHandler:completionHandler errorHandler:errorHandler];
    
}

+ (void)fetchNewFeedCountSince:(NSInteger)milisecSinceLastChecked
             completionHandler:(void (^)(NSInteger newCount))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler {
    NSDictionary *params = @{ @"beforeMillisAgo": @(milisecSinceLastChecked) };
    NSString *url = @"/memories/feedNewCount";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              int newCount = 0;
                              if ([JSON respondsToSelector:@selector(objectForKeyedSubscript:)]) {
                                  newCount = [JSON[@"number"] intValue];
                              }
                              if (completionHandler) {
                                 completionHandler(newCount);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchMemoriesFeedWithParams:(NSDictionary *) params
                  completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/feed";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              int count = [JSON[@"memories_count"] intValue];
                              
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  
                                  // Array to hold memories
                                  NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                                  
                                  NSSortDescriptor *idSorter = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO];
                                  [mutableMemories sortUsingDescriptors:@[idSorter]];
                                  
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                                      
                                      if (completionHandler) {
                                          completionHandler([NSArray arrayWithArray:mutableMemories], count);
                                      }
                                  });
                              });
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

- (void)fetchFeaturedMemoriesWithLatitude:(CGFloat)latitude
                              longitude:(CGFloat)longitude
                  withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/popularHere";
    NSDictionary *params = @{ @"latitude": @(latitude),
                              @"longitude": @(longitude),
                              };
    
    //NSLog(@"url %@",url);
    //NSLog(@"params %@",params);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"featured url %@ result %@",url,result);
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              
                             //translate memories into featured content model objects
                              NSMutableArray *tempContent = [[NSMutableArray alloc] init];
                              for (int i = 0; i < mutableMemories.count; i++) {
                                  SPCFeaturedContent *fc = [[SPCFeaturedContent alloc] initWithFeaturedMemory:mutableMemories[i]];
                                  [tempContent addObject:fc];
                              }
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:tempContent]);
                              }
                          } faultCallback:^(NSError *fault) {
                              //NSLog(@"fault %@",fault);
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchMontageWorldMemoriesWithCurrentMemoryKeys:(NSArray *)memoryKeys
                                     completionHandler:(void (^)(NSArray *memories, BOOL wasMontageStale))completionHandler
                                          errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/montage";
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    if (nil != memoryKeys) {
        // Create the string of memory keys
        NSMutableString *memoryKeysList = [[NSMutableString alloc] init];
        for (NSInteger i = 0; i < memoryKeys.count; ++i) {
            NSString *memoryKey = [memoryKeys objectAtIndex:i];
            [memoryKeysList appendFormat:@"%@,", memoryKey];
            
            if (i == memoryKeys.count - 1) {
                [memoryKeysList deleteCharactersInRange:NSMakeRange(memoryKeysList.length - 1, 1)];
            }
        }
        
        [params setObject:memoryKeysList forKey:@"keyList"];
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              BOOL wasMontageStale = [JSON[@"wasMontageStale"] boolValue];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], wasMontageStale);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchMontageNearbyMemoriesWithCurrentMemoryKeys:(NSArray *)memoryKeys
                                               latitude:(CGFloat)latitude
                                     longitude:(CGFloat)longitude
                         withCompletionHandler:(void (^)(NSArray *memories, BOOL wasMontageStale))completionHandler
                                  errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/nearby/montage";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{ @"latitude": @(latitude),
                                                                                   @"longitude": @(longitude)
                                                                                   }];
    
    if (nil != memoryKeys) {
        // Create the string of memory keys
        NSMutableString *memoryKeysList = [[NSMutableString alloc] init];
        for (NSInteger i = 0; i < memoryKeys.count; ++i) {
            NSString *memoryKey = [memoryKeys objectAtIndex:i];
            [memoryKeysList appendFormat:@"%@,", memoryKey];
            
            if (i == memoryKeys.count - 1) {
                [memoryKeysList deleteCharactersInRange:NSMakeRange(memoryKeysList.length - 1, 1)];
            }
        }
        
        [params setObject:memoryKeysList forKey:@"keyList"];
    }
    
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              BOOL wasMontageStale = [JSON[@"wasMontageStale"] boolValue];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], wasMontageStale);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchRegionMemoriesWithLatitude:(CGFloat)latitude
                              longitude:(CGFloat)longitude
                                 radius:(CGFloat)radius
                  withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/region";
    NSDictionary *params = @{ @"latitude": @(latitude),
                              @"longitude": @(longitude),
                              @"radius": @(radius)
                              };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchRegionMemoriesWithLatitude:(CGFloat)latitude
                              longitude:(CGFloat)longitude
                                 radius:(CGFloat)radius
                         omitIdsBetween:(NSInteger)omitIdMin
                                    and:(NSInteger)omitIdMax
                  withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/region";
    
    if (omitIdMin > omitIdMax) {
        NSInteger swap = omitIdMin;
        omitIdMin = omitIdMax;
        omitIdMax = swap;
    }
    
    NSDictionary *params = @{ @"latitude": @(latitude),
                              @"longitude": @(longitude),
                              @"radius": @(radius),
                              @"omitIdRange": [NSString stringWithFormat:@"%ld,%ld", (long)omitIdMin, (long)omitIdMax]
                              };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchRegionMemoriesWithSouthWestLatitude:(CGFloat)southWestLatitude
                              southWestLongitude:(CGFloat)southWestLongitude
                               northEastLatitude:(CGFloat)northEastLatitude
                              northEastLongitude:(CGFloat)northEastLongitude
                                         pageKey:(NSString *)pageKey
                           withCompletionHandler:(void (^)(NSArray *memories, NSString *nextPageKey))completionHandler
                                    errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/regionV2";
    NSDictionary *params;
    if (pageKey) {
        params = @{ @"southWestLatitude": @(southWestLatitude),
                    @"southWestLongitude": @(southWestLongitude),
                    @"northEastLatitude": @(northEastLatitude),
                    @"northEastLongitude": @(northEastLongitude),
                    @"pageKey" : pageKey
                    };
    } else {
        params = @{ @"southWestLatitude": @(southWestLatitude),
                    @"southWestLongitude": @(southWestLongitude),
                    @"northEastLatitude": @(northEastLatitude),
                    @"northEastLongitude": @(northEastLongitude)
                    };
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              NSString *nextPageKey = JSON[@"nextPageKey"];
                              
                              NSLog(@"Got %lu memories with nextPageKey %@, bounded from %f, %f to %f, %f",
                                    (unsigned long)mutableMemories.count, nextPageKey, southWestLatitude, southWestLongitude, northEastLatitude, northEastLongitude);
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], nextPageKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchRegionMemoriesWithCity:(SPCCity *)city
                            pageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *memories, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/fly";
    
    NSDictionary *params;
    if (!pageKey) {
        params = @{ @"city" : city.cityName ?: @"",
                    @"county" : city.county ?: @"",
                    @"stateAbbr" : city.stateAbbr ?: @"",
                    @"countryAbbr" : city.countryAbbr ?: @"" };
    } else {
        params = @{ @"city" : city.cityName ?: @"",
                    @"county" : city.county ?: @"",
                    @"stateAbbr" : city.stateAbbr ?: @"",
                    @"countryAbbr" : city.countryAbbr ?: @"",
                    @"pageKey" : pageKey,
                    @"nextPageKey" : pageKey };     // support the legacy argument for this feature
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              NSString *nextPageKey = JSON[@"nextPageKey"];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], nextPageKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchRegionMemoriesWithNeighborhood:(SPCNeighborhood *)neighborhood
                                    pageKey:(NSString *)pageKey
                          completionHandler:(void (^)(NSArray *memories, NSString *nextPageKey))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories/fly";
    
    NSDictionary *params;
    if (!pageKey) {
        params = @{ @"neighborhood" : neighborhood.neighborhoodName ?: @"",
                    @"city" : neighborhood.cityName ?: @"",
                    @"county" : neighborhood.county ?: @"",
                    @"stateAbbr" : neighborhood.stateAbbr ?: @"",
                    @"countryAbbr" : neighborhood.countryAbbr ?: @"" };
    } else {
        params = @{ @"neighborhood" : neighborhood.neighborhoodName ?: @"",
                    @"city" : neighborhood.cityName ?: @"",
                    @"county" : neighborhood.county ?: @"",
                    @"stateAbbr" : neighborhood.stateAbbr ?: @"",
                    @"countryAbbr" : neighborhood.countryAbbr ?: @"",
                    @"pageKey" : pageKey,
                    @"nextPageKey" : pageKey };     // support the legacy argument for this feature
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              NSString *nextPageKey = JSON[@"nextPageKey"];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], nextPageKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchLocationMemoriesFeedForVenue:(Venue *)venue
                   includeFeaturedContent:(BOOL)includeFeaturedContent
                    withCompletionHandler:(void (^)(NSArray *memories, NSArray *featuredContent,NSArray *venueHashTags))completionHandler
                             errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories";
    
    float gpsLat, gpsLong;
    if (includeFeaturedContent) {
        // use our current lat/lng
        gpsLat = 0;
        gpsLong = 0;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            gpsLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
            gpsLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
        }

    } else {
        gpsLat = venue.latitude.floatValue;
        gpsLong = venue.longitude.floatValue;
    }
    
    
    
    NSDictionary *params;
    
    if (includeFeaturedContent) {
        params = @{ @"addressId": @(venue.addressId),
                    @"latitude": @(gpsLat),
                    @"longitude": @(gpsLong)
                    };
    } else {
        // omit featured content by specifying a start time
        params = @{ @"addressId": @(venue.addressId),
                    @"latitude": @(gpsLat),
                    @"longitude": @(gpsLong),
                    @"startTime": @(0)
                    };
    }
    //NSLog(@"params %@",params);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"url %@ result %@",url,result);
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *hashtags = JSON[@"hashtags"];
                              NSMutableArray *mutableHashtags = [NSMutableArray arrayWithCapacity:hashtags.count];
                              
                              for (NSDictionary *attributes in hashtags) {
                                  NSString *cleanTag = attributes[@"name"];
                                  NSString *hashTag = [NSString stringWithFormat:@"#%@",cleanTag];
                                  [mutableHashtags addObject:hashTag];
                              }
                              
                              //NSLog(@"mutable hashtags %@",mutableHashtags);
                              NSArray *venueHashTags = mutableHashtags.count > 0 ? [NSArray arrayWithArray:mutableHashtags] : nil;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              
                              NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
                              [mutableMemories sortUsingDescriptors:@[dateSorter]];
                              
                              NSArray *featuredContent = includeFeaturedContent ? [NSArray arrayWithArray:[MeetManager translateFeaturedContentFromResponse:JSON]] : nil;
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenues:featuredContent];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], featuredContent, venueHashTags);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  //NSLog(@"url %@ fault %@",url,fault);
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchLocationMemoriesFeedForVenue:(Venue *)venue
                             createdSince:(NSDate *)createdSince
                    withCompletionHandler:(void (^)(NSArray *memories))completionHandler
                             errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSString *url = @"/memories";
    
    float gpsLat = venue.latitude.floatValue;
    float gpsLong = venue.longitude.floatValue;
    
    NSDictionary *params;
    
    // omit featured content by specifying a start time
    NSTimeInterval millis = ceil([createdSince timeIntervalSince1970] * 1000);
    params = @{ @"addressId": @(venue.addressId),
                @"latitude": @(gpsLat),
                @"longitude": @(gpsLong),
                @"startTime":[NSString stringWithFormat:@"%lld", (long long)millis]
                };
    //NSLog(@"params %@",params);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"url %@ result %@",url,result);
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              
                              NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
                              [mutableMemories sortUsingDescriptors:@[dateSorter]];
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              
                              for (Memory *memory in mutableMemories) {
                                  memory.recordID = memory.recordID + rand()%1000;
                              }
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  //NSLog(@"url %@ fault %@",url,fault);
                                  errorHandler(fault);
                              }
                          }];

    
}

+ (void)fetchLocationMemoriesFeedForLocation:(NSInteger)addressId
                            manuallySelected:(BOOL)manuallySelected
                      includeFeaturedContent:(BOOL)includeFeaturedContent
                       withCompletionHandler:(void (^)(NSArray *memories, NSArray *featuredContent))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = @"/memories";
    
    double gpsLat = 0;
    double gpsLong = 0;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        gpsLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
        gpsLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    }
    
    NSDictionary *params = @{ @"addressId": @(addressId),
                              @"latitude": @(gpsLat),
                              @"longitude": @(gpsLong)
                              };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              // dispatch the processing to a background thread to avoid tying up
                              // the main thread with string parsing.
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  NSDictionary *JSON = (NSDictionary *)result;
                                  
                                  NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                                  
                                  NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:NO];
                                  [mutableMemories sortUsingDescriptors:@[dateSorter]];
                                  
                                  NSArray *featuredContent = includeFeaturedContent ? [NSArray arrayWithArray:[MeetManager translateFeaturedContentFromResponse:JSON]] : nil;
                                  
                                  [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                                  [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenues:featuredContent];
                                  
                                  if (completionHandler) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          completionHandler([NSArray arrayWithArray:mutableMemories], featuredContent);
                                      });
                                  }
                              });
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchPopularMemoriesByUserWithToken:(NSString *)userToken
                                       city:(SPCCity *)city
                                      count:(NSInteger)count
                          completionHandler:(void (^)(NSArray *memories))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    if (city.cityName.length > 0) {
        params[@"city"] = city.cityName;
    }
    if (city.county.length > 0) {
        params[@"county"] = city.county;
    }
    if (city.stateAbbr.length) {
        params[@"stateAbbr"] = city.stateAbbr;
    }
    if (city.countryAbbr.length) {
        params[@"countryAbbr"] = city.countryAbbr;
    }
    
    [MeetManager fetchPopularMemoriesByUserToken:userToken
                                  locationParams:params
                                           count:count
                               completionHandler:completionHandler
                                    errorHandler:errorHandler];
}

+ (void)fetchPopularMemoriesByUserWithToken:(NSString *)userToken
                               neighborhood:(SPCNeighborhood *)neighborhood
                                      count:(NSInteger)count
                          completionHandler:(void (^)(NSArray *memories))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    if (neighborhood.neighborhood.length > 0) {
        params[@"neighborhood"] = neighborhood.neighborhood;
    }
    if (neighborhood.cityName.length > 0) {
        params[@"city"] = neighborhood.cityName;
    }
    if (neighborhood.county.length > 0) {
        params[@"county"] = neighborhood.county;
    }
    if (neighborhood.stateAbbr.length) {
        params[@"stateAbbr"] = neighborhood.stateAbbr;
    }
    if (neighborhood.countryAbbr.length) {
        params[@"countryAbbr"] = neighborhood.countryAbbr;
    }
    
    [MeetManager fetchPopularMemoriesByUserToken:userToken
                                  locationParams:params
                                           count:count
                               completionHandler:completionHandler
                                    errorHandler:errorHandler];
    
}

+ (void)fetchPopularMemoriesByUserToken:(NSString *)userToken
                         locationParams:(NSDictionary *)locationParams
                                  count:(NSInteger)count
                      completionHandler:(void (^)(NSArray *memories))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:locationParams];
    params[@"count"] = @(count);
    NSString *url = [NSString stringWithFormat:@"/memories/%@/popularInArea", userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              NSArray *memories;
                              
                              NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starsCount" ascending:NO];
                              [mutableMemories sortUsingDescriptors:@[starSorter]];
                              
                              if (mutableMemories.count > count) {
                                  memories = [mutableMemories subarrayWithRange:NSMakeRange(0, count)];
                              } else {
                                  memories = [NSArray arrayWithArray:mutableMemories];
                              }
                              
                              if (completionHandler) {
                                  completionHandler(memories);
                              }
    } faultCallback:^(NSError *fault) {
        // fault
        if (errorHandler) {
            errorHandler(fault);
        }
    }];
}


+ (void)fetchMemoryWithMemoryId:(NSInteger)memoryID
                 resultCallback:(void (^)(NSDictionary *))resultCallback
                  faultCallback:(void (^)(NSError *error))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/%i", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)fetchLookBackMemoriesWithID:(NSInteger)notificationID
                  completionHandler:(void (^)(NSArray *memories, NSInteger totalRetrieved, NSDate *lookBackDate))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler  {
    NSString *url = [NSString stringWithFormat:@"/memories/byNotification/%li", (long)notificationID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              int count = [JSON[@"memories_count"] intValue];
                              
                              NSNumber *reportTime = (NSNumber *)[TranslationUtils valueOrNil:JSON[@"reportTime"]];
                              NSDate *lookBackDate;
                              
                              if (reportTime) {
                                  NSTimeInterval seconds = [reportTime doubleValue];
                                  NSTimeInterval miliseconds = seconds/1000;
                                  lookBackDate = [NSDate dateWithTimeIntervalSince1970:miliseconds];
                              }
                              
                              // Array to hold memories
                              NSMutableArray *mutableMemories = [MeetManager translateMemoriesFromResponse:JSON];
                              
                              NSSortDescriptor *idSorter = [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO];
                              [mutableMemories sortUsingDescriptors:@[idSorter]];
                              
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:mutableMemories];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableMemories], count,lookBackDate);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (NSMutableArray *)translateMemoriesFromResponse:(NSDictionary *)JSON {
    NSArray *memories = JSON[@"memories"];
    NSMutableArray *mutableMemories = [NSMutableArray arrayWithCapacity:memories.count];
    
    for (NSDictionary *attributes in memories) {
        [mutableMemories addObject:[Memory memoryWithAttributes:attributes]];
    }
    
    return mutableMemories;
}

+ (NSMutableArray *)translateFeaturedContentFromResponse:(NSDictionary *)JSON {
    NSDictionary *featuredContentListWrapper = JSON[@"featuredContentList"];
    NSArray *featuredContentList = featuredContentListWrapper[@"content"];
    NSMutableArray *mutableContent = [NSMutableArray arrayWithCapacity:featuredContentList.count];
    for (NSDictionary *fc in featuredContentList) {
        SPCFeaturedContent *spcFC = [[SPCFeaturedContent alloc] initWithAttributes:fc];
        [mutableContent addObject:spcFC];
    }
    return mutableContent;
}

+ (void)deleteMemoryWithMemoryId:(NSInteger)memoryID
                  resultCallback:(void (^)(NSDictionary *))resultCallback
                   faultCallback:(void (^)(NSError *))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/%i", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)reportMemoryWithMemoryId:(NSInteger)memoryID
                      reportType:(SPCReportType)reportType
                            text:(NSString *)text
                  resultCallback:(void (^)(NSDictionary *))resultCallback
                   faultCallback:(void (^)(NSError *))faultCallback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // Process the report type
    NSString *finalReportType = @""; // Default
    
    if (SPCReportTypeAbuse == reportType) {
        finalReportType = @"ABUSE";
    } else if (SPCReportTypePersonal == reportType) {
        finalReportType = @"PERSONAL";
    } else if (SPCReportTypeSpam == reportType) {
        finalReportType = @"SPAM";
    }
    
    [params setObject:finalReportType forKey:@"reportType"];
    
    // Process the text
    if (0 < text.length) {
        [params setObject:text forKey:@"text"];
    }
    
    NSString *url = [NSString stringWithFormat:@"/memories/%i/issues", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              [Flurry logEvent:@"MEMORY_REPORTED"];
                              
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)updateMemoryWithMemoryId:(NSInteger)memoryID
                       addressId:(NSInteger)addressID
                  resultCallback:(void (^)(NSDictionary *results))resultCallback
                   faultCallback:(void (^)(NSError *fault))faultCallback {
    NSDictionary *params = @{ @"addressId": @(addressID) };
    NSString *url = [NSString stringWithFormat:@"/memories/%i/update", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                              
                          } faultCallback:^(NSError *error) {
                              NSLog(@"url %@ params %@ error %@",url,params,error);
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)fetchStarsWithMemoryId:(NSInteger)memoryID
             completionHandler:(void (^)(NSArray *stars))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/memories/%i/stars", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSArray *persons;
                              if ([result isKindOfClass:[NSArray class]]) {
                                  NSArray *personsJSON = (NSArray *)result;
                                  NSMutableArray *mutablePersons = [NSMutableArray arrayWithCapacity:personsJSON.count];
                                  
                                  for (NSDictionary *attributes in personsJSON) {
                                      Star *person = [[Star alloc] initWithAttributes:attributes];
                                      [mutablePersons addObject:person];
                                  }
                                  
                                  persons = [NSArray arrayWithArray:mutablePersons];
                              } else {
                                  persons = [NSArray array];
                              }
                              
                              if (completionHandler) {
                                  completionHandler(persons);
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}



+ (void)addStarToMemory:(Memory *)memory
                     resultCallback:(void (^)(NSDictionary *))resultCallback
                      faultCallback:(void (^)(NSError *))faultCallback {
    [MeetManager addStarToMemory:memory asSockPuppet:nil resultCallback:resultCallback faultCallback:faultCallback];
}

+ (void)addStarToMemory:(Memory *)memory
           asSockPuppet:(Person *)sockPuppet
         resultCallback:(void (^)(NSDictionary *))resultCallback
          faultCallback:(void (^)(NSError *))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/%i/stars", (int)memory.recordID];
    NSDictionary *params = nil;
    if (sockPuppet) {
        params = @{ @"sockpuppetKey" : sockPuppet.userToken };
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              [Flurry logEvent:@"MEMORY_STARRED"];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidStarMemory object:memory];
                              
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                                NSLog(@"url %@ error %@",url,error);
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)deleteStarFromMemory:(Memory *)memory
                     resultCallback:(void (^)(NSDictionary *))resultCallback
                      faultCallback:(void (^)(NSError *))faultCallback {
    [MeetManager deleteStarFromMemory:memory asSockPuppet:nil resultCallback:resultCallback faultCallback:faultCallback];
}

+ (void)deleteStarFromMemory:(Memory *)memory
                asSockPuppet:(Person *)sockPuppet
              resultCallback:(void (^)(NSDictionary *))resultCallback
               faultCallback:(void (^)(NSError *))faultCallback {
    
    NSString *url = [NSString stringWithFormat:@"/memories/%i/stars", (int)memory.recordID];
    NSDictionary *params = nil;
    if (sockPuppet) {
        params = @{ @"sockpuppetKey" : sockPuppet.userToken };
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidUnstarMemory object:memory];
                              
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                              NSLog(@"url %@ error %@",url,error);
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)fetchNearbyAddressesWithResultCallback:(void (^)(NSArray *))resultCallback faultCallback:(void (^)(NSError *))faultCallback {
    double gpsLat = 0;
    double gpsLong = 0;
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        gpsLat = [LocationManager sharedInstance].currentLocation.coordinate.latitude;
        gpsLong = [LocationManager sharedInstance].currentLocation.coordinate.longitude;
    }
    
    [MeetManager fetchNearbyAddressesWithLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
}

+ (void)fetchNearbyAddressesWithLatitude:(CGFloat)latitude
                               longitude:(CGFloat)longitude
                          resultCallback:(void (^)(NSArray *))resultCallback
                           faultCallback:(void (^)(NSError *))faultCallback {
    [MeetManager fetchNearbyAddressesWithLatitude:latitude longitude:longitude googleVenueIds:nil resultCallback:resultCallback faultCallback:faultCallback];
}

+ (void)fetchNearbyAddressesWithLatitude:(CGFloat)latitude
                               longitude:(CGFloat)longitude
                       googleVenueIds:(NSArray *)googleVenueIds
                          resultCallback:(void (^)(NSArray *))resultCallback
                           faultCallback:(void (^)(NSError *))faultCallback {
    NSString *url = @"/location/list";
    NSDictionary *params;
    if (!googleVenueIds) {
        params = @{ @"latitude": @(latitude), @"longitude": @(longitude) };
    } else {
        params = @{ @"latitude": @(latitude), @"longitude": @(longitude), @"hintVenueIds": [googleVenueIds componentsJoinedByString:@","] };
    }
    
    [Flurry logEvent:@"NEARBY_ADDRESSES" withParameters:params];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *locations = JSON[@"locations"];
                              
                              NSMutableArray *nearbyVenues = [NSMutableArray arrayWithCapacity:locations.count];
                              
                              for (NSDictionary *attributes in locations) {
                                  Venue *tempVenue = [[Venue alloc] initWithAttributes:attributes];
                                  [nearbyVenues addObject:tempVenue];
                              }
                              
                              if (resultCallback) {
                                  resultCallback(nearbyVenues);
                              }
                          } faultCallback:^(NSError *error) {
                              [MeetManager fetchNearbyAddressesLegacyWithLatitude:latitude longitude:longitude resultCallback:resultCallback faultCallback:faultCallback];
                          }];
}

+ (void)fetchNearbyAddressesLegacyWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude
                          resultCallback:(void (^)(NSArray *))resultCallback
                           faultCallback:(void (^)(NSError *))faultCallback {
    NSString *url = @"/location/addressNamesOfInterestNearby";
    
    NSDictionary *params = @{ @"latitude": @(latitude), @"longitude": @(longitude) };
    
    [Flurry logEvent:@"NEARBY_ADDRESSES" withParameters:params];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *locations = JSON[@"addresses"];
                              
                              NSMutableArray *nearbyVenues = [NSMutableArray arrayWithCapacity:locations.count];
                              
                              for (NSDictionary *attributes in locations) {
                                  Venue *tempVenue = [[Venue alloc] initWithAttributes:attributes];
                                  [nearbyVenues addObject:tempVenue];
                              }
                              
                              if (resultCallback) {
                                  resultCallback(nearbyVenues);
                              }
                          } faultCallback:^(NSError *error) {
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)postVenueWithLat:(double)gpsLat
               longitude:(double)gpsLong
                    name:(NSString *)name
     locationMainPhotoId:(int)mainPhotoId
          resultCallback:(void (^)(Venue *))resultCallback
           faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/location";
    NSDictionary *params;
    
    if (mainPhotoId == 0) {
        params = @{ @"latitude": @(gpsLat),
                    @"longitude": @(gpsLong),
                    @"locationName": name
                    };
    } else {
        params = @{ @"latitude": @(gpsLat),
                    @"longitude": @(gpsLong),
                    @"locationName": name,
                    @"locationMainPhotoId": @(mainPhotoId)
                    };
    }
    [Flurry logEvent:@"VENUE_CREATED"];
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDic = (NSDictionary *)result;
                              
                              if (resultCallback) {
                                  resultCallback([[Venue alloc] initWithAttributes:resultsDic]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)updateVenueWithLocationId:(NSInteger)locationId
                             name:(NSString *)name
              locationMainPhotoId:(int)mainPhotoId
                   resultCallback:(void (^)(Venue *))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/location";
    NSDictionary *params;
    
    if (mainPhotoId == 0) {
        params = @{ @"locationId": @(locationId),
                    @"locationName": name
                    };
    } else {
        params = @{ @"locationId": @(locationId),
                    @"locationName": name,
                    @"locationMainPhotoId": @(mainPhotoId)
                    };
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDic = (NSDictionary *)result;
                              
                              if (resultCallback) {
                                  resultCallback([[Venue alloc] initWithAttributes:resultsDic]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)deleteVenueWithLocationId:(NSInteger)locationId
                   resultCallback:(void (^)(Venue *))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/location";
    NSDictionary *params = @{ @"locationId": @(locationId) };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDic = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback([[Venue alloc] initWithAttributes:resultsDic]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)fetchDefaultLocationNameWithLat:(double)gpsLat
                              longitude:(double)gpsLong
                         resultCallback:(void (^)(NSDictionary *resultsDic))resultCallback
                          faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/location/addressName";
    NSDictionary *params = @{ @"latitude": @(gpsLat), @"longitude": @(gpsLong) };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultsDic = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDic);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)fetchCustomPlaceName:(NSInteger)addressId
              resultCallback:(void (^)(NSDictionary *customLocation))resultCallback
               faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/location/custom";
    
    NSDictionary *params = @{ @"addressId": @(addressId) };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *customLocation = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(customLocation);
                              }
                          } faultCallback:^(NSError *error) {
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)fetchNearbyLocationsWithResultCallback:(void (^)(NSArray *locations))resultCallback
                                 faultCallback:(void (^)(NSError *fault))faultCallback {
    NSLog(@"DEPRECATED!  DO NOT CALL THIS!");
    // DEPRECATED
    // I would have gone through and removed all references, but ain't nobody
    // got time for that.  I need to focus on server stuff for now.  Removing
    // this here guarantees that no client calls will ever happen.
    if (faultCallback) {
        faultCallback(nil);
    }
}

+ (void)shareMemoryWithMemoryId:(NSInteger)memoryId
                    serviceName:(NSString *)serviceName
              completionHandler:(void (^)())completionHandler
                   errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/memories/%@/share/%@", @(memoryId), serviceName];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              if (completionHandler) {
                                  completionHandler();
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

+ (void)updateMemoryAccessTypeWithMemoryId:(NSInteger)memoryId
                                accessType:(NSString *)accessType
                         completionHandler:(void (^)())completionHandler
                              errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/memories/%@/accessType", @(memoryId)];
    NSDictionary *params = @{ @"accessType": accessType };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              if (completionHandler) {
                                  completionHandler();
                              }
                          } faultCallback:^(NSError *error) {
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }];
}

#pragma mark - Comments

+ (void)postCommentWithMemoryID:(NSInteger)memoryID
                           text:(NSString *)commentText
                  taggedUserIDs:(NSString *)taggedIDs
                       hashtags:(NSString *)hashtags
                   asSockPuppet:(Person *)sockPuppet
                 resultCallback:(void (^)(NSInteger commentId))resultCallback
                  faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/%i/comments", (int)memoryID];
   
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    params[@"text"] = commentText;
    
    if (taggedIDs.length > 0) {
        params[@"taggedUserIds"] = taggedIDs;
    }
    
    if (hashtags.length > 0) {
        params[@"hashtags"] = hashtags;
    }
    
    if (sockPuppet) {
        params[@"sockpuppetKey"] = sockPuppet.userToken;
    }
    
    NSLog(@"url %@ params %@",url,params);
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resultDic = (NSDictionary *)result;
                              
                              [Flurry logEvent:@"COMMENT_POSTED"];
                              
                              NSInteger commentId = [resultDic[@"number"] integerValue];
                              if (resultCallback) {
                                  resultCallback(commentId);
                              }
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"url %@ fault %@",url,fault);
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)fetchCommentsWithMemoryID:(NSInteger)memoryID
                   resultCallback:(void (^)(NSArray *comments))resultCallback
                    faultCallback:(void (^)(NSError *))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/%i/comments", (int)memoryID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              //NSLog(@"url %@ json %@",url,JSON);
                              NSArray *commentsRaw = JSON[@"comments"];
                              NSMutableArray *mutableComments = [NSMutableArray arrayWithCapacity:commentsRaw.count];
                              
                              for (int i = 0; i<[commentsRaw count]; i++) {
                                  NSDictionary *commentDic = (NSDictionary *)[commentsRaw objectAtIndex:i];
                                  Comment *cleanComment = [[Comment alloc] initWithAttributes:commentDic];
                                  [mutableComments addObject:cleanComment];
                              }
                              
                              if (resultCallback) {
                                  NSSortDescriptor *dateSorter = [[NSSortDescriptor alloc] initWithKey:@"dateCreated" ascending:YES];
                                  [mutableComments sortUsingDescriptors:@[dateSorter]];
                                  
                                  resultCallback([NSArray arrayWithArray:mutableComments]);
                              }
                          } faultCallback:^(NSError *error) {
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
}

+ (void)reportCommentWithCommentId:(NSInteger)commentId
                        reportType:(SPCReportType)reportType
                              text:(NSString *)text
                    resultCallback:(void (^)())resultCallback
                     faultCallback:(void (^)(NSError *fault))faultCallback {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    // Process the report type
    NSString *finalReportType = @""; // Default
    
    if (SPCReportTypeAbuse == reportType) {
        finalReportType = @"ABUSE";
    } else if (SPCReportTypePersonal == reportType) {
        finalReportType = @"PERSONAL";
    } else if (SPCReportTypeSpam == reportType) {
        finalReportType = @"SPAM";
    } else if (SPCReportTypeIncorrect == reportType) {
        finalReportType = @"INCORRECT";
    }
    
    [params setObject:finalReportType forKey:@"reportType"];
    
    // Process the text
    if (0 < text.length) {
        [params setObject:text forKey:@"text"];
    }
    
    NSString *url = [NSString stringWithFormat:@"/memories/comment/%i/issues", (int)commentId];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              if (resultCallback) {
                                  resultCallback();
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)deleteCommentWithCommentId:(NSInteger)commentId
                    resultCallback:(void (^)())resultCallback
                     faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/comment/%i", (int)commentId];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSLog(@"url %@ result %@",url, result);
                              
                              NSDictionary *resDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback([(NSNumber *)resDict[@"value"] boolValue]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)addStarToComment:(Comment *)comment
          resultCallback:(void (^)())resultCallback
           faultCallback:(void (^)(NSError *fault))faultCallback  {
    NSString *url = [NSString stringWithFormat:@"/memories/comment/%i/stars", (int)comment.recordID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidStarComment object:comment];
                              [Flurry logEvent:@"COMMENT_STARRED"];
                              
                              if (resultCallback) {
                                  resultCallback();
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)deleteStarFromComment:(Comment *)comment
               resultCallback:(void (^)())resultCallback
                faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/memories/comment/%i/stars", (int)comment.recordID];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidUnstarComment object:comment];
                              
                              if (resultCallback) {
                                  resultCallback();
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

#pragma mark - Blocking

+ (void)fetchBlockedUsersResultCallback:(void (^)(NSArray *blockedUsers))resultCallback
                          faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/blockUser";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSArray *blockedUsers = (NSArray *)result;
                              NSMutableArray *mutableBlockedUsers = [NSMutableArray arrayWithCapacity:blockedUsers.count];
                              NSMutableArray *mutableBlockedUserIds = [NSMutableArray arrayWithCapacity:blockedUsers.count];
                              
                              for (NSDictionary *attributes in blockedUsers) {
                                  Person *person = [[Person alloc] initWithAttributes:attributes];
                                  [mutableBlockedUsers addObject:person];
                                  [mutableBlockedUserIds addObject:@(person.recordID)];
                              }
                              
                              [MeetManager setBlockedIds:[NSArray arrayWithArray:mutableBlockedUserIds]];
                              [MeetManager setBlockedIdsRefreshTime];
                              
                              if (resultCallback) {
                                  resultCallback([NSArray arrayWithArray:mutableBlockedUsers]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)blockUserWithId:(NSInteger)blockUserId
         resultCallback:(void (^)(NSDictionary *result))resultCallback
          faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = @"/blockUser";
    NSDictionary *params = @{ @"targetUserId": @(blockUserId) };
    
    [Flurry logEvent:@"BLOCK_USER" withParameters:params];

    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              NSDictionary *resultData = (NSDictionary *)result;
                              
                              NSArray *blockedIds = [MeetManager getBlockedIds];
                              if (blockedIds) {
                                  NSMutableArray *mutArray = [NSMutableArray arrayWithArray:blockedIds];
                                  [mutArray addObject:@(blockUserId)];
                                  [MeetManager setBlockedIds:[NSArray arrayWithArray:mutArray]];
                              } else {
                                  [MeetManager setBlockedIds:[NSArray arrayWithObject:@(blockUserId)]];
                              }

                              [[NSNotificationCenter defaultCenter] postNotificationName:kMeetDidBlockUserNotification object:nil];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kBlockedCollectionMarkDirty object:nil];
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidAddBlock object:@(blockUserId)];
                              
                              if (resultCallback) {
                                  resultCallback(resultData);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

+ (void)unblockUserWithId:(NSInteger)userId
           resultCallback:(void (^)())resultCallback
            faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/blockUser/%@", @(userId)];
    NSDictionary *params = @{ @"targetUserId": @(userId) };

    [Flurry logEvent:@"UNBLOCK_USER" withParameters:params];

    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSArray *blockedIds = [MeetManager getBlockedIds];
                              if (blockedIds) {
                                  NSMutableArray *mutArray = [NSMutableArray arrayWithArray:blockedIds];
                                  NSObject *obj = @(userId);
                                  if ([mutArray containsObject:obj]) {
                                      [mutArray removeObject:obj];
                                  }
                                  [MeetManager setBlockedIds:[NSArray arrayWithArray:mutArray]];
                              }
                              
                              // Notify push manager to delete pending notifications from this friend
                              [[NSNotificationCenter defaultCenter] postNotificationName:kMeetDidUnblockUserNotification object:nil];
                              [[NSNotificationCenter defaultCenter] postNotificationName:kBlockedCollectionMarkDirty object:nil];
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidRemoveBlock object:@(userId)];
                              
                              if (resultCallback) {
                                  resultCallback();
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

#pragma mark - Watch Mems

+(void)watchMemoryWithMemoryKey:(NSString *)memoryKey
                 resultCallback:(void (^)(NSDictionary *results))resultCallback
                  faultCallback:(void (^)(NSError *fault))faultCallback {
    
    
    NSString *url = [NSString stringWithFormat:@"/memories/%@/watch", memoryKey];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              
                              [Flurry logEvent:@"MEMORY_WATCHED"];
                              
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                              NSLog(@"url %@ error %@",url,error);
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];

    
}

+(void)unwatchMemoryWithMemoryKey:(NSString *)memoryKey
                   resultCallback:(void (^)(NSDictionary *results))resultCallback
                    faultCallback:(void (^)(NSError *fault))faultCallback {
    
    
    NSString *url = [NSString stringWithFormat:@"/memories/%@/unwatch", memoryKey];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              
                              [Flurry logEvent:@"MEMORY_UNWATCHED"];
                              
                              NSDictionary *resultsDict = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback(resultsDict);
                              }
                          } faultCallback:^(NSError *error) {
                              NSLog(@"url %@ error %@",url,error);
                              if (faultCallback) {
                                  faultCallback(error);
                              }
                          }];
    
}


#pragma mark Accessors

+ (void)setBlockedIds:(NSArray *)blockedIds {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (blockedIds) {
        [userDefault setObject:blockedIds forKey:@"blockedIds"];
    } else {
        [userDefault removeObjectForKey:@"blockedIds"];
    }
}

+ (NSArray *)getBlockedIds {
    NSArray *blockedIds = [[NSUserDefaults standardUserDefaults] arrayForKey:@"blockedIds"];
    return blockedIds;
}

+ (void)getOrFetchBlockedIdsWithCompletionHandler:(void (^)(NSArray *ids))completionHandler {
    NSArray *array = [MeetManager getBlockedIds];
    if (!array) {
        [MeetManager fetchBlockedUsersResultCallback:^(NSArray *blockedUsers) {
            if (completionHandler) {
                completionHandler([MeetManager getBlockedIds]);
            }
        } faultCallback:^(NSError *fault) {
            // provide anyway...
            if (completionHandler) {
                completionHandler([NSArray array]);
            }
        }];
    }
}

+ (void)setBlockedIdsRefreshTime {
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:[NSDate date] forKey:@"blockedIdsRefreshTime"];
}

+ (NSDate *)getBlockedIdsRefreshTime {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"blockedIdsRefreshTime"];
}

#pragma mark - Reputation

+ (void)fetchCitiesWithSearch:(NSString *)searchString
            completionHandler:(void (^)(NSArray *cities))completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/search/getCitiesByPartial"];
    NSDictionary *params = @{ @"partial": searchString };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              NSMutableArray *citiesArray = [[NSMutableArray alloc] init];
                              
                              for (NSDictionary *dict in JSON) {
                                  SPCCity *city = [[SPCCity alloc] initWithAttributes:dict];
                                  [citiesArray addObject:city];
                              }
                              
                              NSArray *unsortedArray = [NSArray arrayWithArray:citiesArray];
                              NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(cityName)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                              
                              NSArray *sortedArray = [unsortedArray sortedArrayUsingDescriptors:@[sortDescriptor]];
                              if (completionHandler) {
                                  completionHandler(sortedArray);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchRankedUserForCity:(SPCCity *)city
             completionHandler:(void (^)(NSArray *cityUsers, NSInteger cityPop))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/search/getRankedUsersByCity"];
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];

    if (city.cityName.length > 0) {
        params[@"city"] = city.cityName;
    }
    if (city.county.length > 0) {
        params[@"county"] = city.county;
    }
    if (city.stateAbbr.length) {
        params[@"stateAbbr"] = city.stateAbbr;
    }
    if (city.countryAbbr.length) {
        params[@"countryAbbr"] = city.countryAbbr;
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *users = JSON[@"friends"];
                              NSMutableArray *usersArray = [NSMutableArray arrayWithCapacity:users.count];
                              
                              for (NSDictionary *attributes in users) {
                                  Person *person = [[Person alloc] initWithAttributes:attributes];
                                  
                                  BOOL isDuplicate = NO;

                                  for (int i = 0; i < usersArray.count; i++) {
                                      Person *addedPerson = (Person *)usersArray[i];
                                      if ([person.userToken isEqualToString:addedPerson.userToken]) {
                                          isDuplicate = YES;
                                          break;
                                      }
                                  }
                                  
                                  if (!isDuplicate) {
                                      [usersArray addObject:person];
                                  }
                              }
                              
                              if (completionHandler) {
                                  NSArray *cityUsers =[NSArray arrayWithArray:usersArray];
                                  NSInteger cityPop = [JSON[@"population"] integerValue];
                                  completionHandler(cityUsers,cityPop);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchRankedUserForNeighborhood:(SPCNeighborhood *)neighborhood
                rankInCityIfFewResults:(BOOL)rankInCityIfFewResults
             completionHandler:(void (^)(NSArray *cityUsers, SPCCity *city,NSInteger cityPop))completionHandler
                  errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/search/getRankedUsersByNeighborhood"];
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    
    if (neighborhood.neighborhoodName) {
        params[@"neighborhood"] = neighborhood.neighborhoodName;
    }
    if (neighborhood.cityName.length > 0) {
        params[@"city"] = neighborhood.cityName;
    }
    if (neighborhood.county.length > 0) {
        params[@"county"] = neighborhood.county;
    }
    if (neighborhood.stateAbbr.length) {
        params[@"stateAbbr"] = neighborhood.stateAbbr;
    }
    if (neighborhood.countryAbbr.length) {
        params[@"countryAbbr"] = neighborhood.countryAbbr;
    }
    
    params[@"rankInCityIfFewResults"] = @(rankInCityIfFewResults);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *users = JSON[@"friends"];
                              NSMutableArray *usersArray = [NSMutableArray arrayWithCapacity:users.count];
                              
                              for (NSDictionary *attributes in users) {
                                  Person *person = [[Person alloc] initWithAttributes:attributes];
                                  
                                  BOOL isDuplicate = NO;
                                  
                                  for (int i = 0; i < usersArray.count; i++) {
                                      Person *addedPerson = (Person *)usersArray[i];
                                      if ([person.userToken isEqualToString:addedPerson.userToken]) {
                                          isDuplicate = YES;
                                          break;
                                      }
                                  }
                                  
                                  if (!isDuplicate) {
                                      [usersArray addObject:person];
                                  }
                              }
                              
                              SPCCity *city;
                              if (JSON[@"location"]) {
                              
                              NSDictionary *cityDict = JSON[@"location"];
                                  city = [[SPCCity alloc] initWithAttributes:cityDict];
                              }
                              
                              if (completionHandler) {
                                  NSArray *cityUsers =[NSArray arrayWithArray:usersArray];
                                  NSInteger cityPop = [JSON[@"population"] integerValue];
                                  completionHandler(cityUsers,city,cityPop);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchUsersWithSearch:(NSString *)searchString
            completionHandler:(void (^)(NSArray *cities))completionHandler
                 errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/search/getUsersByPartialName"];
    NSDictionary *params = @{ @"partial": searchString };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              NSLog(@"params %@ url %@ result %@",params,url,result);
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *users = JSON[@"friends"];
                              NSMutableArray *usersArray = [NSMutableArray arrayWithCapacity:users.count];
                              
                              for (NSDictionary *attributes in users) {
                                  Person *person = [[Person alloc] initWithAttributes:attributes];
                                  [usersArray addObject:person];
                              }
                              
                              if (completionHandler) {
                                  completionHandler(usersArray);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)fetchNeighborhoodsWithSearch:(NSString *)searchString
           completionHandler:(void (^)(NSArray *cities))completionHandler
                errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/search/getNeighborhoodsByPartial"];
    NSDictionary *params = @{ @"partial": searchString };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSMutableArray *neighborhoodArray = [[NSMutableArray alloc] init];
                              for (NSDictionary *dict in JSON) {
                                  SPCNeighborhood *neighborhood = [[SPCNeighborhood alloc] initWithAttributes:dict];
                                  [neighborhoodArray addObject:neighborhood];
                              }
                              
                              NSArray *unsortedArray = [NSArray arrayWithArray:neighborhoodArray];
                              NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(cityName)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                              
                              NSArray *sortedArray = [unsortedArray sortedArrayUsingDescriptors:@[sortDescriptor]];
                              
                              if (completionHandler) {
                                  completionHandler(sortedArray);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchGlobalRankedUsersWithCompletionHandler:(void (^)(NSArray *rankedUsers))completionHandler
                                       errorHandler:(void (^)(NSError *error))errorHandler {
    
    
    NSString *url = [NSString stringWithFormat:@"/search/getRankedUsers"];
    
    NSLog(@"%@",url);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"%@",result);
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *users = JSON[@"friends"];
                              NSMutableArray *usersArray = [NSMutableArray arrayWithCapacity:users.count];
                              
                              for (NSDictionary *attributes in users) {
                                  Person *person = [[Person alloc] initWithAttributes:attributes];
                                  [usersArray addObject:person];
                              }
                              
                              NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starCount" ascending:NO];
                              [usersArray sortUsingDescriptors:@[starSorter]];
                              
                              NSArray *sortedArray = [NSArray arrayWithArray:usersArray];
                        
                              if (completionHandler) {
                                  completionHandler(sortedArray);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


#pragma mark - Fly search

+ (void)fetchExplorePlacesWithSearch:(NSString *)searchString
                   completionHandler:(void (^)(NSArray *neighborhoods, NSArray *cities))completionHandler
                        errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/search/getPlacesByPartial"];
    NSDictionary *params = @{ @"partial": searchString };
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              NSMutableArray *citiesArray = [[NSMutableArray alloc] init];
                              NSMutableArray *neighborhoodArray = [[NSMutableArray alloc] init];
                              
                              NSArray *citiesJSON = JSON[@"cities"];
                              NSArray *neighborhoodJSON = JSON[@"neighborhoods"];
                              if (citiesJSON) {
                                  for (NSDictionary *dict in citiesJSON) {
                                      SPCCity *city = [[SPCCity alloc] initWithAttributes:dict];
                                      [citiesArray addObject:city];
                                  }
                              }
                              if (neighborhoodJSON) {
                                  for (NSDictionary *dict in neighborhoodJSON) {
                                      SPCNeighborhood *neighborhood = [[SPCNeighborhood alloc] initWithAttributes:dict];
                                      [neighborhoodArray addObject:neighborhood];
                                  }
                              }
                              
                              NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(cityName)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                              NSArray *sortedCityArray = [citiesArray sortedArrayUsingDescriptors:@[sortDescriptor]];
                              
                              sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(neighborhoodName)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                              NSArray *sortedNeighborhoodArray = [neighborhoodArray sortedArrayUsingDescriptors:@[sortDescriptor]];
                              
                              
                              if (completionHandler) {
                                  completionHandler(sortedNeighborhoodArray, sortedCityArray);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];

}


#pragma mark - Star count

- (void)fetchStarCount {
    if (![AuthenticationManager sharedInstance].currentUser) {
        return;
    }
    
    NSString *key = [SPCLiterals literal:kStarCountDateUpdatedKey forUser:[AuthenticationManager sharedInstance].currentUser];
    
    NSDate *date = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:date] * 1000.0;
    
    NSString *url = [NSString stringWithFormat:@"/memories/starsNewCount"];
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
    
    if (timeInterval > 0) {
        mutableParams[@"beforeMillisAgo"] = @((NSInteger)timeInterval);
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:mutableParams
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              // Post notification with the current star count
                              [[NSNotificationCenter defaultCenter] postNotificationName:@"showStarCount" object:nil userInfo:@{ @"count": JSON[@"number"] }];
                              
                              [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
                              [[NSUserDefaults standardUserDefaults] synchronize];
                          } faultCallback:nil];
}

- (void)clearStarCount {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hideStarCount" object:nil];
}

- (void)handleAuthenticationSuccess {
    [MeetManager fetchBlockedUsersResultCallback:nil faultCallback:nil];
}

- (void)handleLogout {
    [MeetManager setBlockedIds:nil];
}


// Followers

+ (void)acceptFollowRequestWithUserToken:(NSString *)userToken completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *))errorHandler {
    [Flurry logEvent:@"FOLLOW_ACCEPT"];
    
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/acceptFrom", userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              // Notify push manager to delete pending requests from this friend
                              [[NSNotificationCenter defaultCenter] postNotificationName:kFollowRequestResponseDidAcceptWithUserToken object:userToken];
                              // Notify friends lists that they need to update
                              [[NSNotificationCenter defaultCenter] postNotificationName:kFollowersCollectionMarkDirty object:nil];
                              // Added a friend: used to update displayed friend counts and relationships.
                              [[NSNotificationCenter defaultCenter] postNotificationName:kDidAddFollower object:userToken];
                              
                              if (completionHandler) {
                                  completionHandler();
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)rejectFollowRequestWithUserToken:(NSString *)userToken completionHandler:(void (^)())completionHandler errorHandler:(void (^)(NSError *error))errorHandler {
    [Flurry logEvent:@"FOLLOW_REJECT"];
    
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/rejectFrom", userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              if (completionHandler) {
                                  completionHandler();
                              }
                              
                              // Notify push manager to delete pending notifications from this friend
                              [[NSNotificationCenter defaultCenter] postNotificationName:kFollowRequestResponseDidRejectWithUserToken object:userToken];
                              // Notify friends list that our collection is now dirty
                              [[NSNotificationCenter defaultCenter] postNotificationName:kFollowersCollectionMarkDirty object:nil];
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)unfollowWithUserToken:(NSString *)userToken
                completionHandler:(void (^)())completionHandler
                     errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/unfollow", userToken];
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              if (completionHandler) {
                                  completionHandler();
                              }
                              
                              [[NSNotificationCenter defaultCenter] postNotificationName:kFollowDidUnfollowWithUserToken object:userToken];
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}

+ (void)sendFollowRequestWithUserToken:(NSString *)userToken
                           completionHandler:(void (^)(BOOL followingNow))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/follow", userToken];
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSInteger success = [JSON[@"number"] integerValue];
                              BOOL followingNow = success == 1;
                              
                              if (completionHandler) {
                                  completionHandler(followingNow);
                              }
                              
                              if (followingNow) {
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kFollowDidFollowWithUserToken object:userToken];
                              } else {
                                  [[NSNotificationCenter defaultCenter] postNotificationName:kFollowDidRequestWithUserToken object:userToken];
                              }
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


+ (void)fetchFollowersWithPageKey:(NSString *)pageKey
                completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                     errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/followers"];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:@"FOLLOW" partialSearch:nil pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}

+ (void)fetchFollowersWithUserToken:(NSString *)targetUserToken
                        withPageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/followers", targetUserToken];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:@"FOLLOW" partialSearch:nil pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}


+ (void)fetchFollowersOrderedByLastMessageWithPageKey:(NSString *)pageKey
                                    completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                                         errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/followers"];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:@"INTERACTION" partialSearch:nil pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}


+ (void)fetchFollowersWithPartialSearch:(NSString *)partialSearch
                                pageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/followers"];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:nil partialSearch:partialSearch pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}


+ (void)fetchFollowersWithUserToken:(NSString *)targetUserToken
                      partialSearch:(NSString *)partialSearch
                        withPageKey:(NSString *)pageKey
                  completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/followers", targetUserToken];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:nil partialSearch:partialSearch pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}


+ (void)fetchFollowedUsersWithPartialSearch:(NSString *)partialSearch
                                    pageKey:(NSString *)pageKey
                    completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                         errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/follows"];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:nil partialSearch:partialSearch pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}


+ (void)fetchFollowedUsersWithUserToken:(NSString *)targetUserToken
                          partialSearch:(NSString *)partialSearch
                            withPageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    NSString *url = [NSString stringWithFormat:@"/entourage/%@/follows", targetUserToken];
    [MeetManager fetchFollowersOrFollowedUsersWithURL:url followSortType:nil partialSearch:partialSearch pageKey:pageKey completionHandler:completionHandler errorHandler:errorHandler];
}

+ (void)fetchFollowersOrFollowedUsersWithURL:(NSString *)url
                              followSortType:(NSString *)followSortType
                               partialSearch:(NSString *)partialSearch
                                     pageKey:(NSString *)pageKey
                           completionHandler:(void (^)(NSArray *followers, NSString *nextPageKey))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (followSortType != nil) {
        params[@"followSortType"] = followSortType;
    }
    if (partialSearch != nil && [partialSearch stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
        params[@"partial"] = partialSearch;
    }
    if (pageKey != nil) {
        params[@"pageKey"] = pageKey;
    }
    
    NSLog(@"followers with URL %@ params %@", url, params);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              //NSLog(@"url %@ params %@ result %@",url,params,result);
                              
                              NSArray *friends = JSON[@"friends"];
                              NSString *nextPageKey = JSON[@"nextPageKey"];
                              NSMutableArray *mutableFriends = [NSMutableArray arrayWithCapacity:friends.count];
                              NSMutableArray *mutableRecordIds = [NSMutableArray arrayWithCapacity:friends.count];
                              
                              [friends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                  Friend *friend = [[Friend alloc] initWithAttributes:obj];
                                  [mutableFriends addObject:friend];
                                  [mutableRecordIds addObject:@(friend.recordID)];
                              }];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableFriends], nextPageKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"url %@ params %@ error %@",url,params,fault);
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}



+(void)fetchUnhandleFollowRequestsCountWithResultCallback:(void (^)(NSInteger totalUnhandledRequests))resultCallback
                                            faultCallback:(void (^)(NSError *fault))faultCallback {
    
    
    if (![AuthenticationManager sharedInstance].currentUser) {
        return;
    }
    
    NSString *url = [NSString stringWithFormat:@"/entourage/requests/count"];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSInteger count = [TranslationUtils integerValueFromDictionary:JSON withKey:@"number"];
                              
                              if (resultCallback) {
                                  resultCallback(count);
                              }

                          } faultCallback:^(NSError *error){
                              NSLog(@"url %@ error %@",url,error);
                          }];
    
    
}


+ (void)fetchFollowerRequestsWithPageKey:(NSString *)pageKey
                       completionHandler:(void (^)(NSArray *followerRequests, NSString *nextPageKey))completionHandler
                            errorHandler:(void (^)(NSError *error))errorHandler {
    
    

    
    NSString *url = [NSString stringWithFormat:@"/entourage/requests"];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (pageKey != nil) {
        params[@"pageKey"] = pageKey;
    }
    
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              NSLog(@"url %@ result %@",url,result);
                              
                              NSArray *friends = JSON[@"friends"];
                              NSString *nextPageKey = JSON[@"nextPageKey"];
                              NSMutableArray *mutableFriends = [NSMutableArray arrayWithCapacity:friends.count];
                              NSMutableArray *mutableRecordIds = [NSMutableArray arrayWithCapacity:friends.count];
                              
                              [friends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                  Friend *friend = [[Friend alloc] initWithAttributes:obj];
                                  [mutableFriends addObject:friend];
                                  [mutableRecordIds addObject:@(friend.recordID)];
                              }];
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:mutableFriends], nextPageKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"url %@ error %@",url,fault);
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
    
}

#pragma mark - Grid Content

-(void)fetchFeaturedGridPageWithPageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *featuredContent, NSString *nextPageKey, NSString *stalePageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];;
    if (pageKey) {
        params[@"pageKey"] = pageKey;
    }
    
    NSString *url = [NSString stringWithFormat:@"/location/featured"];
    
    NSString *build = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    params[@"buildNumber"] = build;
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:[NSDictionary dictionaryWithDictionary:params]
                          resultCallback:^(NSObject *result) {
                              NSLog(@"location/featured results in!");
                              
                              //DO THIS ON A BACKGROUND THREAD!!!
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  
                              
                                  NSDictionary * resultDict = (NSDictionary *) result;
                                  NSArray * resultLocations = resultDict[@"locations"];
                                  NSString * nextPageKey = resultDict[@"nextPageKey"];
                                  NSString *stalePageKey = (NSString *)[TranslationUtils valueOrNil:resultDict[@"isStaleKey"]];
                                  NSMutableArray * venues = [[NSMutableArray alloc] initWithCapacity:resultLocations.count];
                                  
                                  for (NSDictionary * venueDict in resultLocations) {
                                      Venue * venue = [[Venue alloc] initWithAttributes:venueDict];
                                      
                                      if (venue.popularMemories.count > 0) {
                                          [venues addObject:venue];
                                      }
                                  }
                                  //handle completionHandler from main thread
                                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                                      if (completionHandler) {
                                          completionHandler([NSArray arrayWithArray:venues], nextPageKey,stalePageKey);
                                      }
                                                  });
                              });
                          } faultCallback:^(NSError *fault) {
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


-(void)checkForFreshFirstPageWorldGridWithStaleKey:(NSString *)staleKey
                                 completionHandler:(void (^)(BOOL firstPageIsStale))completionHandler
                                      errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSDictionary *params = [NSMutableDictionary dictionary];
    if (staleKey) {
        params = @{ @"isStaleKey": staleKey};
    }
    NSString *url = [NSString stringWithFormat:@"/location/featured/isStale"];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              
                              //NSLog(@"url %@ params %@ result %@",url,params,result);
                              
                              BOOL firstPageIsStale = NO;
                              
                              NSDictionary * resultDict = (NSDictionary *) result;
                              NSString * nextPageResult = resultDict[@"number"];
                              NSInteger nextPageIntgerValue = [nextPageResult integerValue];
                              if (nextPageIntgerValue == 1) {
                                  firstPageIsStale = YES;
                              }
                              
                              if (completionHandler) {
                                  completionHandler(firstPageIsStale);
                              }
                              
                          } faultCallback:^(NSError *error) {
                              //NSLog(@"url %@ params %@ fault %@",url,params,error);
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }
     ];
}



// Memory-based local and world grids

// Grid content (new - memories with supplementary locations)


-(void)fetchWorldFeaturedMemoryAndVenueGridPageWithPageKey:(NSString *)pageKey
                                         completionHandler:(void (^)(NSArray *memories, NSArray *people, NSString *nextPageKey, NSString *stalePageKey))completionHandler
                                              errorHandler:(void (^)(NSError *error))errorHandler {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (pageKey) {
        params[@"pageKey"] = pageKey;
    }
    
    NSString *url = [NSString stringWithFormat:@"/memories/featured"];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:[NSDictionary dictionaryWithDictionary:params]
                          resultCallback:^(NSObject *result) {
                              //NSLog(@"memories/featured results in: %@", result);
                              
                              //DO THIS ON A BACKGROUND THREAD!!!
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  
                                  
                                  NSDictionary * resultDict = (NSDictionary *) result;
                                  NSArray * resultPeople = resultDict[@"people"];
                                  NSString * nextPageKey = resultDict[@"nextPageKey"];
                                  NSString *stalePageKey = (NSString *)[TranslationUtils valueOrNil:resultDict[@"isStaleKey"]];
                                  NSMutableArray *memories = [MeetManager translateMemoriesFromResponse:resultDict];
                                  NSMutableArray *people = [[NSMutableArray alloc] initWithCapacity:resultPeople.count];
                                  
                                  for (NSDictionary * personDict in resultPeople) {
                                      Person *person = [[Person alloc] initWithAttributes:personDict];
                                      [people addObject:person];
                                  }
                                  //handle completionHandler from main thread
                                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                                      if (completionHandler) {
                                          //NSLog(@"calling completion handler");
                                          completionHandler([NSArray arrayWithArray:memories], [NSArray arrayWithArray:people], nextPageKey,stalePageKey);
                                      }
                                  });
                              });
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"failed %@", fault);
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}


-(void)checkForFreshFirstPageWorldFeaturedMemoryAndVenueGridWithStaleKey:(NSString *)staleKey
                                                       completionHandler:(void (^)(BOOL firstPageIsStale))completionHandler
                                                            errorHandler:(void (^)(NSError *error))errorHandler {
    NSDictionary *params = [NSMutableDictionary dictionary];
    if (staleKey) {
        params = @{ @"isStaleKey": staleKey};
    }
    NSString *url = [NSString stringWithFormat:@"/memories/featured/isStale"];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              
                              //NSLog(@"url %@ params %@ result %@",url,params,result);
                              
                              BOOL firstPageIsStale = NO;
                              
                              NSDictionary * resultDict = (NSDictionary *) result;
                              NSString * nextPageResult = resultDict[@"number"];
                              NSInteger nextPageIntgerValue = [nextPageResult integerValue];
                              if (nextPageIntgerValue == 1) {
                                  firstPageIsStale = YES;
                              }
                              
                              if (completionHandler) {
                                  completionHandler(firstPageIsStale);
                              }
                              
                          } faultCallback:^(NSError *error) {
                              //NSLog(@"url %@ params %@ fault %@",url,params,error);
                              if (errorHandler) {
                                  errorHandler(error);
                              }
                          }
     ];
}

-(void)fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:(NSString *)pageKey
                                                   latitude:(double)latitude
                                                  longitude:(double)longitude
                                             resultCallback:(void (^)(NSArray *memories, NSArray *locations, NSString *nextPageKey, NSString *stalePageKey))resultCallback
                                              faultCallback:(void (^)(NSError *fault))faultCallback {
    if (pageKey) {
        // no need for hints
        [self fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:nil resultCallback:resultCallback faultCallback:faultCallback];
        return;
    }
    
    BOOL rateCanceled = [[VenueManager sharedInstance] getRateLimited];
    if (rateCanceled) {
        //NSLog(@"Rate-limited: fetching venue w/o hint");
        [self fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:nil resultCallback:resultCallback faultCallback:faultCallback];
    } else {
        [[VenueManager sharedInstance] fetchGoogleAddressAtLatitude:latitude longitude:longitude resultCallback:^(NSDictionary *googleResponseDictionary) {
            //NSLog(@"Google success %@", googleResponseDictionary);
            NSDictionary * params = @{@"latitude": @(latitude),
                                      @"longitude": @(longitude),
                                      [VenueManager getGoogleAddressParamaterName] : [VenueManager getGoogleAddressParamaterValue:googleResponseDictionary]
                                      };
            
            [self fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:params resultCallback:resultCallback faultCallback:faultCallback];
            
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            //NSLog(@"google fault %d %@", apiResult, fault);
            [self fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:nil resultCallback:resultCallback faultCallback:faultCallback];
        }];
    }
}


-(void)fetchNearbyFeaturedMemoryAndVenueGridPageWithPageKey:(NSString *)pageKey
                                     latitude:(double)latitude
                                    longitude:(double)longitude
                                   hintParams:(NSDictionary *)hintParams
                               resultCallback:(void (^)(NSArray *memories, NSArray *locations, NSString *nextPageKey, NSString *stalePageKey))resultCallback
                                faultCallback:(void (^)(NSError *))faultCallback {
    NSMutableDictionary *params;
    if (hintParams) {
        params = [NSMutableDictionary dictionaryWithDictionary:hintParams];
    } else {
        params = [NSMutableDictionary dictionary];
    }
    
    params[@"latitude"] = @(latitude);
    params[@"longitude"] = @(longitude);
    if (pageKey) {
        params[@"pageKey"] = pageKey;
    }
    
    NSString *url = @"/memories/nearby/featured";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:[NSDictionary dictionaryWithDictionary:params]
                          resultCallback:^(NSObject * result) {
                              //NSLog(@" url %@ params %@ result %@",url,params, result);
                              
                              
                              //DO THIS ON A BACKGROUND THREAD!!!
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  
                                  NSDictionary * resultDict = (NSDictionary *) result;
                                  NSArray * resultPeople = resultDict[@"people"];
                                  NSString * pageKey = resultDict[@"nextPageKey"];
                                  NSString *stalePageKey = (NSString *)[TranslationUtils valueOrNil:resultDict[@"isStaleKey"]];
                                  
                                  CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                                  
                                  NSMutableArray *memories = [MeetManager translateMemoriesFromResponse:resultDict];
                                  for (Memory *memory in memories) {
                                      if (memory.venue && memory.venue.location && memory.venue.specificity == SPCVenueIsReal) {
                                          memory.distanceAway = [location distanceFromLocation:memory.venue.location];
                                      } else {
                                          memory.distanceAway = -1;
                                      }
                                  }
                                  
                                  NSMutableArray *people = [[NSMutableArray alloc] initWithCapacity:resultPeople.count];
                                  for (NSDictionary * personDict in resultPeople) {
                                      Person *person = [[Person alloc] initWithAttributes:personDict];
                                      [people addObject:person];
                                  }
                                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                                      if (resultCallback) {
                                          //NSLog(@"calling result callback");
                                          resultCallback([NSArray arrayWithArray:memories], [NSArray arrayWithArray:people], pageKey,stalePageKey);
                                      }
                                  });
                              });
                          } faultCallback:^(NSError *fault) {
                              //NSLog(@"url %@ params %@ fault %@",url,params,fault);
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}


-(void)checkForFreshFirstPageNearbyFeaturedMemoryAndVenueGridWithStalePageKey:(NSString *)pageKey
                                                                     latitude:(double)latitude
                                                                    longitude:(double)longitude
                                                               resultCallback:(void (^)(BOOL firstPageIsStale))resultCallback
                                                                faultCallback:(void (^)(NSError *fault))faultCallback {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    
    
    params[@"latitude"] = @(latitude);
    params[@"longitude"] = @(longitude);
    if (pageKey) {
        params[@"isStaleKey"] = pageKey;
    }
    
    NSString *url = @"/memories/nearby/featured/isStale";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:[NSDictionary dictionaryWithDictionary:params]
                          resultCallback:^(NSObject * result) {
                              
                              //NSLog(@"url %@ params %@ result %@",url,params,result);
                              
                              BOOL firstPageIsStale = NO;
                              
                              NSDictionary * resultDict = (NSDictionary *) result;
                              NSString * nextPageResult = resultDict[@"number"];
                              NSInteger nextPageIntgerValue = [nextPageResult integerValue];
                              if (nextPageIntgerValue == 1) {
                                  firstPageIsStale = YES;
                              }
                              
                              if (resultCallback) {
                                  resultCallback(firstPageIsStale);
                              }
                          } faultCallback:^(NSError *fault) {
                              //NSLog(@"url %@ params %@ fault %@",url,params,fault);
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}


-(void)fetchGridPageForHashTag:(NSString *)hashtag
                   withPageKey:(NSString *)pageKey
                      completionHandler:(void (^)(NSArray *featuredContent, NSString *nextPageKey))completionHandler
                           errorHandler:(void (^)(NSError *error))errorHandler {
    
    NSDictionary *params = nil;
    
    //strip out the #s
    NSString *cleanTag = [hashtag substringFromIndex:1];
    
    if (pageKey) {
        params = @{ @"hashtag": cleanTag, @"pageKey" : pageKey};
    }
    else {
        params = @{ @"hashtag": cleanTag};
    }

    NSString *url = [NSString stringWithFormat:@"/location/hashtag"];
    
    //NSLog(@"fetchGridPageForHashTag %@",cleanTag);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject *result) {
                              
                              //NSLog(@"url %@ params %@ result %@",url,params,result);
                              
                              NSDictionary * resultDict = (NSDictionary *) result;
                              NSArray * resultLocations = resultDict[@"locations"];
                              NSString * nextPageKey = resultDict[@"nextPageKey"];
                              NSMutableArray * venues = [[NSMutableArray alloc] initWithCapacity:resultLocations.count];
                              for (NSDictionary * venueDict in resultLocations) {
                                  Venue * venue = [[Venue alloc] initWithAttributes:venueDict];
                                  
                                  if (venue.recentHashtagMemories.count > 0) {
                                      [venues addObject:venue];
                                  }
                              }
                              
                              if (completionHandler) {
                                  completionHandler([NSArray arrayWithArray:venues], nextPageKey);
                              }
                          } faultCallback:^(NSError *fault) {
                              //NSLog(@"url %@ params %@ fault %@",url,params,fault);
                              if (errorHandler) {
                                  errorHandler(fault);
                              }
                          }];
}







@end
