//
//  VenueManager.m
//  Spayce
//
//  Created by Jake Rosin on 7/7/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "VenueManager.h"
#import "Singleton.h"
#import "APIService.h"
#import "SPCFeaturedContent.h"
#import "Memory.h"
#import "Venue.h"
#import "SPCCity.h"
#import "SPCNeighborhood.h"
#import "Asset.h"
#import "TranslationUtils.h"
#import "Flurry.h"

const NSTimeInterval RATE_LIMIT_GLOBAL = 5.f;
const NSTimeInterval RATE_LIMIT_LOCATION = 60.0f * 60.0f * 24.0f * 7.0f;
const NSTimeInterval RATE_LIMIT_RADIUS = 60.0f * 5;
const NSTimeInterval RATE_LIMIT_QUOTA_FAILURE = 60.f * 60.0f * 24.0f;

const NSTimeInterval HINT_RADIUS = 100;

const NSTimeInterval RATE_HINT_MIN = 10.f;
const NSTimeInterval RATE_HINT_MAX = 60.f;

const CGFloat USER_LOCATION_RANGE = 80;

#define GOOGLE_ADDRESS_PARAMETER_NAME @"googleReverseGeocoding";
const NSString *GRG_ADDRESS_COMPONENTS = @"address_components";
const NSString *GRG_GEOMETRY = @"geometry";
const NSString *GRG_LOCATION = @"location";
const NSString *GRG_LATITUDE = @"lat";
const NSString *GRG_LONGITUDE = @"lng";
const NSString *GRG_QUERY_TIME = @"query_time";
const NSString *GRG_TYPES = @"types";
const NSString *GRG_SHORT_NAME = @"short_name";
const NSString *GRG_LONG_NAME = @"long_name";


@interface VenueInformation : NSObject

@property (nonatomic, assign) NSInteger addressId;
@property (nonatomic, assign) NSInteger locationId;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSDate *hintPostedAt;

- (instancetype)initWithVenue:(Venue *)venue;

@end

@implementation VenueInformation

- (instancetype)initWithVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.addressId = venue.addressId;
        self.locationId = venue.locationId;
        self.location = [[CLLocation alloc] initWithLatitude:venue.latitude.doubleValue longitude:venue.longitude.doubleValue];
    }
    return self;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[VenueInformation class]] && self.locationId == ((VenueInformation *)object).locationId;
}

- (NSUInteger)hash {
    return (NSUInteger)self.locationId;
}

@end


@interface VenueManager()

@property (nonatomic, assign) NSTimeInterval lastAddressQuery;
@property (nonatomic, assign) NSTimeInterval lastAddressQueryQuotaFailure;
@property (nonatomic, strong) NSMutableArray *addressQueryDictionaries;

// An array of stale venue information that we intend to provide hints about.
@property (nonatomic, strong) NSMutableArray *staleVenueInformationArray;

// Our records about which venues we have already provided hints for.
@property (nonatomic, strong) NSMutableDictionary *hintedVenueInformationDictionary;

// A one-shot timer that schedules our next venue hint.
@property (nonatomic, strong) NSTimer *hintTimer;

@end

@implementation VenueManager

SINGLETON_GCD(VenueManager);


-(void)dealloc {
    [self.hintTimer invalidate];
    self.hintTimer = nil;
}



#pragma mark - Properties

- (NSMutableArray *)addressQueryDictionaries {
    if (!_addressQueryDictionaries) {
        _addressQueryDictionaries = [NSMutableArray array];
    }
    return _addressQueryDictionaries;
}

- (NSMutableArray *)staleVenueInformationArray {
    if (!_staleVenueInformationArray) {
        _staleVenueInformationArray = [NSMutableArray array];
    }
    return _staleVenueInformationArray;
}

- (NSMutableDictionary *)hintedVenueInformationDictionary {
    if (!_hintedVenueInformationDictionary) {
        _hintedVenueInformationDictionary = [NSMutableDictionary dictionary];
    }
    return _hintedVenueInformationDictionary;
}


#pragma mark Google Reverse Geocoding

+ (CLLocation *)locationFromGoogleAddressDictionary:(NSDictionary *)googleAddressDictionary {
    NSDictionary *locationDict = googleAddressDictionary[GRG_GEOMETRY][GRG_LOCATION];
    if (locationDict) {
        NSNumber *addressLatitude = locationDict[GRG_LATITUDE];
        NSNumber *addressLongitude = locationDict[GRG_LONGITUDE];
        return [[CLLocation alloc] initWithLatitude:addressLatitude.doubleValue longitude:addressLongitude.doubleValue];
    }
    return nil;
}

+ (NSDate *)queryDateFromGoogleAddressDictionary:(NSDictionary *)googleAddressDictionary {
    NSNumber *millis = googleAddressDictionary[GRG_QUERY_TIME];
    return [NSDate dateWithTimeIntervalSinceNow:(millis.doubleValue / 1000.0)];
}

+ (NSString *)streetAddressWithStreetName:(NSString *)streetName streetNumber:(NSString *)streetNumber {
    if (streetName && streetNumber) {
        return [NSString stringWithFormat:@"%@ %@", streetNumber, streetName];
    } else if (streetName) {
        return streetName;
    }
    return nil;
}

