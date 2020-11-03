//
//  SPCAssetUploadCoordinator.m
//  Spayce
//
//  Created by Jake Rosin on 11/5/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCAssetUploadCoordinator.h"


// Asset capture
#import "SPCImageToCrop.h"

// Service
#import "APIService.h"

// View
#import "UIImageView+WebCache.h"

#pragma mark - SPCPendingAsset

@interface SPCPendingAsset()

@property (nonatomic, strong) SPCImageToCrop *imageToCrop;
@property (nonatomic, strong) NSURL *videoURL;

@property (nonatomic, strong) Asset *imageAsset;
@property (nonatomic, strong) Asset *videoAsset;

@end

@implementation SPCPendingAsset

- (instancetype)initWithImageToCrop:(SPCImageToCrop *)imageToCrop {
    self = [self initWithImageToCrop:imageToCrop videoURL:nil];
    return self;
}


- (instancetype)initWithImageToCrop:(SPCImageToCrop *)imageToCrop videoURL:(NSURL *)videoURL {
    self = [super init];
    if (self) {
        self.imageToCrop = imageToCrop;
        self.videoURL = videoURL;
    }
    return self;
}

#pragma mark - SPCPendingAsset Accessors

- (BOOL)isReady {
    if (self.imageToCrop && !self.imageAsset) {
        return NO;
    } else if (self.videoURL && !self.videoAsset) {
        return NO;
    }
    
    return YES;
}

- (BOOL)isImage {
    return (self.imageToCrop && !self.videoURL);
}

- (BOOL)isVideo {
    return self.videoURL != nil;
}

- (NSUInteger)assetCount {
    NSUInteger count = 0;
    if (self.imageToCrop) {
        count++;
    }
    if (self.videoURL) {
        count++;
    }
    return count;
}

- (NSUInteger)uploadedAssetCount {
    NSUInteger count = 0;
    if (self.imageAsset) {
        count++;
    }
    if (self.videoAsset) {
        count++;
    }
    return count;
}

- (NSUInteger)pendingAssetCount {
    return self.assetCount - self.uploadedAssetCount;
}

@end


@interface SPCAssetUploadListener : NSObject

@property (copy, nonatomic) void (^progressHandler)(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets);
@property (copy, nonatomic) void (^completionHandler)(SPCAssetUploadCoordinator *coordinator);
@property (copy, nonatomic) void (^failureHandler)(SPCAssetUploadCoordinator *coordinator, NSError *error);

- (instancetype)initWithProgressHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets))progressHandler
                       completionHander:(void (^)(SPCAssetUploadCoordinator *coordinator))completionHandler
                         failureHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSError *error))failureHandler;

@end


@implementation SPCAssetUploadListener

- (instancetype)initWithProgressHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets))progressHandler
                       completionHander:(void (^)(SPCAssetUploadCoordinator *coordinator))completionHandler
                         failureHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSError *error))failureHandler {
    self = [super init];
    if (self) {
        self.progressHandler = progressHandler;
        self.completionHandler = completionHandler;
        self.failureHandler = failureHandler;
    }
    return self;
}

@end

#pragma mark - SPCAssetUploadCoordinator

@interface SPCAssetUploadCoordinator()

@property (nonatomic, strong) NSArray *pendingAssets;
@property (nonatomic, assign) BOOL uploadInProgress;

@property (nonatomic, strong) NSArray *assetUploadListeners;

@end

@implementation SPCAssetUploadCoordinator


#pragma mark - Accessors

- (NSArray *)pendingAssets {
    if (!_pendingAssets) {
        _pendingAssets = [NSArray array];
    }
    return _pendingAssets;
}


- (NSArray *)assetUploadListeners {
    if (!_assetUploadListeners) {
        _assetUploadListeners = [NSArray array];
    }
    return _assetUploadListeners;
}


- (BOOL)hasImages {
    for (SPCPendingAsset *asset in self.pendingAssets) {
        if (asset.isImage) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)hasVideos {
    for (SPCPendingAsset *asset in self.pendingAssets) {
        if (asset.isVideo) {
            return YES;
        }
    }
    return NO;
}


- (NSUInteger)totalAssetCount {
    NSUInteger total = 0;
    for (SPCPendingAsset *asset in self.pendingAssets) {
        total += asset.assetCount;
    }
    return total;
}

- (NSUInteger)uploadedAssetCount {
    NSUInteger total = 0;
    for (SPCPendingAsset *asset in self.pendingAssets) {
        total += asset.uploadedAssetCount;
    }
    return total;
}


- (void)addPendingAsset:(SPCPendingAsset *)pendingAsset {
    if (![self.pendingAssets containsObject:pendingAsset]) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.pendingAssets];
        [array addObject:pendingAsset];
        self.pendingAssets = [NSArray arrayWithArray:array];
        
        // start a background upload?
        if (pendingAsset.isImage) {
            [self uploadAssetsPreemptively];
        }
    }
    NSLog(@"after adding pending asset, has %li pending assets", self.pendingAssets.count);
}

