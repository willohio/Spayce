//
//  SPCWelcomeIntroViewController.m
//  Spayce
//
//  Created by Arria P. Owlia on 4/9/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCWelcomeIntroViewController.h"

#import "SPCWelcomeIntroView.h"

@interface SPCWelcomeIntroViewController()

@property (nonatomic) BOOL isVisible;
@property (nonatomic) BOOL isInBackground;

@end

@implementation SPCWelcomeIntroViewController

#pragma mark - dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - View Events

- (void)loadView {
    self.view = [[SPCWelcomeIntroView alloc] init];
    self.view.gestureRecognizers = @[[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedIntroView:)]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register for background/foreground events
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.welcomeView stop];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.isVisible = YES;
    
    [self.welcomeView play];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.welcomeView stop];
    
    self.isVisible = NO;
}

#pragma mark - Notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isVisible && self.isInBackground) {
        [self.welcomeView play];
    }
    
    self.isInBackground = NO;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    if (self.isVisible) {
        [self.welcomeView stop];
    }
    
    self.isInBackground = YES;
}

#pragma mark - Action-Target

- (void)tappedIntroView:(id)sender {
    if ([self.delegate respondsToSelector:@selector(tappedWelcomeIntroVC:andHasPlayedToEnd:)]) {
        [self.delegate tappedWelcomeIntroVC:self andHasPlayedToEnd:self.welcomeView.hasPlayedToEnd];
    }
}

#pragma mark - Status Bar / Orientation

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Properties

- (SPCWelcomeIntroView *)welcomeView {
    return (SPCWelcomeIntroView *)self.view;
}

@end
