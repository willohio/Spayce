//
//  SPCFeedPhotoScroller.m
//  Spayce
//
//  Created by Christopher Taylor on 5/14/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeedPhotoScroller.h"

// Model
#import "Asset.h"

// View
#import "MemoryCell.h"

// Category
#import "UIImageView+WebCache.h"

// Utility
#import "APIUtils.h"

@interface SPCFeedPhotoScroller ()


@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *imageViews;
@property (nonatomic, strong) NSMutableArray *spacerViews;
@property (nonatomic, strong) NSArray *photoAssetsArray;
@property (nonatomic, strong) UIImageView *previewImage;
@property (nonatomic, assign) BOOL gestureAdded;
@property (nonatomic, strong) UILabel *pageTracker;

@end

@implementation SPCFeedPhotoScroller

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //in order to optimize performance, we initialize the photoscroller with scrollview & 3 image views
        //in this way, we only need to update/clear the image URL(s) upon cell reuse for (almost) all cases
        //when a memory includes more than 3 images, we add extra imageviews to handle that case, and remove them upon cell reuse
        self.backgroundColor = [UIColor clearColor];
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.pagingEnabled = YES;
        self.scrollView.clipsToBounds = YES;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.backgroundColor = [UIColor whiteColor];
        self.scrollView.delegate = self;
        self.scrollView.bouncesZoom = NO;
        self.scrollView.scrollEnabled = YES;
        [self addSubview:self.scrollView];
    
        for (int i = 0; i < 3; i++) {
            UIImageView *tempImgView = [[UIImageView alloc] init];
            tempImgView.contentMode=self.fullScreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
            tempImgView.clipsToBounds=YES;
            tempImgView.backgroundColor = [UIColor clearColor];
            tempImgView.userInteractionEnabled = YES;
            tempImgView.tag = i + 100;
            [self.scrollView addSubview:tempImgView];
            [self.imageViews addObject:tempImgView];
            
        }
        
        
        self.pageTracker = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - 15 - 45, 15, 45, 35)];
        self.pageTracker.backgroundColor = [UIColor colorWithWhite:0.0  alpha:.3];
        self.pageTracker.textColor = [UIColor whiteColor];
        self.pageTracker.font = [UIFont spc_memory_actionButtonFont];
        self.pageTracker.layer.cornerRadius = 2;
        self.pageTracker.hidden = YES;
        self.pageTracker.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.pageTracker];
    }
    return self;
}

-(void)layoutSubviews {
    int page = 0;
    if (self.scrollView) {
        CGFloat width = self.scrollView.frame.size.width;
        page = (self.scrollView.contentOffset.x + (0.5f * width)) / width;
    }
    [self layoutSubviewsAtPage:page];
}

-(void) layoutSubviewsAtPage:(int)page {
 
    // lay out all image views and the scrollview (if available)
    float imageWidth = CGRectGetWidth(self.bounds);
    if (self.imageViews.count > 1) {
        imageWidth = self.fullScreen ? CGRectGetWidth(self.bounds)-10 : CGRectGetWidth(self.bounds);
    }

    self.pageTracker.frame = CGRectMake(self.bounds.size.width - 15 - 45, 15, 45, 35);
    
    if (self.imageViews.count > 9) {
        self.pageTracker.frame = CGRectMake(self.bounds.size.width - 15 - 50, 15, 50, 35);
    }
    
    float page0X = 0;
    float pageX = 0;
    
    for (int i = 0; i < self.imageViews.count; i++) {
        float originX = i * imageWidth;
        
        if (i == 0) {
            page0X = originX;
        }
        if (i == page) {
            pageX = originX;
        }
        
        CGRect imgViewFrame;
        if (self.fullScreen) {
            imgViewFrame = CGRectMake(originX, 0, imageWidth, self.frame.size.height);
        } else {
            imgViewFrame = CGRectMake(originX, self.frame.size.height-imageWidth, imageWidth,imageWidth);
        }
        ((UIImageView *)self.imageViews[i]).frame = imgViewFrame;
        ((UIImageView *)self.imageViews[i]).contentMode=self.fullScreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
        
    }
    
    
    if (self.scrollView) {
        CGRect scrollFrame;
        if (self.fullScreen) {
            scrollFrame = CGRectMake(5, 0, self.bounds.size.width-10, self.bounds.size.height);
        } else {
            scrollFrame = CGRectMake(0,0, CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds));
        }
        CGSize contentSize;
        if (self.fullScreen) {
            contentSize = CGSizeMake(self.photoAssetsArray.count * (self.bounds.size.width-10), self.bounds.size.height);
        } else {
            contentSize = CGSizeMake(self.photoAssetsArray.count * self.bounds.size.width, CGRectGetWidth(self.bounds));
        }
        self.scrollView.frame = scrollFrame;
        self.scrollView.contentSize = contentSize;
        self.scrollView.contentOffset = CGPointMake(pageX - page0X, self.scrollView.contentOffset.y);
    }
}

