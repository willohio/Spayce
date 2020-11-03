//
//  SPCMapDataSource.m
//  Spayce
//
//  Created by Jake Rosin on 6/17/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMapDataSource.h"
#import "SPCMarker.h"

// Manager
#import "AuthenticationManager.h"
#import "ContactAndProfileManager.h"
#import "LocationManager.h"
#import "SDWebImageManager.h"

// Model
#import "Person.h"
#import "ProfileDetail.h"
#import "SPCVenueTypes.h"
#import "User.h"
#import "UserProfile.h"
#import "Location.h"
#import "Asset.h"

// Category
#import "NSString+SPCAdditions.h"

// Utility
#import "APIUtils.h"

#define STACK_WITHIN_METERS 3
#define SELECT_BUTTON_WIDTH 50.0
#define SELECT_BUTTON_HEIGHT 35.0

const NSInteger spc_VENUE_DATA_OPTION_STAR_NONE = 0x1;
const NSInteger spc_VENUE_DATA_OPTION_STAR_GOLD = 0x2;
const NSInteger spc_VENUE_DATA_OPTION_STAR_SILVER = 0x4;
const NSInteger spc_VENUE_DATA_OPTION_STAR_BRONZE = 0x8;

const NSInteger spc_VENUE_DATA_OPTION_USER_LOCATION_CURRENT = 0x10;
const NSInteger spc_VENUE_DATA_OPTION_USER_LOCATION_ORIGINAL = 0x20;

const NSInteger spc_VENUE_DATA_OPTION_REALTIME = 0x40;

const NSInteger spc_VENUE_DATA_OPTION_EMPHASIZE_OWNED = 0x80;

@interface SPCMarkerVenueData()

@property (nonatomic, strong) UIImage *cachedMarkerIcon;
@property (nonatomic, strong) NSString *cachedMarkerIconName;
@property (nonatomic, strong) UIImage *markerPicture;
@property (nonatomic, strong) UIImage *selectedIcon;
@property (nonatomic, strong) UIImage *nonSelectedIcon;
@property (nonatomic, strong) Asset *markerPictureAsset;

@property (nonatomic, assign) BOOL draggable;

- (UIImage *)exploreIconWithMemoryImage:(UIImage *)image;

@end

@implementation SPCMarkerVenueData

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (instancetype)initWithLocation:(CLLocation *)location venue:(Venue *)venue {
    self = [super init];
    if (self) {
        _coordinate = location.coordinate;
        _venue = venue;
        if (venue) {
            _venues = @[venue];
        } else {
            _venues = nil;
        }
        
        // other defaults...
        self.memory = nil;
        self.isCurrentUserLocation = NO;
        self.isOriginalUserLocation = NO;
        self.markerStarType = MarkerStarTypeNone;
        self.mapMarkerStyle = MapMarkerStyleNormal;
    }
    return self;
}


- (instancetype)initWithVenue:(Venue *)venue {
    self = [self initWithLocation:venue.location venue:venue];
    if (self) {
        // nothing to do
    }
    return self;
}


- (instancetype)initWithVenues:(NSArray *)venues {
    self = [self initWithVenue:venues[0]];
    if (self) {
        self.venues = venues;
        
        //create array of companion location ids for use when updating multipin icons
        NSMutableArray *tempIDsArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.venues.count; i++) {
            Venue *tempV = (Venue *)self.venues[i];
            NSNumber *tempLocId = @(tempV.locationId);
            [tempIDsArray addObject:tempLocId];
        }
        
        NSArray *idsArray = [NSArray arrayWithArray:tempIDsArray];
        for (int i = 0; i < self.venues.count; i++) {
            Venue *tempV = (Venue *)self.venues[i];
            tempV.companionLocIds = idsArray;
        }
    }
    return self;
}

- (instancetype)initWithMemory:(Memory *)memory {
    self = [self initWithMemory:memory venue:memory.venue];
    if (self) {
        self.memory = memory;
        // more config?
    }
    return self;
}

- (instancetype)initWithMemory:(Memory *)memory venue:(Venue *)venue {
    self = [self initWithVenue:venue];
    if (self) {
        self.memory = memory;
        self.isOriginalUserLocation = YES;
        if (self.coordinate.latitude == 0 && self.coordinate.longitude == 0) {
            _coordinate = CLLocationCoordinate2DMake(memory.location.latitude.doubleValue, memory.location.longitude.doubleValue);
        }
    }
    return self;
}

- (void) setOptions:(NSInteger)options {
    if (options & spc_VENUE_DATA_OPTION_STAR_NONE) {
        self.markerStarType = MarkerStarTypeNone;
    }
    if (options & spc_VENUE_DATA_OPTION_STAR_BRONZE) {
        self.markerStarType = MarkerStarTypeBronze;
    }
    if (options & spc_VENUE_DATA_OPTION_STAR_SILVER) {
        self.markerStarType = MarkerStarTypeSilver;
    }
    if (options & spc_VENUE_DATA_OPTION_STAR_GOLD) {
        self.markerStarType = MarkerStarTypeGold;
    }
    self.isCurrentUserLocation = options & spc_VENUE_DATA_OPTION_USER_LOCATION_CURRENT;
    self.isOriginalUserLocation = options & spc_VENUE_DATA_OPTION_USER_LOCATION_ORIGINAL;
    self.isRealtime = options & spc_VENUE_DATA_OPTION_REALTIME;
    if (options & spc_VENUE_DATA_OPTION_EMPHASIZE_OWNED) {
        self.mapMarkerStyle = MapMarkerStyleEmphasizeOwned;
    }
}


- (void)setIsRealtime:(BOOL)isRealtime {
    _isRealtime = isRealtime;
}

- (void)setMemory:(Memory *)memory {
    _memory = memory;
}

- (UIImage *)markerWithVenueForLocationId:(Venue *)venue {
    
    NSMutableArray *updateVenues = [NSMutableArray arrayWithArray:self.venues];
    for (int i = 0; i< updateVenues.count; i++) {
        
        Venue *tempV = (Venue *)updateVenues[i];
        if (tempV.locationId == venue.locationId) {
            self.venue = tempV;
            [updateVenues removeObject:tempV];
            [updateVenues insertObject:tempV atIndex:0];
            //NSLog(@"updating multivenue marker to:%@",tempV.displayNameTitle);
            break;
        }
    }
    
    self.venues = [NSArray arrayWithArray:updateVenues];
    

    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:self.venues];
    return venueData.selectedIcon;

}

+ (SPCMarker *)markerWithCurrentLocation:(CLLocation *)location venue:(Venue *)venue {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    venueData.isCurrentUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}


+ (SPCMarker *)markerWithOriginalLocation:(CLLocation *)location venue:(Venue *)venue {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    venueData.isOriginalUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithOriginalAndCurrentLocation:(CLLocation *)location venue:(Venue *)venue {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    venueData.isOriginalUserLocation = YES;
    venueData.isCurrentUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithCurrentLocation:(CLLocation *)location venue:(Venue *)venue draggable:(BOOL)draggable {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    venueData.isCurrentUserLocation = YES;
    venueData.draggable = draggable;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithOriginalLocation:(CLLocation *)location venue:(Venue *)venue draggable:(BOOL)draggable {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    venueData.isOriginalUserLocation = YES;
    venueData.draggable = draggable;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithOriginalAndCurrentLocation:(CLLocation *)location venue:(Venue *)venue draggable:(BOOL)draggable {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    venueData.isCurrentUserLocation = YES;
    venueData.isOriginalUserLocation = YES;
    venueData.draggable = draggable;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithVenue:(Venue *)venue {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenue:venue];
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithVenues:(NSArray *)venues {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:venues];
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithCurrentVenue:(Venue *)venue {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenue:venue];
    venueData.isCurrentUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithCurrentVenues:(NSArray *)venues {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:venues];
    venueData.isCurrentUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithOriginalVenues:(NSArray *)venues {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:venues];
    venueData.isOriginalUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithOriginalAndCurrentVenues:(NSArray *)venues {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:venues];
    venueData.isCurrentUserLocation = YES;
    venueData.isOriginalUserLocation = YES;
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithMemory:(Memory *)memory {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithMemory:memory];
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithRealtimeMemory:(Memory *)memory venue:(Venue *)venue iconReadyHandler:(void (^)(SPCMarker *marker))iconReadyHandler {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithMemory:memory venue:venue];
    venueData.isRealtime = YES;
    venueData.starCount = memory.starsCount;
    return [SPCMarkerVenueData markerWithVenueData:venueData iconReadyHandler:iconReadyHandler];
}

+ (SPCMarker *)markerWithVenueData:(SPCMarkerVenueData *)venueData {
    SPCMarker * marker = [[SPCMarker alloc] init];
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:YES];
    return marker;
}

+ (SPCMarker *)markerWithVenueData:(SPCMarkerVenueData *)venueData iconReadyHandler:(void (^)(SPCMarker *marker))iconReadyHandler {
    SPCMarker * marker = [[SPCMarker alloc] init];
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:YES iconReadyHandler:iconReadyHandler];
    return marker;
}

+ (SPCMarker *)markerWithLocation:(CLLocation *)location venue:(Venue *)venue options:(NSInteger)options {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithLocation:location venue:venue];
    [venueData setOptions:options];
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithVenue:(Venue *)venue options:(NSInteger)options {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenue:venue];
    [venueData setOptions:options];
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (SPCMarker *)markerWithVenues:(NSArray *)venues options:(NSInteger)options {
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:venues];
    [venueData setOptions:options];
    return [SPCMarkerVenueData markerWithVenueData:venueData];
}

+ (void)configureMarker:(SPCMarker *)marker withVenueData:(SPCMarkerVenueData *)venueData reposition:(BOOL)reposition {
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:reposition iconReadyHandler:^(SPCMarker *marker) {
        // nothing
    }];
}

