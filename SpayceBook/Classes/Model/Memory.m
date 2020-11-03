//
//  Memory.m
//  Spayce
//
//  Created by Pavel Dušátko on 11/28/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "Memory.h"

// Framework
#import <CoreText/CoreText.h>

// Model
#import "Comment.h"
#import "Friend.h"
#import "Location.h"
#import "Venue.h"

// View
#import "STTweetLabel.h"

// Category
#import "NSDate-Utilities.h"
#import "NSDate+SPCAdditions.h"

// Manager
#import "SpayceSessionManager.h"
#import "SPCColorManager.h"

// Utility
#import "APIService.h"

#define kMAX_ACTION_TEXT_WIDTH 50

@interface Memory ()

@property (nonatomic, strong,) NSAttributedString *authorAttributedString;
@property (nonatomic) CGFloat commentsCountTextWidth;
@property (nonatomic) CGFloat starsCountTextWidth;
@property (nonatomic) CGFloat heightForMemoryText;

@property (nonatomic, strong) NSArray *hashTagsLowercase;

@end

@implementation Memory

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        [self setWithAttributes:attributes];
    }
    return self;
}

- (void)setWithAttributes:(NSDictionary *)attributes {
    _recordID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"id"];
    _key = (NSString *)[TranslationUtils valueOrNil:attributes[@"key"]];
    _type = [TranslationUtils integerValueFromDictionary:attributes withKey:@"type"];
    _text = (NSString *)[TranslationUtils valueOrNil:attributes[@"text"]];
    if (!_text) {
        _text = @"";
        // having 'nil' here can cause a crash when we created attributed text.
    }
    _text = [self prepForHashTagsAndSanitize:_text];
    _author = [[Person alloc] initWithAttributes:attributes[@"author"]];
    if (attributes[@"realAuthor"]) {
        _realAuthor = [[Person alloc] initWithAttributes:attributes[@"realAuthor"]];
    }
    _friendsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"friends_count"];
    _commentsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"comments_count"];
    _starsCount = [TranslationUtils integerValueFromDictionary:attributes withKey:@"starCount"];
    _locationName = (NSString *)[TranslationUtils valueOrNil:attributes[@"locationName"]];
    _locationIconPhotoAsset = [Asset assetFromDictionary:attributes withAssetKey:@"locationIconPhotoAssetInfo" assetIdKey:@"locationIconPhotoAssetID"];
    _locationMainPhotoAsset = [Asset assetFromDictionary:attributes withAssetKey:@"locationMainPhotoAssetInfo" assetIdKey:@"locationMainPhotoAssetID"];
    _userHasStarred = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"userHasStarred"];
    _userHasCommented = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"userHasCommented"];
    _engagementCount = _starsCount + _commentsCount;
    _isAnonMem = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"isAnonMem"]; 
    _userIsWatching = [TranslationUtils booleanValueFromDictionary:attributes withKey:@"watchingMemory"];
    // featuredTime is in milliseconds since epoch
    NSNumber *featuredTime = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"featuredTime"]];
    // _featuredTime needs to be calculated from seconds since epoch
    _featuredTime = [NSDate dateWithTimeIntervalSince1970:[featuredTime longLongValue] / 1000.0];
    _timeElapsedSinceFeatured = [NSDate formattedDateStringWithDate:_featuredTime];
    
    [self initializeAccessTypeWithAttributes:attributes];
    [self initializeDateCreatedWithAttributes:attributes];
    [self initializeTaggedUsersWithAttributes:attributes];
    [self initializeuUerToStarMostRecentlyWithAttributes:attributes];
    [self initializeLocationWithAttributes:attributes];
    [self initializeVenueWithAttributes:attributes];
    [self initializeCommentsWithAttributes:attributes];
    [self initializeHashTagsWithAttributes:attributes];
    
    if (_author.recordID == -2) {
        _isAnonMem = YES;
    }

    [self preload];
}