- (void)removePendingAsset:(SPCPendingAsset *)pendingAsset {
    if ([self.pendingAssets containsObject:pendingAsset]) {
        NSMutableArray *array = [NSMutableArray arrayWithArray:self.pendingAssets];
        [array removeObject:pendingAsset];
        self.pendingAssets = [NSArray arrayWithArray:array];
        
        // TODO: cancel the upload of this asset?
    }
}

- (void)removePendingAssetAtIndex:(NSUInteger)index {
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.pendingAssets];
    [array removeObjectAtIndex:index];
    self.pendingAssets = [NSArray arrayWithArray:array];
    
    // TODO: cancel the upload of this asset?
}

- (SPCPendingAsset *)getPendingAssetWithTag:(NSInteger)tag {
    SPCPendingAsset *assetToReturn = nil;
    
    for (SPCPendingAsset *asset in self.pendingAssets) {
        if (tag == asset.tag) {
            assetToReturn = asset;
        }
    }
    
    return assetToReturn;
}


- (NSArray *)imagesToCropArray {
    NSMutableArray *imagesToCrop = [NSMutableArray arrayWithCapacity:self.pendingAssets.count];
    for (SPCPendingAsset *pendingAsset in self.pendingAssets) {
        if (pendingAsset.imageToCrop) {
            [imagesToCrop addObject:pendingAsset.imageToCrop];
        }
    }
    return [NSArray arrayWithArray:imagesToCrop];
}


- (NSArray *)uploadedAssetIdStrings {
    // provide assets in order that lists images first, then videos
    NSArray *uploadedAssets = self.uploadedAssets;
    NSMutableArray *strArray = [NSMutableArray arrayWithCapacity:uploadedAssets.count];
    for (Asset *asset in uploadedAssets) {
        [strArray addObject:[NSString stringWithFormat:@"%li", (long)asset.assetID]];
    }
    return strArray;
}


- (NSArray *)uploadedAssets {
    // provide assets in order that lists images first, then videos
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:self.pendingAssets.count * 2];
    for (SPCPendingAsset *pendingAsset in self.pendingAssets) {
        if (pendingAsset.imageAsset) {
            [assets addObject:pendingAsset.imageAsset];
        }
    }
    for (SPCPendingAsset *pendingAsset in self.pendingAssets) {
        if (pendingAsset.videoAsset) {
            [assets addObject:pendingAsset.videoAsset];
        }
    }
    return [NSArray arrayWithArray:assets];
}


- (void)uploadAssetsWithProgressHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSInteger assetsUploaded, NSInteger totalAssets))progressHandler
                       completionHander:(void (^)(SPCAssetUploadCoordinator *coordinator))completionHandler
                         failureHandler:(void (^)(SPCAssetUploadCoordinator *coordinator, NSError *error))failureHandler {
    
    SPCAssetUploadListener *listener = [[SPCAssetUploadListener alloc] initWithProgressHandler:progressHandler completionHander:completionHandler failureHandler:failureHandler];
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:self.assetUploadListeners];
    [array addObject:listener];
    self.assetUploadListeners = [NSArray arrayWithArray:array];
    
    if (!self.uploadInProgress) {
        [self uploadNextAsset];
    } else if (progressHandler) {
        NSInteger assetsUploaded = 0;
        NSInteger totalAssets = 0;
        for (SPCPendingAsset *asset in self.pendingAssets) {
            assetsUploaded += asset.uploadedAssetCount;
            totalAssets += asset.assetCount;
        }
        progressHandler(self, assetsUploaded, totalAssets);
    }
}

- (void)uploadAssetsPreemptively {
    if (!self.uploadInProgress && ![self hasVideos]) {
        [self uploadNextAsset];
    }
}

- (void)uploadNextAsset {
    
    NSInteger assetsUploaded = 0;
    NSInteger totalAssets = 0;
    SPCPendingAsset *pendingAsset = nil;
    for (SPCPendingAsset *asset in self.pendingAssets) {
        assetsUploaded += asset.uploadedAssetCount;
        totalAssets += asset.assetCount;
        if (asset.imageToCrop && !asset.imageAsset && !pendingAsset) {
            pendingAsset = asset;
        }
    }
    for (SPCPendingAsset *asset in self.pendingAssets) {
        if (asset.videoURL && !asset.videoAsset && !pendingAsset) {
            pendingAsset = asset;
        }
    }
    
    NSLog(@"has uploaded %li assets of %li total", assetsUploaded, totalAssets);
    
    if (pendingAsset) {
        self.uploadInProgress = YES;
        // upload!
        if (pendingAsset.imageToCrop && !pendingAsset.imageAsset) {
            // upload an image asset
            NSLog(@"upload an image!");
            [self callProgressHandlersWithUploaded:assetsUploaded total:totalAssets];
            [self uploadImageForPendingAsset:pendingAsset];
        } else if (pendingAsset.videoURL && !pendingAsset.videoAsset) {
            // upload the video
            NSLog(@"upload a vid!");
            [self callProgressHandlersWithUploaded:assetsUploaded total:totalAssets];
            [self uploadVideoForPendingAsset:pendingAsset];
        } else {
            // huh?  race condition maybe?
            if (!pendingAsset.isReady) {
                //NSLog(@"A pending asset is not ready, but has all assets available...?");
                self.uploadInProgress = NO;
                [self callFailureHandlersWithError:nil];
            } else {
                [self uploadNextAsset];
            }
        }
    } else {
        // complete!
        NSLog(@"Upload complete: calling completion handler.");
        self.uploadInProgress = NO;
        [self callCompletionHandlers];
    }
}