+ (void)configureMarker:(SPCMarker *)marker withVenueData:(SPCMarkerVenueData *)venueData reposition:(BOOL)reposition iconReadyHandler:(void (^)(SPCMarker *marker))iconReadyHandler {
    marker.userData = venueData;
    marker.title = venueData.title;
    marker.snippet = venueData.subtitle;
    marker.icon = [venueData markerIconPlaceholder];
    marker.selectedIcon = [venueData selectedIconPlaceholder];
    marker.nonSelectedIcon = [venueData nonSelectedIconPlaceholder];
    marker.groundAnchor = venueData.markerGroundAnchor;
    marker.infoWindowAnchor = venueData.markerInfoWindowAnchor;
    if (venueData.draggable) {
        marker.draggable = YES;
    }
    
    //handle real-time pins for explore mode
    if (venueData.isRealtime) {
        //NSLog(@"look for explore icon");
        marker.appearAnimation = kGMSMarkerAnimationPop;

        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:venueData.exploreAsset.imageUrlThumbnail]
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            marker.icon = [venueData exploreIconWithMemoryImage:image];
            marker.selectedIcon = venueData.selectedIcon;
            marker.nonSelectedIcon = venueData.nonSelectedIcon;
            if (iconReadyHandler) {
                iconReadyHandler(marker);
            }
            marker.map = marker.map;
        }];
 
    }
    // handle the non-real time pins
   else {
       
        //do we have a profile pic img handy?
        if (![ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg) {
            //NSLog(@"no pic asset yet, get image before creating marker!");
            
            Asset *profilePicAsset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
            if (!profilePicAsset) {
                //NSLog(@"uh oh!, no profilePicAsset!");
            }
            
            //are we in preview mode??
            if (![AuthenticationManager sharedInstance].currentUser) {
                //NSLog(@"we are in preview mode!");
                dispatch_async(dispatch_get_main_queue(), ^{
                    marker.icon = venueData.markerIcon;
                    marker.selectedIcon = venueData.selectedIcon;
                    marker.nonSelectedIcon = venueData.nonSelectedIcon;
                    //NSLog(@"Setting icons took %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
                    
                    //NSLog(@"we are in preview mode - no profile pic, but good to go");
                    if (iconReadyHandler) {
                        iconReadyHandler(marker);
                    }
                    marker.map = marker.map;
                });
            }
            else {
            
                //NSLog(@"load profile pic asynchronously");
                [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:profilePicAsset.imageUrlThumbnail] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    [ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg = image;
                    marker.icon = venueData.markerIcon;
                    marker.selectedIcon = venueData.selectedIcon;
                    marker.nonSelectedIcon = venueData.nonSelectedIcon;
                    //NSLog(@"Setting icons took %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
                    if (iconReadyHandler) {
                        iconReadyHandler(marker);
                    }
                    marker.map = marker.map;
                }];
            }
            
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                marker.icon = venueData.markerIcon;
                marker.selectedIcon = venueData.selectedIcon;
                marker.nonSelectedIcon = venueData.nonSelectedIcon;
                //NSLog(@"Setting icons took %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
                
                //NSLog(@"already have profile pic, we're good to go");
                if (iconReadyHandler) {
                    iconReadyHandler(marker);
                }
                marker.map = marker.map;
            });
        }
    }
    
    if (reposition) {
        marker.position = CLLocationCoordinate2DMake(venueData.coordinate.latitude, venueData.coordinate.longitude);
    }
}


#pragma mark - Mutators

-(void)setVenue:(Venue *)venue {
    _venue = venue;
    _cachedMarkerIcon = nil;
    _cachedMarkerIconName = nil;
    _markerPicture = nil;
}

-(void)setVenues:(NSArray *)venues {
    _venues = venues;
    _cachedMarkerIcon = nil;
    _cachedMarkerIconName = nil;
    _markerPicture = nil;
}

-(void)setIsCurrentUserLocation:(BOOL)isCurrentUserLocation {
    _isCurrentUserLocation = isCurrentUserLocation;
    _cachedMarkerIcon = nil;
    _cachedMarkerIconName = nil;
    _markerPicture = nil;
}

-(void)setIsOriginalUserLocation:(BOOL)isOriginalUserLocation {
    _isOriginalUserLocation = isOriginalUserLocation;
    _cachedMarkerIcon = nil;
    _cachedMarkerIconName = nil;
    _markerPicture = nil;
}


#pragma mark - Accessors

+(NSCache *)iconCache {
    static NSCache *cache = nil;
    
    if (cache == nil) {
        cache = [[NSCache alloc] init];
        [cache setCountLimit:18];
    }
    
    return cache;
}

+(NSCache *)assetCache {
    static NSCache *cache = nil;
    
    if (cache == nil) {
        cache = [[NSCache alloc] init];
        [cache setCountLimit:8];
    }
    
    return cache;
}

-(NSString *)title {
    return [self titleForVenue:self.venue];
}

-(NSString *)subtitle {
    return [self subtitleForVenue:self.venue];
}

-(UIImage *)markerIcon {
    if (self.isCurrentUserLocation) {
       return [self loadSelectedMarkerIcon];
    }
    else {
        if (self.isOriginalUserLocation ) {
            return [self loadCreateVenueIcon];
        }
        else {
            return [self loadNonSelectedMarkerIcon];
        }
    }
}

-(UIImage *)markerIconPlaceholder {
    if (self.isCurrentUserLocation) {
        return [self getSelectedMarkerIconPlaceholder];
    }
    else {
        if (self.isOriginalUserLocation ) {
            return [self getCreateVenueIconPlaceholder];
        }
        else {
            return [self getNonSelectedMarkerIconPlaceholder];
        }
    }
}

-(UIImage *)nonSelectedIcon {
    return [self loadNonSelectedMarkerIcon];
}

- (UIImage *)nonSelectedIconPlaceholder {
    return [self getNonSelectedMarkerIconPlaceholder];
}

-(UIImage *)selectedIcon {
    return [self loadSelectedMarkerIcon];
}

-(UIImage *)selectedIconPlaceholder {
    return [self getSelectedMarkerIconPlaceholder];
}

-(UIImage *)exploreIconWithMemoryImage:(UIImage *)image {
    return [self loadExploreIconWithMemoryImage:image];
}

-(BOOL)markerIconIsPlaceholder {
    return _cachedMarkerIcon == nil || ![_cachedMarkerIconName isEqualToString:[self getMarkerIconName]];
}

-(NSInteger)memoryCount {
    if (self.venues) {
        NSInteger count = 0;
        for (Venue * venue in self.venues) {
            count += venue.totalMemories;
        }
        return count;
    }
    return 0;
}

-(void)cacheMarkerPicture:(UIImage *)markerPicture {
    _markerPicture = markerPicture;
    if (markerPicture) {
        NSString * profileAssetString = [APIUtils imageUrlStringForUrlString:self.markerPictureAsset.imageUrlThumbnail size:ImageCacheSizeThumbnailSmall];
        [[SPCMarkerVenueData assetCache] setObject:markerPicture forKey:profileAssetString];
    }
}

-(Asset *)markerPictureAsset {
    Asset *asset = nil;
    if (self.memory) {
        // take either the memory image (if available) or
        // the author photo.
        if (self.isRealtime) {
            if ([self.memory isKindOfClass:[ImageMemory class]]) {
                ImageMemory * imem = (ImageMemory *) self.memory;
                if (imem.images.count > 0) {
                    asset = imem.images[0];
                }
            } else if ([self.memory isKindOfClass:[VideoMemory class]]) {
                VideoMemory * imem = (VideoMemory *) self.memory;
                if (imem.previewImages.count > 0) {
                    asset = imem.previewImages[0];
                }
            }
        }
        
        if (!asset) {
            asset = self.memory.author.imageAsset;
        }
    }
    if (!asset) {
        asset = [ContactAndProfileManager sharedInstance].profile.profileDetail.imageAsset;
    }
    
    return asset;
}

-(Asset *)exploreAsset {
    Asset *asset = nil;
    if (self.memory) {
        // take either the memory image (if available) or
        // the author photo.
        if (self.isRealtime) {
            if ([self.memory isKindOfClass:[ImageMemory class]]) {
                ImageMemory * imem = (ImageMemory *) self.memory;
                if (imem.images.count > 0) {
                    asset = imem.images[0];
                }
            } else if ([self.memory isKindOfClass:[VideoMemory class]]) {
                VideoMemory * imem = (VideoMemory *) self.memory;
                if (imem.previewImages.count > 0) {
                    asset = imem.previewImages[0];
                }
            }
            else {
                //NSLog(@"explore asset missing for mem of type %li",self.memory.type);
                for (int i = 0; i < self.venue.popularMemories.count; i++) {
                    ImageMemory * popMem = (ImageMemory *)self.venue.popularMemories[i];
                    if ([popMem isKindOfClass:[ImageMemory class]]) {
                        //NSLog(@"MIA explore asset, attempting to default to a popular image mem from the same venue");
                        asset = popMem.images[i];
                        break;
                    }
                }
            }
        }
    }
    return asset;
}

-(NSString *)getMarkerIconBaseName {
    NSString *iconName;
    if (self.isRealtime) {
        iconName = @"pin-filled-realtime";
    } else {
        VenueIconType iconType = VenueIconTypeIconNewColor;
        iconName = [SPCVenueTypes imageNameForVenue:self.venue withIconType:iconType];
    }
    
    return iconName;
}

