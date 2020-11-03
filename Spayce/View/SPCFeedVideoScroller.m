//
//  SPCFeedVideoScroller.m
//  Spayce
//
//  Created by Christopher Taylor on 5/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeedVideoScroller.h"

// Model
#import "Asset.h"

// View
#import "MemoryCell.h"
#import "SPCAVPlayerView.h"

// Category
#import "UIImageView+WebCache.h"

// Utility
#import "APIUtils.h"

@interface SPCFeedVideoScroller () <SPCAVPlayerViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *imageViews;

@property (nonatomic, strong) NSArray *photoAssetsArray;
@property (nonatomic, strong) NSMutableArray *spacerViews;
@property (nonatomic, retain) NSMutableArray *vidURLs;
@property (nonatomic, strong) SPCAVPlayerView *playerView;
@property (nonatomic) float playerVolume; // Use this to store a change from/to a muted state
@property (strong, nonatomic) UIButton *soundButton; // Toggles sound
@property (nonatomic, strong) NSMutableArray *moviePlayerViews;
@property (nonatomic, strong) NSFileHandle *file;
@property (nonatomic, strong) UILabel *loadingView;
@property (nonatomic, strong) NSURLConnection *conection;
@property (nonatomic, strong) UIImageView *previewImage;
@property (nonatomic, strong) UILabel *pageTracker;

@property (nonatomic, assign) BOOL gestureAdded;
@property (nonatomic, assign) BOOL imagesAdded;

@end

@implementation SPCFeedVideoScroller

-(void)dealloc {
    [self clearScroller];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.playerView = nil; // Clear any references to the current player
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.scrollView = [[UIScrollView alloc] init];
        self.scrollView.pagingEnabled = YES;
        self.scrollView.clipsToBounds = YES;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.backgroundColor = [UIColor clearColor];
        
        self.scrollView.scrollEnabled = NO;
        [self addSubview:self.scrollView];
        
        UISwipeGestureRecognizer *swipeL = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft)];
        [swipeL setDirection:UISwipeGestureRecognizerDirectionLeft];
        [self.scrollView addGestureRecognizer:swipeL];
        
        UISwipeGestureRecognizer *swipeR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight)];
        [swipeR setDirection:UISwipeGestureRecognizerDirectionRight];
        [self.scrollView addGestureRecognizer:swipeR];
        
        self.pageTracker = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.size.width - 15 - 45, 15, 45, 35)];
        self.pageTracker.backgroundColor = [UIColor colorWithWhite:0.0  alpha:.3];
        self.pageTracker.textColor = [UIColor whiteColor];
        self.pageTracker.font = [UIFont spc_memory_actionButtonFont];
        self.pageTracker.layer.cornerRadius = 2;
        self.pageTracker.hidden = YES;
        self.pageTracker.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.pageTracker];
        
        //add initial  uiimageviews needed for mems with up to 3 vid assets
        for (int i = 0; i < 3; i++) {
            UIImageView *tempImgView = [[UIImageView alloc] init];
            tempImgView.contentMode=self.fullScreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
            tempImgView.clipsToBounds=YES;
            tempImgView.userInteractionEnabled = YES;
            tempImgView.tag = i + 100;
            
            UIButton *playBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
            playBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
            playBtn.layer.cornerRadius = 32;
            UIImage *playBtnImg = [UIImage imageNamed:@"button-play-white"];
            [playBtn setImage:playBtnImg forState:UIControlStateNormal];
            [playBtn setImageEdgeInsets:UIEdgeInsetsMake(0.0, 3.0, 0.0, 0.0)];
            [tempImgView addSubview:playBtn];
            [playBtn addTarget:self action:@selector(prepForVid:) forControlEvents:UIControlEventTouchUpInside];
            playBtn.tag = i;
            
            [self.scrollView addSubview:tempImgView];
            [self.imageViews addObject:tempImgView];
            
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name: UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearVidsFromNotif) name:@"clearVids" object:nil];
        
        // Set initial audiosessioncategory - ambient until volume is un-muted
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    }
    return self;
}


- (void)applicationWillResignActive {
    NSLog(@"applicationWillResign!");
    self.playerView = nil;
}

- (void)applicationDidBecomeActive {
    NSLog(@"did become active!");
    
    //reset our view now that we're back
    self.playerView = nil;
    
    [self resetAndEnablePlayBtns];
    self.scrollView.alpha = 1;

    //clear and reset our notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name: UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearVidsFromNotif) name:@"clearVids" object:nil];
}


