//
//  SPCExploreMemoryCache.m
//  Spayce
//
//  Created by Jake Rosin on 6/26/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCExploreMemoryCache.h"

// Model
#import "Memory.h"
#import "User.h"

// Manager
#import "AuthenticationManager.h"

NSString *ExploredMemoryCacheFileName = @"explored_memory_cache_file_list.plist";

@interface SPCExploreMemoryCache()

// Format: an array of arrays, with each inner element being
// [memoryId, creationTime].
@property (nonatomic, strong) NSMutableArray *exploredMemories;

@end

@implementation SPCExploreMemoryCache

SINGLETON_GCD(SPCExploreMemoryCache);

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

- (void)handleAuthenticationSuccess:(NSNotification *)notification {
    _exploredMemories = nil;
}

- (void)handleLogout:(NSNotification *)notification {
    _exploredMemories = nil;
}

- (NSMutableArray *) exploredMemories {
    if (!_exploredMemories) {
        // TODO: remove 'false' when done testing
        // load memories from file
        NSArray * mems = [self loadPersistedExploredMemories];
        if (mems) {
            // remove any memories whose 'explored time' has expired
            NSDate *now = [NSDate date];
            BOOL altered = NO;
            NSMutableArray * mutArray = [[NSMutableArray alloc] initWithCapacity:mems.count];
            for (int i = 0; i < mems.count; i++) {
                NSDate * expireAt = mems[i][2];
                if ([now compare:expireAt] == NSOrderedAscending) {
                    [mutArray addObject:mems[i]];
                } else {
                    altered = YES;
                }
            }
            // re-save to file
            if (altered) {
                [self persistExploredMemories:mutArray];
            }
            _exploredMemories = mutArray;
        } else {
            _exploredMemories = [[NSMutableArray alloc] init];
        }
    }
    return _exploredMemories;
}

- (void)setHasExploredMemory:(Memory *)memory explored:(BOOL)explored withDuration:(NSTimeInterval)duration writeToFile:(BOOL)writeToFile {
    @synchronized (self.exploredMemories) {
        if (explored) {
            NSDate *exploredUntil = [NSDate dateWithTimeIntervalSinceNow:duration];
            NSArray *mem = @[@(memory.recordID), memory.dateCreated, exploredUntil];
            // make sure it isn't already there...
            BOOL found = NO;
            for (int i = 0; i < self.exploredMemories.count && !found; i++) {
                NSArray * memInPlace = self.exploredMemories[i];
                if ([memInPlace[0] integerValue] == memory.recordID) {
                    found = YES;
                    if ([((NSDate *)memInPlace[2]) compare:exploredUntil] == NSOrderedAscending) {
                        self.exploredMemories[i] = mem;
                    }
                }
            }
            if (!found) {
                [self.exploredMemories addObject:mem];
            }
        } else {
            for (int i = 0; i < self.exploredMemories.count; i++) {
                NSArray * mem = self.exploredMemories[i];
                if ([mem[0] integerValue] == memory.recordID) {
                    [self.exploredMemories removeObjectAtIndex:i];
                    break;
                }
            }
        }
    }
    
    if (writeToFile) {
        [self writeToFile];
    }
}

- (void) writeToFile {
    // Save changes to file
    NSArray * toStore;
    @synchronized(self.exploredMemories) {
        toStore = [NSArray arrayWithArray:self.exploredMemories];
    }
    [self persistExploredMemories:toStore];
}

- (BOOL)getHasExploredMemory:(Memory *)memory {
    if (!memory) {
        return NO;
    }
    
    @synchronized (self.exploredMemories) {
        for (int i = 0; i < self.exploredMemories.count; i++) {
            NSArray * mem = self.exploredMemories[i];
            if ([mem[0] integerValue] == memory.recordID) {
                return [[NSDate date] compare:mem[2]] == NSOrderedAscending;
            }
        }
    }
    return NO;
}

