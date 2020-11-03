//
//  Asset.m
//  Spayce
//
//  Created by Jake Rosin on 8/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "Asset.h"

// Utility
#import "APIUtils.h"
#import "TranslationUtils.h"

@interface Asset()

@property (nonatomic, strong) NSString * baseUrl;
@property (nonatomic, assign) NSInteger assetID;
@property (nonatomic, strong) NSString * token;

@end

@implementation Asset

-(id)initWithAttributes:(NSDictionary *)attributes {
    
    self = [super init];
    if (self) {
        _assetID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"assetID"];
        if (!_assetID) {
            _assetID = [TranslationUtils integerValueFromDictionary:attributes withKey:@"id"];
        }
        _key = (NSString *)[TranslationUtils valueOrNil:attributes[@"key"]];
        _baseUrl = (NSString *)[TranslationUtils valueOrNil:attributes[@"url"]];
        _token = (NSString *)[TranslationUtils valueOrNil:attributes[@"token"]];
    }
    
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _assetID = [aDecoder decodeIntegerForKey:@"assetID"];
        _baseUrl = (NSString *)[aDecoder decodeObjectForKey:@"url"];
        _token = (NSString *)[aDecoder decodeObjectForKey:@"token"];
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeInteger:_assetID forKey:@"assetID"];
    [aCoder encodeObject:_baseUrl forKey:@"url"];
    [aCoder encodeObject:_token forKey:@"token"];
}

#pragma mark - properties and accessors

-(NSDictionary *)attributes {
    NSMutableDictionary * dict = [NSMutableDictionary dictionaryWithCapacity:4];
    dict[@"assetID"] = @(_assetID);
    dict[@"id"] = @(_assetID);
    if (_baseUrl) {
        dict[@"url"] = _baseUrl;
    }
    if (_token) {
        dict[@"token"] = _token;
    }
    return [NSDictionary dictionaryWithDictionary:dict];
}

-(NSString *) baseUrl {
    return _baseUrl ?: self.imageUrlDefault;
}

-(NSString *) imageUrlDefault {
    return [self imageUrlStringWithSize:ImageCacheSizeDefault];
}

-(NSString *) imageUrlThumbnail {
    return [self imageUrlStringWithSize:ImageCacheSizeThumbnailMedium];
}

-(NSString *) imageUrlHalfSquare {
    return [self imageUrlStringWithSize:ImageCacheSizeSquareMedium];
}

-(NSString *) imageUrlSquare {
    return [self imageUrlStringWithSize:ImageCacheSizeSquare];
}

-(NSInteger) integerValue {
    NSLog(@".integerValue called: Asset treated as assetId.  You should consider asset-specific processing.  %@", [NSThread callStackSymbols]);
    return _assetID;
}

-(int) intValue {
    NSLog(@".intValue called: Asset treated as assetId.  You should consider asset-specific processing.  %@", [NSThread callStackSymbols]);
    return (int)_assetID;
}

-(NSString *)imageUrlStringWithSize:(NSInteger)size {
    return _baseUrl ? [APIUtils imageUrlStringForUrlString:_baseUrl size:size] : [APIUtils imageUrlStringForAssetId:_assetID size:size];
}

// Returns either an Asset (parsed from the dictionary entry with key 'assetKey') or,
// if that key is not in the dictionary, an NSNumber retrieved with the key 'assetIdKey.'
+(Asset *)assetFromDictionary:(NSDictionary *)dictionary withAssetKey:(NSString *)assetKey assetIdKey:(NSString *)assetIdKey {
    if (dictionary[assetKey]) {
        return [[Asset alloc] initWithAttributes:dictionary[assetKey]];
    } else if (dictionary[assetIdKey]) {
        Asset *asset = [[Asset alloc] init];
        asset.assetID = [TranslationUtils integerValueFromDictionary:dictionary withKey:assetIdKey];
        if (asset.assetID == 0) {
            return nil;
        }
        return asset;
    } else {
        return nil;
    }
}

// Returns either an NSArray of Assets (parsed from the dictionary entry with key 'assetsKey'
// or, if that key is not in the dictionary, an NSArray of NSNumbers retrieved with the key 'assetIdsKey'
+(NSArray *)assetArrayFromDictionary:(NSDictionary *)dictionary withAssetsKey:(NSString *)assetsKey assetIdsKey:(NSString *)assetIdsKey {
    if (dictionary[assetsKey]) {
        NSArray *array = dictionary[assetsKey];
        NSMutableArray *mutArray = [[NSMutableArray alloc] init];
        for (NSDictionary *dict in array) {
            [mutArray addObject:[[Asset alloc] initWithAttributes:dict]];
        }
        return [NSArray arrayWithArray:mutArray];
    } else if (dictionary[assetIdsKey]) {
        NSArray *array = dictionary[assetsKey];
        NSMutableArray *mutArray = [[NSMutableArray alloc] init];
        for (NSObject *val in array) {
            Asset *asset = [[Asset alloc] init];
            if ([val isKindOfClass:[NSString class]]) {
                asset.assetID = [(NSString *)val integerValue];
            } else if ([val isKindOfClass:[NSNumber class]]) {
                asset.assetID = [(NSNumber *)val integerValue];
            }
            [mutArray addObject:asset];
        }
        return [NSArray arrayWithArray:mutArray];
    } else {
        return nil;
    }
}

+(Asset *)assetWithId:(NSInteger)assetID {
    Asset *asset = [[Asset alloc] init];
    asset.assetID = assetID;
    return asset;
}

+(NSArray *)arrayOfAttributesWithAssets:(NSArray *)assets {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (Asset *asset in assets) {
        [array addObject:[asset attributes]];
    }
    return [NSArray arrayWithArray:array];
}


- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[Asset class]] && ((Asset *)object).assetID == self.assetID;
}

- (NSUInteger)hash {
    return (NSUInteger)self.assetID;
}

@end