-(void)fetchGoogleAddressAtLatitude:(double)latitude
                          longitude:(double)longitude
                     resultCallback:(void (^)(NSDictionary *))resultCallback
                      faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    for (NSDictionary *dict in self.addressQueryDictionaries) {
        CGFloat distance = [location distanceFromLocation:[VenueManager locationFromGoogleAddressDictionary:dict]];
        NSDate *queryTime = [VenueManager queryDateFromGoogleAddressDictionary:dict];
        if (distance < 4 && [[NSDate date] timeIntervalSinceDate:queryTime] < 60*60*24) {
            //NSLog(@"skipping Google query for venue %@, as we have a cached result at distance %f", venue.streetAddress, distance);
            if (resultCallback) {
                resultCallback(dict);
            }
            return;
        }
    }
    
    NSString *url = @"https://maps.googleapis.com/maps/api/geocode/json";
    
    NSDictionary *params = @{@"latlng": [NSString stringWithFormat:@"%f,%f", latitude, longitude]
                             };
    
    __weak typeof(self) weakSelf = self;
    self.lastAddressQuery = [[NSDate date] timeIntervalSince1970];
    [APIService makeApiCallWithMethodUrl:url andRequestType:RequestTypeGet andPathParams:nil andQueryParams:params resultCallback:^(NSObject *resultObj) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        // Don't tie up the main thread with processing: dispatch to the background.
        // Remember to call all callbacks on the main thread.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (![resultObj respondsToSelector:@selector(objectForKey:)]) {
                if (faultCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        faultCallback(GoogleApiResultFailureGoogleCall, nil);
                    });
                }
                return;
            } else if ([((NSDictionary *)resultObj)[@"results"] count] < 1) {
                strongSelf.lastAddressQueryQuotaFailure = [[NSDate date] timeIntervalSince1970];
                
                if (faultCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        faultCallback(GoogleApiResultFailureGoogleCall, nil);
                    });
                }
                return;
            }
            NSDictionary * result = ((NSDictionary *)resultObj)[@"results"][0];
            if (!result) {
                strongSelf.lastAddressQueryQuotaFailure = [[NSDate date] timeIntervalSince1970];
                
                if (faultCallback) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        faultCallback(GoogleApiResultFailureGoogleCall, nil);
                    });
                }
                return;
            }
            NSMutableDictionary *cleanDictionary = [NSMutableDictionary dictionary];
            
            
            NSArray *addressComponents = result[GRG_ADDRESS_COMPONENTS];
            NSDictionary *locationDict = result[GRG_GEOMETRY][GRG_LOCATION];
            
            // include full geometry and a cleaned-up version of address components.
            cleanDictionary[GRG_GEOMETRY] = result[GRG_GEOMETRY];
            NSMutableArray *cleanAddressComponents = [NSMutableArray arrayWithCapacity:addressComponents.count];
            const NSArray *GRG_ADDRESS_COMPONENT_TYPES = @[@"street_number",@"route",@"street_address",@"establishment",@"neighborhood",@"locality",@"administrative_area_level_2",@"administrative_area_level_1",@"postal_code",@"country"];
            
            for (NSDictionary *component in addressComponents) {
                BOOL keep = NO;
                NSArray *types = component[GRG_TYPES];
                for (NSString *type in types) {
                    if ([GRG_ADDRESS_COMPONENT_TYPES containsObject:type]) {
                        keep = YES;
                    }
                }
                if (keep) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                    dict[GRG_TYPES] = types;
                    dict[GRG_SHORT_NAME] = component[GRG_SHORT_NAME];
                    dict[GRG_LONG_NAME] = component[GRG_LONG_NAME];
                    [cleanAddressComponents addObject:[NSDictionary dictionaryWithDictionary:dict]];
                }
            }
            
            // include metadata, including query lat/lng and query time.
            double lat = latitude;
            double lng = longitude;
            if (locationDict[GRG_LATITUDE]) {
                lat = [locationDict[GRG_LATITUDE] doubleValue];
                lng = [locationDict[GRG_LONGITUDE] doubleValue];
            }
            cleanDictionary[GRG_ADDRESS_COMPONENTS] = [NSArray arrayWithArray:cleanAddressComponents];
            cleanDictionary[GRG_GEOMETRY] = @{GRG_LOCATION : @{GRG_LATITUDE : @(lat), GRG_LONGITUDE : @(lng)}};
            cleanDictionary[GRG_QUERY_TIME] = @((long long)[NSDate date].timeIntervalSince1970);
            
            CLLocation *location = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
            NSDictionary *dictionary = [NSDictionary dictionaryWithDictionary:cleanDictionary];
            
            BOOL cached = NO;
            for (int i = 0; i < self.addressQueryDictionaries.count; i++) {
                NSDictionary *cachedDict = self.addressQueryDictionaries[i];
                CGFloat distance = [location distanceFromLocation:[VenueManager locationFromGoogleAddressDictionary:cachedDict]];
                if (distance < 4) {
                    cached = YES;
                    self.addressQueryDictionaries[i] = dictionary;
                    break;
                }
            }
            if (!cached) {
                if (self.addressQueryDictionaries.count >= 20) {
                    [self.addressQueryDictionaries removeObjectAtIndex:0];
                }
                [self.addressQueryDictionaries addObject:dictionary];
            }
            
            if (resultCallback) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    resultCallback(dictionary);
                });
            }
        });
        
    } faultCallback:^(NSError *fault) {
        if (faultCallback) {
            faultCallback(GoogleApiResultFailureGoogleCall, fault);
        }
    } foreignAPI:YES];
}

- (void)fetchGoogleAddressVenueAtLatitude:(double)latitude
                                longitude:(double)longitude
                           resultCallback:(void (^)(Venue *))resultCallback
                            faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    [self fetchGoogleAddressAtLatitude:latitude longitude:longitude resultCallback:^(NSDictionary *dictionary) {
        if (resultCallback) {
            Venue *venue = [VenueManager getGoogleAddressVenue:dictionary];
            venue.latitude = @(latitude);
            venue.longitude = @(longitude);
            resultCallback(venue);
        }
    } faultCallback:faultCallback];
}

+ (Venue *)getGoogleAddressVenue:(NSDictionary *)googleAddressDictionary {
    NSArray * addressComponents = googleAddressDictionary[GRG_ADDRESS_COMPONENTS];
    NSDictionary * location = googleAddressDictionary[GRG_GEOMETRY][GRG_LOCATION];
    
    // Server uses short-form for all components.
    NSString * streetNumber;
    NSString * streetName;
    NSString * streetAddress;
    NSString * neighborhood;
    NSString * city;
    NSString * county;
    NSString * state;
    NSString * postalCode;
    NSString * country;
    
    for (NSDictionary * component in addressComponents) {
        NSString * shortName = component[@"short_name"];
        NSString * longName = component[@"long_name"];
        NSString * name = shortName == nil ? longName : shortName;
        NSArray * types = component[@"types"];
        if ([types containsObject:@"street_number"]) {
            streetNumber = name;
        }
        if ([types containsObject:@"route"]) {
            streetName = name;
        }
        if ([types containsObject:@"street_address"]) {
            streetAddress = name;
        }
        if ([types containsObject:@"neighborhood"]) {
            neighborhood = name;
        }
        if ([types containsObject:@"locality"]) {
            city = name;
        }
        if ([types containsObject:@"administrative_area_level_2"]) {
            county = name;
        }
        if ([types containsObject:@"administrative_area_level_1"]) {
            state = name;
        }
        if ([types containsObject:@"postal_code"]) {
            postalCode = name;
        }
        if ([types containsObject:@"country"]) {
            country = name;
        }
    }
    
    NSNumber * addressLatitude;
    NSNumber * addressLongitude;
    if (location) {
        addressLatitude = location[@"lat"];
        addressLongitude = location[@"lng"];
    }
    
    if (!streetAddress) {
        if (streetName && streetNumber) {
            streetAddress = [NSString stringWithFormat:@"%@ %@", streetNumber, streetName];
        } else if (streetName) {
            streetAddress = streetName;
        }
    }
    
    // Display name?
    NSString * specificName, * generalName;
    if (streetAddress) {
        specificName = streetAddress;
    } else if (neighborhood) {
        specificName = neighborhood;
    }
    if (city && state) {
        generalName = [NSString stringWithFormat:@"%@ %@", city, state];
    } else if (city && country) {
        generalName = [NSString stringWithFormat:@"%@ %@", city, country];
    } else if (state && country) {
        generalName = [NSString stringWithFormat:@"%@ %@", state, country];
    } else if (city) {
        generalName = city;
    } else if (state) {
        generalName = state;
    } else if (country) {
        generalName = country;
    }
    
    NSString * fullName = @"";
    if (specificName && generalName) {
        fullName = [NSString stringWithFormat:@"%@, %@", specificName, generalName];
    } else if (specificName) {
        fullName = specificName;
    } else if (generalName) {
        fullName = generalName;
    }
    
    // Make a venue.
    Venue * venue = [[Venue alloc] init];
    venue.latitude = addressLatitude;
    venue.longitude = addressLongitude;
    venue.defaultName = fullName;
    
    venue.streetAddress = streetAddress;
    venue.neighborhood = neighborhood;
    venue.city = city;
    venue.state = state;
    venue.county = county;
    venue.country = country;
    venue.postalCode = postalCode;
    
    venue.addressLatitude = addressLatitude;
    venue.addressLongitude = addressLongitude;
    
    venue.featuredTime = [VenueManager queryDateFromGoogleAddressDictionary:googleAddressDictionary];
    
    return venue;
}