-(NSMutableArray *)imageViews {
    if (!_imageViews) {
        _imageViews = [[NSMutableArray alloc] init];
    }
    return _imageViews;
}

-(NSMutableArray *)moviePlayerViews {
    if (!_moviePlayerViews) {
        _moviePlayerViews = [[NSMutableArray alloc] init];
    }
    return _moviePlayerViews;
}

-(CGFloat) imageWidth {
    
    if (self.imageViews.count > 1) {
        float tempWidth = self.fullScreen ? CGRectGetWidth(self.bounds)-10 : CGRectGetWidth(self.bounds);
        return tempWidth;
    } else {
        return CGRectGetWidth(self.bounds);
    }
}

-(CGFloat) imageSpacing {
    
    
    float tempSpacing = self.imageViews.count > 1 ? 2 : 0;
    
    if (!self.fullScreen && !viewingInComments) {
        tempSpacing = 0;
    }
    
    return tempSpacing;
}

-(NSInteger)currentIndex {
    return currImg;
}

-(NSInteger) total {
    return _photoAssetsArray.count;
}

-(CGRect) getImageFrameWithIndex:(int)i {
    float imageWidth = self.imageWidth;
    float imageSpacing = self.imageSpacing;
    float originX = i * (imageWidth + imageSpacing);
    
    if (self.fullScreen) {
        return CGRectMake(originX, 0, imageWidth, self.frame.size.height);
    } else {
        return CGRectMake(originX, self.frame.size.height-imageWidth, imageWidth,imageWidth);
    }
}



-(void)layoutSubviews {
    [super layoutSubviews];
    
    int page = 0;
    if (self.scrollView) {
        CGFloat width = self.scrollView.frame.size.width;
        page = (self.scrollView.contentOffset.x + (0.5f * width)) / width;
    }
    [self layoutSubviewsAtPage:page];
    
    // Edit the current movie player's size
    if (nil != self.playerView) {
        CGRect newFrame = self.playerView.frame;
        newFrame.size = CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetWidth(self.bounds));
        self.playerView.frame = newFrame;
    }
}

-(void)layoutSubviewsAtPage:(int)page {
    self.loadingView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    // lay out all image views and the scrollview (if available)
    self.pageTracker.frame = CGRectMake(self.bounds.size.width - 15 - 45, 15, 45, 35);
    
    float page0X = 0;
    float pageX = 0;
    
    for (int i = 0; i < self.imageViews.count; i++) {
        
        float originX = i * (self.imageWidth + self.imageSpacing);
        if (viewingInComments && self.imageViews.count == 1) {
            originX = 1;
        }
        
        CGRect imgViewFrame = [self getImageFrameWithIndex:i];
        if (i == 0) {
            page0X = imgViewFrame.origin.x;
        }
        if (i == page) {
            pageX = imgViewFrame.origin.x;
        }
        
        UIImageView * view = (UIImageView *)self.imageViews[i];
        ((UIImageView *)self.imageViews[i]).contentMode=self.fullScreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
        
        view.frame = imgViewFrame;
        for (UIView * subView in view.subviews) {
            if ([subView isKindOfClass:[UIButton class]]) {
                subView.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
            }
        }
    }
    
    
    if (self.scrollView) {
        CGRect scrollFrame;
        if (self.fullScreen) {
            scrollFrame = CGRectMake(5, 0, self.bounds.size.width-10, self.bounds.size.height);
        } else {
            scrollFrame = CGRectMake(0,0, self.bounds.size.width, self.bounds.size.width);
            if (viewingInComments) {
                scrollFrame = CGRectMake(0,0, self.bounds.size.width, self.bounds.size.width);
            }
        }
        CGSize contentSize;
        if (self.fullScreen) {
            contentSize = CGSizeMake(self.photoAssetsArray.count * (self.bounds.size.width-10), self.bounds.size.height);
        } else {
            contentSize = CGSizeMake(self.photoAssetsArray.count * self.bounds.size.width, self.bounds.size.width);
        }
        self.scrollView.frame = scrollFrame;
        self.scrollView.contentSize = contentSize;
        self.scrollView.contentOffset = CGPointMake(pageX - page0X, self.scrollView.contentOffset.y);
    }
    
    if ((!self.fullScreen) && (self.spacerViews.count > 0)) {
        if (!viewingInComments){
            [self scrollAndFade];
        }
    }
}

-(void)setMemoryImages:(NSArray *)photoAssetsArray {
    [self setMemoryImages:photoAssetsArray withCurrentImage:0];
}