- (BOOL)updateWithMemory:(Memory *)memory {
    if (_recordID == memory.recordID) {
        _friendsCount = memory.friendsCount;
        self.commentsCount = memory.commentsCount;
        _userHasCommented = memory.userHasCommented;
        
        self.starsCount = memory.starsCount;
        _engagementCount = memory.engagementCount;
        _userHasStarred = memory.userHasStarred;
        _userToStarMostRecently = memory.userToStarMostRecently;
        _accessType = memory.accessType;
        
        _locationName = memory.locationName;
        _locationIconPhotoAsset = memory.locationIconPhotoAsset;
        _locationMainPhotoAsset = memory.locationMainPhotoAsset;
        _location = memory.location;
        _venue = memory.venue;
        
        _recentComments = memory.recentComments;
        
        _taggedUsers = memory.taggedUsers;

        [self preload];

        // potentially changed.  Determine if a real changed happened
        // if you're so inclined; I'm not right now.  Remember to
        // be complete (YES in all cases of a change), but soundness
        // is not necessary.
        return YES;
    }
    return NO;
}

- (void)preload {
    // Preload Attributed Strings
    _authorAttributedString = nil;
    [self authorAttributedString];

    _commentsCountTextWidth = 0;
    [self commentsCountTextWidth];

    _starsCountTextWidth = 0;
    [self starsCountTextWidth];

    _heightForCommentText = 0;
    [self heightForCommentText];
    
    _heightForMemoryText = 0;
    if ([_text isKindOfClass:[NSString class]] && _text.length > 0) {
        [self heightForMemoryText:_text];
    }
    else {
        [self heightForMemoryText:@""];
    }
}

- (void)initializeCommentsWithAttributes:(NSDictionary *)attributes {
    
    if (attributes[@"recentComments"]) {
        NSDictionary *recentComRaw = (NSDictionary *)attributes[@"recentComments"];
        if (recentComRaw[@"comments"]){
            NSArray *commentsRaw = recentComRaw[@"comments"];
            NSMutableArray *mutableComments = [NSMutableArray arrayWithCapacity:commentsRaw.count];
            
            for (int i = 0; i<[commentsRaw count]; i++) {
                
                NSDictionary *commentDic = (NSDictionary *)commentsRaw[i];
                Comment *cleanComment = [[Comment alloc] initWithAttributes:commentDic];
                [mutableComments addObject:cleanComment];
            }
            self.recentComments = [NSArray arrayWithArray:mutableComments];
        }
    }
}

- (void)initializeHashTagsWithAttributes:(NSDictionary *)attributes {
    _hashTags = (NSArray *)[TranslationUtils valueOrNil:attributes[@"hashtags"]];
    if (!_hashTags) {
        _hashTagsLowercase = [NSArray array];
    } else {
        NSMutableArray *mutArray = [NSMutableArray arrayWithCapacity:_hashTags.count];
        for (NSString *hashTag in _hashTags) {
            [mutArray addObject:[hashTag lowercaseString]];
        }
        _hashTagsLowercase = [NSArray arrayWithArray:mutArray];
    }
}


- (void)initializeAccessTypeWithAttributes:(NSDictionary *)attributes
{
    NSString *typeString = (NSString *)[TranslationUtils valueOrNil:attributes[@"accessType"]];
    
    if ([typeString isEqualToString:@"PUBLIC"]) {
        _accessType = MemoryAccessTypePublic;
    } if ([typeString isEqualToString:@"FRIENDS"]) {
        _accessType = MemoryAccessTypeFriend;
    } else if ([typeString isEqualToString:@"PRIVATE"]) {
        _accessType = MemoryAccessTypePrivate;
    }
}

- (void)initializeDateCreatedWithAttributes:(NSDictionary *)attributes
{
    NSNumber *dateCreated = (NSNumber *)[TranslationUtils valueOrNil:attributes[@"dateCreated"]];
    _timeElapsed = [NSDate formattedDateStringWithString:(NSString *)[TranslationUtils valueOrNil:attributes[@"dateCreated"]]];
    
    if (dateCreated) {
        NSTimeInterval miliseconds = [dateCreated doubleValue];
        NSTimeInterval seconds = miliseconds/1000;
        _dateCreated = [NSDate dateWithTimeIntervalSince1970:seconds];
    }
}