+(NSString *)getGoogleAddressParamaterValue:(NSDictionary *)googleAddressDictionary {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:googleAddressDictionary options:0 error:&error];
    
    if (!jsonData) {
        NSLog(@"Error serializing dictionary %@\nError is %@", googleAddressDictionary, error);
        return nil;
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}


+(NSString *)getGoogleAddressParamaterName {
    return GOOGLE_ADDRESS_PARAMETER_NAME;
}


#pragma mark Favoriting


#pragma mark - Favoriting / Unfavoriting venues.

-(void)favoriteVenue:(Venue *)venue
      resultCallback:(void (^)(NSDictionary *results))resultCallback
       faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/location/%i/favorites", (int)venue.addressId];
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              if (resultCallback) {
                                  resultCallback((NSDictionary *)result);
                              }
                          }
                           faultCallback:faultCallback];
}


-(void)unfavoriteVenue:(Venue *)venue
        resultCallback:(void (^)(NSDictionary *results))resultCallback
         faultCallback:(void (^)(NSError *fault))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/location/%i/favorites",  (int)venue.addressId];
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeDelete
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject *result) {
                              if (resultCallback) {
                                  resultCallback((NSDictionary *)result);
                              }
                          }
                           faultCallback:faultCallback];
}



-(void)setVenue:(Venue *)venue
     asFavorite:(BOOL)favorite
 resultCallback:(void (^)(NSDictionary *results))resultCallback
  faultCallback:(void (^)(NSError *fault))faultCallback {
    if (favorite) {
        [self favoriteVenue:venue resultCallback:resultCallback faultCallback:faultCallback];
    } else {
        [self unfavoriteVenue:venue resultCallback:resultCallback faultCallback:faultCallback];
    }
}

-(void)reportOrCorrectVenue:(Venue *)venue
                 reportType:(SPCReportType)reportType
                       text:(NSString *)text
          completionHandler:(void (^)(BOOL success))completionHandler {
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
    
    NSString *url = [NSString stringWithFormat:@"/location/%@/issues", venue.addressKey];
    
    NSLog(@"url %@", url);
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resDict = (NSDictionary *)result;
                              int successCode = (int)[resDict[@"number"] integerValue];
                              if (completionHandler) {
                                  completionHandler(successCode == 1);
                              }
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"fault %@", fault);
                              if (completionHandler) {
                                  completionHandler(NO);
                              }
                          }];
}


- (void)updateVenue:(Venue *)venue
   bannerImageAsset:(Asset *)bannerImageAsset
  completionHandler:(void (^)(BOOL success))completionHandler {
    
    NSDictionary *param;
    if (bannerImageAsset.key) {
        param = @{ @"bannerAssetKey" : bannerImageAsset.key };
    } else {
        param = @{ @"bannerAssetId" : @(bannerImageAsset.assetID) };
    }
    [Flurry logEvent:@"UPDATE_VENUE_BANNER" withParameters:param];
    
    NSString *url = [NSString stringWithFormat:@"/location/%@/banner", venue.addressKey];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypePost
                           andPathParams:nil
                          andQueryParams:param
                          resultCallback:^(NSObject * result) {
                              NSDictionary *resDict = (NSDictionary *)result;
                              int successCode = (int)[resDict[@"number"] integerValue];
                              if (completionHandler) {
                                  completionHandler(successCode == 1);
                              }
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"fault %@", fault);
                              if (completionHandler) {
                                  completionHandler(NO);
                              }
                          }];

}

- (void)updateVenue:(Venue *)venue
        bannerImage:(UIImage *)bannerImage
  completionHandler:(void (^)(BOOL))completionHandler {
    
    __block Asset *asset = nil;
    
    void (^doUpdateBanner)(void) = ^{
        if (asset != nil) {
            [self updateVenue:venue bannerImageAsset:asset completionHandler:completionHandler];
        }
    };
    
    if (bannerImage) {
        [APIService uploadAssetToSpayceVaultWithData:UIImageJPEGRepresentation(bannerImage, 0.75)
                                      andQueryParams:nil
                                    progressCallback:nil
                                      resultCallback:^(Asset *uploadedAsset) {
                                          
                                          asset = uploadedAsset;
                                          
                                          if (doUpdateBanner) {
                                              doUpdateBanner();
                                          }
                                      } faultCallback:^(NSError *fault) {
                                          NSLog(@"Fault %@", fault);
                                          if (completionHandler) {
                                              completionHandler(NO);
                                          }
                                      }];
    }
    
}


#pragma mark - Posting / fetching methods

-(void)fetchVenueWithoutGoogleHintAtLatitude:(double)gpsLat longitude:(double)gpsLong resultCallback:(void (^)(Venue *))resultCallback faultCallback:(void (^)(GoogleApiResult, NSError *))faultCallback {
    
    NSString *url = @"/location";
    NSDictionary * params = @{@"latitude": @(gpsLat),
                              @"longitude": @(gpsLong)
                              };
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              //NSLog(@"fetch address result %@",result);
                              
                              NSDictionary *resultsDic = (NSDictionary *)result;
                              if (resultCallback) {
                                  resultCallback([[Venue alloc] initWithAttributes:resultsDic]);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(GoogleApiResultFailureServerCall, fault);
                              }
                          }];
}

