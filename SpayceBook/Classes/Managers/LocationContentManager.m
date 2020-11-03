//
//  LocationContentManager.m
//  Spayce
//
//  Created by Jake Rosin on 5/21/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "LocationContentManager.h"

// Framework
#include <CoreLocation/CoreLocation.h>

// Model
#import "Asset.h"
#import "Memory.h"
#import "SPCBaseDataSource.h"
#import "SPCFeaturedContent.h"

// Controller
#import "SPCCreateVenuePostViewController.h"

// General
#import "Singleton.h"

// Manager
#import "AuthenticationManager.h"
#import "LocationManager.h"
#import "MeetManager.h"
#import "VenueManager.h"

// Types of Content.  Users of this class can make requests for a specific
// set of content types.
NSString * SPCLocationContentVenue = @"SPCLocationContentVenue";
NSString * SPCLocationContentDeviceVenue = @"SPCLocationContentDeviceVenue";
NSString * SPCLocationContentNearbyVenues = @"SPCLocationContentNearbyVenues";
NSString * SPCLocationContentFuzzedVenue = @"SPCLocationContentFuzzedVenue";

NSString * SPCLocationContentFuzzedNeighborhoodVenue = @"SPCLocationContentFuzzedNeighborhoodVenue";
NSString * SPCLocationContentFuzzedCityVenue = @"SPCLocationContentFuzzedCityVenue";

// NSError domain / types.
NSString * SPC_LCM_ErrorDomain = @"SPC_LCM_ErrorDomain";
NSString * SPC_LCM_ErrorInfoKey_Content = @"SPC_LCM_ErrorInfoKey_Content";
NSString * SPC_LCM_ErrorInfoKey_NSError = @"SPC_LCM_ErrorInfoKey_NSError";
NSInteger SPC_LCM_ErrorCode_InternalInconsistency = 1;
NSInteger SPC_LCM_ErrorCode_NoLocation = 2;
NSInteger SPC_LCM_ErrorCode_ContentFetch = 3;

// Location Content updated
NSString * SPCLocationContentVenuesUpdatedInternally = @"SPCLocationContentVenuesUpdatedInternally";
NSString * SPCLocationContentUpdatedInternally = @"SPCLocationContentUpdatedInternally";

NSString * SPCLocationContentNearbyVenuesUpdatedFromServer = @"SPCLocationContentNearbyVenuesUpdatedFromServer";

@interface LocationContentManager()

@property (nonatomic, assign) BOOL cachedUserDeterminedLocation;
@property (nonatomic, strong) CLLocation *cachedContentLocation;
@property (nonatomic, strong) NSDictionary *cachedContent;

@property (nonatomic, strong) CLLocation *cachedContentDeviceLocation;

@end

@implementation LocationContentManager

#pragma mark - Object lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

SINGLETON_GCD(LocationContentManager);

- (id)init {
    self = [super init];
    if (self) {
        self.cachedContent = [[NSDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryPosted:) name:@"addMemoryLocally" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryDeleted:) name:SPCMemoryDeleted object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryUpdated:) name:SPCMemoryUpdated object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localMemoryMoved:) name:SPCMemoryMovedFromVenueToVenue object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localVenuePosted:) name:kSPCDidPostVenue object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localVenueUpdated:) name:kSPCDidUpdateVenue object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_localVenueDeleted:) name:kSPCDidDeleteVenue object:nil];
        
        
        // change of user: don't persist cache
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_newUser:) name:kAuthenticationDidFinishWithSuccessNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_newUser:) name:kAuthenticationDidFailNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_newUser:) name:kAuthenticationDidLogoutNotification object:nil];
    }
    
    return self;
}

#pragma mark - Content access


-(void) clearContentAndLocation {
    @synchronized(self) {
        self.cachedContentLocation = nil;
        self.cachedContentDeviceLocation = nil;
        self.cachedContent = [[NSDictionary alloc] init];
    }
}


-(void) clearContent:(NSArray *)contentTypes {
    @synchronized(self) {
        NSDictionary *previous = [[NSDictionary alloc] initWithDictionary:self.cachedContent];
        NSMutableDictionary *now = [[NSMutableDictionary alloc] init];
        for (NSString * key in [previous keyEnumerator]) {
            if (![contentTypes containsObject:key]) {
                now[key] = previous[key];
            }
        }
        self.cachedContent = [[NSDictionary alloc] initWithDictionary:now];
    }
}