- (NSInteger)currentIndex {
    return currImg;
}

- (NSInteger) total {
    return _photoAssetsArray.count;
}

- (UIImage *)currentImage {
    UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:100+currImg];
    return imageView.image;
}

-(void)setLightbox:(BOOL)lightbox {
    _lightbox = lightbox;
    self.scrollView.backgroundColor = [UIColor clearColor];
}

-(NSMutableArray *)imageViews {
    if (!_imageViews) {
        _imageViews = [[NSMutableArray alloc] init];
    }
    return _imageViews;
}


-(void)viewingFromComments:(BOOL)viewingFromComments {
    viewingInComments = viewingFromComments;
}

-(void)setMemoryImages:(NSArray *)photoAssetsArray {
    [self setMemoryImages:photoAssetsArray withCurrentImage:currImg];
}

-(void)setMemoryImages:(NSArray *)photoAssetsArray withCurrentImage:(int)index {
    [self setMemoryImages:photoAssetsArray withCurrentImage:index placeholder:nil];
}

-(void)setMemoryImages:(NSArray *)photoAssetsArray withCurrentImage:(int)index placeholder:(UIImage *)placeholder {
    [self clearScroller];

    self.photoAssetsArray = photoAssetsArray;
    
    currImg = index;
    displayImg = currImg +1;
    
    //add any extra uiimageviews needed for mems with tons of image assets
    if (photoAssetsArray.count > 3) {
        for (int i = 3; i < photoAssetsArray.count; i++) {
            UIImageView *tempImgView = [[UIImageView alloc] init];
            tempImgView.contentMode=self.fullScreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
            tempImgView.clipsToBounds=YES;
            tempImgView.backgroundColor = [UIColor clearColor];
            tempImgView.userInteractionEnabled = NO;
            tempImgView.tag = i + 100;
            [self.scrollView addSubview:tempImgView];
            [self.imageViews addObject:tempImgView];
        }
    }
  
    if (photoAssetsArray.count > 1 && !self.lightbox) {
        self.pageTracker.hidden = NO;
        self.pageTracker.text = [NSString stringWithFormat:@"%@/%@", @(displayImg), @(photoAssetsArray.count)];
    } else {
        self.pageTracker.hidden = YES;
    }
    
    [self configureScrollerWithPage:index placeholder:placeholder];
    
    if ((!self.fullScreen) && (!self.gestureAdded) && (!self.lightbox)){
        self.gestureAdded = YES;
        MemoryCell *cell;
 
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
             cell = (MemoryCell *)[[[self superview] superview] superview];
        }
        else {
            cell = (MemoryCell *)[[[[self superview] superview] superview] superview];
        }
        
        UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onImageTapped:)];
        [imageTap setNumberOfTapsRequired:1];
        [imageTap requireGestureRecognizerToFail:cell.doubleTap];
        [self addGestureRecognizer:imageTap];
    }
}