-(NSString *)getMarkerIconName {
    
    
    NSString *iconName = [self getMarkerIconBaseName];
    
    // Now apply special handling to the icon.  This level of processing
    // requires creating a new image with customized content, so we rely on the
    // ImageCache to store the result (if it's not just a standard icon).  Types
    // of custom content:
    // 1. The user's device location gets their own photo.
    // 2. A venue pin with > 1 venue gets a count
    // 3. The user's CURRENT location (if a venue) gets a small circular thumbnail
    //      of their profile photo.
    if (self.isOriginalUserLocation || self.venueCount > 1 || self.isCurrentUserLocation || self.memoryCount > 0 || self.markerStarType != MarkerStarTypeNone) {
        // custom pin!
        Asset *profileAsset = self.markerPictureAsset;
        NSInteger memoryCount = self.isOriginalUserLocation ? 0 : self.memoryCount;
        CGFloat alpha = 1.0f;
        if (self.isOriginalUserLocation) {
            iconName = [NSString stringWithFormat:@"%@_markerAssetId_%@", iconName, @(profileAsset.assetID)];
        }
        if (self.venueCount > 1 && !self.isOriginalUserLocation) {
            iconName = [NSString stringWithFormat:@"%@_venueCount_%@", iconName, @(self.venueCount)];
        }
        if (self.isCurrentUserLocation && !self.isOriginalUserLocation) {
            iconName = [NSString stringWithFormat:@"%@_profileBadgeAssetId_%@", iconName, @(profileAsset.assetID)];
        }
        if (self.markerStarType != MarkerStarTypeNone) {
            iconName = [NSString stringWithFormat:@"%@_markerStarType_%@", iconName, @(self.markerStarType)];
        } else if (memoryCount > 0) {
            iconName = [NSString stringWithFormat:@"%@_memoryCount_%@", iconName, @(memoryCount)];
        }
        if (self.isOriginalUserLocation && !self.isCurrentUserLocation && !self.memory && !self.draggable) {
            alpha = self.venue ? 0.7f : 0.5f;
        }
        iconName = [NSString stringWithFormat:@"%@_alpha_%f", iconName, alpha];
    }
    
    return iconName;
}

-(UIImage *)getSelectedMarkerIconPlaceholder {
    if (self.venueCount > 1) {
        if (self.memoryCount > 0) {
            return [UIImage imageNamed:@"multivenue-selected-pin"];
        } else {
            return [UIImage imageNamed:@"selected-mini-multivenue-pin"];
        }
    } else {
        if (self.memoryCount > 0) {
            return [UIImage imageNamed:@"selected-pin"];
        } else {
            return [UIImage imageNamed:@"selected-mini-pin"];
        }
    }
}

-(UIImage *)loadSelectedMarkerIcon {
    
    NSString *iconNameBase = [self getMarkerIconBaseName];
    
    UIImage *icon;
    CGFloat alpha = 1.0f;
    
    
    if (self.venueCount > 1) {
        /*
         NSLog(@" --- multipin with venues: ---");
         for (Venue *v in self.venues) {
         NSLog(@"%@, locId: %li",v.displayNameTitle,v.locationId);
         }
         NSLog(@" --- end ---");
         */

        UIView *compositeView = [[UIView alloc] init];
       
        if (self.memoryCount > 0) {

            compositeView.frame = CGRectMake(0,0, 100, 90);
            
            UIImage *pinBgImg = [UIImage imageNamed:@"multivenue-selected-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 30);
            [compositeView addSubview:iconImageView];
            
            
            // user badge
            UIImage *profileBadgeBackgroundImage = [UIImage imageNamed:@"pin-badge-you"];
            UIImageView *profileFrameView = [[UIImageView alloc] initWithImage:profileBadgeBackgroundImage];
            // place the user's profile pic in the middle.
            UIView *profilePicView;
            if (![ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg) {
                // white placeholder
                 profilePicView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-profile"]];
            } else {
                // put the pic in place
                profilePicView = [[UIImageView alloc] initWithImage:[ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg];
            }
            
            profilePicView.frame = CGRectMake(2.0, 2.0, 25, 25);
            profilePicView.layer.cornerRadius = 12.5f;
            profilePicView.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
            profilePicView.layer.borderWidth = 2;
            profilePicView.clipsToBounds = YES;
            [profileFrameView addSubview:profilePicView];
            CGRect frame = profileFrameView.frame;
            frame.origin = CGPointMake(62.0, 0.0);
            profileFrameView.frame = frame;
            [compositeView addSubview:profileFrameView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(iconImageView.frame)+5, 45, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.center = CGPointMake(compositeView.frame.size.width/2, titleLabel.center.y);
            [compositeView addSubview:titleLabel];
            
            UIImageView *memIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-pin-memory"]];
            [compositeView addSubview:memIcon];
            memIcon.center = CGPointMake(compositeView.frame.size.width/2 - 5, CGRectGetMaxY(titleLabel.frame)+8);
            
            //mem count label
            UILabel * countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(memIcon.frame), CGRectGetMaxY(titleLabel.frame)+4, 15, 10)];
            countLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            countLabel.text = [NSString stringByTruncatingInteger:self.memoryCount];
            countLabel.backgroundColor = [UIColor clearColor];
            countLabel.textAlignment = NSTextAlignmentLeft;
            countLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:8];
            countLabel.numberOfLines = 1;
            [compositeView addSubview:countLabel];
            
            //venue count label
            UILabel * venCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 16, 19, 18)];
            venCountLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
            venCountLabel.text = [NSString stringWithFormat:@"%@", @(self.venueCount)];
            venCountLabel.backgroundColor = [UIColor clearColor];
            venCountLabel.textAlignment = NSTextAlignmentCenter;
            venCountLabel.font = [UIFont spc_boldSystemFontOfSize:14];
            venCountLabel.numberOfLines = 1;
            [compositeView addSubview:venCountLabel];
        }
        
        else {
            
            compositeView.frame = CGRectMake(0,0, 100, 75);
            
            UIImage *pinBgImg = [UIImage imageNamed:@"selected-mini-multivenue-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 35);
            [compositeView addSubview:iconImageView];
            
            
            // user badge
            UIImage *profileBadgeBackgroundImage = [UIImage imageNamed:@"pin-badge-you"];
            UIImageView *profileFrameView = [[UIImageView alloc] initWithImage:profileBadgeBackgroundImage];
            // place the user's profile pic in the middle.
            UIView *profilePicView;
            if (![ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg) {
                // white placeholder
                NSLog(@"placeholder profile??");
                profilePicView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-profile"]];
                profilePicView.backgroundColor = [UIColor whiteColor];
            } else {
                // put the pic in place
                profilePicView = [[UIImageView alloc] initWithImage:[ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg];
            }
            
            profilePicView.frame = CGRectMake(2.0, 2.0, 25, 25);
            profilePicView.layer.cornerRadius = 12.5f;
            profilePicView.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
            profilePicView.layer.borderWidth = 2;
            profilePicView.clipsToBounds = YES;
            [profileFrameView addSubview:profilePicView];
            CGRect frame = profileFrameView.frame;
            frame.origin = CGPointMake(62.0, 5.0);
            profileFrameView.frame = frame;
            [compositeView addSubview:profileFrameView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, CGRectGetMaxY(iconImageView.frame)+5, 45, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.center = CGPointMake(compositeView.frame.size.width/2, titleLabel.center.y);
            [compositeView addSubview:titleLabel];
            
            //venue count label
            UILabel * venCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 21, 19, 18)];
            venCountLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
            venCountLabel.text = [NSString stringWithFormat:@"%@", @(self.venueCount)];
            venCountLabel.backgroundColor = [UIColor clearColor];
            venCountLabel.textAlignment = NSTextAlignmentCenter;
            venCountLabel.font = [UIFont spc_boldSystemFontOfSize:14];
            venCountLabel.numberOfLines = 1;
            [compositeView addSubview:venCountLabel];
            
        }
            
        // Render
        UIGraphicsBeginImageContextWithOptions(compositeView.bounds.size, NO, 0.0);
        [compositeView.layer renderInContext:UIGraphicsGetCurrentContext()];
        icon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }

    else {
        UIView *compositeView = [[UIView alloc] init];
        
        if (self.memoryCount > 0) {
        
            // make and save the image.
            compositeView.backgroundColor = [UIColor clearColor];
            compositeView.frame = CGRectMake(0.0, 0.0, 85.0, 85.0);
        
            UIImage *pinBgImg = [UIImage imageNamed:@"selected-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            pinBgImgView.frame = CGRectMake(15, 10, 55, 75);
            
            UIImage *baseImage;
            if (iconNameBase) {
                baseImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *baseImageView = [[UIImageView alloc] initWithImage:baseImage];
            baseImageView.backgroundColor = [UIColor clearColor];
            baseImageView.center = CGPointMake(compositeView.frame.size.width/2, 5 + compositeView.frame.size.height*.28);
            [compositeView addSubview:baseImageView];
            
            // user badge
            UIImage *profileBadgeBackgroundImage = [UIImage imageNamed:@"pin-badge-you"];
            UIImageView *profileFrameView = [[UIImageView alloc] initWithImage:profileBadgeBackgroundImage];
            // place the user's profile pic in the middle.
            UIView *profilePicView;
            if (![ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg) {
                // white placeholder
                profilePicView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-profile"]];
                profilePicView.backgroundColor = [UIColor whiteColor];
            } else {
                // put the pic in place
                profilePicView = [[UIImageView alloc] initWithImage:[ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg];
            }
            
            profilePicView.frame = CGRectMake(2.0, 2.0, 25, 25);
            profilePicView.layer.cornerRadius = 12.5f;
            profilePicView.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
            profilePicView.layer.borderWidth = 2;
            profilePicView.clipsToBounds = YES;
            [profileFrameView addSubview:profilePicView];
            CGRect frame = profileFrameView.frame;
            frame.origin = CGPointMake(55.0, 0.0);
            profileFrameView.frame = frame;
            [compositeView addSubview:profileFrameView];
            
            // Handle memory count
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(baseImageView.frame)+5, 45, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [compositeView addSubview:titleLabel];
            
            UIImageView *memIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-pin-memory"]];
            [compositeView addSubview:memIcon];
            memIcon.center = CGPointMake(37, 62);
            
            UILabel * countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(memIcon.frame), 58, 15, 10)];
            countLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            countLabel.text = [NSString stringByTruncatingInteger:self.memoryCount];
            countLabel.backgroundColor = [UIColor clearColor];
            countLabel.textAlignment = NSTextAlignmentLeft;
            countLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:8];
            countLabel.numberOfLines = 1;
            [compositeView addSubview:countLabel];
            
            compositeView.alpha = alpha;
        }
        else {
            compositeView.frame = CGRectMake(0,0, 80, 80);
            
            UIImage *pinBgImg = [UIImage imageNamed:@"selected-mini-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            pinBgImgView.frame = CGRectMake(10, 10, 60, 60);
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 30);
            [compositeView addSubview:iconImageView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(iconImageView.frame)+5, 40, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.center = CGPointMake(iconImageView.center.x, titleLabel.center.y);
            [compositeView addSubview:titleLabel];
            
            
            // user badge
            UIImage *profileBadgeBackgroundImage = [UIImage imageNamed:@"pin-badge-you"];
            UIImageView *profileFrameView = [[UIImageView alloc] initWithImage:profileBadgeBackgroundImage];
            // place the user's profile pic in the middle.
            UIView *profilePicView;
            if (![ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg) {
                // white placeholder
                profilePicView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder-profile"]];
                profilePicView.backgroundColor = [UIColor whiteColor];
            } else {
                // put the pic in place
                profilePicView = [[UIImageView alloc] initWithImage:[ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg];
            }
            
            profilePicView.frame = CGRectMake(2.0, 2.0, 25, 25);
            profilePicView.layer.cornerRadius = 12.5f;
            profilePicView.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
            profilePicView.layer.borderWidth = 2;
            profilePicView.clipsToBounds = YES;
            [profileFrameView addSubview:profilePicView];
            CGRect frame = profileFrameView.frame;
            frame.origin = CGPointMake(50.0, 0.0);
            profileFrameView.frame = frame;
            [compositeView addSubview:profileFrameView];
        }
        // Render
        UIGraphicsBeginImageContextWithOptions(compositeView.bounds.size, NO, 0.0);
        [compositeView.layer renderInContext:UIGraphicsGetCurrentContext()];
        icon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return icon;
}


-(UIImage *)getNonSelectedMarkerIconPlaceholder {
    if (self.venueCount > 1) {
        if (self.memoryCount > 0) {
            return [UIImage imageNamed:@"multivenue-blank-pin"];
        } else {
            return [UIImage imageNamed:@"blank-mini-multivenue-pin"];
        }
    } else {
        if (self.memoryCount > 0) {
            return [UIImage imageNamed:@"blank-pin"];
        } else {
            return [UIImage imageNamed:@"blank-mini-pin"];
        }
    }
}


-(UIImage *)loadNonSelectedMarkerIcon {
    
    NSString *iconNameBase = [self getMarkerIconBaseName];
    
    UIImage *icon;
    UIView *compositeView = [[UIView alloc] init];
    
    if (self.venueCount > 1) {
        
        compositeView.frame = CGRectMake(0,0, 100, 90);
        
        if (self.memoryCount > 0) {
            UIImage *pinBgImg = [UIImage imageNamed:@"multivenue-blank-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 30);
            [compositeView addSubview:iconImageView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(iconImageView.frame)+5, 45, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.center = CGPointMake(compositeView.frame.size.width/2, titleLabel.center.y);
            [compositeView addSubview:titleLabel];
            
            UIImageView *memIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-pin-memory"]];
            [compositeView addSubview:memIcon];
            memIcon.center = CGPointMake(compositeView.frame.size.width/2 - 5, CGRectGetMaxY(titleLabel.frame)+8);
            
            //mem count label
            UILabel * countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(memIcon.frame), CGRectGetMaxY(titleLabel.frame)+4, 15, 10)];
            countLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            countLabel.text = [NSString stringByTruncatingInteger:self.memoryCount];
            countLabel.backgroundColor = [UIColor clearColor];
            countLabel.textAlignment = NSTextAlignmentLeft;
            countLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:8];
            countLabel.numberOfLines = 1;
            [compositeView addSubview:countLabel];

            //venue count label
            UILabel * venCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(6, 16, 19, 18)];
            venCountLabel.textColor = [UIColor whiteColor];
            venCountLabel.text = [NSString stringWithFormat:@"%@", @(self.venueCount)];
            venCountLabel.backgroundColor = [UIColor clearColor];
            venCountLabel.textAlignment = NSTextAlignmentCenter;
            venCountLabel.font = [UIFont spc_boldSystemFontOfSize:14];
            venCountLabel.numberOfLines = 1;
            [compositeView addSubview:venCountLabel];
        }
        
        else {
            
            compositeView.frame = CGRectMake(0,0, 100, 75);
            
            UIImage *pinBgImg = [UIImage imageNamed:@"blank-mini-multivenue-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 35);
            [compositeView addSubview:iconImageView];
            
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, CGRectGetMaxY(iconImageView.frame)+5, 45, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            titleLabel.center = CGPointMake(compositeView.frame.size.width/2, titleLabel.center.y);
            [compositeView addSubview:titleLabel];
            
            //venue count label
            UILabel * venCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 21, 19, 18)];
            venCountLabel.textColor = [UIColor whiteColor];
            venCountLabel.text = [NSString stringWithFormat:@"%@", @(self.venueCount)];
            venCountLabel.backgroundColor = [UIColor clearColor];
            venCountLabel.textAlignment = NSTextAlignmentCenter;
            venCountLabel.font = [UIFont spc_boldSystemFontOfSize:14];
            venCountLabel.numberOfLines = 1;
            [compositeView addSubview:venCountLabel];
        }
    
        // Render
        UIGraphicsBeginImageContextWithOptions(compositeView.bounds.size, NO, 0.0);
        [compositeView.layer renderInContext:UIGraphicsGetCurrentContext()];
        icon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
    }
    else {
        
        UIView *compositeView;
        
        if (self.memoryCount > 0) {
        
            compositeView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 55, 75)];
            
            UIImage *pinBgImg = [UIImage imageNamed:@"blank-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, compositeView.frame.size.height * .28);
            [compositeView addSubview:iconImageView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, CGRectGetMaxY(iconImageView.frame)+5, 45, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [compositeView addSubview:titleLabel];
            
            UIImageView *memIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-pin-memory"]];
            [compositeView addSubview:memIcon];
            memIcon.center = CGPointMake(22, 53);
            
            UILabel * countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(memIcon.frame), 49, 15, 10)];
            countLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            countLabel.text = [NSString stringByTruncatingInteger:self.memoryCount];
            countLabel.backgroundColor = [UIColor clearColor];
            countLabel.textAlignment = NSTextAlignmentLeft;
            countLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:8];
            countLabel.numberOfLines = 1;
            [compositeView addSubview:countLabel];
        }
        else {
            compositeView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 60)];
            
            UIImage *pinBgImg = [UIImage imageNamed:@"blank-mini-pin"];
            UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
            [compositeView addSubview:pinBgImgView];
            
            UIImage *iconImage;
            if (iconNameBase) {
                iconImage = [UIImage imageNamed:iconNameBase];
            }
            
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            iconImageView.backgroundColor = [UIColor clearColor];
            iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 20);
            [compositeView addSubview:iconImageView];
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(iconImageView.frame)+5, 40, 10)];
            titleLabel.text = self.title;
            titleLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:8];
            titleLabel.textColor = [UIColor colorWithRed:139.0f/255.0f green:153.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [compositeView addSubview:titleLabel];
        }
        
        
        // Render
        UIGraphicsBeginImageContextWithOptions(compositeView.bounds.size, NO, 0.0);
        [compositeView.layer renderInContext:UIGraphicsGetCurrentContext()];
        icon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return icon;
}

