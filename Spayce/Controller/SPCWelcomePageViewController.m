//
//  SPCWelcomePageViewController.m
//  Spayce
//
//  Created by Arria P. Owlia on 4/10/15.
//  Copyright (c) 2015 Spayce Inc. All rights reserved.
//

#import "SPCWelcomePageViewController.h"

#import "SPCWelcomeViewController.h"
#import "SPCWelcomeIntroViewController.h"

@interface SPCWelcomePageViewController() <UIPageViewControllerDataSource, SPCWelcomeIntroDelegate>

@property (strong, nonatomic) SPCWelcomeViewController *welcomeVC;

@end

@implementation SPCWelcomePageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = self;
    
    [self setViewControllers:@[self.welcomeVC] direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[SPCWelcomeIntroViewController class]])
        return nil;
    
    return self.welcomeIntroVC;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[SPCWelcomeViewController class]])
        return nil;
    
    return self.welcomeVC;
}

#pragma mark - Accessors

- (SPCWelcomeViewController *)welcomeVC {
    if (nil == _welcomeVC) {
        _welcomeVC = [[SPCWelcomeViewController alloc] init];
    }
    
    return _welcomeVC;
}

- (SPCWelcomeIntroViewController *)welcomeIntroVC {
    SPCWelcomeIntroViewController *welcomeIntroVC = [[SPCWelcomeIntroViewController alloc] init];
    welcomeIntroVC.delegate = self;
    return welcomeIntroVC;
}

#pragma mark - SPCWelcomeIntroDelegate

- (void)tappedWelcomeIntroVC:(SPCWelcomeIntroViewController *)welcomeIntroVC andHasPlayedToEnd:(BOOL)hasPlayedToEnd {
    [self setViewControllers:@[self.welcomeVC] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

@end