-(void) getContentFromCache:(NSArray *)contentTypes resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback {
    
    NSDictionary *results;
    @synchronized(self) {
        if (self.cachedContent) {
            results = [NSDictionary dictionaryWithDictionary:self.cachedContent];
        } else {
            results = [NSDictionary dictionary];
        }
    }
    
    BOOL hasContent = YES;
    for (NSString *contentType in contentTypes) {
        if (![results objectForKey:contentType]) {
            hasContent = NO;
        }
    }
    if (hasContent) {
        if (resultCallback) {
            resultCallback(results);
        }
    } else if (faultCallback) {
        faultCallback([LocationContentManager errorWithInternalInconsistency]);
    }
}

-(void) getContent:(NSArray *)contentTypes resultCallback:(void (^)(NSDictionary *))resultCallback faultCallback:(void (^)(NSError *))faultCallback {
    [self getContent:contentTypes progressCallback:^(NSDictionary *partialResults, BOOL *cancel) { /* nothing */ } resultCallback:resultCallback faultCallback:faultCallback];
}

-(void) getContent:(NSArray *)contentTypes progressCallback:(void (^)(NSDictionary *, BOOL *))progressCallback resultCallback:(void (^)(NSDictionary *))resultCallback faultCallback:(void (^)(NSError *))faultCallback {
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        
        BOOL userDetermined;
        CLLocation *location;
        CLLocation *deviceLocation;
        Venue *venue;
        
        deviceLocation = self.cachedContentDeviceLocation;
        if (!deviceLocation) {
            // totally fresh location: we have no cached data to retain.
            [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
                // Current location -- either by GPS, or user-determined?
                BOOL userDetermined;
                CLLocation * location;
                CLLocation * deviceLocation;
                Venue * venue;
                
                if ([LocationManager sharedInstance].userManuallySelectedLocation) {
                    location = [LocationManager sharedInstance].manualLocation;
                    venue = [LocationManager sharedInstance].manualVenue;
                    userDetermined = YES;
                } else {
                    location = [[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong];
                    venue = nil;
                    userDetermined = NO;
                }
                deviceLocation = [[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong];
                
                // Make the call
                [self getContentWithLocation:location userDetermined:userDetermined deviceLocation:deviceLocation venue:venue content:contentTypes cacheWhenComplete:YES progressCallback:progressCallback resultCallback:resultCallback faultCallback:faultCallback];
            } faultCallback:^(NSError *fault) {
                if (faultCallback) {
                    faultCallback([LocationContentManager errorWithNoLocation]);
                }
            }];
            return;
        } else {
            if ([LocationManager sharedInstance].userManuallySelectedLocation) {
                location = [LocationManager sharedInstance].manualLocation;
                venue = [LocationManager sharedInstance].manualVenue;
                userDetermined = YES;
            } else {
                location = deviceLocation;
                venue = nil;
                userDetermined = NO;
            }
            
            // Make the call
            [self getContentWithLocation:location userDetermined:userDetermined deviceLocation:deviceLocation venue:venue content:contentTypes cacheWhenComplete:YES progressCallback:progressCallback resultCallback:resultCallback faultCallback:faultCallback];
        }
        
    }
    
}


-(void) getUncachedContent:(NSArray *)contentTypes resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback {
    [self getUncachedContent:contentTypes progressCallback:^(NSDictionary *partialResults, BOOL *cancel) { /*nothing*/ } resultCallback:resultCallback faultCallback:faultCallback];
}

-(void) getUncachedContent:(NSArray *)contentTypes progressCallback:(void (^)(NSDictionary *partialResults, BOOL *cancel))progressCallback resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback {
    
    // Determine the current device and 'user' location -- if we can.
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
    
        [[LocationManager sharedInstance] getCurrentLocationWithResultCallback:^(double gpsLat, double gpsLong) {
            // Current location -- either by GPS, or user-determined?
            BOOL userDetermined;
            CLLocation * location;
            CLLocation * deviceLocation;
            Venue * venue;
            
            if ([LocationManager sharedInstance].userManuallySelectedLocation) {
                location = [LocationManager sharedInstance].manualLocation;
                venue = [LocationManager sharedInstance].manualVenue;
                userDetermined = YES;
            } else {
                location = [[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong];
                venue = nil;
                userDetermined = NO;
            }
            deviceLocation = [[CLLocation alloc] initWithLatitude:gpsLat longitude:gpsLong];
            
            // Make the call
            [self getContentWithLocation:location userDetermined:userDetermined deviceLocation:deviceLocation venue:venue content:contentTypes cacheWhenComplete:NO progressCallback:progressCallback resultCallback:resultCallback faultCallback:faultCallback];
        } faultCallback:^(NSError *fault) {
            if (faultCallback) {
                faultCallback([LocationContentManager errorWithNoLocation]);
            }
        }];
        
    }
    
}

