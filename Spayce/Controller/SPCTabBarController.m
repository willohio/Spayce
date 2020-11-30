//
//  SPCTabBarController.m
//  Spayce
//
//  Created by William Santiago on 4/22/14.
//  Copyright (c) 2014 Spayce Inc. All rights reserved.
//

#import "SPCTabBarController.h"
#import "LocationManager.h"
#import "LKBadgeView.h"
#import "SPCStarCountButton.h"
#import "PNSManager.h"
#import "SPCMessageManager.h"
#import "Constants.h"
#import "UITabBarController+SPCAdditions.h"
#import "Flurry.h"
#import <AVFoundation/AVFoundation.h>

@interface SPCTabBarController ()

@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, strong) LKBadgeView *newsBadgeView;
@property (nonatomic, strong) LKBadgeView *friendsBadgeView;

@end

@implementation SPCTabBarController

#pragma mark - NSObject - Creating, Copying, and Deallocating Objects

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    @try {
        [self.tabBar removeObserver:self forKeyPath:@"alpha"];
        [self.tabBar removeObserver:self forKeyPath:@"hidden"];
        [self.tabBar removeObserver:self forKeyPath:@"selectedItem"];
        [[PNSManager sharedInstance] removeObserver:self forKeyPath:@"totalCount"];
        [[SPCMessageManager sharedInstance] removeObserver:self forKeyPath:@"unreadThreadCount"];
    }
    @catch (NSException *exception) {}
}

#pragma mark - UIViewController - Managing the View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpToHere) name:@"jumpToHere" object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFriendBadgeCount) name:kFriendRequestDisplaysNeedUpdating object:nil];
    
    [self setTabBarAppearance];
}

#pragma mark - Appearance

- (void)setTabBarAppearance {
    // Set the tabbaritem title font and color
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                                                        NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:8.0f],
                                                        NSForegroundColorAttributeName : [UIColor colorWithRed:119.0f/255.0f green:130.0f/255.0f blue:144.0f/255.0f alpha:1.000f]
                                                        }
                                             forState:UIControlStateNormal];
    [[UITabBarItem appearance] setTitleTextAttributes:@{
                                                        NSFontAttributeName : [UIFont fontWithName:@"OpenSans-Semibold" size:8.0f],
                                                        NSForegroundColorAttributeName : [UIColor whiteColor]
                                                        }
                                             forState:UIControlStateSelected];
    
    // Set the shadow image to no shadows
    [[UITabBar appearance] setShadowImage:nil];
    
    // Set the tint colors
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor whiteColor]];
    
    // Background
    // Setting a background color for the tabbar's appearance
    [[UITabBar appearance] setBackgroundColor:[UIColor colorWithRed:1.0f/255.0f green:24.0f/255.0f blue:73.0f/255.0f alpha:1.0f]];
}

#pragma mark - Accesssors

- (UIButton *)centerButton {
    if (!_centerButton) {
        UITabBar *tabBar = self.tabBar;
        UIImage *image = [UIImage imageNamed:@"tab-bar-memory"];
        
        _centerButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _centerButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        _centerButton.frame = CGRectMake(CGRectGetMidX(tabBar.frame) - (CGRectGetWidth(tabBar.frame) / self.viewControllers.count) / 2, 0.0, CGRectGetWidth(tabBar.frame) / self.viewControllers.count, CGRectGetHeight(tabBar.frame));
        //_centerButton.tintColor = [UIColor colorWithRed:90.0/255.0 green:169.0/255.0 blue:251.0/255.0 alpha:1.0];
        [_centerButton setImage:image forState:UIControlStateNormal];
        [_centerButton addTarget:self action:@selector(centerButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        CGPoint centerPoint = _centerButton.center;
        CGSize bgBtnSize = CGSizeMake(self.view.bounds.size.width/5, 44.0f);
        UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(centerPoint.x - bgBtnSize.width / 2, centerPoint.y - bgBtnSize.height / 2, bgBtnSize.width, bgBtnSize.height)];
        bgView.backgroundColor = [UIColor colorWithRed:3.0f/255.0f green:38.0f/255.0f blue:124.0f/255.0f alpha:1.0f];
        [tabBar addSubview:bgView];
    }
    return _centerButton;
}


- (LKBadgeView *)friendsBadgeView {
    if (!_friendsBadgeView) {
        
        float tabWidth = CGRectGetWidth(self.tabBar.frame)/self.tabBar.items.count;
        
        float offsetAdj = 4;
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            offsetAdj = 10;
        }
        
        _friendsBadgeView = [[LKBadgeView alloc] initWithFrame:CGRectMake(tabWidth * 3, 2.0, CGRectGetWidth(self.tabBar.frame)/self.tabBar.items.count - offsetAdj, 20.0)];
        
        _friendsBadgeView.badgeColor = [UIColor colorWithRed:90.0/255.0 green:169.0/255.0 blue:251.0/255.0 alpha:1.0f];
        _friendsBadgeView.horizontalAlignment = LKBadgeViewHorizontalAlignmentRight;
        _friendsBadgeView.widthMode = LKBadgeViewWidthModeSmall;
        _friendsBadgeView.font = [UIFont spc_badgeFont];
    }
    return _friendsBadgeView;
}

