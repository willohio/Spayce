//
//  Asset.h
//  Spayce
//
//  Created by Jake Rosin on 8/6/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Asset : NSObject<NSCoding>

@property (nonatomic, readonly) NSInteger assetID;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString * token;
@property (nonatomic, readonly) NSString * baseUrl;

@property (nonatomic, readonly) NSString * imageUrlDefault;
@property (nonatomic, readonly) NSString * imageUrlThumbnail;
@property (nonatomic, readonly) NSString * imageUrlHalfSquare;
@property (nonatomic, readonly) NSString * imageUrlSquare;

-(instancetype)initWithAttributes:(NSDictionary *)attributes;
-(instancetype)initWithCoder:(NSCoder *)aDecoder;

-(void)encodeWithCoder:(NSCoder *)aCoder;

-(NSInteger)integerValue;
-(int)intValue;
-(NSDictionary *)attributes;


-(NSString *)imageUrlStringWithSize:(NSInteger)size;

// Returns either an Asset (parsed from the dictionary entry with key 'assetKey') or,
// if that key is not in the dictionary, an NSString or NSNumber retrieved with the key 'assetIdKey.'
+(Asset *)assetFromDictionary:(NSDictionary *)dictionary withAssetKey:(NSString *)assetKey assetIdKey:(NSString *)assetIdKey;

// Returns either an NSArray of Assets (parsed from the dictionary entry with key 'assetsKey'
// or, if that key is not in the dictionary, an NSArray of NSStrings (or NSNumbers) retrieved with the key 'assetIdsKey'
+(NSArray *)assetArrayFromDictionary:(NSDictionary *)dictionary withAssetsKey:(NSString *)assetsKey assetIdsKey:(NSString *)assetIdsKey;

+(Asset *)assetWithId:(NSInteger)assetID;

+(NSArray *)arrayOfAttributesWithAssets:(NSArray *)assets;

@end
