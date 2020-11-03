//
//  ImageCache.m
//  Spayce
//
//  Created by Pavel Dusatko on 10/2/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "ImageCache.h"
#import "NSString+SPCAdditions.h"

NSString * const IMAGE_CACHE_DIRECTORY   = @"image-cache";

@implementation ImageCache

#pragma mark - Private

+ (NSString *)pathForDirectory:(NSString *)directory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    return [documentsDirectory stringByAppendingPathComponent:directory];
}

+ (NSString *)pathForItemName:(NSString *)name directory:(NSString *)directory {
    NSString *imageCacheDirectory = [ImageCache pathForDirectory:directory];
    return [[imageCacheDirectory stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"jpg"];
}

+ (BOOL)imageExists:(NSString *)name inDirectory:(NSString *)directory {
    NSString *fullPathToFile = [ImageCache pathForItemName:name directory:directory];
    NSString *fullPathToDir = [ImageCache pathForDirectory:directory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:fullPathToDir]) {
        [fileManager createDirectoryAtPath:fullPathToDir withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    
    return [fileManager fileExistsAtPath:fullPathToFile];
}

+ (NSString *)itemName:(NSString *)name size:(NSInteger)size {
    if (size == ImageCacheSizeDefault) {
        return name;
    } else {
        return [NSString stringWithFormat:@"%@-%@", name, @(size)];
    }
}

+ (NSString *)imageNameForUrlString:(NSString *)urlString size:(NSInteger)size {
    if (size == ImageCacheSizeDefault) {
        NSString *contactId = [urlString stringBetweenString:@"image/" andString:@"?ses="];
        if (contactId) {
            return [NSString stringWithFormat:@"%@", contactId];
        }
    } else {
        NSString *contactId = [urlString stringBetweenString:@"image/" andString:[NSString stringWithFormat:@"/%i", (int)size]];
        if (contactId) {
            return [NSString stringWithFormat:@"%@", contactId];
        }
    }
    
    return nil;
}

#pragma mark - Accessors

// Access image by it's name
+ (BOOL)hasImageNamed:(NSString *)name {
    return [ImageCache hasImageNamed:name size:ImageCacheSizeDefault];
}


// Access image by it's name and size
+ (BOOL)hasImageNamed:(NSString *)name size:(NSInteger)size {
    return [ImageCache hasImageNamed:name size:size directory:IMAGE_CACHE_DIRECTORY];
}

+ (BOOL)hasImageNamed:(NSString *)name size:(NSInteger)size directory:(NSString *)directory {
    NSString *itemName = [ImageCache itemName:name size:size];
    
    return [ImageCache imageExists:itemName inDirectory:directory];
}

+ (UIImage *)imageNamed:(NSString *)name {
    return [ImageCache imageNamed:name size:ImageCacheSizeDefault];
}

+ (UIImage *)imageNamed:(NSString *)name size:(NSInteger)size {
    return [ImageCache imageNamed:name size:size directory:IMAGE_CACHE_DIRECTORY];
}

+ (UIImage *)imageNamed:(NSString *)name size:(NSInteger)size directory:(NSString *)directory {
    NSString *itemName = [ImageCache itemName:name size:size];
    NSString *path = [ImageCache pathForItemName:itemName directory:directory];
    
    BOOL success = [ImageCache imageExists:itemName inDirectory:directory];
    if (success) {
        NSData *imageData = [NSData dataWithContentsOfFile:path];
        return [UIImage imageWithData:imageData];
    }
    
    return nil;
}

+ (void)cacheImage:(UIImage *)image name:(NSString *)name {
    [ImageCache cacheImage:image name:name size:ImageCacheSizeDefault];
}

+ (void)cacheImage:(UIImage *)image name:(NSString *)name size:(NSInteger)size {
    [ImageCache cacheImage:image name:name size:size directory:IMAGE_CACHE_DIRECTORY];
}

+ (void)cacheImage:(UIImage *)image name:(NSString *)name size:(NSInteger)size directory:(NSString *)directory {
    NSString *itemName = [ImageCache itemName:name size:size];
    BOOL success = [ImageCache imageExists:itemName inDirectory:directory];
    
    if (!success) {
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        NSString *path = [ImageCache pathForItemName:itemName directory:directory];
        
        [imageData writeToFile:path atomically:NO];
    }
}

+ (void)cacheImage:(UIImage *)image urlString:(NSString *)urlString size:(NSInteger)size {
    NSString *imageName = [ImageCache imageNameForUrlString:urlString size:size];
    [ImageCache cacheImage:image name:imageName size:size];
}

+ (void)clearCachedImages {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *fullDirectory = [documentsDirectory stringByAppendingPathComponent:IMAGE_CACHE_DIRECTORY];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *dirContents = [fileManager contentsOfDirectoryAtPath:fullDirectory error:nil];
    NSPredicate *jpgFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.jpg'"];
    NSArray *onlyJPGs = [dirContents filteredArrayUsingPredicate:jpgFilter];
    
    for (NSString *fileName in onlyJPGs) {
        NSString *fullPathToFile = [fullDirectory stringByAppendingPathComponent:fileName];
        [fileManager removeItemAtPath:fullPathToFile error:nil];
    }
}

@end