-(void) getContentWithLocation:(CLLocation *)location userDetermined:(BOOL)userDetermined deviceLocation:(CLLocation *)deviceLocation venue:(Venue *)venue content:(NSArray *)contentTypes cacheWhenComplete:(BOOL)cacheWhenComplete progressCallback:(void (^)(NSDictionary *partialResults, BOOL *cancel))progressCallback resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback {
    
    NSMutableDictionary * content;
    @synchronized(self) {
        // Do our best to perform an atomic update of our cached content.  In other words,
        // construct a dictionary containing everything we need, and at that
        // point set cachedContent / cachedContentLocation appropriately.
        BOOL useCache = [self hasCachedLocation:location userDetermined:userDetermined];
        BOOL useCacheDevice = [self hasCachedDeviceLocation:deviceLocation];
        // 'useCache' determines whether we keep the cache values having to do with
        // the user's reported location (which they can manually assign if they choose).
        // 'useCacheDevice' determines whether we keep cache values having to do with
        // the user's actual, device location (which they can't change), such as
        // 'nearby venues.'
        
        content = [[NSMutableDictionary alloc] initWithDictionary:self.cachedContent];
        if (!useCache || !location) {
            [content removeObjectForKey:SPCLocationContentVenue];
            //NSLog(@"Clearing manual location cache");
        }
        if (!useCacheDevice || !deviceLocation) {
            [content removeObjectForKey:SPCLocationContentNearbyVenues];
            [content removeObjectForKey:SPCLocationContentDeviceVenue];
            [content removeObjectForKey:SPCLocationContentFuzzedVenue];
            [content removeObjectForKey:SPCLocationContentFuzzedCityVenue];
            [content removeObjectForKey:SPCLocationContentFuzzedNeighborhoodVenue];
            //NSLog(@"Clearing device location cache");
        }
        
        // skip the venue fetch step, if we can
        if (venue && !content[SPCLocationContentVenue]) {
            content[SPCLocationContentVenue] = venue;
        }
    }
    
    // This method starts the fetch / callback process.
    [self fetchContentNextStepWithLocation:location userDetermined:userDetermined deviceLocation:deviceLocation content:content cacheWhenComplete:cacheWhenComplete progressCallback:progressCallback resultCallback:resultCallback faultCallback:faultCallback];
}

-(BOOL) hasCachedLocation:(CLLocation *)location userDetermined:(BOOL)userDetermined {
    
    if (self.cachedContentLocation && location) {
        if (userDetermined) {
            // Manually selected locations have no leeway for movement.  If
            // you are in a new place (with different lat / lng), do not use the cached
            // values.
            // TODO: consider examining venue address Ids once this information is
            // stored in LocationManager.
            return self.cachedUserDeterminedLocation && self.cachedContentLocation && self.cachedContentLocation.coordinate.latitude == location.coordinate.latitude && self.cachedContentLocation.coordinate.longitude == location.coordinate.longitude;
        } else {
            // True locations have some leeway for movement before the cache is dropped.
            return !self.cachedUserDeterminedLocation && self.cachedContentLocation && [self.cachedContentLocation distanceFromLocation:location] < 10;
        }
    }
    else {
        return NO;
    }
}

-(BOOL) hasCachedDeviceLocation:(CLLocation *)location {
    // True locations have some leeway for movement before the cache is dropped.
    if (self.cachedContentDeviceLocation && location) {
        return self.cachedContentDeviceLocation && [self.cachedContentDeviceLocation distanceFromLocation:location] < 10;
    }
    else {
        return NO;
    }
}

-(void) updateCacheWithLocation:(CLLocation *)location userDetermined:(BOOL)userDetermined deviceLocation:(CLLocation *)deviceLocation content:(NSDictionary *)content {
    
    BOOL updatedNearbyVenues;
    
    @synchronized(self) {
        BOOL clearedCache = NO;
        BOOL clearedDeviceCache = NO;
        if (![self hasCachedLocation:location userDetermined:userDetermined]) {
            clearedCache = YES;
        }
        if (![self hasCachedDeviceLocation:deviceLocation]) {
            clearedDeviceCache = YES;
        }
        
        updatedNearbyVenues = (clearedDeviceCache || ![self.cachedContent objectForKey:SPCLocationContentNearbyVenues]) && [content objectForKey:SPCLocationContentNearbyVenues];
        
        self.cachedContent = [[NSDictionary alloc] initWithDictionary:content];
        if (clearedCache) {
            self.cachedContentLocation = location;
            self.cachedUserDeterminedLocation = userDetermined;
        }
        if (clearedDeviceCache) {
            self.cachedContentDeviceLocation = deviceLocation;
        }
    }
    
    if (updatedNearbyVenues) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentNearbyVenuesUpdatedFromServer object:nil];
    }
}

