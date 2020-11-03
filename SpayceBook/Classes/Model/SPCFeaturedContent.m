//
//  SPCFeaturedContent.m
//  Spayce
//
//  Created by Jake Rosin on 8/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeaturedContent.h"

// Model
#import "Memory.h"
#import "Venue.h"

// Utility
#import "TranslationUtils.h"
#import "MeetManager.h"

@interface SPCFeaturedContent()

@property (nonatomic, assign) FeaturedContentType contentType;
@property (nonatomic, strong) Memory *memory;
@property (nonatomic, strong) Venue *venue;

@end

@implementation SPCFeaturedContent

-(instancetype)initWithAttributes:(NSDictionary *)attributes {
    self = [super init];
    if (self) {
        // parse the content type
        NSString *typeStr = (NSString *)[TranslationUtils valueOrNil:attributes[@"type"]];
        if ([typeStr isEqualToString:@"POPULAR_MEMORY_HERE"]) {
            self.contentType = FeaturedContentPopularMemoryHere;
        } else if ([typeStr isEqualToString:@"NEARBY_VENUE"]) {
            self.contentType = FeaturedContentVenueNearby;
        } else {
            self.contentType = FeaturedContentFeaturedMemory;
        }
        
        NSDictionary *memoryDict;
        switch (self.contentType) {
            case FeaturedContentFeaturedMemory:
            case FeaturedContentPopularMemoryHere:
                memoryDict = attributes[@"memory"];
                self.memory = [Memory memoryWithAttributes:memoryDict];
                self.venue = self.memory.venue;
                break;
            case FeaturedContentVenueNearby:
                self.venue = [[Venue alloc] initWithAttributes:(NSDictionary *)attributes[@"venue"]];
                if (self.venue.popularMemories.count > 0) {
                    self.memory = self.venue.popularMemories[0];
                }
                break;
            case FeaturedContentText:
                break;
            case FeaturedContentPlaceholder:
                break;
        }
    }
    return self;
}


-(instancetype)initWithPopularMemoryHere:(Memory *)memory {
    self = [super init];
    if (self) {
        self.contentType = FeaturedContentPopularMemoryHere;
        self.memory = memory;
        self.venue = memory.venue;
    }
    return self;
}

-(instancetype)initWithFeaturedMemory:(Memory *)memory {
    self = [super init];
    if (self) {
        self.contentType = FeaturedContentFeaturedMemory;
        self.memory = memory;
        self.venue = memory.venue;
    }
    return self;
}

-(instancetype)initWithVenueNearby:(Venue *)venue {
    self = [super init];
    if (self) {
        self.contentType = FeaturedContentVenueNearby;
    }
    return self;
}

-(instancetype)initPlaceholderForVenue:(Venue *)venue; {
    self = [super init];
    if (self) {
        self.contentType = FeaturedContentPlaceholder;
        self.venue = venue;
    }
    return self;
}

-(instancetype)initUnknownContentForVenue:(Venue *)venue {
    self = [super init];
    if (self) {
        self.contentType = FeaturedContentPlaceholder;
        if (self.memory && self.memory.type == MemoryTypeText) {
            self.contentType = FeaturedContentText;
        }
        if (self.memory && self.memory.type == MemoryTypeVideo) {
            self.contentType = FeaturedContentPopularMemoryHere;
        }
        self.venue = venue;
        if (!self.memory) {
            self.contentType = FeaturedContentPlaceholder;
            [self retrieveVenMem];
        }

    }
    return self;
}

-(void)retrieveVenMem {
    
    //TODO GET THIS WITH THE NEARBY VENUES??
    
    [MeetManager fetchLocationMemoriesFeedForVenue:self.venue
                            includeFeaturedContent:NO
                             withCompletionHandler:^(NSArray *memories, NSArray *featuredContent, NSArray *venueHashTags) {

                                 BOOL foundMem = NO;
                                 
                                 NSMutableArray *tempArray = [NSMutableArray arrayWithArray:memories];
                                 NSSortDescriptor *starSorter = [[NSSortDescriptor alloc] initWithKey:@"starsCount" ascending:NO];
                                 [tempArray sortUsingDescriptors:@[starSorter]];
                                 NSArray *sortedArray = [NSArray arrayWithArray:tempArray];
                                 
                                 
                                 for (int i = 0; i < sortedArray.count; i++) {
                                     Memory *tempMem = (Memory *)memories[i];
                                     if (tempMem.accessType == MemoryAccessTypePublic) {
                                         if (tempMem.type == MemoryTypeText) {
                                            self.memory = memories[i];
                                            self.contentType = FeaturedContentText;
                                            foundMem = YES;
                                            break;
                                         }
                                         if (tempMem.type == MemoryTypeVideo) {
                                             self.memory = memories[i];
                                             self.contentType = FeaturedContentPopularMemoryHere;
                                             break;
                                         }
                                     }
                                 }
                                 
                                 //update cells as needed in featured content scroller
                                 [[NSNotificationCenter defaultCenter] postNotificationName:@"venueContentFetched" object:self.venue];
                                
                                 
                             } errorHandler:^(NSError *errror){
                                 self.contentType = FeaturedContentPlaceholder;
                            }];
}

-(void)updateContentWithMemory:(Memory *)memory {
    
    //only update the featured content if it was a placeholder previously
    if (self.contentType == FeaturedContentPlaceholder) {
    
        self.memory = memory;
        
        if (memory.type == MemoryTypeImage || memory.type == MemoryTypeVideo) {
            self.contentType = FeaturedContentPopularMemoryHere;
        }
        else if (memory.type == MemoryTypeText) {
            self.contentType = FeaturedContentText;
        }
    }
}

-(instancetype)initTextContentForMemory:(Memory *)memory {
    self = [super init];
    if (self) {
        self.contentType = FeaturedContentText;
        self.venue = memory.venue;
        self.memory = memory;
    }
    return self;
}

@end
