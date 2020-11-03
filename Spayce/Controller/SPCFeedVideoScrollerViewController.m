//
//  SPCFeedVideoScrollerViewController.m
//  Spayce
//
//  Created by Jake Rosin on 5/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeedVideoScrollerViewController.h"
#import "SPCFeedVideoScroller.h"

@interface SPCFeedVideoScrollerViewController ()

@property (nonatomic, strong) NSArray * photoAssetIds;
@property (nonatomic, strong) NSArray * videoUrls;
@property (nonatomic, assign) int startingIndex;

@property (nonatomic, strong) SPCFeedVideoScroller * feedVideoScroller;
@property (nonatomic, strong) UIView * statusBg;

@end

@implementation SPCFeedVideoScrollerViewController

- (id)initWithPics:(NSArray *)pics videoURL:(NSArray *)urls index:(int)index {
    self = [super init];
    if (self) {
        self.photoAssetIds = pics;
        self.videoUrls = urls;
        self.startingIndex = index;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.feedVideoScroller = [[SPCFeedVideoScroller alloc] initWithFrame:self.view.frame];
    self.feedVideoScroller.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    self.feedVideoScroller.fullScreen = YES;
    [self.feedVideoScroller setMemoryImages:self.photoAssetIds withCurrentImage:self.startingIndex];
    [self.feedVideoScroller addVidURLs:self.videoUrls];
    [self.view addSubview:self.feedVideoScroller];
    
    float statusHeight = 20;
    
    self.statusBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, statusHeight)];
    self.statusBg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    [self.view addSubview:self.statusBg];
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 50)];
    UIImage *closeBtnImg = [UIImage imageNamed:@"button-close-gray"];
    [closeBtn setBackgroundImage:closeBtnImg forState:UIControlStateNormal];
    [self.view addSubview:closeBtn];
    [closeBtn addTarget:self action:@selector(dismissVideos) forControlEvents:UIControlEventTouchUpInside];
}


-(void)dismissVideos {
    [self.feedVideoScroller clearVids];
    [self.delegate hideVideos];
}


#pragma mark - Orientation methods

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(orientation))
    {
        return orientation;
    }
    
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return true;
}

- (BOOL)shouldAutorotate
{
    return true;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.feedVideoScroller) {
        [self.feedVideoScroller pauseVideo];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.feedVideoScroller) {
        self.feedVideoScroller.frame = self.view.bounds;
        [self.feedVideoScroller setNeedsLayout];
    }
    
    if (self.statusBg) {
        float statusHeight = 20;
        
        self.statusBg.frame = CGRectMake(0, 0, self.view.bounds.size.width, statusHeight);
        [self.statusBg setNeedsLayout];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if (self.feedVideoScroller) {
        [self.feedVideoScroller resumeVideo];
    }
}

@end
