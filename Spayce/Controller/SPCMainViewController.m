//
//  MainViewController.m
//  SpayceBook
//
//  Created by Dmitry Miller on 5/14/13.
//  Copyright (c) 2013 Spayce Inc. All rights reserved.
//

#import "SPCMainViewController.h"

// Framework
#import <FacebookSDK/FacebookSDK.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import "AVFoundation/AVAudioPlayer.h"

// Model
#import "User.h"

// View
#import "IntroAnimation.h"
#import "AppDelegate.h"

// Controller
#import "SPCFeedViewController.h"
#import "SPCProfileViewController.h"
#import "SPCCaptureMemoryViewController.h"
#import "SPCHereViewController.h"
#import "SPCTabBarController.h"
#import "SPCWelcomePageViewController.h"
#import "SPCLocationPromptViewController.h"
#import "SPCExploreViewController.h"
#import "SPCMAMViewController.h"
#import "SPCActivityViewController.h"
#import "SPCPeopleViewController.h"
#import "SPCWelcomeIntroViewController.h"

// Category
#import "UIImage+Tint.h"
#import "UIImage+Color.h"

// Manager
#import "AuthenticationManager.h"
#import "LocationManager.h"

// Constants
#import "Constants.h"

@interface SPCMainViewController () <SPCWelcomeIntroDelegate>

@property (nonatomic, strong) UIViewController *spayceViewController;
@property (nonatomic, strong) UIViewController *exploreViewController;
@property (nonatomic, strong) UIViewController *feedViewController;
@property (nonatomic, strong) UIViewController *locationPromptViewController;
@property (nonatomic, strong) UIViewController *activityViewController;
@property (nonatomic, strong) UIViewController *peopleViewController;
@property (nonatomic, strong) UIViewController *profileViewController;
@property (nonatomic, strong) SPCMAMViewController *mamViewController;
@property (nonatomic, strong) SPCTabBarController *customTabBarController;
@property (nonatomic, strong) UIViewController *currentViewController;
@property (nonatomic, strong) UIView *highSpeedPrompt;
@property (nonatomic, assign) BOOL mamCaptureActive;
@property (nonatomic, assign) BOOL previewMode;
@property (nonatomic, strong) UIViewController *previouslyPresentedViewController;
@property (nonatomic, strong) UIImage *launchImg;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@end

@implementation SPCMainViewController

#pragma mark - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController - Managing the View

- (void)loadView {
    [super loadView];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.view.clipsToBounds = NO;
    self.view.backgroundColor = [UIColor colorWithRed:28.0f/255.0f green:26.0f/255.0f blue:33.0f/255.0f alpha:1.0f];

    // Show logo immediately
    UIImageView *bigLogoImgView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    bigLogoImgView.image = self.launchImg;
    bigLogoImgView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    bigLogoImgView.tag = -2;
    [self.view addSubview:bigLogoImgView];

}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePreviewMode) name:@"beginPreviewMode" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endPreviewMode) name:@"endPreviewMode" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthenticationNotification:) name:kAuthenticationDidFinishWithSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthenticationNotification:) name:kAuthenticationDidUpdateUserInfoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAuthenticationDidFail:) name:kAuthenticationDidFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLogout:) name:kAuthenticationDidLogoutNotification object:nil];
   
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFBInviteAll) name:@"attemptFBInviteAll" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completedFBInviteAll) name:@"FBInviteAllComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(animationComplete) name:kIntroAnimationDidEndNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completedMAMAnimation:) name:@"didFinishRestoringFeedAfterMAMAnimation" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMakeMemAnimation:) name:@"handleMakeMemAnimation" object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleHiSpeedPrompt:) name:@"showHighSpeedPrompt" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMAM:) name:@"handleMAM" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMAMFromModal:) name:@"handleMAMFromModal" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mamEndedFromFullScreenStart) name:@"mamEndedFromFullScreenStart" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissMAM) name:@"dismissMAM" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completedMAM) name:@"completedMAM" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_hideStatusBar) name:@"spc_hideStatusBar" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spc_showStatusBar) name:@"spc_showStatusBar" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarFrameWillChange:) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPNSSound) name:@"playPNSSound" object:nil];
    
    if ([AuthenticationManager sharedInstance].isInitialized) {
        if ([AuthenticationManager sharedInstance].currentUser) {
            [self handleAuthenticationNotification:nil];
        } else if (NO == self.welcomeIntroWasShown) {
            SPCWelcomeIntroViewController *welcomeIntroVC = [[SPCWelcomeIntroViewController alloc] init];
            welcomeIntroVC.delegate = self;
            self.currentViewController = welcomeIntroVC;
        } else {
            SPCWelcomePageViewController *welcomePageViewControler = [[SPCWelcomePageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomePageViewControler];
            
            self.currentViewController = navController;
            
            NSLog(@"handle logout!");
            if (!animationExists){
                animationExists = YES;
                IntroAnimation *introAnimation = [[IntroAnimation alloc] initWithFrame:self.view.frame];
                introAnimation.tag = -1;
                [introAnimation prepAnimation];
                [introAnimation startAnimation];
                [self.view addSubview:introAnimation];
            }
        }
    }
    
    // Construct URL to sound file for PNS alert
    NSString *path = [NSString stringWithFormat:@"%@/pns-msg.mp3", [[NSBundle mainBundle] resourcePath]];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    
    // Create audio player object and initialize with URL to sound
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
}

