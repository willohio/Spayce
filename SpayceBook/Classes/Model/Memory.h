//
//  Memory.h
//  Spayce
//
//  Created by Pavel Dušátko on 11/28/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class Location;
@class Venue;
@class Person;
@class Asset;

typedef NS_ENUM(NSInteger, MemoryType) {
    MemoryTypeText = 1,
    MemoryTypeImage = 2,
    MemoryTypeVideo = 3,
    MemoryTypeAudio = 4,
    MemoryTypeMap = 5,
    MemoryTypeFriends = 6
};

typedef NS_ENUM(NSInteger, MemoryAccessType) {
    MemoryAccessTypePublic,
    MemoryAccessTypeFriend,
    MemoryAccessTypePrivate
};

@interface Memory : NSObject

@property (assign, nonatomic) NSInteger recordID;
@property (strong, nonatomic) NSString *key;
@property (assign, nonatomic) NSInteger type;
@property (assign, nonatomic) NSInteger accessType;
@property (strong, nonatomic) NSDate *dateCreated;
@property (strong, nonatomic) NSString *timeElapsed;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) Location *location;
@property (strong, nonatomic) Venue *venue;
@property (strong, nonatomic) Person *author;
@property (strong, nonatomic) Person *realAuthor;
@property (assign, nonatomic) CGFloat distanceAway;
@property (assign, nonatomic) NSInteger friendsCount;
@property (assign, nonatomic) NSInteger commentsCount;
@property (assign, nonatomic) NSInteger starsCount;
@property (assign, nonatomic) NSInteger engagementCount;
@property (strong, nonatomic) NSString *locationName;
@property (strong, nonatomic) Asset *locationMainPhotoAsset;
@property (strong, nonatomic) Asset *locationIconPhotoAsset;
@property (assign, nonatomic) BOOL userHasStarred;
@property (assign, nonatomic) BOOL userHasCommented;
@property (assign, nonatomic) NSInteger addressID;
@property (strong, nonatomic) NSArray *taggedUsers;
@property (readonly, nonatomic) NSArray *taggedUsersIDs;
@property (strong ,nonatomic) NSArray *recentComments;
@property (strong, nonatomic) Person *userToStarMostRecently;
@property (strong, nonatomic) NSArray *hashTags;
@property (assign, nonatomic) BOOL isAnonMem;
@property (assign, nonatomic) BOOL userIsWatching;
@property (strong, nonatomic) NSDate *featuredTime;
@property (strong, nonatomic) NSString *timeElapsedSinceFeatured;

@property (nonatomic, strong, readonly) NSAttributedString *authorAttributedString;
@property (nonatomic, readonly) CGFloat commentsCountTextWidth;
@property (nonatomic, readonly) CGFloat starsCountTextWidth;
@property (nonatomic, readonly) CGFloat heightForMemoryText;
@property (nonatomic) CGFloat heightForCommentText;

- (id)initWithAttributes:(NSDictionary *)attributes;
- (void)setWithAttributes:(NSDictionary *)attributes;

/* Updates this instance with the fields in the provided memory.
 * If this instance has (potentially) changed, returns YES.
 * The "potentially" allows us to err on the side of updating displays
 * this instance.
 */
- (BOOL)updateWithMemory:(Memory *)memory;
- (void)updateCommentPreviewHeight;

- (NSDate *)datePublicExpired;
- (BOOL)isVipMemory;

- (BOOL)matchesHashTag:(NSString *)hashTag;

- (void)refreshMetadata;

/* A static creation function that returns an instance of the appropriate subclass.
    Useful to avoid having to directly parse the argument to determine the subclass
    before allocating the object. */
+(Memory *)memoryWithAttributes:(NSDictionary *)attributes;

@end

@interface ImageMemory : Memory

@property (strong, nonatomic) NSArray *images;

@end

@interface VideoMemory : Memory

@property (strong, nonatomic) NSArray *previewImages;
@property (strong, nonatomic) NSArray *videoURLs;

@end

@interface AudioMemory : Memory

@property (strong, nonatomic) NSArray *audioURLs;

@end

@interface MapMemory : Memory

@end

@interface FriendsMemory : Memory

@end
