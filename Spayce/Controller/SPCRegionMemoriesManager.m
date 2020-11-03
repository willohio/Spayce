//
//  SPCRegionMemoriesManager.m
//  Spayce
//
//  Created by Jake Rosin on 7/11/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCRegionMemoriesManager.h"

// Model
#import "Location.h"
#import "SPCExploreMemoryCache.h"
#import "Venue.h"

// Manager
#import "AuthenticationManager.h"
#import "MeetManager.h"

// MapKit: for CoordinateRegions and the like.
#import "MKMapView+SPCAdditions.h"
#import <GoogleMaps/GoogleMaps.h>

const CGFloat RECACHE_REGION_COVERAGE_EMERGENCY_MAXIMUM = 0.05f;   // If only 5% of the region is covered by the cache...
const CGFloat RECACHE_REGION_COVERAGE_MAXIMUM = 0.5f;       // if the requested region is < 50% covered by the cache...
const CGFloat RECACHE_REGION_OVERCOVERAGE_MINIMUM = 10.f;  // if the cache is 10 times larger than the requested region...
const NSInteger CACHE_EXPANSIONS_WITHOUT_DELAY = 3;
const NSTimeInterval CACHE_EXPANSIONS_TIME_BETWEEN = 60.0f;
const NSTimeInterval CACHE_REFRESH_AFTER = 60.0f * 10;    // 10 minutes
const NSTimeInterval CACHE_REPLACE_RATE_LIMIT = 2.0f;
const NSTimeInterval CACHE_PAGE_QUERY_LIMIT = 10.f;       // a new page every 10 seconds.

const NSInteger MAXIMUM_CACHE_SIZE = 5000;             // don't need more than 5000 memories at once...

@interface SPCRegionMemoriesManager()

@property (nonatomic, strong) NSArray *permanentMemories;
@property (nonatomic, strong) NSArray *cachedMemories;

@property (nonatomic, assign) CGFloat southWestLatitude;
@property (nonatomic, assign) CGFloat southWestLongitude;
@property (nonatomic, assign) CGFloat northEastLatitude;
@property (nonatomic, assign) CGFloat northEastLongitude;
@property (nonatomic, strong) NSString *nextPageKey;
@property (nonatomic, strong) NSArray *memories;
@property (nonatomic, strong) NSArray *allMemories;
@property (nonatomic, assign) NSInteger numberOfMemoryQueries;
@property (nonatomic, assign) NSInteger numberOfMemoriesInLastQuery;
@property (nonatomic, assign) NSTimeInterval lastQueryTime;
@property (nonatomic, assign) NSTimeInterval firstQueryTime;
@property (nonatomic, assign) NSInteger regionNumber;
@property (nonatomic, assign) BOOL freshQueryInProgress;
@property (nonatomic, assign) BOOL pageQueryInProgress;


@end


@implementation SPCRegionMemoriesManager

SINGLETON_GCD(SPCRegionMemoriesManager);

- (instancetype) init {
    self = [super init];
    if (!self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:)
                                                     name:kAuthenticationDidLogoutNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthenticationSuccess:)
                                                     name:kAuthenticationDidFinishWithSuccessNotification
                                                   object:nil];
    }
    return self;
}


#pragma mark Property accessors

- (NSArray *)permanentMemories {
    if (!_permanentMemories) {
        _permanentMemories = [NSArray array];
    }
    return _permanentMemories;
}

- (NSArray *)cachedMemories {
    if (!_cachedMemories) {
        _cachedMemories = [NSArray array];
    }
    return _cachedMemories;
}


#pragma mark Actions

-(void) handleLogout:(NSNotification *)notification {
    // clear local cached data
    [self clear];
}

-(void) handleAuthenticationSuccess:(NSNotification *)notification {
    // clear local cached data
    [self clear];
}

-(void) clear {
    self.permanentMemories = nil;
    [self clearImpermanent];
}

-(void)clearImpermanent {
    self.southWestLatitude = 0;
    self.southWestLongitude = 0;
    self.northEastLatitude = 0;
    self.northEastLongitude = 0;
    self.nextPageKey = nil;
    self.cachedMemories = nil;
    self.memories = nil;
    self.allMemories = nil;
    self.numberOfMemoryQueries = 0;
    self.numberOfMemoriesInLastQuery = 0;
    self.lastQueryTime = 0;
    self.firstQueryTime = 0;
    [self rebuildCache];
}

-(NSArray *)sortMemories:(NSArray *)memories {
    NSArray *sorted = [memories sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO]]];
    // remove duplicates
    NSMutableArray *mutable = [NSMutableArray arrayWithCapacity:sorted.count];
    for (int i = 0; i < sorted.count; i++) {
        if (i == 0 || [sorted[i] recordID] != [sorted[i-1] recordID]) {
            [mutable addObject:sorted[i]];
        }
    }
    return [NSArray arrayWithArray:mutable];
}

