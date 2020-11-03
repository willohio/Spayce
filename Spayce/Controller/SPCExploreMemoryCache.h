//
//  SPCExploreMemoryCache.h
//  Spayce
//
//  Created by Jake Rosin on 6/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"

@class Memory;

@interface SPCExploreMemoryCache : NSObject

+ (SPCExploreMemoryCache *)sharedInstance;

- (void)setHasExploredMemory:(Memory *)memory explored:(BOOL)explored withDuration:(NSTimeInterval)duration writeToFile:(BOOL)writeToFile;
- (void)writeToFile;
- (BOOL)getHasExploredMemory:(Memory *)memory;
- (NSDate *)getExploredUntilForMemory:(Memory *)memory;

- (NSArray *)unexploredMemoriesFromMemories:(NSArray *)memories;

@end
