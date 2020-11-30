//
//  ImageCache.h
//  Spayce
//
//  Created by William Santiago on 10/2/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject

// Access image by it's name
+ (BOOL)hasImageNamed:(NSString *)name;
// Access image by it's name and size
+ (BOOL)hasImageNamed:(NSString *)name size:(NSInteger)size;
// Access image by it's name
+ (UIImage *)imageNamed:(NSString *)name;
// Access image by it's name and size
+ (UIImage *)imageNamed:(NSString *)name size:(NSInteger)size;
// Cache image based on it's name
+ (void)cacheImage:(UIImage *)image name:(NSString *)name;
// Cache image based on it's name and size
+ (void)cacheImage:(UIImage *)image name:(NSString *)name size:(NSInteger)size;
// Cache image base on it's url string
+ (void)cacheImage:(UIImage *)image urlString:(NSString *)urlString size:(NSInteger)size;
// Remove all cached images
+ (void)clearCachedImages;

@end