-(UIImage *)loadExploreIconWithMemoryImage:(UIImage *)memoryImage {
    
    //NSLog(@"loadExploreIcon");
    UIView *compositeView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 56, 77.5)];
    
    UIImage *pinBgImg = [UIImage imageNamed:@"blank-explore-pin"];
    UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
    [compositeView addSubview:pinBgImgView];
    
    UIView *iconImageViewCornerRounder = [[UIView alloc] initWithFrame:CGRectMake(3, 3, 50, 65)];
    iconImageViewCornerRounder.layer.cornerRadius = 1;
    iconImageViewCornerRounder.clipsToBounds = YES;
    iconImageViewCornerRounder.layer.masksToBounds = YES;
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    iconImageView.backgroundColor = [UIColor colorWithRed:153.0f/255.0f green:143.0f/255.0f blue:204.0f/255.0f alpha:1.0f];
    [iconImageViewCornerRounder addSubview:iconImageView];
    iconImageView.image = memoryImage;
    
    [compositeView addSubview:iconImageViewCornerRounder];
    
    UIImageView *starIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"star-gold-xx-small"]];
    [compositeView addSubview:starIcon];
    starIcon.center = CGPointMake(22, 60);
    
    UILabel * countLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(starIcon.frame)+3, 55, 15, 10)];
    countLabel.textColor = [UIColor colorWithRed:117.0f/255.0f green:132.0f/255.0f blue:152.0f/255.0f alpha:1.0];
    countLabel.text = [NSString stringByTruncatingInteger:self.starCount];
    countLabel.backgroundColor = [UIColor clearColor];
    countLabel.textAlignment = NSTextAlignmentLeft;
    countLabel.font = [UIFont spc_boldSystemFontOfSize:8];
    countLabel.numberOfLines = 1;
    [compositeView addSubview:countLabel];
    
    // Render
    UIImage *icon;
            
    UIGraphicsBeginImageContextWithOptions(compositeView.bounds.size, NO, 0.0);
    [compositeView.layer renderInContext:UIGraphicsGetCurrentContext()];
    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return icon;
}


-(UIImage *)getCreateVenueIconPlaceholder {
    return [UIImage imageNamed:@"blank-user-pin"];
}

-(UIImage *)loadCreateVenueIcon {
    
    //NSLog(@"loadExploreIcon");
    UIView *compositeView = [[UIView alloc] initWithFrame:CGRectMake(0,0, 55, 75)];
    
    UIImage *pinBgImg = [UIImage imageNamed:@"blank-user-pin"];
    UIImageView *pinBgImgView = [[UIImageView alloc] initWithImage:pinBgImg];
    [compositeView addSubview:pinBgImgView];
    
    UIImageView *iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 4, 40, 40)];
    iconImageView.backgroundColor = [UIColor colorWithRed:63.0f/255.0f green:85.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
    iconImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    iconImageView.layer.borderWidth = 3;
    iconImageView.layer.cornerRadius  = iconImageView.frame.size.width/2;
    iconImageView.center = CGPointMake(compositeView.frame.size.width/2, 30);
    iconImageView.clipsToBounds = YES;
    iconImageView.layer.masksToBounds = YES;
    iconImageView.image = [ContactAndProfileManager sharedInstance].profile.profileDetail.profileImg;
    
    [compositeView addSubview:iconImageView];
    
    UILabel * youLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 53, 55, 10)];
    youLabel.textColor = [UIColor whiteColor];
    youLabel.text = @"You";
    youLabel.backgroundColor = [UIColor clearColor];
    youLabel.textAlignment = NSTextAlignmentCenter;
    youLabel.font = [UIFont spc_boldSystemFontOfSize:8];
    youLabel.numberOfLines = 1;
    [compositeView addSubview:youLabel ];
    
    // Render
    UIImage *icon;
    
    UIGraphicsBeginImageContextWithOptions(compositeView.bounds.size, NO, 0.0);
    [compositeView.layer renderInContext:UIGraphicsGetCurrentContext()];
    icon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return icon;
}