-(void)fetchVenueWithGoogleHintAtLatitude:(double)gpsLat
                                longitude:(double)gpsLong
                              rateLimited:(BOOL)rateLimited
                            resultCallback:(void (^)(Venue *))resultCallback
                            faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    
    BOOL rateCanceled = rateLimited && [self getRateLimited];
    if (rateCanceled) {
        //NSLog(@"Rate-limited: fetching venue w/o hint");
        [self fetchVenueWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
    } else {
        [self fetchGoogleAddressAtLatitude:gpsLat longitude:gpsLong resultCallback:^(NSDictionary *googleResponseDictionary) {
            //NSLog(@"Google address fetched; providing it as a hint...");
            // fetch!
            NSString *url = @"/location";
            NSDictionary * params = @{@"latitude": @(gpsLat),
                                      @"longitude": @(gpsLong),
                                      [VenueManager getGoogleAddressParamaterName] : [VenueManager getGoogleAddressParamaterValue:googleResponseDictionary]
                                      };
            [APIService makeApiCallWithMethodUrl:url
                                  andRequestType:RequestTypeGet
                                   andPathParams:nil
                                  andQueryParams:params
                                  resultCallback:^(NSObject * result) {
                                      //NSLog(@"fetch address result %@",result);
                                      
                                      NSDictionary *resultsDic = (NSDictionary *)result;
                                      if (resultCallback) {
                                          resultCallback([[Venue alloc] initWithAttributes:resultsDic]);
                                      }
                                  } faultCallback:^(NSError *fault) {
                                      if (faultCallback) {
                                          faultCallback(GoogleApiResultFailureServerCall, fault);
                                      }
                                  }];

        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            NSLog(@"Error %@: fetching venue w/o hint", fault);
            [self fetchVenueWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
        }];
    }
}





-(void)fetchFavoritedVenuesWithUserToken:(NSString *)userToken
                                    city:(SPCCity *)city
                          resultCallback:(void (^)(NSArray *venues))resultCallback
                           faultCallback:(void (^)(NSError *fault))faultCallback {
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
    
    [self fetchFavoritedVenuesWithUserToken:userToken locationParams:params resultCallback:resultCallback faultCallback:faultCallback];
}


-(void)fetchFavoritedVenuesWithUserToken:(NSString *)userToken
                            neighborhood:(SPCNeighborhood *)neighborhood
                          resultCallback:(void (^)(NSArray *venues))resultCallback
                           faultCallback:(void (^)(NSError *fault))faultCallback {
    
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
    
    [self fetchFavoritedVenuesWithUserToken:userToken locationParams:params resultCallback:resultCallback faultCallback:faultCallback];
}


-(void)fetchFavoritedVenuesWithUserToken:(NSString *)userToken
                          locationParams:(NSDictionary *)locationParams
                          resultCallback:(void (^)(NSArray *))resultCallback
                           faultCallback:(void (^)(NSError *))faultCallback {
    NSString *url = [NSString stringWithFormat:@"/location/%@/favoritedInArea", userToken];
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:locationParams
                          resultCallback:^(NSObject *result) {
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                              NSArray *locations = JSON[@"locations"];
                              
                              NSMutableArray *venuesMut = [NSMutableArray arrayWithCapacity:locations.count];
                              
                              for (NSDictionary *attributes in locations) {
                                  Venue *tempVenue = [[Venue alloc] initWithAttributes:attributes];
                                  [venuesMut addObject:tempVenue];
                              }
                              
                              NSArray *venues = [NSArray arrayWithArray:venuesMut];
                              if (resultCallback) {
                                  resultCallback(venues);
                              }
                          } faultCallback:^(NSError *fault) {
                              // fault
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];

}



-(void)fetchVenueAndNearbyVenuesWithoutGoogleHintAtLatitude:(double)gpsLat
                                               longitude:(double)gpsLong
                                          resultCallback:(void (^)(Venue *venue, NSArray *venues, Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue))resultCallback
                                           faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    NSDictionary * params = @{@"latitude": @(gpsLat),
                              @"longitude": @(gpsLong)
                              };
    [self fetchVenueAndNearbyVenuesWithUserLatitude:gpsLat userLongitude:gpsLong params:params resultCallback:resultCallback faultCallback:faultCallback];
}

-(void)fetchVenueAndNearbyVenuesWithGoogleHintAtLatitude:(double)gpsLat longitude:(double)gpsLong rateLimited:(BOOL)rateLimited resultCallback:(void (^)(Venue *, NSArray *,Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue))resultCallback faultCallback:(void (^)(GoogleApiResult, NSError *))faultCallback {
    
    BOOL rateCanceled = rateLimited && [self getRateLimited];
    if (rateCanceled) {
        //NSLog(@"Rate-limited: fetching venue w/o hint");
        [self fetchVenueAndNearbyVenuesWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
    } else {
        [self fetchGoogleAddressAtLatitude:gpsLat longitude:gpsLong resultCallback:^(NSDictionary *googleResponseDictionary) {
            
            NSDictionary * params = @{@"latitude": @(gpsLat),
                                      @"longitude": @(gpsLong),
                                      [VenueManager getGoogleAddressParamaterName] : [VenueManager getGoogleAddressParamaterValue:googleResponseDictionary]
                                      };
            
            [self fetchVenueAndNearbyVenuesWithUserLatitude:gpsLat userLongitude:gpsLong params:params resultCallback:resultCallback faultCallback:faultCallback];
            
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
             [self fetchVenueAndNearbyVenuesWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
        }];
    }

    
}

-(void)fetchVenueAndNearbyVenuesWithUserLatitude:(double)gpsLat
                                   userLongitude:(double)gpsLong
                                          params:(NSDictionary *)params
                            resultCallback:(void (^)(Venue *, NSArray *,Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue))resultCallback
                             faultCallback:(void (^)(GoogleApiResult, NSError *))faultCallback {
    
    //NSLog(@"calling /location/nearby");
    
    NSString *url = @"/location/nearby";
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              NSDictionary *JSON = (NSDictionary *)result;
                              
                            //NSLog(@"calling /location/nearby %@",JSON);
                              
                              NSArray *locations = JSON[@"locations"];
                              
                              NSMutableArray *nearbyVenuesMut = [NSMutableArray arrayWithCapacity:locations.count];
                              Venue *fuzzedNeighborhoodVenue;
                              Venue *fuzzedCityVenue;

                              
                              for (NSDictionary *attributes in locations) {
                                  Venue *tempVenue = [[Venue alloc] initWithAttributes:attributes];
                                  
                                  if (tempVenue.specificity > SPCVenueIsReal) {
                                      
                                      if (tempVenue.specificity == SPCVenueIsFuzzedToCity) {
                                          NSLog(@"got a fuzzed city venue!");
                                          fuzzedCityVenue = tempVenue;
                                      }
                                      if (tempVenue.specificity == SPCVenueIsFuzzedToNeighhborhood) {
                                          NSLog(@"got a fuzzed neighborhood venue!");
                                          fuzzedNeighborhoodVenue = tempVenue;
                                      }
                                  }
                                  else if (tempVenue.displayName && [tempVenue.displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
                                      [nearbyVenuesMut addObject:tempVenue];
                                  }
                              }
                              
                              NSArray *nearbyVenues = [NSArray arrayWithArray:nearbyVenuesMut];
                              
                              // post hints for stale venues
                              [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleVenues:nearbyVenues];
                              
                              Venue *userVenue = nearbyVenuesMut.count > 0 ? nearbyVenuesMut[0] : nil;
                              if (resultCallback) {
                                  resultCallback(userVenue, nearbyVenues, fuzzedNeighborhoodVenue,fuzzedCityVenue);
                              }

                          } faultCallback:^(NSError *fault) {
                              //NSLog(@"url %@  fault %@",url,fault);
                              
                              if (faultCallback) {
                                  faultCallback(GoogleApiResultFailureServerCall, fault);
                              }
                          }];
}


-(void)fetchVenueAndFeaturedContentNearbyWithoutGoogleHintAtLatitude:(double)gpsLat
                                                           longitude:(double)gpsLong
                                                      resultCallback:(void (^)(Venue *venue, NSArray *venues, NSArray *featuredContent, Venue *fuzzedVenue))resultCallback
                                                       faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    NSDictionary * params = @{@"latitude": @(gpsLat),
                              @"longitude": @(gpsLong)
                              };
    [self fetchVenueAndFeaturedContentNearbyWithUserLatitude:gpsLat userLongitude:gpsLong params:params resultCallback:resultCallback faultCallback:faultCallback];
}