-(void)setMemoryImages:(NSArray *)photoAssetsArray withCurrentImage:(int)index {
    
    //NSLog(@"setMemoryImages photoAssetsArray %@",photoAssetsArray);
    
    [self clearScroller];
    self.photoAssetsArray = photoAssetsArray;
    
    currImg = index;
    displayImg = currImg +1;
    
    // add any extra uiimageviews needed for mems with tons of image assets (beyond our base of 3)
    for (int i = 3; i < photoAssetsArray.count; i++) {
        UIImageView *tempImgView = [[UIImageView alloc] init];
        tempImgView.contentMode=self.fullScreen ? UIViewContentModeScaleAspectFit : UIViewContentModeScaleAspectFill;
        tempImgView.clipsToBounds=YES;
        tempImgView.userInteractionEnabled = YES;
        tempImgView.tag = i + 100;
        
        UIButton *playBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 64, 64)];
        playBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        playBtn.layer.cornerRadius = 32;
        UIImage *playBtnImg = [UIImage imageNamed:@"button-play-white"];
        [playBtn setImage:playBtnImg forState:UIControlStateNormal];
        [playBtn setImageEdgeInsets:UIEdgeInsetsMake(0.0, 3.0, 0.0, 0.0)];
        [tempImgView addSubview:playBtn];
        [playBtn addTarget:self action:@selector(prepForVid:) forControlEvents:UIControlEventTouchUpInside];
        playBtn.tag = i;
        
        [self.scrollView addSubview:tempImgView];
        [self.imageViews addObject:tempImgView];
        
    }
    
    //add our tap gesture to trigger light box mode
    
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
        [self.scrollView addGestureRecognizer:imageTap];
        
    }
    
    //display our page tracker if needed
    if (photoAssetsArray.count > 1 && !self.lightbox) {
        self.pageTracker.hidden = NO;
        self.pageTracker.text = [NSString stringWithFormat:@"%@/%@", @(displayImg), @(photoAssetsArray.count)];
    } else {
        self.pageTracker.hidden = YES;
    }
    
    //set our images, enable buttons, and layout our views
    [self configureScrollerAtPage:index];

}

-(void)configureScrollerAtPage:(int)page {
    
    
    if (self.fullScreen || viewingInComments) {
        self.scrollView.scrollEnabled = YES;
    }
    
    
    //updaate our placeholder images images
    
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
                     placeholderImage:[UIImage imageNamed:@"placeholder-gray"]
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

    self.imagesAdded = YES;
    
    [self enableButtonSubviews:self];
    [self layoutSubviewsAtPage:page];
}

#pragma mark - Swipe gesture methods

-(void)swipeLeft {
    
    if (!swipeInProgress && !self.fullScreen && !viewingInComments) {
        
        int maxImg = (int)self.photoAssetsArray.count - 1;
        
        if (currImg < maxImg) {
            
            swipeInProgress = YES;
            
            //update & animate offset
            currImg++;
            [self scrollAndFade];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(spcFeedVideoScroller:onAssetScrolledTo:videoUrl:)]) {
                [self.delegate spcFeedVideoScroller:self onAssetScrolledTo:currImg videoUrl:self.vidURLs[currImg]];
            }
            
            self.playerView = nil;
        }
    }
}

-(void)swipeRight {
    
    if (!swipeInProgress && !self.fullScreen && !viewingInComments) {
        
        int minImg = 0;
        
        if (currImg > minImg) {
            swipeInProgress = YES;
            
            //update & animate offset
            currImg--;
            [self scrollAndFade];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(spcFeedVideoScroller:onAssetScrolledTo:videoUrl:)]) {
                [self.delegate spcFeedVideoScroller:self onAssetScrolledTo:currImg videoUrl:self.vidURLs[currImg]];
            }
            
            self.playerView = nil;
        }
    }
}

-(void)scrollAndFade {
    
    //update scroller offset
    float newOffset = self.bounds.size.width * currImg;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(resetScroll)];
    self.scrollView.contentOffset = CGPointMake(newOffset, 0);
    [UIView commitAnimations];
}

-(void)resetScroll {
    swipeInProgress = NO;
    displayImg = currImg +1;
    self.pageTracker.text = [NSString stringWithFormat:@"%@/%@", @(displayImg), @(self.photoAssetsArray.count)];
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
        
        if (index > -1 && [self.delegate respondsToSelector:@selector(spcFeedVideoScroller:onAssetTappedWithIndex:videoUrl:)]) {
            [self.delegate spcFeedVideoScroller:self onAssetTappedWithIndex:index videoUrl:self.vidURLs[index]];
        }
    }
}

