//
//  SPCMailComposeViewController.m
//  Spayce
//
//  Created by William Santiago on 2014-11-05.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCMailComposeViewController.h"

@interface SPCMailComposeViewController ()

@property (nonatomic, strong) UIColor *barTintColorOriginal;
@property (nonatomic, strong) UIColor *tintColorOriginal;
@property (nonatomic, strong) NSDictionary *titleTextAttributesOriginal;

@end

@implementation SPCMailComposeViewController

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.barTintColorOriginal = [UINavigationBar appearance].barTintColor;
    self.tintColorOriginal = [UINavigationBar appearance].tintColor;
    self.titleTextAttributesOriginal = [UINavigationBar appearance].titleTextAttributes;
    
    [UINavigationBar appearance].barTintColor = [UIColor colorWithRed:44.0/255.0 green:73.0/255.0 blue:110.0/255.0 alpha:1.0];
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    [UINavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor] };
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UINavigationBar appearance].barTintColor = self.barTintColorOriginal;
    [UINavigationBar appearance].tintColor = self.tintColorOriginal;
    [UINavigationBar appearance].titleTextAttributes = self.titleTextAttributesOriginal;
}

#pragma mark - Status bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    return nil;
}

@end