- (LKBadgeView *)newsBadgeView {
    if (!_newsBadgeView) {
        
        float tabWidth = CGRectGetWidth(self.tabBar.frame)/self.tabBar.items.count;
        
        float offsetAdj = 4;
        
        if ([UIScreen mainScreen].bounds.size.width >= 375) {
            offsetAdj = 10;
        }
        
        _newsBadgeView = [[LKBadgeView alloc] initWithFrame:CGRectMake(tabWidth * 3, 2.0, CGRectGetWidth(self.tabBar.frame)/self.tabBar.items.count - offsetAdj, 20.0)];
        
        _newsBadgeView.badgeColor = [UIColor colorWithRed:90.0/255.0 green:169.0/255.0 blue:251.0/255.0 alpha:1.0f];
        _newsBadgeView.horizontalAlignment = LKBadgeViewHorizontalAlignmentRight;
        _newsBadgeView.widthMode = LKBadgeViewWidthModeSmall;
        _newsBadgeView.font = [UIFont spc_badgeFont];
    }
    return _newsBadgeView;
}

- (void)setViewControllers:(NSArray *)viewControllers {
    [super setViewControllers:viewControllers];
    
    // Do not add to view hierarchy prior to view controllers being set
    // This has layout implications since we're positioning based on the
    // total amount of view controllers
    if (!self.centerButton.superview) {
        [self.tabBar addSubview:self.centerButton];
        
        // Observe tab bar 'hidden' and 'alpha' properties in order to
        // update center button accordingly to mimic consistency
        // Observe the selectedItem to reset the People section when changing tabs
        [self.tabBar addObserver:self forKeyPath:@"selectedItem" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
        [self.tabBar addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
        [self.tabBar addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    
    if (!self.friendsBadgeView.superview) {
        [self.tabBar addSubview:self.friendsBadgeView];
        self.friendsBadgeView.text = [NSString stringWithFormat:@"%i",(int)[PNSManager sharedInstance].unseenFriendRequests];
        
        if ([PNSManager sharedInstance].unseenFriendRequests <= 0) {
            self.friendsBadgeView.hidden = YES;
        } else {
            self.friendsBadgeView.hidden = NO;
        }
        
    }
    
    if (!self.newsBadgeView.superview) {
        [self.tabBar addSubview:self.newsBadgeView];
         NSInteger combinedCount = [PNSManager sharedInstance].unreadNews + [SPCMessageManager sharedInstance].unreadThreadCount;
        self.newsBadgeView.text = [NSString stringWithFormat:@"%i",(int)combinedCount];
        
        
        if (combinedCount <= 0) {
            self.newsBadgeView.hidden = YES;
        } else {
            self.newsBadgeView.hidden = NO;
        }
        // Start observing the value of the total unread notifications count
        NSLog(@"add tab bar observers?");
        [[PNSManager sharedInstance] addObserver:self forKeyPath:@"totalCount" options:NSKeyValueObservingOptionInitial context:nil];
        [[SPCMessageManager sharedInstance] addObserver:self forKeyPath:@"unreadThreadCount" options:NSKeyValueObservingOptionInitial context:nil];
    }
}

#pragma mark - Private

- (void)revealTabBar {
    self.tabBar.alpha = 1.0;
    self.tabBar.hidden = NO;
    [self setTabBarHidden:NO animated:NO];
}

#pragma mark - Actions

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [super setSelectedIndex:selectedIndex];
    [self revealTabBar];
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController {
    [super setSelectedViewController:selectedViewController];
    [self revealTabBar];
}

- (void)centerButtonAction:(id)sender {
    
    if (self.previewMode) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
        return;
    }
    
    if (([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        
        if ([[LocationManager sharedInstance] locServicesAvailable]) {
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    // Permission has been granted. Use dispatch_async for any UI updating
                    // code because this block may be executed in a thread.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"handleMAM" object:nil];
                    });
                } else {
                    // Permission has been denied.
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Camera Access Disabled", nil)
                                                    message:NSLocalizedString(@"Spayce functionality will be limited without access to the camera. Please go to Settings > Privacy > Camera > and turn on Spayce", nil)
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil] show];
                    });
              
                }
            }];
    
        }
        else {
            //location is off, show prompt
            [self setSelectedIndex:TAB_BAR_MAM_ITEM_INDEX];
        }
    } else {
            //location is off, show prompt
            [self setSelectedIndex:TAB_BAR_MAM_ITEM_INDEX];
    }
}

