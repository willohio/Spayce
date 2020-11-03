//
//  FICPhoto.m
//  FastImageCache
//
//  Copyright (c) 2013 Path, Inc.
//  See LICENSE for full license agreement.
//

#import "FICPhoto.h"
#import "FICUtilities.h"

#pragma mark External Definitions

NSString *const FICDPhotoImageFormatFamily = @"FICDPhotoImageFormatFamily";
NSString *const FICDPhotoSquareImageFormatName = @"FICDPhotoSquareImageFormatName";
NSString *const FICDPhotoSquareMediumImageFormatName = @"FICDPhotoSquareMediumImageFormatName";
NSString *const FICDPhotoThumbnailXSmallFormatName = @"FICDPhotoThumbnailXSmallFormatName";
NSString *const FICDPhotoThumbnailSmallFormatName = @"FICDPhotoThumbnailSmallFormatName";
NSString *const FICDPhotoThumbnailMediumFormatName = @"FICDPhotoThumbnailMediumFormatName";
NSString *const FICDPhotoThumbnailLargeFormatName = @"FICDPhotoThumbnailLargeFormatName";
NSString *const FICDPhotoThumbnailXLargeFormatName = @"FICDPhotoThumbnailXLargeFormatName";


CGSize const FICDPhotoSquareImageSize = {620, 620};
CGSize const FICDPhotoSquareMediumImageSize = {310, 310};
CGSize const FICDPhotoThumbnailXSmall = {32, 32};
CGSize const FICDPhotoThumbnailSmall = {60, 60};
CGSize const FICDPhotoThumbnailMedium = {100, 100};
CGSize const FICDPhotoThumbnailLarge = {200, 200};
CGSize const FICDPhotoThumbnailXLarge = {320, 320};

#pragma mark - Class Extension

@interface FICPhoto () {
    NSURL *_sourceImageURL;
    NSString *_UUID;
    NSString *_thumbnailFilePath;
    BOOL _thumbnailFileExists;
    BOOL _didCheckForThumbnailFile;
}

@end

#pragma mark

@implementation FICPhoto

@synthesize sourceImageURL = _sourceImageURL;

#pragma mark - Property Accessors

- (UIImage *)sourceImage {
    UIImage *sourceImage = nil;

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.sourceImageURL
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];
    NSURLResponse *response;
    NSError *error;

    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (!error && data) {
        sourceImage = [UIImage imageWithData:data];
    }

    return sourceImage;
}

- (UIImage *)thumbnailImage {
    return self.sourceImage;
}

- (BOOL)thumbnailImageExists {
    return YES;
}

#pragma mark - FICImageCacheEntity

- (NSString *)UUID {
    if (_UUID == nil) {
        // MD5 hashing is expensive enough that we only want to do it once
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([_sourceImageURL absoluteString]);
        _UUID = FICStringWithUUIDBytes(UUIDBytes);
    }
    
    return _UUID;
}

- (NSString *)sourceImageUUID {
    return [self UUID];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName {
    return _sourceImageURL;
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *)image withFormatName:(NSString *)formatName {
    FICEntityImageDrawingBlock drawingBlock = ^(CGContextRef contextRef, CGSize contextSize) {
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        CGContextClearRect(contextRef, contextBounds);

        CGContextSetFillColorWithColor(contextRef, [[UIColor whiteColor] CGColor]);
        CGContextFillRect(contextRef, contextBounds);

        UIGraphicsPushContext(contextRef);
        [image drawInRect:contextBounds];
        UIGraphicsPopContext();
    };

    return drawingBlock;
}

@end
