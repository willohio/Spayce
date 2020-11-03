//
//  SPCWebViewController.m
//  Spayce
//
//  Created by Pavel Dusatko on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCWebViewController.h"

@interface SPCWebViewController ()

@property (nonatomic, strong) UIWebView *webView;

@end

@implementation SPCWebViewController

#pragma mark - Accessors

- (UIWebView *)webView {
    if (!_webView) {
        _webView = [[UIWebView alloc] init];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _webView;
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];
    
    [self.view addSubview:self.webView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureNavigationBar];
    
    NSURL *url = [NSURL URLWithString:self.urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - Configuration

- (void)configureNavigationBar {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[[UIImage imageNamed:@"button-back-light-small"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:self action:@selector(pop)];
}

#pragma mark - Actions

- (void)pop {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