#pragma mark - View Cleanup Methods

-(void)clearScroller {
    
    if (self.imagesAdded) {

        NSLog(@"clear scroller");
        self.imagesAdded = NO;
        UIView *view;
        NSArray *subs = [self.scrollView subviews];
        
        //clean up as necessary
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
                [imgView removeFromSuperview];
            }
        }
    
    }
    
    // We also need to clean-up our imageViews arrray upon reuse!
    for (int i = (int)self.imageViews.count - 1; i > 2; i--) {
        [self.imageViews removeObjectAtIndex:i];
    }
    
    [self clearVids];
    
    self.loadingView.hidden = YES;
    [self resetAndEnablePlayBtns];
    
    // Reset initial audiosessioncategory - ambient until volume is un-muted
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
}

- (void)resetAndEnablePlayBtns {
    
    UIView *view;
    NSArray *subs = [self.scrollView subviews];
    
    for (view in subs) {
        
        NSArray *subsubs = [view subviews];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIButton *btn;
            for (btn in subsubs) {
                
                if ([btn isKindOfClass:[UIButton class]]) {
                    UIImage *playBtnImg = [UIImage imageNamed:@"button-play-white"];
                    [btn setImage:playBtnImg forState:UIControlStateNormal];
                }
            }
        });
    }
    
    [self enableButtonSubviews:self];
}

- (void)clearVidsFromNotif {
    NSLog(@"clear vids called from external notification");
    self.playerView = nil;
}

- (void)clearVids {
    //clear all notifs and reset the ones we want to persist notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name: UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive) name: UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearVidsFromNotif) name:@"clearVids" object:nil];

    //just in case it's somehow hanging around..
    if (nil != self.playerView) {
        self.playerView = nil;
    }
    
    // Let's stop any/all videos. Also, doing this after 'self.playerView = nil' means we do not observe the rate change here, which is what we want
    if (self.moviePlayerViews.count > 0) {
        NSLog(@"stop movie");
        for (SPCAVPlayerView *playerView in self.moviePlayerViews) {
            [playerView stop];
        }
        [self.moviePlayerViews removeAllObjects];
    }
    
    // Also, re-set our volume to 0
    self.playerVolume = 0.0f;
    self.soundButton = nil; // So it will be re-created with default values
    
    //reset scroll view
    [self enableButtonSubviews:self];
}

- (void)enableButtonSubviews:(UIView *)rootView {
    for (UIView * view in rootView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            [((UIButton *)view) setEnabled:YES];
        }
        [self enableButtonSubviews:view];
    }
}


#pragma mark - video methods

-(void)addVidURLs:(NSArray *)videoURLs {
    // Set our video URLs
    self.vidURLs = [NSMutableArray arrayWithArray:videoURLs];

    //Wipe any previous moviePlayers
    [self.moviePlayerViews removeAllObjects];
    self.playerView = nil;
    
    NSLog(@"add video URLs!");
    
    // Add latest input video URLs to our moviePlayers array
    for (NSUInteger urlIndex = 0; urlIndex < [self.vidURLs count]; ++urlIndex) {
        NSURL *videoURL = [NSURL URLWithString:[self.vidURLs objectAtIndex:urlIndex]];
        NSLog(@"Initing playerItem");
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
        NSLog(@"Initing player");
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        NSLog(@"Initing playerView");
        SPCAVPlayerView *playerView = [[SPCAVPlayerView alloc] initWithPlayer:player];
        playerView.delegate = self;
        
        NSLog(@"Adding playerView");
        [self.moviePlayerViews addObject:playerView];
    }
    
    NSLog(@"Setting self.playerView");
    NSInteger currentIndex = self.currentIndex;
    self.playerView = [self.moviePlayerViews objectAtIndex:self.currentIndex];
    
    // Set the button up to be in a 'loading' state, since we'll be auto-loading this first playerView
    if (nil != self.playerView) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf prepForVid:[strongSelf playButtonAtIndex:currentIndex]];
        });
    }
    NSLog(@"Done");
}

//called when user taps on play button
- (void)prepForVid:(id)sender{
    UIButton *vidBtn = (UIButton *)sender;
    int vidBtnTag = (int)vidBtn.tag;
    if (nil != sender && self.moviePlayerViews.count > vidBtnTag) {
        NSLog(@"prep for vid!");
        
        [((UIButton *)sender) setEnabled:NO];
        self.loadingView.hidden = NO;
        isLoading = YES;
        
        // Set the clock 'loading' icon
        UIImage *loadingImg = [UIImage imageNamed:@"clock-4pm"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [vidBtn setImage:loadingImg forState:UIControlStateNormal];
        });
        
        // Grab the appropriate moviePlayer
        self.playerView = [self.moviePlayerViews objectAtIndex:vidBtnTag];
        
        // Let it play
        [self playVideo];
    }
}