-(CGPoint) markerGroundAnchor {
    return CGPointMake(0.5f, 0.97f);
}

-(CGPoint) markerInfoWindowAnchor {
    return CGPointMake(0.5, 0.0f);
}


#pragma mark - Accessors

- (BOOL)isOwnedByUser {
    for (Venue *venue in self.venues) {
        if (venue.isOwnedByUser) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)venueCount {
    return _venues.count;
}


- (Venue *)venueAt:(NSInteger)index {
    return _venues[index];
}


- (NSString *)titleForVenue:(Venue *)venue {
    if (venue) {
        NSString * displayName = venue.displayName;
        NSRange range = [displayName rangeOfString:@"," options:NSBackwardsSearch];
        if (range.location == NSNotFound) {
            return displayName;
        } else {
            return [venue.displayName substringToIndex:range.location];
        }
    } else if (self.isOriginalUserLocation) {
        return @"You are here";
    } else if (self.isCurrentUserLocation) {
        return @"Selected location";
    }
    return nil;
}


- (NSString *)subtitleForVenue:(Venue *)venue {
    if (venue) {
        if (self.isOriginalUserLocation && [SPCMapDataSource venue:venue is:self.venue]) {
            return @"You are here";
        } else if (self.isCurrentUserLocation && [SPCMapDataSource venue:venue is:self.venue]) {
            return @"Selected location";
        }
        NSRange range = [venue.displayName rangeOfString:@"," options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            return [venue.displayName substringFromIndex:(range.location + range.length + 1)];
        }
    }
    return nil;
}


- (NSString *)titleForVenueAt:(NSInteger)index {
    return [self titleForVenue:[self venueAt:index]];
}


- (NSString *)subtitleForVenueAt:(NSInteger)index {
    return [self subtitleForVenue:[self venueAt:index]];
}


@end



@interface SPCMapDataSource()

@property (nonatomic, strong) SPCGoogleMapInfoView *infoWindow;
@property (nonatomic, strong) SPCMarker *infoWindowMarker;
@property (nonatomic, strong) SPCMarkerVenueData *infoWindowVenueData;
@property (nonatomic, assign) NSInteger infoWindowStack;

@property (nonatomic, strong) UITableView *infoWindowTableView;

@end

@implementation SPCMapDataSource


- (SPCMapDataSource *)init {
    self = [super init];
    if (self) {
        self.stackedVenueType = StackedVenueTypeShowDeviceLocation;
        self.infoWindowType = InfoWindowTypeVenueSelection;
        self.mapMarkerStyle = MapMarkerStyleNormal;
        self.infoWindowConfirmationText = @"";
        self.infoWindowSelectText = @"Go";
        self.deviceVenueAlpha = 1.0f;
    }
    return self;
}



+ (BOOL)venue:(Venue *)venue is:(Venue *)venue2 {
    return venue && venue2
        && ((venue.locationId && venue2.locationId && venue.locationId == venue2.locationId)
            || ((venue.locationId <= 0 || venue2.locationId <= 0) && [venue.displayName isEqualToString:venue2.displayName]));
}

+ (BOOL)venue:(Venue *)venue isIdenticalTo:(Venue *)venue2 {
    return venue && venue2 && venue.locationId && venue.locationId == venue2.locationId && venue.totalMemories == venue2.totalMemories && venue.totalStars == venue2.totalStars && [venue.displayName isEqualToString:venue2.displayName] && [venue.latitude isEqualToNumber:venue2.latitude] && [venue.longitude isEqualToNumber:venue2.longitude];
}

+ (BOOL)userOwnsVenue:(Venue *)venue {
    return venue && venue.ownerId && venue.ownerId == [AuthenticationManager sharedInstance].currentUser.userId;
}

- (int)configureZIndexForMarker:(SPCMarker *)marker {
    if ([marker.userData isKindOfClass:[SPCMarkerVenueData class]]) {
        SPCMarkerVenueData *venueData = marker.userData;
        int zIndex = self.zIndexVenue;
        if (venueData.isCurrentUserLocation && venueData.isOriginalUserLocation) {
            zIndex = MAX(self.zIndexCurrent, self.zIndexDevice);
        } else if (venueData.isCurrentUserLocation) {
            zIndex = self.zIndexCurrent;
        } else if (venueData.isOriginalUserLocation) {
            zIndex = self.zIndexDevice;
        }
        marker.zIndex = zIndex;
    }
    return 0;
}

- (BOOL)setAsVenueStacksWithVenues:(NSArray *)venues atCurrentVenue:(Venue *)currentVenue deviceVenue:(Venue *)deviceVenue {
    
    // try to short-circuit
    if (!venues) {
        venues = [NSArray array];
    }
    
    if (_venues && _currentVenue && _deviceVenue) {
        BOOL same = YES;
        same = same && [SPCMapDataSource venue:_currentVenue is:currentVenue];
        same = same && [SPCMapDataSource venue:_deviceVenue is:deviceVenue];
        same = same && _venues.count == venues.count;
        for (int i = 0; i < venues.count && same; i++) {
            same = same && [SPCMapDataSource venue:_venues[i] is:venues[i]];
        }
        if (same) {
            return NO;
        }
    }
    
    //NSLog(@"Step 1: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    _venues = venues;
    _currentVenue = currentVenue;
    _deviceVenue = deviceVenue;
    
    
    // Stack the venues
    
    // Order the provided venues by prominence (then stars, then memories).
    // Iterate through the resulting list to form an array-of-arrays, with
    // each element representing a list of venues (in order of priority)
    // that exist within the same general spot (within STACK_WITHIN_METERS distance).
    
    NSArray *sortedVenues = [self sortVenuesByProminence:venues];
    
    //NSLog(@"Step 2: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    _currentVenueStack = -1;
    _deviceVenueStack = -1;
    
    // Now create the array-of-arrays
    NSMutableArray * stackedVenues = [[NSMutableArray alloc] init];
    NSMutableArray * venueStackNumber = [[NSMutableArray alloc] init];
    NSMutableArray * stackedMemories = [[NSMutableArray alloc] init];
    for (int i = 0; i < sortedVenues.count; i++) {
        
        Venue * venue = (Venue *)sortedVenues[i];
        
        //NSLog(@"stacking venue with location id %ld, display name %@, prominence %f, totalStars %d, totalMemories %d", (long)(venue.locationId), venue.displayName, venue.prominence, venue.totalStars, venue.totalMemories);
        
        // Venue location
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[[venue latitude] doubleValue]
                                                          longitude:[[venue longitude] doubleValue]];
        
        // check if w/in the stacking distance of any existing venue list.
        NSInteger stackNum = -1;
        for (int j = 0; j < stackedVenues.count && stackNum < 0; j++) {
            Venue * topVenue = ((NSArray *)stackedVenues[j])[0];
            // Venue location
            CLLocation *topLocation = [[CLLocation alloc] initWithLatitude:[[topVenue latitude] doubleValue]
                                                                 longitude:[[topVenue longitude] doubleValue]];
            
            if ([location distanceFromLocation:topLocation] < STACK_WITHIN_METERS) {
                // stack here
                [((NSMutableArray *)stackedVenues[j]) addObject:venue];
                stackedMemories[j] = @([((NSNumber *)stackedMemories[j]) integerValue] + venue.totalMemories);
                stackNum = j;
            }
        }
        
        if (stackNum < 0) {
            // a new stack
            [stackedVenues addObject:[@[venue] mutableCopy]];
            [stackedMemories addObject:@(venue.totalMemories)];
            stackNum = stackedVenues.count -1;
        }
        
        if ([SPCMapDataSource venue:venue is:_currentVenue]) {
            _currentVenueStack = stackNum;
        }
        
        if ([SPCMapDataSource venue:venue is:_deviceVenue]) {
            _deviceVenueStack = stackNum;
            _deviceVenue = venue;
            // HACK: update pointer to make sure we have current star / memory counts
        }

        [venueStackNumber addObject:@(stackNum)];
    }
    
    //NSLog(@"Step 3: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    // convert from mutable to immutable
    for (int i = 0; i < stackedVenues.count; i++) {
        stackedVenues[i] = [NSArray arrayWithArray:stackedVenues[i]];
    }
    _stackedVenues = [NSArray arrayWithArray:stackedVenues];
    _venueStack = [NSArray arrayWithArray:venueStackNumber];
    
    // sort the stacked memory counts: we use this to determine gold, silver
    // and bronze stars.
    NSArray * sortedStackedMemories = [stackedMemories sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"integerValue" ascending:NO]]];
    // Use selector, not indexing, in case we have a list of length 0.
    NSInteger goldMemories = sortedStackedMemories.count > 0 ? [sortedStackedMemories[0] integerValue] : 0;
    NSInteger silverMemories = sortedStackedMemories.count > 1 ? [sortedStackedMemories[1] integerValue] : 0;
    NSInteger bronzeMemories = sortedStackedMemories.count > 2 ? [sortedStackedMemories[2] integerValue] : 0;
    
    //NSLog(@"Step 4: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    // Construct markers for all these
    NSMutableArray * stackMarkers = [[NSMutableArray alloc] initWithCapacity:_stackedVenues.count];
    // Add venue markers
    [_stackedVenues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        // Create new marker object
        SPCMarker * marker;
        NSInteger options = 0;
        NSInteger memories = [stackedMemories[idx] integerValue];
        if (memories > 0) {
            if (memories == goldMemories) {
                options |= spc_VENUE_DATA_OPTION_STAR_GOLD;
            } else if (memories == silverMemories) {
                options |= spc_VENUE_DATA_OPTION_STAR_SILVER;
            } else if (memories == bronzeMemories) {
                options |= spc_VENUE_DATA_OPTION_STAR_BRONZE;
            }
        }
        if (self.stackedVenueType == StackedVenueTypeShowDeviceLocation) {
            if (idx == self.currentVenueStack && idx == self.deviceVenueStack) {
                options |= spc_VENUE_DATA_OPTION_USER_LOCATION_CURRENT & spc_VENUE_DATA_OPTION_USER_LOCATION_ORIGINAL;
            } else if (idx == self.deviceVenueStack) {
                options |= spc_VENUE_DATA_OPTION_USER_LOCATION_ORIGINAL;
            } else if (idx == self.currentVenueStack) {
                options |= spc_VENUE_DATA_OPTION_USER_LOCATION_CURRENT;
            } else {
                // no location options
            }
        } else if (self.stackedVenueType == StackedVenueTypeOmitDeviceLocation) {
            if (idx == self.currentVenueStack) {
                options |= spc_VENUE_DATA_OPTION_USER_LOCATION_CURRENT;
            } else {
                // no location options
            }
        }
        if (self.mapMarkerStyle == MapMarkerStyleEmphasizeOwned) {
            options |= spc_VENUE_DATA_OPTION_EMPHASIZE_OWNED;
        }
        marker = [SPCMarkerVenueData markerWithVenues:obj options:options];
        if (idx == self.currentVenueStack) {
            ((SPCMarkerVenueData *)marker.userData).venue = self.currentVenue;
        }
        
        if (marker) {
            [self configureZIndexForMarker:marker];
            [stackMarkers addObject:marker];
        }
    }];
    _stackedVenueMarkers = [NSArray arrayWithArray:stackMarkers];
    
    //NSLog(@"Step 5: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    // SET:
    // venues;
    // venueMarkers;
    // venueStack;
    
    // stackedVenues;
    // stackedVenueMarkers;
    
    // currentVenue;
    // deviceVenue;
    // currentVenueStack;
    // deviceVenueStack;
    
    // NOT YET SET:
    // currentVenueMarker;
    // deviceVenueMarker;
    // allMarkers;
    // ...and all "Location" markers
    
    if (_currentVenueStack > -1) {
        _currentVenueMarker = _stackedVenueMarkers[_currentVenueStack];
    } else {
        _currentVenueMarker = [SPCMarkerVenueData markerWithCurrentVenue:_currentVenue];
        [self configureZIndexForMarker:_currentVenueMarker];
    }
    if (_deviceVenueStack > -1) {
        _deviceVenueMarker = _stackedVenueMarkers[_deviceVenueStack];
    } else {
        CLLocation *stableLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
            stableLocation = [LocationManager sharedInstance].currentStableLocation;
        }
        _deviceVenueMarker = [SPCMarkerVenueData markerWithOriginalLocation:stableLocation venue:_deviceVenue];
        [self configureZIndexForMarker:_deviceVenueMarker];
    }
    
    //NSLog(@"Step 6: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    CLLocation *stableLocation = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        stableLocation = [LocationManager sharedInstance].currentStableLocation;
    }
    
    _deviceLocationMarker = [SPCMarkerVenueData markerWithOriginalLocation:stableLocation venue:self.deviceVenue ];
    _deviceLocationCurrentMarker = [SPCMarkerVenueData markerWithCurrentLocation:stableLocation venue:self.deviceVenue];
    [self configureZIndexForMarker:_deviceLocationMarker];
    [self configureZIndexForMarker:_deviceLocationCurrentMarker];
    
    //NSLog(@"Step 7: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    CLLocation * location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        location = [LocationManager sharedInstance].locationInUse;
    }
    _locationMarker = [SPCMarkerVenueData markerWithCurrentLocation:location venue:self.currentVenue];
    [self configureZIndexForMarker:_locationMarker];
    
    //NSLog(@"Step 8: %f seconds", [[NSDate date] timeIntervalSinceDate:date]);
    
    return YES;
}