-(void)configureScrollerWithPage:(int)page {
    [self configureScrollerWithPage:page placeholder:nil];
}

-(void)configureScrollerWithPage:(int)page placeholder:(UIImage *)placeholder {
    
    if (!placeholder) {
        placeholder = [UIImage imageNamed:@"placeholder-gray"];
    }
   
    if (self.fullScreen || viewingInComments) {
        self.scrollView.scrollEnabled = YES;
    }
    
    for (int i = 0; i < self.photoAssetsArray.count; i++) {
      
        //set image url & placeholder
        UIImageView *imageView = (UIImageView *)[self.scrollView viewWithTag:100+i];
        NSString *imageUrlStr;
        id imageAsset = self.photoAssetsArray[i];
        if ([imageAsset isKindOfClass:[Asset class]]) {
            Asset * asset = (Asset *)imageAsset;
            imageUrlStr = [asset imageUrlSquare];
        } else {
            NSString *imageName = [NSString stringWithFormat:@"%@", self.photoAssetsArray[i]];
            int photoID = [imageName intValue];
            imageUrlStr = [APIUtils imageUrlStringForAssetId:photoID size:ImageCacheSizeSquare];
        }

        [imageView sd_setImageWithURL:[NSURL URLWithString:imageUrlStr]
                             placeholderImage:(i == page ? placeholder : [UIImage imageNamed:@"placeholder-gray"])
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                        
                                        if (error) {
                                            //NSLog(@"error %@",error);
                                        }
                                        if (image) {
                                            //NSLog(@"got image!");
                                            imageView.image = image;
                                        }
                                    }];
    }
    
    [self layoutSubviewsAtPage:page];
}


#pragma mark - Scroll gesture tap

-(void) onImageTapped:(id)sender {
    if (self.delegate) {
        int index = -1;
        if (self.photoAssetsArray.count == 1) {
            index = 0;
        } else if (self.photoAssetsArray.count > 1) {
            CGFloat width = self.scrollView.frame.size.width;
            index = (self.scrollView.contentOffset.x + (0.5f * width)) / width;
        }
        
        if (index > -1 && self.delegate && [self.delegate respondsToSelector:@selector(spcFeedPhotoScroller:onAssetTappedWithIndex:)]) {
            [self.delegate spcFeedPhotoScroller:self onAssetTappedWithIndex:index];
        }
    }
}

#pragma mark - View Cleanup Methods

-(void)clearScroller {
    
    UIView *view;
    NSArray *subs = [self.scrollView subviews];
 
    //clean up the scroller as necessary
    for (view in subs) {

        //clear extra images in the 'permanent' uiimageviews
        if ((view.tag >= 101) && (view.tag < 103)) {
            UIImageView *imgView = (UIImageView *)view;
            [imgView sd_cancelCurrentImageLoad];
            [imgView sd_setImageWithURL:nil placeholderImage:nil];
        }

        //remove any extra image views added to handle assets with 3+ images
        if (view.tag > 102) {
            UIImageView *imgView = (UIImageView *)view;
            [imgView sd_cancelCurrentImageLoad];
            [view removeFromSuperview];
        }
        
        if (view.tag == 0) {
            [view removeFromSuperview];
        }
    }

    // We also need to clean-up our imageViews array upon reuse!
    for (int i = (int)self.imageViews.count - 1; i > 2; i--) {
        [self.imageViews removeObjectAtIndex:i];
    }
   
    if (self.scrollView) {
        [self.scrollView setContentOffset:CGPointMake(0, 0)];
    }
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    currImg = round(scrollView.contentOffset.x / self.frame.size.width);
    displayImg = currImg +1;
    self.pageTracker.text = [NSString stringWithFormat:@"%@/%@", @(displayImg), @(self.photoAssetsArray.count)];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(spcFeedPhotoScroller:onAssetScrolledTo:)]) {
        [self.delegate spcFeedPhotoScroller:self onAssetScrolledTo:currImg];
    }
}

@end
