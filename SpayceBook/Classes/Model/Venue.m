//
//  Venue.m
//  Spayce
//
//  Created by Christopher Taylor on 1/19/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//



#import "Venue.h"
#import "TranslationUtils.h"
#import "MeetManager.h"
#import "Memory.h"
#import "Asset.h"
#import "AuthenticationManager.h"
#import "User.h"
#import "SPCVenueTypes.h"
#import "LocationManager.h"
#import "Enums.h"

// Category
#import "NSDate+SPCAdditions.h"

@implementation Venue

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        if ([attributes respondsToSelector:@selector(objectForKey:)]){
            _defaultName = (NSString *)[TranslationUtils valueOrNil:attributes[@"name"]];
            if (_defaultName.length < 1){
                _defaultName = (NSString *)[TranslationUtils valueOrNil:attributes[@"locationName"]];
            }
            if (_defaultName.length < 1){
                _defaultName = (NSString *)[TranslationUtils valueOrNil:attributes[@"addressName"]];
            }
            if (_defaultName.length < 1){
                _defaultName = (NSString *)[TranslationUtils valueOrNil:attributes[@"displayName"]];
            }
            _customName = (NSString *)[TranslationUtils valueOrNil:attributes[@"customLocationName"]];
            _latitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"latitude"]];
            _longitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"longitude"]];
            _distance = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"distance"]];
            _imageAsset = [Asset assetFromDictionary:attributes withAssetKey:@"locationMainPhotoAssetInfo" assetIdKey:@"locationMainPhotoAssetID"];
            _bannerAsset = [Asset assetFromDictionary:attributes withAssetKey:@"bannerAssetInfo" assetIdKey:@"bannerAssetID"];
            
            _addressId = [TranslationUtils integerValueFromDictionary:attributes withKey:@"addressId"];
            if (_addressId == 0) {
                _addressId = [TranslationUtils integerValueFromDictionary:attributes withKey:@"id"];
            }
            _addressKey = (NSString *)[TranslationUtils valueOrNil:attributes[@"addressKey"]];
            _locationId = [TranslationUtils integerValueFromDictionary:attributes withKey:@"locationId"];
          
            NSString *specificity = (NSString *)[TranslationUtils valueOrNil:attributes[@"specificity"]];
            _specificity = SPCVenueIsReal;
            
            if ([specificity isEqualToString:@"NEIGHBORHOOD"]) {
                _specificity = SPCVenueIsFuzzedToNeighhborhood;
            }
            if ([specificity isEqualToString:@"CITY"]) {
                _specificity = SPCVenueIsFuzzedToCity;
            }
            
            _userIsWithin =  [TranslationUtils booleanValueFromDictionary:attributes withKey:@"userIsWithin"];
            
            _locationKey = (NSString *)[TranslationUtils valueOrNil:attributes[@"locationKey"]];
            _prominence = [(NSNumber *)[TranslationUtils valueOrNil:attributes[@"prominence"]] floatValue];
            if (attributes[@"totalMemories"]) {
                _totalMemories = [TranslationUtils integerValueFromDictionary:attributes withKey:@"totalMemories"];
            } else {
                _totalMemories = 0;
            }
            if (attributes[@"userMemories"]) {
                _totalUserMemories = [TranslationUtils integerValueFromDictionary:attributes withKey:@"userMemories"];
            } else {
                _totalUserMemories = 0;
            }
            if (attributes[@"totalStars"]) {
                _totalStars = [TranslationUtils integerValueFromDictionary:attributes withKey:@"totalStars"];
            } else {
                _totalStars = 0;
            }
            
            if (!_addressId) {
                float locLat = [_latitude floatValue];
                float locLong = [_longitude floatValue];
                //NSLog(@"inializing addressId for venue");
                [MeetManager fetchDefaultLocationNameWithLat:locLat longitude:locLong
                                              resultCallback:^(NSDictionary *resultsDic) {
                                                  if (resultsDic[@"addressId"]){
                                                      _addressId = [TranslationUtils integerValueFromDictionary:resultsDic withKey:@"addressId"];
                                                  }
                                              }
                                               faultCallback:^(NSError *fault) {
                                               }];
            }
            
            _venueName = (NSString *)[TranslationUtils valueOrNil:attributes[@"venueName"]];
            _venueTypes = (NSArray *)[TranslationUtils valueOrNil:attributes[@"venueTypes"]];
            _streetAddress = (NSString *)[TranslationUtils valueOrNil:attributes[@"streetAddress"]];
            _neighborhood = (NSString *)[TranslationUtils valueOrNil:attributes[@"neighborhood"]];
            _city = (NSString *)[TranslationUtils valueOrNil:attributes[@"city"]];
            _state = (NSString *)[TranslationUtils valueOrNil:attributes[@"state"]];
            _county = (NSString *)[TranslationUtils valueOrNil:attributes[@"county"]];
            _postalCode = (NSString *)[TranslationUtils valueOrNil:attributes[@"postalCode"]];
            _country = (NSString *)[TranslationUtils valueOrNil:attributes[@"country"]];
            
            _hasStaleAddress = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"hasStaleAddress"];
            _hasStaleVenue = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"hasStaleVenue"];
            
            _addressLatitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"addressLatitude"]];
            _addressLongitude = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"addressLongitude"]];
            
            NSNumber *isFavorited = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"isFavorite"]];
            _favorited = isFavorited && [isFavorited integerValue] != 0;
          
            // featuredTime is in milliseconds since epoch
            NSNumber *featuredTime = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"featuredTime"]];
            // _featuredTime needs to be calculated from seconds since epoch
            _featuredTime = [NSDate dateWithTimeIntervalSince1970:[featuredTime longLongValue] / 1000.0];
            _timeElapsedSinceFeatured = [NSDate formattedMediumDateStringWithDate:_featuredTime];
          
            _ownerId = [TranslationUtils integerValueFromDictionary:attributes withKey:@"ownerId"];
            
            if (_distance == 0) {
                [self calculateDistFromLatLong];
            }
            
            [self initPopularMemoriesWithAttributes:attributes];
            [self initRecentHashTagMemoriesWithAttributes:attributes];
        }
        else {
            _defaultName = @"Parsing Issues";
            _customName = @"Parsing Issues";
            _latitude = @0;
            _longitude = @0;
            _imageAsset = nil;
            _totalMemories = 0;
            _totalStars = 0;
            
            _ownerId = 0;
        }
    }
    return self;
}