- (NSArray *)sortVenuesByProminence:(NSArray *)venues {
    NSArray *sortDescriptors = @[
                                 [NSSortDescriptor sortDescriptorWithKey:@"prominence" ascending:NO],
                                 [NSSortDescriptor sortDescriptorWithKey:@"totalStars" ascending:NO],
                                 [NSSortDescriptor sortDescriptorWithKey:@"totalMemories" ascending:NO],
                                 [NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]
                                 ];
    
    return [venues sortedArrayUsingDescriptors:sortDescriptors];
}

- (NSArray *)venueStackAtVenue:(Venue *)venue {
    // make a stack at this location.
    NSMutableArray *stack = [[NSMutableArray alloc] init];
    [stack addObject:venue];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[[venue latitude] doubleValue]
                                                      longitude:[[venue longitude] doubleValue]];
    [self.venues enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Venue * v = (Venue *)obj;
        if (![SPCMapDataSource venue:venue is:v]) {
            CLLocation *vLocation = [[CLLocation alloc] initWithLatitude:[[v latitude] doubleValue]
                                                               longitude:[[v longitude] doubleValue]];
            
            if ([location distanceFromLocation:vLocation] < STACK_WITHIN_METERS) {
                [stack addObject:v];
            }
        }
    }];
    
    return [NSArray arrayWithArray:stack];
}

- (SPCMarker *)markerWithStackAtCurrentVenue:(Venue *)venue {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarker * marker = [SPCMarkerVenueData markerWithCurrentVenues:sortedVenues];
    ((SPCMarkerVenueData *)marker.userData).venue = nil;
    return marker;
}



- (SPCMarker *)markerWithStackAtVenue:(Venue *)venue {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarker * marker = [SPCMarkerVenueData markerWithVenues:sortedVenues];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
    return marker;
}

- (SPCMarker *)markerWithStackAtDeviceVenue:(Venue *)venue {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarker * marker = [SPCMarkerVenueData markerWithOriginalVenues:sortedVenues];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
    return marker;
}

- (SPCMarker *)markerWithStackAtDeviceAndCurrentVenue:(Venue *)venue {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarker * marker = [SPCMarkerVenueData markerWithOriginalAndCurrentVenues:sortedVenues];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
    return marker;
}

- (void)configureMarker:(SPCMarker *)marker withStackAtVenue:(Venue *)venue reposition:(BOOL)reposition {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:sortedVenues];
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:reposition];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
}

- (void)configureMarker:(SPCMarker *)marker withStackAtCurrentVenue:(Venue *)venue reposition:(BOOL)reposition {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:sortedVenues];
    venueData.isCurrentUserLocation = YES;
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:reposition];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
}

- (void)configureMarker:(SPCMarker *)marker withStackAtDeviceAndCurrentVenue:(Venue *)venue reposition:(BOOL)reposition {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:sortedVenues];
    venueData.isCurrentUserLocation = YES;
    venueData.isOriginalUserLocation = YES;
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:reposition];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
}


- (void)configureMarker:(SPCMarker *)marker withStackAtDeviceVenue:(Venue *)venue reposition:(BOOL)reposition {
    NSArray * sortedVenues = [self sortVenuesByProminence:[self venueStackAtVenue:venue]];
    SPCMarkerVenueData * venueData = [[SPCMarkerVenueData alloc] initWithVenues:sortedVenues];
    venueData.isOriginalUserLocation = YES;
    [SPCMarkerVenueData configureMarker:marker withVenueData:venueData reposition:reposition];
    ((SPCMarkerVenueData *)marker.userData).venue = venue;
}

- (CGFloat)infoWindowHeightForMarker:(SPCMarker *)marker mapView:(GMSMapView *)mapView {
    CGFloat rowHeight = [self tableView:nil heightForRowAtIndexPath:nil];
    SPCMarkerVenueData *venueData = marker.userData;
    CGFloat visibleRows = MIN(4, venueData.venueCount);
    CGFloat height = rowHeight * visibleRows;
    while (height + 50 > mapView.frame.size.height) {
        visibleRows--;
        height = rowHeight * visibleRows;
    }
    
    if (height <= 0) {
        return rowHeight;
    }
    if (visibleRows < venueData.venueCount || visibleRows > 3) {
        height -= rowHeight * 0.4;
    }
    
    return height;
}

- (UIView *)getInfoWindowForMarker:(SPCMarker *)marker mapView:(GMSMapView *)mapView {
    if (self.infoWindowType == InfoWindowTypeVenueSelection) {
        return [self getInfoWindowWithSelection:YES forMarker:marker mapView:mapView];
    } else if (self.infoWindowType == InfoWindowTypeVenueSelectionOwned) {
        // allow selection if any venue here is owned by the user
        BOOL owned = NO;
        SPCMarkerVenueData * venueData = marker.userData;
        for (Venue * venue in venueData.venues) {
            owned = owned || [SPCMapDataSource userOwnsVenue:venue];
        }
        return [self getInfoWindowWithSelection:owned forMarker:marker mapView:mapView];
    } else if (self.infoWindowType == InfoWindowTypeVenueInformation) {
        return [self getInfoWindowWithSelection:NO forMarker:marker mapView:mapView];
    } else if (self.infoWindowType == InfoWindowTypeVenueConfirmation) {
        return [self getInfoWindowWithConfirmationForMarker:marker mapView:mapView];
    }
    
    return nil;
}


- (UIView *)getInfoWindowWithSelection:(BOOL)selection forMarker:(SPCMarker *)marker mapView:(GMSMapView *)mapView {
    self.infoWindowMarker = marker;
    self.infoWindowVenueData = (SPCMarkerVenueData *)marker.userData;
    // find the stack
    self.infoWindowStack = -1;
    for (int i = 0; i < self.stackedVenueMarkers.count; i++) {
        if (self.stackedVenueMarkers[i] == marker) {
            self.infoWindowStack = i;
        }
    }
    
    // Put it in a table
    CGFloat tableHeight = [self infoWindowHeightForMarker:marker mapView:mapView];
    BOOL canScroll = self.infoWindowVenueData.venueCount * [self tableView:nil heightForRowAtIndexPath:nil] > tableHeight;
    CGFloat tableWidth = CGRectGetWidth(mapView.frame) - 30.0;
    if (!selection) {
        //tableWidth -= SELECT_BUTTON_WIDTH;
    }
    if (!self.infoWindowTableView) {
        self.infoWindowTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableWidth, tableHeight)];
        self.infoWindowTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.infoWindowTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        self.infoWindowTableView.frame = CGRectMake(0.0, 0.0, tableWidth, tableHeight);
    }
    self.infoWindowTableView.scrollEnabled = canScroll;
    self.infoWindowTableView.allowsSelection = NO;
    self.infoWindowTableView.dataSource = self;
    self.infoWindowTableView.delegate = self;
    
    [self.infoWindowTableView reloadData];
    
    [self.infoWindow setContentView:self.infoWindowTableView withEdgeInsets:UIEdgeInsetsZero];
    return self.infoWindow;
}