-(void)fetchVenueAndFeaturedContentNearbyWithGoogleHintAtLatitude:(double)gpsLat
                                                        longitude:(double)gpsLong
                                                      rateLimited:(BOOL)rateLimited
                                                   resultCallback:(void (^)(Venue *venue, NSArray *venues, NSArray *featuredContent, Venue *fuzzedVenue))resultCallback
                                                    faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    
    BOOL rateCanceled = rateLimited && [self getRateLimited];
    if (rateCanceled) {
        //NSLog(@"Rate-limited: fetching venue w/o hint");
        [self fetchVenueAndFeaturedContentNearbyWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
    } else {
        [self fetchGoogleAddressAtLatitude:gpsLat longitude:gpsLong resultCallback:^(NSDictionary *googleResponseDictionary) {
            
            NSDictionary * params = @{@"latitude": @(gpsLat),
                                      @"longitude": @(gpsLong),
                                      [VenueManager getGoogleAddressParamaterName] : [VenueManager getGoogleAddressParamaterValue:googleResponseDictionary]
                                      };
            
            [self fetchVenueAndFeaturedContentNearbyWithUserLatitude:gpsLat userLongitude:gpsLong params:params resultCallback:resultCallback faultCallback:faultCallback];
            
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            [self fetchVenueAndFeaturedContentNearbyWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:resultCallback faultCallback:faultCallback];
        }];
    }
    
}



-(void)fetchVenueAndFeaturedContentNearbyWithUserLatitude:(double)gpsLat
                                            userLongitude:(double)gpsLong
                                                   params:(NSDictionary *)params
                                           resultCallback:(void (^)(Venue *venue, NSArray *venues, NSArray *featuredContent, Venue *fuzzedVenue))resultCallback
                                                    faultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))faultCallback {
    
    //NSLog(@"fetching nearby venues and featured content using /location/listFeaturedHere");
    
    NSString *url = @"/location/listFeaturedHere";
    NSLog(@"params %@",params);
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:params
                          resultCallback:^(NSObject * result) {
                              
                              // dispatch our processing to a background thread, to avoid monopolizing the
                              // main thread with our data processing.  Remember to use the main queue for all
                              // callbacks.
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  NSDictionary *JSON = (NSDictionary *)result;
                                  
                                  NSArray *content = JSON[@"content"];
                                  
                                  NSMutableArray *nearbyVenuesMut = [NSMutableArray arrayWithCapacity:content.count];
                                  NSMutableArray *nearbyFeaturedContentMut = [NSMutableArray arrayWithCapacity:content.count];
                                  
                                  CLLocation *location = [[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong];
                                  Venue *fuzzedVenue;
                                  
                                  //NSLog(@"received %d elements from /location/listFeaturedHere at %f, %f", content.count, gpsLat, gpsLong);
                                  
                                  for (NSDictionary *attributes in content) {
                                      SPCFeaturedContent *featuredContent = [[SPCFeaturedContent alloc] initWithAttributes:attributes];
                                      Venue *tempVenue = featuredContent.venue;
                                      if (tempVenue) {
                                          CGFloat distance = [location distanceFromLocation:tempVenue.location];
                                          featuredContent.distance = distance;
                                          tempVenue.distance = [NSNumber numberWithFloat:distance];
                                          tempVenue.distanceAway = distance;
                                          [tempVenue updateDistance:distance];
                                      }
                                      //NSLog(@"Featured content has type %d", featuredContent.contentType);
                                      if (featuredContent.contentType == FeaturedContentVenueNearby) {
                                          if (tempVenue.displayName && [tempVenue.displayName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0) {
                                              //NSLog(@"Including venue with display name %@", tempVenue.displayName);
                                              if (tempVenue.specificity > SPCVenueIsReal) {
                                                  fuzzedVenue = tempVenue;
                                              }
                                              else {
                                                  [nearbyVenuesMut addObject:tempVenue];
                                              }
                                              [nearbyFeaturedContentMut addObject:featuredContent];
                                          }
                                      } else {
                                          //NSLog(@"Including featured memory with text %@", featuredContent.memory.text);
                                          [nearbyFeaturedContentMut addObject:featuredContent];
                                      }
                                  }
                                  
                                  
                                  
                                  NSArray *nearbyVenues = [NSArray arrayWithArray:nearbyVenuesMut];
                                  NSArray *featuredContent = [NSArray arrayWithArray:nearbyFeaturedContentMut];
                                  Venue *userVenue = nil;
                                  
                                  // post hints for stale venues
                                  [[VenueManager sharedInstance] postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenues:featuredContent];
                                  
                                  if (nearbyVenues.count > 0) {
                                      // use the best!
                                      userVenue = nearbyVenues[0];
                                      // NSLog(@"Best available venue is %@", userVenue.displayName);
                                      if (resultCallback) {
                                          dispatch_async(dispatch_get_main_queue(), ^(void) {
                                              resultCallback(userVenue, nearbyVenues, featuredContent,fuzzedVenue);
                                          });
                                      }
                                  } else {
                                      // attempt to retrieve just the venue.
                                      dispatch_async(dispatch_get_main_queue(), ^(void) {
                                          [self fetchVenueWithoutGoogleHintAtLatitude:gpsLat longitude:gpsLong resultCallback:^(Venue *venue) {
                                              if (resultCallback) {
                                                  resultCallback(venue, nearbyVenues, featuredContent,fuzzedVenue);
                                              }
                                          } faultCallback:faultCallback];
                                      });
                                  }
                              });
                              
                          } faultCallback:^(NSError *fault) {
                              NSLog(@"url %@  fault %@",url,fault);
                              
                              if (faultCallback) {
                                  faultCallback(GoogleApiResultFailureServerCall, fault);
                              }
                          }];
    
}


