//
//  APIUtils.m
//  SpayceBook
//
//  Created by Dmitry Miller on 7/4/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "APIUtils.h"
#import "APIService.h"
#import "SpayceSessionManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSString+SPCAdditions.h"

static NSString * IMAGE_URL_SUFFIX_DEFAULT = @"";
static NSString * IMAGE_URL_SUFFIX_THUMB = @"__thumb";
static NSString * IMAGE_URL_SUFFIX_HALF_SQUARE = @"__half_square";
static NSString * IMAGE_URL_SUFFIX_SQUARE = @"__square";

@implementation APIUtils

#pragma mark - Private

+ (NSString *)safeUrlStringFromString:(NSString *)string {
    __autoreleasing NSString *encodedString;
    
    encodedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                                                          NULL,
                                                                                          (__bridge CFStringRef)string,
                                                                                          NULL,
                                                                                          (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                          kCFStringEncodingUTF8
                                                                                          );
    return encodedString;
}

#pragma mark - Query

+ (NSString *)queryStringForParams:(NSDictionary *)queryParamsDict {
    if (queryParamsDict == nil) {
        return nil;
    }

    NSMutableString *query = [[NSMutableString alloc] init];
    BOOL isFirstEntry = YES;

    for (NSString *key in queryParamsDict.allKeys) {
        if (isFirstEntry) {
            isFirstEntry = NO;
        } else {
            [query appendString:@"&"];
        }

        [query appendString:[APIUtils safeUrlStringFromString:key]];
        [query appendString:@"="];
        
        NSObject *value =  queryParamsDict[key];
        NSString *strValue = [value isKindOfClass:[NSString class]] ? (NSString *)value : [value description];
        [query appendString:[APIUtils safeUrlStringFromString:strValue]];
    }

    return query;
}

+ (NSString *)md5:(NSString *)input {
    const char *cStr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest); // This is the md5 call
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%2x", digest[i]];
    }

    return [output stringByReplacingOccurrencesOfString:@" " withString:@""];
}

#pragma mark - Images

+ (NSString *)imageUrlStringForAssetId:(NSInteger)assetId {
    return [APIUtils imageUrlStringForAssetId:assetId size:ImageCacheSizeDefault];
}

+ (NSString *)imageUrlStringForAssetId:(NSInteger)assetId size:(NSInteger)size {
    if (assetId == 0) {
        return nil;
    }
    
    NSString *baseURL = [APIService baseUrl];
    NSString *sessionId = [SpayceSessionManager sharedInstance].currentSessionId;
    
    if (size == ImageCacheSizeDefault) {
        return [NSString stringWithFormat:@"%@/meet/image/%@?ses=%@", baseURL, @(assetId), sessionId];
    }
    else if ((size == ImageCacheSizeSquare) || (size == ImageCacheSizeSquareMedium))  {
        return [NSString stringWithFormat:@"%@/meet/image/%@/square/%@?ses=%@", baseURL, @(assetId), @(size), sessionId];
    }
    else {
        return [NSString stringWithFormat:@"%@/meet/image/%@/%@?ses=%@", baseURL, @(assetId), @(size), sessionId];
    }
}

+ (NSString *)imageUrlStringForUrlString:(NSString *)urlString size:(NSInteger)size {
    // The functionality here differs depending on whether the URL uses the legacy format
    // (load from the spayce-server through a REST Api) or the new, load-balancing format
    // (load directly from S3 or some other hosting service using a base path with a
    // small set of supported suffixes).
    if ([urlString rangeOfString:[APIService baseUrl]].location != NSNotFound
                && [urlString rangeOfString:@"/image/"].location != NSNotFound) {
        // Format is:
        // ".../image/{assetId}/... other info"
        // Strip out the assetId and create an image load path from it at the specified size.
        NSString * assetIdString = [urlString stringBetweenString:@"/image/" andString:@"/"];
        NSInteger assetId = [assetIdString integerValue];
        return [APIUtils imageUrlStringForAssetId:assetId size:size];
    } else if ([urlString rangeOfString:@"token"].location != NSNotFound && [urlString rangeOfString:@"id"].location != NSNotFound) {
        // Format is:
        // ...<base path>.../<token>_token__<id>_id.<extension>
        // or
        // ...<base path>.../<token>_token__<id>_id<sizeformat>.<extension>
        // Where <sizeformat> is one of:
        //
        //      <empty string>
        //      __half_square
        //      __square
        //      __thumb
        
        NSInteger extensionLoc = [urlString rangeOfString:@"." options:NSBackwardsSearch].location;
        NSString * extension = [urlString substringFromIndex:extensionLoc];
        NSString * base = [urlString substringToIndex:extensionLoc];
        
        // remove all size suffixes from the base
        base = [APIUtils stringByRemovingSuffix:IMAGE_URL_SUFFIX_DEFAULT fromString:base];
        base = [APIUtils stringByRemovingSuffix:IMAGE_URL_SUFFIX_THUMB fromString:base];
        base = [APIUtils stringByRemovingSuffix:IMAGE_URL_SUFFIX_HALF_SQUARE fromString:base];
        base = [APIUtils stringByRemovingSuffix:IMAGE_URL_SUFFIX_SQUARE fromString:base];
        
        // add the appropriate suffix and replace the extension
        urlString = [NSString stringWithFormat:@"%@%@%@", base, [APIUtils suffixForSize:size], extension];
    }
    return urlString;
}

+(NSString *) suffixForSize:(NSInteger)size {
    if (size == ImageCacheSizeDefault) {
        return IMAGE_URL_SUFFIX_DEFAULT;
    } else if (size <= ImageCacheSizeThumbnailMedium) {
        return IMAGE_URL_SUFFIX_THUMB;
    } else if (size <= ImageCacheSizeSquareMedium) {
        return IMAGE_URL_SUFFIX_HALF_SQUARE;
    } else if (size <= ImageCacheSizeSquare) {
        return IMAGE_URL_SUFFIX_SQUARE;
    }
    return IMAGE_URL_SUFFIX_DEFAULT;
}

+(NSString *) stringByRemovingSuffix:(NSString *)suffix fromString:(NSString *)baseString {
    NSInteger lengthWithoutSuffix = baseString.length - suffix.length;
    if (lengthWithoutSuffix >= 0 && [baseString rangeOfString:suffix options:NSBackwardsSearch].location == lengthWithoutSuffix) {
        return [baseString substringToIndex:lengthWithoutSuffix];
    }
    return baseString;
}

@end