- (UIView *)getInfoWindowWithConfirmationForMarker:(SPCMarker *)marker mapView:(GMSMapView *)mapView {
    self.infoWindowMarker = marker;
    self.infoWindowVenueData = (SPCMarkerVenueData *)marker.userData;
    // find the stack
    self.infoWindowStack = -1;
    for (int i = 0; i < self.stackedVenueMarkers.count; i++) {
        if (self.stackedVenueMarkers[i] == marker) {
            self.infoWindowStack = i;
        }
    }
    
    // Put it in a table
    CGFloat tableHeight = [self infoWindowHeightForMarker:marker mapView:mapView];
    BOOL canScroll = self.infoWindowVenueData.venueCount > 3;
    CGFloat tableWidth = CGRectGetWidth(mapView.frame) - 25.0;
    if (!self.infoWindowTableView) {
        self.infoWindowTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableWidth, tableHeight)];
        self.infoWindowTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.infoWindowTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        self.infoWindowTableView.frame = CGRectMake(0.0, 0.0, tableWidth, tableHeight);
    }
    self.infoWindowTableView.scrollEnabled = canScroll;
    self.infoWindowTableView.allowsSelection = NO;
    self.infoWindowTableView.dataSource = self;
    self.infoWindowTableView.delegate = self;
    
    [self.infoWindowTableView reloadData];
    
    [self.infoWindow setContentView:self.infoWindowTableView withEdgeInsets:UIEdgeInsetsZero];
    return self.infoWindow;
}



- (void)refreshInfoWindowForMarker:(SPCMarker *)marker {
    NSLog(@"refreshInfoWindowForMarker %@", marker);
    if (self.infoWindowMarker && self.infoWindowMarker == marker) {
        NSLog(@"info window is currenly open!  reloading data");
        self.infoWindowVenueData = (SPCMarkerVenueData *)marker.userData;
        [self.infoWindowTableView reloadData];
    }
}

- (SPCGoogleMapInfoView *)infoWindow {
    if (!_infoWindow) {
        _infoWindow = [[SPCGoogleMapInfoView alloc] init];
    }
    return _infoWindow;
}

#pragma mark - UITableView delagate / data source methods

