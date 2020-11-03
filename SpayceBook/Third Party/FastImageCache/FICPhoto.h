//
//  FICPhoto.h
//  FastImageCache
//
//  Copyright (c) 2013 Path, Inc.
//  See LICENSE for full license agreement.
//

#import "FICEntity.h"

extern NSString *const FICDPhotoImageFormatFamily;
extern NSString *const FICDPhotoSquareImageFormatName;
extern NSString *const FICDPhotoSquareMediumImageFormatName;
extern NSString *const FICDPhotoThumbnailXSmallFormatName;
extern NSString *const FICDPhotoThumbnailSmallFormatName;
extern NSString *const FICDPhotoThumbnailMediumFormatName;
extern NSString *const FICDPhotoThumbnailLargeFormatName;
extern NSString *const FICDPhotoThumbnailXLargeFormatName;

extern CGSize const FICDPhotoSquareImageSize;
extern CGSize const FICDPhotoSquareMediumImageSize;
extern CGSize const FICDPhotoThumbnailXSmall;
extern CGSize const FICDPhotoThumbnailSmall;
extern CGSize const FICDPhotoThumbnailMedium;
extern CGSize const FICDPhotoThumbnailLarge;
extern CGSize const FICDPhotoThumbnailXLarge;

@interface FICPhoto : NSObject <FICEntity>

@property (nonatomic, copy) NSURL *sourceImageURL;
@property (nonatomic, strong, readonly) UIImage *sourceImage;
@property (nonatomic, strong, readonly) UIImage *thumbnailImage;
@property (nonatomic, assign, readonly) BOOL thumbnailImageExists;

@end