#pragma mark - UIViewController - Configuring the View Rotation Settings

- (BOOL)shouldAutorotate {
    return UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        return orientation;
    }
    
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}


#pragma mark - UIViewController - Configuring the View’s Layout Behavior

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    // Hidden during MAM capture and (if the current VC is the explore VC and it prefers a hidden status bar)
    // Also hidden during welcome view controller presentation
    BOOL isPresentingWelcomeScreen = NO;
    if ([self.currentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navCtlr = (UINavigationController *)self.currentViewController;
        if ([[navCtlr.viewControllers firstObject] isKindOfClass:[SPCWelcomePageViewController class]]) {
            isPresentingWelcomeScreen = YES;
        }
    } else if ([self.currentViewController isKindOfClass:[SPCWelcomeIntroViewController class]]) {
        isPresentingWelcomeScreen = YES;
    }
    
    if (self.mamCaptureActive || (TAB_BAR_HOME_ITEM_INDEX == self.customTabBarController.selectedIndex && [self.exploreViewController prefersStatusBarHidden]) || isPresentingWelcomeScreen) {
        return YES;
    } else {
        return NO;
    }
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    if ([self.currentViewController isKindOfClass:[UITabBarController class]]) {
        UINavigationController *navController = (UINavigationController *)self.customTabBarController.selectedViewController;
        if ([navController respondsToSelector:@selector(topViewController)]) {
              return navController.topViewController;
        }
        else {
            UIViewController *vc = [[UIViewController alloc]init];
            return vc;
        }
      
    }
    else if ([self.currentViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)self.currentViewController;
        return navController.topViewController;
    }
    else {
        UIViewController *vc = [[UIViewController alloc]init];
        return vc;
    }
}

#pragma mark - Accessors - Tab Bar Items