- (void)uploadImageForPendingAsset:(SPCPendingAsset *)pendingAsset {
    
    SPCImageToCrop *imageToCrop = pendingAsset.imageToCrop;
    UIImage *memoryImage = imageToCrop.image;
    
    NSDictionary *params;
    
    if (imageToCrop.hasCrop) {
        
        NSLog(@"memoryImage width %f height %f",memoryImage.size.width,memoryImage.size.height);
        
        int roundedOriginX = round(imageToCrop.originX);
        int roundedOriginY = round(imageToCrop.originY);
        int roundedWidth = round(imageToCrop.cropSize);
        
        params = @{ @"cropX": @(roundedOriginX),
                    @"cropY": @(roundedOriginY),
                    @"cropW": @(roundedWidth),
                    @"cropH": @(roundedWidth)
                    };
    }
    
    NSLog(@"params for image upload %@",params);
    __weak typeof(self)weakSelf = self;
    [APIService uploadAssetToSpayceVaultWithData:UIImageJPEGRepresentation(memoryImage, 0.75)
                                  andQueryParams:params
                                progressCallback:nil
                                  resultCallback:^(Asset *asset) {
                                      __strong typeof(weakSelf)strongSelf = weakSelf;
                                      
                                      // cache image localy for quick display after posting
                                      if (strongSelf.precacheImgView) {
                                          NSLog(@"caching image locally....");
                                          NSString *imageUrlStr = [asset imageUrlSquare];
                                          [strongSelf.precacheImgView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                                                                    placeholderImage:strongSelf.precacheImgView.image
                                                                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                                                           }];
                                      }
                                      
                                      NSLog(@"image upload success!");
                                      
                                      // set the asset and start the next upload (or completion call).
                                      pendingAsset.imageAsset = asset;
                                      [strongSelf uploadNextAsset];
                                      
                                  } faultCallback:^(NSError *fault) {
                                      NSLog(@"fault %@",fault);
                                      __strong typeof(weakSelf)strongSelf = weakSelf;
                                      
                                      strongSelf.uploadInProgress = NO;
                                      [strongSelf callFailureHandlersWithError:fault];
                                  }];
    
}

- (void)uploadVideoForPendingAsset:(SPCPendingAsset *)pendingAsset {
    
    NSURL *url = pendingAsset.videoURL;
    NSData *videoData = [NSData dataWithContentsOfURL:url];
    
    __weak typeof(self)weakSelf = self;
    [APIService uploadVideoAssetToSpayceVaultWithData:videoData
                                       andQueryParams:nil
                                     progressCallback:nil
                                       resultCallback:^(Asset *asset) {
                                           __strong typeof(weakSelf)strongSelf = weakSelf;
                                           
                                           NSLog(@"video uploaded!");
                                           // set the asset and start the next upload (or completion call).
                                           pendingAsset.videoAsset = asset;
                                           [strongSelf uploadNextAsset];
                                           
                                       } faultCallback:^(NSError *fault) {
                                           NSLog(@"fault %@",fault);
                                           __strong typeof(weakSelf)strongSelf = weakSelf;
                                           
                                           strongSelf.uploadInProgress = NO;
                                           [strongSelf callFailureHandlersWithError:fault];
                                       }];
    
}

- (void)callProgressHandlersWithUploaded:(NSUInteger)uploaded total:(NSUInteger)total {
    NSArray *array = self.assetUploadListeners;
    for (SPCAssetUploadListener *listener in array) {
        if (listener.progressHandler) {
            listener.progressHandler(self, uploaded, total);
        }
    }
}

- (void)callCompletionHandlers {
    NSArray *array = self.assetUploadListeners;
    self.assetUploadListeners = [NSArray array];
    for (SPCAssetUploadListener *listener in array) {
        if (listener.completionHandler) {
            listener.completionHandler(self);
        }
    }
}

- (void)callFailureHandlersWithError:(NSError *)error {
    NSArray *array = self.assetUploadListeners;
    self.assetUploadListeners = [NSArray array];
    for (SPCAssetUploadListener *listener in array) {
        if (listener.failureHandler) {
            listener.failureHandler(self, error);
        }
    }
}

- (void)clearAllAssets {
    NSLog(@"clear all assets!");
    for (SPCPendingAsset *pendingAsset in self.pendingAssets) {
        if (pendingAsset.imageToCrop) {
            pendingAsset.imageToCrop  = nil;  //must set these to nil to avoid leaking!
        }
    }
    self.pendingAssets = nil;
}

@end