-(void)setCacheMemories:(NSArray *)memories
  forRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
              southWestLongitude:(CGFloat)southWestLongitude
               northEastLatitude:(CGFloat)northEastLatitude
             northEastLongitude:(CGFloat)northEastLongitude
            nextPageKey:(NSString *)nextPageKey {
    self.southWestLatitude = southWestLatitude;
    self.southWestLongitude = southWestLongitude;
    self.northEastLatitude = northEastLatitude;
    self.northEastLongitude = northEastLongitude;
    self.nextPageKey = nextPageKey;
    self.numberOfMemoryQueries = 1;
    self.numberOfMemoriesInLastQuery = memories.count;
    self.lastQueryTime = [[NSDate date] timeIntervalSince1970];
    self.firstQueryTime = self.lastQueryTime;
    
    self.cachedMemories = [self memoriesByCombiningArray:
                           [self memories:self.cachedMemories withinRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude] withArray:memories];
    [self rebuildCache];
}

-(void)expandCacheMemories:(NSArray *)memories withNextPageKey:(NSString *)nextPageKey {
    self.numberOfMemoryQueries++;
    self.numberOfMemoriesInLastQuery = memories.count;
    self.lastQueryTime = [[NSDate date] timeIntervalSince1970];
    
    self.nextPageKey = nextPageKey;
    self.cachedMemories = [self memoriesByCombiningArray:self.cachedMemories withArray:memories];
    [self rebuildCache];
}

- (NSArray *)memories:(NSArray *)memories
                     withinRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                    southWestLongitude:(CGFloat)southWestLongitude
                                     northEastLatitude:(CGFloat)northEastLatitude
                                    northEastLongitude:(CGFloat)northEastLongitude {
    if (!memories) {
        return nil;
    }
    NSMutableArray *mut = [[NSMutableArray alloc] initWithCapacity:memories.count];
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:CLLocationCoordinate2DMake(southWestLatitude, southWestLongitude) coordinate:CLLocationCoordinate2DMake(northEastLatitude, northEastLongitude)];
    for (int i = 0; i < memories.count; i++) {
        Memory *memory = memories[i];
        if ([bounds containsCoordinate:CLLocationCoordinate2DMake(memory.location.latitude.doubleValue, memory.location.longitude.doubleValue)]) {
            [mut addObject:memory];
        }
    }
    return [NSArray arrayWithArray:mut];
}

- (NSArray *)memoriesByCombiningArray:(NSArray *)array1 withArray:(NSArray *)array2 {
    if (!array1 || array1.count == 0) {
        if (array2 && array2.count > 0) {
            return [self memoriesByCombiningArray:array2 withArray:array1];
        } else {
            return [NSArray array];
        }
    } else {
        if (!array2 || array2.count == 0) {
            return array1;
        } else {
            NSMutableSet *memoryKeys = [NSMutableSet setWithCapacity:array1.count + array2.count];
            NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:array1.count + array2.count];
            for (Memory *memory in array1) {
                if (![memoryKeys containsObject:memory.key]) {
                    [memoryKeys addObject:memory.key];
                    [mutArray addObject:memory];
                }
            }
            for (Memory *memory in array2) {
                if (![memoryKeys containsObject:memory.key]) {
                    [memoryKeys addObject:memory.key];
                    [mutArray addObject:memory];
                }
            }
            return [NSArray arrayWithArray:mutArray];
        }
    }
}

- (void)rebuildCache {
    // combine permanent and cached memories, leaving out duplicate memories.
    NSMutableSet *keys = [NSMutableSet set];
    NSMutableArray *mems = [NSMutableArray arrayWithCapacity:(self.permanentMemories.count + self.cachedMemories.count)];
    for (Memory *mem in self.permanentMemories) {
        if (![keys containsObject:mem.key]) {
            [mems addObject:mem];
        }
    }
    for (Memory *mem in self.cachedMemories) {
        if (![keys containsObject:mem.key]) {
            [mems addObject:mem];
        }
    }
    
    NSArray *sortedMemories = [self sortMemories:mems];
    self.memories = [[SPCExploreMemoryCache sharedInstance] unexploredMemoriesFromMemories:sortedMemories];
    self.allMemories = sortedMemories;
}

-(NSInteger)getMinCacheMemoryIdInSortedArray:(NSArray *)memories {
    if (!memories || memories.count == 0) {
        return -1;
    }
    // cache should be sorted in DECREASING id order.
    return ((Memory *)memories[memories.count -1]).recordID;
}

-(NSInteger)getMaxCacheMemoryIdInSortedArray:(NSArray *)memories {
    if (!memories || memories.count == 0) {
        return -1;
    }
    // cache should be sorted in DECREASING id order.
    return ((Memory *)memories[0]).recordID;
}




#pragma mark - Cache helper functions