- (void)initializeTaggedUsersWithAttributes:(NSDictionary *)attributes {
    NSArray *tagged = (NSArray *)[TranslationUtils valueOrNil:attributes[@"taggedUsers"]];
    NSMutableArray *mutablePeople = [NSMutableArray arrayWithCapacity:tagged.count];
    for (NSDictionary * personAttributes in tagged) {
        [mutablePeople addObject:[[Person alloc] initWithAttributes:personAttributes]];
    }
    
    _taggedUsers = [NSArray arrayWithArray:mutablePeople];
    
    if (mutablePeople.count == 0) {
        NSArray *localTagged = (NSArray *)[TranslationUtils valueOrNil:attributes[@"localTaggedUsers"]];
        if (localTagged.count >0){
            _taggedUsers = localTagged;
        }
    }
}


- (void) initializeuUerToStarMostRecentlyWithAttributes:(NSDictionary *)attributes {
    NSDictionary *profileAttributes = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"lastUserToStar"]];
    if (profileAttributes) {
        _userToStarMostRecently = [[Person alloc] initWithAttributes:profileAttributes];
    } else {
        _userToStarMostRecently = nil;
    }
}

- (void) initializeLocationWithAttributes:(NSDictionary *)attributes {
    NSDictionary *locationAttributes = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"location"]];
    if (locationAttributes) {
        _location = [[Location alloc] initWithAttributes:locationAttributes];
    } else {
        NSNumber * latitude = [TranslationUtils numberFromDictionary:attributes withKey:@"latitude"];
        NSNumber * longitude = [TranslationUtils numberFromDictionary:attributes withKey:@"longitude"];
        if (latitude && longitude && [latitude floatValue] != 0 && [longitude floatValue] != 0) {
            _location = [[Location alloc] init];
            _location.latitude = latitude;
            _location.longitude = longitude;
        }
    }
}

- (void) initializeVenueWithAttributes:(NSDictionary *)attributes {
    NSDictionary *venueAttributes = (NSDictionary *)[TranslationUtils valueOrNil:attributes[@"venue"]];
    if (venueAttributes) {
        _venue = [[Venue alloc] initWithAttributes:venueAttributes];
    } else {
        NSNumber * latitude = [TranslationUtils numberFromDictionary:attributes withKey:@"latitude"];
        NSNumber * longitude = [TranslationUtils numberFromDictionary:attributes withKey:@"longitude"];
        NSString * locationName = (NSString *)[TranslationUtils valueOrNil:attributes[@"locationName"]];
        if (latitude && longitude && [latitude floatValue] != 0 && [longitude floatValue] != 0 && locationName) {
            _venue = [[Venue alloc] init];
            _venue.latitude = latitude;
            _venue.longitude = longitude;
            _venue.defaultName = locationName;
        }
    }
}

- (void)updateCommentPreviewHeight {
    _heightForCommentText = 0;
    [self heightForCommentText];
}
#pragma mark - Accessors

- (NSString *)timeElapsed {
    if (_dateCreated) {
        _timeElapsed = [NSDate formattedDateStringWithDate:_dateCreated];
    }
    
    return _timeElapsed;
}

