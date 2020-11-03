//
//  Venue.h
//  Spayce
//
//  Created by Christopher Taylor on 1/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class Asset;
@class Memory;

@interface Venue : NSObject

@property (strong, nonatomic) NSString *defaultName;
@property (strong, nonatomic) NSString *customName;
@property (strong, nonatomic) NSNumber *latitude;
@property (strong, nonatomic) NSNumber *longitude;
@property (strong, nonatomic) Asset *imageAsset;
@property (strong, nonatomic) Asset *bestImageAsset;
@property (strong, nonatomic) Asset *bannerAsset;
@property (strong, nonatomic) Memory *bestImageAssetMemory;
@property (assign, nonatomic) NSNumber *distance;
@property (assign, nonatomic) CGFloat distanceAway;
@property (assign, nonatomic) NSInteger addressId;
@property (strong, nonatomic) NSString *addressKey;
@property (assign, nonatomic) NSInteger locationId;
@property (strong, nonatomic) NSString *locationKey;
@property (assign, nonatomic) NSInteger totalMemories;
@property (assign, nonatomic) NSInteger totalStars;
@property (assign, nonatomic) NSInteger totalUserMemories;
@property (strong, nonatomic) NSArray * popularMemories;
@property (strong, nonatomic) NSArray * recentHashtagMemories;
@property (assign, nonatomic) CGFloat prominence;
@property (strong, nonatomic) NSString *venueName;
@property (strong, nonatomic) NSArray *venueTypes;
@property (strong, nonatomic) NSString *streetAddress;
@property (strong, nonatomic) NSString *neighborhood;
@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *county;
@property (strong, nonatomic) NSString *postalCode;
@property (strong, nonatomic) NSString *country;
@property (strong, nonatomic) NSArray * companionLocIds;
@property (strong, nonatomic) NSDate *featuredTime;
@property (strong, nonatomic) NSString *timeElapsedSinceFeatured;
@property (assign, nonatomic) NSInteger specificity;
@property (assign, nonatomic) BOOL userIsWithin;

@property (assign, nonatomic) BOOL hasStaleAddress;
@property (assign, nonatomic) BOOL hasStaleVenue;

@property (strong, nonatomic) NSNumber *addressLatitude;
@property (strong, nonatomic) NSNumber *addressLongitude;

@property (assign, nonatomic) NSInteger ownerId;

@property (assign, nonatomic) BOOL favorited;

@property (nonatomic, assign) NSInteger venueProximityScore;

- (id)initWithAttributes:(NSDictionary *)attributes;
- (void)updateDistance:(double)distance;
- (void)updateScore;
- (CLLocation *)location;

- (NSString *)displayName;
- (NSString *)displayNameTitle;
- (NSString *)displayNameSubtitle;
- (NSString *)displayMemoriesCountString;
- (NSString *)displayStarsCountString;

// some helpful accessors (useful for determining a sort order, e.g.)
-(BOOL)isOwnedByUser;
-(BOOL)isOwnedByUserFriend;
-(BOOL)isCustomVenue;
-(BOOL)isRealVenue;

@end