-(CGFloat) proportionCoveredByCacheOfRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                              southWestLongitude:(CGFloat)southWestLongitude
                                               northEastLatitude:(CGFloat)northEastLatitude
                                              northEastLongitude:(CGFloat)northEastLongitude {
    if (!self.lastQueryTime || !self.numberOfMemoryQueries) {
        return 0.0f;
    }
    
    if (northEastLongitude < southWestLongitude) {
        northEastLongitude += 360;
    }
    
    // Relatively straightforward.  Use a terrible projection that assumes 1 degree is the
    // same change everywhere.
    CGRect regionRect = CGRectMake(southWestLongitude, southWestLatitude, northEastLongitude - southWestLongitude, northEastLatitude - southWestLatitude);
    CGFloat cacheNorthEastLongitude = self.northEastLongitude;
    if (cacheNorthEastLongitude < self.southWestLongitude) {
        cacheNorthEastLongitude += 360;
    }
    CGRect cacheRect = CGRectMake(self.southWestLongitude, self.southWestLatitude, cacheNorthEastLongitude - self.southWestLongitude, self.northEastLatitude - self.southWestLatitude);
    
    if (!CGRectIntersectsRect(regionRect, cacheRect)) {
        // no intersection
        return 0.0f;
    }
    
    CGFloat regionArea = regionRect.size.width * regionRect.size.height;
    CGFloat cacheArea = cacheRect.size.width * cacheRect.size.height;
    
    CGRect intersectRect = CGRectIntersection(regionRect, cacheRect);
    CGFloat intersectArea = intersectRect.size.width * intersectRect.size.height;
    if (CGRectEqualToRect(intersectRect, cacheRect)) {
        // the new region fully encloses the cache.
        // Return the proportion -- i.e., fraction of the area -- of the region
        // which is covered.
        return intersectArea / regionArea;
    } else if (CGRectEqualToRect(intersectRect, regionRect)) {
        // The cache fully encloses the new region.  We allow "overcoverage."
        return cacheArea / regionArea;
    }
    
    // There is a partial intersection between the two.  Divide intersection
    // by region.
    return intersectArea / regionArea;
}

-(BOOL) hasCachedResultsForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                    southWestLongitude:(CGFloat)southWestLongitude
                                     northEastLatitude:(CGFloat)northEastLatitude
                                    northEastLongitude:(CGFloat)northEastLongitude {
    CGFloat coverage = [self proportionCoveredByCacheOfRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude];
    if (coverage < RECACHE_REGION_COVERAGE_MAXIMUM) {
        return NO;
    } else if (coverage > RECACHE_REGION_OVERCOVERAGE_MINIMUM) {
        return NO;
    }
    return YES;
}


- (Memory *) getCachedUnexploredMemoryForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                                  southWestLongitude:(CGFloat)southWestLongitude
                                                   northEastLatitude:(CGFloat)northEastLatitude
                                                  northEastLongitude:(CGFloat)northEastLongitude
                                                          projection:(GMSProjection *)projection
                                                       mapViewBounds:(CGRect)mapViewBounds
                                               displayedWithMemories:(NSArray *)displayedWithMemories {
    
    __block Memory *memory = nil;
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:CLLocationCoordinate2DMake(southWestLatitude, southWestLongitude) coordinate:CLLocationCoordinate2DMake(northEastLatitude, northEastLongitude)];
    
    NSMutableArray *displayedWithMemoryPoints = nil;
    if (displayedWithMemories) {
        displayedWithMemoryPoints = [NSMutableArray arrayWithCapacity:displayedWithMemories.count];
        for (Memory *mem in displayedWithMemories) {
            CGPoint point = [projection pointForCoordinate:CLLocationCoordinate2DMake(mem.location.latitude.floatValue, mem.location.longitude.floatValue)];
            [displayedWithMemoryPoints addObject:[NSValue valueWithCGPoint:point]];
        }
    }
    
    
    
    [self.memories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Memory * mem = obj;
        if (![[SPCExploreMemoryCache sharedInstance] getHasExploredMemory:mem]) {
            // unexplored!  Is it in the region?
            CLLocationCoordinate2D memCoordinate = CLLocationCoordinate2DMake(mem.location.latitude.doubleValue, mem.location.longitude.doubleValue);
            
            if ([bounds containsCoordinate:memCoordinate]) {
                // within the radius...
                if ([self isMemory:mem withinMapViewBounds:mapViewBounds withProjection:projection]) {
                    // Great!
                    
                    //is it the right type of mem?
                    if ((mem.type == MemoryTypeImage) || (mem.type == MemoryTypeVideo)) {
                        if (displayedWithMemoryPoints) {
                            // we want this memory to be at least 50 points away from existing memories.
                            // otherwise, we will pick the furthest one, defined as greatest MINIMUM distance.
                            CGPoint memPoint = [projection pointForCoordinate:CLLocationCoordinate2DMake(mem.location.latitude.floatValue, mem.location.longitude.floatValue)];
                            CGFloat minDistance = -1;
                            for (NSValue *pointValue in displayedWithMemoryPoints) {
                                CGPoint point = [pointValue CGPointValue];
                                CGFloat distance = MAX(ABS(point.x - memPoint.x), ABS(point.y - memPoint.y));
                                if (minDistance == -1 || minDistance > distance) {
                                    minDistance = distance;
                                }
                            }
                            if (minDistance > 50 || minDistance == -1) {
                                memory = mem;
                                *stop = YES;
                            }
                        } else {
                            memory = mem;
                            *stop = YES;
                        }
                    }
                }
            }
        }
    }];
    
    return memory;
}