-(void)initPopularMemoriesWithAttributes:(NSDictionary *)attributes {
    NSDictionary * memoriesDict = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"popularMemories"]];
    if (!memoriesDict) {
        return;
    }
    NSArray * memoriesArray = (NSArray *)[TranslationUtils valueOrNil:memoriesDict[@"memories"]];
    if (!memoriesArray) {
        return;
    }
    NSMutableArray * memories = [[NSMutableArray alloc] initWithCapacity:memoriesArray.count];
    for (int i = 0; i < memoriesArray.count; i++) {
        [memories addObject:[Memory memoryWithAttributes:memoriesArray[i]]];
    }
    // sort
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    _popularMemories = [memories sortedArrayUsingDescriptors:@[sort]];
}


-(void)initRecentHashTagMemoriesWithAttributes:(NSDictionary *)attributes {
    NSDictionary * memoriesDict = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"recentHashtagMemories"]];
    if (!memoriesDict) {
        return;
    }
    NSArray * memoriesArray = (NSArray *)[TranslationUtils valueOrNil:memoriesDict[@"memories"]];
    if (!memoriesArray) {
        return;
    }
    
    NSMutableArray *mutableMemories = [NSMutableArray arrayWithCapacity:memoriesArray.count];
    
    for (NSDictionary *attributes in memoriesArray) {
        [mutableMemories addObject:[Memory memoryWithAttributes:attributes]];
    }
    
    _recentHashtagMemories = [NSArray arrayWithArray:mutableMemories];
}

-(Asset *)bestImageAsset {
    if (_popularMemories) {
        for (Memory *memory in _popularMemories) {
            if ([memory isKindOfClass:[ImageMemory class]]) {
                return ((ImageMemory *)memory).images[0];
            }
        }
    }
    
    return self.imageAsset;
}

-(Memory *)bestImageAssetMemory {
    if (_popularMemories) {
        for (Memory *memory in _popularMemories) {
            if ([memory isKindOfClass:[ImageMemory class]]) {
                return memory;
            }
        }
    }
    
    return nil;
}

-(void)calculateDistFromLatLong {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
        CLLocationDistance metersAway = [self.location distanceFromLocation:[LocationManager sharedInstance].currentLocation];
        [self updateDistance:metersAway];
    }
}

-(void)updateDistance:(double)dist {
    _distanceAway = dist;
}