-(void)postAddressHintsFromGoogleAsynchronouslyForStaleVenue:(Venue *)venue {
    if (!venue) {
        return;
    }
    
    if (venue.hasStaleAddress) {
        NSObject *key = @(venue.locationId);
        VenueInformation *venueInfo = self.hintedVenueInformationDictionary[key];
        if (venueInfo) {
            // old?
            NSDate * atOrAfter = [NSDate dateWithTimeIntervalSinceNow:-RATE_LIMIT_LOCATION];
            if ([atOrAfter compare:venueInfo.hintPostedAt] == NSOrderedDescending) {
                [self.hintedVenueInformationDictionary removeObjectForKey:key];
                venueInfo = nil;
            }
        }
        
        if (!venueInfo) {
            venueInfo = [[VenueInformation alloc] initWithVenue:venue];
            if (![self.staleVenueInformationArray containsObject:venueInfo]) {
                [self.staleVenueInformationArray addObject:venueInfo];
            }
        }
    }
    
    if ([NSThread isMainThread]) {
        if (!self.hintTimer && self.staleVenueInformationArray.count > 0) {
            NSTimeInterval nextHintInterval = RATE_HINT_MIN + (RATE_HINT_MAX - RATE_HINT_MIN) * ((double)arc4random() / 0x100000000);
            self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:nextHintInterval target:self selector:@selector(postNextHint) userInfo:nil repeats:NO];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.hintTimer && self.staleVenueInformationArray.count > 0) {
                NSTimeInterval nextHintInterval = RATE_HINT_MIN + (RATE_HINT_MAX - RATE_HINT_MIN) * ((double)arc4random() / 0x100000000);
                self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:nextHintInterval target:self selector:@selector(postNextHint) userInfo:nil repeats:NO];
            }
        });
    }
}


-(void)postAddressHintsFromGoogleAsynchronouslyForStaleVenues:(NSArray *)venues {
    if (!venues) {
        return;
    }
    
    for (Venue *venue in venues) {
        if (venue.hasStaleAddress) {
            NSObject *key = @(venue.locationId);
            VenueInformation *venueInfo = self.hintedVenueInformationDictionary[key];
            if (venueInfo) {
                // old?
                NSDate * atOrAfter = [NSDate dateWithTimeIntervalSinceNow:-RATE_LIMIT_LOCATION];
                if ([atOrAfter compare:venueInfo.hintPostedAt] == NSOrderedDescending) {
                    [self.hintedVenueInformationDictionary removeObjectForKey:key];
                    venueInfo = nil;
                }
            }
            
            if (!venueInfo) {
                venueInfo = [[VenueInformation alloc] initWithVenue:venue];
                if (![self.staleVenueInformationArray containsObject:venueInfo]) {
                    [self.staleVenueInformationArray addObject:venueInfo];
                }
            }
        }
    }
    
    if ([NSThread isMainThread]) {
        if (!self.hintTimer && self.staleVenueInformationArray.count > 0) {
            NSTimeInterval nextHintInterval = RATE_HINT_MIN + (RATE_HINT_MAX - RATE_HINT_MIN) * ((double)arc4random() / 0x100000000);
            self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:nextHintInterval target:self selector:@selector(postNextHint) userInfo:nil repeats:NO];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.hintTimer && self.staleVenueInformationArray.count > 0) {
                NSTimeInterval nextHintInterval = RATE_HINT_MIN + (RATE_HINT_MAX - RATE_HINT_MIN) * ((double)arc4random() / 0x100000000);
                self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:nextHintInterval target:self selector:@selector(postNextHint) userInfo:nil repeats:NO];
            }
        });
    }
    
    
}


-(void)postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenue:(SPCFeaturedContent *)featuredContent {
    [self postAddressHintsFromGoogleAsynchronouslyForStaleVenue:featuredContent.venue];
}

-(void)postAddressHintsFromGoogleAsynchronouslyForStaleFeaturedContentVenues:(NSArray *)featuredContents {
    if (!featuredContents) {
        NSMutableArray *venues = [NSMutableArray arrayWithCapacity:featuredContents.count];
        for (SPCFeaturedContent *content in featuredContents) {
            if (content.venue) {
                [venues addObject:content.venue];
            }
        }
        [self postAddressHintsFromGoogleAsynchronouslyForStaleVenues:venues];
    }
}


-(void)postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenue:(Memory *)memory {
    [self postAddressHintsFromGoogleAsynchronouslyForStaleVenue:memory.venue];
}

-(void)postAddressHintsFromGoogleAsynchronouslyForStaleMemoryVenues:(NSArray *)memories {
    if (!memories) {
        NSMutableArray *venues = [NSMutableArray arrayWithCapacity:memories.count];
        for (Memory *memory in memories) {
            if (memory.venue) {
                [venues addObject:memory.venue];
            }
        }
        [self postAddressHintsFromGoogleAsynchronouslyForStaleVenues:venues];
    }
}


