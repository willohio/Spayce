//
//  SPCFeedVideoScroller.h
//  Spayce
//
//  Created by Christopher Taylor on 5/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPCFeedVideoScroller;

@protocol SPCFeedVideoScrollerDelegate <NSObject>

@optional

- (void)spcFeedVideoScroller:(SPCFeedVideoScroller *)feedScroller onAssetTappedWithIndex:(int)index videoUrl:(NSString *)url;
- (void)spcFeedVideoScroller:(SPCFeedVideoScroller *)feedScroller onAssetScrolledTo:(int)index videoUrl:(NSString *)url;

@end

@interface SPCFeedVideoScroller : UIView {
    BOOL isLoading;
    int currImg;
    int displayImg;
    BOOL swipeInProgress;
    BOOL viewingInComments;
}

@property (nonatomic, readonly) NSInteger currentIndex;
@property (nonatomic, readonly) NSInteger total;
@property (nonatomic, assign) BOOL fullScreen;
@property (nonatomic, assign) BOOL lightbox;
@property (nonatomic, weak) id<SPCFeedVideoScrollerDelegate> delegate;

- (void)setMemoryImages:(NSArray *)photoAssetsArray;
- (void)setMemoryImages:(NSArray *)photoAssetsArray withCurrentImage:(int)index;

- (void)addVidURLs:(NSArray *)videoURLs;
- (void)clearVids;
- (void)clearScroller;

- (void)pauseVideo;
- (void)resumeVideo;
@end