- (BOOL)isVipMemory {
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

- (NSDate *)datePublicExpired {
    return [self.dateCreated dateByAddingMinutes:100];
}

- (NSArray *)taggedUsersIDs {
    NSMutableArray *userIDs = [[NSMutableArray alloc] init];

    for (Person *person in self.taggedUsers) {
        [userIDs addObject:[NSString stringWithFormat:@"%@", @(person.recordID)]];
    }

    return userIDs;
}

- (NSAttributedString *)authorAttributedString {
    if (!_authorAttributedString) {
        UIColor * nameColor = [SPCColorManager sharedInstance].nameNormalColor;

        NSMutableAttributedString *authorText = [[NSMutableAttributedString alloc] init];
        
        NSString *firstname = self.author.firstname ? : NSLocalizedString(@"<Firstname>", nil);
        if (self.author.userToken) {
            NSDictionary *attributes = @{ STTweetAnnotationHotWord: self.author.userToken, NSForegroundColorAttributeName : nameColor };
        
            [authorText appendAttributedString:[[NSAttributedString alloc] initWithString:firstname attributes:attributes]];
            [authorText addAttribute:NSFontAttributeName value:[UIFont spc_boldSystemFontOfSize:14] range:NSMakeRange(0, authorText.length)];
            [authorText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:20.0f/255.0f green:41.0f/255.0f blue:75.0f/255.0f alpha:1.0f] range:NSMakeRange(0, authorText.length)];
        }
        _authorAttributedString = authorText;
    }
    return _authorAttributedString;
}

- (void)setCommentsCount:(NSInteger)commentsCount {
    _commentsCountTextWidth = 0; // Reset Comments Count Text Width
    _commentsCount = commentsCount;
}

- (CGFloat)commentsCountTextWidth {
    if (_commentsCountTextWidth == 0) {
        CGSize constraint = CGSizeMake(kMAX_ACTION_TEXT_WIDTH, 44);

      NSInteger commentsCount = self.commentsCount;

        NSString *countText = [NSString stringWithFormat:@"%@", @(commentsCount)];

        NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_memory_actionButtonFont] };

        CGRect frame = [countText boundingRectWithSize:constraint
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:attributes
                                               context:NULL];
        
        _commentsCountTextWidth = 5 + frame.size.width;
    }
    return _commentsCountTextWidth;
}

- (void)setStarsCount:(NSInteger)starsCount {
    _starsCountTextWidth = 0; // Reset Star Count Text Width
    _starsCount = starsCount;
}

- (CGFloat)starsCountTextWidth {
    if (_starsCountTextWidth == 0) {
        CGSize constraint = CGSizeMake(kMAX_ACTION_TEXT_WIDTH + 50, 44);

        NSInteger starsCount = self.starsCount;

        NSString *countText = [NSString stringWithFormat:@"%@", @(starsCount)];

        NSDictionary *attributes = @{ NSFontAttributeName: [UIFont spc_memory_actionButtonFont] };

        CGRect frame = [countText boundingRectWithSize:constraint
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                            attributes:attributes
                                               context:NULL];
        
        _starsCountTextWidth = 5 + frame.size.width;
    }
    return _starsCountTextWidth;
}

- (CGFloat)heightForCommentText {
    if (_heightForCommentText == 0) {
        CGFloat totalHeight = 8;

        for (int i = 0; i < self.recentComments.count; i++)  {
            Comment *comment = (Comment *)self.recentComments[i];
            CGFloat textHeight = ceilf(comment.attributedTextHeight);

            float delta = 3;
            if (i + 1 == self.recentComments.count) {
                delta = 8;
            }
            
            totalHeight = totalHeight + textHeight + delta;
        }

        if (self.recentComments.count == 0) {
            totalHeight = 0;
        }

        _heightForCommentText = totalHeight;
    }
    return _heightForCommentText;
}