- (UITabBarItem *)spayceTabBarItem {
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"HOME", nil)
                                                             image:[[[UIImage imageNamed:@"tab-bar-spayce"] imageTintedWithColor:[UIColor colorWithRed:119.0f/255.0f green:130.0f/255.0f blue:144.0f/255.0f alpha:1.000f]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                     selectedImage:[[[UIImage imageNamed:@"tab-bar-spayce"] imageTintedWithColor:[UITabBar appearance].tintColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.1" options:NSNumericSearch] != NSOrderedAscending) {
        // at least iOS 7.1.  See
        // http://stackoverflow.com/questions/22321323/ios-7-1-uitabbaritem-titlepositionadjustment-and-imageinsets
        tabBarItem.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(-1, 0);
    } else {
        tabBarItem.imageInsets = UIEdgeInsetsMake(2, -1, -2, 1);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(-1, 0);
    }
    
    return tabBarItem;
}

- (UITabBarItem *)feedTabBarItem {
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"FOLLOWS", nil)
                                                             image:[[[UIImage imageNamed:@"tab-bar-follows"] imageTintedWithColor:[UIColor colorWithRed:119.0f/255.0f green:130.0f/255.0f blue:144.0f/255.0f alpha:1.000f]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                     selectedImage:[[[UIImage imageNamed:@"tab-bar-follows"] imageTintedWithColor:[UITabBar appearance].tintColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.1" options:NSNumericSearch] != NSOrderedAscending) {
        // at least iOS 7.1.  See
        // http://stackoverflow.com/questions/22321323/ios-7-1-uitabbaritem-titlepositionadjustment-and-imageinsets
        tabBarItem.imageInsets = UIEdgeInsetsMake(3, 0, -3, 0);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(-4, 0);
    } else {
        tabBarItem.imageInsets = UIEdgeInsetsMake(3, -4, -3, 4);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(-4, 0);
    }
    
    return tabBarItem;
}

- (UITabBarItem *)addMemoryTabBarItem {
    UITabBarItem *item = [[UITabBarItem alloc]
                          initWithTitle:NSLocalizedString(@"MEMORY", nil) image:nil selectedImage:nil];
    //[item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateNormal];
    item.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
    return item;
}

- (UITabBarItem *)activityTabBarItem {
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"ACTIVITY", nil)
                                                             image:[[[UIImage imageNamed:@"tab-bar-activity"] imageTintedWithColor:[UIColor colorWithRed:119.0f/255.0f green:130.0f/255.0f blue:144.0f/255.0f alpha:1.000f]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                     selectedImage:[[[UIImage imageNamed:@"tab-bar-activity"] imageTintedWithColor:[UITabBar appearance].tintColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.1" options:NSNumericSearch] != NSOrderedAscending) {
        // at least iOS 7.1.  See
        // http://stackoverflow.com/questions/22321323/ios-7-1-uitabbaritem-titlepositionadjustment-and-imageinsets
        tabBarItem.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(4, 0);
    } else {
        tabBarItem.imageInsets = UIEdgeInsetsMake(2, 4, -2, -4);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(4, 0);
    }
    
    return tabBarItem;
}

- (UITabBarItem *)profileTabBarItem {
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"PROFILE", nil)
                                                             image:[[[UIImage imageNamed:@"tab-bar-profile"] imageTintedWithColor:[UIColor colorWithRed:119.0f/255.0f green:130.0f/255.0f blue:144.0f/255.0f alpha:1.000f]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                                                     selectedImage:[[[UIImage imageNamed:@"tab-bar-profile"] imageTintedWithColor:[UITabBar appearance].tintColor] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.1" options:NSNumericSearch] != NSOrderedAscending) {
        // at least iOS 7.1.  See
        // http://stackoverflow.com/questions/22321323/ios-7-1-uitabbaritem-titlepositionadjustment-and-imageinsets
        tabBarItem.imageInsets = UIEdgeInsetsMake(2, 0, -2, 0);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(1, 0);
    } else {
        tabBarItem.imageInsets = UIEdgeInsetsMake(2, 1, -2, -1);
        tabBarItem.titlePositionAdjustment = UIOffsetMake(1, 0);
    }
    
    return tabBarItem;
}

#pragma mark - Accessors - View Controllers

- (UIViewController *)exploreViewController {
    if (!_exploreViewController) {
        _exploreViewController = [[SPCExploreViewController alloc] init];
    }
    return _exploreViewController;
}

- (UIViewController *)activityViewController {
    if (!_activityViewController) {
        _activityViewController = [[SPCActivityViewController alloc] init];
    }
    return _activityViewController;
}

- (UIViewController *)peopleViewController {
    if (!_peopleViewController) {
        _peopleViewController = [[SPCPeopleViewController alloc] init];
    }
    return _peopleViewController;
}
- (UIViewController *)locationPromptViewController {
    if (!_locationPromptViewController) {
        _locationPromptViewController = [[SPCLocationPromptViewController alloc] init];
    }
    return _locationPromptViewController;
}

- (UIViewController *)feedViewController {
    if (!_feedViewController) {
        _feedViewController = [[SPCFeedViewController alloc] initWithType:FeedControllerMemories];
    }
    return _feedViewController;
}

- (UIViewController *)profileViewController {
    if (!_profileViewController) {
        _profileViewController = [[SPCProfileViewController alloc] init];
    }
    return _profileViewController;
}

- (SPCMAMViewController *)mamViewController {
    if (!_mamViewController) {
        _mamViewController = [[SPCMAMViewController alloc] init];
    }
    return _mamViewController;
}

#pragma mark - Accessors - Navigation Controllers

- (UINavigationController *)spayceNavController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.exploreViewController];
    navController.tabBarItem = [self spayceTabBarItem];
    return navController;
}

- (UINavigationController *)activityNavController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.activityViewController];
    navController.tabBarItem = [self activityTabBarItem];
    return navController;
}

- (UINavigationController *)peopleNavController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.peopleViewController];
    navController.tabBarItem = [self activityTabBarItem];
    return navController;
}

- (UINavigationController *)locationPromptNavController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.locationPromptViewController];
    navController.tabBarItem = [self addMemoryTabBarItem];
    return navController;
}

- (UINavigationController *)feedNavController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.feedViewController];
    navController.tabBarItem = [self feedTabBarItem];
    return navController;
}

