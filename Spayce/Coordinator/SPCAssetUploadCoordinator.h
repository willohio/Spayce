//
//  SPCAssetUploadCoordinator.h
//  Spayce
//
//  Created by Jake Rosin on 11/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SPCImageToCrop;
@class Asset;

@interface SPCPendingAsset : NSObject

@property (nonatomic, readonly) SPCImageToCrop *imageToCrop;
@property (nonatomic, readonly) NSURL *videoURL;
@property (nonatomic, readonly) BOOL isReady;

@property (nonatomic, readonly) NSUInteger assetCount;
@property (nonatomic, readonly) NSUInteger uploadedAssetCount;
@property (nonatomic, readonly) NSUInteger pendingAssetCount;
@property (nonatomic, readonly) BOOL isImage;
@property (nonatomic, readonly) BOOL isVideo;

@property (nonatomic, readonly) Asset *imageAsset;
@property (nonatomic, readonly) Asset *videoAsset;

@property (nonatomic) NSInteger tag;

- (instancetype)initWithImageToCrop:(SPCImageToCrop *)imageToCrop;
- (instancetype)initWithImageToCrop:(SPCImageToCrop *)imageToCrop videoURL:(NSURL *)videoURL;

@end



@interface SPCAssetUploadCoordinator : NSObject

@property (nonatomic, readonly) NSArray *pendingAssets;
@property (nonatomic, readonly) BOOL hasImages;
@property (nonatomic, readonly) BOOL hasVideos;

@property (nonatomic, readonly) NSUInteger totalAssetCount;
@property (nonatomic, readonly) NSUInteger uploadedAssetCount;

@property (nonatomic, readonly) NSArray *imagesToCropArray;
@property (nonatomic, readonly) NSArray *uploadedAssetIdStrings;
@property (nonatomic, readonly) NSArray *uploadedAssets;

@property (nonatomic, strong) UIImageView *precacheImgView;


- (void)addPendingAsset:(SPCPendingAsset *)pendingAsset;
- (void)removePendingAsset:(SPCPendingAsset *)pendingAsset;
- (void)removePendingAssetAtIndex:(NSUInteger)index;
- (SPCPendingAsset *)getPendingAssetWithTag:(NSInteger)tag;

- (void)uploadAssetsWithProgressHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets))progressHandler
                       completionHander:(void (^)(SPCAssetUploadCoordinator *coordinator))completionHandler
                         failureHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSError *error))failureHandler;
- (void)clearAllAssets;
@end