#pragma mark - Actions

- (void)playVideo {
    NSLog(@"play video!");
    
    // Set the playerView's frame/background
    CGRect movieFrame = [self getImageFrameWithIndex:(int)self.currentIndex];
    if (self.scrollView) {
        movieFrame = CGRectOffset(movieFrame, self.scrollView.frame.origin.x, self.scrollView.frame.origin.y);
    }
    self.playerView.frame = movieFrame;
    if (self.fullScreen) {
        self.playerView.backgroundColor = [UIColor whiteColor];
        self.playerView.layer.backgroundColor = [UIColor whiteColor].CGColor;
    }
    if (self.lightbox) {
        self.playerView.backgroundColor = [UIColor clearColor];
        self.playerView.layer.backgroundColor = [UIColor clearColor].CGColor;
    }
    
    self.playerView.volume = self.playerVolume;
    [self.playerView play];
}

- (void)pauseVideo {
    NSLog(@"pause video!");
    if (nil != self.playerView) {
        [self.playerView pause];
    }
}

- (void)resumeVideo {
    NSLog(@"resume video!");
    if (nil != self.playerView) {
        [self.playerView play];
    }
}

- (void)tappedSoundButton:(id)sender {
    if (0.0f == self.playerVolume) {
        self.playerVolume = 1.0f;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    } else {
        self.playerVolume = 0.0f;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    }
    
    UIImage *volumeImage = [UIImage imageNamed:@"Volume"];
    if (0.0f < self.playerVolume) {
        volumeImage = [UIImage imageNamed:@"Volume-Off"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.soundButton setImage:volumeImage forState:UIControlStateNormal];
    });
    
    self.playerView.volume = self.playerVolume;
}

#pragma mark - SPCAVPlayerView delegate

- (void)didStartPlaybackWithPlayerView:(SPCAVPlayerView *)playerView {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ([strongSelf.playerView isEqual:playerView]) {
            if (![strongSelf.scrollView isEqual:strongSelf.playerView.superview]) {
                [playerView removeFromSuperview];
                [strongSelf.scrollView addSubview:playerView];
            }
            
            if (![strongSelf.scrollView isEqual:self.soundButton.superview]) {
                [strongSelf.scrollView addSubview:self.soundButton];
            }
        }
    });
}

- (void)didFinishPlaybackToEndWithPlayerView:(SPCAVPlayerView *)playerView {
    if ([self.playerView isEqual:playerView]) {
        self.playerView = nil;
    }
}

- (void)didFailToPlayWithError:(NSError *)error withPlayerView:(SPCAVPlayerView *)playerView {
    if ([self.playerView isEqual:playerView]) {
        self.playerView = nil;
    }
}

#pragma mark - Accessors

- (void)setPlayerView:(SPCAVPlayerView *)playerView {
    if (nil != _playerView) {
        [_playerView removeFromSuperview];
        [_playerView stop];
        [self.soundButton removeFromSuperview]; // This is/should be somewhat coupled to the playerView
    }
    
    // Set the playerView
    _playerView = playerView;
    
    // Buttons
    if (nil == _playerView) {
        [self resetAndEnablePlayBtns];
    }
}

- (UIButton *)playButtonAtIndex:(NSInteger)index {
    UIButton *buttonRet = nil;
    for (UIView *view in self.scrollView.subviews) {
        for (UIView *subview in view.subviews) {
            if (subview.tag == index && [subview isKindOfClass:[UIButton class]]) {
                buttonRet = (UIButton *)subview;
                break;
            }
        }
    }
    
    return buttonRet;
}

- (UIButton *)soundButton {
    if (nil == _soundButton) {
        _soundButton = [[UIButton alloc] init];
        _soundButton.layer.cornerRadius = 3.0f;
        _soundButton.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
        [_soundButton setImage:[UIImage imageNamed:@"Volume"] forState:UIControlStateNormal];
        [_soundButton addTarget:self action:@selector(tappedSoundButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGRect imageRect = [self getImageFrameWithIndex:(int)self.currentIndex];
    _soundButton.frame = CGRectMake(CGRectGetMinX(imageRect) + 15, CGRectGetMinY(imageRect) + 15, 45, 35);
    
    return _soundButton;
}

@end