- (void)postNextHint {
    if ([self.staleVenueInformationArray count] > 0) {
        
        // find a venue that we are willing and able to post a hint for.
        VenueInformation *venueInfo = nil;
        
        int index = 0;
        
        NSArray *staleVenues = [NSArray arrayWithArray:self.staleVenueInformationArray];
        while (!venueInfo && staleVenues.count > index) {
            venueInfo = staleVenues[index];
            
            // omit this venue if:
            // 1. we have recently posted a hint about it
            // skip this venue if:
            // 1. we have recently posted a hint "near" it.
            
            if ([self getHintPostedForVenueInformation:venueInfo within:RATE_LIMIT_LOCATION]) {
                [self.staleVenueInformationArray removeObject:venueInfo];
                index++;
                venueInfo = nil;
            } else {
                NSDate * atOrAfter = [NSDate dateWithTimeIntervalSinceNow:-RATE_LIMIT_RADIUS];
                __block BOOL limited = NO;
                [self.hintedVenueInformationDictionary.allValues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    VenueInformation *info = obj;
                    CGFloat distance = [venueInfo.location distanceFromLocation:info.location];
                    if (distance < HINT_RADIUS && [atOrAfter compare:info.hintPostedAt] == NSOrderedAscending) {
                        limited = YES;
                        *stop = YES;
                        [self.staleVenueInformationArray removeObject:venueInfo];
                        [self.staleVenueInformationArray addObject:venueInfo];
                    }
                }];
                
                if (limited) {
                    index++;
                    venueInfo = nil;
                }
            }
        }
        
        if (venueInfo) {
            __weak typeof(self) weakSelf = self;
            [self postVenueAddressGoogleHintForVenueInformation:venueInfo rateLimited:NO resultCallback:^(GoogleApiResult apiResult, NSError *fault) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (apiResult == GoogleApiResultSuccess) {
                    // remove the venue from the stale array, and add it to the hinted.
                    [strongSelf.staleVenueInformationArray removeObject:venueInfo];
                    venueInfo.hintPostedAt = [NSDate date];
                    [strongSelf.hintedVenueInformationDictionary setObject:venueInfo forKey:@(venueInfo.locationId)];
                } else {
                    // put this venue at the end of our queue (if we can).
                    [strongSelf.staleVenueInformationArray removeObject:venueInfo];
                    [strongSelf.staleVenueInformationArray addObject:venueInfo];
                }
                
                // schedule another?
                if (strongSelf.staleVenueInformationArray.count > 0) {
                    NSTimeInterval nextHintInterval = RATE_HINT_MIN + (RATE_HINT_MAX - RATE_HINT_MIN) * ((double)arc4random() / 0x100000000);
                    strongSelf.hintTimer = [NSTimer scheduledTimerWithTimeInterval:nextHintInterval target:self selector:@selector(postNextHint) userInfo:nil repeats:NO];
                } else {
                    strongSelf.hintTimer = nil;
                }
            }];
        } else {
            self.hintTimer = nil;
        }
    } else {
        self.hintTimer = nil;
    }
}


-(void)postVenueAddressGoogleHintForVenueInformation:(VenueInformation *)venueInformation
                                  rateLimited:(BOOL)rateLimited
                               resultCallback:(void (^)(GoogleApiResult apiResult, NSError *fault))resultCallback {
    
    BOOL rateCanceled = rateLimited && [self getRateLimitedForVenueInformation:venueInformation];
    if (rateCanceled) {
        if (resultCallback) {
            resultCallback(GoogleApiResultRateLimited, nil);
        }
    } else {
        if (resultCallback) {
            resultCallback(GoogleApiResultSuccess, nil);
        }
        
        [self fetchGoogleAddressAtLatitude:venueInformation.location.coordinate.latitude longitude:venueInformation.location.coordinate.longitude resultCallback:^(NSDictionary *googleResponseDictionary) {
            NSString *url = @"/location/hint";
            NSDictionary * params = @{@"latitude": @(venueInformation.location.coordinate.latitude),
                                      @"longitude": @(venueInformation.location.coordinate.longitude),
                                      @"addressId": @(venueInformation.addressId),
                                      @"locationId": @(venueInformation.locationId),
                                      [VenueManager getGoogleAddressParamaterName] : [VenueManager getGoogleAddressParamaterValue:googleResponseDictionary]
                                      };
            [APIService makeApiCallWithMethodUrl:url
                                  andRequestType:RequestTypePost
                                   andPathParams:nil
                                  andQueryParams:params
                                  resultCallback:^(NSObject * result) {
                                      if (resultCallback) {
                                          resultCallback(GoogleApiResultSuccess, nil);
                                      }
                                  } faultCallback:^(NSError *fault) {
                                      if (resultCallback) {
                                          resultCallback(GoogleApiResultFailureServerCall, fault);
                                      }
                                  }];

        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            if (resultCallback) {
                resultCallback(apiResult, fault);
            }
        }];
    }
}





-(void)fetchTrendingVenuesForWorldWithResultCallback:(void (^)(NSArray *venues))resultCallback
                                       faultCallback:(void (^)(NSError *fault))faultCallback {
    
    NSString *url = @"/location/trending";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              // NSLog(@"get /location/trending result %@",result);
                              NSDictionary * resultDict = (NSDictionary *) result;
                              NSArray * resultLocations = resultDict[@"locations"];
                              NSMutableArray * venues = [[NSMutableArray alloc] initWithCapacity:resultLocations.count];
                              for (NSDictionary * venueDict in resultLocations) {
                                  Venue * venue = [[Venue alloc] initWithAttributes:venueDict];
                                  [venues addObject:venue];
                              }
                              
                              if (resultCallback) {
                                  resultCallback(venues);
                              }
                              
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
    }

-(void)fetchTrendingVenuesNearbyWithCurrentVenue:(Venue *)venue
                                  resultCallback:(void (^)(NSArray *venues))resultCallback
                                   faultCallback:(void (^)(NSError *fault))faultCallback {
    
    NSString *url = @"/location/trendingInCity";
    
    NSMutableDictionary * params = [[NSMutableDictionary alloc] init];
    if (venue.city) {
        params[@"city"] = venue.city;
    }
    if (venue.county) {
        params[@"county"] = venue.county;
    }
    if (venue.state) {
        params[@"stateAbbr"] = venue.state;
    }
    if (venue.country) {
        params[@"countryAbbr"] = venue.country;
    }
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:[NSDictionary dictionaryWithDictionary:params]
                          resultCallback:^(NSObject * result) {
                              // NSLog(@"get /location/trending result %@",result);
                              NSDictionary * resultDict = (NSDictionary *) result;
                              NSArray * resultLocations = resultDict[@"locations"];
                              NSMutableArray * venues = [[NSMutableArray alloc] initWithCapacity:resultLocations.count];
                              for (NSDictionary * venueDict in resultLocations) {
                                  Venue * newVenue = [[Venue alloc] initWithAttributes:venueDict];
                                  [venues addObject:newVenue];
                              }

                              if (resultCallback) {
                                  resultCallback(venues);
                              }
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}

-(NSArray *)sortVenuesByRelevanceToUser:(NSArray *)venues {
    return [venues sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"venueProximityScore" ascending:NO]]];
}


