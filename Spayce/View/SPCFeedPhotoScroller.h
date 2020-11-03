//
//  SPCFeedPhotoScroller.h
//  Spayce
//
//  Created by Christopher Taylor on 5/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCFeedPhotoScroller;
@class Asset;

@protocol SPCFeedPhotoScrollerDelegate <NSObject>

@optional

- (void)spcFeedPhotoScroller:(SPCFeedPhotoScroller *)feedScroller onAssetTappedWithIndex:(int)index;
- (void)spcFeedPhotoScroller:(SPCFeedPhotoScroller *)feedScroller onAssetScrolledTo:(int)index;

@end

@interface SPCFeedPhotoScroller : UIView <UIScrollViewDelegate> {
    
    int currImg;
    int displayImg;
    BOOL swipeInProgress;
    BOOL viewingInComments;
    
}

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, readonly) NSInteger total;
@property (nonatomic, readonly) UIImage *currentImage;
@property (nonatomic, assign) BOOL lightbox;
@property (nonatomic, assign) BOOL fullScreen;
@property (nonatomic, weak) id<SPCFeedPhotoScrollerDelegate> delegate;

-(void)setMemoryImages:(NSArray *)photoAssetsArray;
-(void)setMemoryImages:(NSArray *)photoAssetsArray withCurrentImage:(int)index;
-(void)setMemoryImages:(NSArray *)photoAssetsArray withCurrentImage:(int)index placeholder:(UIImage *)placeholder;
-(void)viewingFromComments:(BOOL)viewingFromComments;

@end
