//
//  SPCRegionMemoriesManager.h
//  Spayce
//
//  Created by Jake Rosin on 7/11/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>
#import "Memory.h"

@interface SPCRegionMemoriesManager : NSObject

+(SPCRegionMemoriesManager *)sharedInstance;


-(void) fetchAnyMemoryForRegionWithProjection:(GMSProjection *)projection
                               mapViewBounds:(CGRect)mapViewBounds
                             ignoreRateLimit:(BOOL)ignoreRateLimit
                       displayedWithMemories:(NSArray *)memories
                withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                           completionHandler:(void (^)(Memory *memory))completionHandler
                                errorHandler:(void (^)(NSError *error))errorHandler;

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
 * as a response.  At least one callback will be made on the caller's thread, before
 * this method returns.
 */
-(void) fetchUnexploredMemoryForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                         southWestLongitude:(CGFloat)southWestLongitude
                                          northEastLatitude:(CGFloat)northEastLatitude
                                         northEastLongitude:(CGFloat)northEastLongitude
                                            ignoreRateLimit:(BOOL)ignoreRateLimit
                                      displayedWithMemories:(NSArray *)memories
                               withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                          completionHandler:(void (^)(Memory *memory))completionHandler
                                               errorHandler:(void (^)(NSError *error))errorHandler;


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
 * as a response.  At least one callback will be made on the caller's thread, before
 * this method returns.
 */
-(void) fetchUnexploredMemoryForRegionWithProjection:(GMSProjection *)projection
                                     mapViewBounds:(CGRect)mapViewBounds
                                     ignoreRateLimit:(BOOL)ignoreRateLimit
                               displayedWithMemories:(NSArray *)memories
                      withWillFetchRemotelyHandler:(void (^)(BOOL *cancel))willFetchRemotelyHandler
                                 completionHandler:(void (^)(Memory *memory))completionHandler
                                      errorHandler:(void (^)(NSError *error))errorHandler;



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
   mapViewBounds:(CGRect)mapViewBounds;



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
 * as a response.  At least one callback will be made on the caller's thread, before
 * this method returns.
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
                                               errorHandler:(void (^)(NSError *error))errorHandler;


/*
 * Informs the manager that the provided memory has been explored.  It will not
 * be returned as a result in future 'fetchUnexploredMemoryForRegion' calls.
 * Behavior is unspecified if two different threads attempt the two calls
 * simultaneously.
 */
- (void)setHasExploredMemory:(Memory *)memory explored:(BOOL)explored withDuration:(NSTimeInterval)duration;


/*
 * Caches the memories for the specified region using a query to the server.
 * This method will be automatically called as a response to 'fetchUnexplored...',
 * but only if no memories are available.  Calling this method periodically will
 * re-cache memories for possibly fresh results.  This method may be safely
 * called periodically for the same region; if no new memories need to be cached,
 * no remote fetch will be performed (based on distance traveled and time elapsed).
 */
- (void)cacheMemoriesForRegionWithSouthWestLatitude:(CGFloat)southWestLatitude
                                 southWestLongitude:(CGFloat)southWestLongitude
                                  northEastLatitude:(CGFloat)northEastLatitude
                                 northEastLongitude:(CGFloat)northEastLongitude
                                  completionHandler:(void (^)(NSInteger memoriesCached))completionHandler
                                       errorHandler:(void (^)(NSError *error))errorHandler;

/*
 * Caches the memories for the specified region using a query to the server.
 * This method will be automatically called as a response to 'fetchUnexplored...',
 * but only if no memories are available.  Calling this method periodically will
 * re-cache memories for possibly fresh results.  This method may be safely
 * called periodically for the same region; if no new memories need to be cached,
 * no remote fetch will be performed (based on distance traveled and time elapsed).
 */
- (void)cacheMemoriesForRegionWithProjection:(GMSProjection *)projection
                                mapViewBounds:(CGRect)mapViewBounds
                            completionHandler:(void (^)(NSInteger memoriesCached))completionHandler
                                 errorHandler:(void (^)(NSError *error))errorHandler;


/*
 * Sets the "permanent" memories that will always be available to this manager,
 * regardless of whether new regions are requested.
 */
- (void)setOutsideMemories:(NSArray *)memories;

/*
 * Adds to the existing set of "permanent" memories that will always be available
 * to this manager, regardless of whether new regions are requested.
 */
- (void)addOutsideMemories:(NSArray *)memories;

@end