-(void) fetchContentNextStepWithLocation:(CLLocation *)location userDetermined:(BOOL)userDetermined deviceLocation:(CLLocation *)deviceLocation content:(NSMutableDictionary *)content cacheWhenComplete:(BOOL)cacheWhenComplete progressCallback:(void (^)(NSDictionary *partialResults, BOOL *cancel))progressCallback resultCallback:(void (^)(NSDictionary *results))resultCallback faultCallback:(void (^)(NSError *fault))faultCallback {
    
    // Progress callback.
    BOOL cancel = NO;
    progressCallback(content, &cancel);
    if (cancel) {
        // whelp, that's it
        return;
    }
    
    // If we have all the content we need, perform the update immediately.
    BOOL allContent = content[SPCLocationContentVenue] && content[SPCLocationContentDeviceVenue] && content[SPCLocationContentNearbyVenues];
    
    if (allContent) {
        if (resultCallback) {
            resultCallback(content);
        }
    } else {
        // Fetch all the content.
        [[VenueManager sharedInstance] fetchVenueAndNearbyVenuesWithGoogleHintAtLatitude:deviceLocation.coordinate.latitude longitude:deviceLocation.coordinate.longitude rateLimited:YES resultCallback:^(Venue *venue, NSArray *venues, Venue *fuzzedNeighborhoodVenue,Venue *fuzzedCityVenue) {
            
            if (!venue.latitude || [venue.latitude floatValue] == 0) {
                venue.latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
                venue.longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
            }
            // add to our values
            NSLog(@"Content has %d items; venue is %@", content.count, venue);
            if (venue) {
                if (!content[SPCLocationContentVenue]) {
                    content[SPCLocationContentVenue] = venue;
                }
                content[SPCLocationContentDeviceVenue] = venue;
                content[SPCLocationContentNearbyVenues] = venues;
            }
            if (fuzzedNeighborhoodVenue) {
                //NSLog(@"fuzzed neigh venue received in LCM");
                content[SPCLocationContentFuzzedNeighborhoodVenue] = fuzzedNeighborhoodVenue;
            }
            if (fuzzedCityVenue) {
                //NSLog(@"fuzzed city venue received in LCM");
                content[SPCLocationContentFuzzedCityVenue] = fuzzedCityVenue;
            }
            
            // Progress callback.
            BOOL cancel = NO;
            progressCallback(content, &cancel);
            if (cancel) {
                // whelp, that's it
                return;
            }
            
            // Cache this result and perform the result callback.
            if (cacheWhenComplete) {
                [self updateCacheWithLocation:location userDetermined:userDetermined deviceLocation:deviceLocation content:content];
            }
            if (resultCallback) {
                resultCallback(content);
            }
            
        } faultCallback:^(GoogleApiResult apiResult, NSError *fault) {
            // fault
            if (faultCallback) {
                faultCallback([LocationContentManager errorWithContent:SPCLocationContentNearbyVenues originalError:fault]);
            }
        }];

    }
}



#pragma mark - NSError construction

+ (NSError *) errorWithInternalInconsistency {
    return [NSError errorWithDomain:SPC_LCM_ErrorDomain code:SPC_LCM_ErrorCode_InternalInconsistency userInfo:nil];
}

+ (NSError *) errorWithNoLocation {
    return [NSError errorWithDomain:SPC_LCM_ErrorDomain code:SPC_LCM_ErrorCode_NoLocation userInfo:nil];
}

+ (NSError *) errorWithContent:(NSString *)content originalError:(NSError *)error {
    return [NSError errorWithDomain:SPC_LCM_ErrorDomain
                               code:SPC_LCM_ErrorCode_ContentFetch
                           userInfo:@{ SPC_LCM_ErrorInfoKey_Content : content ,
                                       SPC_LCM_ErrorInfoKey_NSError : error }];
}


#pragma mark - Notification responders and relevant helpers