- (Memory *) getAnyMemoryForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                     southWestLongitude:(CGFloat)southWestLongitude
                                      northEastLatitude:(CGFloat)northEastLatitude
                                     northEastLongitude:(CGFloat)northEastLongitude
                                             projection:(GMSProjection *)projection
                                          mapViewBounds:(CGRect)mapViewBounds
                                  displayedWithMemories:(NSArray *)displayedWithMemories {
    
    __block Memory *memory = nil;
    __block NSDate *memoryExploredUntilDate;
    GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:CLLocationCoordinate2DMake(southWestLatitude, southWestLongitude) coordinate:CLLocationCoordinate2DMake(northEastLatitude, northEastLongitude)];
    
    NSMutableArray *displayedWithMemoryPoints = nil;
    if (displayedWithMemories) {
        displayedWithMemoryPoints = [NSMutableArray arrayWithCapacity:displayedWithMemories.count];
        for (Memory *mem in displayedWithMemories) {
            CGPoint point = [projection pointForCoordinate:CLLocationCoordinate2DMake(mem.location.latitude.floatValue, mem.location.longitude.floatValue)];
            [displayedWithMemoryPoints addObject:[NSValue valueWithCGPoint:point]];
        }
    }
    
    // among those memories that qualify, we take either the first we find
    // that has not been explored, or
    //NSLog(@"Looking for a memory out of %d, with %d already placed", self.allMemories.count, displayedWithMemoryPoints.count);
    [self.allMemories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Memory * mem = obj;
        NSDate *exploredUntil = [[SPCExploreMemoryCache sharedInstance] getExploredUntilForMemory:mem];
        // Is it in the region?

        CLLocationCoordinate2D memCoordinate = CLLocationCoordinate2DMake(mem.location.latitude.doubleValue, mem.location.longitude.doubleValue);
        
        // skip if we already have a candidate that was either not explored, or will be unexplored sooner than this one.
        if (memoryExploredUntilDate && exploredUntil && [memoryExploredUntilDate compare:exploredUntil] == NSOrderedAscending) {
            return;
        }
        
        if ([bounds containsCoordinate:memCoordinate]) {
            // within the radius...
            if ([self isMemory:mem withinMapViewBounds:mapViewBounds withProjection:projection]) {
                // Great!
                
                //is it the right type of mem?
                if ((mem.type == MemoryTypeImage) || (mem.type == MemoryTypeVideo)) {
                    BOOL isCandidate = NO;
                    if (displayedWithMemoryPoints) {
                        // we want this memory to be at least 50 points away from existing memories.
                        // otherwise, we will pick the furthest one, defined as greatest MINIMUM distance.
                        CGPoint memPoint = [projection pointForCoordinate:CLLocationCoordinate2DMake(mem.location.latitude.floatValue, mem.location.longitude.floatValue)];
                        CGFloat minDistance = -1;
                        for (NSValue *pointValue in displayedWithMemoryPoints) {
                            CGPoint point = [pointValue CGPointValue];
                            CGFloat distance = MAX(ABS(point.x - memPoint.x), ABS(point.y - memPoint.y));
                            if (minDistance == -1 || minDistance > distance) {
                                minDistance = distance;
                            }
                        }
                        isCandidate = minDistance > 60 || minDistance == -1;
                        if (isCandidate) {
                            //NSLog(@"Candidate memory is %f away from %d others (at %@)", minDistance, displayedWithMemories.count, mem.venue.displayNameTitle);
                        }
                    } else {
                        isCandidate = YES;
                        //NSLog(@"Candidate memory with no others displayed (at %@)", mem.venue.displayNameTitle);
                    }
                    
                    if (isCandidate) {
                        memory = mem;
                        memoryExploredUntilDate = exploredUntil;
                        *stop = !memoryExploredUntilDate;   // stop if unexplored
                    }
                }
            }
        }
    }];
    
    //NSLog(@"Keeping memory at %@", memory.venue.displayNameTitle);
    return memory;
}


- (BOOL) isMemory:(Memory *)memory withinMapViewBounds:(CGRect)mapViewBounds withProjection:(GMSProjection *)projection {
    if (!projection) {
        return YES;
    }
    CGPoint point = [projection pointForCoordinate:CLLocationCoordinate2DMake([memory.location.latitude floatValue], [memory.location.longitude floatValue])];
    return CGRectContainsPoint(mapViewBounds, point);
}


/*
 * Fetches a single unexplored memory that occurs in the specified region.
 * The memory fetched (if successful) will NOT be created by this user, and
 * will NOT be previously explored.
 *
 * If the completionHandler is called with 'nil', then no such memory exists
 * (but we were successful in determining that).
 *
 * If a remote fetch is required to get the memory, 'willFetchRemotelyHandler' will
 * be called; set 'cancel' to NO to prevent this.  The 'errorHandler' will be called
 * as a response.
 */
-(void) fetchUnexploredMemoryForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                         southWestLongitude:(CGFloat)southWestLongitude
                                          northEastLatitude:(CGFloat)northEastLatitude
                                         northEastLongitude:(CGFloat)northEastLongitude
                                            ignoreRateLimit:(BOOL)ignoreRateLimit
                                      displayedWithMemories:(NSArray *)memories
                               withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                          completionHandler:(void (^)(Memory *memory))completionHandler
                                               errorHandler:(void (^)(NSError *error))errorHandler {
    
    [self fetchUnexploredMemoryForRegionWithSouthWestLatitude:southWestLatitude
                                           southWestLongitude:southWestLongitude
                                            northEastLatitude:northEastLatitude
                                           northEastLongitude:northEastLongitude
                                                   projection:nil mapViewBounds:CGRectZero ignoreRateLimit:ignoreRateLimit displayedWithMemories:memories withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:completionHandler errorHandler:errorHandler];
}


/*
 * Fetches a single unexplored memory that occurs in the specified region.
 * The memory fetched (if successful) will NOT be created by this user, and
 * will NOT be previously explored.
 *
 * The memory provided will occur within the specified bounds of the map view
 * having the provided projection.
 *
 * If the completionHandler is called with 'nil', then no such memory exists
 * (but we were successful in determining that).
 *
 * If a remote fetch is required to get the memory, 'willFetchRemotelyHandler' will
 * be called; set 'cancel' to NO to prevent this.  The 'errorHandler' will be called
 * as a response.
 */
-(void) fetchUnexploredMemoryForRegionWithProjection:(GMSProjection *)projection
                                       mapViewBounds:(CGRect)mapViewBounds
                                     ignoreRateLimit:(BOOL)ignoreRateLimit
                               displayedWithMemories:(NSArray *)memories
                        withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                   completionHandler:(void (^)(Memory *memory))completionHandler
                                        errorHandler:(void (^)(NSError *error))errorHandler {
    
    [self fetchMemoryForRegionWithProjection:projection mapViewBounds:mapViewBounds ignoreRateLimit:ignoreRateLimit mustBeNew:YES displayedWithMemories:memories withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:completionHandler errorHandler:errorHandler];
}


-(void) fetchAnyMemoryForRegionWithProjection:(GMSProjection *)projection
                               mapViewBounds:(CGRect)mapViewBounds
                             ignoreRateLimit:(BOOL)ignoreRateLimit
                        displayedWithMemories:(NSArray *)memories
                withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                           completionHandler:(void (^)(Memory *memory))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler {
    
    [self fetchMemoryForRegionWithProjection:projection mapViewBounds:mapViewBounds ignoreRateLimit:ignoreRateLimit mustBeNew:NO displayedWithMemories:memories withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:completionHandler errorHandler:errorHandler];
}

-(void) fetchMemoryForRegionWithProjection:(GMSProjection *)projection
                             mapViewBounds:(CGRect)mapViewBounds
                           ignoreRateLimit:(BOOL)ignoreRateLimit
                                 mustBeNew:(BOOL)mustBeNew
                     displayedWithMemories:(NSArray *)memories
              withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                         completionHandler:(void (^)(Memory *memory))completionHandler
                              errorHandler:(void (^)(NSError *error))errorHandler {
    
    CGPoint bottomLeft = CGPointMake(CGRectGetMinX(mapViewBounds), CGRectGetMaxY(mapViewBounds));
    CGPoint topRight = CGPointMake(CGRectGetMaxX(mapViewBounds), CGRectGetMinY(mapViewBounds));
    
    CLLocationCoordinate2D southWest = [projection coordinateForPoint:bottomLeft];
    CLLocationCoordinate2D northEast = [projection coordinateForPoint:topRight];
    
    [self fetchMemoryForRegionWithSouthWestLatitude:southWest.latitude
                                 southWestLongitude:southWest.longitude
                                  northEastLatitude:northEast.latitude
                                 northEastLongitude:northEast.longitude projection:projection mapViewBounds:mapViewBounds ignoreRateLimit:ignoreRateLimit mustBeNew:mustBeNew displayedWithMemories:memories withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:completionHandler errorHandler:errorHandler];
}


/*
 * Determines if the provided memory meets the requirements for display used
 * in 'fetchUnexploredMemoryForRegionWithProjection'.  Does NOT determine whether
 * the memory is unexplored; only does a location analysis.
 *
 * Example use case: determine if a memory already placed on the map is still visible.
 * If not, you might want to quickly replace it with a new memory.
 */
-(BOOL) isMemory:(Memory *)memory
inRegionWithProjection:(GMSProjection *)projection
   mapViewBounds:(CGRect)mapViewBounds {
    
    return [self isMemory:memory withinMapViewBounds:mapViewBounds withProjection:projection];
}


/*
 * Fetches a single unexplored memory that occurs in the specified region.
 * The memory fetched (if successful) will NOT be created by this user, and
 * will NOT be previously explored.
 *
 * The memory provided will occur within the specified bounds of the map view
 * having the provided projection.
 *
 * If the completionHandler is called with 'nil', then no such memory exists
 * (but we were successful in determining that).
 *
 * If a remote fetch is required to get the memory, 'willFetchRemotelyHandler' will
 * be called; set 'cancel' to NO to prevent this.  The 'errorHandler' will be called
 * as a response.
 */
-(void) fetchUnexploredMemoryForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                         southWestLongitude:(CGFloat)southWestLongitude
                                          northEastLatitude:(CGFloat)northEastLatitude
                                         northEastLongitude:(CGFloat)northEastLongitude
                                                 projection:(GMSProjection *)projection
                                              mapViewBounds:(CGRect)mapViewBounds
                                            ignoreRateLimit:(BOOL)ignoreRateLimit
                                      displayedWithMemories:(NSArray *)memories
                               withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                          completionHandler:(void (^)(Memory *memory))completionHandler
                                               errorHandler:(void (^)(NSError *error))errorHandler {
    
    [self fetchMemoryForRegionWithSouthWestLatitude:southWestLatitude
                                 southWestLongitude:southWestLongitude
                                  northEastLatitude:northEastLatitude
                                 northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds ignoreRateLimit:ignoreRateLimit mustBeNew:YES displayedWithMemories:memories withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:completionHandler errorHandler:errorHandler];
}


/*
 * Fetches a memory that occurs in the specified region.
 
 * If mustBeNew is true
 * The memory fetched (if successful) will NOT be created by this user, and
 * will NOT be previously explored.
 *
 * If mustBeNew is not true, we will take any memory in the region that we have
 *
 */

-(void) fetchMemoryForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                               southWestLongitude:(CGFloat)southWestLongitude
                                northEastLatitude:(CGFloat)northEastLatitude
                               northEastLongitude:(CGFloat)northEastLongitude
                                        projection:(GMSProjection *)projection
                                     mapViewBounds:(CGRect)mapViewBounds
                                   ignoreRateLimit:(BOOL)ignoreRateLimit
                                        mustBeNew:(BOOL)mustBeNew
                            displayedWithMemories:(NSArray *)memories
                      withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                 completionHandler:(void (^)(Memory *memory))completionHandler
                                      errorHandler:(void (^)(NSError *error))errorHandler {
    
    //NSLog(@"fetching from %@", [NSThread callStackSymbols]);
    
    // First attempt: find an unexplored memory in our cache w/in this region.
    // Only do this if we are within the EMERGENCY_RECACHE coverage bounds.
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    Memory * memory = nil;
    CGFloat coverage = [self proportionCoveredByCacheOfRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude];
    BOOL emergency = coverage < RECACHE_REGION_COVERAGE_EMERGENCY_MAXIMUM;
    if (!emergency) {
        if (mustBeNew) {
            memory = [self getCachedUnexploredMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
        } else {
            memory = [self getAnyMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
        }
        if (memory) {
            // Maybe fetch a new cache?  Maybe fetch a new page preemptively?
            if (self.nextPageKey && self.lastQueryTime + CACHE_PAGE_QUERY_LIMIT < now && self.cachedMemories.count < MAXIMUM_CACHE_SIZE) {
                NSLog(@"fetching another cache page");
                // we have another page to fetch...
                [self fetchNextPageCacheWithWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:nil errorHandler:nil];
            }
            // easy!
            completionHandler(memory);
            return;
        }
    }
    
    // This might be a completely new area, with our cached results being irrelevant.  Check that.
    if (!emergency && [self hasCachedResultsForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude]) {
        // hrm.  We have a cache, but no memory is appropriate.  Maybe it's time to
        // start our whole query over from scratch?  Or maybe it's time to try expanding?
        
        if (self.nextPageKey && self.lastQueryTime + CACHE_PAGE_QUERY_LIMIT < now && self.cachedMemories.count < MAXIMUM_CACHE_SIZE) {
            NSLog(@"fetching another cache page");
            // we have another page to fetch...
            [self fetchNextPageCacheWithWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:^(NSInteger numMemories) {
                if (completionHandler) {
                    Memory *memory = nil;
                    if (mustBeNew) {
                        memory = [self getCachedUnexploredMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
                    } else {
                        memory = [self getAnyMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
                    }
                    completionHandler(memory);
                }
            } errorHandler:errorHandler];
        } else {
            BOOL immediateRecache = self.firstQueryTime + CACHE_REFRESH_AFTER < now && self.lastQueryTime + CACHE_REPLACE_RATE_LIMIT < now;
            if (immediateRecache) {
                // entirely new!  Start over.  Fresh cache.
                NSLog(@"must fetch fresh cache!");
                [self fetchFreshCacheWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:^(NSInteger numFetched) {
                    if (completionHandler) {
                        Memory *memory = nil;
                        if (mustBeNew) {
                            memory = [self getCachedUnexploredMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
                        } else {
                            memory = [self getAnyMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
                        }
                        completionHandler(memory);
                    }
                } errorHandler:errorHandler];
            }
            else {
                if (completionHandler) {
                    completionHandler(nil);
                }
            }
        }
    } else if (ignoreRateLimit || self.firstQueryTime + CACHE_REPLACE_RATE_LIMIT < [[NSDate date] timeIntervalSince1970]) {
        // entirely new!  Start over.  Fresh cache.
        [self clearImpermanent];
        NSLog(@"must fetch fresh cache!");
        [self fetchFreshCacheWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude withWillFetchRemotelyHandler:willFetchRemotelyHandler completionHandler:^(NSInteger numFetched) {
            // Might be nil, might not be, we don't care.  Send it.
            if (completionHandler) {
                Memory *memory = nil;
                if (mustBeNew) {
                    memory = [self getCachedUnexploredMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
                } else {
                    memory = [self getAnyMemoryForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude projection:projection mapViewBounds:mapViewBounds displayedWithMemories:memories];
                }
                completionHandler(memory);
            }
        } errorHandler:errorHandler];
    } else {
        // we'd LIKE to replace the cache completely, but we've been rate-limited.
        NSLog(@"rate-limited: no new cache");
        if (completionHandler) {
            completionHandler(nil);
        }
    }
}


-(void) fetchFreshCacheWithSouthWestLatitude:(CGFloat)southWestLatitude
                          southWestLongitude:(CGFloat)southWestLongitude
                           northEastLatitude:(CGFloat)northEastLatitude
                          northEastLongitude:(CGFloat)northEastLongitude
       withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                  completionHandler:(void (^)(NSInteger numMemories))completionHandler
                       errorHandler:(void (^)(NSError *error))errorHandler {
    
    if (self.freshQueryInProgress) {
        if (errorHandler) {
            errorHandler(nil);
        }
        return;
    }
    
    // To reduce cache misses, we actually expand this area slightly.
    // Don't tell anyone!
    
    CGFloat latitudeSpan = northEastLatitude - southWestLatitude;
    CGFloat longitudeSpan = northEastLongitude - southWestLongitude;
    if (longitudeSpan < 0) {
        longitudeSpan += 360;
    }
    // expand by 0.1 in each direction.
    CGFloat ONE_EIGHTY = 180;
    CGFloat NINETY = 90;
    southWestLatitude = MAX(-NINETY, southWestLatitude - latitudeSpan * 0.1);
    northEastLatitude = MIN(NINETY, northEastLatitude + latitudeSpan * 0.1);
    southWestLongitude -= longitudeSpan * 0.1;
    northEastLongitude += longitudeSpan * 0.1;
    if (southWestLongitude < -ONE_EIGHTY) {
        southWestLongitude += 360;
    }
    if (northEastLongitude > ONE_EIGHTY) {
        northEastLongitude -= 360;
    }
    
    BOOL cancel = NO;
    if (willFetchRemotelyHandler) {
        willFetchRemotelyHandler(&cancel);
        if (cancel) {
            if (errorHandler) {
                errorHandler(nil);
            }
            return;
        }
    }
    
    self.regionNumber++;
    NSInteger regionNumberHere = self.regionNumber;
    self.freshQueryInProgress = YES;
    __weak SPCRegionMemoriesManager * weakSelf = self;
    [MeetManager fetchRegionMemoriesWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude pageKey:nil withCompletionHandler:^(NSArray *memories, NSString *nextPageKey) {
        __strong SPCRegionMemoriesManager * strongSelf = weakSelf;
        strongSelf.freshQueryInProgress = NO;
        strongSelf.pageQueryInProgress = NO;
        if (regionNumberHere == strongSelf.regionNumber) {
            [strongSelf setCacheMemories:memories forRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude nextPageKey:nextPageKey];
            if (completionHandler) {
                completionHandler(memories.count);
            }
            // fetch a new page IMMEDIATELY
            if (strongSelf.nextPageKey) {
                [self fetchNextPageCacheWithWillFetchRemotelyHandler:nil completionHandler:nil errorHandler:nil];
            }
        } else if (completionHandler) {
            completionHandler(0);
        }
    } errorHandler:^(NSError *error) {
        __strong SPCRegionMemoriesManager * strongSelf = weakSelf;
        strongSelf.freshQueryInProgress = NO;
        strongSelf.pageQueryInProgress = NO;
        if (errorHandler) {
            errorHandler(error);
        }
    }];
}

- (void)fetchNextPageCacheWithWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                     completionHandler:(void (^)(NSInteger numMemories))completionHandler
                                          errorHandler:(void (^)(NSError *error))errorHandler {
    NSInteger regionNumberHere = self.regionNumber;
    if (!self.nextPageKey || self.pageQueryInProgress || self.freshQueryInProgress) {
        // no
        if (errorHandler) {
            errorHandler(nil);
        }
        return;
    }
    
    BOOL cancel = NO;
    if (willFetchRemotelyHandler) {
        willFetchRemotelyHandler(&cancel);
        if (cancel) {
            if (errorHandler) {
                errorHandler(nil);
            }
            return;
        }
    }
    
    self.pageQueryInProgress = YES;
    __weak SPCRegionMemoriesManager * weakSelf = self;
    [MeetManager fetchRegionMemoriesWithSouthWestLatitude:self.southWestLatitude southWestLongitude:self.southWestLongitude northEastLatitude:self.northEastLatitude northEastLongitude:self.northEastLongitude pageKey:self.nextPageKey withCompletionHandler:^(NSArray *memories, NSString *nextPageKey) {
        __strong SPCRegionMemoriesManager * strongSelf = weakSelf;
        if (regionNumberHere == strongSelf.regionNumber) {
            // if the region number has been incremented, we have already set 'pageQueryInProgress' to NO.
            strongSelf.pageQueryInProgress = NO;
            [strongSelf expandCacheMemories:memories withNextPageKey:nextPageKey];
            if (completionHandler) {
                completionHandler(memories.count);
            }
        } else if (completionHandler) {
            completionHandler(0);
        }
    } errorHandler:^(NSError *error) {
        __strong SPCRegionMemoriesManager * strongSelf = weakSelf;
        strongSelf.pageQueryInProgress = NO;
        if (errorHandler) {
            errorHandler(error);
        }
    }];
}


/*
 * Informs the manager that the provided memory has been explored.  It will not
 * be returned as a result in future 'fetchUnexploredMemoryForRegion' calls.
 * Behavior is unspecified if two different threads attempt the two calls
 * simultaneously.
 */
- (void)setHasExploredMemory:(Memory *)memory explored:(BOOL)explored withDuration:(NSTimeInterval)duration {
    [[SPCExploreMemoryCache sharedInstance] setHasExploredMemory:memory explored:explored withDuration:duration writeToFile:NO];
    // record that we displayed this memory (dispatch to a background thread;
    // this operation performs file I/O)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // This code runs on a background thread
        [[SPCExploreMemoryCache sharedInstance] writeToFile] ;
    });
    
    
}


/*
 * Caches the memories for the specified region using a query to the server.
 * This method will be automatically called as a response to 'fetchUnexplored...',
 * but only if no memories are available.  Calling this method periodically will
 * re-cache memories for possibly fresh results.  This method may be safely
 * called periodically for the same region; if no new memories need to be cached,
 * no remote fetch will be performed (based on distance traveled and time elapsed).
 */
- (void) cacheMemoriesForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                  southWestLongitude:(CGFloat)southWestLongitude
                                   northEastLatitude:(CGFloat)northEastLatitude
                                  northEastLongitude:(CGFloat)northEastLongitude
                          completionHandler:(void (^)(NSInteger memoriesCached))completionHandler
                               errorHandler:(void (^)(NSError *error))errorHandler {
    
    if (![self hasCachedResultsForRegionWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude] || self.firstQueryTime + CACHE_REFRESH_AFTER < [[NSDate date] timeIntervalSince1970]) {
        [self fetchFreshCacheWithSouthWestLatitude:southWestLatitude southWestLongitude:southWestLongitude northEastLatitude:northEastLatitude northEastLongitude:northEastLongitude withWillFetchRemotelyHandler:nil completionHandler:completionHandler errorHandler:errorHandler];
    }
    
}


/*
 * Caches the memories for the specified region using a query to the server.
 * This method will be automatically called as a response to 'fetchUnexplored...',
 * but only if no memories are available.  Calling this method periodically will
 * re-cache memories for possibly fresh results.  This method may be safely
 * called periodically for the same region; if no new memories need to be cached,
 * no remote fetch will be performed (based on distance traveled and time elapsed).
 */
- (void) cacheMemoriesForRegionWithProjection:(GMSProjection *)projection
                                mapViewBounds:(CGRect)mapViewBounds
                            completionHandler:(void (^)(NSInteger memoriesCached))completionHandler
                                 errorHandler:(void (^)(NSError *error))errorHandler {
    
    CGPoint bottomLeft = CGPointMake(CGRectGetMinX(mapViewBounds), CGRectGetMaxY(mapViewBounds));
    CGPoint topRight = CGPointMake(CGRectGetMaxX(mapViewBounds), CGRectGetMinY(mapViewBounds));
    
    CLLocationCoordinate2D southWest = [projection coordinateForPoint:bottomLeft];
    CLLocationCoordinate2D northEast = [projection coordinateForPoint:topRight];
    
    [self cacheMemoriesForRegionWithSouthWestLatitude:southWest.latitude southWestLongitude:southWest.longitude northEastLatitude:northEast.latitude northEastLongitude:northEast.longitude completionHandler:completionHandler errorHandler:errorHandler];
}


/*
 * Sets the "permanent" memories that will always be available to this manager,
 * regardless of whether new regions are requested.
 */
- (void)setOutsideMemories:(NSArray *)memories {
    self.permanentMemories = memories;
    [self rebuildCache];
}

/*
 * Adds to the existing set of "permanent" memories that will always be available
 * to this manager, regardless of whether new regions are requested.
 */
- (void)addOutsideMemories:(NSArray *)memories {
    if (memories) {
        self.permanentMemories = [self memoriesByCombiningArray:self.permanentMemories withArray:memories];
        [self rebuildCache];
    }
}


@end