- (UINavigationController *)profileNavController {
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.profileViewController];
    navController.tabBarItem = [self profileTabBarItem];
    return navController;
}

#pragma mark - Accessors - Tab Bar Controller

- (SPCTabBarController *)customTabBarController {
    if (!_customTabBarController) {
        _customTabBarController = [[SPCTabBarController alloc] init];
        
        BOOL needToAdmin = NO;
        
        if (needToAdmin){
            _customTabBarController.viewControllers = @[
                                                        [self spayceNavController],
                                                        [self feedNavController],
                                                        [self locationPromptViewController],
                                                        [self peopleNavController],
                                                        [self profileNavController]
                                                        ];
        }
        else {
        _customTabBarController.viewControllers = @[
                                                    [self spayceNavController],
                                                    [self feedNavController],
                                                    [self locationPromptViewController],
                                                    [self activityNavController],
                                                    [self profileNavController]
                                                    ];
        }
        //[_customTabBarController.tabBar setSelectionIndicatorImage:[UIImage imageWithColor:[UIColor colorWithRed:217.0/255.0 green:222.0/255.0 blue:229.0/255.0 alpha:1.0] size:CGSizeMake(CGRectGetWidth(_customTabBarController.tabBar.frame) / _customTabBarController.tabBar.items.count, CGRectGetHeight(_customTabBarController.tabBar.frame))]];
        //[_customTabBarController.tabBar setBackgroundColor:[UIColor colorWithRed:42.0f/255.0f green:51.0f/255.0f blue:64.0f/255.0f alpha:1.000f]];
    }
    return _customTabBarController;
}

#pragma mark - Accessors - Bonus View

-(UIView *)highSpeedPrompt {
    if (!_highSpeedPrompt) {
        _highSpeedPrompt = [[UIView alloc] initWithFrame:self.view.frame];
        _highSpeedPrompt.backgroundColor = [UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:.7];
        
        CAGradientLayer *l = [CAGradientLayer layer];
        l.frame = _highSpeedPrompt.bounds;
        l.name = @"Gradient";
        
        l.colors = @[(id)[[UIColor colorWithRed:45.0f/255.0f green:55.0f/255.0f blue:71.0f/255.0f alpha:1.0] CGColor], (id)[[UIColor colorWithRed:45.0f / 255.0f green:55.0f / 255.0f blue:71.0f / 255.0f alpha:.6] CGColor]];
        
        l.startPoint = CGPointMake(0.5, 0.0f);
        l.endPoint = CGPointMake(0.5f, 1.0f);
        [_highSpeedPrompt.layer addSublayer:l];
        
        UIImage *iconImg = [UIImage imageNamed:@"automobile"];
        UIImageView *iconImgView = [[UIImageView alloc] initWithImage:iconImg];
        iconImgView.center = CGPointMake(self.view.bounds.size.width/2, 175);
        [_highSpeedPrompt addSubview:iconImgView];
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(iconImgView.frame), self.view.frame.size.width - 40, 20)];
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.text = @"High Speed";
        [_highSpeedPrompt addSubview:titleLabel];
        
        UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(60, CGRectGetMaxY(titleLabel.frame), self.view.frame.size.width - 120, 80)];
        msgLabel.text = @"It looks like you are moving quickly and not at a specific place, would you like to view nearby memories and venues?";
        msgLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        msgLabel.textColor = [UIColor whiteColor];
        msgLabel.numberOfLines = 0;
        msgLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        msgLabel.textAlignment = NSTextAlignmentCenter;
        [_highSpeedPrompt addSubview:msgLabel];
        
        UIButton *hiSpeedBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(msgLabel.frame) + 20, self.view.frame.size.width - 40, 40)];
        hiSpeedBtn.backgroundColor = [UIColor clearColor];
        hiSpeedBtn.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
        hiSpeedBtn.layer.borderWidth = 1;
        hiSpeedBtn.layer.cornerRadius = 2;
        hiSpeedBtn.titleLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        hiSpeedBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        [hiSpeedBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [hiSpeedBtn setTitle:@"Enter High Speed Mode" forState:UIControlStateNormal];
        [hiSpeedBtn addTarget:self action:@selector(goHighSpeed) forControlEvents:UIControlEventTouchUpInside];
        [_highSpeedPrompt addSubview:hiSpeedBtn];
        
        UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(hiSpeedBtn.frame) + 20, self.view.frame.size.width - 40, 40)];
        cancelBtn.backgroundColor = [UIColor clearColor];
        cancelBtn.layer.cornerRadius = 2;
        cancelBtn.titleLabel.textColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f];
        cancelBtn.layer.borderColor = [UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f].CGColor;
        cancelBtn.layer.borderWidth = 1;
        cancelBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
        [cancelBtn setTitleColor:[UIColor colorWithRed:84.0f/255.0f green:179.0f/255.0f blue:250.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        [cancelBtn setTitle:@"Not Now" forState:UIControlStateNormal];
        [cancelBtn addTarget:self action:@selector(cancelHighSpeed) forControlEvents:UIControlEventTouchUpInside];
        [_highSpeedPrompt addSubview:cancelBtn];
        
        
    }
    return _highSpeedPrompt;
}