- (CGFloat)heightForMemoryText:(NSString *)memText {
    if (_heightForMemoryText == 0) {
        
        float maxWidth = 270;
        
        //4.7"
        if ([UIScreen mainScreen].bounds.size.width == 375) {
            maxWidth = 325.0;
        }
        
        //5"
        if ([UIScreen mainScreen].bounds.size.width > 375) {
            maxWidth = 355.0;
        }
        
        CGSize constraint = CGSizeMake(maxWidth, 20000);
                
        _heightForMemoryText = 0;
        
        NSMutableAttributedString * cellText;
        NSDictionary *attributes = @{ NSForegroundColorAttributeName: [UIColor blackColor],
                                      NSFontAttributeName: [UIFont spc_memory_textFont] };

        // Account for memory text if it exists
        if (_text.length > 0) {
            cellText = [[NSMutableAttributedString alloc] initWithString:_text attributes:attributes];
        }
        else {
            cellText = [[NSMutableAttributedString alloc] initWithString:@"" attributes:attributes];
        }
        
        // Account for tagged users as necessary
        if (_taggedUsers.count > 0) {
            [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@" - with" attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xa4a5a6], NSFontAttributeName: [UIFont spc_memory_textFont] }]];
            NSString * strAnd = _taggedUsers.count == 2 ? @" and" : @" &";
            NSString * strSep = @",";
            for (int i = 0; i < _taggedUsers.count; i++) {
                Person * person = _taggedUsers[i];
                // separator?
                if (i > 0) {
                    if (i + 1 == _taggedUsers.count) {
                        [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:strAnd attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xa4a5a6], NSFontAttributeName: [UIFont spc_memory_textFont] }]];
                    } else {
                        [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:strSep attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xa4a5a6], NSFontAttributeName: [UIFont spc_memory_textFont] }]];
                    }
                }
                
                UIColor *nameColor = [UIColor colorWithRGBHex:0x4a6b8c];
                
                NSString *name = person.firstname;
                if (person.firstname.length == 0) {
                    name = person.displayName;
                }

                
                [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
                [cellText appendAttributedString:[[NSAttributedString alloc]
                                                  initWithString:name
                                                  attributes:@{ STTweetAnnotationHotWord: person.userToken,
                                                                NSForegroundColorAttributeName: nameColor,
                                                                NSFontAttributeName: [UIFont spc_memory_textFont] }]];
            }
            [cellText appendAttributedString:[[NSAttributedString alloc] initWithString:@"." attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithRGBHex:0xa4a5a6], NSFontAttributeName: [UIFont spc_memory_textFont] }]];
        }
        
        // Add line spacing
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:1.7];
        [cellText addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, cellText.length)];
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithAttributedString:cellText];
                
        //using core text to correctly handle sizing for emoji
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attrString);
        CGSize targetSize = CGSizeMake(constraint.width, CGFLOAT_MAX);
        CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [attrString length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
        _heightForMemoryText = ceilf(fitSize.height);
        
        if (cellText.length == 0) {
            _heightForMemoryText = -12;
        }
     
    }
    return _heightForMemoryText;
}

- (NSString *)prepForHashTagsAndSanitize:(NSString *)originalString {
    
    NSString *cleanString;
    NSMutableString *workingString = [[NSMutableString alloc] initWithString:originalString];
    
    NSRange range = [workingString rangeOfString:@"#"];
    while(range.location != NSNotFound)
    {
        NSInteger nextLocation;
        
        if (range.location != 0) {
            NSString *prevCharStr = [workingString substringWithRange:NSMakeRange(range.location-1, 1)];
            if (![prevCharStr isEqualToString:@" "]) {
                [workingString insertString:@" " atIndex:range.location];
            }
        }
        
        nextLocation = range.location + 1;
        if (nextLocation < workingString.length) {
            range = [workingString rangeOfString:@"#" options:0 range:NSMakeRange(nextLocation, [workingString length] - nextLocation - 1)];
        }
        else {
            break;
        }
    }
    
    cleanString = [NSString stringWithString:workingString];
    return cleanString;
}

- (void)refreshMetadata {
    [self preload];
}


- (BOOL)matchesHashTag:(NSString *)hashTag {
    if (!self.hashTags) {
        return NO;
    }
    NSLog(@"matches %@?", hashTag);
    NSString *lowercase = [hashTag lowercaseString];
    for (NSString *tag in self.hashTagsLowercase) {
        NSLog(@"%@ matches %@?", tag, lowercase);
    }
    return [self.hashTagsLowercase containsObject:lowercase];
}


