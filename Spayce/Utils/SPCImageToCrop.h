//
//  SPCImageToCrop.h
//  Spayce
//
//  Created by Christopher Taylor on 6/12/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCImageToCrop : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGFloat originX;
@property (nonatomic, assign) CGFloat originY;
@property (nonatomic, assign) CGFloat cropSize;

@property (nonatomic, readonly) BOOL hasCrop;

-(id)initWithImageToCrop:(SPCImageToCrop *)imageToCrop;
-(id)initWithDefaultsAndImage:(UIImage *)fullImage;
-(id)initWithNewMAMDefaultsAndImage:(UIImage *)fullImage;
-(UIImage *)cropPreviewImage;

@end