-(UIImage *)launchImg {
    NSArray *allPngImageNames = [[NSBundle mainBundle] pathsForResourcesOfType:@"png"
                                                                   inDirectory:nil];
    
    for (NSString *imgName in allPngImageNames) {
        
        if ([imgName respondsToSelector:@selector(containsString:)]) {
            
            if ([imgName rangeOfString:@"LaunchImage"].location != NSNotFound) {
                UIImage *img = [UIImage imageNamed:imgName];
                // Has image same scale and dimensions as our current device's screen?
                if (img.scale == [UIScreen mainScreen].scale && CGSizeEqualToSize(img.size, [UIScreen mainScreen].bounds.size)) {
                    return img;
                    break;
                }
            }
        }
        else {
            if ([imgName rangeOfString:@"LaunchImage"].location != NSNotFound) {
                NSMutableString *mutImgName = [NSMutableString stringWithString:imgName];
                NSInteger loc = [imgName rangeOfString:@"LaunchImage"].location;
                NSInteger length = imgName.length - loc;
                NSString *trimmedStr = [mutImgName substringWithRange:NSMakeRange(loc,length)];
                UIImage *img = [UIImage imageNamed:trimmedStr];
                
                if (img.scale * img.size.width == [UIScreen mainScreen].scale * [UIScreen mainScreen].bounds.size.width) {
                    return img;
                    break;
                }
            }
        }
    }
    
    return nil;
}

#pragma mark - SPCWelcomeIntroDelegate