-(void)updateScore {
    
    _venueProximityScore = 0;
    
    //Adjust for proximity
  
    if (self.distanceAway > 40) {
        _venueProximityScore = _venueProximityScore - 2;
    }
    if (self.distanceAway > 60) {
        _venueProximityScore = _venueProximityScore - 2;
    }
    
    if (self.distanceAway < 20) {
        _venueProximityScore = _venueProximityScore + 2;
    }
    if (self.distanceAway < 5) {
        _venueProximityScore = _venueProximityScore + 2;
    }
    
    //Adjust for custom / favs / real venues
    
    if (self.isOwnedByUser) {
        _venueProximityScore = _venueProximityScore + 10;
    }
    if (self.isOwnedByUserFriend) {
        _venueProximityScore = _venueProximityScore + 8;
    }
    if (self.isRealVenue) {
        _venueProximityScore = _venueProximityScore + 1;
    }
    
    //Adjust for user's memories
    
    if (self.totalUserMemories > 0) {
        _venueProximityScore = _venueProximityScore + 3;
    }
    if (self.totalUserMemories > 2) {
        _venueProximityScore = _venueProximityScore + 5;
    }
    if (self.totalUserMemories > 5) {
        _venueProximityScore = _venueProximityScore + 5;
    }
    
    //Adjust for other people's memories
    
    if (self.totalMemories > 0) {
        _venueProximityScore = _venueProximityScore + 2;
    }
    if (self.totalMemories > 3) {
        _venueProximityScore = _venueProximityScore + 2;
    }
    if (self.totalMemories > 10) {
        _venueProximityScore = _venueProximityScore + 2;
    }
    
    // Adjust for Venue Types
    
    // TODO !!  Rework for all of the new types.
}


#pragma mark - Accessors
    
- (CLLocation *)location
{
    if (self.latitude && self.longitude) {
        return [[CLLocation alloc] initWithLatitude:[self.latitude doubleValue]
                                          longitude:[self.longitude doubleValue]];
    } else {
        return nil;
    }
}

- (NSString *)displayName {
    if (self.customName) {
        return self.customName;
    }
    return self.defaultName;
}

- (NSString *)displayNameTitle {
    if (self.venueName) {
        return self.venueName;
    } else if (self.streetAddress) {
        return self.streetAddress;
    }
    
    NSString * disp = self.displayName;
    if ([disp rangeOfString:@","].location != NSNotFound) {
        NSString *title = [disp componentsSeparatedByString:@","][0];
        return [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    } else {
        return [disp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
}

- (NSString *)displayNameSubtitle {
    NSString * disp = self.displayName;
    if ([disp rangeOfString:@","].location != NSNotFound) {
        NSArray *components = [disp componentsSeparatedByString:@","];
        NSString *subtitle = components[components.count -1];
        return [subtitle stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    } else {
        return nil;
    }
}

- (NSString *)displayMemoriesCountString {
    if (self.totalMemories > 0) {
        NSString *memoryString = (self.totalMemories > 1) ? NSLocalizedString(@"memories", nil) : NSLocalizedString(@"memory", nil);
        return [NSString stringWithFormat:@"%@ %@", @(self.totalMemories), memoryString];
    }
    return NSLocalizedString(@"0 memories", nil);
}

- (NSString *)displayStarsCountString {
    if (self.totalStars > 0) {
        NSString *starString = (self.totalStars > 1) ? NSLocalizedString(@"stars", nil) : NSLocalizedString(@"star", nil);
        return [NSString stringWithFormat:@"%@ %@", @(self.totalStars), starString];
    }
    return NSLocalizedString(@"0 stars", nil);
}

// some helpful accessors (useful for determining a sort order, e.g.)
-(BOOL)isOwnedByUser {
    return self.ownerId && self.ownerId == [AuthenticationManager sharedInstance].currentUser.userId;
}

-(BOOL)isOwnedByUserFriend {
    
    BOOL isOwnedByFriend = NO;
    
    NSArray *friends = [[NSUserDefaults standardUserDefaults] arrayForKey:@"friendIds"];
    
    for (int i = 0; i< friends.count; i++) {
        
        NSInteger friendId = [friends[i] integerValue];
        
        if (friendId == self.ownerId) {
            NSLog(@"%@ owned by FRIEND!",self.displayName);
            isOwnedByFriend = YES;
            break;
        }
    }
    
    return isOwnedByFriend;
}

-(BOOL)isCustomVenue {
    return self.ownerId != 0;
}

-(BOOL)isRealVenue {
    return !self.ownerId && self.venueName;
}

#pragma mark - Private

- (BOOL)isEqual:(id)object {
    if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    return [self isEqualToVenue:object];
}

- (BOOL)isEqualToVenue:(Venue *)venue {
    if (self == venue)
        return YES;
    if (![[self latitude] isEqualToNumber:[venue latitude]] || ![[self longitude] isEqualToNumber:[venue longitude]]
        || ([self addressId] && [venue addressId] && [self addressId] != [venue addressId]))
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash += [[self latitude] hash];
    hash += [[self longitude] hash];
    return hash;
}

@end