-(void)fetchSuggestedVenuesResultCallback:(void (^)(NSArray *venues))resultCallback
                                       faultCallback:(void (^)(NSError *fault))faultCallback {
    
    NSString *url = @"/memories/suggestedRegions";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:nil
                          resultCallback:^(NSObject * result) {
                              NSDictionary * resultDict = (NSDictionary *) result;
                              //NSLog(@"resultDict %@",resultDict);
                              NSArray * resultLocations = resultDict[@"locations"];
                              NSMutableArray * venues = [[NSMutableArray alloc] initWithCapacity:resultLocations.count];
                              for (NSDictionary * venueDict in resultLocations) {
                                  Venue * venue = [[Venue alloc] initWithAttributes:venueDict];
                                  if (venue.popularMemories.count > 0) {
                                      [venues addObject:venue];
                                  }
                              }
                              
                              if (resultCallback) {
                                  NSArray *resultVenue = [NSArray arrayWithArray:venues];
                                  resultCallback(resultVenue);
                              }
                              
                          } faultCallback:^(NSError *fault) {
                              if (faultCallback) {
                                  faultCallback(fault);
                              }
                          }];
}


#pragma mark Spayce grid

-(void)fetchFeaturedNearbyGridPageWithPageKey:(NSString *)pageKey
                                     latitude:(double)latitude
                                    longitude:(double)longitude
                               resultCallback:(void (^)(NSArray *venues, NSString *nextPageKey, NSString *stalePageKey))resultCallback
                                faultCallback:(void (^)(NSError *fault))faultCallback {
    
    if (pageKey) {
        // no need for hints
        [self fetchFeaturedNearbyGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:nil resultCallback:resultCallback faultCallback:faultCallback];
        return;
    }
    
    BOOL rateCanceled = [self getRateLimited];
    if (rateCanceled) {
        //NSLog(@"Rate-limited: fetching venue w/o hint");
        [self fetchFeaturedNearbyGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:nil resultCallback:resultCallback faultCallback:faultCallback];
    } else {
        [self fetchGoogleAddressAtLatitude:latitude longitude:longitude resultCallback:^(NSDictionary *googleResponseDictionary) {
            
            NSDictionary * params = @{@"latitude": @(latitude),
                                      @"longitude": @(longitude),
                                      [VenueManager getGoogleAddressParamaterName] : [VenueManager getGoogleAddressParamaterValue:googleResponseDictionary]
                                      };
            
            [self fetchFeaturedNearbyGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:params resultCallback:resultCallback faultCallback:faultCallback];
            
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            [self fetchFeaturedNearbyGridPageWithPageKey:pageKey latitude:latitude longitude:longitude hintParams:nil resultCallback:resultCallback faultCallback:faultCallback];
        }];
    }
}


-(void)fetchFeaturedNearbyGridPageWithPageKey:(NSString *)pageKey
                                     latitude:(double)latitude
                                    longitude:(double)longitude
                                   hintParams:(NSDictionary *)hintParams
                               resultCallback:(void (^)(NSArray *, NSString *, NSString *))resultCallback
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
    
    NSString *build = [NSBundle mainBundle].infoDictionary[@"CFBundleVersion"];
    params[@"buildNumber"] = build;
    
    NSString *url = @"/location/nearby/featured";
    
    [APIService makeApiCallWithMethodUrl:url
                          andRequestType:RequestTypeGet
                           andPathParams:nil
                          andQueryParams:[NSDictionary dictionaryWithDictionary:params]
                          resultCallback:^(NSObject * result) {
                              //NSLog(@" url %@ params %@ result %@",url,params, result);
                              
                              
                              //DO THIS ON A BACKGROUND THREAD!!!
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  
                                  NSDictionary * resultDict = (NSDictionary *) result;
                                  NSArray * resultLocations = resultDict[@"locations"];
                                  NSString * pageKey = resultDict[@"nextPageKey"];
                                  NSString *stalePageKey = (NSString *)[TranslationUtils valueOrNil:resultDict[@"isStaleKey"]];
                                  

                                  CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                                  
                                  NSMutableArray * venues = [[NSMutableArray alloc] initWithCapacity:resultLocations.count];
                                  for (NSDictionary * venueDict in resultLocations) {
                                      Venue * newVenue = [[Venue alloc] initWithAttributes:venueDict];
                                      
                                      CGFloat distance = [location distanceFromLocation:newVenue.location];
                                      newVenue.distance = [NSNumber numberWithFloat:distance];
                                      newVenue.distanceAway = distance;
                                      [newVenue updateDistance:distance];
                                      
                                      if (newVenue.popularMemories.count > 0) {
                                          [venues addObject:newVenue];
                                      }
                            
                                  }
                                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                                      if (resultCallback) {
                                          resultCallback(venues, pageKey,stalePageKey);
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


-(void)checkForFreshFirstPageNearbyGridWithStalePageKey:(NSString *)pageKey
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
    
    NSString *url = @"/location/nearby/featured/isStale";
    
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

#pragma mark - Helper methods

-(BOOL) getRateLimited {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    BOOL limited = now <= self.lastAddressQuery + RATE_LIMIT_GLOBAL;
    limited = limited || now <= self.lastAddressQueryQuotaFailure + RATE_LIMIT_QUOTA_FAILURE;
    return limited;
}

-(BOOL) getRateLimitedForVenue:(Venue *)venue {
    if ([self getRateLimited]) {
        return YES;
    }
    return [self getHintPostedForVenue:venue within:RATE_LIMIT_LOCATION];
}

-(BOOL) getHintPostedForVenue:(Venue *)venue within:(NSTimeInterval)within {
    NSNumber * key = @(venue.locationId);
    VenueInformation *venueInfo = self.hintedVenueInformationDictionary[key];
    if (!venueInfo) {
        return NO;
    }
    NSDate * atOrAfter = [NSDate dateWithTimeIntervalSinceNow:-within];
    if ([atOrAfter compare:venueInfo.hintPostedAt] == NSOrderedDescending) {
        [self.hintedVenueInformationDictionary removeObjectForKey:key];
        return NO;
    }
    return YES;
}

-(BOOL) getRateLimitedForVenueInformation:(VenueInformation *)venueInformation {
    if ([self getRateLimited]) {
        return YES;
    }
    return [self getHintPostedForVenueInformation:venueInformation within:RATE_LIMIT_LOCATION];
}

-(BOOL) getHintPostedForVenueInformation:(VenueInformation *)venueInformation within:(NSTimeInterval)within {
    NSNumber * key = @(venueInformation.locationId);
    VenueInformation *venueInfo = self.hintedVenueInformationDictionary[key];
    if (!venueInfo) {
        return NO;
    }
    NSDate * atOrAfter = [NSDate dateWithTimeIntervalSinceNow:-within];
    if ([atOrAfter compare:venueInfo.hintPostedAt] == NSOrderedDescending) {
        [self.hintedVenueInformationDictionary removeObjectForKey:key];
        return NO;
    }
    return YES;
}

@end