- (void)tappedWelcomeIntroVC:(SPCWelcomeIntroViewController *)welcomeIntroVC andHasPlayedToEnd:(BOOL)hasPlayedToEnd {
    // Set that we've watched the intro video, so it no longer plays automatically on startup
    self.welcomeIntroWasShown = YES;
    
    // Custom transition into the welcome view controller
    SPCWelcomePageViewController *welcomePageViewController = [[SPCWelcomePageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomePageViewController];
    
    // Remove any lingering view controllers, except for the welcome intro VC
    for (UIViewController *viewController in self.childViewControllers) {
        if (NO == [viewController isEqual:welcomeIntroVC]) {
            [viewController removeFromParentViewController];
            [viewController.view removeFromSuperview];
        }
    }
    
    // Add the navController to the controller view hierarchy - just to the right of the screen
    navController.view.frame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    [self.view addSubview:navController.view];
    [self addChildViewController:navController];
    [navController didMoveToParentViewController:self];
    
    // Slide the welcomeIntroVC and the welcomeVc to the left, at the same time
    [UIView animateWithDuration:0.4f animations:^{
        welcomeIntroVC.view.frame = CGRectMake(-1 * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        navController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    } completion:^(BOOL finished) {
        [welcomeIntroVC removeFromParentViewController];
        [welcomeIntroVC.view removeFromSuperview];
        
        // Make sure we set our currentViewController property
        _currentViewController = navController;
    }];
}

- (void)setWelcomeIntroWasShown:(BOOL)welcomeIntroWasShown {
    [[NSUserDefaults standardUserDefaults] setBool:welcomeIntroWasShown forKey:kSPCWelcomeIntroWasShown];
}

- (BOOL)welcomeIntroWasShown {
    BOOL wasShown = NO;
    
    if (nil != [[NSUserDefaults standardUserDefaults] objectForKey:kSPCWelcomeIntroWasShown]) {
        wasShown = [[NSUserDefaults standardUserDefaults] boolForKey:kSPCWelcomeIntroWasShown];
    }
    
    return wasShown;
}

#pragma mark - Private

- (void)setCurrentViewController:(UIViewController *)currentViewController {
    if (_currentViewController == currentViewController || [_currentViewController class] == [currentViewController class]) {
        return;
    }
    
    // Remove current view controller from view controller hiearchy
    for (UIViewController *viewController in self.childViewControllers) {
        [viewController removeFromParentViewController];
        [viewController.view removeFromSuperview];
    }
    
    // Add new view controller to controller view hierarchy
    if (currentViewController == self.customTabBarController) {
        self.customTabBarController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        [self.view addSubview:self.customTabBarController.view];
        [self addChildViewController:self.customTabBarController];
        [self.customTabBarController didMoveToParentViewController:self];
    } else {
        currentViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
       
        [self.view addSubview:currentViewController.view];
        [self addChildViewController:currentViewController];
        [currentViewController didMoveToParentViewController:self];
    }
    
    // Show splash animation
    //NSLog(@"set vc!");
    if (!animationExists && !self.previewMode && YES == self.welcomeIntroWasShown) {
        animationExists = YES;
        //NSLog(@"add intro animation to main vc!");
        IntroAnimation *introAnimation = [[IntroAnimation alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        if (justLoggedIn) {
            [introAnimation loginStarted];
            justLoggedIn = NO;
        }
        [introAnimation prepAnimation];
        [introAnimation startAnimation];
        [self.view addSubview:introAnimation];
    }
    _currentViewController = currentViewController;
}

-(void)handleFBInviteAll {
    
    if ([FBSession activeSession] && [FBSession activeSession].accessTokenData.accessToken) {
        
        NSLog(@"active FB session and access token exists - attempting to handleFBInviteAll");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FBInviteAllSkipped" object:nil];
    }
    else {
        //NSLog(@"skipping FB send all");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FBInviteAllSkipped" object:nil];
    }
}


#pragma mark - NSNotificationCenter

- (void)handlePreviewMode {
    
    self.previewMode = YES;
    
    self.exploreViewController = nil;
    self.feedViewController = nil;
    self.locationPromptViewController = nil;
    self.activityViewController = nil;
    self.profileViewController = nil;
    self.customTabBarController = nil;
    self.currentViewController = self.customTabBarController;
    ((SPCTabBarController *)self.customTabBarController).previewMode = YES;

}

- (void)endPreviewMode {
    
    self.previewMode = YES;
    
    SPCWelcomePageViewController *welcomePageViewControler = [[SPCWelcomePageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomePageViewControler];
    
    self.currentViewController = navController;
    
    // Reset to default tab
    if (self.customTabBarController.viewControllers.count > 0) {
        self.customTabBarController.selectedViewController = self.customTabBarController.viewControllers[0];
    }
}


- (void)handleAuthenticationNotification:(NSNotification *)notification {
    justLoggedIn = (notification.userInfo != nil);
    self.previewMode = NO;
    
    // Avoid information leaking between profiles: create new ViewControllers
    // for everything.
    self.exploreViewController = nil;
    self.feedViewController = nil;
    self.locationPromptViewController = nil;
    self.activityViewController = nil;
    self.profileViewController = nil;
    self.customTabBarController = nil;
    self.currentViewController = self.customTabBarController;
    
}

- (void)handleAuthenticationDidFail:(NSNotification *)notification {
    SPCWelcomePageViewController *welcomePageViewControler = [[SPCWelcomePageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomePageViewControler];
    
    self.currentViewController = navController;
    
    // Reset to default tab
    if (self.customTabBarController.viewControllers.count > 0) {
        self.customTabBarController.selectedViewController = self.customTabBarController.viewControllers[0];
    }
}

- (void)handleLogout:(NSNotification *)notification {
    SPCWelcomePageViewController *welcomePageViewControler = [[SPCWelcomePageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:welcomePageViewControler];
    
    self.currentViewController = navController;
    
    // Avoid information leaking between profiles: zero out view controllers
    self.exploreViewController = nil;
    self.spayceViewController = nil;
    self.feedViewController = nil;
    self.locationPromptViewController = nil;
    self.activityViewController = nil;
    self.profileViewController = nil;
    self.customTabBarController = nil;
}

-(void)animationComplete {
    animationExists = NO;
}

- (void)handleMakeMemAnimation:(NSNotification *)notification {
    // Reset to Spayce tab & kickstart animation
    if (self.customTabBarController.viewControllers.count > 0) {
        [self completedMAM];
        self.customTabBarController.selectedViewController = self.customTabBarController.viewControllers[0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"finishMemAnimation" object:nil];
    }
}

- (void)handleHiSpeedPrompt:(NSNotification *)notification {
    //[self.view addSubview:self.highSpeedPrompt];
}

- (void)goHighSpeed {
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"goHighSpeed" object:nil];
    //[self.highSpeedPrompt removeFromSuperview];
}

- (void)cancelHighSpeed {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse) {
       // [[LocationManager sharedInstance] cancelHiSpeed];
    }
    //[self.highSpeedPrompt removeFromSuperview];
}

#pragma mark - Special Case: MAM Capture Methods
// in order to support the desired transition animation
// we use the following methods

- (void)handleMAM:(NSNotification *)note {
#if TARGET_IPHONE_SIMULATOR
//          ____
//     _[]_/____\__n_
//    |_____.--.__()_|
//    |LI  //# \\    |
//    |    \\__//    |
//    |     '--'     |
//    '--------------'
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry No Camera On SIM", nil)
                                message:NSLocalizedString(@"____\n _[]_/____\\__n_\n|_____.--.__()__|\n|LI    // # \\\\       |\n|       \\\\__//       |\n|         '--'         |\n'----------------'", nil)
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
    return;
#endif
    
    //handles status bar for capture
 
    //only hide the status bar if it's not expanded
    CGRect statusBarFrame =  [(AppDelegate*)[[UIApplication sharedApplication] delegate] currentStatusBarFrame];
    float maxUnexpandedHeight = 20;
    BOOL expandedStatusBar = NO;
    
    if (CGRectGetHeight(statusBarFrame) > maxUnexpandedHeight) {
        expandedStatusBar = YES;
    }
    self.mamCaptureActive = YES;
    
    if (!expandedStatusBar) {
        [self performSelector:@selector(spc_hideStatusBar) withObject:nil afterDelay:.4];
    }
    //Venue *venue = note.object;
    
    //add capture vc to view and prep for reveal
    
    
    //SPCCaptureMemoryViewController *tempAddMemVC = [[SPCCaptureMemoryViewController alloc] initWithSelectedVenue:venue];
    //UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tempAddMemVC];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.mamViewController];
    
    [self addChildViewController:navController.viewControllers[0]];
 
    [self.view insertSubview:self.mamViewController.view atIndex:0];
    
    //[self.view insertSubview:tempAddMemVC.view atIndex:0];
    
    //reveal splash logo for when needed
    [[self.view viewWithTag:-2] setAlpha:0];
    
    //animate out existing content
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:.5];
    self.currentViewController.view.center = CGPointMake(self.currentViewController.view.center.x, self.currentViewController.view.frame.size.height/2 + CGRectGetHeight(self.currentViewController.view.frame));
    [UIView commitAnimations];

}

- (void)handleMAMFromModal:(NSNotification *)note {
#if TARGET_IPHONE_SIMULATOR
    //          ____
    //     _[]_/____\__n_
    //    |_____.--.__()_|
    //    |LI  //# \\    |
    //    |    \\__//    |
    //    |     '--'     |
    //    '--------------'
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry No Camera On SIM", nil)
                                message:NSLocalizedString(@"____\n _[]_/____\\__n_\n|_____.--.__()__|\n|LI    // # \\\\       |\n|       \\\\__//       |\n|         '--'         |\n'----------------'", nil)
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
    return;
#endif
    
    if (self.presentedViewController) {
        self.previouslyPresentedViewController = self.presentedViewController;
        
        Venue *venue = note.object;
        SPCCaptureMemoryViewController *captureMemoryViewController = [[SPCCaptureMemoryViewController alloc] initWithSelectedVenue:venue];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:captureMemoryViewController];
        [self addChildViewController:navController];
        [self.view insertSubview:navController.view atIndex:0];
        
        [[self.view viewWithTag:-2] setAlpha:0];
        
        self.currentViewController.view.center = CGPointMake(self.currentViewController.view.center.x, self.currentViewController.view.center.y + CGRectGetHeight(self.currentViewController.view.frame));
        
        [self spc_setStatusBarMasked:YES];
        
        [self.customTabBarController dismissViewControllerAnimated:YES completion:^{
            [self spc_hideStatusBar];
            [self spc_setStatusBarMasked:NO];
        }];
    }
}

- (void)presentViewController:(UIViewController *)viewController completionHandler:(void (^)())completionHandler {
    [self.customTabBarController presentViewController:self.previouslyPresentedViewController animated:YES completion:^{
        if (completionHandler) {
            completionHandler();
        }
    }];
}

//called when MAM is cancelled
- (void)dismissMAM {
    [self spc_setStatusBarMasked:YES];
    [self spc_setStatusBarMasked:NO];
    
    if (self.previouslyPresentedViewController) {
        [self presentViewController:self.previouslyPresentedViewController completionHandler:^{
            self.previouslyPresentedViewController = nil;
            
            [self dismissMAMAnimated:NO];
        }];
    }
    else {
        [self dismissMAMAnimated:YES];
    }
}

- (void)dismissMAMAnimated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.5 : 0.0 animations:^{
        self.currentViewController.view.center = CGPointMake(self.currentViewController.view.center.x, self.currentViewController.view.frame.size.height/2);
    } completion:^(BOOL finished) {
        [self cleanUpAfterMAM];
    }];
}

//called after MAM is posted
- (void)completedMAM {
    //move previous content to center immediately
    self.currentViewController.view.center = CGPointMake(self.currentViewController.view.center.x, self.currentViewController.view.frame.size.height/2);
    [self cleanUpAfterMAM];
}

- (void)mamEndedFromFullScreenStart {
    self.previouslyPresentedViewController = nil;
}

- (void)completedMAMAnimation:(NSNotification *)note {
    if (self.previouslyPresentedViewController) {
        [self presentViewController:self.previouslyPresentedViewController completionHandler:^{
            self.previouslyPresentedViewController = nil;
        }];
    }
}

//called after MAM posts or cancels
-(void)cleanUpAfterMAM {
    
    //update status bar
    self.mamCaptureActive = NO;
    [self spc_showStatusBar];
    
    // Remove capture view controller from hiearchy
    for (UIViewController *viewController in self.childViewControllers) {
       
        if (viewController != self.currentViewController) {
            [viewController removeFromParentViewController];
            [viewController.view removeFromSuperview];
        }
    }
    
    //reveal splash logo under content for when needed
    [[self.view viewWithTag:-2] setAlpha:1];
    
    [self.mamViewController resetMAM];
    
    self.mamViewController = nil;
}

#pragma mark - Status bar

- (void)spc_hideStatusBar {
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)spc_showStatusBar {
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)spc_setStatusBarMasked:(BOOL)masked {
    SPCHereViewController *spayceViewController = (SPCHereViewController *)self.spayceViewController;
    spayceViewController.mamCaptureActive = masked;
}


-(bool)isOnPhoneCall {
    
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall *call in callCenter.currentCalls)  {
        if (call.callState == CTCallStateConnected) {
            NSLog(@"is on call?");
            return YES;
        }
    }
    
    NSLog(@"not on a call");
    return NO;
}