NSInteger TAG_SEPARATOR = 98;
NSInteger TAG_IMAGE_VIEW = 99;
NSInteger TAG_RIGHT_BUTTON = 100;
NSInteger TAG_TITLE = 101;
NSInteger TAG_SUBTITLE = 102;
NSInteger TAG_STARS = 103;
NSInteger TAG_MEMORIES = 104;
NSInteger TAG_CONFIRM_BUTTON = 105;
NSInteger TAG_CANCEL_BUTTON = 106;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.infoWindowType == InfoWindowTypeVenueSelection) {
        return [self tableView:tableView cellForSelection:YES withRowAtIndexPath:indexPath];
    } else if (self.infoWindowType == InfoWindowTypeVenueSelectionOwned) {
        Venue * venue = indexPath.row < self.infoWindowVenueData.venueCount ? self.infoWindowVenueData.venues[indexPath.row] : nil;
        return [self tableView:tableView cellForSelection:[SPCMapDataSource userOwnsVenue:venue] withRowAtIndexPath:indexPath];
    } else if (self.infoWindowType == InfoWindowTypeVenueInformation) {
        return [self tableView:tableView cellForSelection:NO withRowAtIndexPath:indexPath];
    } else if (self.infoWindowType == InfoWindowTypeVenueConfirmation) {
        return [self tableView:tableView cellForConfirmationWithRowAtIndexPath:indexPath];
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForSelection:(BOOL)selection withRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 70.0;
    CGFloat width = CGRectGetWidth(tableView.frame);
    if (indexPath.row >= self.infoWindowVenueData.venueCount) {
        // "Drag to reposition"
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SPCMapDataSourceDragToRepositionCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPCMapDataSourceDragToRepositionCell"];
            cell.backgroundColor = [UIColor whiteColor];
            
            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.tag = TAG_TITLE;
            titleLabel.font = [UIFont spc_mediumFont];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor blackColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:titleLabel];
        }
        
        UILabel * titleLabel = (UILabel *)[cell.contentView viewWithTag:TAG_TITLE];
        titleLabel.frame = CGRectMake(0.0, 0.0, width, height);
        titleLabel.text = @"Drag to Reposition";
        
        return cell;
    } else {
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SPCMapDataSourceSelectionCalloutCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPCMapDataSourceSelectionCalloutCell"];
            cell.backgroundColor = [UIColor whiteColor];
            
            UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0.5)];
            separatorView.tag = TAG_SEPARATOR;
            separatorView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
            [cell.contentView addSubview:separatorView];
            
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.tag = TAG_IMAGE_VIEW;
            imageView.layer.cornerRadius = 23;
            imageView.clipsToBounds = YES;
            imageView.contentMode = UIViewContentModeCenter;
            [cell.contentView addSubview:imageView];
            
            UIButton *rightCalloutButton = [[UIButton alloc] init];
            rightCalloutButton.tag = TAG_RIGHT_BUTTON;
            rightCalloutButton.backgroundColor = [UIColor colorWithRGBHex:0xebebeb];
            [rightCalloutButton.titleLabel setFont:[UIFont spc_mediumFont]];
            [rightCalloutButton setTitle:NSLocalizedString(self.infoWindowSelectText, nil) forState:UIControlStateNormal];
            [rightCalloutButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [rightCalloutButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
            //[rightCalloutButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(calloutAccessoryControlTapped:)]];
            [rightCalloutButton addTarget:self action:@selector(selectButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            rightCalloutButton.layer.cornerRadius = 2;
            rightCalloutButton.clipsToBounds = YES;
            [cell.contentView addSubview:rightCalloutButton];
            
            
            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.tag = TAG_TITLE;
            titleLabel.font = [UIFont spc_mediumFont];
            titleLabel.backgroundColor = [UIColor whiteColor];
            titleLabel.textColor = [UIColor colorWithRGBHex:0x646464];
            [cell.contentView addSubview:titleLabel];
            
            UILabel *subtitleLabel = [[UILabel alloc] init];
            subtitleLabel.tag = TAG_SUBTITLE;
            subtitleLabel.font = [UIFont spc_regularFont];
            subtitleLabel.backgroundColor = [UIColor clearColor];
            subtitleLabel.textColor = [UIColor colorWithRGBHex:0xa8a8a8];
            [cell.contentView addSubview:subtitleLabel];
            
            UILabel *starsLabel = [[UILabel alloc] init];
            starsLabel.tag = TAG_STARS;
            starsLabel.font = [UIFont spc_map_subtitleFont];
            starsLabel.backgroundColor = [UIColor clearColor];
            starsLabel.textColor = [UIColor colorWithRGBHex:0xa8a8a8];
            starsLabel.minimumScaleFactor = 0.8;
            [cell.contentView addSubview:starsLabel];
            
            UILabel *memoriesLabel = [[UILabel alloc] init];
            memoriesLabel.tag = TAG_MEMORIES;
            memoriesLabel.font = [UIFont spc_map_subtitleFont];
            memoriesLabel.backgroundColor = [UIColor clearColor];
            memoriesLabel.textColor = [UIColor colorWithRGBHex:0xa8a8a8];
            memoriesLabel.minimumScaleFactor = 0.8;
            [cell.contentView addSubview:memoriesLabel];
        }
        
        UIView *separatorView = [cell.contentView viewWithTag:TAG_SEPARATOR];
        UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:TAG_IMAGE_VIEW];
        UIButton *rightCalloutButton = (UIButton *)[cell.contentView viewWithTag:TAG_RIGHT_BUTTON];
        UILabel * titleLabel = (UILabel *)[cell.contentView viewWithTag:TAG_TITLE];
        UILabel * subtitleLabel = (UILabel *)[cell.contentView viewWithTag:TAG_SUBTITLE];
        UILabel * starsLabel = (UILabel *)[cell.contentView viewWithTag:TAG_STARS];
        UILabel * memoriesLabel = (UILabel *)[cell.contentView viewWithTag:TAG_MEMORIES];
        
        NSInteger index = indexPath.row;
        
        // used to determine which button the user clicked
        cell.contentView.tag = index;
        
        separatorView.hidden = (index == 0);
        
        // Update values
        imageView.backgroundColor = [SPCVenueTypes colorForVenue:[self.infoWindowVenueData venueAt:index]];
        imageView.image = [SPCVenueTypes imageForVenue:[self.infoWindowVenueData venueAt:index] withIconType:VenueIconTypeIconNewColor];
        titleLabel.text = [self.infoWindowVenueData titleForVenueAt:index];
        subtitleLabel.text = [self.infoWindowVenueData subtitleForVenueAt:index];
        starsLabel.text = [self.infoWindowVenueData venueAt:index] ? [self.infoWindowVenueData venueAt:index].displayStarsCountString : nil;
        memoriesLabel.text = [self.infoWindowVenueData venueAt:index] ? [self.infoWindowVenueData venueAt:index].displayMemoriesCountString : nil;
        
        // Update layout
        CGFloat buttonWidth = selection ? SELECT_BUTTON_WIDTH : 0.0;
        rightCalloutButton.frame = CGRectMake(0.0, 0.0, buttonWidth, SELECT_BUTTON_HEIGHT);
        rightCalloutButton.center = CGPointMake(width - 10 - buttonWidth/2.0, height/2.0);
        
        CGFloat buttonSpacingWidth = buttonWidth ? buttonWidth + 20.0 : 0.0;
        
        BOOL showsStars = starsLabel.text.length > 0;
        BOOL showsMemories = memoriesLabel.text.length > 0;
        
        imageView.frame = CGRectMake(12.0, 12.0, 46.0, 46.0);
        titleLabel.frame = CGRectMake(CGRectGetMaxX(imageView.frame) + 10.0, 11.0, width - buttonSpacingWidth - CGRectGetMaxX(imageView.frame) - 20, titleLabel.font.lineHeight);
        subtitleLabel.frame = CGRectMake(CGRectGetMaxX(imageView.frame) + 10.0, height/2.0 - subtitleLabel.font.lineHeight / 2.0 - 1.0, titleLabel.frame.size.width, subtitleLabel.font.lineHeight);
        
        if (showsStars) {
            CGFloat maxWidth = CGRectGetWidth(subtitleLabel.frame) / 2.0 - 6.0;
            CGRect boundingRect = [starsLabel.text boundingRectWithSize:CGSizeMake(320.0, starsLabel.font.lineHeight) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{ NSFontAttributeName: starsLabel.font } context:nil];
            CGFloat w = MIN(maxWidth, boundingRect.size.width);
            
            starsLabel.frame = CGRectMake(CGRectGetMinX(subtitleLabel.frame), CGRectGetMaxY(subtitleLabel.frame) + 1.0, w, starsLabel.font.lineHeight);
        }
        if (showsMemories) {
            CGFloat maxWidth = CGRectGetWidth(subtitleLabel.frame) - (showsStars ? starsLabel.frame.size.width : 0) - 6.0;
            CGRect boundingRect = [memoriesLabel.text boundingRectWithSize:CGSizeMake(320.0, memoriesLabel.font.lineHeight) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{ NSFontAttributeName: memoriesLabel.font } context:nil];
            CGFloat w = MIN(maxWidth, boundingRect.size.width);
            
            CGFloat horizontalOffset = (showsStars) ? 12.0 : 0.0;
            memoriesLabel.frame = CGRectMake(CGRectGetMinX(subtitleLabel.frame) + CGRectGetWidth(starsLabel.frame) + horizontalOffset, CGRectGetMaxY(subtitleLabel.frame) + 1.0, w, memoriesLabel.font.lineHeight);
        }
        
        return cell;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForConfirmationWithRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = 80;
    CGFloat width = CGRectGetWidth(tableView.frame);
    if (indexPath.row >= self.infoWindowVenueData.venueCount) {
        // "Drag to reposition"
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SPCMapDataSourceDragToRepositionCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPCMapDataSourceDragToRepositionCell"];
            cell.backgroundColor = [UIColor whiteColor];
            
            UILabel *titleLabel = [[UILabel alloc] init];
            titleLabel.tag = TAG_TITLE;
            titleLabel.font = [UIFont spc_mediumFont];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.textColor = [UIColor blackColor];
            titleLabel.textAlignment = NSTextAlignmentCenter;
            [cell.contentView addSubview:titleLabel];
        }
        
        UILabel * titleLabel = (UILabel *)[cell.contentView viewWithTag:TAG_TITLE];
        titleLabel.frame = CGRectMake(0.0, 0.0, width, height);
        titleLabel.text = @"Drag to Reposition";
        
        return cell;
    } else {
        CGFloat buttonWidth = 60.0f;
        CGFloat buttonEdge = CGRectGetWidth(tableView.frame) - buttonWidth;
        
        UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"SPCMapDataSourceConfirmationCalloutCell"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SPCMapDataSourceConfirmationCalloutCell"];
            cell.backgroundColor = [UIColor whiteColor];
            
            UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 0.5)];
            separatorView.tag = TAG_SEPARATOR;
            separatorView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
            [cell.contentView addSubview:separatorView];
            
            // Create new location prompt text?
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 15.0, buttonEdge - 24.0, 15)];
            label.tag = TAG_TITLE;
            label.numberOfLines = 1;
            label.text = @"Create new location here?";
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = NSTextAlignmentLeft;
            label.textColor = [UIColor colorWithRed:161.0/255.0 green:170.0/255.0 blue:174.0/255.0 alpha:1.0];
            label.font = [UIFont spc_mediumSystemFontOfSize:14];
            [cell.contentView addSubview:label];
            
            // TODO: address label config?
            UILabel * addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 37, buttonEdge - 24.0, 20)];
            addressLabel.tag = TAG_SUBTITLE;
            addressLabel.numberOfLines = 1;
            addressLabel.text = @"...";
            addressLabel.backgroundColor = [UIColor clearColor];
            addressLabel.textAlignment = NSTextAlignmentLeft;
            addressLabel.textColor = [UIColor colorWithRed:106.0/255.0 green:177.0/255.0 blue:251.0/255.0 alpha:1.0];
            addressLabel.font = [UIFont spc_mediumSystemFontOfSize:14];
            [cell.contentView addSubview:addressLabel];
            
            // Buttons?
            UIButton * buttonConfirm = [[UIButton alloc] initWithFrame:CGRectMake(buttonEdge, 0.0, buttonWidth, 40.0)];
            buttonConfirm.tag = TAG_CONFIRM_BUTTON;
            [buttonConfirm setTitle:@"YES" forState:UIControlStateNormal];
            [buttonConfirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            buttonConfirm.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:15];
            buttonConfirm.backgroundColor = [UIColor colorWithRed:155.0/255.0 green:202.0/255.0 blue:62.0/255.0 alpha:1.0];
            [buttonConfirm addTarget:self action:@selector(confirmButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:buttonConfirm];
            
            UIButton * buttonCancel = [[UIButton alloc] initWithFrame:buttonConfirm.frame];
            buttonCancel.tag = TAG_CANCEL_BUTTON;
            buttonCancel.frame = CGRectOffset(buttonCancel.frame, 0, 40.0);
            [buttonCancel setTitle:@"NO" forState:UIControlStateNormal];
            [buttonCancel setTitleColor:[UIColor colorWithRed:136.0/255.0 green:146.0/255.0 blue:151.0/255.0 alpha:1.0] forState:UIControlStateNormal];
            buttonCancel.titleLabel.font = [UIFont spc_mediumSystemFontOfSize:15];
            buttonCancel.backgroundColor = [UIColor colorWithRed:241.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0];
            [buttonCancel addTarget:self action:@selector(cancelButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:buttonCancel];
        }
        
        UIView *separatorView = [cell.contentView viewWithTag:TAG_SEPARATOR];
        
        UILabel * label = (UILabel *)[cell.contentView viewWithTag:TAG_TITLE];
        UILabel * addressLabel = (UILabel *)[cell.contentView viewWithTag:TAG_SUBTITLE];
        
        UIButton * confirmButton = (UIButton *)[cell.contentView viewWithTag:TAG_CONFIRM_BUTTON];
        UIButton * cancelButton = (UIButton *)[cell.contentView viewWithTag:TAG_CANCEL_BUTTON];
        
        NSInteger index = indexPath.row;
        
        // used to determine which button the user clicked
        cell.contentView.tag = index;
        
        separatorView.hidden = (index == 0);
        
        Venue * venue = [self.infoWindowVenueData venueAt:index];
        NSString * addressLine;
        if (venue.venueName) {
            addressLine = venue.venueName;
        } else if (venue.streetAddress) {
            addressLine = venue.streetAddress;
        } else {
            addressLine = [self.infoWindowVenueData titleForVenueAt:index];
        }
        
        // Update values
        label.text = self.infoWindowConfirmationText;
        addressLabel.text = addressLine;
        
        // Update layouts
        if (self.infoWindowVenueData.venueCount == 1) {
            confirmButton.frame = CGRectMake(buttonEdge, 0.0, buttonWidth, 40.0);
            cancelButton.frame = CGRectOffset(confirmButton.frame, 0, 40);
            cancelButton.hidden = NO;
            cancelButton.enabled = YES;
        } else {
            confirmButton.frame = CGRectMake(buttonEdge, 0.0, buttonWidth, 80.0);
            cancelButton.hidden = YES;
            cancelButton.enabled = NO;
        }
        
        if (venue.addressId) {
            confirmButton.alpha = 1.0;
            confirmButton.enabled = YES;
        } else {
            confirmButton.alpha = 0.5;
            confirmButton.enabled = NO;
        }
        
        return cell;
    }
}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.infoWindowVenueData.venueCount + (self.infoWindowMarker.draggable ? 1 : 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.infoWindowType == InfoWindowTypeVenueSelection) {
        return 70.0;
    } else if (self.infoWindowType == InfoWindowTypeVenueSelectionOwned) {
        return 70.0;
    } else if (self.infoWindowType == InfoWindowTypeVenueInformation) {
        return 66.0;
    } else if (self.infoWindowType == InfoWindowTypeVenueConfirmation) {
        return 80.0;
    }
    
    return 80.0;
}

- (void)selectButtonTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger index = button.superview.tag;
    Venue * venue = [self.infoWindowVenueData venueAt:index];
    if ([self.delegate respondsToSelector:@selector(userDidSelectVenue:fromStack:withMarker:)]) {
        [self.delegate userDidSelectVenue:venue fromStack:self.infoWindowStack withMarker:self.infoWindowMarker];
    }
}

- (void)confirmButtonTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger index = button.superview.tag;
    Venue * venue = [self.infoWindowVenueData venueAt:index];
    if ([self.delegate respondsToSelector:@selector(userDidConfirmVenue:fromStack:withMarker:)]) {
        [self.delegate userDidConfirmVenue:venue fromStack:self.infoWindowStack withMarker:self.infoWindowMarker];
    }
}

- (void)cancelButtonTapped:(id)sender {
    UIButton *button = (UIButton *)sender;
    NSInteger index = button.superview.tag;
    Venue * venue = [self.infoWindowVenueData venueAt:index];
    if ([self.delegate respondsToSelector:@selector(userDidCancelVenue:fromStack:withMarker:)]) {
        [self.delegate userDidCancelVenue:venue fromStack:self.infoWindowStack withMarker:self.infoWindowMarker];
    }
}


@end
