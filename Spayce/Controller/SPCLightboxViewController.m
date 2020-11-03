//
//  SPCLightboxViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-12.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCLightboxViewController.h"

// Category
#import "UIImageView+WebCache.h"

@interface SPCLightboxViewController ()

// Data
@property (nonatomic, strong) NSURL *url;

// UI
@property (nonatomic, strong) UIView *customNavigationBar;
@property (nonatomic, strong) UIButton *customBackButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation SPCLightboxViewController

#pragma mark - Object lifecycle

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

#pragma mark - Accessors

- (UIView *)customNavigationBar {
    if (!_customNavigationBar) {
        _customNavigationBar = [[UIView alloc] init];
        _customNavigationBar.backgroundColor = [UIColor blackColor];
        _customNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _customNavigationBar;
}

- (UIButton *)customBackButton {
    if (!_customBackButton) {
        _customBackButton = [[UIButton alloc] init];
        _customBackButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_customBackButton setImage:[UIImage imageNamed:@"button-back-light"] forState:UIControlStateNormal];
        [_customBackButton addTarget:self action:@selector(pop) forControlEvents:UIControlEventTouchUpInside];
    }
    return _customBackButton;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _activityIndicator;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _imageView;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    // Add to view hierarchy
    [self.view addSubview:self.customNavigationBar];
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.activityIndicator];
    [self.customNavigationBar addSubview:self.customBackButton];
    
    // Setup auto layout constraints
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.customNavigationBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imageView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.customBackButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:20]];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.customBackButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.customNavigationBar attribute:NSLayoutAttributeLeft multiplier:1.0 constant:5]];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.customBackButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44]];
    [self.customNavigationBar addConstraint:[NSLayoutConstraint constraintWithItem:self.customBackButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:44]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self fetchImage];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tabBarController.tabBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.tabBarController.tabBar.hidden = NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)fetchImage {
    [self.activityIndicator startAnimating];
    
    [self.imageView sd_setImageWithURL:self.url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        [self.activityIndicator stopAnimating];
        self.activityIndicator.hidden = YES;
    }];
}

@end