- (void)statusBarFrameWillChange:(NSNotification*)notification {
    NSValue* rectValue = [[notification userInfo] valueForKey:UIApplicationStatusBarFrameUserInfoKey];
    CGRect newFrame;
    [rectValue getValue:&newFrame];
    //NSLog(@"statusBarFrameWillChange: newSize %f, %f", newFrame.size.width, newFrame.size.height);

    float maxUnexpandedHeight = 20;
    
    if ( CGRectGetHeight(newFrame) > maxUnexpandedHeight) {
        if (self.mamCaptureActive) {
            //NSLog(@"show status bar, mam capture is active, but it's an expanded status bar");
            [self spc_showStatusBar];
            self.mamViewController.view.frame = self.view.bounds;
        }
    }
    else {
        if (self.mamCaptureActive) {
 
            /*  ATTEMPT TO HANDLE STATUS BAR UPDATE CHANGE W/IN MAM WHILE CAPTURE SESSION IS ACTIVE AND CALL/NAVIGATION ENDS 
             
             // - Issue is that status bar comes back as 20, autoresizing mask kicks in accordingly, but there's actually no status bar here, so we the autoresizing mask isn't right
             
             NSLog(@"initial self frame %f %f %f %f",self.view.frame.origin.x,self.view.frame.origin.y,self.view.frame.size.width,self.view.frame.size.height);
            
             NSLog(@"hide status bar, mam capture is active");
             // tried - hiding status bar as is done when mam is entered.  nope.
             [self spc_hideStatusBar];
            
             NSLog(@"self frame %f %f %f %f",self.view.frame.origin.x,self.view.frame.origin.y,self.view.frame.size.width,self.view.frame.size.height);
             NSLog(@"mamVC frame %f %f %f %f",self.mamViewController.view.frame.origin.x,self.mamViewController.view.frame.origin.y,self.mamViewController.view.frame.size.width,self.mamViewController.view.frame.size.height);
            
             // tried - hard setting the frame. nope.
             // tried - disabling autoresizing mask here.  nope.
             
             */
           
            //note - grr.  the above still doesn't work.  dismissing capture for now, since that case is handled cleanly and when MAM is reopened the view is set properly
            [self dismissMAM];
        }
    }
}

#pragma mark - Audio 

-(void)playPNSSound {
    [_audioPlayer play];
}

@end