- (void)jumpToHere {
    [self revealTabBar];
    [self setSelectedIndex:TAB_BAR_HOME_ITEM_INDEX];
}

- (void)jumpToProfile {
    [self revealTabBar];
    [self setSelectedIndex:TAB_BAR_PROFILE_ITEM_INDEX];
}

- (void)showStarCountNotification:(NSNotification *)note {
    /*
    self.profileButton.count = [note.userInfo[@"count"] integerValue];
    [self.profileButton updateTitle];
    [self.profileButton hideButtonAfterDelay:8];
     */
}

- (void)hideStarCountNotification:(NSNotification *)note {
  //  self.profileButton.count = 0;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}


-(void)updateFriendBadgeCount {
    self.friendsBadgeView.text = [NSString stringWithFormat:@"%i",(int)[PNSManager sharedInstance].unseenFriendRequests];
    
    if ([PNSManager sharedInstance].unseenFriendRequests <= 0) {
        self.friendsBadgeView.hidden = YES;
    } else {
        self.friendsBadgeView.text = [NSString stringWithFormat:@"%i",(int)[PNSManager sharedInstance].unseenFriendRequests];
        
        self.friendsBadgeView.hidden = NO;
    }
}
#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [PNSManager sharedInstance]) {
        if ([keyPath isEqualToString:@"totalCount"])  {
            
            NSInteger combinedCount = [PNSManager sharedInstance].unreadNews + [SPCMessageManager sharedInstance].unreadThreadCount;
            self.newsBadgeView.text = [NSString stringWithFormat:@"%i",(int)combinedCount];
            
            if (combinedCount <= 0) {
                self.newsBadgeView.hidden = YES;
            } else {
                self.newsBadgeView.hidden = NO;
            }
        }
    }
    
    if (object == [SPCMessageManager sharedInstance]) {
        if ([keyPath isEqualToString:@"unreadThreadCount"])  {
            
            NSInteger combinedCount = [PNSManager sharedInstance].unreadNews + [SPCMessageManager sharedInstance].unreadThreadCount;
            self.newsBadgeView.text = [NSString stringWithFormat:@"%i",(int)combinedCount];

            if (combinedCount <= 0) {
                self.newsBadgeView.hidden = YES;
            } else {
                self.newsBadgeView.hidden = NO;
            }
        }
    }
    
    
    if (object == self.tabBar) {
        if ([keyPath isEqualToString:@"selectedItem"])  {
            
            UITabBar *bar = (UITabBar *)object;
            // The change dictionary will contain the previous tabBarItem for the "old" key.
            UITabBarItem *wasItem = [change objectForKey:NSKeyValueChangeOldKey];
            NSUInteger was = [bar.items indexOfObject:wasItem];
            // The same is true for the new tabBarItem but it will be under the "new" key.
            UITabBarItem *isItem = [change objectForKey:NSKeyValueChangeNewKey];
            NSUInteger is = [bar.items indexOfObject:isItem];
            
            if (was != is ) {
                //we have changed tabs, reset People as needed
                [[NSNotificationCenter defaultCenter] postNotificationName:@"clearVids" object:nil]; // stop all videos on tab bar switch
                
                if (self.previewMode) {
                     if ((is == TAB_BAR_FEED_ITEM_INDEX) || (is == TAB_BAR_ACTIVITY_ITEM_INDEX) || (is == TAB_BAR_PROFILE_ITEM_INDEX)) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"endPreviewMode" object:nil];
                    }
                }
                
                if (was == TAB_BAR_ACTIVITY_ITEM_INDEX) {
                   [[NSNotificationCenter defaultCenter] postNotificationName:@"checkForNotifBadgeUpdate" object:nil];
                }
                
                if (is == TAB_BAR_HOME_ITEM_INDEX) {
                    [Flurry logEvent:@"TAB_HOME"];
                }
                if (is == TAB_BAR_FEED_ITEM_INDEX) {
                    [Flurry logEvent:@"TAB_FEED"];
                }
                if (is == TAB_BAR_MAM_ITEM_INDEX) {
                    [Flurry logEvent:@"TAB_MAM"];
                }
                if (is == TAB_BAR_ACTIVITY_ITEM_INDEX) {
                    [Flurry logEvent:@"TAB_ACTIVITY"];
                }
                if (is == TAB_BAR_PROFILE_ITEM_INDEX) {
                    [Flurry logEvent:@"TAB_FRIENDS"];
                }
                
                // Alert other VCs that we have changed tab bar items
                [[NSNotificationCenter defaultCenter] postNotificationName:kSPCTabBarSelectedItemDidChangeNotification object:@{@"bar": object, @"change" : change}];
            }
            
        }
    }
}


@end