+(Memory *)memoryWithAttributes:(NSDictionary *)attributes {
    NSInteger memoryType = [attributes[@"type"] integerValue];
    Memory *memory;
    if (memoryType == MemoryTypeText) {
        memory = [[Memory alloc] initWithAttributes:attributes];
    }
    if (memoryType == MemoryTypeImage) {
        memory = [[ImageMemory alloc] initWithAttributes:attributes];
    }
    if (memoryType == MemoryTypeVideo) {
        memory = [[VideoMemory alloc] initWithAttributes:attributes];
    }
    if (memoryType == MemoryTypeAudio) {
        memory = [[AudioMemory alloc] initWithAttributes:attributes];
    }
    if (memoryType == MemoryTypeMap) {
        memory = [[MapMemory alloc] initWithAttributes:attributes];
    }
    if (memoryType == MemoryTypeFriends) {
        memory = [[FriendsMemory alloc] initWithAttributes:attributes];
    }
    
    return memory;
}

#pragma mark - Comparing memories

- (BOOL)isEqual:(id)object {
    if (object == self)
        return YES;
    if (!object || ![object isKindOfClass:[self class]])
        return NO;
    return [self isEqualToMemory:object];
}

- (BOOL)isEqualToMemory:(Memory *)memory {
    if (self == memory)
        return YES;
    if (self.recordID != memory.recordID)
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = 0;
    hash += [@([self recordID]) hash];
    return hash;
}

@end

@implementation ImageMemory

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super initWithAttributes:attributes];
    if (self) {
        _images = [Asset assetArrayFromDictionary:attributes withAssetsKey:@"assetsInfo" assetIdsKey:@"assets"];
    }
    return self;
}

@end


@implementation VideoMemory

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super initWithAttributes:attributes];
    if (self) {
        NSArray *assets = [Asset assetArrayFromDictionary:attributes withAssetsKey:@"assetsInfo" assetIdsKey:@"assets"];
        
        NSInteger vidCount = assets.count % 2 == 0 ? assets.count / 2 : 1;
        
        NSMutableArray *mutableImages = [NSMutableArray arrayWithCapacity:vidCount];
        NSMutableArray *mutableVids = [NSMutableArray arrayWithCapacity:vidCount];
        
        for (int i =0; i < [assets count]; i++) {
            if (i<vidCount) {
                [mutableImages addObject:assets[i]];
            }
            else {
                //create paths for vids
                Asset *asset = assets[i];
                [mutableVids addObject:asset.baseUrl];
            }
        }
        
        _previewImages = [NSArray arrayWithArray:mutableImages];
        _videoURLs  = [NSArray arrayWithArray:mutableVids];
        
        //NSLog(@"_previewImages %@",_previewImages);
        //NSLog(@"_videoURLs %@",_videoURLs);
    }
    
    return self;
}

@end


@implementation AudioMemory

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super initWithAttributes:attributes];
    if (self) {
        
        NSArray *assets = (NSArray *)[TranslationUtils valueOrNil:attributes[@"assets"]];
        
        NSMutableArray *mutableAudio = [NSMutableArray arrayWithCapacity:assets.count];
        NSString *sessionId = [SpayceSessionManager sharedInstance].currentSessionId;
        
        //set download path for audio files
        for (int i =0; i <[assets count]; i++) {
            
                //create paths for audio
                NSString *basePath = [APIService baseUrl];
                NSString *audioPath = [NSString stringWithFormat:@"%@/spaycevault/download/%@?ses=%@", basePath, assets[i], sessionId];
                [mutableAudio addObject:audioPath];
        }
        _audioURLs  = [NSArray arrayWithArray:mutableAudio];
        //NSLog(@"_audioURLs %@",_audioURLs);
    }
    
    return self;
}

@end


@implementation MapMemory

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super initWithAttributes:attributes];
    if (self) {
        // nothing else to do: memories already have location
    }
    
    return self;
}

@end


@implementation FriendsMemory

#pragma mark - Object lifecycle

- (id)initWithAttributes:(NSDictionary *)attributes
{
    self = [super initWithAttributes:attributes];
    if (self) {
        // nothing else to do: memories already have tagged users and an author
    }
    
    return self;
}

@end