//
//  APIUtils.h
//  SpayceBook
//
//  Created by Dmitry Miller on 7/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APIUtils : NSObject

// Query
+ (NSString *)queryStringForParams:(NSDictionary *)queryParams;
+ (NSString *)md5:(NSString *)input;
// Images
+ (NSString *)imageUrlStringForAssetId:(NSInteger)assetId;
+ (NSString *)imageUrlStringForAssetId:(NSInteger)assetId size:(NSInteger)size;
+ (NSString *)imageUrlStringForUrlString:(NSString *)urlString size:(NSInteger)size;

@end
