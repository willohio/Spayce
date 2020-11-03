//
//  SPCFeedPhotoScrollerViewController.m
//  Spayce
//
//  Created by Jake Rosin on 5/15/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCFeedPhotoScrollerViewController.h"
#import "SPCFeedPhotoScroller.h"

@interface SPCFeedPhotoScrollerViewController ()

@property (nonatomic, strong) NSArray * photoAssets;
@property (nonatomic, assign) int startingIndex;

@property (nonatomic, strong) SPCFeedPhotoScroller * feedPhotoScroller;
@property (nonatomic, strong) UIView * statusBg;

@end

@implementation SPCFeedPhotoScrollerViewController

- (id)initWithPics:(NSArray *)pics index:(int)index {
    self = [super init];
    if (self) {
        self.photoAssets = pics;
        self.startingIndex = index;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.feedPhotoScroller = [[SPCFeedPhotoScroller alloc] initWithFrame:self.view.frame];
    self.feedPhotoScroller.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    self.feedPhotoScroller.fullScreen = YES;
    [self.feedPhotoScroller setMemoryImages:self.photoAssets withCurrentImage:self.startingIndex];
    [self.view addSubview:self.feedPhotoScroller];
    
    float statusHeight = 20;
    
    self.statusBg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, statusHeight)];
    self.statusBg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    [self.view addSubview:self.statusBg];
    
    UIButton *closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 50, 50)];
    UIImage *closeBtnImg = [UIImage imageNamed:@"button-close-gray"];
    [closeBtn setBackgroundImage:closeBtnImg forState:UIControlStateNormal];
    [self.view addSubview:closeBtn];
    [closeBtn addTarget:self action:@selector(dismissPhotos) forControlEvents:UIControlEventTouchUpInside];
}


-(void)dismissPhotos {
    [self.delegate hidePics];
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.feedPhotoScroller) {
        self.feedPhotoScroller.frame = self.view.bounds;
        [self.feedPhotoScroller setNeedsLayout];
    }
    
    if (self.statusBg) {
        float statusHeight = 20;
        
        self.statusBg.frame = CGRectMake(0, 0, self.view.bounds.size.width, statusHeight);
        [self.statusBg setNeedsLayout];
    }
}

@end