- (NSDate *)getExploredUntilForMemory:(Memory *)memory {
    if (!memory) {
        return nil;
    }
    
    @synchronized (self.exploredMemories) {
        for (int i = 0; i < self.exploredMemories.count; i++) {
            NSArray * mem = self.exploredMemories[i];
            if ([mem[0] integerValue] == memory.recordID) {
                return [[NSDate date] compare:mem[2]] == NSOrderedAscending ? mem[2] : nil;
            }
        }
    }
    return nil;
}

- (NSArray *)unexploredMemoriesFromMemories:(NSArray *)memories {
    NSArray *explored = self.exploredMemories;
    if (!explored) {
        return memories;
    }
    NSMutableArray * unexploredMemories = [[NSMutableArray alloc] initWithCapacity:memories.count];
    @synchronized(explored) {
        for (int i = 0; i < memories.count; i++) {
            // "getHasExploredMemory" returns a BOOL indicating whether the
            // provided memory has been explored (when this values is set,
            // a duration is provided; the method call checks both whether we
            // have set the memory as explored and whether the duration is expired).
            BOOL contained = [self getHasExploredMemory:memories[i]];
            if (!contained) {
                [unexploredMemories addObject:memories[i]];
            }
        }
    }
    return [NSArray arrayWithArray:unexploredMemories];
}


#pragma mark - Persist explored memories

// To clear the persisted memory cache, add 1 to PERSISTED_FORMAT
// Format history:
// 0: Format #, persistent memories, and current user ID are stored under their own keys.
//          persisent memories have format:
//              [ NSNumber (recordID)
//                NSDate (creationTime)
//                NSDate (explored record expires at)
//              ]

#define PERSISTED_FORMAT 0
#define PERSISTED_FORMAT_KEY @"PERSISTED_FORMAT"
#define PERSISTED_MEMORIES_USER_ID_KEY @"PERSISTED_MEMORIES_USER_ID_KEY"
#define PERSISTED_MEMORIES_KEY @"PERSISTED_MEMORIES"

- (NSArray *)loadPersistedExploredMemories
{
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:[self filePath]];
    
    if (codedData != nil) {
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
        NSNumber *format = [unarchiver decodeObjectForKey:PERSISTED_FORMAT_KEY];
        NSNumber *userId = [unarchiver decodeObjectForKey:PERSISTED_MEMORIES_USER_ID_KEY];
        if (!format || [format intValue] != PERSISTED_FORMAT || !userId || [userId intValue] != [AuthenticationManager sharedInstance].currentUser.userId) {
            NSLog(@"Coded data doesn't match, with format %@ and userId %@", format, userId);
            // clear the persisted cache.  Our format has changed, or
            // some other event requires us to delete the existing cache.
            [self persistExploredMemories:nil];
            return nil;
        }
        NSArray *res =  (NSArray *)[unarchiver decodeObjectForKey:PERSISTED_MEMORIES_KEY];
        [unarchiver finishDecoding];
        
        return res;
    }
    else {
        return nil;
    }
}

- (void)persistExploredMemories:(NSArray *)exploredMemoriesToPersist
{
    if (exploredMemoriesToPersist == nil)
    {
        NSString *filePath = [self filePath];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL exists = [fm fileExistsAtPath:filePath];
        
        if (exists) {
            NSLog(@"delete stored explored memories!");
            NSError *err = nil;
            [fm removeItemAtPath:filePath error:&err];
            NSLog(@"clear active copy of explored memories!");
            _exploredMemories = nil;
        }
    }
    else {
        NSMutableData *archivedData = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archivedData];
        [archiver encodeObject:@PERSISTED_FORMAT forKey:PERSISTED_FORMAT_KEY];
        [archiver encodeObject:@([AuthenticationManager sharedInstance].currentUser.userId) forKey:PERSISTED_MEMORIES_USER_ID_KEY];
        [archiver encodeObject:exploredMemoriesToPersist forKey:PERSISTED_MEMORIES_KEY];
        [archiver finishEncoding];
        [archivedData writeToFile:[self filePath] atomically:YES];
    }
}

- (NSString *)filePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    
    return [documentsDirectory stringByAppendingPathComponent:ExploredMemoryCacheFileName];
}


@end
