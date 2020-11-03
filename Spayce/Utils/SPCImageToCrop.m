//
//  SPCImageToCrop.m
//  Spayce
//
//  Created by Christopher Taylor on 6/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCImageToCrop.h"

@interface SPCImageToCrop()

@property (nonatomic, assign) BOOL hasCrop;

@end

@implementation SPCImageToCrop

-(void)dealloc {
    NSLog(@"SPCImageToCrop dealloc");
}

-(id) initWithImageToCrop:(SPCImageToCrop *)imageToCrop {
    NSLog(@"SPCImageToCrop init");
    self = [self initWithDefaultsAndImage:imageToCrop.image];
    if (self) {
        if (imageToCrop.hasCrop) {
            self.originX = imageToCrop.originX;
            self.originY = imageToCrop.originY;
            self.cropSize = imageToCrop.cropSize;
        }
    }
    return self;
}

-(id)initWithDefaultsAndImage:(UIImage *)fullImage {
    
    NSLog(@"SPCImageToCrop init");
    self = [super init];
    if (self) {
        self.image = fullImage;
        self.originX = 0;
        self.originY = 70 * [UIScreen mainScreen].scale;
        
        if (fullImage.size.width <= fullImage.size.height) {
           self.cropSize = fullImage.size.width;
        }
        else {
           self.cropSize = fullImage.size.height;
           self.originX = (fullImage.size.width - self.cropSize) / 2;
           self.originY = 0;
        }
    }
    return self;
}

-(id)initWithNewMAMDefaultsAndImage:(UIImage *)fullImage {
    
    NSLog(@"SPCImageToCrop init");
    self = [super init];
    if (self) {
        self.image = fullImage;
        self.originX = 0;
        self.originY =  195 * [UIScreen mainScreen].scale;
        
        if (fullImage.size.width <= fullImage.size.height) {
            self.cropSize = fullImage.size.width;
        }
        else {
            self.cropSize = fullImage.size.height;
            self.originX = (fullImage.size.width - self.cropSize) / 2;
            self.originY = 0;
        }
        
        if (fullImage.size.height == fullImage.size.width) {
            self.originY = 0;
        }
    }
    return self;
}

-(UIImage *)cropPreviewImage {
    
    UIImage *croppedImage;
    
    CGRect cropRect = CGRectMake(_originX, _originY, _cropSize, _cropSize);
    NSLog(@"cropRect originX %f, originY %f, cropSize %f",_originX,_originY,_cropSize);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([_image CGImage], cropRect);
    croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return croppedImage;
}


#pragma mark - Setters

- (void)setCropSize:(CGFloat)cropSize {
    _cropSize = cropSize;
    self.hasCrop = YES;
}

@end
