//
//  GoogleHintManager.h
//  Spayce
//
//  Created by Jake Rosin on 7/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Enums.h"

@class Venue;
@class SPCFeaturedContent;
@class Memory;
@class SPCCity;
@class SPCNeighborhood;
@class Asset;

@interface VenueManager : NSObject

+(VenueManager *)sharedInstance;


#pragma mark Google Reverse Geocoding

- (void)fetchGoogleAddressAtLatitude:(double)latitude
                          longitude:(double)longitude
                     resultCallback:(void (^)(NSDictionary *))resultCallback
                      faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;

- (void)fetchGoogleAddressVenueAtLatitude:(double)latitude
                               longitude:(double)longitude
                          resultCallback:(void (^)(Venue *))resultCallback
                           faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;

+ (Venue *)getGoogleAddressVenue:(NSDictionary *)googleAddressDictionary;
+ (NSString *)getGoogleAddressParamaterValue:(NSDictionary *)googleAddressDictionary;
+ (NSString *)getGoogleAddressParamaterName;


#pragma mark Favoriting


-(void)favoriteVenue:(Venue *)venue
      resultCallback:(void (^)(NSDictionary *results))resultCallback
       faultCallback:(void (^)(NSError *fault))faultCallback;


-(void)unfavoriteVenue:(Venue *)venue
        resultCallback:(void (^)(NSDictionary *results))resultCallback
         faultCallback:(void (^)(NSError *fault))faultCallback;

-(void)setVenue:(Venue *)venue
     asFavorite:(BOOL)favorite
 resultCallback:(void (^)(NSDictionary *results))resultCallback
  faultCallback:(void (^)(NSError *fault))faultCallback;

-(void)reportOrCorrectVenue:(Venue *)venue
                 reportType:(SPCReportType)reportType
                       text:(NSString *)text
          completionHandler:(void (^)(BOOL success))completionHandler;

- (void)updateVenue:(Venue *)venue
   bannerImageAsset:(Asset *)bannerImageAsset
  completionHandler:(void (^)(BOOL success))completionHandler;

- (void)updateVenue:(Venue *)venue
        bannerImage:(UIImage *)bannerImage
  completionHandler:(void (^)(BOOL success))completionHandler;


-(void)fetchVenueWithoutGoogleHintAtLatitude:(double)gpsLat
                                    longitude:(double)gpsLong
                               resultCallback:(void (^)(Venue *))resultCallback
                                faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;

-(void)fetchVenueWithGoogleHintAtLatitude:(double)gpsLat
                                longitude:(double)gpsLong
                              rateLimited:(BOOL)rateLimited
                           resultCallback:(void (^)(Venue *))resultCallback
                            faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;


-(void)fetchFavoritedVenuesWithUserToken:(NSString *)userToken
                                    city:(SPCCity *)city
                          resultCallback:(void (^)(NSArray *venues))resultCallback
                           faultCallback:(void (^)(NSError *fault))faultCallback;

-(void)fetchFavoritedVenuesWithUserToken:(NSString *)userToken
                            neighborhood:(SPCNeighborhood *)neighborhood
                          resultCallback:(void (^)(NSArray *venues))resultCallback
                           faultCallback:(void (^)(NSError *fault))faultCallback;



-(void)fetchVenueAndNearbyVenuesWithoutGoogleHintAtLatitude:(double)gpsLat
                                               longitude:(double)gpsLong
                                          resultCallback:(void (^)(Venue *venue, NSArray *venues, Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue))resultCallback
                                           faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;


-(void)fetchVenueAndNearbyVenuesWithGoogleHintAtLatitude:(double)gpsLat
                                               longitude:(double)gpsLong
                                             rateLimited:(BOOL)rateLimited
                                          resultCallback:(void (^)(Venue *venue, NSArray *venues,Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue))resultCallback
                                           faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;

-(void)fetchVenueAndFeaturedContentNearbyWithoutGoogleHintAtLatitude:(double)gpsLat
                                                  longitude:(double)gpsLong
                                             resultCallback:(void (^)(Venue *venue, NSArray *venues, NSArray *featuredContent, Venue *fuzzedVenue))resultCallback
                                              faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;


-(void)fetchTrendingVenuesForWorldWithResultCallback:(void (^)(NSArray *venues))resultCallback
                                       faultCallback:(void (^)(NSError *fault))faultCallback;

-(void)fetchTrendingVenuesNearbyWithCurrentVenue:(Venue *)venue
                                  resultCallback:(void (^)(NSArray *venues))resultCallback
                                   faultCallback:(void (^)(NSError *fault))faultCallback;

-(void)fetchSuggestedVenuesResultCallback:(void (^)(NSArray *venues))resultCallback
                            faultCallback:(void (^)(NSError *fault))faultCallback;





#pragma mark Spayce grid

-(void)fetchFeaturedNearbyGridPageWithPageKey:(NSString *)pageKey
                                     latitude:(double)latitude
                                    longitude:(double)longitude
                               resultCallback:(void (^)(NSArray *venues, NSString *nextPageKey, NSString *stalePageKey))resultCallback
                                faultCallback:(void (^)(NSError *fault))faultCallback;


-(void)checkForFreshFirstPageNearbyGridWithStalePageKey:(NSString *)pageKey
                                             latitude:(double)latitude
                                            longitude:(double)longitude
                                       resultCallback:(void (^)(BOOL firstPageIsStale))resultCallback
                                        faultCallback:(void (^)(NSError *fault))faultCallback;

-(void)fetchVenueAndFeaturedContentNearbyWithGoogleHintAtLatitude:(double)gpsLat
                                               longitude:(double)gpsLong
                                             rateLimited:(BOOL)rateLimited
                                          resultCallback:(void (^)(Venue *venue, NSArray *venues, NSArray *featuredContent, Venue *fuzzedVenue))resultCallback
                                           faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback;


-(void)postAddressHintsFromGoogleAsynchronouslyForStaleVenue:(Venue *)venue;
-(void)postAddressHintsFromGoogleAsynchronouslyForStaleVenues:(NSArray *)venues;
-(void)postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenue:(SPCFeaturedContent *)featuredContent;
-(void)postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenues:(NSArray *)featuredContents;
-(void)postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenue:(Memory *)memory;
-(void)postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:(NSArray *)memories;



#pragma mark Rate limiting

-(BOOL)getRateLimited;

-(BOOL)getRateLimitedForVenue:(Venue *)venue;


@end