- (BOOL)updateVenue:(Venue *)venue withMemoryCountDelta:(NSInteger)memoryCountDelta starCountDelta:(NSInteger)starCountDelta {
    __block BOOL changed = NO;
    @synchronized(self) {
        Venue *currentVenue = self.cachedContent[SPCLocationContentVenue];
        Venue *deviceVenue = self.cachedContent[SPCLocationContentDeviceVenue];
        NSArray *nearbyVenues = self.cachedContent[SPCLocationContentNearbyVenues];
        
        // update cached venues with these deltas.  Take care not to update the
        // same instance twice.
        
        if ([SPCMapDataSource venue:venue is:currentVenue]) {
            currentVenue.totalMemories += memoryCountDelta;
            currentVenue.totalStars += starCountDelta;
            changed = YES;
        }
        if ([SPCMapDataSource venue:venue is:deviceVenue] && currentVenue != deviceVenue) {
            deviceVenue.totalMemories += memoryCountDelta;
            deviceVenue.totalStars += starCountDelta;
            changed = YES;
        }
        [nearbyVenues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Venue * v = obj;
            if ([SPCMapDataSource venue:venue is:v] && v != currentVenue && v != deviceVenue) {
                v.totalMemories += memoryCountDelta;
                v.totalStars += starCountDelta;
                changed = YES;
            }
        }];
    }
    return changed;
}

- (void)spc_localMemoryPosted:(NSNotification *)note {
    BOOL venuesChanged = NO;
    NSDictionary * cacheContent;
    @synchronized(self) {
        Memory *memory = (Memory *)[note object];

        if (memory && memory.venue) {
            venuesChanged = [self updateVenue:memory.venue withMemoryCountDelta:1 starCountDelta:0];
        }
        
        cacheContent = [NSDictionary dictionaryWithDictionary:self.cachedContent];
    }
    
    if (venuesChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentVenuesUpdatedInternally object:cacheContent];
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentUpdatedInternally object:cacheContent];
    }
}

- (void)spc_localMemoryDeleted:(NSNotification *)note {
    BOOL venuesChanged = NO;
    NSDictionary * cacheContent;
    @synchronized(self) {
        Memory * memory = [note object];
        
        // remove the memory from venue totals.
        venuesChanged = [self updateVenue:memory.venue withMemoryCountDelta:-1 starCountDelta:-memory.starsCount];
        
        cacheContent = [NSDictionary dictionaryWithDictionary:self.cachedContent];
    }
    
    if (venuesChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentVenuesUpdatedInternally object:cacheContent];
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentUpdatedInternally object:cacheContent];
    }
}

- (void)spc_localMemoryUpdated:(NSNotification *)note {
    // nothing to do
}

- (void)spc_localMemoryMoved:(NSNotification *)note {
    BOOL venuesChanged = NO;
    NSDictionary * cacheContent;
    @synchronized(self) {
        NSArray * objects = [note object];
        Memory * memory = objects[0];
        Venue * sourceVenue = objects[1];
        Venue * destVenue = objects[2];
        
        // remove the memory from source venue totals...
        venuesChanged = [self updateVenue:sourceVenue withMemoryCountDelta:-1 starCountDelta:-memory.starsCount] || venuesChanged;
        // add to the dest venue totals...
        venuesChanged = [self updateVenue:destVenue withMemoryCountDelta:1 starCountDelta:memory.starsCount] || venuesChanged;
        
        cacheContent = [NSDictionary dictionaryWithDictionary:self.cachedContent];
    }
    
    if (venuesChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentVenuesUpdatedInternally object:cacheContent];
        [[NSNotificationCenter defaultCenter] postNotificationName:SPCLocationContentUpdatedInternally object:cacheContent];
    }
}

- (void)spc_localVenuePosted:(NSNotification *)note {
    Venue * venue = (Venue *)[note object];
    NSArray * venues = self.cachedContent[SPCLocationContentNearbyVenues];
    
    if (venue && venues) {
        // Add this venue to our cache
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:venues];
        [tempArray addObject:venue];
        NSMutableDictionary * newCache = [[NSMutableDictionary alloc] initWithDictionary:self.cachedContent];
        newCache[SPCLocationContentNearbyVenues] = tempArray;
        self.cachedContent = newCache;
    }
}

- (void)spc_localVenueUpdated:(NSNotification *)note {
    // quick-and-dirty: clear our cache.
    // TODO: more efficiently update our local records
    NSLog(@"spc_localVenueUpdated");
    [self clearContentAndLocation];
}

- (void)spc_localVenueDeleted:(NSNotification *)note {
    // quick-and-dirty: clear our cache.
    // TODO: more efficiently update our local records
    NSLog(@"spc_localVenueDeleted");
    [self clearContentAndLocation];
}



- (void)spc_newUser:(NSNotification *)note {
    [self clearContentAndLocation];
}

@end
