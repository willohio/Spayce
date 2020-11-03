//
//  SPCFeaturedContent.h
//  Spayce
//
//  Created by Jake Rosin on 8/16/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//
//  "Featured Content" is a wrapper for some other Model object,
//  along with an enum indicating the type of content being featured.
//  This content is (e.g.) displayed as a horizontally scrollable section
//  of the Spayce screen, between the venue map and memories.

#import <Foundation/Foundation.h>
@class Memory;
@class Venue;

typedef NS_ENUM(NSInteger, FeaturedContentType) {
    FeaturedContentPopularMemoryHere,
    FeaturedContentFeaturedMemory,
    FeaturedContentVenueNearby,
    FeaturedContentText,
    FeaturedContentPlaceholder
};

@interface SPCFeaturedContent : NSObject

@property (nonatomic, readonly) FeaturedContentType contentType;
@property (nonatomic, readonly) Memory *memory;
@property (nonatomic, readonly) Venue *venue;

@property (nonatomic, assign) CGFloat distance;

-(instancetype)initWithAttributes:(NSDictionary *)attributes;
-(instancetype)initPlaceholderForVenue:(Venue *)venue;
-(instancetype)initUnknownContentForVenue:(Venue *)venue;
-(void)updateContentWithMemory:(Memory *)memory;
-(instancetype)initTextContentForMemory:(Memory *)memory;

// TODO: remove these? they are placeholder factory methods to test UI
// while the server support for this feature is being implemented
-(instancetype)initWithPopularMemoryHere:(Memory *)memory;
-(instancetype)initWithFeaturedMemory:(Memory *)memory;
-(instancetype)initWithVenueNearby:(Venue *)venue;

@end
